local path = "entities/gmod_wire_egp/lib/"

Msg("EGP Lib Loading:\n")
include(path.."Lib.lua")

if SERVER then
	AddCSLuaFile("autorun/egp.lua")
	AddCSLuaFile(path.."Lib.lua")
	AddCSLuaFile(path.."Usm.lua")
	AddCSLuaFile(path.."Element.lua")
end

Msg("Adding USM Layouts:\n")
include(path.."Usm.lua")

if CLIENT then
	Msg("Adding Cl Elements:\n")
	include(path.."Element.lua")
end

Msg("EGP Lib Loaded!\n") 
