local camera = require("lib.hump.camera")

function Load_pre()
	require("src")

	RequireAll()
	ParseArgs()
end

function Load_resources()
	Camera = camera()
	Font = love.graphics.newFont("res/fonts/fira.ttf", 15)

	Images.ohno = love.graphics.newImage("res/gfx/ohno.png")
	Images.load = love.graphics.newImage("res/gfx/load.png")
	Images.save = love.graphics.newImage("res/gfx/save.png")
	Images.show_progress = love.graphics.newImage("res/gfx/show-progress.png")
end

function Load_ui()
	InitButtons()

	progressButton = ImageButton:new(Width - 48 * 1, 0, 48, 48, Images.show_progress, function()
		ShowProgress = not ShowProgress
	end)
	loadButton = ImageButton:new(Width - 48 * 2, 0, 48, 48, Images.load, loadGame)
	saveButton = ImageButton:new(Width - 48 * 3, 0, 48, 48, Images.save, saveGame)
end

function Load_after()
	GenerateMap()
end

LoadStages = {
	Load_pre,
	Load_resources,
	Load_ui,
	Load_after,
}
