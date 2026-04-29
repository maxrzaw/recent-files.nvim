# `worktree-oldfiles.nvim`

A Telescope extension that provides a git worktree aware oldfiles picker for Neovim.

It is built around a few behaviors that are useful when you work across Git repos and worktrees:

- understands Git worktrees
- can treat the same relative path in sibling worktrees as one logical entry when you are browsing from that shared Git context
- falls back to distinct file paths when there is no matching Git context to translate through

## Requirements

- Neovim `0.10+`
- [`nvim-telescope/telescope.nvim`](https://github.com/nvim-telescope/telescope.nvim)
- [`nvim-lua/plenary.nvim`](https://github.com/nvim-lua/plenary.nvim)

## Installation

### `lazy.nvim`

```lua
{
    "nvim-telescope/telescope.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "maxrzaw/worktree-oldfiles.nvim",
    },
    opts = {
        extensions = {
            worktree_oldfiles = {
                default_branch = "main",
            },
        },
    },
    config = function(_, opts)
        local telescope = require("telescope")
        telescope.setup(opts)
        telescope.load_extension("worktree_oldfiles")
    end,
}
```

## Usage

- Lua: `require("telescope").extensions.worktree_oldfiles.worktree_oldfiles()`
- Command: `:Telescope worktree_oldfiles`

## Configuration

Pass a partial config through `telescope.setup({ extensions = { worktree_oldfiles = { ... } } })`.

```lua
require("telescope").setup({
    extensions = {
        worktree_oldfiles = {
            default_branch = "main",
            repo_overrides = {
                ["/path/to/repo/.git"] = "trunk",
            },
            max_entries = 1000,
            ignore_patterns = {
                "**/.git/*",
                "node_modules/**",
            },
            skip_filetypes = {
                TelescopePrompt = true,
                gitcommit = true,
                gitrebase = true,
            },
            picker = {
                prompt_title = "My Worktree Oldfiles",
                mappings = {
                    i = {
                        ["<C-y>"] = function(prompt_bufnr)
                            local entry = require("telescope.actions.state").get_selected_entry()
                            if entry and entry.filename then
                                vim.fn.setreg("+", entry.filename)
                            end
                        end,
                    },
                },
            },
        },
    },
})
```

`picker.prompt_title` overrides the Telescope picker title.

`picker.mappings` follows Telescope's per-mode mapping format and is merged into the extension picker.

### Defaults

- `default_branch = "main"`
- `max_entries = 1000`
- generic ignore patterns for build output, temporary files, and OS junk
- default skip filetypes: `alpha`, `gitcommit`, `gitrebase`, `lazy`, `mason`, `neo-tree`, `TelescopePrompt`
- `picker.prompt_title = "Worktree Oldfiles"`

## Development

Run the unit tests with:

```sh
make test-unit
```

Bootstrap the test dependencies and run the Telescope integration tests with:

```sh
make test-integration
```

Run both test suites with:

```sh
make test
```

Run `luacheck` with:

```sh
make lint
```
