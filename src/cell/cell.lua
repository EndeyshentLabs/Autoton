Cells = {}

CellSize = 64

---@type table<string, CellOpts>
CellType = {
	NONE = {
		displayName = "(void)",
		buildable = false,
		isStorage = false,
		drawable = false,
		_BASED_NAME = "NONE"
	},
	ORE = {
		displayName = "ORE",
		buildable = false,
		isStorage = false,
		drawable = false,
		_BASED_NAME = "ORE"
	},
}

--- CellType that can be build ordered in toolbar order
---@enum BuildableCellTypes
BuildableCellTypes = {}

---@enum StorageCellTypes
StorageCellTypes = {
	CellType.CONVEYOR,
	CellType.STORAGE,
}

---@enum Direction
Direction = {
	RIGHT = 0,
	DOWN = 1,
	LEFT = 2,
	UP = 3,
}

ProtectEnum(Direction)

---@class Cell
---@field x integer
---@field y integer
---@field type CellOpts
---@field direction Direction
---@field content Content
---@field progress number
---@field under Cell|nil
---@field storage table<ContentOpts, integer>
Cell = class("Cell", {
	x = 0,
	y = 0,
	type = {},
	direction = Direction.RIGHT,
	content = Content:new(),
	progress = 0,
	storage = {},
})

function Cell:init(x, y, _type, direction, content, under)
	self.x = x
	self.y = y
	self.type = _type
	self.direction = direction
	self.content = content
	self.under = under
end

---@return Cell|nil
function Cell:lookup(relX, relY)
	relX = relX or 0
	relY = relY or 0
	if (self.x + relX <= 0 or self.x + relX > CellAmount) or (self.y + relY <= 0 or self.x + relX > CellAmount) then
		return nil
	end
	return Cells[self.x + relX][self.y + relY]
end

---@return integer
function Cell:storageCapacity()
	local n = 0
	for _, v in pairs(self.storage) do
		n = n + v
	end
	return n
end

---@return boolean
function Cell:isStorageFull()
	return self:storageCapacity() >= self.type.maxCap
end

---@return boolean
function Cell:isStorageOverflowed()
	return self:storageCapacity() > self.type.maxCap
end

---Removes or clears the storage
---@param content ContentOpts?
---@return integer|table<ContentOpts, integer>
function Cell:removeFromStorage(content)
	if content ~= nil and self.storage[content] ~= nil then
		local savedContent = self.storage[content]
		self.storage[content] = nil
		return savedContent
	end

	local savedContent = {}
	for k, v in pairs(self.storage) do
		savedContent[k] = v
	end
	self.storage = {}
	return savedContent
end

---Adds content to the storage
---@param cont Content|table<ContentOpts, integer>
function Cell:addToStorage(cont)
	if self:isStorageFull() then
		return
	end
	if cont.opts or cont.amount then -- type(cont) == Content
		local availableCap = self.type.maxCap - self:storageCapacity()
		local willOverflow = availableCap - cont.amount < 0
		if not willOverflow then
			self.storage[cont.opts] = (self.storage[cont.opts] or 0) + cont.amount
		else
			self.storage[cont.opts] = (self.storage[cont.opts] or 0) + availableCap
		end
	else -- type(cont) == table<Content>
		for k, v in pairs(cont) do
			self:addToStorage(Content:new(k, v))
		end
	end
end

---Transfers self's content to other cell
---@param dst Cell
function Cell:transferStorage(dst)
	local stored = self:removeFromStorage()
	---@diagnostic disable-next-line: param-type-mismatch
	dst:addToStorage(stored)
end

function Cell:update(dt)
	if self.type.update then
		self.type.update(self, dt)
	end
end

function Cell:draw()
	if self.under then
		DrawCell(self.under)
	end

	DrawCell(self)

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

	love.graphics.setColor(0.7, 0.7, 0.7)
	love.graphics.print(
		("%s\n%d\n%d%%"):format(self.content.opts.displayName, self:storageCapacity(), self.progress),
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

---Returns cell's sprite based on it's type
---@param cell Cell
---@return love.Image|nil
function ImageFromCell(cell)
	if cell.type == CellType.ORE then
		return cell.content.opts.image
	end

	return cell.type.image
end

---@param cell Cell
function DrawCell(cell)
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

	local image = ImageFromCell(cell)

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

		if cell.type.isStorage then
			-- TODO: Make storage an array of `Content`s
			for k, _ in pairs(cell.storage) do
				if k and k.image then
					love.graphics.draw(k.image, (cell.x - 1) * CellSize + CellSize / 2, (cell.y - 1) * CellSize, 0, CellSize / 256, CellSize / 256)
					break -- yes, we're just doing 1 iteration
				end
			end
		end
	end
end
