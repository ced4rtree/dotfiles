;; -*- lexical-binding: t -*-

;; use-package stuff
(require 'use-package-ensure)
(setq use-package-always-ensure t)

;; register melpa
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

;; ui improvements
(setopt modus-themes-italic-constructs t
        modus-themes-bold-constructs t
        modus-themes-mixed-fonts t
        modus-themes-completions
        '((matches . (underline italic))
          (selection . (extrabold))))
(load-theme 'modus-vivendi-tinted t)
(setopt mode-line-end-spaces nil)
(set-display-table-slot standard-display-table 'vertical-border (make-glyph-code ?│))
(menu-bar-mode -1)
(scroll-bar-mode -1)
(tool-bar-mode -1)
(add-to-list 'default-frame-alist '(font . "JetBrainsMono Nerd Font-11"))
(add-to-list 'default-frame-alist '(alpha-background . 75))
(pixel-scroll-precision-mode t)

;; flash modeline instead of the screen
(setq visible-bell t
      ring-bell-function
      (lambda ()
        (let ((orig-bg (face-background 'mode-line)))
          (set-face-background 'mode-line "brown1")
          (run-with-idle-timer 0.1 nil
                               (lambda (bg) (set-face-background 'mode-line bg))
                               orig-bg))))

;; completion
(use-package vertico
  :ensure marginalia
  :ensure vertico-prescient
  :ensure prescient
  :ensure vertico-posframe
  :ensure orderless
  :ensure t

  :commands (vertico-mode
             marginalia-mode
             vertico-prescient-mode
             prescient-persist-mode
             vertico-posframe-mode
             vertico-directory-enter
             vertico-directory-delete-char
             vertico-directory-delete-word
             vertico-directory-tidy)
  :defines vertico-map

  :demand t
  :config
  (vertico-mode)
  (vertico-prescient-mode)
  (prescient-persist-mode)
  (marginalia-mode)
  (vertico-posframe-mode)

  (require 'vertico-directory)
  (keymap-set vertico-map "RET" #'vertico-directory-enter)
  (keymap-set vertico-map "DEL" #'vertico-directory-delete-char)
  (keymap-set vertico-map "M-DEL" #'vertico-directory-delete-word)
  (add-hook 'rfn-eshadow-update-overlay-hook #'vertico-directory-tidy)

  :custom
  (vertico-cycle t))
(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))

;; automatically pair parentheses, braces, quotes, etc.
(electric-pair-mode t)

;; line numbers
(add-hook 'prog-mode-hook #'display-line-numbers-mode)

;; fun squigglies
(add-hook 'prog-mode-hook #'flymake-mode-on)

;; just have y-or-n not yes-or-no
(defalias #'yes-or-no-p #'y-or-n-p)

;; hideshow mode
(with-eval-after-load 'hideshow
  (add-hook 'prog-mode-hook #'hs-minor-mode))

;; mu4e
(use-package mu4e
  :ensure nil
  :load-path "/usr/share/emacs/site-lisp/mu4e"

  :custom
  (smtpmail-stream-type 'starttls) ;; use tls for encryption
  (mu4e-change-filenames-when-moving t) ;; update file names as you move them around
  (mu4e-update-interval (* 10 60)) ;; update email every 10 minutes
  (mu4e-hide-index-messages t) ;; stop flashing my email to everyone around me
  (mu4e-get-mail-command "mbsync -a") ;; requires isync to be installed and configured for your emails

  :config
  (load (concat user-emacs-directory "emails.el")))

;; password decryption (for mbsync)
(defun efs/lookup-password (&rest keys)
  "Lookup a password from ~/.authinfo.gpg using KEYS to index the desired password.

e.g. (efs/lookup-password :host \"example.com\" :user \"user\"), which
will find the password for user@example.com"

  (let ((result (apply #'auth-source-search keys)))
    (when result
        (funcall (plist-get (car result) :secret)))))

;; tab bar mode
(tab-bar-mode t)
(setq tab-bar-show 1
      tab-bar-close-button-show nil
      tab-bar-format '(tab-bar-format-tabs tab-bar-separator tab-bar-format-align-right tab-bar-format-global))

(defun cedar/tab-name (tab)
  "Returns the name of TAB as a string."
  (cdr (assoc-string 'name tab)))

(defun cedar/open-name-in-tab (name always-perform-callback callback &rest callback-args)
  "Open/create a tab called NAME, and call CALLBACK upon opening.

If NAME is already a tab that exists, switch to it.  If there's not a
tab with the name NAME, then create a new tab with the name NAME and
call CALLBACK with the optionally supplied CALLBACK-ARGS.

If ALWAYS-PERFORM-CALLBACK is t, CALLBACK will always be performed with
its arguments, even if NAME is already an existing tab."

  (if (and (eq (length (tab-bar-tabs)) 1)
           (string-equal (cedar/tab-name (car (tab-bar-tabs))) "*scratch*"))
      (progn
        (tab-rename name)
        (apply callback callback-args))
    (let* ((tab-names (mapcar #'cedar/tab-name (tab-bar-tabs))))
      (if (and (member name tab-names) (not always-perform-callback))
          (tab-bar-switch-to-tab name)
        (progn
          (tab-bar-switch-to-tab name)
          (apply callback callback-args))))))

;; project.el and tab-bar-mode integration
(use-package project
  :ensure nil
  :commands (project-prompt-project-dir)
  :config
  (defun cedar/project-switch-project-tab ()
    "Switch to a project tab, or create one if the prompted project doesn't exist."
    (interactive)
    (let* ((project-name (project-prompt-project-dir)))
      (cedar/open-name-in-tab project-name nil 'project-switch-project project-name)))

  (defun cedar/project-kill-buffers-and-tab ()
    "Kill all buffers in the current project and close the current tab."
    (interactive)
    (project-kill-buffers)
    (tab-bar-close-tab))
  :bind (("C-x p p" . cedar/project-switch-project-tab)
         ("C-x p k" . cedar/project-kill-buffers-and-tab)))

;; emms
(use-package emms
  :ensure nil
  :commands (emms-all emms-smart-browse)
  :defines emms-playlist-mode-map
  :custom
  (emms-seek-seconds 5)
  (emms-player-list '(emms-player-mpv))
  (emms-info-functions '(emms-info-native))

  :config
;;; (setq emms-player-mpd-music-directory (concat (getenv "HOME") "/Music"))
;;; (setq emms-player-mpd-server-name "localhost")
;;; (setq emms-player-mpd-server-port "6600")
;;; (setq mpc-host "localhost:6600")
  (require 'emms-setup)
  (emms-all)

  (defun cedar/emms-smart-browse-in-tab ()
    (interactive)
    (cedar/open-name-in-tab "EMMS (Music)" t #'emms-smart-browse))

  :bind (("C-c m t" . emms-pause) ;; t for toggle
         ("C-c m n" . emms-next)
         ("C-c m p" . emms-previous)
         ("C-c m m" . cedar/emms-smart-browse-in-tab)
         :map emms-playlist-mode-map
         ("Z" . emms-shuffle)))

;; move backup files
(setq backup-directory-alist '((".*" . "~/.cache/emacs/auto-saves")))
(setq auto-save-file-name-transforms '((".*" "~/.cache/emacs/auto-saves" t)))

;; let me use the mouse in emacs pwetty pwease
(xterm-mouse-mode 1)

;; which-key
(which-key-mode t)

;; scrolling
;;; scroll one line at a time (less "jumpy" than defaults)
(setq mouse-wheel-scroll-amount '(1 ((shift) . 1)) ;; 1 line at a time
      mouse-wheel-progressive-speed nil ;; don't accelerate scrolling
      mouse-wheel-follow-mouse 't ;; scroll window under mouse
      scroll-step 1 ;; keyboard scroll one line at a time
      scroll-conservatively 101 ;; scroll one line at a time when moving the cursor down the page
      scroll-margin 8) ;; start scrolling 8 lines from the top/bottom

;; eglot
(use-package eglot
  :ensure nil
  :custom
  (eglot-autoshutdown t)
  :config
  :bind (:map prog-mode-map
              ("C-c c c" . (lambda ()
			     (interactive)
			     (eglot-ensure)))
              ("C-c c r" . eglot-rename)
              ("C-c c k" . eglot-shutdown)
              ("C-c c f" . eglot-code-action-quickfix)))

(use-package eglot-java
  :defer t
  :hook (eglot-managed-mode . (lambda ()
    				(interactive)
    				(when (or (string= major-mode "java-mode")
    					  (string= major-mode "java-ts-mode"))
    				  (eglot-java-mode t))))
  :hook (java-mode . eglot-java-mode))

;; tree-sitter
(setq major-mode-remap-alist
      '((java-mode  . java-ts-mode)
        (c-mode . c-ts-mode)
        (c++-mode . c++-ts-mode)
        (rust-mode . rust-ts-mode)))

;; configure gc-cons-threshold to be reasonable
(setq gc-cons-threshold (* 2 1024 1024))

;; tabbing
(setq-default tab-width 4
              c-basic-offset 4
              c-ts-mode-indent-offset 4
              c-ts-mode-indent-style 'bsd
              c-default-style "bsd"
              indent-tabs-mode nil)
(defvaralias 'c-basic-offset 'tab-width)
(defvaralias 'c-ts-mode-indent-offset 'tab-width)
(indent-tabs-mode nil)
(defun cedar/change-tab-width (WIDTH)
  "Set the width of a tab to WIDTH in the current buffer."
  (setq-local tab-width WIDTH
              c-basic-offset WIDTH
              c-ts-mode-indent-offset WIDTH
              java-ts-mode-indent-offset WIDTH))

;; comment-line keybinding
(define-key prog-mode-map (kbd "C-c C-/") #'comment-line)
(define-key prog-mode-map (kbd "C-c C-_") #'comment-line)

;; let me just scroll through completions regularly
(define-key completion-in-region-mode-map (kbd "M-n") #'minibuffer-next-completion)
(define-key completion-in-region-mode-map (kbd "M-p") #'minibuffer-previous-completion)
(define-key completion-in-region-mode-map (kbd "TAB") #'minibuffer-choose-completion)

;; org mode settings

;;; org tempo to enable various shortcuts for blocks in org mode
(use-package org-tempo :ensure nil)

;;; agenda settings
(setopt org-agenda-files '("~/org/agenda/")
        org-agenda-skip-deadline-if-done t
        org-agenda-skip-scheduled-if-done t
        org-agenda-skip-timestamp-if-done t
        org-agenda-skip-scheduled-if-deadline-is-shown t
        org-agenda-skip-timestamp-if-deadline-is-shown t
        org-agenda-start-day "-2d"
        org-agenda-start-on-weekday nil
        org-agenda-span 7
        org-agenda-window-setup 'current-window)
(defun cedar/open-agenda-in-tab ()
  "Go to an org agenda tab, creating one if it doesn't exist."
  (interactive)
  (cedar/open-name-in-tab "Agenda" t #'org-agenda nil "n"))
(global-set-key (kbd "C-c o a") #'cedar/open-agenda-in-tab)

;;; org indent
(require 'org-indent)
(add-hook 'org-mode-hook #'org-indent-mode)

;; magit
(use-package magit :defer t)

;; ansi colors in compilation buffer
;; (http://endlessparentheses.com/ansi-colors-in-the-compilation-buffer-output.html)
(require 'ansi-color)
(defun endless/colorize-compilation ()
  "Colorize from `compilation-filter-start' to `point'."
  (let ((inhibit-read-only t))
    (ansi-color-apply-on-region
     compilation-filter-start (point))))
(add-hook 'compilation-filter-hook #'endless/colorize-compilation)

;; indent bars
(use-package indent-bars
  :vc (:url "https://github.com/jdtsmith/indent-bars")
  :custom
  (indent-bars-treesit-support t)
  (indent-bars-treesit-ignore-blank-lines-types '("module"))
  (indent-bars-starting-column 0)
  (indent-bars-color '(highlight :face-bg t :blend 0.7))
  :config
  (defun turn-off-indent-bars-mode ()
    "Turn off indent-bars-mode"
    (interactive)
    (indent-bars-mode -1))
  :hook (prog-mode . indent-bars-mode)
  :hook ((emacs-lisp-mode lisp-mode) . turn-off-indent-bars-mode))

;; discord integration
(use-package elcord
  :custom
  (elcord-editor-icon "emacs_pen_icon")
  :commands elcord-mode
  :defines elcord-mode elcord-mode-icon-alist
  :config
  ;; https://github.com/Mstrodl/elcord/issues/17
  (defun elcord--enable-on-frame-created (f)
    (ignore f)
    (elcord-mode +1))

  (defun elcord--disable-elcord-if-no-frames (f)
    (when (let ((frames (delete f (visible-frame-list))))
            (or (null frames)
                (and (null (cdr frames))
                     (eq (car frames) terminal-frame))))
      (elcord-mode -1)
      (add-hook 'after-make-frame-functions 'elcord--enable-on-frame-created)))

  (defun my/elcord-mode-hook ()
    (if elcord-mode
        (add-hook 'delete-frame-functions 'elcord--disable-elcord-if-no-frames)
      (remove-hook 'delete-frame-functions 'elcord--disable-elcord-if-no-frames)))

  (add-hook 'elcord-mode-hook 'my/elcord-mode-hook)

  ;; elcord only has language icons setup for non-tree-sitter major modes, so I
  ;; have to add that manually
  (add-to-list 'elcord-mode-icon-alist '(java-ts-mode . "java-mode_icon"))
  (add-to-list 'elcord-mode-icon-alist '(c++-ts-mode . "cpp-mode_icon"))
  (add-to-list 'elcord-mode-icon-alist '(c-ts-mode . "c-mode_icon"))
  (add-to-list 'elcord-mode-icon-alist '(rust-ts-mode . "rust-mode_icon"))
  (add-to-list 'elcord-mode-icon-alist '(haskell-ts-mode . "haskell-mode_icon"))
  
  (elcord-mode))

;; languages
(use-package haskell-mode)
(use-package stumpwm-mode)

;; ligatures
(use-package ligature
  :commands (ligature-set-ligatures global-ligature-mode)
  :config
  (ligature-set-ligatures 'prog-mode '("--" "---" "==" "===" "!=" "!==" "=!="
                                       "=:=" "=/=" "<=" ">=" "&&" "&&&" "&=" "++" "+++" "***" ";;" "!!"
                                       "??" "???" "?:" "?." "?=" "<:" ":<" ":>" ">:" "<:<" "<>" "<<<" ">>>"
                                       "<<" ">>" "||" "-|" "_|_" "|-" "||-" "|=" "||=" "##" "###" "####"
                                       "#{" "#[" "]#" "#(" "#?" "#_" "#_(" "#:" "#!" "#=" "^=" "<$>" "<$"
                                       "$>" "<+>" "<+" "+>" "<*>" "<*" "*>" "</" "</>" "/>" "<!--" "<#--"
                                       "-->" "->" "->>" "<<-" "<-" "<=<" "=<<" "<<=" "<==" "<=>" "<==>"
                                       "==>" "=>" "=>>" ">=>" ">>=" ">>-" ">-" "-<" "-<<" ">->" "<-<" "<-|"
                                       "<=|" "|=>" "|->" "<->" "<~~" "<~" "<~>" "~~" "~~>" "~>" "~-" "-~"
                                       "~@" "[||]" "|]" "[|" "|}" "{|" "[<" ">]" "|>" "<|" "||>" "<||"
                                       "|||>" "<|||" "<|>" "..." ".." ".=" "..<" ".?" "::" ":::" ":=" "::="
                                       ":?" ":?>" "//" "///" "/*" "*/" "/=" "//=" "/==" "@_" "__" "???"
                                       "<:<" ";;;"))
  (global-ligature-mode t))

;; move custom nonsense to a different file
(setq custom-file (concat user-emacs-directory "custom.el"))
