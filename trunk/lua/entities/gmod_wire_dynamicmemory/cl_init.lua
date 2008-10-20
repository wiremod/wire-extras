/*******************************
	Dynamic Memory Gate
	  for Wiremod
	  
	(C) Sebastian J.
********************************/

include('shared.lua')

ENT.Spawnable			= false
ENT.AdminSpawnable		= false
ENT.RenderGroup 		= RENDERGROUP_BOTH

function ENT:Initialize()
end

function ENT:OnRemove()
end

function ENT:Draw()
	self:DrawModel()
	Wire_Render(self)
end

function ENT:IsTranslucent()
	return false
end

function ENT:Think()
end

function ENT:GetOverlayText()
	return "Dynamic Memory (".. self:GetNWString("size") ..")"	
end
