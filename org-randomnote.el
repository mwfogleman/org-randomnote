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

(defvar org-randomnote-candidates org-agenda-files)

;; depends on f.el
;; https://github.com/rejeep/f.el

;; TODO: Check if selected candidate is empty

(defun file-empty-p (f)
  (= (f-size f) 0))

(defun org-randomnote-get-randomnote-candidates ()
  (-remove 'file-empty-p org-randomnote-candidates))

(defun org-go-to-header ()
  (when (equal major-mode 'org-mode)
    (if (org-at-heading-p)
	(org-beginning-of-line)
      (org-up-element))))

(defun org-get-random-file ()
  (let* ((cands (org-randomnote-get-randomnote-candidates))
	 (cnt (length org-randomnote-list))
	 (nmbr (random cnt)))
    (nth nmbr cands)))

(defun org-go-to-random-header (f)
  (find-file f)
  (let* ((l (random (count-lines (point-min) (point-max)))))
    (goto-line l)
    (org-go-to-header)
    (outline-show-all)
    (recenter-top-bottom 0)))

(defun org-randomnote ()
  (interactive)
  (org-go-to-random-header (org-get-random-file)))

;; Bugs:
;; find-file-noselect: Wrong type argument: stringp, nil

;; Snippets
;; (when (org-at-drawer-p)
;;   (org-go-to-header))

;; (org-tree-to-indirect-buffer)
;; (switch-to-buffer (other-buffer))

(provide 'org-randomnote)

;;; org-randomnote.el ends here
