AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include( "shared.lua" )

local MODEL = Model( "models/jaanus/wiretool/wiretool_siren.mdl" )
function ENT:Initialize()
	self:SetModel( MODEL )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Inputs = Wire_CreateInputs( self, { "Percent" } )
	self.Outputs = Wire_CreateOutputs( self, { "Percent" } )
	
	self.Trigger = 0
	
	self.Percent = 0
	self.Entities = {}
end

function ENT:TriggerInput( name, val )
	if ( name == "Percent" ) then
		self:SetPercent( val )
	end
end

local function SetBuoyancy( ent, percent )
	local phys = ent:GetPhysicsObject()
	if ( !phys:IsValid() ) then return end
	phys:SetBuoyancyRatio( percent / 100 )
	phys:Wake()
end

function ENT:AddEntity( ent )
	self.Entities[ ent ] = true
	self:SetPercent()
end
function ENT:RemoveEntity( ent )
	SetBuoyancy( ent, 0 )
	self.Entities[ ent ] = nil
end

function ENT:SetPercent( val )
	self.Percent = math.Clamp( val or self.Percent, -1000, 1000 )
	self:SetOverlayText( "Buoyancy: " .. self.Percent .. "%" )
	
	for ent, _ in pairs( self.Entities ) do
		if ( IsValid( ent ) ) then
			SetBuoyancy( ent, self.Percent )
		else
			self.Entities[ ent ] = nil
		end
	end
end

function ENT:OnRemove()
	for ent, _ in pairs( self.Entities ) do
		if ( IsValid( ent ) ) then
			self:RemoveEntity( ent )
		end
	end
end

// Support for duping.
function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}
		info.Entities = {}
		for ent, _ in pairs( self.Entities ) do info.Entities[ #info.Entities + 1 ] = ent:EntIndex() end
	return info
end
function ENT:ApplyDupeInfo( ply, ent, info, GetEntByID )
	self.BaseClass.ApplyDupeInfo( self, ply, ent, info, GetEntByID )
	if ( info.Entities ) then
		for _, index in pairs( info.Entities ) do
			local ent = GetEntByID( index ) or ents.GetByIndex( index )
			if ( IsValid( ent ) ) then
				self:AddEntity( ent )
			end
		end
	end
end
