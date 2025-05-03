<MKDocTOC/>

# memcard.nvim

simple session manager for neovim


# Install

with lazy.nvim

```lua
require('lazy').setup({
    {
        'l4zygreed/memcard.nvim',
        cmd = { 'CardSave', 'CardDelete', 'CardLoad'},
        opts = {},
    }
})
```

default config

```lua
opts = {
    dir = vim.fn.stdpath('cache') .. '/memcard', -- direcory to store sessions
    auto_save_on_exit = false, -- auto save session when quit neovim
    root_markers = { '.git' } -- root markers for project dir for default_name
}
```

# Commands

## CardSave
args: `name` (optional)

save a session with name or select from complete list
if name is not provided, it will be auto generated (default_name) based on current working directory
or used name of currently loaded session

## CardLoad
args: `name` (optional)

load a session, if name is not provided, it will use default_name

## CardDelete
args: name

delete a session by name
