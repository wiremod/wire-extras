AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

function ENT:SpawnFunction( ply, tr )
	if ( !tr.Hit ) then return end
	local SpawnPos = tr.HitPos + tr.HitNormal * 1
	local ent = ents.Create( "gmod_wire_ramcard_default024" )
	ent:SetPos( SpawnPos )
	ent:SetOwner( ply )
	ent:Spawn()
	ent:Activate()
	return ent
end

function ENT:Initialize()
	self.Size = 24
	self.SizePrint = "24 Values"
	
	self:SetupBase()
end
