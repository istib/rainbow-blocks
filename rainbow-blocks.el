;;; rainbow-blocks.el --- Block syntax highlighting for lisp code

;; Copyright (C) 2014 istib

;; Author: istib
;; URL: https://github.com/istib/rainbow-blocks
;; Version: 0.1
;; Package-Requires:
;; Keywords:

;; This file is not part of GNU Emacs

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Rainbow-blocks highlights blocks made of parentheses, brackets, and
;; braces according to their depth. Each successive level is
;; highlighted in a different color. This makes it easy to orient
;; yourself in the code, and tell which statements are at a given
;; level.


;;; Code:


(eval-when-compile (require 'cl))

(defgroup rainbow-blocks nil
  "Highlight nested parentheses, brackets, and braces according to their depth."
  :prefix "rainbow-blocks-"
  :group 'applications)

(defgroup rainbow-blocks-faces nil
  "Faces for successively nested pairs of blocks.

When depth exceeds innermost defined face, colors cycle back through."
  :tag "Color Scheme"
  :group 'rainbow-blocks
  :link '(custom-group-link "rainbow-blocks")
  :link '(custom-group-link :tag "Toggle Blocks" "rainbow-blocks-toggle-delimiter-highlighting")
  :prefix 'rainbow-blocks-faces-)

;; Choose which blocks you want to highlight in your preferred language:

(defgroup rainbow-blocks-toggle-delimiter-highlighting nil
  "Choose which blocks to highlight."
  :tag "Toggle Blocks"
  :group 'rainbow-blocks
  :link '(custom-group-link "rainbow-blocks")
  :link '(custom-group-link :tag "Color Scheme" "rainbow-blocks-faces"))

(defcustom rainbow-blocks-highlight-parens-p t
  "Enable highlighting of nested parentheses -- ().

Non-nil (default) enables highlighting of parentheses.
Nil disables parentheses highlighting."
  :tag "Highlight Parentheses?"
  :type 'boolean
  :group 'rainbow-blocks-toggle-delimiter-highlighting)

(defcustom rainbow-blocks-highlight-brackets-p t
  "Enable highlighting of nested brackets -- [].

Non-nil (default) enables highlighting of brackets.
Nil disables bracket highlighting."
  :tag "Highlight Brackets?"
  :type 'boolean
  :group 'rainbow-blocks-toggle-delimiter-highlighting)

(defcustom rainbow-blocks-highlight-braces-p t
  "Enable highlighting of nested braces -- {}.

Non-nil (default) enables highlighting of braces.
Nil disables brace highlighting."
  :tag "Highlight Braces?"
  :type 'boolean
  :group 'rainbow-blocks-toggle-delimiter-highlighting)


;;; Faces:

;; Unmatched delimiter face:
(defface rainbow-blocks-unmatched-face
  '((((background light)) (:foreground "#88090B"))
    (((background dark)) (:foreground "#88090B")))
  "Face to highlight unmatched closing blocks in."
  :group 'rainbow-blocks-faces)

;; Faces for highlighting blocks by nested level:
(defface rainbow-blocks-depth-1-face
  '((((background light)) (:foreground "#707183"))
    (((background dark)) (:foreground "grey55")))
  "Nested blocks face, depth 1 - outermost set."
  :tag "Rainbow Blocks Depth 1 Face -- OUTERMOST"
  :group 'rainbow-blocks-faces)

(defface rainbow-blocks-depth-2-face
  '((((background light)) (:foreground "#7388d6"))
    (((background dark)) (:foreground "#93a8c6")))
  "Nested blocks face, depth 2."
  :group 'rainbow-blocks-faces)

(defface rainbow-blocks-depth-3-face
  '((((background light)) (:foreground "#909183"))
    (((background dark)) (:foreground "#b0b1a3")))
  "Nested blocks face, depth 3."
  :group 'rainbow-blocks-faces)

(defface rainbow-blocks-depth-4-face
  '((((background light)) (:foreground "#709870"))
    (((background dark)) (:foreground "#97b098")))
  "Nested blocks face, depth 4."
  :group 'rainbow-blocks-faces)

(defface rainbow-blocks-depth-5-face
  '((((background light)) (:foreground "#907373"))
    (((background dark)) (:foreground "#aebed8")))
  "Nested blocks face, depth 5."
  :group 'rainbow-blocks-faces)

(defface rainbow-blocks-depth-6-face
  '((((background light)) (:foreground "#6276ba"))
    (((background dark)) (:foreground "#b0b0b3")))
  "Nested blocks face, depth 6."
  :group 'rainbow-blocks-faces)

(defface rainbow-blocks-depth-7-face
  '((((background light)) (:foreground "#858580"))
    (((background dark)) (:foreground "#90a890")))
  "Nested blocks face, depth 7."
  :group 'rainbow-blocks-faces)

(defface rainbow-blocks-depth-8-face
  '((((background light)) (:foreground "#80a880"))
    (((background dark)) (:foreground "#a2b6da")))
  "Nested blocks face, depth 8."
  :group 'rainbow-blocks-faces)

(defface rainbow-blocks-depth-9-face
  '((((background light)) (:foreground "#887070"))
    (((background dark)) (:foreground "#9cb6ad")))
  "Nested blocks face, depth 9."
  :group 'rainbow-blocks-faces)

;;; Faces 10+:
;; NOTE: Currently unused. Additional faces for depths 9+ can be added on request.

(defconst rainbow-blocks-max-face-count 9
  "Number of faces defined for highlighting delimiter levels.

Determines depth at which to cycle through faces again.")

(defvar rainbow-blocks-outermost-only-face-count 0
  "Number of faces to be used only for N outermost delimiter levels.

This should be smaller than `rainbow-blocks-max-face-count'.")

;;; Face utility functions

(defsubst rainbow-blocks-depth-face (depth)
  "Return face-name for DEPTH as a string 'rainbow-blocks-depth-DEPTH-face'.

For example: 'rainbow-blocks-depth-1-face'."
  (intern-soft
   (concat "rainbow-blocks-depth-"
           (number-to-string
            (or
             ;; Our nesting depth has a face defined for it.
             (and (<= depth rainbow-blocks-max-face-count)
                depth)
             ;; Deeper than # of defined faces; cycle back through to
             ;; `rainbow-blocks-outermost-only-face-count' + 1.
             ;; Return face # that corresponds to current nesting level.
             (+ 1 rainbow-blocks-outermost-only-face-count
                (mod (- depth rainbow-blocks-max-face-count 1)
                     (- rainbow-blocks-max-face-count
                        rainbow-blocks-outermost-only-face-count)))))
           "-face")))

;;; Nesting level

(defvar rainbow-blocks-syntax-table nil
  "Syntax table (inherited from buffer major-mode) which uses all blocks.


When rainbow-blocks-minor-mode is first activated, it sets this variable and
the other rainbow-blocks specific syntax tables based on the current
major-mode. The syntax table is constructed by the function
'rainbow-blocks-make-syntax-table'.")

;; syntax-table: used with syntax-ppss for determining current depth.
(defun rainbow-blocks-make-syntax-table (syntax-table)
  "Inherit SYNTAX-TABLE and add blocks intended to be highlighted by mode."
  (let ((table (copy-syntax-table syntax-table)))
    (modify-syntax-entry ?\( "()  " table)
    (modify-syntax-entry ?\) ")(  " table)
    (modify-syntax-entry ?\[ "(]" table)
    (modify-syntax-entry ?\] ")[" table)
    (modify-syntax-entry ?\{ "(}" table)
    (modify-syntax-entry ?\} "){" table)
    table))

(defsubst rainbow-blocks-depth (loc)
  "Return # of nested levels of parens, brackets, braces LOC is inside of."
  (let ((depth
         (with-syntax-table rainbow-blocks-syntax-table
           (car (syntax-ppss loc)))))
    (if (>= depth 0)
        depth
      0))) ; ignore negative depths created by unmatched closing parens.


;;; Text properties

;; Backwards compatibility: Emacs < v23.2 lack macro 'with-silent-modifications'.
(eval-and-compile
  (unless (fboundp 'with-silent-modifications)
    (defmacro with-silent-modifications (&rest body)
      "Defined by rainbow-blocks.el for backwards compatibility with Emacs < 23.2.
 Execute BODY, pretending it does not modify the buffer.
If BODY performs real modifications to the buffer's text, other
than cosmetic ones, undo data may become corrupted.

This macro will run BODY normally, but doesn't count its buffer
modifications as being buffer modifications.  This affects things
like buffer-modified-p, checking whether the file is locked by
someone else, running buffer modification hooks, and other things
of that nature.

Typically used around modifications of text-properties which do
not really affect the buffer's content."
      (declare (debug t) (indent 0))
      (let ((modified (make-symbol "modified")))
        `(let* ((,modified (buffer-modified-p))
                (buffer-undo-list t)
                (inhibit-read-only t)
                (inhibit-modification-hooks t)
                deactivate-mark
                ;; Avoid setting and removing file locks and checking
                ;; buffer's uptodate-ness w.r.t the underlying file.
                buffer-file-name
                buffer-file-truename)
           (unwind-protect
               (progn
                 ,@body)
             (unless ,modified
               (restore-buffer-modified-p nil))))))))

(defsubst rainbow-blocks-propertize-delimiter (loc depth)
  "Highlight a single delimiter at LOC according to DEPTH.

LOC is the location of the character to add text properties to.
DEPTH is the nested depth at LOC, which determines the face to use.

Sets text properties:
`font-lock-face' to the appropriate delimiter face.
`rear-nonsticky' to prevent color from bleeding into subsequent characters typed by the user."
  (with-silent-modifications
    (let* ((delim-face (if (<= depth 0)
                           'rainbow-blocks-unmatched-face
                         (rainbow-blocks-depth-face depth)))
           (end-pos    (save-excursion (goto-char loc)
                                    (forward-sexp)
                                    (point))))
      (add-text-properties loc end-pos
                           `(font-lock-face ,delim-face
                                            rear-nonsticky t)))))


(defsubst rainbow-blocks-unpropertize-delimiter (loc)
  "Remove text properties set by rainbow-blocks mode from char at LOC."
  ;; (let ((end-pos (save-excursion (goto-char loc) (forward-sexp) (point))))
  (let ((end-pos (1+ loc)))
    (with-silent-modifications
      (remove-text-properties loc end-pos
                              '(font-lock-face nil
                                               rear-nonsticky nil)))))

(defvar rainbow-blocks-escaped-char-predicate nil)
(make-variable-buffer-local 'rainbow-blocks-escaped-char-predicate)

(defvar rainbow-blocks-escaped-char-predicate-list
  '((emacs-lisp-mode          . rainbow-blocks-escaped-char-predicate-emacs-lisp)
    (inferior-emacs-lisp-mode . rainbow-blocks-escaped-char-predicate-emacs-lisp)
    (lisp-mode                . rainbow-blocks-escaped-char-predicate-lisp)
    (scheme-mode              . rainbow-blocks-escaped-char-predicate-lisp)
    (clojure-mode             . rainbow-blocks-escaped-char-predicate-lisp)
    (inferior-scheme-mode     . rainbow-blocks-escaped-char-predicate-lisp)
    ))

(defun rainbow-blocks-escaped-char-predicate-emacs-lisp (loc)
  (or (and (eq (char-before loc) ?\?) ; e.g. ?) - deprecated, but people use it
           (not (and (eq (char-before (1- loc)) ?\\) ; special case: ignore ?\?
                     (eq (char-before (- loc 2)) ?\?))))
      (and (eq (char-before loc) ?\\) ; escaped char, e.g. ?\) - not counted
           (eq (char-before (1- loc)) ?\?))))

(defun rainbow-blocks-escaped-char-predicate-lisp (loc)
  (eq (char-before loc) ?\\))

(defsubst rainbow-blocks-char-ineligible-p (loc)
  "Return t if char at LOC should be skipped, e.g. if inside a comment.

Returns t if char at loc meets one of the following conditions:
- Inside a string.
- Inside a comment.
- Is an escaped char, e.g. ?\)"
  (let ((parse-state (syntax-ppss loc)))
    (or
     (nth 3 parse-state)                ; inside string?
     (nth 4 parse-state)                ; inside comment?
     (and rainbow-blocks-escaped-char-predicate
          (funcall rainbow-blocks-escaped-char-predicate loc)))))


(defun rainbow-blocks-apply-color (delim depth loc)
  "Apply color for DEPTH to DELIM at LOC following user settings.

DELIM is a string specifying delimiter type.
DEPTH is the delimiter depth, or corresponding face # if colors are repeating.
LOC is location of character (delimiter) to be colorized."
  (and
   ;; Ensure user has enabled highlighting of this delimiter type.
   (symbol-value (intern-soft
                  (concat "rainbow-blocks-highlight-" delim "s-p")))
   (rainbow-blocks-propertize-delimiter loc
                                        depth)))


;;; JIT-Lock functionality

;; Used to skip delimiter-by-delimiter `rainbow-blocks-propertize-region'.
(defconst rainbow-blocks-delim-regex "\\(\(\\|\)\\|\\[\\|\\]\\|\{\\|\}\\)"
  "Regex matching all opening and closing delimiters the mode highlights.")

;; main function called by jit-lock:
(defun rainbow-blocks-propertize-region (start end)
  "Highlight blocks in region between START and END.

Used by jit-lock for dynamic highlighting."
  (setq rainbow-blocks-escaped-char-predicate
        (cdr (assoc major-mode rainbow-blocks-escaped-char-predicate-list)))
  (save-excursion
    (goto-char start)
    ;; START can be anywhere in buffer; determine the nesting depth at START loc
    (let ((depth (rainbow-blocks-depth start)))
      (while (and (< (point) end)
                  (re-search-forward rainbow-blocks-delim-regex end t))
        (backward-char) ; re-search-forward places point after delim; go back.
        (unless (rainbow-blocks-char-ineligible-p (point))
          (let ((delim (char-after (point))))
            (cond ((eq ?\( delim)
                   (setq depth (1+ depth))
                   (rainbow-blocks-apply-color "paren" depth (point)))
                  ((eq ?\) delim)
                   ;;(rainbow-blocks-apply-color "paren" depth (point))
                   (setq depth (or (and (<= depth 0) 0) ; unmatched paren
                                   (1- depth))))
                  ((eq ?\[ delim)
                   (setq depth (1+ depth))
                   (rainbow-blocks-apply-color "bracket" depth (point)))
                  ((eq ?\] delim)
                   ;;(rainbow-blocks-apply-color "bracket" depth (point))
                   (setq depth (or (and (<= depth 0) 0) ; unmatched bracket
                                   (1- depth))))
                  ((eq ?\{ delim)
                   (setq depth (1+ depth))
                   (rainbow-blocks-apply-color "brace" depth (point)))
                  ((eq ?\} delim)
                   ;;(rainbow-blocks-apply-color "brace" depth (point))
                   (setq depth (or (and (<= depth 0) 0) ; unmatched brace
                                   (1- depth)))))))
        ;; move past delimiter so re-search-forward doesn't pick it up again
        (forward-char)))))

(defun rainbow-blocks-unpropertize-region (start end)
  "Remove highlighting from blocks between START and END."
  (save-excursion
    (set-text-properties (point-min) (point-max) nil)
    (goto-char start)
    (while (and (< (point) end)
                (re-search-forward rainbow-blocks-delim-regex end t))
      ;; re-search-forward places point 1 further than the delim matched:
      (rainbow-blocks-unpropertize-delimiter (1- (point))))))


;;; Minor mode:

;;;###autoload
(define-minor-mode rainbow-blocks-mode
  "Highlight nested parentheses, brackets, and braces according to their depth."
  nil " Blocks" nil ; No modeline lighter - it's already obvious when the mode is on.
  (if (not rainbow-blocks-mode)
      (progn
        (jit-lock-unregister 'rainbow-blocks-propertize-region)
        (rainbow-blocks-unpropertize-region (point-min) (point-max)))
    (jit-lock-register 'rainbow-blocks-propertize-region t)
    ;; Create necessary syntax tables inheriting from current major-mode.
    (set (make-local-variable 'rainbow-blocks-syntax-table)
         (rainbow-blocks-make-syntax-table (syntax-table)))))

;;;###autoload
(defun rainbow-blocks-mode-enable ()
  (rainbow-blocks-mode 1))

;;;###autoload
(defun rainbow-blocks-mode-disable ()
  (rainbow-blocks-mode 0))

;;;###autoload
(define-globalized-minor-mode global-rainbow-blocks-mode
  rainbow-blocks-mode rainbow-blocks-mode-enable)

(provide 'rainbow-blocks)

;;; rainbow-blocks.el ends here
