Args = {
	debug = {
		---@diagnostic disable-next-line: unused-local
		callback = function(pos)
			IsDebug = true

			love.window.setTitle(love.window.getTitle() .. " (DEBUG)")
		end,
	},
	["debug-ui"] = {
		---@diagnostic disable-next-line: unused-local
		callback = function(pos)
			IsDebug = true

			love.window.setTitle(love.window.getTitle() .. " (DEBUG)")

			---@diagnostic disable-next-line: lowercase-global
			vudu = require("lib.vudu.vudu")
			vudu:initialize()
			vudu:initializeDefaultHotkeys()
		end,
	},
	seed = {
		callback = function(pos)
			if arg[pos + 1] == nil or not arg[pos + 1]:find("%d+") then
				error("No seed was provided or invalid seed!")
			end

			-- arg[pos + 1] WILL be numeric 100%
			---@diagnostic disable-next-line: param-type-mismatch
			love.math.setRandomSeed(tonumber(arg[pos + 1]))
		end,
	},
}

local function asArg(a)
	if string.sub(a, 1, 2) == "--" then
		return string.sub(a, 3, #a), true
	elseif string.sub(a, 1, 1) == "-" then
		return string.sub(a, 2, #a), true
	end

	return a, false
end

function ParseArgs()
	for k, v in ipairs(arg) do
		local a, opt = asArg(v)

		if not opt then
			goto continue
		end

		if Args[a] ~= nil then
			Args[a].callback(k)
		end

		::continue::
	end
end
