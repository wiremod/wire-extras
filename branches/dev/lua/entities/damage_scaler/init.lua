//Build Two
//Cleaned
//Fix for multiple scales

//Thanks to ZeitJT for the dupe help!

AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua' )

ENT.WireDebugName = "Damage Scale"

function ENT:Initialize() 
	self:PhysicsInit( SOLID_VPHYSICS )     
	self:SetMoveType( MOVETYPE_VPHYSICS )   
	self:SetSolid( SOLID_VPHYSICS )               
	local phys = self:GetPhysicsObject() 

	self.Outputs = WireLib.CreateSpecialOutputs(self, { "Damage", "Entity" } , { "NORMAL", "ENTITY" } )

	self.Inputs = Wire_CreateInputs(self, { "On", "Refresh" })	

	if (phys:IsValid()) then  		
		phys:Wake()  	
	end 
	
	self.Damage = 271
	self.On = 1
	self.Refresh = 0
end

function ENT:TriggerInput(iname, value)
	if (iname == "On") then
		self.On = value
	elseif (iname == "Refresh") then
		self.Refresh = value
	end
end

function ENT:OnTakeDamage(dmginfo)
	if (self.On != 0) then
		self.Damage = dmginfo:GetDamage()
		self.Enti = dmginfo:GetAttacker()
	else
		self.Damage = 0
	end
end

function ENT:Think()
	if ( self.On != 0 ) then
		Wire_TriggerOutput(self, "Damage", self.Damage)			
		Wire_TriggerOutput( self, "Entity", self.Enti )	
		self:SetOverlayText( "The Damage Is "..self.Damage )
		
			if ( self.Damage > 0 ) then
				self.Damage = 0 			
					if ( self.Refresh >= 0 )	then	
						self:NextThink( CurTime() + self.Refresh + 0.01 )
						return true
					end						
			end 
	
	else
		self:SetOverlayText( " Scale Is Off " )
	end
end

function ENT:BuildDupeInfo()
return self.BaseClass.BuildDupeInfo(self) or {}  //Fetches most data
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)  // Applies the generic data we gathered earlier
end



