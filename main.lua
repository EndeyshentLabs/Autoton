require("utils")
require("cell")
local camera = require("lib.hump.camera")

local cellAmount = 20

---@type Direction
Rotation = Direction.RIGHT

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

	for x = 1, cellAmount do
		oreGrid[x] = {}

		for y = 1, cellAmount do
			oreGrid[x][y] = love.math.noise(baseX + 0.1 * x, baseY + 0.1 * y)
		end
	end

	for x = 1, cellAmount, 1 do
		Cells[x] = {}

		for y = 1, cellAmount, 1 do
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

			Cells[x][y] = Cell:new(type, nil, Content:new(contentName))
		end
	end
end

---@diagnostic disable-next-line: duplicate-set-field
function love.load()
	if isDebug() then
		---@diagnostic disable-next-line: lowercase-global
		vudu = require("lib.vudu.vudu")
		vudu:initialize()
	end

	Camera = camera()
	Cells = {}
	Font = love.graphics.newFont("res/fonts/fira.ttf", 15)

	Images = {}
	Images.conveyor = love.graphics.newImage("res/gfx/conveyor.png")
	Images.junction = love.graphics.newImage("res/gfx/junction.png")
	Images.generator = love.graphics.newImage("res/gfx/generator.png")
	Images.ore_iron = love.graphics.newImage("res/gfx/ore-iron.png")
	Images.ore_gold = love.graphics.newImage("res/gfx/ore-gold.png")

	generateMap()
	dumpMap()
end

local cameraX = 0
local cameraY = 0

local time = 1

---@diagnostic disable-next-line: duplicate-set-field
function love.update(dt)
	time = time - dt

	local secondPassed = false

	if time <= 0 then
		secondPassed = true

		print("Second passed")

		local leftover = math.abs(time)
		time = 1 - leftover
	end

	if love.keyboard.isDown("w") then
		cameraY = cameraY - 300 * dt
	elseif love.keyboard.isDown("s") then
		cameraY = cameraY + 300 * dt
	end
	if love.keyboard.isDown("a") then
		cameraX = cameraX - 300 * dt
	elseif love.keyboard.isDown("d") then
		cameraX = cameraX + 300 * dt
	end

	Camera:lookAt(cameraX, cameraY)

	for x, _ in pairs(Cells) do
		for y, cell in pairs(Cells[x]) do
			local type = cell.type

			if type == CellType.GENERATOR then
				if
					y + 1 > cellAmount
					or Cells[x][y + 1].type ~= CellType.CONVEYOR
					or not cell.under
					or Cells[x][y].under.content.name == DEFAULT_CONTENT_NAME
				then
					goto continue
				end

				if
					(
						Cells[x][y + 1].content.name == cell.under.content.name
						or Cells[x][y + 1].content.name == DEFAULT_CONTENT_NAME
					) and secondPassed
				then
					Cells[x][y + 1].content.name = cell.under.content.name
					Cells[x][y + 1].content.amount = Cells[x][y + 1].content.amount + 1
				end
			elseif type == CellType.CONVEYOR then
				if cell.content.amount <= 0 then
					Cells[x][y].content.name = DEFAULT_CONTENT_NAME
					goto continue
				end

				local offset = { ["x"] = 0, ["y"] = 0 }

				if cell.direction == Direction.RIGHT then
					offset.x = 1
				elseif cell.direction == Direction.DOWN then
					offset.y = 1
				elseif cell.direction == Direction.LEFT then
					offset.x = -1
				elseif cell.direction == Direction.UP then
					offset.y = -1
				end

				if x + offset.x <= 0 or x + offset.x > cellAmount or y + offset.y <= 0 or y + offset.y > cellAmount then
					goto continue
				end

				if
					x + offset.x > cellAmount
					or y + offset.y > cellAmount
					or Cells[x + offset.x][y + offset.y].type ~= CellType.CONVEYOR
					or Cells[x][y].content.amount == 0
				then
					goto continue
				end

				if
					(
						Cells[x + offset.x][y + offset.y].content.name == cell.content.name
						or Cells[x + offset.x][y + offset.y].content.name == DEFAULT_CONTENT_NAME
					) and secondPassed
				then
					local sub = 3
					Cells[x + offset.x][y + offset.y].content.name = cell.content.name

					if Cells[x][y].content.amount < 3 then
						sub = Cells[x][y].content.amount
					end

					assert(sub <= 3 and sub > 0, "0 < sub <= 3 (current " .. sub .. ")")

					Cells[x + offset.x][y + offset.y].content.amount = Cells[x + offset.x][y + offset.y].content.amount
						+ sub

					Cells[x][y].content.amount = Cells[x][y].content.amount - sub

					if Cells[x][y].content.amount == 0 then
						Cells[x][y].content.name = DEFAULT_CONTENT_NAME
					end
				end
			elseif type == CellType.JUNCTION then
				if y + 1 > cellAmount or y - 1 < 0 then
					goto continue
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

				if x + 1 > cellAmount or x - 1 < 0 then
					goto continue
				end
				if
					(Cells[x + 1][y].type == CellType.CONVEYOR)
					and (Cells[x - 1][y].type == CellType.CONVEYOR and Cells[x][y - 1].direction == Direction.right)
					and (Cells[x - 1][y].content.name == Cells[x - 1][y].content.name or Cells[x + 1][y].content.name == DEFAULT_CONTENT_NAME)
					and (Cells[x - 1][y].content.amount > 0)
				then
					Cells[x - 1][y].content.amount = Cells[x - 1][y].content.amount - 1
					Cells[x + 1][y].content.amount = Cells[x + 1][y].content.amount + 1
					Cells[x + 1][y].content.name = Cells[x - 1][y].content.name
				end
			end
			::continue::
		end
	end
