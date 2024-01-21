function DrawGame()
	-- Draw grid
	if MapReady then
		for x, _ in pairs(Cells) do
			local xDrawn = false
			local camX = CameraX - Width / 2
			local camY = CameraY - Height / 2
			if (x * CellSize - CellSize >= CameraX + Width / 2) or (x * CellSize <= camX) then
				goto continue2
			end

			for y, cell in pairs(Cells[x]) do
				cell:draw()

				love.graphics.setColor(0.1, 0.1, 0.1)
				if not xDrawn then
					love.graphics.line(x * CellSize, 0, x * CellSize, CellSize * CellAmount)
					xDrawn = true
				end

				if (y * CellSize - CellSize >= CameraY + Height / 2) or (y * CellSize <= camY) then
					goto continue
				end

				love.graphics.line(0, y * CellSize, CellSize * CellAmount, y * CellSize)
				::continue::
			end
			::continue2::
		end
	end

	-- Preview drawing (if BuildSelection ~= CellType.NONE)
	local a = math.ceil((love.mouse.getX() - (Width / 2) + CameraX) / CellSize)
	local b = math.ceil((love.mouse.getY() - (Height / 2) + CameraY) / CellSize)

	---@diagnostic disable-next-line: missing-fields
	local previewImage = ImageFromCell({ type = BuildSelection })

	if previewImage then
		local previewOffsetX = 0
		local previewOffsetY = 0

		if Rotation == 1 then
			previewOffsetX = CellSize
		elseif Rotation == 2 then
			previewOffsetX = CellSize
			previewOffsetY = CellSize
		elseif Rotation == 3 then
			previewOffsetY = CellSize
		end

		love.graphics.setColor(1, 1, 1, 0.5)
		love.graphics.draw(
			previewImage,
			(a - 1) * CellSize + previewOffsetX,
			(b - 1) * CellSize + previewOffsetY,
			Rotation * math.rad(90),
			CellSize / 128,
			CellSize / 128
		)
	end
end

function DrawOverlay()
	DrawButtons()

	progressButton:draw()
	if ShowProgress then
		love.graphics.setColor(0, 1, 0)
	else
		love.graphics.setColor(1, 0, 0)
	end
	love.graphics.rectangle("line", progressButton.x, progressButton.y, progressButton.w, progressButton.h)
	loadButton:draw()
	saveButton:draw()

	if BuildSelection ~= CellType.NONE then
		love.graphics.setColor(0, 1, 0)
		love.graphics.rectangle("line", BuildSelectionNum * ButtonSize - ButtonSize, 0, ButtonSize, ButtonSize)
	end

	love.graphics.setColor(1, 1, 1)
	love.graphics.print(
		("FPS: %d  Seed: %d (Generation: %d)  PlayTime: %f"):format(
			love.timer.getFPS(),
			love.math.getRandomSeed(),
			MapGeneration,
			PlayTime
		),
		0,
		Height - Font:getHeight()
	)

	local index = 0
	for name, amount in pairs(Core) do
		if type(amount) == "function" then
			goto continue3
		end
		love.graphics.print(("%s: %d"):format(name, amount), 48 * 5 + 2, Font:getHeight() * index)
		index = index + 1
		::continue3::
	end
end
