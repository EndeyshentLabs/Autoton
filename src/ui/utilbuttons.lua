UtilButtons = {}

function InitUtilButtons()
	for k, proto in ipairs(UtilButtonsProto) do
		table.insert(
			UtilButtons,
			ImageButton:new(Width - ButtonSize * k, 0, ButtonSize, ButtonSize, proto[1], proto[2])
		)
	end
end

function UpdateUtilButtons()
	local triggered = false
	for _, v in pairs(UtilButtons) do
		local res = v:update()
		if res and not triggered then
			triggered = true
			return triggered
		end
	end
end

function DrawUtilButtons()
	for _, v in pairs(UtilButtons) do
		v:draw()
	end
end
