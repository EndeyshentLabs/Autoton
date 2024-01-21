Core = {}
---@param resource Content
function Core:add(resource)
	self[resource.name] = (self[resource.name] or 0) + resource.amount
end
---@param resource Content
function Core:remove(resource)
	self[resource.name] = (self[resource.name] or 0) - resource.amount
	if self[resource.name] <= 0 then
		self[resource.name] = nil
	end
end

IsCorePlased = false
