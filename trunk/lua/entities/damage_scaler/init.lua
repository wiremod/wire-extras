//Build Two
//Cleaned
//Fix for multiple scales

//Please pm Hitman271(@yahoo.com) for a way to save wires for the dupe

AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua' )

ENT.WireDebugName = "Damage Scale"

function ENT:Initialize() 
	self.Entity:PhysicsInit( SOLID_VPHYSICS )     
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )   
	self.Entity:SetSolid( SOLID_VPHYSICS )               
	local phys = self.Entity:GetPhysicsObject() 
		
		local outputtypes = { }
		local outputs = { }
		
		local n = 1
		outputs[n] = "Damage"
	
		// Create "Entity" output - must be at the end!

		for i = 1, n do
			outputtypes[i] = "NORMAL"
		end
	
		n = n + 1
		outputs[n] = "Entity"
		outputtypes[n] = "ENTITY"
	
		self.Outputs = WireLib.CreateSpecialOutputs(self.Entity, outputs, outputtypes)

	self.Inputs = Wire_CreateInputs(self.Entity, { "On", "Refresh" })	

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
		Wire_TriggerOutput(self.Entity, "Damage", self.Damage)			
		Wire_TriggerOutput( self.Entity, "Entity", self.Enti )	
		self:SetOverlayText( "The Damage Is "..self.Damage )
		
			if ( self.Damage > 0 ) then
				self.Damage = 0 			
					if ( self.Refresh >= 0 )	then	
						self.Entity:NextThink( CurTime() + self.Refresh + 0.01 )
						return true
					end						
			end 
	
	else
		self:SetOverlayText( " Scale Is Off " )
	end
end

//Added to on down from here
function ENT:OnRemove()
    Wire_Remove(self.Entity)
end

function ENT:OnRestore()
    Wire_Restored(self.Entity)
end

function ENT:BuildDupeInfo()
    return WireLib.BuildDupeInfo(self.Entity)
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
    WireLib.ApplyDupeInfo( ply, ent, info, GetEntByID )
end



