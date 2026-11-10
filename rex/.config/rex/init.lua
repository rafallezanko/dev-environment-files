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

-- alt+d: jump between agents that need attention, like Herdr's herdr-agent-jump.sh.
-- Priority blocked > done > working (the first non-empty group wins), cycling in
-- sidebar order starting after the focused pane. Statuses come from what programs
-- report (OSC 7501), e.g. Claude Code with Rex's hooks.
local terminal = "com.superlogical.terminal"
local jump_priority = { "blocked", "done", "working" }

rex.action{
  name  = "agent_jump",
  title = "Jump to Agent Needing Attention",
  args  = { dry_run = "boolean?" },
  run   = function(ctx, args)
    local panes = {}
    -- list_blocks only answers for sessions this action's stream is attached to
    rex.call("session.attach_all", { event_scope = "all" })
    local sessions = rex.call("session.list", {})
    for _, s in ipairs(sessions and sessions.sessions or {}) do
      local list = rex.call("session.list_blocks", { session_id = s.session_id })
      for _, b in ipairs(list and list.blocks or {}) do
        if b.creator_name == terminal and b.placement == "placed" then
          local st = rex.block.call(terminal, "program_status",
            { session_id = s.session_id, block_id = b.block_id })
          local states = {}
          for _, r in ipairs(st and st.records or {}) do states[r.state] = true end
          table.insert(panes, { session_id = s.session_id, window_id = b.window_id,
                                block_id = b.block_id, states = states })
        end
      end
    end

    local current = 0
    for i, p in ipairs(panes) do
      if p.block_id == ctx.block_id then current = i end
    end

    for _, state in ipairs(jump_priority) do
      for step = 1, #panes do
        local p = panes[(current + step - 1) % #panes + 1]
        if p.states[state] then
          if args.dry_run then return { state = state, target = p, panes = #panes } end
          rex.call("session.focus_block", { session_id = p.session_id, block_id = p.block_id })
          rex.client.queue("session.select", { session_id = p.session_id, window_id = p.window_id })
          return
        end
      end
    end
  end,
}

rex.bind("alt+d", "agent_jump")
