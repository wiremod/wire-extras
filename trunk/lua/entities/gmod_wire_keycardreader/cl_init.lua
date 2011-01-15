
include('shared.lua')

ENT.RenderGroup 		= RENDERGROUP_BOTH

function ENT:Initialize()
	mx, mn = self:GetRenderBounds()
	self:SetRenderBounds( mn + Vector(0,0,128), mx, 0 )
end

function ENT:Draw()
    self.BaseClass.Draw(self)
    if (self:GetReadMode() == 0) then
        local vStart = self:GetPos()
        local vForward = self:GetUp()
	
        local trace = {}
            trace.start = vStart
            trace.endpos = vStart + (vForward * self:GetRange())
            trace.filter = { self }
        local trace = util.TraceLine( trace ) 

        local endpos
        if (trace.Hit) then
            endpos = trace.HitPos
        else
            endpos = vStart + (vForward * self:GetRange())
        end
            
        render.SetMaterial(Material("tripmine_laser"))
        render.DrawBeam(vStart, endpos, 6, 0, 10, Color(self:GetColor()))
    end
    Wire_Render(self)
end