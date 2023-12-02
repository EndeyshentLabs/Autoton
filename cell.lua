require("content")

Cells = {}

CellSize = 64

---@enum CellType
CellType = {
	NONE = 0,
	GENERATOR = 1,
	CONVEYOR = 2,
	JUNCTION = 3,
	ORE = 4,
	CORE = 5,
}

function CellType.tostring(cellType)
	if cellType == CellType.GENERATOR then
		return "GENERATOR"
	elseif cellType == CellType.CONVEYOR then
		return "CONVEYOR"
	elseif cellType == CellType.JUNCTION then
		return "JUNCTION"
	elseif cellType == CellType.ORE then
		return "ORE"
	elseif cellType == CellType.CORE then
		return "CORE"
	elseif cellType == CellType.NONE then
		return "(void)"
	end
end

protectEnum(CellType)

---@enum Direction
Direction = {
	RIGHT = 0,
	DOWN = 1,
	LEFT = 2,
	UP = 3,
}

protectEnum(Direction)

---@class Cell
---@field x integer
---@field y integer
---@field type CellType
---@field direction Direction
---@field content Content
---@field progress number
---@field under Cell|nil
---@field update function
---@field draw function
Cell = {}

---Cell class constructor
---@param x integer
---@param y integer
---@param type CellType
---@param direction? integer
---@param content? Content
---@param under? Cell
---@return Cell
function Cell:new(x, y, type, direction, content, under)
	local public = {}
	public.x = x
	public.y = y
	public.type = type
	public.direction = direction or Direction.RIGHT
	public.content = content or Content:new()
	public.under = under
	--- In percents
	public.progress = 0

	--- cellTime - how long would it take for block to do something (in secs)
	--- In seconds
	local generatorTime = 2
	--- In seconds
	local conveyorTime = 1

	--- Get reference to a cell positioned at `relX` and `relY` relatively to `self` cell
	---@param relX? integer
	---@param relY? integer
	---@return Cell|nil
	function public:lookup(relX, relY)
		relX = relX or 0
		relY = relY or 0
		if (self.x + relX <= 0 or self.x + relX > CellAmount) or (self.y + relY <= 0 or self.x + relX > CellAmount) then
			return nil
		end
		return Cells[self.x + relX][self.y + relY]
	end

	function public:updateGenerator(dt)
		local cellUnder = self:lookup(0, 1)
		if
			not cellUnder
			or cellUnder.type ~= CellType.CONVEYOR
			or not self.under
			or self.under.content.name == DEFAULT_CONTENT_NAME
		then
			return
		end

		self.progress = self.progress + dt * (100 / generatorTime)

		local updated = false
		if
			(cellUnder.content.name == self.under.content.name or cellUnder.content.name == DEFAULT_CONTENT_NAME)
			and self.progress >= 100
		then
			cellUnder.content.name = self.under.content.name
			cellUnder.content.amount = cellUnder.content.amount + 1

			updated = true
		end

		if self.progress >= 100 and updated then
			self.progress = 0
		end
	end

	function public:updateConveyor(dt)
		if self.content.amount <= 0 then
			self.content.name = DEFAULT_CONTENT_NAME
			return
		end

		local offset = { ["x"] = 0, ["y"] = 0 }

		if self.direction == Direction.RIGHT then
			offset.x = 1
		elseif self.direction == Direction.DOWN then
			offset.y = 1
		elseif self.direction == Direction.LEFT then
			offset.x = -1
		elseif self.direction == Direction.UP then
			offset.y = -1
		end

		local dstCell = self:lookup(offset.x, offset.y)
		if not dstCell then
			return
		end

		if
			not dstCell
			or (dstCell.type ~= CellType.CONVEYOR and dstCell.type ~= CellType.CORE)
			or self.content.amount == 0
			or (dstCell.content.name ~= self.content.name and dstCell.content.name ~= DEFAULT_CONTENT_NAME)
		then
			return
		end

		self.progress = self.progress + dt * (100 / conveyorTime)

		local updated = false
		if dstCell.type == CellType.CORE and self.progress >= 100 then
			Core:add(self.content)

			self.content = Content:new()

			updated = true
		elseif
			(dstCell.content.name == self.content.name or dstCell.content.name == DEFAULT_CONTENT_NAME)
			and self.progress >= 100
		then
			local sub = 3
			dstCell.content.name = self.content.name

			if self.content.amount < 3 then
				sub = self.content.amount
			end

			assert(sub <= 3 and sub > 0, "0 < sub <= 3 (current " .. sub .. ")")

			dstCell.content.amount = dstCell.content.amount + sub

			self.content.amount = self.content.amount - sub

			updated = true
		end

		if self.progress >= 100 and updated then
			self.progress = 0
		end
	end

	---@diagnostic disable-next-line: unused-local
	function public:updateJunction(dt)
		local inputOffset = {}
		inputOffset.x = 0
		inputOffset.y = 0

		if self.x - 1 > 0 and self.x + 1 <= CellAmount then
			if self:lookup(-1).type == CellType.CONVEYOR and self:lookup(-1).direction == Direction.RIGHT then
				inputOffset.x = -1
			elseif self:lookup(1).type == CellType.CONVEYOR and self:lookup(1).direction == Direction.LEFT then
				inputOffset.x = 1
			else
				goto next
			end

			local outputCell = self:lookup(-inputOffset.x)
			if not outputCell or outputCell.type ~= CellType.CONVEYOR then
				goto next
			end

			if inputOffset.x ~= 0 then
				local inputCell = self:lookup(inputOffset.x)
				if not inputCell or inputCell.content.name == DEFAULT_CONTENT_NAME then
					goto next
				end

				if
					(inputCell and outputCell)
					and (
						inputCell.content.name == outputCell.content.name
						or outputCell.content.name == DEFAULT_CONTENT_NAME
					)
				then
					outputCell.content.name = inputCell.content.name
					outputCell.content.amount = outputCell.content.amount + inputCell.content.amount
					inputCell.content.amount = 0
					inputCell.content.name = DEFAULT_CONTENT_NAME
				end
			end
		end

		::next::

		if self.y - 1 > 0 and self.y + 1 <= CellAmount then
			if self:lookup(0, -1).type == CellType.CONVEYOR and self:lookup(0, -1).direction == Direction.DOWN then
				inputOffset.y = -1
			elseif self:lookup(0, 1).type == CellType.CONVEYOR and self:lookup(0, 1).direction == Direction.UP then
				inputOffset.y = 1
			else
				return
			end

			local outputCell = self:lookup(0, -inputOffset.y)
			if not outputCell or outputCell.type ~= CellType.CONVEYOR then
				return
			end

			if inputOffset.y ~= 0 then
				local inputCell = self:lookup(0, inputOffset.y)
				if
					(inputCell and outputCell)
					and (
						inputCell.content.name == outputCell.content.name
						or outputCell.content.name == DEFAULT_CONTENT_NAME
					)
				then
					outputCell.content.name = inputCell.content.name
					outputCell.content.amount = outputCell.content.amount + inputCell.content.amount
					inputCell.content.amount = 0
					inputCell.content.name = DEFAULT_CONTENT_NAME
				end
			end
		end
	end

	function public:update(dt)
		if self.type == CellType.GENERATOR then
			self:updateGenerator(dt)
		elseif self.type == CellType.CONVEYOR then
			self:updateConveyor(dt)
		elseif self.type == CellType.JUNCTION then
			self:updateJunction(dt)
		elseif self.type == CellType.ORE or self.type == CellType.NONE then
			if self.progress ~= 0 then
				self.progress = 0
			end
		end
	end

	function public:draw()
		if self.under then
			drawCell(self.under)
		end

		drawCell(self)

		love.graphics.setColor(0.5, 0.5, 0.5)
		local camX = CameraX - Width / 2
		local camY = CameraY - Height / 2

		if
			(self.x * CellSize - CellSize >= CameraX + Width / 2)
			or (self.x * CellSize <= camX)
			or (self.y * CellSize - CellSize >= CameraY + Height / 2)
			or (self.y * CellSize <= camY)
		then
			return
		end

		love.graphics.print(
			("%s\n%d\n%d%%"):format(self.content.name, self.content.amount, self.progress),
			(self.x - 1) * CellSize + 1,
			(self.y - 1) * CellSize + 1
		)

		if self.progress > 0 and ShowProgress then
			love.graphics.rectangle(
				"fill",
				self.x * CellSize - CellSize,
				self.y * CellSize - 8,
				CellSize * self.progress / 100,
				8
			)
		end
	end

	setmetatable(public, self)
	self.__index = self
	return public
