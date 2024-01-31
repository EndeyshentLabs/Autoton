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

	---@type table<table<love.Image, function>>
	UtilButtonsProto = {
		{
			Images.show_progress,
			function()
				ShowProgress = not ShowProgress
			end,
		},
		{
			Images.load,
			function()
				loadGame()
			end,
		},
		{
			Images.save,
			function()
				saveGame()
			end,
		},
	}
end

function Load_ui()
	InitButtons()
	InitUtilButtons()
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
