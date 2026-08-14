return {
  "mrjones2014/smart-splits.nvim",
  -- poza herdr (goły terminal, wezterm, zellij); wewnątrz herdr te same
  -- klawisze obsługuje herdr-splits.lua
  cond = vim.env.HERDR_ENV ~= "1",
  config = function()
    require("smart-splits").setup({})
    -- Mapowania Ctrl + hjkl
    vim.keymap.set("n", "<C-h>", require("smart-splits").move_cursor_left)
    vim.keymap.set("n", "<C-j>", require("smart-splits").move_cursor_down)
    vim.keymap.set("n", "<C-k>", require("smart-splits").move_cursor_up)
    vim.keymap.set("n", "<C-l>", require("smart-splits").move_cursor_right)
  end,
}
