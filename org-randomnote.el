;;; org-randomnote.el --- Find a random note in your Org-Mode files

;; Copyright (C) 2017 Michael Fogleman

;; Author: Michael Fogleman <michaelwfogleman@gmail.com>
;; URL: http://github.com/mwfogleman/org-randomnote
;; Package-Version: 20190403.1633
;; Version: 0.1.0
;; Package-Requires: ((f "0.19.0") (dash "2.12.0") org)

;; This file is NOT part of GNU Emacs.

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; This package implements the "Random Note" functionality popularized
;; by Tiago Forte with Evernote in Emacs Org-Mode.

;;; Code:

(require 'dash)
(require 'f)
(require 'org)

(defcustom org-randomnote-candidates (org-agenda-files)
  "The files that org-randomnote will draw from in finding a random note.  Defaults to `(org-agenda-files)'."
  :group 'org-randomnote
  :type '(repeat :tag "List of files and directories" file)
  :set
  (lambda (sym value)
    (set sym value)
    (setq org-randomnote--file-to-header-count
          (-map (lambda (f) (cons f 0))
                org-randomnote-candidates))
    (setq org-randomnote--file-to-tick-count
          (-map (lambda (f) (cons f 0))
                org-randomnote-candidates))
    (org-randomnote--update-header-count)))

(defvar org-randomnote-open-behavior 'default
  "Configure the behavior that org-randomnote uses to open a random note.  Set to `default' or `indirect-buffer'.")

(defvar org-randomnote--file-to-header-count ()
  "Association list mapping file names from org-randomnote-candidates to the
number of headers within that file. Not user-serviceable.")

(defvar org-randomnote--file-to-tick-count ()
  "Association list mapping file names from org-randomnote-candidates to the
value of calling `buffer-chars-modified-tick' in the buffer.  Not
user-serviceable.")

(defvar org-randomnote--update-header-count-timer nil
  "Timer that calls `org-randomnote--update-header-count'. Not
user-serviceable.")

(defun org-randomnote--update-header-count ()
  "Update the header count for random choices."
  (dolist (f org-randomnote-candidates)
    (let*  ((entry (assoc f org-randomnote--file-to-tick-count))
            (old-ticks (cdr entry))
            (new-ticks (buffer-chars-modified-tick
                        (find-buffer-visiting f))))
      (unless (and entry (equal old-ticks new-ticks))
        (setcdr entry new-ticks)
        (setcdr (assoc f org-randomnote--file-to-header-count)
                (org-randomnote--count-headers f))))))

(defun org-randomnote--count-headers (f)
  "Count the number of Org headers in the file F."
  (with-current-buffer (find-buffer-visiting f)
    (save-restriction
      (widen)
      (save-excursion
        (goto-char (point-min))
        (let ((cnt (if (outline-on-heading-p) 1 0)))
          (while (outline-next-heading)
            (setq cnt (+ 1 cnt)))
          cnt)))))

(defun org-randomnote--get-randomnote-candidates ()
  "Remove empty files from `org-randomnote-candidates'."
  (-remove 'f-empty? org-randomnote-candidates))

(defun org-randomnote--random (seq)
  "Given an input sequence SEQ, return a random output."
  (let* ((cnt (length seq))
         (nmbr (random cnt)))
    (nth nmbr seq)))

(defun org-randomnote--get-random-file ()
  "Select a random file from `org-randomnote-candidates', weighted by the
number of headers within each candidate file."
  (let*
      ((cumulative-header-count-reversed
        (-reduce-from
         (lambda (acc x)
           (if (null acc)
               (list x)
             (cons (cons (car x) (+ (cdr x) (cdr (first acc))))
                   acc)))
         nil
         org-randomnote--file-to-header-count))
       (total-header-count (cdar cumulative-header-count-reversed))
       (cumulative-header-count (reverse
                                 cumulative-header-count-reversed)))
    (if (= total-header-count 0)
        ;; No headers in any files - choose any random file.
        (car (org-randomnote--random org-randomnote-candidates))
      (let* ((r (random total-header-count)))
        (car
         (-first
          (lambda (x) (< r (cdr x)))
          cumulative-header-count))))))

(defun org-randomnote--get-random-subtree (f match)
  "Get a random subtree satisfying Org match within an Org file F."
  (find-file f)
  (org-randomnote--random (org-map-entries (lambda () (line-number-at-pos)) match 'file)))

(defun org-randomnote--go-to-random-header (f match)
  "Given an Org file F, go to a random header satisfying Org match within that file."
  (org-goto-line (org-randomnote--get-random-subtree f match))
  (outline-show-all)
  (recenter-top-bottom 0))

(defun org-randomnote--with-indirect-buffer (f match)
  "Given an Org file F, go to a random header satisfying Org match within that file."
  (org-goto-line (org-randomnote--get-random-subtree f match))
  (org-tree-to-indirect-buffer)
  (switch-to-buffer (other-buffer)))

;;;###autoload
(defun org-randomnote (&optional match)
  "Go to a random note satisfying Org match within a random Org file."
  (interactive)
  (when (null org-randomnote--update-header-count-timer)
    ;; First update header count and block to ensure it's updated, then store
    ;; timer to repeat this every 30 seconds from now on.
    (org-randomnote--update-header-count)
    (setq org-randomnote--update-header-count-timer
          (run-at-time 30 30 #'org-randomnote--update-header-count)))
  (let* ((f (org-randomnote--get-random-file))
         (match (or match nil)))
    (cond ((eq org-randomnote-open-behavior 'default) (org-randomnote--go-to-random-header f match))
          ((eq org-randomnote-open-behavior 'indirect-buffer) (org-randomnote--with-indirect-buffer f match)))))

(provide 'org-randomnote)

;;; org-randomnote.el ends here
