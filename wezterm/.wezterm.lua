local wezterm = require("wezterm")
local act = wezterm.action
-- 1. PANCERNE ŁADOWANIE PLUGINU
-- Pobieramy ścieżkę do Twojego katalogu domowego
local home = wezterm.home_dir
-- Dodajemy ścieżkę do pluginu do wyszukiwarki Lua
package.path = package.path .. ";" .. home .. "/.config/wezterm/plugins/resurrect.wezterm/src/?.lua"

-- Próbujemy załadować plugin (używamy pcall, żeby terminal nie wybuchł przy błędzie)
local ok, resurrect = pcall(require, "init")
if not ok then
	wezterm.log_error("Błąd ładowania resurrect: " .. resurrect)
end

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
	color_scheme = "Catppuccin Macchiato", -- lub Twój ulubiony
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

-- 4. OBSŁUGA RESURRECT (Nowe skróty i Auto-save)
if ok then
	-- Ręczny zapis: Cmd + Shift + S
	table.insert(config.keys, {
		key = "S",
		mods = "CTRL|SHIFT",
		action = wezterm.action_callback(function(win, pane)
			resurrect.save_state(resurrect.workspace_state.get_workspace_state())
			win:toast_notification("WezTerm", "Stan sesji zapisany!", nil, 3000)
		end),
	})

	-- Przywracanie: Cmd + Shift + R
	table.insert(config.keys, {
		key = "R",
		mods = "CTRL|SHIFT",
		action = wezterm.action_callback(function(win, pane)
			resurrect.fuzzy_load(win, pane, function(id, label)
				id = string.match(id, "([^/]+)$")
				resurrect.workspace_state.restore_workspace_state(id)
			end, { title = "Wybierz sesję do przywrócenia" })
		end),
	})

	-- AUTOMATYCZNY ZAPIS co 15 minut (900 000 ms)
	wezterm.time_update_callback(function()
		resurrect.save_state(resurrect.workspace_state.get_workspace_state())
	end, 900000)
end

return config
