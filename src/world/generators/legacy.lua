return function()
	table.sort(OreContentSpawnRates, function(a, b)
		return not (a < b)
	end)

	local oreGrid = {}
	local baseX = 10000 * love.math.random()
	local baseY = 10000 * love.math.random()

	for x = 1, CellAmount do
		oreGrid[x] = {}

		for y = 1, CellAmount do
			oreGrid[x][y] = love.math.noise(baseX + BasisX * x, baseY + BasisY * y)
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
