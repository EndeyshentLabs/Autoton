Locales = {
	"en_US",
	"ru_RU",
}

CurrentLocaleIndex = 1

-- Stub locale
CurrentLocale = {
	oreIron = "oreIron",
	oreGold = "oreGold",
	cellMinerName = "cellMinerName",
	cellMinerDesc = "cellMinerDesc",
	cellConveyorName = "cellConveyorName",
	cellConveyorDesc = "cellConveyorDesc",
	cellJunctionName = "cellJunctionName",
	cellJunctionDesc = "cellJunctionDesc",
	cellStorageName = "cellStorageName",
	cellStorageDesc = "cellStorageDesc",
	cellCoreName = "cellCoreName",
	cellCoreDesc = "cellCoreDesc",

	settingWindowTitle = "settingWindowTitle",
	vsync = "vsync",
	fullscreen = "fullscreen",
	language = "language",
	requiresRestart = "requiresRestart",
	save = "save",
	close = "close",
}

LocaleFilename = "CurrentLocale"

function SaveLocale()
	local ok, err = love.filesystem.write(LocaleFilename, tostring(CurrentLocaleIndex))

	if not ok then
		error("Couldn't save locale: " .. err)
	end
end

---@return boolean success
function LoadLocale()
	if love.filesystem.getInfo(LocaleFilename) then
		local contents, err = love.filesystem.read(LocaleFilename)

		if contents == nil and err then
			error("Couldn't load saved locale: " .. err)
		end

		local savedLocale = tonumber(contents)

		if savedLocale < 1 or savedLocale > #Locales then
			error("Couldn't load saved locale: invalid locale '" .. contents .. "'")
		end

		CurrentLocaleIndex = savedLocale
		return true
	else
		return false
	end
end
