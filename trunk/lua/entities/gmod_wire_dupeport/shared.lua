ENT.Type = "anim"
ENT.Base = "base_wire_entity"
ENT.PrintName = "Dupe Teleport"
ENT.Author = "Free Fall"

ENT.Spawnable = false
ENT.AdminSpawnable = false

function ENT:SetBeamLength(length)
	self.Entity:SetNetworkedFloat("BeamLength", length)
end

function ENT:GetBeamLength()
	return self.Entity:GetNetworkedFloat("BeamLength") or 0
end