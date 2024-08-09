require("config.lazy")
require("config.maps")
require("config.settings")

-- Autosave
vim.opt.autowriteall = true
vim.opt.undofile = true -- Persist history between sessions
vim.opt.undolevels = 1000 -- or any desired value
vim.opt.undoreload = 10000 -- or any desired value
vim.opt.hidden = false -- equivalent to nohidden, prevents unsaved hidden buffers
