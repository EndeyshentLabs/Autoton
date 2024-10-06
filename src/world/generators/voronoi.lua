local p = require("lib.polygon")
local v = require("lib.voronoi")

local points = {}
local vertex, segments, centroids = {}, {}, {}

local function generatePoints()
	for i = 1, 100 do
		points[i] = {
			x = love.math.random(0, CellAmount) + love.math.random(),
			y = love.math.random(0, CellAmount) + love.math.random(),
		}
	end

	vertex, segments, centroids = v(points, 0, 0, CellAmount, CellAmount)
end

local function markOregen()
	for _, c in ipairs(centroids) do
		if love.math.random(1, 3) == 2 then
			c.oreGen = love.math.random(1, 2)
		end
	end
end

return function()
	generatePoints()
	markOregen()

	for x = 1, CellAmount do
		Cells[x] = {}

		for y = 1, CellAmount do
			local type = CellType.NONE
			local contentName = DEFAULT_CONTENT_TYPE

			local _, currentCentroid = p.findContainingPolygon(x, y, centroids, "vertices")
			if currentCentroid and centroids[currentCentroid].oreGen ~= nil then
				local ore = centroids[currentCentroid].oreGen
				type = CellType.ORE

				if ore == 1 then
					contentName = GameBuilder.contentTypes.oreGold
				elseif ore == 2 then
					contentName = GameBuilder.contentTypes.oreIron
				else
					error("Unreachable: " .. ore)
				end
			end

			Cells[x][y] = Cell:new(x, y, type, Direction.RIGHT, Content:new(contentName))
		end
	end
end
