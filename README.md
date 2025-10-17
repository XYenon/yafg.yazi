# yafg.yazi (Yet Another FG)

Fuzzy find and grep in Yazi using ripgrep and fzf. This plugin provides an interactive search interface that allows you to search file contents and open results directly in your configured editor.

> Inspired by [fg.yazi](https://github.com/DreamMaoMao/fg.yazi)

## Requirements

- `bash`
- `rg` (ripgrep)
- `fzf`
- `bat`
- A text editor (default: `hx` Helix)

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

## Configuration

Customize the editor and command format in `~/.config/yazi/init.lua`:

```lua
require("yafg"):setup({
  editor = "nvim",                    -- Editor command (default: "hx")
  args = { "--noplugin" },            -- Additional editor arguments (default: {})
  file_arg_format = "+{row} {file}",  -- File argument format (default: "{file}:{row}:{col}")
})
```

Format placeholders:

- `{file}` - File path
- `{row}` - Line number
- `{col}` - Column number

## Features

- **Interactive search**: Use ripgrep to search file contents with live preview
- **Switch modes**: Press `Ctrl-T` to toggle between ripgrep and fzf modes
- **Multi-select**: Select multiple search results
- **Preview**: View file contents with syntax highlighting via bat
- **Direct open**: Opens selected files in your configured editor at the matched line
- **Configurable**: Customize editor command, arguments, and file format

## Troubleshooting

- **Failed to start fzf**: ensure all required dependencies are installed (`rg`, `fzf`, `bat`, `bash`).
- **Preview not working**: install `bat` for syntax-highlighted previews.
- **Editor not opening**: ensure your configured editor is installed and in your PATH, or customize it in `init.lua`.

## Development

This repository uses [treefmt](https://github.com/numtide/treefmt) for formatting:

```bash
nix fmt
```

Feel free to open a PR to add more features or support additional editors.
