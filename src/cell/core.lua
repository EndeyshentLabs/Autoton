Core = {}
---@param resource Content
function Core:add(resource)
	self[resource.opts] = (self[resource.opts] or 0) + resource.amount
end
---@param resource Content
function Core:remove(resource)
	self[resource.opts] = (self[resource.opts] or 0) - resource.amount
	if self[resource.opts] <= 0 then
		self[resource.opts] = nil
	end
end

IsCorePlased = false
