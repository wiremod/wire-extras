ENT.Type			= "anim"
ENT.Base			= "base_wire_entity"

if not WireVersion then
	timer.Simple(0, function(ENT) if not WireVersion then ENT.Base = "base_gmodentity" end end)
end

ENT.PrintName		= "Keypad"
ENT.Author			= "Robbis_1 (Killer HAHA) and TomyLobo"
ENT.Contact			= "Robbis_1 and TomyLobo at Facepunch Studios"
ENT.Purpose			= ""
ENT.Instructions	= ""

ENT.Spawnable		= false
ENT.AdminSpawnable	= false
