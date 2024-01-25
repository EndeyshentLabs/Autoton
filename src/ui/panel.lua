Panel = {}
Panel.format = ""

function Panel:clear()
	self.format = ""
end

function Panel:update()
	local x = love.mouse.getX() - Width / 2 + CameraX
	local y = love.mouse.getY() - Height / 2 + CameraY
	local a = math.ceil(x / CellSize)
	local b = math.ceil(y / CellSize)

	if a > CellAmount or b > CellAmount or a <= 0 or b <= 0 then
		Panel:clear()
		return
	end

	---@type Cell
	local cell = Cells[a][b]

	if cell.type == CellType.NONE and cell.under then
		---@type Cell
		cell = cell.under
	end

	if not cell.type.displayName then
		Panel:clear()
		return
	end

	self.format = "Name: " .. cell.type.displayName

	if cell.type.description and cell.type.description ~= "" then
		self.format = self.format .. "\nDescription:\n  " .. cell.type.description
	end

	if cell.type.time then
		self.format = self.format .. "\nSingle iteration: " .. cell.type.time .. "sec(s)"
	end

	if cell.type.maxCap then
		self.format = self.format .. "\nCapacity: " .. cell.type.maxCap
	end
end

function Panel:draw()
	love.graphics.setColor(0.05, 0.05, 0.05)
	love.graphics.rectangle("fill", 0, 0, ButtonColumnCount * ButtonSize, Height)

	love.graphics.setColor(0.15, 0.15, 0.15)
	love.graphics.rectangle("fill", 0, Height - 256, ButtonColumnCount * ButtonSize, 256)

	love.graphics.setColor(1, 1, 1)
	love.graphics.printf(self.format, 0, Height - 256, ButtonColumnCount * ButtonSize)
end
