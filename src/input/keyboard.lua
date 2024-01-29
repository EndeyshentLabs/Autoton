---@type table<love.KeyConstant, KeyboardBindOpts>
KeyboardBinds = {}

---@param bind KeyboardBindOpts
function KeyboardBinds_tostring(bind)
	local s = bind.key

	if bind.mod1 then
		s = s .. "+" .. bind.mod1
	elseif bind.mod2 then
		s = s .. "+" .. bind.mod2
	elseif bind.mod3 then
		s = s .. "+" .. bind.mod3
	end

	return s .. " (" .. bind.displayName .. ")"
end
