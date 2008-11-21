/*******************************
	Wired RT Camera
	  for Wiremod
	  
	(C) Sebastian J.
********************************/

ENT.Type = "anim"
ENT.Base = "base_wire_entity"

ENT.PrintName		= ""
ENT.Author			= ""
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""

ENT.Spawnable			= false
ENT.AdminSpawnable		= false

function ENT:TrackEntity( ent, lpos )

	if ( !ent || !ent:IsValid() ) then return end

	local WPos = self.TrackEnt:LocalToWorld( lpos )
	
	if ( ent:IsPlayer() ) then
		WPos = WPos + Vector( 0, 0, 54 )
	end
	
	local CamPos = self:GetPos()
	local Ang = WPos - CamPos
	
	Ang = Ang:Angle()
	self:SetAngles(Ang)

end

function ENT:CanTool( ply, trace, mode )

	if (self:GetMoveType() == MOVETYPE_NONE) then return false end
	
	return true

end
