ENT.Base = "base_ai" 
ENT.Type = "ai"

ENT.PrintName		= ""
ENT.Author			= ""

ENT.Contact			= ""  
ENT.Purpose			= ""
ENT.Instructions		= ""
ENT.Category			= ""

ENT.Spawnable			= "false"
ENT.AdminSpawnable		= "false"

ENT.AutomaticFrameAdvance = true

function ENT:OnRemove()
end

function ENT:PhysicsCollide( data, physobj )
end

function ENT:PhysicsUpdate( physobj )
end

function ENT:SetAutomaticFrameAdvance( bUsingAnim )

	self.AutomaticFrameAdvance = bUsingAnim

end
