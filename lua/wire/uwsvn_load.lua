// This gets loaded from Wiremod.
if SERVER then
	-- this file
	AddCSLuaFile("wire/uwsvn_load.lua")
	
	-- shared includes
	AddCSLuaFile("wire/uwsvn/updatecheck.lua")

	-- client includes
	AddCSLuaFile("wire/uwsvn/client/stringtochars.lua")
	AddCSLuaFile("wire/uwsvn/client/welcome_menu_uwsvn_version_check.lua")
end

-- shared includes
include("wire/uwsvn/UpdateCheck.lua")

-- server includes
if SERVER then
	include("wire/uwsvn/server/exitpoint.lua")
	include("wire/uwsvn/server/player_tfextension.lua")
	include("wire/uwsvn/server/sv_radiosystems.lua")
end

-- client includes
if CLIENT then
	include("wire/uwsvn/client/stringtochars.lua")
	include("wire/uwsvn/client/welcome_menu_uwsvn_version_check.lua")
end
