---@type ContentBuilder
GameBuilder = ContentBuilder:new(RESERVED_GAME_BASE)

GameBuilder:addContent("oreIron", {
	displayName = CurrentLocale.oreIron,
	image = GameBuilder:addImage("oreIron", "res/gfx/ore-iron.png"),
})

GameBuilder:addContent("oreGold", {
	displayName = CurrentLocale.oreGold,
	image = GameBuilder:addImage("oreGold", "res/gfx/ore-gold.png"),
})

GameBuilder:addCell("miner", {
	displayName = CurrentLocale.cellMinerName,
	description = CurrentLocale.cellMinerDesc,
	buildable = true,
	time = 2,
	image = GameBuilder:addImage("miner", "res/gfx/generator.png"),
	drawable = true,
	isStorage = false,
	---@param self Cell
	---@param dt number
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
	displayName = CurrentLocale.cellConveyorName,
	description = CurrentLocale.cellConveyorDesc,
	buildable = true,
	time = 1,
	image = GameBuilder:addImage("conveyor", "res/gfx/conveyor.png"),
	drawable = true,
	isStorage = true,
	maxCap = 3,
	---@param self Cell
	---@param dt number
	update = function(self, dt)
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
		if not dstCell:isStorageFull() and self.progress >= 100 then
			self:transferStorage(dstCell)

			updated = true
		end

		if self.progress >= 100 and updated then
			self.progress = 0
		end
	end,
})

GameBuilder:addCell("junction", {
	displayName = CurrentLocale.cellJunctionName,
	description = CurrentLocale.cellJunctionDesc,
	buildable = true,
	image = GameBuilder:addImage("junction", "res/gfx/junction.png"),
	drawable = true,
	isStorage = false,
	---@param self Cell
	---@param dt number
	update = function(self, dt)
		local inputX = nil
		local inputY = nil
		local inputOffsetX = 0
		local inputOffsetY = 0

		local conveyorType = GameBuilder.cellTypes.conveyor

		local left = self:lookup(-1)
		local right = self:lookup(1)
		local up = self:lookup(0, -1)
		local down = self:lookup(0, 1)

		if left and left.type == conveyorType and left.direction == Direction.RIGHT then
			inputX = left
			inputOffsetX = -1
		elseif right and right.type == conveyorType and right.direction == Direction.LEFT then
			inputX = right
			inputOffsetX = 1
		end

		if up and up.type == conveyorType and up.direction == Direction.DOWN then
			inputY = up
			inputOffsetY = -1
		elseif down and down.type == conveyorType and down.direction == Direction.UP then
			inputY = down
			inputOffsetY = 1
		end

		---@type Cell|nil
		local dstX = nil
		---@type Cell|nil
		local dstY = nil
		if inputOffsetX ~= 0 then
			dstX = self:lookup(inputOffsetX * -1)
		end
		if inputOffsetY ~= 0 then
			dstY = self:lookup(0, inputOffsetY * -1)
		end

		if inputX and dstX and dstX.type.isStorage and not dstX:isStorageFull() then
			inputX:transferStorage(dstX)
		end
		if inputY and dstY and dstY.type.isStorage and not dstY:isStorageFull() then
			inputY:transferStorage(dstY)
		end
	end,
})

GameBuilder:addCell("storage", {
	displayName = CurrentLocale.cellStorageName,
	description = CurrentLocale.cellStorageDesc,
	buildable = true,
	image = GameBuilder:addImage("storage", "res/gfx/storage.png"),
	drawable = true,
	isStorage = true,
	maxCap = 64 * 3,
})

GameBuilder:addCell("core", {
	displayName = CurrentLocale.cellCoreName,
	buildable = true,
	image = GameBuilder:addImage("core", "res/gfx/core.png"),
	drawable = true,
	isStorage = true,
	maxCap = 99999, -- """INFINITE""" maxCap
	---@param self Cell
	---@param dt number
	update = function(self, dt)
		if self:storageCapacity() > 0 then
			local storage = self:removeFromStorage()
			for content, amount in pairs(storage) do
				Core:add(Content:new(ContentType[content._BASED_NAME], amount))
			end
		end
	end,
})

-- TODO: Locales for keybinds

GameBuilder:addKeyboardBind("space", {
	displayName = "Print storage contents",
	key = "space",
	callback = function()
		local x, y = Camera:mousePosition()
		local a = math.ceil(x / CellSize)
		local b = math.ceil(y / CellSize)

		local s = ""
		for k, v in pairs(Cells[a][b].storage) do
			s = s .. k.displayName .. "(" .. k._BASED_NAME .. ")" .. " - " .. v .. "\n"
		end

		if s ~= nil and s ~= "" then
			love.window.showMessageBox("Cell's storage", s, "info")
		end
	end,
})

GameBuilder:addKeyboardBind("r", {
	displayName = "Rotate cell to build (hold <lshift> to do counter-clockwise)",
	key = "r",
	callback = function()
		if love.keyboard.isDown("lshift") then
			if Rotation == Direction.RIGHT then
				Rotation = Direction.UP
			else
				Rotation = Rotation - 1
			end
		else
			if Rotation == Direction.UP then
				Rotation = Direction.RIGHT
			else
				Rotation = Rotation + 1
			end
		end
	end,
})

GameBuilder:addKeyboardBind("lalt", {
	displayName = "Toggle ALT view mode",
	key = "lalt",
	callback = function()
		AltView = not AltView
	end,
})

GameBuilder:addKeyboardBind("q", {
	displayName = "Clear build selection",
	key = "q",
	callback = function()
		BuildSelection = CellType.NONE
		BuildSelectionNum = 0
	end,
})

GameBuilder:addKeyboardBind("p", {
	displayName = "Save game",
	key = "p",
	callback = function()
		saveGame()
	end,
})

GameBuilder:addKeyboardBind("l", {
	displayName = "Load saved game",
	key = "l",
	callback = function()
		loadGame()
	end,
})

GameBuilder:addKeyboardBind("f5", {
	displayName = "Re-generate map on the same seed",
	key = "f5",
	callback = function()
		MapReady = false
		GenerateMap()
	end,
})

GameBuilder:addKeyboardBind("f9", {
	displayName = "Open debug lua console (lua debug.debug())",
	key = "f9",
	callback = function()
		debug.debug()
	end,
})
