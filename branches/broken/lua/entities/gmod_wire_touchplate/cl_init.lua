ENT.Type = "anim"
ENT.Base = "base_wire_entity"
ENT.PrintName = "Touch Plate"
ENT.Author = "Asphid_Jackal"
ENT.Contact = "nullonentry"
ENT.Purpose = ""
ENT.Instructions = ""
ENT.Category = "Other"
ENT.Spawnable = false
ENT.AdminSpawnable = false

if not CLIENT then return end

-- get rid of outline
function ENT:Draw()
	self:DrawModel()
end
