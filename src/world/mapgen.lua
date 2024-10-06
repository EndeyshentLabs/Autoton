---@type boolean
MapReady = false
MapGeneration = 0

MapGenerator = require("src.world.generators.voronoi")

function GenerateMap()
	table.sort(OreContentSpawnRates, function(a, b)
		return not (a < b)
	end)

	MapGenerator()

	MapGeneration = MapGeneration + 1
	MapReady = true
end

function DumpMap()
	for x, _ in pairs(Cells) do
		for y, cell in pairs(Cells[x]) do
			print(x, y, cell.type.name, cell.content.name, cell.content.amount)
		end
	end
end
