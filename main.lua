Width = love.graphics.getWidth()
Height = love.graphics.getHeight()

require("utils")
require("cell")
require("ui")
local camera = require("lib.hump.camera")

Core = {}
---@param resource Content
function Core:add(resource)
	self[resource.name] = (self[resource.name] or 0) + resource.amount
end
---@param resource Content
function Core:remove(resource)
	self[resource.name] = (self[resource.name] or 0) - resource.amount
	if self[resource.name] <= 0 then
		self[resource.name] = nil
	end
end

local corePlased = false

ShowProgress = true
CellAmount = 100

PlayTime = 0

---@type Direction
Rotation = Direction.RIGHT
---@type CellType
BuildSelection = CellType.NONE

---@type ImageButton
local generatorButton = nil
---@type ImageButton
local conveyorButton = nil
---@type ImageButton
local junctionButton = nil
---@type ImageButton
local coreButton = nil
---@type ImageButton
local progressButton = nil
---@type ImageButton
local saveButton = nil
---@type ImageButton
local loadButton = nil

local function dumpMap()
	for x, _ in pairs(Cells) do
		for y, cell in pairs(Cells[x]) do
			print(x, y, CellType.tostring(cell.type), cell.content.name, cell.content.amount)
		end
	end
end

local mapGeneration = 0

local function generateMap()
	local oreGrid = {}
	local baseX = 10000 * love.math.random()
	local baseY = 10000 * love.math.random()

	for x = 1, CellAmount do
		oreGrid[x] = {}

		for y = 1, CellAmount do
			oreGrid[x][y] = love.math.noise(baseX + 0.1 * x, baseY + 0.1 * y)
		end
	end

	for x = 1, CellAmount, 1 do
		Cells[x] = {}

		for y = 1, CellAmount, 1 do
			---@type CellType
			local type = CellType.NONE
			---@type ContentType
			local contentName = DEFAULT_CONTENT_NAME

			if oreGrid[x][y] > OreContentSpawnRates["iron"] then
				type = CellType.ORE
				contentName = ContentType.IRON -- NOTE: Coal would be better
			elseif oreGrid[x][y] < OreContentSpawnRates["gold"] then
				type = CellType.ORE
				contentName = ContentType.GOLD
			end

			Cells[x][y] = Cell:new(x, y, type, nil, Content:new(contentName))
		end
	end

	mapGeneration = mapGeneration + 1
end

Camera = nil
CameraX = 0
CameraY = 0

local mapReady = false

local mapGeneratorThread = coroutine.create(generateMap)

---@diagnostic disable-next-line: duplicate-set-field
function love.load()
	if isDebug() then
		---@diagnostic disable-next-line: lowercase-global
		vudu = require("lib.vudu.vudu")
		vudu.initialize()
		vudu.initializeDefaultHotkeys()
	end

	for _, v in pairs(arg) do
		if v:match("%-%-%d+") then
			love.math.setRandomSeed(v:match("%d+"))
		end
	end

	Camera = camera()
	Font = love.graphics.newFont("res/fonts/fira.ttf", 15)

	Images = {}
	Images.ohno = love.graphics.newImage("res/gfx/ohno.png")
	Images.conveyor = love.graphics.newImage("res/gfx/conveyor.png")
	Images.junction = love.graphics.newImage("res/gfx/junction.png")
	Images.generator = love.graphics.newImage("res/gfx/generator.png")
	Images.ore_iron = love.graphics.newImage("res/gfx/ore-iron.png")
	Images.ore_gold = love.graphics.newImage("res/gfx/ore-gold.png")
	Images.load = love.graphics.newImage("res/gfx/load.png")
	Images.save = love.graphics.newImage("res/gfx/save.png")
	Images.show_progress = love.graphics.newImage("res/gfx/show-progress.png")
	Images.core = love.graphics.newImage("res/gfx/core.png")

	generatorButton = ImageButton:new(48 * 0, 0, 48, 48, Images.generator, function()
		BuildSelection = CellType.GENERATOR
	end)
	conveyorButton = ImageButton:new(48 * 1, 0, 48, 48, Images.conveyor, function()
		BuildSelection = CellType.CONVEYOR
	end)
	junctionButton = ImageButton:new(48 * 2, 0, 48, 48, Images.junction, function()
		BuildSelection = CellType.JUNCTION
	end)
	coreButton = ImageButton:new(48 * 3, 0, 48, 48, Images.core, function()
		BuildSelection = CellType.CORE
	end)
	progressButton = ImageButton:new(Width - 48, 0, 48, 48, Images.show_progress, function()
		ShowProgress = not ShowProgress
	end)
	loadButton = ImageButton:new(Width - 48 * 2, 0, 48, 48, Images.load, loadGame)
	saveButton = ImageButton:new(Width - 48 * 3, 0, 48, 48, Images.save, saveGame)

	coroutine.resume(mapGeneratorThread)
	dumpMap()

	mapReady = true
