# review.nvim

A simple spaced-repetition review system for Neovim.

`review.nvim` keeps review metadata outside your files, so it can work with any file type supported by Neovim.

## Features

* Review any file type
* Review metadata stored separately from the source file
* No changes to Markdown or source files
* Simple spaced-repetition intervals
* Telescope-based review finder
* Detects deleted files as `MISSING`
* Restore deleted files without losing review metadata
* Clean missing review entries manually
* Supports overdue, today, tomorrow and upcoming reviews

## Default intervals

```text
1 → 3 → 7 → 14 → 30 → 60 days
```

A newly added file is scheduled for the next day.

## Keymaps

| Key          | Action                |
| ------------ | --------------------- |
| `<leader>ra` | Add current file      |
| `<leader>rr` | Open review finder    |
| `<leader>rc` | Complete review       |
| `<leader>rp` | Postpone review       |
| `<leader>rd` | Remove current file   |
| `<leader>rC` | Clean missing reviews |

Inside the Telescope review finder:

| Key       | Action                   |
| --------- | ------------------------ |
| `<Enter>` | Open selected file       |
| `<C-c>`   | Complete selected review |
| `<C-p>`   | Postpone selected review |
| `<C-d>`   | Remove selected review   |

## Data

Review metadata is stored outside the project:

```text
~/.local/share/nvim/review/reviews.json
```

Your source files are never modified by the plugin.

## Installation

Using lazy.nvim:

```lua
{
  "ocsiker/review.nvim",
  lazy = false,

  opts = {
    intervals = {
      1,
      3,
      7,
      14,
      30,
      60,
    },
  },
}
```

## License

MIT

