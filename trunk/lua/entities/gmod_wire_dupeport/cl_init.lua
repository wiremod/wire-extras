include("shared.lua")
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:Draw()
	self.BaseClass.Draw(self)
	Wire_DrawTracerBeam( self, 1 )
end
