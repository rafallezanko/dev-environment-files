-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

if vim.fn.executable("lazygit") == 1 then
  vim.keymap.set("n", "<leader>lg", function()
    Snacks.lazygit({ cwd = LazyVim.root.git() })
  end, { desc = "Lazygit (Root Dir)" })
  vim.keymap.set("n", "<leader>lG", function()
    Snacks.lazygit()
  end, { desc = "Lazygit (cwd)" })
end

vim.keymap.set("n", "<leader>fT", function()
  Snacks.terminal(nil, { win = { position = "left" } })
end, { desc = "Terminal left" })
