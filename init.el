(menu-bar-mode -1)                   ; no menu bar
(tool-bar-mode -1)                   ; no tool bar
(set-fringe-mode 8)                  ; breathing room at edges
(column-number-mode t)               ; show column in modeline
(setq display-line-numbers-type 'relative) ; relative (like vim); t for absolute
(global-display-line-numbers-mode t) ; after the type, so buffers that
                                     ; already exist pick it up too
(set-face-attribute 'default nil
                    :family "JetBrainsMono Nerd Font"
                    :height 110)
;; Fallback if that font is missing:
;; (set-face-attribute 'default nil :family "DejaVu Sans Mono" :height 130)
;;; ─── PACKAGES ─────────────────────────────────────────────────────────────
;; Packages come from Nix (`programs.emacs.extraPackages' in nix-config's
;; modules/home.nix), already on `load-path' with autoloads generated — no
;; package.el, no MELPA, no `:ensure'; new packages go there first. So a
;; `use-package' block is only worth writing when it carries real config: a
;; bare `(use-package foo)' is just an eager `require', and a `:mode' that
;; restates the package's own autoload cookie does nothing.
;;; ─── CUSTOM FILE ──────────────────────────────────────────────────────────
;; Nix installs this file as a read-only /nix/store symlink, so Customize
;; can't write its block back here — accepting a theme or answering `!' to a
;; dir-locals prompt would fail on save. Point it at a sibling file instead;
;; the directory is writable. custom.el is machine-local scratch, so anything
;; worth keeping gets hand-written here.
(setq custom-file (locate-user-emacs-file "custom.el"))
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
(delete-selection-mode t)            ; typing replaces selection
(setopt use-short-answers t)         ; y/n instead of yes/no
;; `show-paren-mode' is on by default since Emacs 28.
;;; ─── THEME ────────────────────────────────────────────────────────────────
(use-package doom-themes
  :custom
  ;; Themes trusted to run their elisp unprompted; add a hash by hand after
  ;; vetting one.
  (custom-safe-themes
   '("8c7e832be864674c220f9a9361c851917a93f921fedb7717b1b5ece47690c098"
     "8a015b9c62f50bf58bf2e71c875c060b0e217212b62d65b0b4a0cf7328dbb76c"
     default))
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
  :custom (which-key-idle-delay 0.5))
;;; ─── GIT: MAGIT ───────────────────────────────────────────────────────────
(use-package magit
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
;;; ─── TREESITTER ───────────────────────────────────────────────────────────
;; Grammars built by Nix (see EMACS_TREE_SITTER_GRAMMARS in nix-config's
;; modules/home.nix) take priority over treesit-auto's runtime git-clone-
;; and-compile install, which needs a C toolchain and network access.
(when-let ((dir (getenv "EMACS_TREE_SITTER_GRAMMARS")))
  (add-to-list 'treesit-extra-load-path dir))
(use-package treesit-auto
  :custom
  (treesit-auto-install 'prompt)
  ;; Keep in sync with `treesitGrammars' in nix-config's modules/home.nix:
  ;; treesit-auto ships 62 recipes, and any whose `-ts-mode' is built in
  ;; (yaml, json, toml, ...) would prompt to git-clone and compile on first
  ;; open — the runtime installer this setup exists to avoid.
  (treesit-auto-langs '(python javascript typescript tsx rust))
  :config (global-treesit-auto-mode))
;;; ─── LSP: EGLOT ───────────────────────────────────────────────────────────
(use-package eglot
  :init
  ;; Hooked to `envrc-mode-hook', not the major-mode hooks: envrc turns on
  ;; from `after-change-major-mode-hook', i.e. after a buffer's own mode hook,
  ;; so hooking the mode would race envrc's PATH setup and miss the
  ;; project-local server (see DIRENV below). Both the `-ts-mode' and stock
  ;; modes are listed because treesit-auto only remaps when the grammar is
  ;; actually installed.
  (add-hook 'envrc-mode-hook
            (lambda ()
              (when (derived-mode-p 'python-mode 'python-ts-mode
                                     'js-mode 'js-ts-mode
                                     'typescript-mode 'typescript-ts-mode
                                     'rust-mode 'rust-ts-mode
                                     'nim-mode)
                (eglot-ensure))))
  :custom
  (eglot-autoshutdown t)
  :config
  ;; basedpyright over eglot's stock pylsp default (see PYTHON below).
  (add-to-list 'eglot-server-programs
               '((python-mode python-ts-mode) . ("basedpyright-langserver" "--stdio")))
  ;; eglot has no Nim entry at all, so this one is required, not an override.
  ;; Not nim-mode's own nimsuggest integration: `nimsuggest-path' is
  ;; initialised with `(executable-find "nimsuggest")' at load time, which is
  ;; nil before direnv supplies Nim; eglot resolves per-buffer, after envrc.
  (add-to-list 'eglot-server-programs
               '(nim-mode . ("nimlangserver"))))
;;; ─── DIRENV ───────────────────────────────────────────────────────────────
;; Per-project environments (venvs, tool versions) come from each project's
;; own `.envrc' (typically `use flake'); envrc-mode loads them into the
;; buffer's `process-environment'/`exec-path' so eglot, compile and shell
;; commands all see them.
(use-package envrc
  :init (envrc-global-mode))
;;; ─── FORMAT ON SAVE: APHELEIA ─────────────────────────────────────────────
(use-package apheleia
  :init (apheleia-global-mode t)
  :config
  ;; apheleia defaults python to black; use ruff, which is what the devShells
  ;; install (see PYTHON below).
  (dolist (mode '(python-mode python-ts-mode))
    (setf (alist-get mode apheleia-mode-alist) '(ruff-isort ruff))))
;;; ─── PYTHON ───────────────────────────────────────────────────────────────
;; Nothing Python is installed globally — each project's flake.nix devShell
;; supplies python3, ruff and basedpyright through direnv. ruff lints
;; (flymake) and formats (apheleia); basedpyright does types/nav/hover
;; (eglot).
(use-package flymake-ruff
  ;; On `eglot-managed-mode-hook', not the python hooks: `eglot--managed-mode'
  ;; *replaces* `flymake-diagnostic-functions', discarding anything a mode
  ;; hook added earlier, and it is also the only thing here that turns
  ;; `flymake-mode' on. `flymake-ruff-load' no-ops outside Python.
  :hook (eglot-managed-mode . flymake-ruff-load))
;;; ─── LANGUAGES ────────────────────────────────────────────────────────────
;; markdown-mode, yaml-mode, rust-mode, csv-mode and nix-mode get no block
;; here: Nix installs them and their autoloads already claim their extensions.
;;
;; nim-mode is a classic (non-tree-sitter) mode — no `nim-ts-mode' exists and
;; treesit-auto doesn't know Nim, so nothing uses the grammar Nix builds (see
;; TREESITTER); wiring one up is still to do. These `:mode' entries do earn
;; their keep: nim-mode's own autoloads send .nims/.nimble to
;; `nimscript-mode-maybe'.
(use-package nim-mode
  :mode (("\\.nim\\'"  . nim-mode)
         ("\\.nims\\'" . nim-mode)
         ("\\.nimble\\'" . nim-mode)))
;;; ─── CLOJURE ──────────────────────────────────────────────────────────────
;; CIDER settings that specific repos set via .dir-locals.el, whitelisted so
;; opening a file there doesn't prompt. Each entry is one exact
;; (variable . value) pair; the two `cider-clojure-cli-aliases' keys are two
;; different projects' aliases, not a duplicate. Answering `!' at a prompt
;; lands in custom.el, so move anything worth keeping up here.
(setopt safe-local-variable-values
        '((cider-clojure-cli-aliases . "test:dev-front")
          (cider-default-cljs-repl . custom)
          (cider-preferred-build-tool . clojure-cli)
          (cider-clojure-cli-aliases . "dev-front:test")
          (cider-cljs-repl-type . "figwheel-main")
          (cider-clojure-cli-global-options
           . "-M:calva:dev-front:test -m figwheel.main -b dev -r")))

;; paredit — structural editing: M-( wrap, M-s splice, C-right slurp,
;; C-left barf, M-r raise. clojurescript-mode and clojurec-mode derive from
;; clojure-mode, so `clojure-mode-hook' covers them here and below too.
(use-package paredit
  :hook ((clojure-mode
          cider-repl-mode
          emacs-lisp-mode                     ; good for elisp too
          lisp-mode)
         . enable-paredit-mode))

;; rainbow-delimiters — colour-code bracket depth.
(use-package rainbow-delimiters
  :hook ((clojure-mode
          cider-repl-mode
          emacs-lisp-mode)
         . rainbow-delimiters-mode))

;; clojure-mode — syntax highlighting, indentation, imenu.
(use-package clojure-mode
  ;; .clj/.cljs/.cljc come from clojure-mode's autoloads; .edn is listed only
  ;; to override its newer default of `edn-mode'.
  :mode ("\\.edn\\'" . clojure-mode)
  :custom
  (clojure-align-forms-automatically t)) ; line up values in map literals

;; CIDER — REPL, inline eval, test runner, debugger.
;;
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
  ;; Only what differs from cider's defaults — pretty-printing, REPL
  ;; font-lock and eldoc are already on out of the box.
  :custom
  (cider-show-error-buffer 'only-in-repl)  ; keep errors in REPL, not a popup
  (cider-repl-display-help-banner nil)     ; skip the welcome banner
  (cider-repl-pop-to-buffer-on-connect 'display-only) ; show REPL but don't focus it
  (cider-save-file-on-load t)              ; auto-save before loading, don't prompt
  ;; A global comint setting, not cider's, so the REPL follows its output.
  (comint-move-point-for-output t))

;; clj-refactor — refactorings on top of CIDER, all under the "C-c C-m"
;; prefix (mnemonic: modifier). "C-c C-m ?" lists them all via which-key.
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
  (cljr-auto-clean-ns nil)   ; don't rewrite the whole ns form after a require
  (cljr-warn-on-eval nil))   ; don't prompt before cljr evaluates its helpers
;;; ─── SHELL ENVIRONMENT ────────────────────────────────────────────────────
(use-package exec-path-from-shell
  :config
  (dolist (var '("NIX_SSL_CERT_FILE" "NIX_PROFILES" "__ETC_PROFILE_NIX_SOURCED" "XDG_DATA_DIRS"))
    (add-to-list 'exec-path-from-shell-variables var))
  (exec-path-from-shell-initialize))
;;; ─── CLAUDE CODE IDE ──────────────────────────────────────────────────────
;; Bridges the Claude Code CLI into Emacs via MCP. Terminal backend is
;; `ghostel' (libghostty); vterm and eat are installed as alternatives.
(use-package claude-code-ide
  :custom
  (claude-code-ide-terminal-backend 'ghostel)
  :bind ("C-c C-'" . claude-code-ide-menu)
  :config
  (claude-code-ide-emacs-tools-setup))
;;; ─── KEYBINDINGS ──────────────────────────────────────────────────────────
(global-set-key (kbd "<escape>") 'keyboard-escape-quit) ; ESC quits prompts
(global-set-key (kbd "C-c l") #'org-store-link)
(global-set-key (kbd "C-c a") #'org-agenda)
(global-set-key (kbd "C-c c") #'org-capture)

;; Last, so Customize's machine-local settings win. :noerror because
;; custom.el doesn't exist until Customize first writes one.
(load custom-file :noerror)
