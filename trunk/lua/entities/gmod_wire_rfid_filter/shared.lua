

ENT.Type 			= "anim"
ENT.Base 			= "base_wire_entity"

ENT.PrintName		= ""
ENT.Author			= ""
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""

ENT.Spawnable			= false
ENT.AdminSpawnable		= false


function ENT:SetLinkedTargetFinder(tf)
	self.Entity:SetNetworkedEntity("LinkedTargetFinder", tf)
end

function ENT:GetLinkedTargetFinder()
	return self.Entity:GetNetworkedEntity("LinkedTargetFinder")
end