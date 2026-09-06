# Keybinds to learn

These maps are **Neovim** (`~/.config/nvim`), not Cursor. Leader is **Space**. Press `Space` and wait: which-key lists maps.

This config is LazyVim + [craftzdog](https://github.com/craftzdog/dotfiles/tree/master/.config/nvim) maps. Craftzdog keys win when they overlap LazyVim — except the cases below, where LazyVim **prefix** maps win.

---

## These keys look broken (they are not what the table implies)

### `+` — numbers, not zoom

| What you press | What actually happens |
| --- | --- |
| `+` (normal mode, cursor **on a digit**) | Increment. |
| `-` | Oil (parent directory). **Not** decrement. |
| `Ctrl-a` / `Ctrl-x` | Dial: numbers, `true`/`false`, `let`/`const`, semver, date. |
| `Ctrl-m` | Jumplist **forward** (stand-in for `Ctrl-i`). |
| `Ctrl--` / `Ctrl-+` | **Not mapped.** On Mac that is often font zoom (`Cmd-=` / `Cmd--`). |

Cursor must sit on the number (`42`, not the space after it). Hammering `+` 10+ times hits Cowboy (`Hold it Cowboy!`). Use `3+` instead.

In a **terminal**, `Ctrl-m` **is Enter**. The jumplist map may fire on Enter in normal mode, or do nothing useful. It will never decrease a number.

### `Space` `c` and `Space` `d` — stolen by LazyVim prefixes

`<leader>c` is black-hole **change** (`"_c`). `<leader>d` is black-hole **delete** (`"_d`). Both wait for a **motion** (`iw`, `w`, `d` for a line, …).

LazyVim also owns those letters as **groups**:

- `Space` `c` → **Code** (`ca` action, `cf` format, `cr` rename, `cd` diagnostics, `cm` Mason, …)
- `Space` `d` → **Debug / profiler** (`dpp`, `dph`, …)

which-key treats `c` / `d` as prefixes, so `Space` `c` and `Space` `d` open a menu. They do **not** start `"_c` / `"_d`.

**Do this instead**

| Want | Keys |
|--- | --- |
| Delete without yanking | `"_d` + motion, or `"_dd` for a line, or visual select then `"_d` |
| Change without yanking | `"_c` + motion |
| Code action / format / rename | `Space` `ca` / `Space` `cf` / `Space` `cr` |
| Delete buffer | `Space` `bd` |

`Space` alone does nothing until the next key (or which-key pops). That is leader, not play/pause.

---

## Daily vim (craftzdog)

| Key | What it does |
| --- | --- |
| `ss` | Horizontal split |
| `sv` | Vertical split |
| `sh` `sj` `sk` `sl` | Move to left / down / up / right window |
| `Ctrl-w` + arrows | Resize splits |
| `te` then Enter | New tab (type a filename after `te` if you want) |
| `Tab` / `Shift-Tab` | Next / previous tab |
| `sb` | Last **buffer** (the other file you were just in) |
| `sn` / `sp` | Next / previous buffer |
| `-` | Oil (folder of this file; `-` again goes up) |
| `+` | Increment number under cursor |
| `x` | Delete char, **do not** yank it |
| `dw` | Delete word **backwards**, do not yank |
| `Space` `d` / `D` | Delete (visual too), do not yank — **blocked**, see above |
| `Space` `c` / `C` | Change, do not yank — **blocked**, see above |
| `Space` `p` / `P` | Paste from register 0 (last **yank**, not last delete) |
| `Space` `o` / `O` | New line below / above **without** continuing comments |
| `Ctrl-m` | Jump forward in jumplist (same as `Ctrl-i`) |
| `Ctrl-j` | Next diagnostic **and** LazyVim “lower window”. Window move usually wins. |
| `Space` `i` | Toggle LSP inlay hints |
| `Space` `r` | On a line with `#rrggbb`, replace hex with `hsl()` |
| `:ToggleAutoformat` | Toggle format-on-save |

Cowboy: hammering `h` `j` `k` `l` `+` 10+ times shows "Hold it Cowboy!". Use counts (`10j`) instead.

`Ctrl-a` is wired twice: select-all in keymaps, increment via **dial**. Dial usually wins. Use `+` / `Ctrl-x` for numbers; `ggVG` if you need select-all.

---

## Telescope (craftzdog)

These are the `;` maps. LazyVim still has `Space` `f` / `Space` `s` pickers too.

| Key | What it does |
| --- | --- |
| `;f` | Find files (hidden on, respects `.gitignore`) |
| `;r` | Live grep (also searches hidden) |
| `;e` | Diagnostics |
| `;s` | Treesitter symbols (functions, vars) |
| `;c` | LSP incoming calls |
| `;t` | Help tags |
| `;;` | Resume last picker |
| `\\` | Open buffers (`\` twice) |
| `Space` `fP` | Find files inside **plugin** install dir |
| `sf` | File browser at **this file's** folder |

### Inside a Telescope picker

| Key | Mode | What it does |
| --- | --- | --- |
| `Ctrl-n` / `Ctrl-p` | insert | Next / prev result |
| `j` / `k` | normal | Next / prev result |
| `Enter` | both | Open |
| `Ctrl-x` | both | Open horizontal split |
| `Ctrl-v` | both | Open vertical split |
| `Ctrl-t` | both | Open in new tab |
| `Ctrl-q` | both | Send to quickfix |
| `Esc` | insert | Normal mode in picker |
| `Esc` again / `q` | normal | Close |

### File browser (`sf`) — extra maps (normal mode)

| Key | What it does |
| --- | --- |
| `N` | Create file/folder |
| `h` | Parent directory |
| `/` | Start typing to filter |
| `Ctrl-u` / `Ctrl-d` | Jump 10 items |
| `PageUp` / `PageDown` | Scroll preview |

---

## Git

### LazyGit (Folke / Snacks)

Install the binary once: `brew install lazygit`

| Key | What it does |
| --- | --- |
| `Space` `gg` | LazyGit at git **root** |
| `Space` `gG` | LazyGit in **cwd** |
| `Space` `gl` | LazyGit **log** (root) |
| `Space` `gf` | LazyGit log for **this file** |

### Inside LazyGit

| Key | What it does |
| --- | --- |
| `1`–`5` | Switch panels (status, files, branches, commits, stash) |
| `j` / `k` | Move |
| `Space` | Stage / unstage file or hunk |
| `a` | Stage / unstage all |
| `c` | Commit |
| `C` | Commit (with editor) |
| `p` | Pull |
| `P` | Push |
| `w` | Worktree / next page of keybindings (see footer) |
| `x` | Open command menu |
| `d` | Diff / remove (depends on panel; check footer) |
| `Enter` | Inspect / file |
| `e` | Edit file (opens back in this Neovim) |
| `z` | Undo |
| `?` | Help |
| `q` | Quit |

Footer of LazyGit always shows the keys for the **current** panel. Learn `?` first.

### git.nvim (craftzdog)

| Key | What it does |
| --- | --- |
| `Space` `gb` | Blame |
| `Space` `go` | Open file on GitHub / remote in browser |

---

## Coding

### Completion (blink.cmp)

| Key | What it does |
| --- | --- |
| `Tab` / `Shift-Tab` | Next / prev completion item (blink) |
| `Enter` | Confirm completion |
| `Ctrl-y` | Confirm (LazyVim default) |
| `Ctrl-e` | Abort completion |

### Dial (smart increment)

| Key | What it does |
| --- | --- |
| `Ctrl-a` | Next: number, `true`/`false`, `let`/`const`, semver, date |
| `Ctrl-x` | Previous of the same |

### Rename

| Key | What it does |
| --- | --- |
| `:IncRename new_name` | Live rename (type the new name after the command) |
| `Space` `cr` | LazyVim LSP rename |

### mini.bracketed (jump with `[` `]`)

| Key | What it does |
| --- | --- |
| `[d` `]d` | Prev / next diagnostic |
| `[b` `]b` | Prev / next buffer |
| `[c` `]c` | Prev / next comment |
| `[x` `]x` | Prev / next git conflict marker |
| `[i` `]i` | Prev / next indent change |
| `[j` `]j` | Prev / next jump |
| `[l` `]l` | Prev / next location list |
| `[o` `]o` | Prev / next oldfile |
| `[n` `]n` | Prev / next treesitter node |
| `[u` `]u` | Undo points |

---

## UI

| Key | What it does |
| --- | --- |
| `Space` `z` | Zen mode |
| `Space` `th` | Close **hidden** buffers |
| `Space` `tu` | Close nameless buffers |
| `:Noice` | Message history |
| `:Lazy` | Plugin manager |
| `:Mason` | LSP / tool installer |
| `Space` `L` | LazyVim changelog (LazyVim default) |

---

## LazyVim you will still hit every day

Craftzdog did not remove these.

| Key | What it does |
| --- | --- |
| `-` | Oil (replaces `Space` `e`) |
| `Space` `ff` | Find files (LazyVim / Telescope) |
| `Space` `sg` | Grep |
| `Space` `ss` | LSP document symbols |
| `Space` `/` | Grep (root) |
| `Space` `sk` | Search **keymaps** (use this when you forget) |
| `Space` `qq` | Quit all |
| `Space` `bd` | Delete buffer |
| `Space` `fn` | New file |
| `Ctrl-h` `Ctrl-j` `Ctrl-k` `Ctrl-l` | Move windows (LazyVim; same idea as `s` + hjkl) |
| `Ctrl-s` | Save |
| `Esc` `Esc` | Clear search highlight |
| `gcc` | Toggle comment line |
| `gc` | Toggle comment (visual) |
| `K` | Hover docs |
| `gd` | Go to definition (Telescope, new window) |
| `gr` | References |
| `gI` | Implementation |
| `gy` | Type definition |
| `]e` `[e` | Next / prev error |
| `Space` `ca` | Code action |
| `Space` `cf` | Format |

---

## Conflicts worth remembering

| Key | LazyVim | This config |
| --- | --- | --- |
| `Space` `d` | Debug / profiler prefix | black-hole delete — **prefix wins** |
| `Space` `c` | Code menu | black-hole change — **prefix wins** |
| `Space` `p` | (varies) | paste from yank register 0 |
| `Space` `gb` | blame picker | git.nvim blame window |
| `Ctrl-j` | lower window | next diagnostic — **window move wins** |

When lost: `Space` `sk` (search keymaps) or `Space` then wait for which-key.
