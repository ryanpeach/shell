require("config.lazy")
require("config.maps")
require("config.settings")
local wk = require("which-key")

-- Custom
vim.g.mapleader = " "

-- Autosave
vim.opt.autowriteall = true
vim.opt.undofile = true -- Persist history between sessions
vim.opt.undolevels = 1000 -- or any desired value
vim.opt.undoreload = 10000 -- or any desired value
vim.opt.hidden = false -- equivalent to nohidden, prevents unsaved hidden buffers

-- Make editing lua better
local shell_dir = os.getenv("SHELL_DIR") or os.getenv("HOME")
wk.register({
    l = {
        name = "lua",
        i = {":e ~/.config/nvim/init.lua<CR>", "Edit init.lua"},
        s = {":source ~/.config/nvim/init.lua<CR>", "Reload init.lua"},
        l = {
            ':lua os.execute("git clone https://github.com/ryanpeach/shell " .. "' ..
                shell_dir .. '")<CR>', "Clone shell repo"
        },
        p = {
            ':lua os.execute("cp -r ~/.config/nvim/ ' .. shell_dir ..
                '/home/.config/nvim/")<CR>', "Copy nvim config"
        },
        e = {':e ' .. shell_dir .. '<CR>', "Goto SHELL_DIR"}
    }
}, {prefix = "<leader>"})

vim.cmd([[
  augroup ReloadInitOnSave
    autocmd!
    autocmd BufWritePost BufWritePost ~/.config/nvim/**/*.lua source ~/.config/nvim/init.lua
  augroup END
]])
