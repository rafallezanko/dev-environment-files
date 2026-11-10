return {
  "mrjones2014/smart-splits.nvim",
  -- poza herdr (goły terminal, Rex, wezterm, zellij); wewnątrz herdr te same
  -- klawisze obsługuje herdr-splits.lua
  cond = vim.env.HERDR_ENV ~= "1",
  config = function()
    require("smart-splits").setup({
      -- W Rex (TERM_PROGRAM=rex) na krawędzi oddajemy ruch do Rex: `rex focus <kierunek>`.
      -- Druga połowa integracji to akcja smart_nav w ~/.config/rex/init.lua, która
      -- w panelu z nvim przekazuje ctrl+hjkl do nvim. Poza Rex: zwykłe zawijanie.
      at_edge = function(ctx)
        if vim.env.TERM_PROGRAM == "rex" then
          local bin = vim.env.REX_BIN_DIR and (vim.env.REX_BIN_DIR .. "/rex") or "rex"
          vim.system({ bin, "focus", ctx.direction })
        else
          ctx.wrap()
        end
      end,
    })
    -- Mapowania Ctrl + hjkl
    vim.keymap.set("n", "<C-h>", require("smart-splits").move_cursor_left)
    vim.keymap.set("n", "<C-j>", require("smart-splits").move_cursor_down)
    vim.keymap.set("n", "<C-k>", require("smart-splits").move_cursor_up)
    vim.keymap.set("n", "<C-l>", require("smart-splits").move_cursor_right)
  end,
}
