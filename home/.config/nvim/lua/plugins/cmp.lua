return {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
        "hrsh7th/cmp-buffer", -- source for text in buffer
        "hrsh7th/cmp-path", -- source for file system paths
        "petertriho/cmp-git", -- source for git files
        {
            "L3MON4D3/LuaSnip",
            version = "v2.*",
            -- install jsregexp (optional!).
            build = "make install_jsregexp"
        }, "rafamadriz/friendly-snippets", "onsails/lspkind.nvim" -- vs-code like pictograms
    },
    config = function()
        local cmp = require("cmp")
        local lspkind = require("lspkind")
        local luasnip = require("luasnip")

        require("luasnip.loaders.from_vscode").lazy_load()

        cmp.setup({
            snippet = {
                expand = function(args)
                    luasnip.lsp_expand(args.body)
                end
            },
            mapping = cmp.mapping.preset.insert({
                ["<C-d>"] = cmp.mapping.scroll_docs(-4),
                ["<C-f>"] = cmp.mapping.scroll_docs(4),
                ["<C-Space>"] = cmp.mapping.complete(),
                ["<C-e>"] = cmp.mapping.close(),
                ["<CR>"] = cmp.mapping.confirm({
                    behavior = cmp.ConfirmBehavior.Replace,
                    select = true
                })
            }),
            sources = cmp.config.sources({
                {name = "nvim_lsp"}, {name = "luasnip"}, {name = "buffer"},
                {name = "path"}
            })

        })

        -- To use git you need to install the plugin petertriho/cmp-git and uncomment lines below
        -- Set configuration for specific filetype.
        cmp.setup.filetype('gitcommit', {
            sources = cmp.config.sources({{name = 'git'}}, {{name = 'buffer'}})
        })
        require("cmp_git").setup()

        -- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
        cmp.setup.cmdline({'/', '?'}, {
            mapping = cmp.mapping.preset.cmdline(),
            sources = {{name = 'buffer'}}
        })

        -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
        cmp.setup.cmdline(':', {
            mapping = cmp.mapping.preset.cmdline(),
            sources = cmp.config
                .sources({{name = 'path'}}, {{name = 'cmdline'}}),
            matching = {disallow_symbol_nonprefix_matching = false}
        })

        vim.cmd([[
      set completeopt=menuone,noinsert,noselect
      highlight! default link CmpItemKind CmpItemMenuDefault
    ]])
    end
}
