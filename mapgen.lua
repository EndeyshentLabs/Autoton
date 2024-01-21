MapReady = false
MapGeneration = 0

function GenerateMap()
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

	MapGeneration = MapGeneration + 1

	MapReady = 1
end

function DumpMap()
	for x, _ in pairs(Cells) do
		for y, cell in pairs(Cells[x]) do
			print(x, y, CellType.tostring(cell.type), cell.content.name, cell.content.amount)
		end
	end
end