end

---@diagnostic disable-next-line: duplicate-set-field
function love.update(dt)
	PlayTime = PlayTime + dt
	if love.keyboard.isDown("w") then
		CameraY = CameraY - 300 * dt
	elseif love.keyboard.isDown("s") then
		CameraY = CameraY + 300 * dt
	end
	if love.keyboard.isDown("a") then
		CameraX = CameraX - 300 * dt
	elseif love.keyboard.isDown("d") then
		CameraX = CameraX + 300 * dt
	end

	Camera:lookAt(CameraX, CameraY)

	if mapReady then
		for x, _ in pairs(Cells) do
			for _, cell in pairs(Cells[x]) do
				if cell.type ~= CellType.ORE and cell.type ~= CellType.NONE then
					cell:update(dt)
				end
			end
		end
	end
end

---@diagnostic disable-next-line: duplicate-set-field
function love.draw()
	love.graphics.setFont(Font)

	Camera:attach()

	local a = math.ceil((love.mouse.getX() - (Width / 2) + CameraX) / CellSize)
	local b = math.ceil((love.mouse.getY() - (Height / 2) + CameraY) / CellSize)

	local previewImage = imageFromCell(Cell:new(0, 0, BuildSelection))

	if previewImage then
		local previewOffsetX = 0
		local previewOffsetY = 0

		if Rotation == 1 then
			previewOffsetX = CellSize
		elseif Rotation == 2 then
			previewOffsetX = CellSize
			previewOffsetY = CellSize
		elseif Rotation == 3 then
			previewOffsetY = CellSize
		end

		love.graphics.setColor(1, 1, 1, 0.5)
		love.graphics.draw(
			previewImage,
			(a - 1) * CellSize + previewOffsetX,
			(b - 1) * CellSize + previewOffsetY,
			Rotation * math.rad(90),
			CellSize / 128,
			CellSize / 128
		)
	end

	-- Draw grid
	if mapReady then
		for x, _ in pairs(Cells) do
			local xDrawn = false
			local camX = CameraX - Width / 2
			local camY = CameraY - Height / 2
			if (x * CellSize - CellSize >= CameraX + Width / 2) or (x * CellSize <= camX) then
				goto continue2
			end

			for y, cell in pairs(Cells[x]) do
				cell:draw()

				love.graphics.setColor(0.1, 0.1, 0.1)
				if not xDrawn then
					love.graphics.line(x * CellSize, 0, x * CellSize, CellSize * CellAmount)
					xDrawn = true
				end

				if (y * CellSize - CellSize >= CameraY + Height / 2) or (y * CellSize <= camY) then
					goto continue
				end

				love.graphics.line(0, y * CellSize, CellSize * CellAmount, y * CellSize)
				::continue::
			end
			::continue2::
		end
	end

	Camera:detach()

	love.graphics.setColor(1, 0, 0)
	generatorButton:draw()
	conveyorButton:draw()
	junctionButton:draw()
	coreButton:draw()
	progressButton:draw()
	if ShowProgress then
		love.graphics.setColor(0, 1, 0)
	else
		love.graphics.setColor(1, 0, 0)
	end
	love.graphics.rectangle("line", progressButton.x, progressButton.y, progressButton.w, progressButton.h)
	loadButton:draw()
	saveButton:draw()

	local currentButton = nil
	if BuildSelection == CellType.GENERATOR then
		currentButton = generatorButton
	elseif BuildSelection == CellType.CONVEYOR then
		currentButton = conveyorButton
	elseif BuildSelection == CellType.JUNCTION then
		currentButton = junctionButton
	elseif BuildSelection == CellType.CORE then
		currentButton = coreButton
	end

	if currentButton then
		love.graphics.setColor(0, 1, 0)
		love.graphics.rectangle("line", currentButton.x, currentButton.y, currentButton.w, currentButton.h)
	end

	love.graphics.setColor(1, 1, 1)
	love.graphics.print(
		("FPS: %d  Seed: %d (Generation: %d)  PlayTime: %f"):format(
			love.timer.getFPS(),
			love.math.getRandomSeed(),
			mapGeneration,
			PlayTime
		),
		0,
		Height - Font:getHeight()
	)

	local index = 0
	for name, amount in pairs(Core) do
		if type(amount) == "function" then
			goto continue
		end
		love.graphics.print(("%s: %d"):format(name, amount), 48 * 5 + 2, Font:getHeight() * index)
		index = index + 1
		::continue::
	end
end

