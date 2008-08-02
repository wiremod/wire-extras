AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua' )

local ison = 0

local model = "models/jaanus/wiretool/wiretool_siren.mdl"

function ENT:Initialize() 
	self.Entity:SetModel( model ) 	
	self.Entity:PhysicsInit( SOLID_VPHYSICS )     
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )   
	self.Entity:SetSolid( SOLID_VPHYSICS )               
	local phys = self.Entity:GetPhysicsObject()  
		if not (WireAddon == nil) then self.Inputs = Wire_CreateInputs(self.Entity, { "X", "Y", "GO" }) end	
	    	if not (WireAddon == nil) then self.Outputs = Wire_CreateOutputs(self.Entity, { "On"}) end
	if (phys:IsValid()) then  		
		phys:Wake()  	
	end 
 
end   

function ENT:TriggerInput( iname, value ) 
	if ( iname == "X" ) then
		local X = value
	end
	if ( iname == "Y" ) then
		local Y = value
	end
	if ( iname == "GO" ) then
		local GO = value
		self.ison = value
	end
	SendVars( X, Y, GO )
end

function SendVars( X, Y, GO )// This has to be routed somehow
	Npc_C_271 = {} // Just a custom variable to be sure of no duplicates
	local m = Npc_C_271
	m.X = X
	m.Y = Y
	m.GO = GO
	Npc_C_271 = m
end

function ENT:Think()
	if ( self.ison == 1 ) then
		self:SetOverlayText( " Npc is moving " )
	else
		self:SetOverlayText( " Npc is idle " )
	end
	if not ( WireAddon == nil ) then Wire_TriggerOutput( self.Entity, "On", self.ison ) end
end
	




