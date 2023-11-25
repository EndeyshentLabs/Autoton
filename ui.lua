require("lib.32log")

---@class ImageButton
---@field x integer
---@field y integer
---@field w integer Width
---@field h integer Height
---@field image love.Image
---@field callback function
---@field new function<integer, integer, integer, integer, love.Image, function>
ImageButton = {}
class("ImageButton")({
	x = 0,
	y = 0,
	w = 0,
	h = 0,
	image = love.graphics.newImage("res/gfx/ohno.png"),
	callback = function()
		assert(false, "Callback is not implemented! Please implement it when creating new instance of ImageButton.")
	end,
})

---@param x integer
---@param y integer
---@param w integer Width
---@param h integer Height
---@param image love.Image
---@param callback function
function ImageButton:__init(x, y, w, h, image, callback)
	self.x = x
	self.y = y
	self.w = w
	self.h = h
	self.image = image or love.graphics.newImage("res/gfx/ohno.png")
	self.callback = callback
		or function()
			assert(false, "Callback is not implemented! Please implement it when creating new instance of ImageButton.")
		end
end

function ImageButton:update()
	if
		love.mouse.getX() >= self.x
		and love.mouse.getX() <= self.x + self.w
		and love.mouse.getY() >= self.y
		and love.mouse.getY() <= self.y + self.h
	then
		self.callback()
	end
end

function ImageButton:draw()
	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(self.image, self.x, self.y, 0, self.w / self.image:getWidth(), self.h / self.image:getHeight())
end
