function Draw_game()
	Camera:attach()
	DrawGame()
	Camera:detach()
end

function Draw_ui()
	DrawOverlay()
	Some:draw()
end

DrawStages = {
	Draw_game,
	Draw_ui,
}
