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
	local camX = CameraX - love.graphics.getWidth() / 2
	local camY = CameraY - love.graphics.getHeight() / 2

	if x * CellSize - CellSize >= CameraX + love.graphics.getWidth() / 2 then
		return
	end
	if x * CellSize <= camX then
		return
	end
	if y * CellSize - CellSize >= CameraY + love.graphics.getHeight() / 2 then
		return
	end
	if y * CellSize <= camY then
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
	public.direction = direction or 0
	public.content = content or Content:new()
	public.under = under

	function public:update(dt, secondPassed)
		if self.type == CellType.GENERATOR then
			if
				y + 1 > CellAmount
				or Cells[x][y + 1].type ~= CellType.CONVEYOR
				or not self.under
				or self.under.content.name == DEFAULT_CONTENT_NAME
			then
				return
			end

			if
				(
					Cells[x][y + 1].content.name == self.under.content.name
					or Cells[x][y + 1].content.name == DEFAULT_CONTENT_NAME
				) and secondPassed
			then
				Cells[x][y + 1].content.name = self.under.content.name
				Cells[x][y + 1].content.amount = Cells[x][y + 1].content.amount + 1
			end
		elseif self.type == CellType.CONVEYOR then
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

			if x + offset.x <= 0 or x + offset.x > CellAmount or y + offset.y <= 0 or y + offset.y > CellAmount then
				return
			end

			if
				x + offset.x > CellAmount
				or y + offset.y > CellAmount
				or Cells[x + offset.x][y + offset.y].type ~= CellType.CONVEYOR
				or self.content.amount == 0
			then
				return
			end

			if
				(
					Cells[x + offset.x][y + offset.y].content.name == self.content.name
					or Cells[x + offset.x][y + offset.y].content.name == DEFAULT_CONTENT_NAME
				) and secondPassed
			then
				local sub = 3
				Cells[x + offset.x][y + offset.y].content.name = self.content.name

				if self.content.amount < 3 then
					sub = self.content.amount
				end

				assert(sub <= 3 and sub > 0, "0 < sub <= 3 (current " .. sub .. ")")

				Cells[x + offset.x][y + offset.y].content.amount = Cells[x + offset.x][y + offset.y].content.amount
					+ sub

				self.content.amount = self.content.amount - sub

				if self.content.amount == 0 then
					self.content.name = DEFAULT_CONTENT_NAME
				end
			end
		elseif self.type == CellType.JUNCTION then
			if y + 1 > CellAmount or y - 1 < 0 then
				return
			end
			if
				(Cells[x][y + 1].type == CellType.CONVEYOR)
				and (Cells[x][y - 1].type == CellType.CONVEYOR and Cells[x][y - 1].direction == Direction.DOWN)
				and (Cells[x][y - 1].content.name == Cells[x][y + 1].content.name or Cells[x][y + 1].content.name == DEFAULT_CONTENT_NAME)
				and (Cells[x][y - 1].content.amount > 0)
			then
				Cells[x][y - 1].content.amount = Cells[x][y - 1].content.amount - 1
				Cells[x][y + 1].content.amount = Cells[x][y + 1].content.amount + 1
				Cells[x][y + 1].content.name = Cells[x][y - 1].content.name
			end

			if x + 1 > CellAmount or x - 1 < 0 then
				return
			end
			if
				(Cells[x + 1][y].type == CellType.CONVEYOR)
				and (Cells[x - 1][y].type == CellType.CONVEYOR and Cells[x - 1][y].direction == Direction.RIGHT)
				and (Cells[x - 1][y].content.name == Cells[x - 1][y].content.name or Cells[x + 1][y].content.name == DEFAULT_CONTENT_NAME)
				and (Cells[x - 1][y].content.amount > 0)
			then
				Cells[x - 1][y].content.amount = Cells[x - 1][y].content.amount - 1
				Cells[x + 1][y].content.amount = Cells[x + 1][y].content.amount + 1
				Cells[x + 1][y].content.name = Cells[x - 1][y].content.name
			end
		end
	end

	function public:draw()
		if self.under then
			drawCell(self.x, self.y, self.under)
		end

		drawCell(self.x, self.y, self)

		love.graphics.setColor(0.5, 0.5, 0.5)
		love.graphics.print(
			self.content.name .. "\n" .. self.content.amount,
			(self.x - 1) * CellSize + 1,
			(self.y - 1) * CellSize + 1
		)
	end

	setmetatable(public, self)
	self.__index = self
	return public
end
