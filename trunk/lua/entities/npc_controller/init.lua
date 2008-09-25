AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua' )

local ison = 0

local model = "models/jaanus/wiretool/wiretool_siren.mdl"

ENT.WireDebugName = "Npc Controller"

function ENT:Initialize() 
	self.Entity:SetModel( model ) 	
	self.Entity:PhysicsInit( SOLID_VPHYSICS )     
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )   
	self.Entity:SetSolid( SOLID_VPHYSICS )               
	local phys = self.Entity:GetPhysicsObject()  
		if WireAddon then //Changed this part to conform
			self.Inputs = Wire_CreateInputs(self.Entity, { "X", "Y", "Z", "Go" })
			self.Outputs = Wire_CreateOutputs(self.Entity, { "On"})
		end 
	if (phys:IsValid()) then  		
		phys:Wake()  	
	end 
 
end   

function ENT:TriggerInput( iname, value )
	if ( NPCGPS == nil ) then 
		NPCGPS = {}
		elseif ( iname == "X" ) then
			NPCGPS[1] = value
		elseif ( iname == "Y" ) then
			NPCGPS[2] = value
		elseif ( iname == "Z" ) then
			NPCGPS[3] = value
		elseif ( iname == "Go" ) then
			NPCGPS[4] = value 
			self.ison = value
	end
end

function ENT:Think()
	if ( self.ison == 1 ) then
		self:SetOverlayText( " Npc is moving " )
	else
		self:SetOverlayText( " Npc is idle " )
	end
	if WireAddon then
		Wire_TriggerOutput( self.Entity, "On", self.ison )
	end
end
	




