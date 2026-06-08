;;; init.el --- Modern Emacs configuration -*- lexical-binding: t -*-
;;; ─── PACKAGE SETUP ────────────────────────────────────────────────────────
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)
;; Refresh package list on first run
(unless package-archive-contents
  (package-refresh-contents))
(unless (package-installed-p 'use-package)
  (package-install 'use-package))
(require 'use-package)
(setq use-package-always-ensure t)   ; auto-install all packages
;;; ─── CORE UI ──────────────────────────────────────────────────────────────
(setq inhibit-startup-message t)     ; no splash screen
(scroll-bar-mode -1)                 ; no scrollbar
(tool-bar-mode -1)                   ; no toolbar
(tooltip-mode -1)                    ; no tooltips
(menu-bar-mode -1)                   ; no menu bar (remove if you prefer it)
(set-fringe-mode 8)                  ; breathing room at edges
(column-number-mode t)               ; show column in modeline
(global-display-line-numbers-mode t) ; line numbers everywhere
(setq display-line-numbers-type 'relative) ; relative numbers (like vim); use t for absolute
;; Font — change to taste
(set-face-attribute 'default nil :family "JetBrains Mono" :height 130)
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

;;; ─── KEYBINDINGS ──────────────────────────────────────────────────────────
;; Make ESC quit prompts
(global-set-key (kbd "<escape>") 'keyboard-escape-quit)
