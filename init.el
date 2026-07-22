(menu-bar-mode -1)                   ; no menu bar (remove if you prefer it)
(tool-bar-mode -1)                   ; no tool bar
(set-fringe-mode 8)                  ; breathing room at edges
(column-number-mode t)               ; show column in modeline
(global-display-line-numbers-mode t) ; line numbers everywhere
(setq display-line-numbers-type 'relative) ; relative numbers (like vim); use t for absolute
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
;; Prefer tagged GNU/NonGNU ELPA releases over MELPA's rolling snapshots:
;; MELPA's date-based versions (e.g. 20260721.2157) always sort higher than
;; semantic versions (e.g. 4.6.0), so without this, package.el keeps pulling
;; MELPA's bleeding-edge build even when a stable release exists elsewhere.
(setq package-archive-priorities
      '(("gnu" . 3) ("nongnu" . 2) ("melpa" . 1)))
(package-initialize)
(setq use-package-always-ensure t)   ; auto-install any missing use-package packages
;; Font — change to taste
(set-face-attribute 'default nil
                    :family "JetBrainsMono Nerd Font"
                    :height 110)
;; Fallback if JetBrains Mono isn't installed:
;; (set-face-attribute 'default nil :family "DejaVu Sans Mono" :height 130)
;;; ─── BEHAVIOUR ────────────────────────────────────────────────────────────
(setq-default
  indent-tabs-mode nil               ; spaces, not tabs
  tab-width 4
  fill-column 100)
(setq
  make-backup-files nil              ; no ~ backup files
  auto-save-default nil              ; no #autosave# files
  confirm-kill-emacs 'yes-or-no-p   ; ask before quitting
  recentf-max-saved-items 50)
(global-auto-revert-mode t)          ; reload files changed on disk
(recentf-mode t)                     ; track recent files
(savehist-mode t)                    ; persist minibuffer history
(save-place-mode t)                  ; return to last position in files
(electric-pair-mode t)               ; auto-close brackets/quotes
(show-paren-mode t)                  ; highlight matching parens
(delete-selection-mode t)            ; typing replaces selection
;;; ─── THEME ────────────────────────────────────────────────────────────────
(use-package doom-themes
  :config
  (load-theme 'doom-tokyo-night t)
  (doom-themes-visual-bell-config))
;;; ─── MODELINE ─────────────────────────────────────────────────────────────
(use-package doom-modeline
  :init (doom-modeline-mode t))
;;; ─── COMPLETION: VERTICO + ORDERLESS + MARGINALIA ─────────────────────────
(use-package vertico
  :init (vertico-mode t))
(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))
(use-package marginalia
  :init (marginalia-mode t))
(use-package consult
  :bind
  (("C-s"   . consult-line)          ; better isearch
   ("C-x b" . consult-buffer)        ; better buffer switch
   ("M-y"   . consult-yank-pop)      ; browse kill-ring
   ("C-x r b" . consult-bookmark)))
;;; ─── IN-BUFFER COMPLETION: CORFU ──────────────────────────────────────────
(use-package corfu
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.2)
  :init (global-corfu-mode t))
;;; ─── WHICH-KEY ────────────────────────────────────────────────────────────
(use-package which-key
  :init (which-key-mode t)
  :diminish
  :custom (which-key-idle-delay 0.5))
;;; ─── GIT: MAGIT ───────────────────────────────────────────────────────────
(use-package magit                   ; NOTE: fixed missing opening paren in base template
  :bind ("C-c g" . magit-status))
;;; ─── MULTIPLE CURSORS ─────────────────────────────────────────────────────
(use-package multiple-cursors
  :bind
  (("C->" . mc/mark-next-like-this)
   ("C-<" . mc/mark-previous-like-this)
   ("C-c C-<" . mc/mark-all-like-this)))
;;; ─── PROJECT MANAGEMENT ───────────────────────────────────────────────────
;; project.el is built-in; just add a keybinding
(global-set-key (kbd "C-c p") project-prefix-map)
;;; ─── TREESITTER  ───────────────────────────────────────────────
(use-package treesit-auto
  :custom (treesit-auto-install 'prompt)
  :config (global-treesit-auto-mode))
;;; ─── LSP: EGLOT  ────────────────────────────────
(use-package eglot
  :hook
  ((python-ts-mode . eglot-ensure)
   (js-ts-mode     . eglot-ensure)
   (typescript-ts-mode . eglot-ensure)
   (rust-ts-mode   . eglot-ensure))
  :custom
  (eglot-autoshutdown t))
;;; ─── LANGUAGES ────────────────────────────────────────────────────────────
(use-package markdown-mode)
(use-package yaml-mode)
(use-package rust-mode)
(use-package csv-mode
  :mode "\\.csv\\'")
(use-package nix-mode
  :mode "\\.nix\\'")
;;; ─── CLOJURE ──────────────────────────────────────────────────────────────

;; paredit — structural S-expression editing; essential for all Lisps.
;; Key bindings: M-( wrap, M-s splice, C-right slurp, C-left barf, M-r raise.
(use-package paredit
  :hook
  ((clojure-mode       . enable-paredit-mode)
   (clojurescript-mode . enable-paredit-mode)
   (clojurec-mode      . enable-paredit-mode)
   (cider-repl-mode    . enable-paredit-mode)
   (emacs-lisp-mode    . enable-paredit-mode)  ; good for elisp too
   (lisp-mode          . enable-paredit-mode)))

;; rainbow-delimiters — colour-code bracket depth so nesting is instantly readable.
(use-package rainbow-delimiters
  :hook
  ((clojure-mode       . rainbow-delimiters-mode)
   (clojurescript-mode . rainbow-delimiters-mode)
   (clojurec-mode      . rainbow-delimiters-mode)
   (cider-repl-mode    . rainbow-delimiters-mode)
   (emacs-lisp-mode    . rainbow-delimiters-mode)))

;; clojure-mode — major mode: syntax highlighting, indentation, imenu support.
(use-package clojure-mode
  :mode
  (("\\.clj\\'"  . clojure-mode)
   ("\\.cljs\\'" . clojurescript-mode)
   ("\\.cljc\\'" . clojurec-mode)
   ("\\.edn\\'"  . clojure-mode))
  :custom
  ;; Align map literals so values line up — a common Clojure style preference.
  ;; Set to nil if you prefer standard indentation.
  (clojure-align-forms-automatically t))

;; CIDER — Clojure Interactive Development Environment that Rocks.
;; Provides REPL, inline eval, test runner, debugger, and much more.
;;
;; Quick-start workflow:
;;   M-x cider-jack-in         start a REPL for a deps.edn / Leiningen project
;;   M-x cider-jack-in-cljs    start a ClojureScript REPL
;;   C-c C-e                   eval expression before point, show result inline
;;   C-c C-k                   load (eval) the whole buffer
;;   C-c C-z                   switch to/from the REPL buffer
;;   C-c C-t C-t               run test at point
;;   C-c C-t C-n               run all tests in namespace
;;   C-c M-i                   inspect a value
;;   C-c C-d C-d               show documentation for symbol at point
;;   M-.                       jump to definition
;;   M-,                       jump back
(use-package cider
  :after clojure-mode
  :custom
  ;; Show eval results inline in the buffer (requires Emacs 28+).
  (cider-show-error-buffer 'only-in-repl)  ; keep errors in REPL, not a popup
  (cider-repl-display-help-banner nil)     ; skip the welcome banner
  (cider-repl-pop-to-buffer-on-connect 'display-only) ; show REPL but don't focus it
  (cider-repl-use-pretty-printing t)       ; pretty-print REPL output
  (cider-repl-use-clojure-font-lock t)     ; syntax-highlight REPL input
  (cider-save-file-on-load t)              ; auto-save before loading buffer
  ;; eldoc — show function arglists in the minibuffer as you type.
  (cider-eldoc-display-for-symbol-at-point t)
  (comint-scroll-to-bottom-on-output t)
  (cider-interactive-eval-output-destination 'repl-buffer)
  :hook
  (cider-mode . eldoc-mode))

;; clj-refactor — refactoring operations built on top of CIDER.
;;
;; All commands are under the "C-c C-m" prefix (mnemonic: modifier).
;; Run M-x cljr-add-keybindings-to-map to see the full list, or type
;; "C-c C-m ?" with which-key installed for an interactive menu.
;;
;; Commonly used:
;;   C-c C-m th   thread-first (->)
;;   C-c C-m tl   thread-last (->>)
;;   C-c C-m ua   unwind all threading
;;   C-c C-m ai   add import to ns
;;   C-c C-m ar   add require to ns
;;   C-c C-m cn   clean (sort & remove unused) ns requires
;;   C-c C-m ef   extract function
;;   C-c C-m il   introduce let binding
;;   C-c C-m ml   move to let
(use-package clj-refactor
  :after (clojure-mode cider)
  :hook
  (clojure-mode . (lambda ()
                    (clj-refactor-mode t)
                    ;; Prefix for refactoring commands; "C-c C-m" avoids most conflicts.
                    (cljr-add-keybindings-with-prefix "C-c C-m")))
  :custom
  ;; Automatically add missing requires when you use a namespace alias that
  ;; isn't yet in the ns form. Set to nil to be asked each time.
  (cljr-auto-clean-ns nil)
  (cljr-warn-on-eval nil))

(use-package exec-path-from-shell
  :config
  (dolist (var '("NIX_SSL_CERT_FILE" "NIX_PROFILES" "__ETC_PROFILE_NIX_SOURCED" "XDG_DATA_DIRS"))
    (add-to-list 'exec-path-from-shell-variables var))
  (exec-path-from-shell-initialize))


(use-package org-journal
  :defer t
  :init
  ;; Change default prefix key; needs to be set before loading org-journal
  (setq org-journal-prefix-key "C-c j ")
  :config
  (setq org-journal-dir "~/org/journal/"
        org-journal-date-format "%A, %d %B %Y"))

(use-package org-roam
  :custom
  (org-roam-directory (file-truename "/home/jbullard/org"))
  :bind (("C-c n l" . org-roam-buffer-toggle)
         ("C-c n f" . org-roam-node-find)
         ("C-c n g" . org-roam-graph)
         ("C-c n i" . org-roam-node-insert)
         ("C-c n c" . org-roam-capture)
         ;; Dailies
         ("C-c n j" . org-roam-dailies-capture-today))
  :config
  ;; If you're using a vertical completion framework, you might want a more informative completion interface

  (setq org-roam-node-display-template (concat "${title:*} " (propertize "${tags:10}" 'face 'org-tag)))
  (org-roam-db-autosync-mode)
  ;; If using org-roam-protocol
  (require 'org-roam-protocol))

;;; ─── KEYBINDINGS ──────────────────────────────────────────────────────────
;; Make ESC quit prompts
(global-set-key (kbd "<escape>") 'keyboard-escape-quit)
(global-set-key (kbd "C-c l") #'org-store-link)
(global-set-key (kbd "C-c a") #'org-agenda)
(global-set-key (kbd "C-c c") #'org-capture)
(setopt use-short-answers t)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   '("8c7e832be864674c220f9a9361c851917a93f921fedb7717b1b5ece47690c098" "8a015b9c62f50bf58bf2e71c875c060b0e217212b62d65b0b4a0cf7328dbb76c" default))
 '(package-selected-packages
   '(csv-mode org-roam nix-mode multiple-cursors clj-refactor cider clojure-mode rainbow-delimiters paredit rust-mode yaml-mode markdown-mode treesit-auto magit which-key corfu consult marginalia orderless vertico doom-modeline doom-themes))
 '(safe-local-variable-values
   '((cider-clojure-cli-aliases . "test:dev-front")
     (cider-default-cljs-repl . custom)
     (cider-preferred-build-tool . clojure-cli)
     (cider-clojure-cli-aliases . "dev-front:test")
     (cider-cljs-repl-type . "figwheel-main")
     (cider-clojure-cli-global-options . "-M:calva:dev-front:test -m figwheel.main -b dev -r"))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
