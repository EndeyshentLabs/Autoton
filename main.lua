Width = love.graphics.getWidth()
Height = love.graphics.getHeight()
Images = {}

require("lib.30log")

local camera = require("lib.hump.camera")

Camera = nil
CameraX = 0
CameraY = 0

require("args")
require("utils")

---@diagnostic disable-next-line: duplicate-set-field
function love.load()
	require("src")

	RequireAll()
	ParseArgs()

	Camera = camera()
	Font = love.graphics.newFont("res/fonts/fira.ttf", 15)

	Images.ohno = love.graphics.newImage("res/gfx/ohno.png")
	Images.load = love.graphics.newImage("res/gfx/load.png")
	Images.save = love.graphics.newImage("res/gfx/save.png")
	Images.show_progress = love.graphics.newImage("res/gfx/show-progress.png")

	InitButtons()

	progressButton = ImageButton:new(Width - 48 * 1, 0, 48, 48, Images.show_progress, function()
		ShowProgress = not ShowProgress
	end)
	loadButton = ImageButton:new(Width - 48 * 2, 0, 48, 48, Images.load, loadGame)
	saveButton = ImageButton:new(Width - 48 * 3, 0, 48, 48, Images.save, saveGame)

	GenerateMap()
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

	Panel:update()

	if MapReady then
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
	DrawGame()
	Camera:detach()

	DrawOverlay()
end

---@diagnostic disable-next-line: duplicate-set-field
function love.mousepressed(mouseX, mouseY, button)
	if UpdateButtons() then
		return
	end
	if mouseX < ButtonColumnCount * ButtonSize then
		return
	end
	if saveButton:update() then
		return
	end
	if loadButton:update() then
		return
	end
	if progressButton:update() then
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
		Cell:new(a, b, Cells[a][b].type, nil, Content:new(Cells[a][b].content.opts, Cells[a][b].content.amount))
	local iserase = button == 2

	if not iserase then
		if
			(BuildSelection == GameBuilder.cellTypes.core and IsCorePlased)
			or (BuildSelection == CellType.NONE and BuildSelectionNum == 0)
		then
			goto exit
		end

		Cells[a][b].content.opts = DEFAULT_CONTENT_TYPE
		Cells[a][b].content.amount = 0
		Cells[a][b].direction = Rotation
		Cells[a][b].type = BuildSelection

		::exit::
	end

	if iserase and Cells[a][b].type ~= CellType.ORE then
		if Cells[a][b].type == GameBuilder.cellTypes.core then
			IsCorePlased = false
		end
		Cells[a][b].type = CellType.NONE
	end

	if not iserase and not Cells[a][b].under then
		Cells[a][b].under = under
	end
	Cells[a][b].content.amount = 0
	Cells[a][b].progress = 0
	Cells[a][b].storage = {}
end

---@diagnostic disable-next-line: duplicate-set-field
function love.keypressed(key)
	if key == "space" then
		local x = love.mouse.getX() - Width / 2 + CameraX
		local y = love.mouse.getY() - Height / 2 + CameraY
		local a = math.ceil(x / CellSize)
		local b = math.ceil(y / CellSize)

		for k, v in pairs(Cells[a][b].storage) do
			print(k, v)
		end
	elseif key == "r" then
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
	elseif string.byte(key, 1, 1) >= string.byte("1", 1, 1) and string.byte(key, 1, 1) <= string.byte("9", 1, 1) then
		local num = string.byte(key, 1, 1) - 48
		if num <= #BuildableCellTypes then
			BuildSelection = BuildableCellTypes[num]
			BuildSelectionNum = num
		end
	elseif key == "q" then
		BuildSelection = CellType.NONE
		BuildSelectionNum = 0
	elseif key == "p" then
		saveGame()
	elseif key == "l" then
		loadGame()
	elseif key == "f5" then
		MapReady = false
		GenerateMap()
		MapReady = true
	elseif key == "f9" and IsDebug then
		debug.debug()
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
	local s = ("return ({{ playTime = %f, seed = %d, generation = %d }, {\n"):format(
		PlayTime,
		love.math.getRandomSeed(),
		MapGeneration
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
		MapGeneration = info.generation or 1
		Cells = save
		love.window.showMessageBox("Loaded!", "Lastest save loaded!")
	end
end
