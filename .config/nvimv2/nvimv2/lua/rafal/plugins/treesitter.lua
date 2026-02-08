local langs = {
  "json",
  "javascript",
  "typescript",
  "tsx",
  "yaml",
  "html",
  "css",
  "prisma",
  "markdown",
  "markdown_inline",
  "svelte",
  "graphql",
  "go",
  "gomod",
  "gowork",
  "gosum",
  "python",
  "bash",
  "lua",
  "vim",
  "dockerfile",
  "query",
  "vimdoc",
  "c",
}

return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  event = { "BufReadPre", "BufNewFile" },
  build = function()
    require("nvim-treesitter").install(langs):wait()
  end,
  config = function()
    vim.treesitter.language.register("bash", "zsh")

    vim.api.nvim_create_autocmd("FileType", {
      callback = function()
        local ft = vim.bo.filetype
        if ft == "" then
          return
        end

        local lang = vim.treesitter.language.get_lang(ft) or ft
        if not vim.list_contains(langs, lang) then
          return
        end

        vim.treesitter.start()
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })
  end,
}
