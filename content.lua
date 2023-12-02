---@enum ContentType
ContentType = {
	IRON = "iron",
	GOLD = "gold",
	[0] = "OH_NO",
}

protectEnum(ContentType)

---@enum OreContentSpawnRates
OreContentSpawnRates = {
	[ContentType.IRON] = 0.8,
	[ContentType.GOLD] = 0.1,
}

protectEnum(OreContentSpawnRates)

---@type ContentType
DEFAULT_CONTENT_NAME = "OH_NO"

---@class Content
---@field name ContentType
---@field amount integer
Content = {}

---Content class constructor
---@param name? ContentType
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
