AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

function ENT:SpawnFunction( ply, tr )
	if ( !tr.Hit ) then return end
	local SpawnPos = tr.HitPos + tr.HitNormal * 1
	local ent = ents.Create( "gmod_wire_ramcard_proxy32" )
	ent:SetPos( SpawnPos )
	ent:Spawn()
	ent:SetCardOwner( ply )
	ent:Activate()
	return ent
end

function ENT:Initialize()
	self.Size = 32768
	self.SizePrint = "32KB"
	self.MaxDist = 100
	
	self:SetupBase()
end
