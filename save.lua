require("cell")

---comment
---@param cell Cell
---@return integer|nil
---@return integer|nil
---@return integer|nil
---@return integer|nil
---@return Content|nil
---@return Cell|nil
function UnwrapCell(cell)
	if cell == nil then
		return nil, nil, nil, nil, nil, nil
	end
	local x, y, type, direction, content, under

	for k, v in pairs(cell) do
		if k == "x" then
			x = v
		elseif k == "y" then
			y = v
		elseif k == "type" then
			type = v
		elseif k == "direction" then
			direction = v
		elseif k == "content" then
			content = { ["name"] = v.name or "FIX_ME", ["amount"] = v.amount }
		elseif k == "under" then
			local _x, _y, _type, _direction, _content = UnwrapCell(v)
			under = Cell:new(
				_x or 0,
				_y or 0,
				_type or 0,
				_direction or 0,
				_content or { ["name"] = "BUG", ["amount"] = -11037 }
			)
		end
	end

	return x, y, type, direction, content, under
end

function CellToString(cell)
	if not cell then
		return
	end
	local x, y, type, direction, content, under = UnwrapCell(cell)
	local us = ""
	if under then
		us = CellToString(under)
	end
	if us == "" then
		us = "nil"
	end
	return ("Cell:new(%d, %d, %d, %d, %s, %s)"):format(
		x,
		y,
		type,
		direction,
		('{ ["name"] = "%s", ["amount"] = %d }'):format(content.name or "FIX_ME", content.amount or 0),
		us
	)
end
