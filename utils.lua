-- CLASS UTILS

---OOP. Extneds a class.
---Usage:
---```lua
---Animal = {}
---
---function Animal:new(name)
---    -- fields methods and so on
---end
---
---Cat = extended(Animal) -- Will inherit all fields and methods
---```
---@param parent table
---@return table
function extended(parent)
	local child = {}
	setmetatable(child, { __index = parent })
	return child
end

-- MISC UTILS

---Print the `text` with drop-shadow.
---@param text string String to print
---@param x number X position of the text
---@param y number Y position of the text
---@param r? number Red component of the color
---@param g? number Green component of the color
---@param b? number Blue component of the color
---@param sR? number Red component of the shadow color
---@param sG? number Green component of the shadow color
---@param sB? number Blue component of the shadow color
function printShadow(text, x, y, r, g, b, sR, sG, sB)
	if sR and sG and sB then
		love.graphics.setColor(sR, sG, sB)
	else
		love.graphics.setColor(0.25, 0.25, 0.25)
	end
	love.graphics.print(text, Font, x + 2, y + 2)
	if r and g and b then
		love.graphics.setColor(r, g, b)
	else
		love.graphics.setColor(1, 1, 1)
	end
	love.graphics.print(text, Font, x, y)
end

---love.graphics.setColor but uses hex string.
---Yoinked from https://love2d.org/wiki/love.math.colorFromBytes#Example
---@param rgba string Hex string (e.g. "#RRGGBBAA")
function setColorHEX(rgba)
	assert(rgba:sub(1, 1) == "#", "Hex string starts with `#`!")
	assert(#rgba >= 7, "Too short hex color!")
	assert(#rgba <= 9, "Too long hex color!")
	local rb = tonumber(string.sub(rgba, 2, 3), 16)
	local gb = tonumber(string.sub(rgba, 4, 5), 16)
	local bb = tonumber(string.sub(rgba, 6, 7), 16)
	local ab = tonumber(string.sub(rgba, 8, 9), 16) or nil
	love.graphics.setColor(love.math.colorFromBytes(rb, gb, bb, ab))
end

---Checks, if game is running in debug mode(`--debug` flag)
---@return boolean
function isDebug()
	-- Debug flag need to be last flag!
	if arg[#arg] == "-debug" or arg[#arg] == "--debug" then
		return true
	else
		return false
	end
end
