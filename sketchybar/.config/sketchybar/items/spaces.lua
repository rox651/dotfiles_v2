local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

local SPACE_COUNT = 8

sbar.add("event", "aerospace_refresh")

local spaces = {}
local space_brackets = {}

local function set_space_highlight(i, selected)
	spaces[i]:set({
		icon = { highlight = selected },
		label = { highlight = selected },
		background = { border_color = selected and colors.highlight or colors.bar.bg },
	})
	space_brackets[i]:set({
		background = { border_color = selected and colors.grey or colors.bg2 },
	})
end

local function refresh_workspaces()
	sbar.exec("aerospace list-windows --all --format '%{workspace}|%{app-name}'", function(out)
		local apps_by_ws = {}
		for i = 1, SPACE_COUNT do
			apps_by_ws[i] = {}
		end

		for line in string.gmatch(out or "", "[^\r\n]+") do
			local ws, app = line:match("^([^|]+)|(.+)$")
			local n = tonumber(ws)
			if n and n >= 1 and n <= SPACE_COUNT and app and app ~= "" then
				apps_by_ws[n][app] = true
			end
		end

		for i = 1, SPACE_COUNT do
			local icon_line = ""
			local count = 0
			for app, _ in pairs(apps_by_ws[i]) do
				count = count + 1
				icon_line = icon_line .. " " .. (app_icons[app] or app_icons["default"])
			end
			if count == 0 then
				icon_line = " —"
			end
			spaces[i]:set({ label = { string = icon_line } })
		end
	end)

	sbar.exec("aerospace list-workspaces --focused", function(out)
		local focused = tonumber((out or ""):match("%d+"))
		for i = 1, SPACE_COUNT do
			set_space_highlight(i, i == focused)
		end
	end)
end

sbar.exec("nohup $CONFIG_DIR/helpers/aerospace_listener.sh >/dev/null 2>&1 &")

for i = 1, SPACE_COUNT do
	local space = sbar.add("item", "space." .. i, {
		position = "left",
		icon = {
			font = { family = settings.font.text, style = settings.font.style_map["Heavy"] },
			string = i,
			padding_left = 15,
			padding_right = 8,
			color = colors.white,
			highlight_color = colors.orange,
		},
		label = {
			padding_right = 20,
			color = colors.white,
			highlight_color = colors.sora.primary,
			font = "sketchybar-app-font:Regular:16.0",
			y_offset = -1,
		},
		padding_right = 1,
		padding_left = 1,
		background = {
			color = colors.bar.bg,
			border_width = 2,
			height = 28,
			border_color = colors.black,
		},
	})

	spaces[i] = space

	space_brackets[i] = sbar.add("bracket", { space.name }, {
		background = {
			color = colors.transparent,
			border_color = colors.bg2,
			height = 30,
			border_width = 2,
		},
	})

	sbar.add("item", "space.padding." .. i, {
		position = "left",
		width = settings.group_paddings,
	})

	space:subscribe("mouse.clicked", function(_)
		sbar.exec("aerospace workspace " .. i)
	end)
	space:subscribe("aerospace_refresh", refresh_workspaces)
end

local aerospace_observer = sbar.add("item", "aerospace_observer", {
	drawing = false,
	updates = true,
	update_freq = 2,
})
aerospace_observer:subscribe("aerospace_refresh", refresh_workspaces)
aerospace_observer:subscribe({ "forced", "routine" }, refresh_workspaces)

local spaces_indicator = sbar.add("item", {
	padding_left = -3,
	padding_right = 0,
	icon = {
		padding_left = 8,
		padding_right = 9,
		color = colors.grey,
		string = icons.switch.on,
	},
	label = {
		width = 0,
		padding_left = 0,
		padding_right = 8,
		string = "Spaces",
		color = colors.bg1,
	},
	background = {
		color = colors.with_alpha(colors.grey, 0.0),
		border_color = colors.with_alpha(colors.bg1, 0.0),
	},
})

spaces_indicator:subscribe("swap_menus_and_spaces", function(_)
	local currently_on = spaces_indicator:query().icon.value == icons.switch.on
	spaces_indicator:set({
		icon = currently_on and icons.switch.off or icons.switch.on,
	})
end)

spaces_indicator:subscribe("mouse.entered", function(_)
	sbar.animate("tanh", 30, function()
		spaces_indicator:set({
			background = {
				color = { alpha = 1.0 },
				border_color = { alpha = 1.0 },
			},
			icon = { color = colors.bg1 },
			label = { width = "dynamic" },
		})
	end)
end)

spaces_indicator:subscribe("mouse.exited", function(_)
	sbar.animate("tanh", 30, function()
		spaces_indicator:set({
			background = {
				color = { alpha = 0.0 },
				border_color = { alpha = 0.0 },
			},
			icon = { color = colors.grey },
			label = { width = 0 },
		})
	end)
end)

spaces_indicator:subscribe("mouse.clicked", function(_)
	sbar.trigger("swap_menus_and_spaces")
end)

refresh_workspaces()
