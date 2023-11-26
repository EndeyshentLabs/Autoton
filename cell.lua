Cells = {}

---@enum ContentType
ContentType = {
	IRON = "iron",
	GOLD = "gold",
}

DEFAULT_CONTENT_NAME = "OH_NO"

---@class Content
---@field name string
---@field amount integer
Content = {}

---Content class constructor
---@param name? string
---@param amount? integer
---@return Content
function Content:new(name, amount)
	local public = {}
	public.name = name or DEFAULT_CONTENT_NAME
	public.amount = amount or 0

	setmetatable(public, self)
	self.__index = self
	return public
end

CellSize = 64

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
	elseif type == CellType.ORE then
		if cell.content.name == ContentType.IRON then
			return Images.ore_iron
		elseif cell.content.name == ContentType.GOLD then
			return Images.ore_gold
		end
	end

	return nil
end

---@param x integer
---@param y integer
---@param cell Cell
function drawCell(x, y, cell)
	local camX = CameraX - Width / 2
	local camY = CameraY - Height / 2

	if
		(x * CellSize - CellSize >= CameraX + Width / 2)
		or (x * CellSize <= camX)
		or (y * CellSize - CellSize >= CameraY + Height / 2)
		or (y * CellSize <= camY)
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
			(x - 1) * CellSize + offsetX,
			(y - 1) * CellSize + offsetY,
			cell.direction * math.rad(90),
			CellSize / 128,
			CellSize / 128
		)
	end
end

---@enum CellType
CellType = {
	NONE = 0,
	GENERATOR = 1,
	CONVEYOR = 2,
	JUNCTION = 3,
	ORE = 4,
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
	elseif cellType == CellType.NONE then
		return "(void)"
	end
end

---@enum Direction
Direction = {
	RIGHT = 0,
	DOWN = 1,
	LEFT = 2,
	UP = 3,
}

---@class Cell
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
		if
			self.y + 1 > CellAmount
			or Cells[self.x][self.y + 1].type ~= CellType.CONVEYOR
			or not self.under
			or self.under.content.name == DEFAULT_CONTENT_NAME
		then
			return
		end

		self.progress = self.progress + dt * (100 / generatorTime)

		local updated = false
		if
			(
				Cells[self.x][self.y + 1].content.name == self.under.content.name
				or Cells[self.x][self.y + 1].content.name == DEFAULT_CONTENT_NAME
			) and self.progress >= 100
		then
			Cells[self.x][self.y + 1].content.name = self.under.content.name
			Cells[self.x][self.y + 1].content.amount = Cells[self.x][self.y + 1].content.amount + 1

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

		if
			self.x + offset.x <= 0
			or self.x + offset.x > CellAmount
			or self.y + offset.y <= 0
			or self.y + offset.y > CellAmount
		then
			return
		end

		if
			self.x + offset.x > CellAmount
			or self.y + offset.y > CellAmount
			or Cells[self.x + offset.x][self.y + offset.y].type ~= CellType.CONVEYOR
			or self.content.amount == 0
		then
			return
		end

		self.progress = self.progress + dt * (100 / conveyorTime)

		local updated = false
		if
			(
				Cells[self.x + offset.x][self.y + offset.y].content.name == self.content.name
				or Cells[self.x + offset.x][self.y + offset.y].content.name == DEFAULT_CONTENT_NAME
			) and self.progress >= 100
		then
			local sub = 3
			Cells[self.x + offset.x][self.y + offset.y].content.name = self.content.name

			if self.content.amount < 3 then
				sub = self.content.amount
			end

			assert(sub <= 3 and sub > 0, "0 < sub <= 3 (current " .. sub .. ")")

			Cells[self.x + offset.x][self.y + offset.y].content.amount = Cells[self.x + offset.x][self.y + offset.y].content.amount
				+ sub

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
			if
				Cells[self.x - 1][self.y].type == CellType.CONVEYOR
				and Cells[self.x - 1][self.y].direction == Direction.RIGHT
			then
				inputOffset.x = -1
			elseif
				Cells[self.x + 1][self.y].type == CellType.CONVEYOR
				and Cells[self.x + 1][self.y].direction == Direction.LEFT
			then
				inputOffset.x = 1
			else
				goto next
			end

			if Cells[self.x + inputOffset.x * -1][self.y].type ~= CellType.CONVEYOR then
				goto next
			end

			if inputOffset.x ~= 0 then
				if Cells[self.x + inputOffset.x][self.y].content.name == DEFAULT_CONTENT_NAME then
					goto next
				end

				if
					Cells[self.x + inputOffset.x][self.y].content.name
						== Cells[self.x + inputOffset.x * -1][self.y].content.name
					or Cells[self.x + inputOffset.x * -1][self.y].content.name == DEFAULT_CONTENT_NAME
				then
					Cells[self.x + inputOffset.x * -1][self.y].content.name =
						Cells[self.x + inputOffset.x][self.y].content.name
					Cells[self.x + inputOffset.x * -1][self.y].content.amount = Cells[self.x + inputOffset.x * -1][self.y].content.amount
						+ Cells[self.x + inputOffset.x][self.y].content.amount
					Cells[self.x + inputOffset.x][self.y].content.amount = 0
					Cells[self.x + inputOffset.x][self.y].content.name = DEFAULT_CONTENT_NAME
				end
			end
		end

		::next::

		if self.y - 1 > 0 and self.y + 1 <= CellAmount then
			if
				Cells[self.x][self.y - 1].type == CellType.CONVEYOR
				and Cells[self.x][self.y - 1].direction == Direction.DOWN
			then
				inputOffset.y = -1
			elseif
				Cells[self.x][self.y + 1].type == CellType.CONVEYOR
				and Cells[self.x][self.y + 1].direction == Direction.UP
			then
				inputOffset.y = 1
			else
				return
			end

			if Cells[self.x][self.y + inputOffset.y * -1].type ~= CellType.CONVEYOR then
				return
			end

			if inputOffset.y ~= 0 then
				if
					Cells[self.x][self.y + inputOffset.y].content.name
						== Cells[self.x][self.y + inputOffset.y * -1].content.name
					or Cells[self.x][self.y + inputOffset.y * -1].content.name == DEFAULT_CONTENT_NAME
				then
					Cells[self.x][self.y + inputOffset.y * -1].content.name =
						Cells[self.x][self.y + inputOffset.y].content.name
					Cells[self.x][self.y + inputOffset.y * -1].content.amount = Cells[self.x][self.y + inputOffset.y * -1].content.amount
						+ Cells[self.x][self.y + inputOffset.y].content.amount
					Cells[self.x][self.y + inputOffset.y].content.amount = 0
					Cells[self.x][self.y + inputOffset.y].content.name = DEFAULT_CONTENT_NAME
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
			drawCell(self.x, self.y, self.under)
		end

		drawCell(self.x, self.y, self)

		love.graphics.setColor(0.5, 0.5, 0.5)
		local camX = CameraX - Width / 2
		local camY = CameraY - Height / 2

		if
			(x * CellSize - CellSize >= CameraX + Width / 2)
			or (x * CellSize <= camX)
			or (y * CellSize - CellSize >= CameraY + Height / 2)
			or (y * CellSize <= camY)
		then
			return
		end

		love.graphics.print(
			("%s\n%d\n%d%%"):format(self.content.name, self.content.amount, self.progress),
			(x - 1) * CellSize + 1,
			(y - 1) * CellSize + 1
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
