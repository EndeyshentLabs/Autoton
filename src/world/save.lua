---Unwraps `cell`s fileds
---@param cell any
---@return integer|nil
---@return integer|nil
---@return CellOpts
---@return Direction
---@return Content|nil
---@return Cell|nil
function UnwrapCell(cell)
	if cell == nil then
		return nil, nil, CellType["NONE"], 0, nil, nil
	end

	local x = cell.x
	local y = cell.y
	local _type = cell.type
	local direction = cell.direction
	local content = cell.content
	local under

	if cell.under then
		local _x, _y, __type, _direction, _content = UnwrapCell(cell.under)
		under = Cell:new(
			_x or 0,
			_y or 0,
			__type,
			_direction or 0,
			_content
		)
	end

	return x, y, _type, direction, content, under
end

---Converts cell to valid lua Cell contrusction string
---@param cell Cell
---@return string|nil
function CellToString(cell)
	if not cell then
		return
	end
	local x, y, _type, direction, content, under = UnwrapCell(cell)
	local us = "nil"
	if under then
		us = CellToString(under)
	end
	return ('Cell:new(%d, %d, CellType["%s"], %d, Content:new(ContentType["%s"], %d), %s)'):format(
		x,
		y,
		_type._BASED_NAME,
		direction,
		content.opts._BASED_NAME,
		content.amount,
		us or "nil"
	)
end
