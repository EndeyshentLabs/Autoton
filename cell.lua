---@enum ContentType
ContentType = {
	IRON = "iron",
	GOLD = "gold",
}

DEFAULT_CONTENT_NAME = "OH_NO"

---@class Content
---@field name string
---@field amount integer
Content = {}

---Content class constructor
---@param name? string
---@param amount? integer
---@return Content
function Content:new(name, amount)
	local public = {}
	public.name = name or DEFAULT_CONTENT_NAME
	public.amount = amount or 0

	setmetatable(public, self)
	self.__index = self
	return public
end

---@enum CellType
CellType = {
	NONE = 0,
	GENERATOR = 1,
	CONVEYOR = 2,
	JUNCTION = 3,
	ORE = 4,
}

function CellType.tostring(cellType)
	if cellType == CellType.GENERATOR then
		return "GENERATOR"
	elseif cellType == CellType.CONVEYOR then
		return "CONVEYOR"
	elseif cellType == CellType.JUNCTION then
		return "JUNCTION"
	elseif cellType == CellType.ORE then
		return "ORE"
	elseif cellType == CellType.NONE then
		return "(void)"
	end
end

---@class Cell
---@field type CellType
---@field direction integer
---@field content Content
---@field under Cell|nil
Cell = {}

---Cell class constructor
---@param type CellType
---@param direction? integer
---@param content? Content
---@param under? Cell
---@return Cell
function Cell:new(type, direction, content, under)
	local public = {}
	public.type = type
	public.direction = direction or 0
	public.content = content or Content:new()
	public.under = under

	setmetatable(public, self)
	self.__index = self
	return public
end