end

local spacing = 64

---@param x integer
---@param y integer
---@param cell Cell
local function drawCell(x, y, cell)
	local camX = cameraX - love.graphics.getWidth() / 2
	local camY = cameraY - love.graphics.getHeight() / 2

	if x * spacing - spacing >= cameraX + love.graphics.getWidth() / 2 then
		return
	end
	if x * spacing <= camX then
		return
	end
	if y * spacing - spacing >= cameraY + love.graphics.getHeight() / 2 then
		return
	end
	if y * spacing <= camY then
		return
	end

	local image
	local type = cell.type

	love.graphics.setColor(1, 1, 1)

	if type == CellType.CONVEYOR then
		image = Images.conveyor
	elseif type == CellType.JUNCTION then
		image = Images.junction
	elseif type == CellType.GENERATOR then
		image = Images.generator
	elseif type == CellType.ORE then
		if cell.content.name == ContentType.IRON then
			image = Images.ore_iron
		elseif cell.content.name == ContentType.GOLD then
			image = Images.ore_gold
		end
	end

	if image then
		local offsetX = 0
		local offsetY = 0

		if cell.direction == Direction.DOWN then
			offsetX = spacing
		elseif cell.direction == Direction.LEFT then
			offsetX = spacing
			offsetY = spacing
		elseif cell.direction == Direction.UP then
			offsetY = spacing
		end

		love.graphics.draw(
			image,
			(x - 1) * spacing + offsetX,
			(y - 1) * spacing + offsetY,
			cell.direction * math.rad(90),
			spacing / 128,
			spacing / 128
		)
	end
end

---@diagnostic disable-next-line: duplicate-set-field
function love.draw()
	love.graphics.setFont(Font)

	Camera:attach()

	local a = math.ceil((love.mouse.getX() - (love.graphics.getWidth() / 2) + cameraX) / spacing)
	local b = math.ceil((love.mouse.getY() - (love.graphics.getHeight() / 2) + cameraY) / spacing)

	local previewOffsetX = 0
	local previewOffsetY = 0

	if Rotation == 1 then
		previewOffsetX = spacing
	elseif Rotation == 2 then
		previewOffsetX = spacing
		previewOffsetY = spacing
	elseif Rotation == 3 then
		previewOffsetY = spacing
	end

	love.graphics.setColor(1, 1, 1, 0.5)
	love.graphics.draw(
		Images.conveyor,
		(a - 1) * spacing + previewOffsetX,
		(b - 1) * spacing + previewOffsetY,
		Rotation * math.pi / 2,
		spacing / 128,
		spacing / 128
	)

	-- Draw grid
	for x, _ in pairs(Cells) do
		for y, cell in pairs(Cells[x]) do
			if cell.under then
				drawCell(x, y, cell.under)
			end

			drawCell(x, y, cell)

			love.graphics.setColor(0.5, 0.5, 0.5)
			love.graphics.print(
				cell.content.name .. "\n" .. cell.content.amount,
				(x - 1) * spacing + 1,
				(y - 1) * spacing + 1
			)

			love.graphics.setColor(0.1, 0.1, 0.1)
			love.graphics.line(x * spacing, y, x * spacing, love.graphics.getHeight())
			love.graphics.line(x, y * spacing, love.graphics.getWidth(), y * spacing)
		end
	end

	Camera:detach()

	love.graphics.setColor(1, 0, 0)
	printShadow(
		"LMB - Place generator\nRMB - Place conveyor\nMMB - Destroy\nR - rotate (current: "
			.. Rotation
			.. ")\nL_SHIFT + R - Reverse rotate",
		0,
		0,
		1,
		0,
		0
	)
end

---@diagnostic disable-next-line: duplicate-set-field
function love.mousepressed(mouseX, mouseY, button)
	local x = mouseX - love.graphics.getWidth() / 2 + cameraX
	local y = mouseY - love.graphics.getHeight() / 2 + cameraY
	local a = math.ceil(x / spacing)
	local b = math.ceil(y / spacing)

	if a > cellAmount or b > cellAmount or a <= 0 or b <= 0 then
		return
	end

	print(("Mouse %d: %d, %d"):format(button, a, b))

	local under = Cell:new(Cells[a][b].type, nil, Content:new(Cells[a][b].content.name, Cells[a][b].content.amount)) -- Cells[a][b].content
	local iserase = false

	if button == 1 then
		Cells[a][b].type = CellType.GENERATOR
	elseif button == 2 then
		Cells[a][b].content.name = DEFAULT_CONTENT_NAME
		Cells[a][b].type = CellType.CONVEYOR
	elseif button == 4 then
		Cells[a][b].content.name = DEFAULT_CONTENT_NAME
		Cells[a][b].type = CellType.JUNCTION
	elseif button == 3 then
		if Cells[a][b].type ~= CellType.ORE then
			Cells[a][b].type = CellType.NONE
		end

		iserase = true
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
	end
end
