ShowProgress = true

CellAmount = 100

---@type Direction
Rotation = Direction.RIGHT
---@type CellOpts
BuildSelection = CellType.NONE
---@type integer
BuildSelectionNum = 0

---@type boolean
AltView = true

---@enum OreContentSpawnRates
OreContentSpawnRates = {
	[GameBuilder.contentTypes.oreIron] = 0.8,
	[GameBuilder.contentTypes.oreGold] = 0.1,
}

-- Mapgen "stretching" factor

BasisX = 0.05
BasisY = 0.1
