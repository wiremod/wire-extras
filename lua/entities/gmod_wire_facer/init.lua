
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')
ENT.WireDebugName = "Facer"
ENT.OverlayDelay = 0.1

function ENT:Initialize()
		
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Inputs = Wire_CreateInputs(self.Entity,{"X", "Y", "Z", "On"})
	self.Entity:SetGravity(0)
	
	self.Xp = 0
	self.Yp = 0
	self.Zp = 0
	self.On = 0
	self.NextTime = 0
end

function ENT:TriggerInput(iname,value) 
		local phys = self.Entity:GetPhysicsObject()
		if (iname == "X") then
		
			self.Xp = value
			
		elseif (iname == "Y") then
		
			self.Yp = value
			
		elseif (iname == "Z") then
		
			self.Zp = value

		elseif (iname == "On") then
		
			self.On = value
			
		end
		
		if (self.On == 1) then
		
		//########################Rotation code goes here, finally
		self.LastPosition = self.Entity:GetPos()
		self.Target = Vector(self.Xp, self.Yp, self.Zp)
		AimVec = ( self.Target - self.LastPosition ):Angle()				
		self.Entity:SetAngles(AimVec)
		phys:Wake()
		//######################## End rotation code
				
		end
    return true
	
	
end

function ENT:SetPhysicsCollisions( Ent, b ) 
   
 	if (!Ent || !Ent:IsValid() || !Ent:GetPhysicsObject()) then return end 
 	 
 	Ent:GetPhysicsObject():EnableCollisions( b ) 
   
 end

function ENT:SendObjects (const, ent)

end

function ENT:Think()	
end
