# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This repository is a personal Emacs configuration consisting of a single file, `init.el`. There is no build system or test suite — `init.el` is both the source and the artifact.

Packages are **not** installed by Emacs. They come from Nix: `programs.emacs.extraPackages` in `~/nix-config/modules/home.nix` (a separate repo) builds an Emacs with every package already on `load-path`, autoloads generated. There is no `package.el` setup, no MELPA, and no `:ensure` anywhere in `init.el`. Adding a package therefore means editing `home.nix` and running `home-manager switch` **first**; a `use-package` block for a package Nix hasn't installed yet silently does nothing until then. The same applies to tree-sitter grammars (`treesitGrammars` in `home.nix`, exported as `EMACS_TREE_SITTER_GRAMMARS`).

When something in Emacs doesn't recognise a package or grammar that `home.nix` clearly lists, suspect a stale generation before suspecting `init.el` — check with `emacs --batch --eval '(princ (locate-library "PKG"))'`.

## Validating changes

There's no CI or test runner. To check that edits are well-formed and load:

```sh
emacs --batch --eval '(check-parens)' -l init.el
```

This is fast and pulls nothing. Under `--batch` the package autoloads aren't activated, so roughly seven `Error (use-package): .../:init: Symbol's function definition is void: ...` warnings (doom-themes, doom-modeline, vertico, marginalia, corfu, envrc, apheleia) are **expected and pre-existing**. What matters is that no *new* ones appear and that no "Cannot load" error shows up. To confirm a specific form took effect:

```sh
emacs --batch -l init.el --eval '(princ (format "%S" (assoc (quote nim-mode) eglot-server-programs)))'
```

## Structure of init.el

Banner-commented sections (`;;; ─── NAME ───...`, all padded to 78 columns), in load order:

1. **UI chrome** (top, no banner) — menu/tool bar, fringes, line numbers, font. Built-ins only; runs before anything else. `display-line-numbers-type` is set *before* the mode so pre-existing buffers pick it up.
2. **PACKAGES** — comment only: the Nix story above, plus the two rules it implies (no bare `use-package`, no redundant `:mode`).
3. **CUSTOM FILE** — `custom-file` points at `custom.el` beside `init.el`, because Nix installs `init.el` as a read-only `/nix/store` symlink that Customize can't write to. `custom.el` is machine-local scratch, not in this repo; anything worth keeping is hand-written into `init.el`. Loaded by the last form in the file so Customize wins.
4. **BEHAVIOUR** — editing defaults and global minor modes, all built-ins, no `use-package`.
5. **Feature blocks**, one `use-package` each — `doom-themes` (also holds `custom-safe-themes`), `doom-modeline`, the minibuffer stack (`vertico` + `orderless` + `marginalia` + `consult`), `corfu`, `which-key`, `magit`, `multiple-cursors`, and `project.el` (built-in, just a keybinding).
6. **TREESITTER** — `treesit-extra-load-path` from `EMACS_TREE_SITTER_GRAMMARS`, and `treesit-auto-langs` narrowed to what Nix builds so treesit-auto never offers its git-clone-and-compile installer. Keep that list in sync with `treesitGrammars`.
7. **LSP: EGLOT** — `eglot-ensure` runs from `envrc-mode-hook`, not the major-mode hooks, so the direnv environment is in place before a project-local server is looked up. The guard is a `derived-mode-p` list naming both `-ts-mode` and stock modes. `eglot-server-programs` gets basedpyright (overriding pylsp) and nimlangserver (eglot ships no Nim entry).
8. **DIRENV** — `envrc-global-mode`. Everything project-local hangs off this.
9. **FORMAT ON SAVE: APHELEIA** — global, with python pointed at ruff instead of black.
10. **PYTHON** — `flymake-ruff`, hooked to `eglot-managed-mode-hook` because eglot *replaces* `flymake-diagnostic-functions` and is the only thing here that enables `flymake-mode`.
11. **LANGUAGES** — mostly a comment. markdown/yaml/rust/csv/nix-mode need no block at all; only `nim-mode` has one, because its own autoloads route `.nims`/`.nimble` to `nimscript-mode-maybe`.
12. **CLOJURE** — `safe-local-variable-values` (per-repo CIDER dir-locals whitelist), then a deliberately ordered stack: `paredit` → `rainbow-delimiters` → `clojure-mode` → `cider` (`:after clojure-mode`) → `clj-refactor` (`:after (clojure-mode cider)`). Keep that order; the later blocks depend on `:after`.
13. **SHELL ENVIRONMENT** — `exec-path-from-shell`, importing Nix vars (`NIX_SSL_CERT_FILE`, `NIX_PROFILES`, `__ETC_PROFILE_NIX_SOURCED`, `XDG_DATA_DIRS`) that GUI Emacs wouldn't otherwise see.
14. **CLAUDE CODE IDE** — `claude-code-ide` over MCP, `ghostel` terminal backend.
15. **KEYBINDINGS** — global keys layered on top of the `:bind` clauses in the blocks above.
16. **`custom-file` load** — last form, `:noerror` because `custom.el` may not exist yet.

## Conventions to preserve when editing

- New packages go through `use-package` with `:hook`/`:bind`/`:custom` keywords rather than bare `add-hook`/`setq` after `:config` — and into `home.nix` first.
- **Never write a keyword-less `use-package`.** With no `:ensure` to do, it expands to an eager `(require 'foo)` at startup and buys nothing over the package's own autoloads. A block must earn its place with real configuration.
- **Don't restate a package's autoload cookie.** Check before adding `:mode`/`:commands` — most packages already claim their own extensions, and a duplicate entry is dead weight. List one only when it *overrides* the package's default (`.edn` → `clojure-mode`, `.nims` → `nim-mode`).
- **Don't set a variable to its own default.** Check `(get 'VAR 'standard-value)` before adding a `:custom` line; likewise check whether a mode is already on by default (`show-paren-mode`, `global-eldoc-mode`) before enabling it.
- **Don't list derived modes separately in hooks.** `clojurescript-mode` and `clojurec-mode` run `clojure-mode-hook`; one entry covers all three. Use the list form: `:hook ((mode-a mode-b) . fn)`.
- Section banners mark top-level feature groups — add to an existing section or create a new banner rather than interleaving unrelated config.
- Comments explain *why* a non-obvious setting exists (the eglot/envrc hook-ordering trap, the flymake/eglot backend replacement, the CIDER quick-reference) — never what a form obviously does. Say it once: cross-reference another section instead of repeating its rationale.
