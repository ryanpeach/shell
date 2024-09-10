-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local wk = require("which-key")

-- Override only <leader><tab>h and <leader><tab>l for tab navigation
wk.add({
    { "<leader><tab>h", "<cmd>tabprevious<cr>", desc="Previous Tab" },
    { "<leader><tab>l", "<cmd>tabnext<cr>", desc="Next Tab" },
})
