---@type table<string, ContentOpts>
ContentType = {
	["OH_NO"] = {
		displayName = "OH_NO",
		image = Images.ohno,
	},
}

---@type ContentOpts
DEFAULT_CONTENT_TYPE = ContentType["OH_NO"]

---@class Content
---@field opts ContentOpts
---@field amount integer
---@field new function
Content = class("Content", {
	opts = DEFAULT_CONTENT_TYPE,
	amount = 0,
})

---Content class constructor
---@param opts ContentOpts
---@param amount integer
function Content:init(opts, amount)
	self.opts = opts or DEFAULT_CONTENT_TYPE
	self.amount = amount or 0
end
