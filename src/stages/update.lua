function Update_camera(dt)
	if love.keyboard.isScancodeDown("w") then
		CameraY = CameraY - 300 * dt
	elseif love.keyboard.isScancodeDown("s") then
		CameraY = CameraY + 300 * dt
	end
	if love.keyboard.isScancodeDown("a") then
		CameraX = CameraX - 300 * dt
	elseif love.keyboard.isScancodeDown("d") then
		CameraX = CameraX + 300 * dt
	end

	Camera:lookAt(CameraX, CameraY)
end

function Update_ui(dt)
	Panel:update()
end

function Update_world(dt)
	if MapReady then
		for x, _ in pairs(Cells) do
			for _, cell in pairs(Cells[x]) do
				if cell.type ~= CellType.ORE and cell.type ~= CellType.NONE then
					cell:update(dt)
				end
			end
		end
	end
end

UpdateStages = {
	Update_camera,
	Update_ui,
	Update_world,
}
