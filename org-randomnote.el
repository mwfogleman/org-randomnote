;;; org-randomnote.el --- Find a random note in your Org-Mode files

;; Copyright (C) 2017 Michael Fogleman

;; Author: Michael Fogleman <michaelwfogleman@gmail.com>
;; URL: http://github.com/mwfogleman/org-randomnote
;; Package-Requires: ((f "0.19.0") (dash "2.12.0"))

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

(defvar org-randomnote-candidates org-agenda-files
  "The files that org-randomnote will draw from in finding a random note.  Defaults to `org-agenda-files'.")

(defvar org-randomnote-open-behavior 'default
  "Configure the behavior that org-randomnote uses to open a random note.  Set to `default' or `indirect-buffer'.")

(defun f-empty? (f)
  "Check if a file F is empty."
  (= (f-size f) 0))

(defun org-randomnote--go-to-header ()
  "Go to a header in an Org file."
  (when (equal major-mode 'org-mode)
    (if (org-at-heading-p)
	(beginning-of-line)
      (outline-previous-heading))))

(defun org-randomnote--get-randomnote-candidates ()
  "Remove empty files from `org-randomnote-candidates'."
  (-remove 'f-empty? org-randomnote-candidates))

(defun org-randomnote--get-random-file ()
  "Select a random file from `org-randomnote-candidates'."
  (let* ((cands (org-randomnote--get-randomnote-candidates))
	 (cnt (length cands))
	 (nmbr (random cnt)))
    (nth nmbr cands)))

(defun org-randomnote--go-to-random-line (f)
  "Go to a random line within an Org file F."
  (find-file f)
  (let* ((l (random (count-lines (point-min) (point-max)))))
    (org-goto-line l)))

(defun org-randomnote--go-to-random-header (f)
  "Given an Org file F, go to a random header within that file."
  (org-randomnote--go-to-random-line f)
  (org-randomnote--go-to-header)
  (outline-show-all)
  (recenter-top-bottom 0))

(defun org-randomnote--with-indirect-buffer (f)
  "Given an Org file F, go to a random header within that file."
  (org-randomnote--go-to-random-line f)
  (org-randomnote--go-to-header)
  (org-tree-to-indirect-buffer)
  (switch-to-buffer (other-buffer)))

(defun org-randomnote ()
  "Go to a random note within a random Org file."
  (interactive)
  (let* ((f (org-randomnote--get-random-file)))
    (cond ((eq org-randomnote-open-behavior 'default) (org-randomnote--go-to-random-header f))
	  ((eq org-randomnote-open-behavior 'indirect-buffer) (org-randomnote--with-indirect-buffer f)))))

(provide 'org-randomnote)

;;; org-randomnote.el ends here
