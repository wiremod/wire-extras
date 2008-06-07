
include('shared.lua')

ENT.RenderGroup 		= RENDERGROUP_BOTH


function ENT:Draw()
	self.BaseClass.Draw(self)
	local vStart = self.Entity:GetPos()
	local vForward = self.Entity:GetUp()
	local vEnd = vStart + (vForward * self:GetBeamRange())

	local bbmin, bbmax = self.Entity:GetRenderBounds()
	local lspos = self.Entity:WorldToLocal(vStart)
	local lepos = self.Entity:WorldToLocal(vEnd)
	if (lspos.x < bbmin.x) then bbmin.x = lspos.x end
	if (lspos.y < bbmin.y) then bbmin.y = lspos.y end
	if (lspos.z < bbmin.z) then bbmin.z = lspos.z end
	if (lspos.x > bbmax.x) then bbmax.x = lspos.x end
	if (lspos.y > bbmax.y) then bbmax.y = lspos.y end
	if (lspos.z > bbmax.z) then bbmax.z = lspos.z end
	if (lepos.x < bbmin.x) then bbmin.x = lepos.x end
	if (lepos.y < bbmin.y) then bbmin.y = lepos.y end
	if (lepos.z < bbmin.z) then bbmin.z = lepos.z end
	if (lepos.x > bbmax.x) then bbmax.x = lepos.x end
	if (lepos.y > bbmax.y) then bbmax.y = lepos.y end
	if (lepos.z > bbmax.z) then bbmax.z = lepos.z end
	self.Entity:SetRenderBounds(bbmin, bbmax, Vector()*6)

    local trace = {
		start = vStart,
		endpos = vEnd,
		filter = { self.Entity },
		}
	local trace = util.TraceLine( trace )

	local endpos
	if(trace.Hit)then
	   endpos = trace.HitPos
	else
	   endpos = vEnd
	end
	render.SetMaterial(Material("tripmine_laser"))
	render.DrawBeam(vStart, endpos, 6, 0, 10, Color(self.Entity:GetColor()))
end

function ENT:Think()
end
