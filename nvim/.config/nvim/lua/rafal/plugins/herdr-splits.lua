-- Port smart-splits.nvim pod herdr: ctrl+hjkl chodzi po splitach nvim,
-- a na krawędzi przeskakuje do sąsiedniego panelu herdr. Druga połowa
-- integracji to plugin serwerowy (`herdr plugin install lmilojevicc/herdr-splits.nvim`)
-- + bindy [[keys.command]] w herdr/config.toml — bez nich ctrl+hjkl
-- w ogóle nie dotrze do nvim.
return {
  "lmilojevicc/herdr-splits.nvim",
  -- tylko wewnątrz panelu herdr; poza nim klawisze trzyma smart-splits.lua
  cond = vim.env.HERDR_ENV == "1",
  config = function()
    require("herdr-splits").setup({
      -- na krawędzi nvim oddaje ruch do herdr (nie zawija w obrębie nvim)
      at_edge = "wrap",
      unzoom_on_nav = true,
    })
    -- Mapowania Ctrl + hjkl (jak w smart-splits.lua)
    vim.keymap.set("n", "<C-h>", require("herdr-splits").move_cursor_left)
    vim.keymap.set("n", "<C-j>", require("herdr-splits").move_cursor_down)
    vim.keymap.set("n", "<C-k>", require("herdr-splits").move_cursor_up)
    vim.keymap.set("n", "<C-l>", require("herdr-splits").move_cursor_right)
  end,
}
