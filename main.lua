---@diagnostic disable: need-check-nil
require("utils")
require("cell")
require("ui")
local camera = require("lib.hump.camera")

CellAmount = 20

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

local function dumpMap()
	for x, _ in pairs(Cells) do
		for y, cell in pairs(Cells[x]) do
			print(x, y, CellType.tostring(cell.type), cell.content.name, cell.content.amount)
		end
	end
end

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
			local type = 0
			local contentName = DEFAULT_CONTENT_NAME

			if oreGrid[x][y] > 0.5 then
				type = CellType.ORE

				if love.math.random(1, 2) == 1 then
					contentName = ContentType.IRON
				else
					contentName = ContentType.GOLD
				end
			end

			Cells[x][y] = Cell:new(x, y, type, nil, Content:new(contentName))
		end
	end
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
		vudu:initialize()
	end

	Camera = camera()
	Font = love.graphics.newFont("res/fonts/fira.ttf", 15)

	Images = {}
	Images.conveyor = love.graphics.newImage("res/gfx/conveyor.png")
	Images.junction = love.graphics.newImage("res/gfx/junction.png")
	Images.generator = love.graphics.newImage("res/gfx/generator.png")
	Images.ore_iron = love.graphics.newImage("res/gfx/ore-iron.png")
	Images.ore_gold = love.graphics.newImage("res/gfx/ore-gold.png")

	generatorButton = ImageButton:new(48 * 0, 0, 48, 48, Images.generator, function()
		BuildSelection = CellType.GENERATOR
	end)
	conveyorButton = ImageButton:new(48 * 1, 0, 48, 48, Images.conveyor, function()
		BuildSelection = CellType.CONVEYOR
	end)
	junctionButton = ImageButton:new(48 * 2, 0, 48, 48, Images.junction, function()
		BuildSelection = CellType.JUNCTION
	end)

	coroutine.resume(mapGeneratorThread)
	dumpMap()

	mapReady = true
end

---@diagnostic disable-next-line: duplicate-set-field
function love.update(dt)
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
				cell:update(dt)
			end
		end
	end
end

---@diagnostic disable-next-line: duplicate-set-field
function love.draw()
	love.graphics.setFont(Font)

	Camera:attach()

	local a = math.ceil((love.mouse.getX() - (love.graphics.getWidth() / 2) + CameraX) / CellSize)
	local b = math.ceil((love.mouse.getY() - (love.graphics.getHeight() / 2) + CameraY) / CellSize)

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
			for y, cell in pairs(Cells[x]) do
				cell:draw()

				love.graphics.setColor(0.1, 0.1, 0.1)
				love.graphics.line(x * CellSize, y, x * CellSize, love.graphics.getHeight())
				love.graphics.line(x, y * CellSize, love.graphics.getWidth(), y * CellSize)
			end
		end
	end

	Camera:detach()

	love.graphics.setColor(1, 0, 0)
	generatorButton:draw()
	conveyorButton:draw()
	junctionButton:draw()

	local currentButton = nil
	if BuildSelection == CellType.GENERATOR then
		currentButton = generatorButton
	elseif BuildSelection == CellType.CONVEYOR then
		currentButton = conveyorButton
	elseif BuildSelection == CellType.JUNCTION then
		currentButton = junctionButton
	end

	if currentButton then
		love.graphics.setColor(0, 1, 0)
		love.graphics.rectangle("line", currentButton.x, currentButton.y, currentButton.w, currentButton.h)
	end
end

---@diagnostic disable-next-line: duplicate-set-field
function love.mousepressed(mouseX, mouseY, button)
	generatorButton:update()
	conveyorButton:update()
	junctionButton:update()

	if button > 2 then
		return
	end

	local x = mouseX - love.graphics.getWidth() / 2 + CameraX
	local y = mouseY - love.graphics.getHeight() / 2 + CameraY
	local a = math.ceil(x / CellSize)
	local b = math.ceil(y / CellSize)

	if a > CellAmount or b > CellAmount or a <= 0 or b <= 0 or mouseY <= 48 then
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
		end
	end

	if iserase and Cells[a][b].type ~= CellType.ORE then
		Cells[a][b].type = CellType.NONE
	end

	Cells[a][b].direction = Rotation
	if not iserase and not Cells[a][b].under then
		Cells[a][b].under = under
	end
	Cells[a][b].content.amount = 0
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
	end
end
