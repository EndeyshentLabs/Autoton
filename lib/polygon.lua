-- Modified by @EndeyshentLabs
local M = {}

function M.checkSide(point, vect1, vect2)
    -- Returns a positive number if point is on the right of the line going through points vect1 and vect2,
    -- 0 if it lies on the line, and a negative number if it is on the left.
    return (vect2.x - vect1.x) * (point.y - vect1.y) - (vect2.y - vect1.y) * (point.x - vect1.x)
end

function M.isInsidePolygon(point, polygon)
    -- Polygon is a list of points.
    local side = M.checkSide(point, polygon[#polygon], polygon[1])
    if side == 0 then
        return "on the line" -- Returns a specific result which still is considered true by Lua.
    end
    local left = side < 0
    for i = 2, #polygon do
        local left2 = M.checkSide(point, polygon[i - 1], polygon[i]) < 0
        if left ~= left2 then
            return false
        end
    end
    return true
end

function M.getBoundingBox(polygon)
    if not polygon.AABB then
        local minx = polygon[1].x
        local miny = polygon[1].y
        local maxx = polygon[1].x
        local maxy = polygon[1].y
        for i = 2, #polygon do
            if polygon[i].x < minx then
                minx = polygon[i].x
            elseif polygon[i].x > maxx then
                maxx = polygon[i].x
            end
            if polygon[i].y < miny then
                miny = polygon[i].y
            elseif polygon[i].y > maxy then
                maxy = polygon[i].y
            end
        end
        polygon.AABB = { { x = minx, y = miny }, { x = maxx, y = maxy } }
    end
    return polygon.AABB[1].x, polygon.AABB[1].y, polygon.AABB[2].x, polygon.AABB[2].y
end

function M.isInsideAABB(point, polygon)
    local minx, miny, maxx, maxy = M.getBoundingBox(polygon)
    if point.x < minx or point.x > maxx or point.y < miny or point.x > maxx then
        return false
    else
        return true
    end
end

function M.findContainingPolygon(x, y, list, key)
    local point = { x = x, y = y }
    for i = 1, #list do
        local polygon
        if key then
            polygon = list[i][key]
        else
            polygon = list[i]
        end
        if (#polygon >= 3) and M.isInsideAABB(point, polygon) and M.isInsidePolygon(point, polygon) then
            return polygon, i
        end
    end
end

function M.printPoint(point)
    print('x=' .. point.x .. ', y=' .. point.y)
end

function M.printPolygon(polygon)
    print('Printing vertices of a polygon with ' .. #polygon .. ' sides:')
    for i = 1, #polygon do
        io.write('    ')
        M.printPoint(polygon[i])
    end
end

return M
