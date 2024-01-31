MapReady = false
MapGeneration = 0

function GenerateMap()
	table.sort(OreContentSpawnRates, function(a, b)
		return not (a < b)
	end)

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
			local type = CellType.NONE
			local contentName = DEFAULT_CONTENT_TYPE

			for content, rate in pairs(OreContentSpawnRates) do
				if (rate >= 0.5 and oreGrid[x][y] > rate) or (rate < 0.5 and oreGrid[x][y] < rate) then
					type = CellType.ORE
					contentName = content

					break
				end
			end

			Cells[x][y] = Cell:new(x, y, type, Direction.RIGHT, Content:new(contentName))
		end
	end

	MapGeneration = MapGeneration + 1

	MapReady = 1
end

function DumpMap()
	for x, _ in pairs(Cells) do
		for y, cell in pairs(Cells[x]) do
			print(x, y, cell.type.name, cell.content.name, cell.content.amount)
		end
	end
end
