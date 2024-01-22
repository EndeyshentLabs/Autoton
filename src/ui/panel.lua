Panel = {}
Panel.name = ""
Panel.description = ""

function Panel:clear()
	self.name = ""
	self.description = ""
end

function Panel:update() end

function Panel:draw()
	love.graphics.setColor(0.05, 0.05, 0.05)
	love.graphics.rectangle("fill", 0, 0, ButtonColumnCount * ButtonSize, Height)
end
