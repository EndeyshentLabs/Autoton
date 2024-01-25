---@type ContentBuilder
GameBuilder = ContentBuilder:new(RESERVED_GAME_BASE)

GameBuilder:addContent("oreIron", {
	displayName = "Iron Ore",
	image = GameBuilder:addImage("oreIron", "res/gfx/ore-iron.png"),
})

GameBuilder:addContent("oreGold", {
	displayName = "Gold Ore",
	image = GameBuilder:addImage("oreGold", "res/gfx/ore-gold.png"),
})

GameBuilder:addCell("miner", {
	displayName = "Miner",
	buildable = true,
	time = 2,
	image = GameBuilder:addImage("miner", "res/gfx/generator.png"),
	drawable = true,
	isStorage = false,
	update = function(self, dt)
		local cellUnder = self:lookup(0, 1)
		if
			not cellUnder
			or not cellUnder.type.isStorage
			or (cellUnder.type.isStorage and cellUnder:isStorageFull())
			or not self.under
		then
			return
		end

		self.progress = self.progress + dt * (100 / GameBuilder.cellTypes.miner.time)

		local updated = false
		if self.progress >= 100 then
			cellUnder:addToStorage(Content:new(self.under.content.opts, 1))

			updated = true
		end

		if self.progress >= 100 and updated then
			self.progress = 0
		end
	end,
})

GameBuilder:addCell("conveyor", {
	displayName = "Conveyor",
	buildable = true,
	time = 1,
	image = GameBuilder:addImage("conveyor", "res/gfx/conveyor.png"),
	drawable = true,
	isStorage = true,
	maxCap = 3,
	update = function(self, dt)
		-- TODO: Rewrite

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

		if not dstCell or not dstCell.type.isStorage or self:storageCapacity() == 0 or dstCell:isStorageFull() then
			return
		end

		self.progress = self.progress + dt * (100 / GameBuilder.cellTypes.conveyor.time)

		local updated = false
		if dstCell.type == CellType.CORE and self.progress >= 100 then
			for n, a in pairs(self.storage) do
				Core:add(Content:new(n, a))
			end

			self.storage = {}

			updated = true
		elseif not dstCell:isStorageFull() and self.progress >= 100 then
			self:transferStorage(dstCell)

			updated = true
		end

		if self.progress >= 100 and updated then
			self.progress = 0
		end
	end,
})

GameBuilder:addCell("junction", {
	displayName = "Junction",
	buildable = true,
	image = GameBuilder:addImage("junction", "res/gfx/junction.png"),
	drawable = true,
	isStorage = false,
	update = function(self, dt)
		-- TODO: Rewrite

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
	end,
})

GameBuilder:addCell("storage", {
	displayName = "Storage",
	buildable = true,
	image = GameBuilder:addImage("storage", "res/gfx/storage.png"),
	drawable = true,
	isStorage = true,
	maxCap = 64 * 3,
})

-- TODO: Fix CORE cell
-- GameBuilder:addCell("core", {
-- 	displayName= "Core",
-- 	buildable = true,
-- 	image = GameBuilder:addImage("core", "res/gfx/core.png"),
-- 	drawable = true,
-- 	isStorage = true,
-- })