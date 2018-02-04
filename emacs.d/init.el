(when (>= emacs-major-version 24)
  (require 'package)
  (add-to-list
   'package-archives
   '("melpa" . "http://melpa.org/packages/")
   t)
  (package-initialize))

(when (memq window-system '(mac ns))
  (exec-path-from-shell-initialize))
(add-to-list 'load-path "~/.emacs.d/ext")
(setq ispell-program-name "/usr/local/bin/aspell")
(defun my/->string (str)
  (cond
   ((stringp str) str)
   ((symbolp str) (symbol-name str))))

(defun my/->mode-hook (name)
  "Turn mode name into hook symbol"
  (intern (replace-regexp-in-string "\\(-mode\\)?\\(-hook\\)?$"
                                    "-mode-hook"
                                    (my/->string name))))

(defun my/->mode (name)
  "Turn mode name into mode symbol"
  (intern (replace-regexp-in-string "\\(-mode\\)?$"
                                    "-mode"
                                    (my/->string name))))

(defun my/set-modes (arg mode-list)
  (dolist (m mode-list)
    (funcall (my/->mode m) arg)))

(defun my/turn-on (&rest mode-list)
  "Turn on the given (minor) modes."
  (my/set-modes +1 mode-list))

(defvar my/normal-base-modes
  (mapcar 'my/->mode '(text prog))
  "The list of modes that are considered base modes for
  programming and text editing. In an ideal world, this should
  just be text-mode and prog-mode, however, some modes that
  should derive from prog-mode derive from fundamental-mode
  instead. They are added here.")

(defun my/normal-mode-hooks ()
  "Returns the mode-hooks for `my/normal-base-modes`"
  (mapcar 'my/->mode-hook my/normal-base-modes))

(setq backup-directory-alist `(("." . "~/.saves")))
(setq backup-by-copying t)
(setq delete-old-versions t
  kept-new-versions 6
  kept-old-versions 2
  version-control t)
(setq make-backup-files nil)

(setq custom-file "~/.emacs.d/custom.el")
(load custom-file)
(load-theme 'zenburn)

(custom-set-faces
  '(magit-diff-none ((t (:foreground "white"))))
  '(magit-item-highlight ((t (:background "grey44"))))
  '(minibuffer-prompt ((t (:foreground "brown"))))
  '(cursor ((t (:background "magenta1" :foreground "magenta")))))

;; default window width and height
(defun custom-set-frame-size ()
  (add-to-list 'default-frame-alist '(height . 45))
  (add-to-list 'default-frame-alist '(width . 110)))
(custom-set-frame-size)
(add-hook 'before-make-frame-hook 'custom-set-frame-size)

(set-face-attribute 'default nil
                    :family "Inconsolata"
                    :height 120
                    :weight 'normal
                    :width 'normal)

(when (functionp 'set-fontset-font)
  (set-fontset-font "fontset-default"
                    'unicode
                    (font-spec :family "DejaVu Sans Mono"
                               :width 'normal
                               :size 12.4
                               :weight 'normal)))

(when (window-system)
  (tool-bar-mode -1)
  (scroll-bar-mode -1))
(when (not (window-system))
  (menu-bar-mode -1))
(when (window-system)
  (require 'git-gutter-fringe)
  (global-git-gutter-mode +1))

(setq-default indicate-buffer-boundaries 'left)
(setq-default indicate-empty-lines +1)

(setq redisplay-dont-pause t
      scroll-margin 1
      scroll-step 1
      scroll-conservatively 10000
      scroll-preserve-screen-position 1)
(setq mouse-wheel-follow-mouse 't)
(setq mouse-wheel-scroll-amount '(1 ((shift) . 1)))
(require 'uniquify)
(setq uniquify-buffer-name-style 'forward)

(when (not (window-system))
  (xterm-mouse-mode +1))

(setq-default indent-tabs-mode nil)

(defun my/clean-buffer-formatting ()
  "Indent and clean up the buffer"
  (interactive)
  (indent-region (point-min) (point-max))
  (whitespace-cleanup))

(global-set-key "\C-cn" 'my/clean-buffer-formatting)

(defun my/general-formatting-hooks ()
  (setq show-trailing-whitespace 't))

(dolist (mode-hook (my/normal-mode-hooks))
  (add-hook mode-hook 'my/general-formatting-hooks))
(defun my/text-formatting-hooks ()
  (my/turn-on 'auto-fill)) ; turn on automatic hard line wraps

(add-hook 'text-mode-hook
          'my/text-formatting-hooks)

(add-hook 'after-init-hook #'global-flycheck-mode)

(add-hook 'before-save-hook 'delete-trailing-whitespace)

'(show-paren-mode t)
(add-hook 'after-init-hook #'show-paren-mode)

(define-minor-mode my/pair-programming-mode
  "Toggle visualizations for pair programming.
Interactively with no argument, this command toggles the mode.  A
positive prefix argument enables the mode, any other prefix
argument disables it.  From Lisp, argument omitted or nil enables
the mode, `toggle' toggles the state.

This turns on hightlighting the current line, line numbers and
command-log-mode."
  ;; The initial value.
  nil
  ;; The indicator for the mode line.
  " Pairing"
  ;; The minor mode bindings.
  '()
  :group 'my/pairing
  (my/set-modes (if my/pair-programming-mode 1 -1)
                '(linum hl-line command-log)))

(define-global-minor-mode my/global-pair-programming-mode
  my/pair-programming-mode
  (lambda () (my/pair-programming-mode 1)))

(global-set-key "\C-c\M-p" 'my/global-pair-programming-mode)
(setq my/lisps
      '(emacs-lisp lisp clojure))

(add-to-list 'auto-mode-alist '("\\.js\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.jsx$" . web-mode))

;; (defadvice web-mode-highlight-part (around tweak-jsx activate)
;;    (if (equal web-mode-content-type "jsx")
;;       (let ((web-mode-enable-part-face nil))
;;         ad-do-it)
;;      ad-do-it))

;; 3/25 the highlighting in the return markup section went away without this:
(setq web-mode-content-types-alist
  '(("jsx" . "\\.js[x]?\\'")))

(setq js2-basic-offset 2)

(defun my-console-log ()
   "Insert empty console log statement."
   (interactive)
   (insert "console.log('',);")
   (backward-char 4)
   (js2-indent-line))

(global-set-key (kbd "C-x C-1") 'my-console-log)

(defun my-anon-function ()
   "Insert empty anonymous function."
   (interactive)
   (insert "function () {};")
   (backward-char 2)
   (js2-indent-line))

(global-set-key (kbd "C-x C-2") 'my-anon-function)
(add-to-list 'auto-mode-alist '("\\.groovy\\'" . groovy-mode))
(add-to-list 'auto-mode-alist '("\\.json\\'\\|\\.jshintrc\\'" . js-mode))
(require 'ansi-color)
(defun colorize-compilation-buffer ()
  (toggle-read-only)
  (ansi-color-apply-on-region (point-min) (point-max))
  (toggle-read-only))
(add-hook 'compilation-filter-hook 'colorize-compilation-buffer)
(add-hook 'shell-mode-hook 'ansi-color-for-comint-mode-on)
(setq compilation-scroll-output t)
;; (require 'fuzzy)
;; (require 'auto-complete)
;; (setq ac-auto-show-menu t
;;       ac-quick-help-delay 0.5
;;       ac-use-fuzzy t)
;; (global-auto-complete-mode +1)

(global-set-key "\C-cg" 'magit-status)
(global-set-key (kbd "C-c b") 'magit-blame-mode)
(global-set-key "\C-cq" 'delete-indentation)
(defun my/edit-emacs-configuration ()
  (interactive)
  (find-file "~/.emacs.d/emacs.org"))

(global-set-key "\C-ce" 'my/edit-emacs-configuration)

(setq ido-enable-flex-matching t)
(ido-mode +1)
(ido-yes-or-no-mode +1)

(setq inhibit-startup-screen +1)
(when (memq window-system '(mac ns))
  (exec-path-from-shell-initialize))

(defun my/->string (str)
  (cond
   ((stringp str) str)
   ((symbolp str) (symbol-name str))))

(defun my/->mode-hook (name)
  "Turn mode name into hook symbol"
  (intern (replace-regexp-in-string "\\(-mode\\)?\\(-hook\\)?$"
                                    "-mode-hook"
                                    (my/->string name))))

(defun my/->mode (name)
  "Turn mode name into mode symbol"
  (intern (replace-regexp-in-string "\\(-mode\\)?$"
                                    "-mode"
                                    (my/->string name))))

(defun my/set-modes (arg mode-list)
  (dolist (m mode-list)
    (funcall (my/->mode m) arg)))

(defun my/turn-on (&rest mode-list)
  "Turn on the given (minor) modes."
  (my/set-modes +1 mode-list))

(defvar my/normal-base-modes
  (mapcar 'my/->mode '(text prog))
  "The list of modes that are considered base modes for
  programming and text editing. In an ideal world, this should
  just be text-mode and prog-mode, however, some modes that
  should derive from prog-mode derive from fundamental-mode
  instead. They are added here.")

(defun my/normal-mode-hooks ()
  "Returns the mode-hooks for `my/normal-base-modes`"
  (mapcar 'my/->mode-hook my/normal-base-modes))

(setq backup-directory-alist `(("." . "~/.saves")))
(setq backup-by-copying t)
(setq delete-old-versions t
  kept-new-versions 6
  kept-old-versions 2
  version-control t)
(setq make-backup-files nil)

(when (memq window-system '(mac ns))
  (exec-path-from-shell-initialize))

(add-to-list 'load-path "~/.emacs.d/ext")

(setq ispell-program-name "/usr/local/bin/aspell")
(put 'narrow-to-region 'disabled nil)
