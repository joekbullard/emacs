(menu-bar-mode -1)                   ; no menu bar (remove if you prefer it)
(tool-bar-mode -1)                   ; no tool bar
(set-fringe-mode 8)                  ; breathing room at edges
(column-number-mode t)               ; show column in modeline
(global-display-line-numbers-mode t) ; line numbers everywhere
(setq display-line-numbers-type 'relative) ; relative numbers (like vim); use t for absolute
;; Packages are provided by Nix (see `programs.emacs.extraPackages' in
;; nix-config's modules/home.nix) and are already on `load-path' before
;; Emacs starts, so `use-package' below just requires them — no package.el,
;; no MELPA fetch, no `:ensure'.
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
  :init
  ;; Start eglot from `envrc-mode-hook', not the major-mode hooks directly:
  ;; `envrc-mode' (below) turns on via `after-change-major-mode-hook', which
  ;; Emacs always runs *after* a buffer's own mode hook (e.g.
  ;; `python-ts-mode-hook'). Hooking eglot to the mode hook would race
  ;; envrc's PATH setup and fail to find a project-local server such as
  ;; basedpyright; hooking off envrc instead guarantees the per-project
  ;; environment (see DIRENV below) is already in place first.
  ;; Match both the tree-sitter and stock major modes: `treesit-auto' only
  ;; remaps to the `-ts-mode' variant when its grammar is actually installed,
  ;; which isn't guaranteed, so eglot must still start in plain `python-mode'
  ;; et al.
  (add-hook 'envrc-mode-hook
            (lambda ()
              (when (derived-mode-p 'python-mode 'python-ts-mode
                                     'js-mode 'js-ts-mode
                                     'typescript-mode 'typescript-ts-mode
                                     'rust-mode 'rust-ts-mode)
                (eglot-ensure))))
  :custom
  (eglot-autoshutdown t)
  :config
  ;; basedpyright over eglot's stock pylsp default; comes from each project's
  ;; own devShell (see PYTHON section below).
  (add-to-list 'eglot-server-programs
               '((python-mode python-ts-mode) . ("basedpyright-langserver" "--stdio"))))
;;; ─── DIRENV ───────────────────────────────────────────────────────────────
;; Per-project environments (Python venvs, tool versions) come from each
;; project's own `.envrc' (typically `use flake'), not anything global.
;; envrc-mode loads that environment into the buffer's `process-environment'/
;; `exec-path' so eglot, compile, and shell commands all see it.
(use-package envrc
  :init (envrc-global-mode))
;;; ─── FORMAT ON SAVE: APHELEIA ─────────────────────────────────────────────
(use-package apheleia
  :init (apheleia-global-mode t)
  :config
  ;; apheleia defaults python to black; use ruff instead since that's what
  ;; we're installing per-project (see PYTHON below), not both.
  (setf (alist-get 'python-mode apheleia-mode-alist) '(ruff-isort ruff))
  (setf (alist-get 'python-ts-mode apheleia-mode-alist) '(ruff-isort ruff)))
;;; ─── PYTHON ───────────────────────────────────────────────────────────────
;; No Python interpreter or tooling is installed globally — each project
;; supplies its own via a `flake.nix' devShell (python3, basedpyright, ruff)
;; picked up through direnv. ruff covers linting (flymake, above) and
;; formatting (apheleia, above); basedpyright covers types/nav/hover (eglot).
(use-package flymake-ruff
  :hook ((python-mode python-ts-mode) . flymake-ruff-load))
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


;;; ─── CLAUDE CODE IDE ──────────────────────────────────────────────────────
;; Bridges Claude Code CLI into Emacs via MCP. Terminal backend is `ghostel'
;; (libghostty-powered), Nix-installed alongside vterm/eat as alternatives.
(use-package claude-code-ide
  :custom
  (claude-code-ide-terminal-backend 'ghostel)
  :bind ("C-c C-'" . claude-code-ide-menu)
  :config
  (claude-code-ide-emacs-tools-setup))

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
