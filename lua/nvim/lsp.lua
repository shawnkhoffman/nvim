-- local sumneko_root_path = "/usr/lib/lua-language-server"
-- local sumneko_binary = sumneko_root_path .. "/bin/Linux/lua-language-server"
vim.lsp.set_log_level("debug")
local util = require"lspconfig".util

local cmp_status_ok, cmp = pcall(require, "cmp")
if not cmp_status_ok then return end

local cmp_dap_status_ok, cmp_dap = pcall(require, "cmp_dap")
if not cmp_dap_status_ok then return end

local snip_status_ok, luasnip = pcall(require, "luasnip")
if not snip_status_ok then return end

local check_backspace = function()
    local col = vim.fn.col "." - 1
    return col == 0 or vim.fn.getline("."):sub(col, col):match "%s"
end

local icons = require "nvim.icons"

local kind_icons = icons.kind

-- Setup nvim-cmp.
cmp.setup {
    snippet = {
        -- REQUIRED - you must specify a snippet engine
        expand = function(args)
            luasnip.lsp_expand(args.body) -- For `luasnip` users.
        end
    },

    enabled = function()
        return vim.api.nvim_buf_get_option(0, "buftype") ~= "prompt" or cmp_dap.is_dap_buffer()
    end,
    mapping = cmp.mapping.preset.insert {
        ["<C-k>"] = cmp.mapping.select_prev_item(),
        ["<C-j>"] = cmp.mapping.select_next_item(),
        ["<C-b>"] = cmp.mapping(cmp.mapping.scroll_docs(-1), {"i", "c"}),
        ["<C-f>"] = cmp.mapping(cmp.mapping.scroll_docs(1), {"i", "c"}),
        ["<C-Space>"] = cmp.mapping(cmp.mapping.complete(), {"i", "c"}),
        -- ["<C-y>"] = cmp.config.disable, -- Specify `cmp.config.disable` if you want to remove the default `<C-y>` mapping.
        ["<C-e>"] = cmp.mapping {i = cmp.mapping.abort(), c = cmp.mapping.close()},
        -- Accept currently selected item. If none selected, `select` first item.
        -- Set `select` to `false` to only confirm explicitly selected items.
        ["<CR>"] = cmp.mapping.confirm {select = true},
        ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_next_item()
            elseif luasnip.expandable() then
                luasnip.expand()
            elseif luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
            elseif check_backspace() then
                fallback()
            else
                fallback()
            end
        end, {"i", "s"}),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
                luasnip.jump(-1)
            else
                fallback()
            end
        end, {"i", "s"})
    },
    formatting = {
        fields = {"kind", "abbr", "menu"},
        format = function(entry, vim_item)
            -- Kind icons
            vim_item.kind = string.format("%s", kind_icons[vim_item.kind])

            if entry.source.name == "cmp_tabnine" then
                -- if entry.completion_item.data ~= nil and entry.completion_item.data.detail ~= nil then
                -- menu = entry.completion_item.data.detail .. " " .. menu
                -- end
                vim_item.kind = icons.misc.Robot
            end
            -- vim_item.kind = string.format('%s %s', kind_icons[vim_item.kind], vim_item.kind) -- This concatonates the icons with the name of the item kind
            -- NOTE: order matters
            vim_item.menu = ({
                -- nvim_lsp = "[LSP]",
                -- nvim_lua = "[Nvim]",
                -- luasnip = "[Snippet]",
                -- buffer = "[Buffer]",
                -- path = "[Path]",
                -- emoji = "[Emoji]",

                nvim_lsp = "",
                nvim_lua = "",
                luasnip = "",
                buffer = "",
                path = "",
                emoji = "",
                dap = ""
            })[entry.source.name]
            return vim_item
        end
    },
    sources = {
        {name = "nvim_lsp"}, {name = "nvim_lua"}, {name = "luasnip"}, {name = "buffer"},
        {name = "cmp_tabnine"}, {name = "path"}, {name = "emoji"}, {name = "dap"}
    },
    confirm_opts = {behavior = cmp.ConfirmBehavior.Replace, select = false},
    -- documentation = true,
    window = {
        -- documentation = "native",
        documentation = {
            border = {"╭", "─", "╮", "│", "╯", "─", "╰", "│"},
            winhighlight = "NormalFloat:Pmenu,NormalFloat:Pmenu,CursorLine:PmenuSel,Search:None"
        },
        completion = {
            border = {"╭", "─", "╮", "│", "╯", "─", "╰", "│"},
            winhighlight = "NormalFloat:Pmenu,NormalFloat:Pmenu,CursorLine:PmenuSel,Search:None"
        }
    },
    experimental = {
        ghost_text = true
        -- native_menu = false,
    }
}

-- Setup lspconfig.
local function config(_config)
    return vim.tbl_deep_extend("force", {
        capabilities = require("cmp_nvim_lsp").update_capabilities(vim.lsp.protocol.make_client_capabilities())
    }, _config or {})
end

local runtime_path = vim.split(package.path, ';')
table.insert(runtime_path, "lua/?.lua")
table.insert(runtime_path, "lua/?/init.lua")

local lsp_installer = require("nvim-lsp-installer")

-- Register a handler that will be called for all installed servers.
-- Alternatively, you may also register handlers on specific server instances instead (see example below).
local function make_server_ready()
    lsp_installer.on_server_ready(function(server)
        local opts = config()

        -- (optional) Customize the options passed to the server
        if server.name == "sumneko_lua" then
            opts.settings = {
                Lua = {
                    runtime = {
                        -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
                        version = 'LuaJIT',
                        -- Setup your lua path
                        path = runtime_path
                    },
                    diagnostics = {
                        -- Get the language server to recognize the `vim` global
                        globals = {'vim'}
                    },
                    workspace = {
                        -- Make the server aware of Neovim runtime files
                        library = vim.api.nvim_get_runtime_file("", true)
                    },
                    -- Do not send telemetry data containing a randomized but unique identifier
                    telemetry = {enable = false}
                }
            }
        end

        if server.name == "efm" then
            opts = {
                init_options = {documentFormatting = true},
                filetypes = {"lua"},
                settings = {
                    rootMarkers = {".git/"},
                    languages = {
                        lua = {
                            {
                                formatCommand = "lua-format -i --no-keep-simple-function-one-line --no-break-after-operator --column-limit=110 --break-after-table-lb",
                                formatStdin = true
                            }
                        }
                    }
                }
            }
        end
        server:setup(opts)
    end)
end

---------------------------------------------------

---------------------------------------------------
local function install_server(server)
    local lsp_installer_servers = require 'nvim-lsp-installer.servers'
    local ok, server_analyzer = lsp_installer_servers.get_server(server)
    if ok then if not server_analyzer:is_installed() then server_analyzer:install(server) end end
end
---------------------------------------------------

---------------------------------------------------
local servers = {
    'bashls', 'dockerls', 'eslint', 'sumneko_lua', 'gopls', 'pyright', 'rust_analyzer', 'terraformls',
    'vimls', 'yamlls', 'ansiblels', 'cssls', 'dotls', 'jsonls', 'hls', 'pylsp', 'cmake', 'graphql', 'tflint',
    'tsserver', 'efm'
}

-- setup the LS
make_server_ready() -- LSP mappings

-- install the LS

for _, server in ipairs(servers) do install_server(server) end

require("luasnip/loaders/from_vscode").load()
require("luasnip/loaders/from_vscode").lazy_load()
