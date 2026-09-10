-- Catppuccin Macchiato — https://github.com/catppuccin/catppuccin

local palette = {
	black = 0xff181926, -- crust
	white = 0xffcad3f5, -- text
	red = 0xffed8796,
	green = 0xffa6da95,
	blue = 0xff8aadf4,
	yellow = 0xffeed49f,
	orange = 0xfff5a97f,
	magenta = 0xffc6a0f6,
	grey = 0xff6e738d, -- overlay0
	shadow = 0xff11111b,

	accent = {
		cyan = 0xff7dc4e4, -- sapphire
		purple = 0xffc6a0f6, -- mauve
		sage = 0xffa6da95, -- green
		rose = 0xffed8796, -- red
		gold = 0xffeed49f, -- yellow
		peach = 0xfff5a97f,
		teal = 0xff8bd5ca,
		steel = 0xffa5adcb, -- subtext0
		primary = 0xffc6a0f6, -- mauve
	},

	semantic = {
		error = 0xffed8796,
		warn = 0xfff5a97f,
		ok = 0xffa6da95,
		info = 0xff8aadf4,
	},

	highlight = 0xffb7bdf8, -- lavender
	bar = { bg = 0xcc24273a, border = 0xff363a4f }, -- base / surface0
	popup = { bg = 0xc01e2030, border = 0xff494d64 }, -- mantle / surface1
	bg1 = 0xff1e2030, -- mantle
	bg2 = 0xff363a4f, -- surface0
}

return {
	black = palette.black,
	white = palette.white,
	red = palette.red,
	green = palette.green,
	blue = palette.blue,
	yellow = palette.yellow,
	orange = palette.orange,
	magenta = palette.magenta,
	grey = palette.grey,
	shadow = palette.shadow,
	transparent = 0x00000000,

	sora = palette.accent,
	semantic = palette.semantic,
	highlight = palette.highlight,
	bar = palette.bar,
	popup = palette.popup,
	bg1 = palette.bg1,
	bg2 = palette.bg2,

	with_alpha = function(color, alpha)
		if alpha > 1.0 or alpha < 0.0 then
			return color
		end
		return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
	end,
}
