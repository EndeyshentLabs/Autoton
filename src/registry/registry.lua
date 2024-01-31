---@diagnostic disable: inject-field
RESERVED_GAME_BASE = "AUTOTON"

---@class ContentBuilder
---@field base string Builder's base
---@field images table<love.Image> Images added/created by builder
---@field contentTypes table<ContentOpts> ContentTypes added/created by builder
---@field cellTypes table<Cell> Cells added/created by builder
---@field binds table<love.KeyConstant, KeyboardBindOpts> Keyboard keybinds
---@field new function
ContentBuilder = class("ContentBuilder", {
	base = "",
	images = {},
	contentTypes = {},
	cellTypes = {},
	binds = {},
})

function ContentBuilder:init(base)
	assert(base ~= nil, "ContentBuilder's base cannot be nil!")
	assert(base ~= "", "ContentBuilder's base cannot be empty!")
	self.base = base
end

---Make "base::name" type string
---@param name string
---@return string
function ContentBuilder:basedName(name) -- NOTE: NICE function name
	return self.base .. "::" .. name
end

---Add new ContentType
---@param name string New content's name
---@param opts ContentOpts Content opts
function ContentBuilder:addContent(name, opts)
	local basedName = self:basedName(name)

	ContentType[basedName] = opts
	ContentType[basedName]._BASED_NAME = basedName
	self.contentTypes[name] = ContentType[basedName]
end

---Load new image
---@param name string Usable name of an image
---@param path string Path to image
---@return love.Image
function ContentBuilder:addImage(name, path)
	local basedName = self:basedName(name)

	Images[basedName] = love.graphics.newImage(path)
	self.images[name] = Images[basedName]
	return Images[basedName]
end

---Add new ContentType
---@param name string New content's name
---@param opts CellOpts Content opts
function ContentBuilder:addCell(name, opts)
	local basedName = self:basedName(name)

	CellType[basedName] = opts
	CellType[basedName]._BASED_NAME = basedName
	self.cellTypes[name] = CellType[basedName]

	if opts.buildable then
		table.insert(BuildableCellTypes, self.cellTypes[name])
	end
end

---Add new KeyboardBind
---@param key love.KeyConstant
---@param opts KeyboardBindOpts
function ContentBuilder:addKeyboardBind(key, opts)
	KeyboardBinds[key] = opts
	KeyboardBinds[key]._BASED_NAME = self:basedName(key)
	self.binds[key] = KeyboardBinds[key]
end

ContentRegistry = {
	---@type table<string, ContentBuilder>
	entries = {},
}
ContentRegistry.__index = ContentRegistry

---Creates new registry entry and return ContentBuilder for it
---@param base string Builder's base
---@return ContentBuilder
function ContentRegistry:makeContentBuilder(base)
	if base == RESERVED_GAME_BASE then
		error(("Cannot create base '%s': Reserved name"):format(base))
	end
	for k, _ in pairs(self.entries) do
		if base == k then
			error(("Base with name '%s' already exitst!"):format(base))
		end
	end

	local builder = ContentBuilder:new(base)
	self.entries[base] = builder

	return builder
end

------------ PSEUDO TYPES ------------

---@class ContentOpts
---@field displayName string? Content's display name
---@field image love.Image Content's texture as image

---@class CellOpts
---@field displayName string Cell's display name
---@field description string? Cell's description
---@field image? love.Image Cell's texture as image
---@field update? function<Cell, number> update method
---@field buildable boolean Is cell buildable
---@field drawable boolean Is cell buildable
---@field isStorage boolean Is cell buildable
---@field maxCap? integer Storage's max capacity
---@field time? number Is cell buildable

---@class KeyboardBindOpts
---@field displayName string
---@field key love.KeyConstant
---@field mod1 love.KeyConstant?
---@field mod2 love.KeyConstant?
---@field mod3 love.KeyConstant?
---@field callback function
