local Util = require("util.common")

return {
  {
    "williamboman/mason.nvim",
    cmd = { "MasonInstallAll" },
    opts = function(_, opts)
      -- Create user command to synchronously install all Mason tools in `opts.ensure_installed`.
      vim.api.nvim_create_user_command("MasonInstallAll", function()
        for _, tool in ipairs(opts.ensure_installed) do
          vim.cmd("MasonInstall " .. tool)
        end
      end, {})

      return opts
    end,
  },

  -- do the same for mason lsp servers
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      -- Create user command to synchronously install all LSP servers in `opts.servers`.
      vim.api.nvim_create_user_command("LspInstallAll", function()
        for server, _ in pairs(opts.servers) do
          vim.cmd("LspInstall " .. server)
        end
      end, {})

      return opts
    end,
  },
}