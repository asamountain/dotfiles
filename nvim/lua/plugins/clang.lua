-- C/C++ development setup
return {
  -- Install extra tools via Mason
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "clangd",        -- LSP (already installed, kept here for fresh machines)
        "clang-format",  -- formatter
        "codelldb",      -- debugger (DAP)
        "cmake-language-server",
      })
    end,
  },

  -- Treesitter: add cmake parser alongside c/cpp (clangd extra adds c & cpp)
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, { "cmake" })
    end,
  },

  -- clangd: point to compile_commands.json and enable extra features
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        clangd = {
          cmd = {
            "clangd",
            "--background-index",          -- index in background for faster startup
            "--clang-tidy",                -- enable clang-tidy diagnostics
            "--header-insertion=iwyu",     -- include-what-you-use style
            "--completion-style=detailed", -- rich completions
            "--function-arg-placeholders", -- fill in argument names on completion
          },
          init_options = {
            usePlaceholders = true,
            completeUnimported = true,
            clangdFileStatus = true,  -- show file status in statusline
          },
        },
      },
    },
  },

  -- clang-format: use conform.nvim (LazyVim's default formatter)
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        c = { "clang_format" },
        cpp = { "clang_format" },
        h = { "clang_format" },
        hpp = { "clang_format" },
      },
    },
  },
}
