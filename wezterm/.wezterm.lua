local wezterm = require("wezterm")
local act = wezterm.action
local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")

local function is_vim(pane)
	-- Sprawdzamy procesy w panelu
	local process_info = pane:get_foreground_process_info()
	if process_info then
		-- Przeszukujemy listę procesów (przydatne przy aliasach i skryptach)
		for _, proc in ipairs(pane:get_foreground_process_info()) do
			if proc.name:find("n?vim") then
				return true
			end
		end
	end

	-- Dodatkowy check na wypadek, gdyby info o procesie było niepełne
	local process_name = pane:get_foreground_process_name()
	if process_name and process_name:find("n?vim") then
		return true
	end

	return pane:get_user_vars().IS_NVIM == "true"
end

local function split_nav(key, direction)
	return {
		key = key,
		mods = "CTRL",
		action = wezterm.action_callback(function(win, pane)
			if is_vim(pane) then
				win:perform_action({ SendKey = { key = key, mods = "CTRL" } }, pane)
			else
				win:perform_action({ ActivatePaneDirection = direction }, pane)
			end
		end),
	}
end

local config = {
	front_end = "WebGpu",
	color_scheme = "Tokyo Night",
	colors = {
		background = "#011628",
		foreground = "#CBE0F0",
		cursor_bg = "#CBE0F0",
		cursor_fg = "#011628",
		cursor_border = "#CBE0F0",
		selection_bg = "#275378",
		selection_fg = "#CBE0F0",
		split = "#547998",
		tab_bar = {
			background = "#011423",
			active_tab = {
				bg_color = "#011628",
				fg_color = "#CBE0F0",
			},
			inactive_tab = {
				bg_color = "#011423",
				fg_color = "#627E97",
			},
			inactive_tab_hover = {
				bg_color = "#143652",
				fg_color = "#CBE0F0",
			},
			new_tab = {
				bg_color = "#011423",
				fg_color = "#627E97",
			},
			new_tab_hover = {
				bg_color = "#143652",
				fg_color = "#CBE0F0",
			},
		},
	},
	hide_tab_bar_if_only_one_tab = true,

	-- Ustawienia dla nieaktywnych paneli
	inactive_pane_hsb = {
		saturation = 0.5, -- Zmniejsza nasycenie kolorów (0.0 = czarno-białe)
		brightness = 0.4, -- Mocne przyciemnienie (0.0 = całkiem czarne, 1.0 = normalne)
	},

	keys = {
		-- Smart Navigation Ctrl + hjkl
		split_nav("h", "Left"),
		split_nav("j", "Down"),
		split_nav("k", "Up"),
		split_nav("l", "Right"),

		-- Zoom (Maksymalizacja panelu) pod Alt + Z
		{ key = "m", mods = "ALT", action = act.TogglePaneZoomState },

		-- Zarządzanie Projektami (Workspaces)
		{ key = "w", mods = "ALT", action = act.ShowLauncherArgs({ flags = "WORKSPACES" }) },
		{
			key = "n",
			mods = "ALT",
			action = act.PromptInputLine({
				description = "Nazwa nowego projektu:",
				action = wezterm.action_callback(function(window, pane, line)
					if line then
						window:perform_action(act.SwitchToWorkspace({ name = line }), pane)
					end
				end),
			}),
		},
		{
			key = "L",
			mods = "CMD|SHIFT",
			action = wezterm.action_callback(function(window, pane)
				-- Otwórz nvim
				pane:send_text("v\n")

				-- Stwórz panel po prawej (30%) i odpal Claude
				local claude_pane = pane:split({ direction = "Right", size = 0.3 })
				claude_pane:send_text("jclaude.sh\n")

				-- Stwórz terminal pod Claudem
				claude_pane:split({ direction = "Bottom", size = 0.4 })
			end),
		},
		-- -- MAGICZNY PRZYCISK: Layout 70/30 (Alt + L)
		-- {
		-- 	key = "l",
		-- 	mods = "ALT",
		-- 	action = wezterm.action_callback(function(window, pane)
		-- 		-- 1. Odpal nvim w głównym panelu
		-- 		pane:send_text("v .\n")
		--
		-- 		-- 2. Split pionowy (30% na prawo)
		-- 		local claude_pane = pane:split({ direction = "Right", size = 0.3 })
		-- 		claude_pane:send_text("./jclaude.sh\n")
		--
		-- 		-- 3. Split poziomy pod Claudem
		-- 		claude_pane:split({ direction = "Bottom", size = 0.4 })
		-- 	end),
		-- },
	},
}

-- Ręczny zapis: Ctrl + Shift + S
table.insert(config.keys, {
	key = "S",
	mods = "CTRL|SHIFT",
	action = wezterm.action_callback(function(win, pane)
		resurrect.state_manager.save_state(resurrect.workspace_state.get_workspace_state())
		win:toast_notification("WezTerm", "Stan sesji zapisany!", nil, 3000)
	end),
})

-- Przywracanie: Ctrl + Shift + R
table.insert(config.keys, {
	key = "R",
	mods = "CTRL|SHIFT",
	action = wezterm.action_callback(function(win, pane)
		resurrect.fuzzy_loader.fuzzy_load(win, pane, function(id, label)
			local type = string.match(id, "^([^/]+)")
			id = string.match(id, "([^/]+)$")
			id = string.match(id, "(.+)%..+$")
			local opts = {
				relative = true,
				restore_text = true,
				on_pane_restore = resurrect.tab_state.default_on_pane_restore,
			}
			if type == "workspace" then
				local state = resurrect.state_manager.load_state(id, "workspace")
				resurrect.workspace_state.restore_workspace(state, opts)
			elseif type == "window" then
				local state = resurrect.state_manager.load_state(id, "window")
				resurrect.window_state.restore_window(pane:window(), state, opts)
			elseif type == "tab" then
				local state = resurrect.state_manager.load_state(id, "tab")
				resurrect.tab_state.restore_tab(pane:tab(), state, opts)
			end
		end, { title = "Wybierz sesję do przywrócenia" })
	end),
})

-- Automatyczny zapis co 15 minut
resurrect.state_manager.periodic_save()

return config
