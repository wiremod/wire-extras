
include('shared.lua')

ENT.RenderGroup 		= RENDERGROUP_OPAQUE

function ENT:Draw()
	self.BaseClass.Draw(self)

	local target = self:GetLinkedTargetFinder()
	if (target) and (target:IsValid()) and (LocalPlayer():GetEyeTrace().Entity == self.Entity) and (EyePos():Distance(self.Entity:GetPos()) < 4096) then
	    local start = self.Entity:GetPos()
		local endpos = target:GetPos()
		local scroll = -3*CurTime()

		render.SetMaterial(Material("cable/physbeam"))
	    render.DrawBeam(start, endpos, 8, scroll, (endpos-start):Length()/10+scroll, Color(255, 255, 255, 192))
	end
end