end

---Returns cell's sprite based on it's type
---@param cell Cell
---@return love.Image|nil
function imageFromCell(cell)
	local type = cell.type

	if type == CellType.CONVEYOR then
		return Images.conveyor
	elseif type == CellType.JUNCTION then
		return Images.junction
	elseif type == CellType.GENERATOR then
		return Images.generator
	elseif type == CellType.CORE then
		return Images.core
	elseif type == CellType.ORE then
		if cell.content.name == ContentType.IRON then
			return Images.ore_iron
		elseif cell.content.name == ContentType.GOLD then
			return Images.ore_gold
		end
	end

	return nil
end

---@param cell Cell
function drawCell(cell)
	local camX = CameraX - Width / 2
	local camY = CameraY - Height / 2

	if
		(cell.x * CellSize - CellSize >= CameraX + Width / 2)
		or (cell.x * CellSize <= camX)
		or (cell.y * CellSize - CellSize >= CameraY + Height / 2)
		or (cell.y * CellSize <= camY)
	then
		return
	end

	local image = imageFromCell(cell)

	if image then
		local offsetX = 0
		local offsetY = 0

		if cell.direction == Direction.DOWN then
			offsetX = CellSize
		elseif cell.direction == Direction.LEFT then
			offsetX = CellSize
			offsetY = CellSize
		elseif cell.direction == Direction.UP then
			offsetY = CellSize
		end

		love.graphics.setColor(1, 1, 1)
		love.graphics.draw(
			image,
			(cell.x - 1) * CellSize + offsetX,
			(cell.y - 1) * CellSize + offsetY,
			cell.direction * math.rad(90),
			CellSize / 128,
			CellSize / 128
		)
	end
end
