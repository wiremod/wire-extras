include('shared.lua')

ENT.RenderGroup 		= RENDERGROUP_BOTH

function ENT:Draw()

self.Entity:DrawModel()

end
