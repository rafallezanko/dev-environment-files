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
  "java",
  "kotlin",
  "scala",
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
    local to_install = vim.tbl_filter(function(lang)
      return not pcall(vim.treesitter.language.add, lang)
    end, langs)
    if #to_install > 0 then
      require("nvim-treesitter").install(to_install)
    end

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

        local ok = pcall(vim.treesitter.start)
        if ok then
          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}
