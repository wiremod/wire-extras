
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

ENT.WireDebugName = "Freezer"

include('shared.lua')

local MODEL = Model("models/jaanus/wiretool/wiretool_siren.mdl")


function ENT:Initialize()
	self.Entity:SetModel( MODEL )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )

	self.Inputs = Wire_CreateInputs( self.Entity, { "Activate" } )	
	
	self:SetOverlayText( "Wire Freezer - Activated" )
	
end

function ENT:SendVars( Ent1 )

	self.Ent1 = Ent1

end

function ENT:TriggerInput(iname, value)

	if (iname == "Activate") then
	
		if ( value == 0  ) then
		
		self.Ent1:GetPhysicsObject():EnableMotion( true )
		//self.Ent1:GetPhysicsObject():SetUnFreezable( false )
		self.Ent1:GetPhysicsObject():Wake()
			
		self:SetOverlayText( "Weld Freezer - Deactivated" )
			
		end
		
		if ( value == 1 ) then
		

		self.Ent1:GetPhysicsObject():EnableMotion( false )
		//self.Ent1:GetPhysicsObject():SetUnFreezable( true )
		self:SetOverlayText( "Weld Freezer - Activated" )
			
		end
		
	end
	
end

function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}
	if (self.Ent1) and (self.Ent1:IsValid()) then
		info.Ent1 = self.Ent1:EntIndex()
	end
	return info
end 

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)
	if (info.Ent1) then
		self.Ent1 = GetEntByID(info.Ent1)
		if (!self.Ent1) then
			self.Ent1 = ents.GetByIndex(info.Ent1)
		end
	end
	self:TriggerInput("Activate", self.Inputs.Activate.Value)
end
 