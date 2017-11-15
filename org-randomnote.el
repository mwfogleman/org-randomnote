;;; org-randomnote.el --- Find a random note in your Org-Mode files

;; Copyright (C) 2017 Michael Fogleman

;; Author: Michael Fogleman <michaelwfogleman@gmail.com>
;; URL: http://github.com/mwfogleman/org-randomnote
;; Package-Requires: ((f "0.19.0") (dash "2.13.0"))

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

(defvar org-randomnote-candidates org-agenda-files)

(defun f-empty? (f)
  "Check if a file F is empty."
  (= (f-size f) 0))

(defun org-randomnote--go-to-header ()
  "Go to a header in an Org file."
  (when (equal major-mode 'org-mode)
    (if (org-at-heading-p)
	(org-beginning-of-line)
      (org-up-element))))

(defun org-randomnote--get-randomnote-candidates ()
  "Remove empty files from `org-randomnote-candidates'."
  (-remove 'f-empty? org-randomnote-candidates))

(defun org-randomnote--get-random-file ()
  "Select a random file from `org-randomnote-candidates'."
  (let* ((cands (org-randomnote--get-randomnote-candidates))
	 (cnt (length cands))
	 (nmbr (random cnt)))
    (nth nmbr cands)))

(defun org-randomnote--get-random-line ()
  "Get a random line within the current file."
  (random (count-lines (point-min) (point-max))))

(defun org-randomnote--go-to-random-header (f)
  "Given a file F, go to a random header within that file."
  (find-file f)
  (let* ((l (org-randomnote--get-random-line)))
    (org-goto-line l)
    (org-randomnote--go-to-header)
    (outline-show-all)
    (recenter-top-bottom 0)))

(defun org-randomnote ()
  "Go to a random note within a random Org file."
  (interactive)
  (org-randomnote--go-to-random-header (org-randomnote--get-random-file)))

;; Bugs:
;; find-file-noselect: Wrong type argument: stringp, nil

;; Snippets
;; (when (org-at-drawer-p)
;;   (org-randomnote--go-to-header))

;; (org-tree-to-indirect-buffer)
;; (switch-to-buffer (other-buffer))

(provide 'org-randomnote)

;;; org-randomnote.el ends here
