local mt_class = {}

function mt_class:extends(parrent)
	self.super = parrent
	setmetatable(mt_class, { __index = parrent })
	parrent.__members__ = parrent.__members__ or {}
	return self
end

local function define(class, members)
	class.__members__ = class.__members__ or {}
	for k, v in pairs(members) do
		class.__members__[k] = v
	end
	function class:new(...)
		local newvalue = {}
		for k, v in pairs(class.__members__) do
			newvalue[k] = v
		end
		setmetatable(newvalue, { __index = class })
		if newvalue.__init then
			newvalue:__init(...)
		end
		return newvalue
	end
end

function class(name)
	local newclass = {}
	_G[name] = newclass
	return setmetatable(newclass, { __index = mt_class, __call = define })
end
