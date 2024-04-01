local camera = require("lib.hump.camera")

function Load_pre()
	-- TODO: Load saved settings

	-- Safely loading the locale (to prevent nil string)
	local locale = require("locale." .. CurrentLocaleName)
	for name, value in pairs(locale) do
		CurrentLocale[name] = value
	end

	require("src")

	RequireAll()
	ParseArgs()
end

function Load_resources()
	Camera = camera()
	Camera.smoother = Camera.smooth.damped(5)
	Font = love.graphics.newFont("res/fonts/fira.ttf", 15)

	Images.ohno = love.graphics.newImage("res/gfx/ohno.png")
	Images.load = love.graphics.newImage("res/gfx/load.png")
	Images.save = love.graphics.newImage("res/gfx/save.png")
	Images.show_progress = love.graphics.newImage("res/gfx/show-progress.png")
	Images.settings = love.graphics.newImage("res/gfx/settings.png")

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
		{
			Images.settings,
			function()
				SettingsWdow.active = true
			end,
		},
	}
end

function Load_ui()
	InitButtons()
	InitUtilButtons()
end

local _margin = 0
local function margin(n)
	_margin = _margin + n + (n == 0 and 0 or 2)
	return _margin
end

function Load_windows()
	Some.theme.font = Font

	-- TODO: Add locales for settings window

	SettingsWdow = Some.addWindow("Settings", 0, 0, 300, 600, false, true)
	SettingsWdow.active = false

	local vsyncButton = Some.WcheckButton(SettingsWdow, 0, margin(0), love.window.getVSync() == 1)
	Some.Wtext(SettingsWdow, "VSync", 20, margin(0) + 20 / 2 - Font:getHeight() / 2)

	local fullscreenButton = Some.WcheckButton(SettingsWdow, 0, margin(20), love.window.getFullscreen())
	Some.Wtext(SettingsWdow, "Fullscreen", 20, margin(0) + 20 / 2 - Font:getHeight() / 2)

	Some.WtextButton(SettingsWdow, "Save", 0, SettingsWdow.h - Font:getHeight() * 2, function ()
		love.window.setVSync(vsyncButton.enabled)
		love.window.setFullscreen(fullscreenButton.enabled)
	end)
	Some.WtextButton(SettingsWdow, "Close", Font:getWidth("Save") + 2, SettingsWdow.h - Font:getHeight() * 2, function ()
		SettingsWdow.active = false
		Some:mousemoved(love.mouse.getX(), love.mouse.getY())
	end)
end

function Load_after()
	GenerateMap()
end

LoadStages = {
	Load_pre,
	Load_resources,
	Load_ui,
	Load_windows,
	Load_after,
}
