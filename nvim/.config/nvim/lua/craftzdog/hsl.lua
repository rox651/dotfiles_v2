local M = {}

local hexChars = "0123456789abcdef"

function M.hex_to_rgb(hex)
  hex = string.lower(hex)
  local ret = {}
  for i = 0, 2 do
    local char1 = string.sub(hex, i * 2 + 2, i * 2 + 2)
    local char2 = string.sub(hex, i * 2 + 3, i * 2 + 3)
    local digit1 = string.find(hexChars, char1) - 1
    local digit2 = string.find(hexChars, char2) - 1
    ret[i + 1] = (digit1 * 16 + digit2) / 255.0
  end
  return ret
end

function M.rgbToHsl(r, g, b)
  local max, min = math.max(r, g, b), math.min(r, g, b)
  local h = 0
  local s = 0
  local l = 0

  l = (max + min) / 2

  if max == min then
    h, s = 0, 0
  else
    local d = max - min
    if l > 0.5 then
      s = d / (2 - max - min)
    else
      s = d / (max + min)
    end
    if max == r then
      h = (g - b) / d
      if g < b then
        h = h + 6
      end
    elseif max == g then
      h = (b - r) / d + 2
    elseif max == b then
      h = (r - g) / d + 4
    end
    h = h / 6
  end

  return h * 360, s * 100, l * 100
end

function M.hexToHSL(hex)
  local rgb = M.hex_to_rgb(hex)
  local h, s, l = M.rgbToHsl(rgb[1], rgb[2], rgb[3])
  return string.format("hsl(%d, %d, %d)", math.floor(h + 0.5), math.floor(s + 0.5), math.floor(l + 0.5))
end

function M.replaceHexWithHSL()
  local line_number = vim.api.nvim_win_get_cursor(0)[1]
  local line_content = vim.api.nvim_buf_get_lines(0, line_number - 1, line_number, false)[1]

  for hex in line_content:gmatch("#[0-9a-fA-F]+") do
    local hsl = M.hexToHSL(hex)
    line_content = line_content:gsub(hex, hsl)
  end

  vim.api.nvim_buf_set_lines(0, line_number - 1, line_number, false, { line_content })
end

return M
