return {
  "ibhagwan/fzf-lua",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    local fzf_lua = require("fzf-lua")
    local actions = require("fzf-lua.actions")
    local trouble_actions = require("trouble.sources.fzf").actions

    local function send_to_qf_and_open(selected, opts)
      actions.file_sel_to_qf(selected, opts)
      vim.cmd("copen")
    end

    fzf_lua.setup({
      "telescope",
      keymap = {
        fzf = {
          true,
          ["ctrl-j"] = "down",
          ["ctrl-k"] = "up",
        },
      },
      actions = {
        files = {
          true,
          ["ctrl-q"] = send_to_qf_and_open,
          ["ctrl-t"] = trouble_actions.open,
        },
      },
    })

    -- set keymaps
    local keymap = vim.keymap -- for conciseness

    keymap.set("n", "<leader>ff", "<cmd>FzfLua files<cr>", { desc = "Fuzzy find files in cwd" })
    keymap.set("n", "<leader>fr", "<cmd>FzfLua oldfiles<cr>", { desc = "Fuzzy find recent files" })
    keymap.set("n", "<leader>fs", "<cmd>FzfLua live_grep<cr>", { desc = "Find string in cwd" })
    keymap.set("n", "<leader>fc", "<cmd>FzfLua grep_cword<cr>", { desc = "Find string under cursor in cwd" })
    keymap.set("n", "<leader>ft", "<cmd>TodoFzfLua<cr>", { desc = "Find todos" })
    keymap.set("n", "<leader>fk", "<cmd>FzfLua keymaps<cr>", { desc = "Find todos" })
  end,
}