---@diagnostic disable-next-line: duplicate-set-field
function love.mousepressed(mouseX, mouseY, button)
	if generatorButton:update() then
		return
	end
	if conveyorButton:update() then
		return
	end
	if junctionButton:update() then
		return
	end
	if coreButton:update() then
		return
	end
	if progressButton:update() then
		return
	end
	if loadButton:update() then
		return
	end
	if saveButton:update() then
		return
	end

	if button > 2 then
		return
	end

	local x = mouseX - Width / 2 + CameraX
	local y = mouseY - Height / 2 + CameraY
	local a = math.ceil(x / CellSize)
	local b = math.ceil(y / CellSize)

	if a > CellAmount or b > CellAmount or a <= 0 or b <= 0 then
		return
	end

	print(("Mouse %d: %d, %d"):format(button, a, b))

	local under =
		Cell:new(a, b, Cells[a][b].type, nil, Content:new(Cells[a][b].content.name, Cells[a][b].content.amount))
	local iserase = button == 2

	if not iserase then
		if BuildSelection == CellType.GENERATOR then
			Cells[a][b].type = CellType.GENERATOR
		elseif BuildSelection == CellType.CONVEYOR then
			Cells[a][b].content.name = DEFAULT_CONTENT_NAME
			Cells[a][b].type = CellType.CONVEYOR
		elseif BuildSelection == CellType.JUNCTION then
			Cells[a][b].content.name = DEFAULT_CONTENT_NAME
			Cells[a][b].type = CellType.JUNCTION
		elseif BuildSelection == CellType.CORE and not corePlased then
			Cells[a][b].content.name = DEFAULT_CONTENT_NAME
			Cells[a][b].content.amount = 0
			Cells[a][b].type = CellType.CORE
			corePlased = true
		end
	end

	if iserase and Cells[a][b].type ~= CellType.ORE then
		if Cells[a][b].type == CellType.CORE then
			corePlased = false
		end
		Cells[a][b].type = CellType.NONE
	end

	Cells[a][b].direction = Rotation
	if not iserase and not Cells[a][b].under then
		Cells[a][b].under = under
	end
	Cells[a][b].content.amount = 0
	Cells[a][b].progress = 0
end

---@diagnostic disable-next-line: duplicate-set-field
function love.keypressed(key)
	if key == "space" then
		dumpMap()
	elseif key == "r" then
		if love.keyboard.isDown("lshift") then
			if Rotation == 0 then
				Rotation = 3
			else
				Rotation = Rotation - 1
			end
		else
			if Rotation == 3 then
				Rotation = 0
			else
				Rotation = Rotation + 1
			end
		end
	elseif key == "1" then
		BuildSelection = CellType.GENERATOR
	elseif key == "2" then
		BuildSelection = CellType.CONVEYOR
	elseif key == "3" then
		BuildSelection = CellType.JUNCTION
	elseif key == "4" then
		BuildSelection = CellType.CORE
	elseif key == "p" then
		saveGame()
	elseif key == "l" then
		loadGame()
	elseif key == "f5" then
		mapReady = false
		generateMap()
		mapReady = true
	end
end

---@diagnostic disable-next-line: duplicate-set-field
function love.resize()
	Width = love.graphics.getWidth()
	Height = love.graphics.getHeight()
	progressButton.x = Width - 48
	loadButton.x = Width - 48 * 2
	saveButton.x = Width - 48 * 3
end

function saveGame()
	require("save")
	local s = ("return ({{ playTime = %f, seed = %d, generation = %d }, {\n"):format(
		PlayTime,
		love.math.getRandomSeed(),
		mapGeneration
	)
	for x, _ in pairs(Cells) do
		s = s .. "{\n"
		for _, cell in pairs(Cells[x]) do
			s = s .. CellToString(cell) .. ",\n"
		end
		s = s .. "},\n"
	end
	s = s .. "}})"

	local ok, msg = love.filesystem.write("savedata.lua", s)
	if not ok then
		love.window.showMessageBox("Saving error!", "Failed to save: " .. msg, "error")
	else
		love.window.showMessageBox("Saved!", "Successfully saved!")
	end
end

function loadGame()
	local button = love.window.showMessageBox(
		"Load",
		"Do you really want to load the last save?\nAll unsaved progress will be lost!",
		{ "Yes", "No", enterbutton = 1, escapebutton = 2 }
	)
	if button == 1 then
		local savedata = require("savedata")
		local info = savedata[1]
		local save = savedata[2]
		PlayTime = info.playTime or 0
		love.math.setRandomSeed(info.seed or 0)
		mapGeneration = info.generation or 1
		Cells = save
		love.window.showMessageBox("Loaded!", "Lastest save loaded!")
	end
end
