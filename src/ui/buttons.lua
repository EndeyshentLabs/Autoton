Buttons = {}
ButtonSize = 48

ButtonColumnCount = 5

function InitButtons()
	for k, v in ipairs(BuildableCellTypes) do
		table.insert(
			Buttons,
			ImageButton:new(
				((k - 1) % ButtonColumnCount) * ButtonSize,
				math.ceil(k / ButtonColumnCount) * ButtonSize - ButtonSize,
				ButtonSize,
				ButtonSize,
				---@diagnostic disable-next-line: missing-fields
				ImageFromCell({ type = v }),
				function()
					BuildSelection = v
				end
			)
		)
	end
end

function UpdateButtons()
	local triggered = false
	for _, v in pairs(Buttons) do
		local res = v:update()
		if res and not triggered then
			triggered = true
			return triggered
		end
	end
end

function DrawButtons()
	for _, v in pairs(Buttons) do
		v:draw()
	end
end
