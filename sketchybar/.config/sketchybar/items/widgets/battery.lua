local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

local battery = sbar.add("item", "widgets.battery", {
	position = "right",
	icon = {
		font = {
			style = settings.font.style_map["Regular"],
			size = 16.0,
		},
		color = colors.sora.sage,
	},
	label = {
		string = "??%",
		font = {
			family = settings.font.numbers,
			style = settings.font.style_map["Bold"],
			size = 13.0,
		},
		width = 42,
	},
	padding_right = 1,
	padding_left = 1,
	update_freq = 120,
})

battery:subscribe({ "routine", "power_source_change", "system_woke", "forced" }, function()
	sbar.exec("pmset -g batt", function(batt_info)
		local found, _, charge = batt_info:find("(%d+)%%")
		if not found then
			return
		end
		charge = tonumber(charge)

		local charging = batt_info:find("AC Power")
		local icon = icons.battery._100
		local color = colors.sora.sage

		if charging then
			icon = icons.battery.charging
		elseif charge > 80 then
			icon = icons.battery._100
		elseif charge > 60 then
			icon = icons.battery._75
		elseif charge > 40 then
			icon = icons.battery._50
		elseif charge > 20 then
			icon = icons.battery._25
			color = colors.sora.gold
		else
			icon = icons.battery._0
			color = colors.semantic.error
		end

		battery:set({
			icon = { string = icon, color = color },
			label = { string = charge .. "%", color = color },
		})
	end)
end)

battery:subscribe("mouse.clicked", function()
	sbar.exec("open 'x-apple.systempreferences:com.apple.preference.battery'")
end)

sbar.add("bracket", "widgets.battery.bracket", { battery.name }, {
	background = { color = colors.bar.bg },
})

sbar.add("item", "widgets.battery.padding", {
	position = "right",
	width = settings.group_paddings,
})
