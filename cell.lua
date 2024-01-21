local class = require("lib.30log")

Cells = {}

CellSize = 64

---@type table<string, CellOpts>
CellType = {
	NONE = {
		displayName = "(void)",
		buildable = false,
		isStorage = false,
		drawable = false,
	},
	ORE = {
		displayName = "ORE",
		buildable = false,
		isStorage = false,
		drawable = false,
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

--[[
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
	---@type integer
	public.x = x
	---@type integer
	public.y = y
	---@type CellType
	public.type = type
	---@type Direction
	public.direction = direction or Direction.RIGHT
	---@type Content
	public.content = content or Content:new()
	---@type Cell?
	public.under = under
	---@type boolean
	public.isStorage = false
	--- In percents
	---@type number
	public.progress = 0
	---@type table<ContentType, integer>
	public.storage = {}
	---@type number
	public.maxCap = 0

	-- cellTime - how long would it take for block to do something (in secs)

	--- In seconds
	local generatorTime = 2
	--- In seconds
	local conveyorTime = 1

	function public:detectStorageSpecs()
		self.isStorage = false
		self.maxCap = 0

		for _, v in pairs(StorageCellTypes) do
			if v == self.type then
				self.isStorage = true
				break
			end
		end

		if self.type == CellType.CONVEYOR then
			self.maxCap = 3
		elseif self.type == CellType.STORAGE then
			self.maxCap = 192
		end
	end

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
			or not cellUnder.isStorage
			or (cellUnder.isStorage and cellUnder:isStorageFull())
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
			cellUnder:addToStorage(Content:new(self.under.content.name, 1))

			updated = true
		end

		if self.progress >= 100 and updated then
			self.progress = 0
		end
	end

	---@return integer
	function public:storageCapacity()
		local n = 0
		for _, v in pairs(self.storage) do
			n = n + v
		end
		return n
	end

	function public:isStorageFull()
		return self:storageCapacity() >= self.maxCap
	end

	function public:isStorageOverflowed()
		return self:storageCapacity() > self.maxCap
	end

	---Removes or clears the storage
	---@param contentType ContentType?
	---@return integer|table<ContentType, integer>
	function public:removeFromStorage(contentType)
		if contentType ~= nil and self.storage[contentType] ~= nil then
			local savedContent = self.storage[contentType]
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
	---@param cont Content|table<ContentType, integer>
	function public:addToStorage(cont)
		if public:isStorageFull() then
			return
		end
		if cont.name or cont.amount then -- type(cont) == Content
			local availableCap = self.maxCap - self:storageCapacity()
			local willOverflow = availableCap - cont.amount < 0
			if not willOverflow then
				self.storage[cont.name] = (self.storage[cont.name] or 0) + cont.amount
			else
				self.storage[cont.name] = (self.storage[cont.name] or 0) + availableCap
			end
		else -- type(cont) == table<Content>
			for k, v in pairs(cont) do
				self:addToStorage(Content:new(k, v))
			end
		end
	end

	---Transfers self's content to other cell
	---@param dst Cell
	function public:transferStorage(dst)
		local stored = self:removeFromStorage()
		dst:addToStorage(stored)
	end

	function public:updateConveyor(dt)
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
			or (not dstCell.isStorage and dstCell.type ~= CellType.CORE)
			or self:storageCapacity() == 0
			or dstCell:isStorageFull()
		then
			return
		end

		self.progress = self.progress + dt * (100 / conveyorTime)

		local updated = false
		if dstCell.type == CellType.CORE and self.progress >= 100 then
			for n, a in pairs(self.storage) do
				Core:add(Content:new(n, a))
			end

			self.storage = {}

			updated = true
		elseif
			-- (dstCell.content.name == self.content.name or dstCell.content.name == DEFAULT_CONTENT_NAME)
			not dstCell:isStorageFull() and self.progress >= 100
		then
			self:transferStorage(dstCell)

			updated = true
		end

		if self.progress >= 100 and updated then
			self.progress = 0
		end
	end

	---@diagnostic disable-next-line: unused-local
	function public:updateJunction(dt)
		local inputX = nil
		local inputY = nil
		local inputOffsetX = 0
		local inputOffsetY = 0

		if self:lookup(-1).type == CellType.CONVEYOR and self:lookup(-1).direction == Direction.RIGHT then
			inputX = self:lookup(-1)
			inputOffsetX = -1
		elseif self:lookup(1).type == CellType.CONVEYOR and self:lookup(1).direction == Direction.LEFT then
			inputX = self:lookup(1)
			inputOffsetX = 1
		end

		if self:lookup(0, -1).type == CellType.CONVEYOR and self:lookup(0, -1).direction == Direction.DOWN then
			inputY = self:lookup(0, -1)
			inputOffsetY = -1
		elseif self:lookup(0, 1).type == CellType.CONVEYOR and self:lookup(0, 1).direction == Direction.UP then
			inputY = self:lookup(0, 1)
			inputOffsetY = 1
		end

		local dstX = nil
		local dstY = nil
		if inputOffsetX ~= 0 then
			dstX = self:lookup(inputOffsetX * -1)
		end
		if inputOffsetY ~= 0 then
			dstY = self:lookup(0, inputOffsetY * -1)
		end

		if inputX and dstX and dstX.isStorage and not dstX:isStorageFull() then
			inputX:transferStorage(dstX)
		end
		if inputY and dstY and dstY.isStorage and not dstY:isStorageFull() then
			inputY:transferStorage(dstY)
		end
	end

	function public:update(dt)
		self:detectStorageSpecs()

		if _G.type(self.type.update) == "function" then
			self.type.update(self, dt)
		end
	end

	function public:draw()
		if self.under then
			DrawCell(self.under)
		end

		DrawCell(self)

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
			("%s\n%d\n%d%%"):format(self.content.name, self:storageCapacity(), self.progress),
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
--]]

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
	end
end
