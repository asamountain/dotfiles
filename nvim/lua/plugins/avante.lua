return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  build = "make",
  opts = {
    provider = "claude",
    claude = {
      model = "claude-sonnet-4-6",
      max_tokens = 4096,
    },
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "nvim-treesitter/nvim-treesitter",
    {
      "MeanderingProgrammer/render-markdown.nvim",
      opts = { file_types = { "markdown", "Avante" } },
      ft = { "markdown", "Avante" },
    },
  },
}
