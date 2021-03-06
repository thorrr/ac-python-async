;;; ac-python-async.el --- Simple Python Completion Source for Auto-Complete

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; Simple Python Completion Source for Auto-Complete
;;;;; =================================================
;;;;;
;;;;; This file provides a completion source for Auto-Complete:
;;;;; http://www.emacswiki.org/emacs/AutoComplete
;;;;;
;;;;; It is derived from the excellent ac-python by Chris Poole, downloadable from
;;;;; http://chrispoole.com/downloads/ac-python.el
;;;;;
;;;;; Keywords: vc tools
;;;;; Package: ac-python-async
;;;;; Package-Requires: ((auto-complete "1.5.0") (deferred "20150309.2052"))
;;;;;
;;;;; Installation
;;;;; ------------
;;;;; 
;;;;; Setup Auto-Complete in the usual fashion, and make sure it gets loaded for
;;;;; python buffers. Then, place this file in your load-path, and add
;;;;; 
;;;;;     (require 'ac-python-async)
;;;;; 
;;;;; to your .emacs file (after loading Auto-Complete).
;;;;; 
;;;;; Improves upon the original ac-python by evaluating the auto-complete string
;;;;; asynchronously, using the deferred library to run the completion in a separate emacs
;;;;; process.  This substantially reduces lag as the editor constantly attempts
;;;;; auto-complete as the cursor moves around the buffer.
;;;;; 
;;;;; Usage
;;;;; -----
;;;;; 
;;;;; Python symbols will be completed by Auto-Complete, once Emacs learns about
;;;;; these symbols. This is the short-coming of the plugin, but it's a small
;;;;; price to pay.
;;;;; 
;;;;; To teach Emacs about symbols in imported modules, Emacs needs to execute
;;;;; the Python source. This can be accomplished with `python-send-buffer` for
;;;;; example, often bound to `C-c C-c`. If a python process is already running,
;;;;; this is essentially instantaneous.
;;;;;
;;;;; ---
;;;;;
;;;;; Version: 20170425
;;;;; License: MIT
;;;;; Author: Jason Bell  <jbellthor@gmail.com>
;;;;;
;;;;; Based on ac-python by Chris Poole:
;;;;;
;;;;;     <chris@chrispoole.com>
;;;;;     More information: http://chrispoole.com/project/ac-python
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; Code:

(require 'auto-complete)
(require 'deferred)
(require 'python)

(defcustom ac-python-async:get-completion-process (lambda ()
  (python-shell-get-process))
  "By default this uses (python-shell-get-process) to get the
autocompete process.  Override this if you want to use something
else" 
  :type 'function)


(defvar ac-python-async:last-completion nil)
(defvar ac-python-async:pos -1)
 
(defun ac-python-async:completion-request ()
  "spin up a request for auto-completion.  This goes into the init section"
  (setq ac-python-async:pos (point))
  (deferred:$
    (deferred:next (lambda ()
      (ac-python-async:completion-at-point)))
    (deferred:nextc it
      (lambda (reply)
        ;; reply is a list of completion candidates
        (setq ac-python-async:last-completion reply)))))
 
(defun ac-python-async:direct-matches ()
  "parse last-completion to generate matches auto-complete can
   consume, but only if the point hasn't moved from where it
   started"
  (if (= ac-python-async:pos (point))
      ac-python-async:last-completion
    nil))

(defun ac-python-async:get-ac-help (symbol-with-properties)
  (message-no-echo (concat "get-ac-help(" symbol-with-properties ")"))
    (let* ((plain-symbol (substring-no-properties symbol-with-properties))
         (symbol (if (string-suffix-p "(" plain-symbol)
                     (substring plain-symbol 0 -1)  ;; cut off parenthesis
                   plain-symbol))
         (process (funcall ac-python-async:get-completion-process))
         (eldoc
          (python-shell-send-string-no-output
           (format (concat
                    "import pydoc;\n"
                    "try:\n"
                    "  a = pydoc.plain(pydoc.render_doc(%s, '%s'))[0:1600]\n"  ;;limit to approx 80x20
                    "  print(a)\n"
                    "except:\n"
                    "  print('')") symbol "%s" ;;second argument to render_doc is a %s
                   )
           process)
          ;;(python-eldoc-at-point symbol) ;; simple built-in eldoc
          ))
      (if eldoc eldoc "")))

(defun ac-python-async:start-of-expression ()
  "Return point of the start of python expression at point.
   Assumes symbol can be alphanumeric, `.' or `_'."
  (save-excursion
    (and (re-search-backward
          (rx (or buffer-start (regexp "[^[:alnum:]._]"))
              (group (1+ (regexp "[[:alnum:]._]"))) point)
          nil t)
         (match-beginning 1))))

(defun python-symbol-completions (symbol)
  "Adapter to make ac-python work with builtin emacs python mode (by gallina)"
  (let* ((process (funcall ac-python-async:get-completion-process))
         (whole-line (if (> emacs-major-version 24) nil
                       (buffer-substring-no-properties (line-beginning-position) (line-end-position))))
         (psc (python-shell-completion-get-completions
               process
               whole-line ;; in emacs 25, this is the 'import' argument which should be held nil
               symbol)))
    (if psc psc "")))
 
(defun ac-python-async:get-python-symbol-at-point ()
  "Return python symbol at point.
   Assumes symbol can be alphanumeric, `.' or `_'."
  (let* ((end (point))
         (start (ac-python-async:start-of-expression))
         (out (if (not start) nil
                (buffer-substring-no-properties start end))))
    (if out out "")))
 
 
(defun ac-python-async:completion-at-point ()
  "Returns a possibly empty list of completions for the symbol at
point."
  (python-symbol-completions (ac-python-async:get-python-symbol-at-point)))
 
 
(defvar ac-source-python-async
  '(
    (init . ac-python-async:completion-request)
    (candidates . ac-python-async:direct-matches)
    (prefix . ac-python-async:start-of-expression)
    (symbol . "f")  ;; TOOD - not every completion is a function type.  parse type(<symbol>)
    (document . ac-python-async:get-ac-help)
    (cache)
    (requires . 2))
  "Source for python completion.")
 
(add-hook 'python-mode-hook (lambda () (add-to-list 'ac-sources 'ac-source-python-async)))
 
(provide 'ac-python-async)
;;; ac-python-async.el ends here
