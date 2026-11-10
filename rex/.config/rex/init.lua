-- Migrated from Herdr (~/.config/herdr/config.toml) and Ghostty (~/.config/ghostty/config).

-- Herdr: zoom = "alt+m"
rex.bind("alt+m", "pane.zoom")

-- Pane navigation with ctrl+hjkl (replaces Herdr's herdr-splits plugin keys).
-- In a pane running (n)vim the key goes to the editor for its own split
-- navigation; elsewhere it moves focus between Rex panes.
local vim_names = { nvim = true, vim = true }

rex.action{
  name  = "smart_nav",
  title = "Focus Pane or Pass Key to Vim",
  args  = { dir = "string", key = "string" },
  run   = function(ctx, args)
    local p = rex.block.call("com.superlogical.terminal", "process", { block_id = ctx.block_id })
    if p and p.foreground and vim_names[p.foreground.name] then
      rex.client.queue("pane.send_key", { key = args.key })
    else
      rex.client.queue("pane.focus." .. args.dir)
    end
  end,
}

rex.bind("ctrl+h", "smart_nav", { dir = "left",  key = "ctrl+h" })
rex.bind("ctrl+j", "smart_nav", { dir = "down",  key = "ctrl+j" })
rex.bind("ctrl+k", "smart_nav", { dir = "up",    key = "ctrl+k" })
rex.bind("ctrl+l", "smart_nav", { dir = "right", key = "ctrl+l" })
