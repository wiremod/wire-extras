Msg("EGP v2 Beta Installed & Loading\n")

--Need A Main Addon Table! (NEATNES!)
if not EGP then EGP = {} end

--User Message Tables!
if not EGP.USM then EGP.USM = {} end

--Includes for the basics!
if CLIENT then include("EGP/EGP_Client.lua") end

if SERVER then
	include("EGP/EGP_Server.lua")
	AddCSLuaFile("EGP/EGP_Client.lua")
	AddCSLuaFile("EGP/EGP_Shared.lua")
end

--Valid Fonts
EGP.ValidFonts = {}
EGP.ValidFonts[1] = "coolvetica"
EGP.ValidFonts[2] = "arial"
EGP.ValidFonts[3] = "lucida console"
EGP.ValidFonts[4] = "trebuchet"
EGP.ValidFonts[5] = "courier new"
EGP.ValidFonts[6] = "times new roman"

--Finaly Loaded
for k,_ in pairs(EGP.USM) do
	Msg("EGP: usm layout added " .. k .. "\n")
end

if CLIENT then
	for k,_ in pairs(EGP.ELEMENT) do
		Msg("EGP: element added " .. k.. "\n")
	end
end
--