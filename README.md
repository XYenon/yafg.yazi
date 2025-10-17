# yafg.yazi (Yet Another FG)

Fuzzy find and grep in Yazi using ripgrep and fzf. This plugin provides an interactive search interface that allows you to search file contents and open results directly in Helix editor.

> Inspired by [fg.yazi](https://github.com/DreamMaoMao/fg.yazi)

## Requirements

- `bash`
- `rg` (ripgrep)
- `fzf`
- `bat`
- `hx` (Helix editor)

## Installation

Install the plugin via the package manager:

```bash
ya pkg add XYenon/yafg
```

This clones the repository, adds it to `~/.config/yazi/package.toml`, and pins the current revision.

## Usage

Add a shortcut in `~/.config/yazi/keymap.toml`:

```toml
[[mgr.prepend_keymap]]
on  = [ "F", "G" ]
run = "plugin yafg"
```

## Features

- **Interactive search**: Use ripgrep to search file contents with live preview
- **Switch modes**: Press `Ctrl-T` to toggle between ripgrep and fzf modes
- **Multi-select**: Select multiple search results
- **Preview**: View file contents with syntax highlighting via bat
- **Direct open**: Opens selected files in Helix editor at the matched line

## Troubleshooting

- **Failed to start fzf**: ensure all required dependencies are installed (`rg`, `fzf`, `bat`, `bash`, `hx`).
- **Preview not working**: install `bat` for syntax-highlighted previews.
- **Editor not opening**: ensure `hx` (Helix) is installed and in your PATH.

## Development

This repository uses [treefmt](https://github.com/numtide/treefmt) for formatting:

```bash
nix fmt
```

Feel free to open a PR to add more features or support additional editors.
