function love.conf(t)
	t.title = "Autoton. EndeyshentLabs (C), 2023"
	t.console = true
	t.version = "11.3"

	t.window.width = 800
	t.window.height = 600
	t.window.resizable = true
	t.window.fullscreen = false
	t.window.minwidth = 640
	t.window.minheight = 480
	t.window.highdpi = true
	t.window.vsync = false

	t.modules.joystick = false
	t.modules.touch = false
end
