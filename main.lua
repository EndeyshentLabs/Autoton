require("utils")

local cellAmount = 20
local rotation = 0

---@enum CellTypes
local CellType = {
	GENERATOR = 1,
	CONVEYOR = 2,
}

---@enum ContentType
local ContentType = {
	IRON = "iron",
}

function CellType.tostring(cellType)
	if cellType == 1 then
		return "GENERATOR"
	elseif cellType == 2 then
		return "CONVEYOR"
	elseif cellType == 0 then
		return "(void)"
	end
end

local function dumpMap()
	for x, _ in pairs(Cells) do
		for y, cell in pairs(Cells[x]) do
			print(x, y, CellType.tostring(cell.type), cell.content.name, cell.content.amount)
			-- print(x, y, cell.type, cell.content.name, cell.content.amount)
		end
	end
end

local DEFAULT_CONTENT_NAME = "OH_NO"

function love.load()
	Font = love.graphics.newFont("res/fonts/fira.ttf", 15)

	Images = {}
	Images.conveyor = love.graphics.newImage("res/gfx/conveyor.png")
	Images.generator = love.graphics.newImage("res/gfx/generator.png")

	Cells = {}

	for x = 1, cellAmount, 1 do
		Cells[x] = {}
		for y = 1, cellAmount, 1 do
			Cells[x][y] = {
				["type"] = 0,
				["direction"] = 0,
				["content"] = {
					["name"] = DEFAULT_CONTENT_NAME,
					["amount"] = 0,
				},
			}
		end
	end

	dumpMap()
end

function love.update(dt)
	for x, _ in pairs(Cells) do
		for y, cell in pairs(Cells[x]) do
			local type = cell.type

			if type == CellType.GENERATOR then
				if not Cells[x][y + 1] then
					goto continue
				end

				if Cells[x][y + 1].type == CellType.CONVEYOR then
					if
						Cells[x][y + 1].content.name == ContentType.IRON
						or Cells[x][y + 1].content.name == DEFAULT_CONTENT_NAME
					then
						Cells[x][y + 1].content.name = ContentType.IRON
						Cells[x][y + 1].content.amount = Cells[x][y + 1].content.amount + 1
					end
				end
			elseif type == CellType.CONVEYOR then
				if cell.content.amount == 0 then
					Cells[x][y].content.name = DEFAULT_CONTENT_NAME
					goto continue
				end

				local offset = { ["x"] = 0, ["y"] = 0 }

				if cell.direction == 0 then
					offset.x = 1
				elseif cell.direction == 1 then
					offset.y = 1
				elseif cell.direction == 2 then
					offset.x = -1
				elseif cell.direction == 3 then
					offset.y = -1
				end

				if Cells[x + offset.x] then
					if not Cells[x + offset.x][y + offset.y] then
						goto continue
					end
				else
					goto continue
				end

				if
					Cells[x + offset.x][y + offset.y].type == CellType.CONVEYOR
					and (
						Cells[x + offset.x][y + offset.y].content.name == cell.content.name
						or Cells[x + offset.x][y + offset.y].content.name == DEFAULT_CONTENT_NAME
					)
				then
					Cells[x + offset.x][y + offset.y].content.name = cell.content.name
					Cells[x + offset.x][y + offset.y].content.amount = Cells[x + offset.x][y + offset.y].content.amount
						+ cell.content.amount
					Cells[x][y].content.amount = DEFAULT_CONTENT_NAME
					Cells[x][y].content.amount = 0
				end
			end
			::continue::
		end
	end
end

local spacing = love.graphics.getWidth() / cellAmount

function love.draw()
	love.graphics.setFont(Font)

	local a = math.ceil(love.mouse.getX() / spacing)
	local b = math.ceil(love.mouse.getY() / spacing)

	local previewOffsetX = 0
	local previewOffsetY = 0
	if rotation == 1 then
		previewOffsetX = spacing
	elseif rotation == 2 then
		previewOffsetX = spacing
		previewOffsetY = spacing
	elseif rotation == 3 then
		previewOffsetY = spacing
	end
	love.graphics.setColor(1, 1, 1, 0.5)
	love.graphics.draw(
		Images.conveyor,
		(a - 1) * spacing + previewOffsetX,
		(b - 1) * spacing + previewOffsetY,
		rotation * math.pi / 2,
		spacing / 128,
		spacing / 128
	)

	-- Draw grid
	spacing = love.graphics.getWidth() / cellAmount
	for x, _ in pairs(Cells) do
		for y, cell in pairs(Cells[x]) do
			local type = cell.type
			local image

			love.graphics.setColor(1, 1, 1)

			if type == CellType.CONVEYOR then
				image = Images.conveyor
			elseif type == CellType.GENERATOR then
				image = Images.generator
			end

			if image then
				local offsetX = 0
				local offsetY = 0
				if cell.direction == 1 then
					offsetX = spacing
				elseif cell.direction == 2 then
					offsetX = spacing
					offsetY = spacing
				elseif cell.direction == 3 then
					offsetY = spacing
				end
				love.graphics.draw(
					image,
					(x - 1) * spacing + offsetX,
					(y - 1) * spacing + offsetY,
					cell.direction * math.pi / 2,
					spacing / 128,
					spacing / 128
				)
			end

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

	love.graphics.setColor(1, 0, 0)
	printShadow(
		"LMB - Place generator\nRMB - Place conveyor\nMMB - Destroy\nR - rotate (current: "
			.. rotation
			.. ")\nL_SHIFT + R - Reverse rotate",
		0,
		0,
		1,
		0,
		0
	)
end

function love.mousepressed(x, y, button)
	local a = math.ceil(x / spacing)
	local b = math.ceil(y / spacing)

	if a > cellAmount or b > cellAmount then
		return
	end

	if not Cells[a][b] then
		return
	end

	print(("Mouse %d: %d, %d"):format(button, a, b))

	if button == 1 then
		Cells[a][b].type = CellType.GENERATOR
	elseif button == 2 then
		Cells[a][b].type = CellType.CONVEYOR
	elseif button == 3 then
		Cells[a][b].type = 0
	end

	Cells[a][b].direction = rotation
	Cells[a][b].content.name = DEFAULT_CONTENT_NAME
	Cells[a][b].content.amount = 0
end

function love.keypressed(key)
	if key == "space" then
		dumpMap()
	elseif key == "r" then
		if love.keyboard.isDown("lshift") then
			if rotation == 0 then
				rotation = 3
			else
				rotation = rotation - 1
			end
		else
			if rotation == 3 then
				rotation = 0
			else
				rotation = rotation + 1
			end
		end
	end
end
