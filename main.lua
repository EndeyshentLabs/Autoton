Width = love.graphics.getWidth()
Height = love.graphics.getHeight()
Images = {}

require("lib.30log")

Camera = nil
CameraX = 0
CameraY = 0

require("args")
require("utils")

---@diagnostic disable-next-line: duplicate-set-field
function love.load()
	require("src.stages")

	for _, stage in ipairs(LoadStages) do
		stage()
	end
end

---@diagnostic disable-next-line: duplicate-set-field
function love.update(dt)
	PlayTime = PlayTime + dt

	for _, stage in ipairs(UpdateStages) do
		stage(dt)
	end
end

---@diagnostic disable-next-line: duplicate-set-field
function love.draw()
	love.graphics.setFont(Font)

	for _, stage in ipairs(DrawStages) do
		stage()
	end
end

---@diagnostic disable-next-line: duplicate-set-field
function love.mousepressed(mouseX, mouseY, button)
	if UpdateButtons() then
		return
	end
	if mouseX < ButtonColumnCount * ButtonSize then
		return
	end
	if UpdateUtilButtons() then
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

	if not iserase and (BuildSelectionNum == 0 or BuildSelection == CellType.NONE) then
		return
	end

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

---@param key love.KeyConstant
---@diagnostic disable-next-line: duplicate-set-field
function love.keypressed(key)
	-- TODO: Migrate this to keybind system(probably arrow keys)
	if string.byte(key, 1, 1) >= string.byte("1", 1, 1) and string.byte(key, 1, 1) <= string.byte("9", 1, 1) then
		local num = string.byte(key, 1, 1) - 48
		if num <= #BuildableCellTypes then
			BuildSelection = BuildableCellTypes[num]
			BuildSelectionNum = num
		end

		return
	end

	local bind = KeyboardBinds[key]

	if bind then
		bind.callback()
	end
end

---@diagnostic disable-next-line: duplicate-set-field
function love.resize()
	Width = love.graphics.getWidth()
	Height = love.graphics.getHeight()
	for k, utilButton in ipairs(UtilButtons) do
		utilButton.x = Width - ButtonSize * k
	end
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
