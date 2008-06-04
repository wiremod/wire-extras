
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')
ENT.WireDebugName = "Servo"
ENT.OverlayDelay = 0.1

function ENT:Initialize()
		
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Inputs = Wire_CreateInputs(self.Entity,{"Yaw", "Pitch", "Roll"})
	self.Entity:SetGravity(0)
	
	self.Yaw = 0
	self.Pitch = 0
	self.Roll = 0
	self.CanRotate = 1
	self.NextTime = 0
	self.Priority = "yaw" // Only necessary if single axis forced.... code for that is commented out
	self.ShouldLimit = 0 // Not quite sure how to do convar implementation to make a checkbox for this, so.. i'll leave it in...	
	
end

function ENT:TriggerInput(iname,value) 
	
		if (self.CanRotate == 0 && self.ShouldLimit == 1) then return true end // Waits for CanRotate to == 1 before rotates
	
		local phys = self.Entity:GetPhysicsObject()
		local ent1 = self.Const:GetTable().Ent1
		local ent2 = self.Const:GetTable().Ent2	
		local bone1 = self.Const:GetTable().Bone1
		local bone2 = self.Const:GetTable().Bone2
		local myAng = ent2:GetAngles()
		
		self.Entity:ForgetTheWeld(self.Entity)
		if (self.Const != NULL) then self.Const:Remove() self.Const = NULL end
		
		if (iname == "Yaw") then
		
			self.Yaw = value
			self.Priority = "yaw"
			
		
		elseif (iname == "Pitch") then
		
			self.Pitch = value
			self.Priority = "pitch"
		
		elseif (iname == "Roll") then
		
			self.Roll = value
			self.Priority = "roll"
			
		end
		
		//########################Rotation code goes here, finally
		
		if (self.ShouldLimit==1) then
			if (self.Priority == "yaw") then myAng:RotateAroundAxis( ent2:GetUp(), self.Yaw )
			elseif (self.Priority == "pitch") then myAng:RotateAroundAxis( ent2:GetRight(), self.Pitch )
			elseif (self.Priority == "roll") then myAng:RotateAroundAxis( ent2:GetForward(), self.Roll )
			end
		else
			myAng:RotateAroundAxis( ent2:GetUp(), self.Yaw )
			myAng:RotateAroundAxis( ent2:GetRight(), self.Pitch )
			myAng:RotateAroundAxis( ent2:GetForward(), self.Roll )
		end
				
		self.Entity:SetAngles(myAng)
				
		self.Const = constraint.Weld(ent1, ent2, bone1, bone2, 0, 1, 0)
			
		phys:Wake()
		
		//######################## End rotation code
		
		self.CanRotate = 0 // Don't allow rotation until the next cycle comes
		
		
    return true
	
	
end

function ENT:SetPhysicsCollisions( Ent, b ) 
   
 	if (!Ent || !Ent:IsValid() || !Ent:GetPhysicsObject()) then return end 
 	 
 	Ent:GetPhysicsObject():EnableCollisions( b ) 
   
 end

function ENT:SendObjects (const, ent)

	self.Const = const //This works, self.Const is indeed an entity....
						// Now, the million fucking dollar question is how to break the weld and reweld it every time the pitch/yaw/roll update...
	self.Other = ent // This is so we can do the next thing...

end

function ENT:Think()

	self.BaseClass.Think(self)
	
	if (self.ShouldLimit == 1) then
		if (CurTime() < self.NextTime) then return end
		self.CanRotate = 1
		self.NextTime = CurTime() + .05 // This can be adjusted to update more quickly and smoothly... none of the rotational math at all will be performed until this is met
	end
	
end

 function ENT:ForgetTheWeld( ent ) //This should blast away the constraint, little fucker... goes through constraint.Find and STOPS IT FROM RETURNING FALSE
									// I'm pretty sure what I'm trying to do above happens before the constraint table gets refreshed...
 	if ( !ent:GetTable().Constraints ) then return end 
	
	local OTab = self.Const:GetTable()
	local blank = {}
   
	for k, v in pairs( ent:GetTable().Constraints ) do 
	 
		if ( v:IsValid() ) then 
		
			local CTab = v:GetTable()
 	 
 			if ( CTab.Type == OTab.Type && CTab.Ent1 == OTab.Ent1 && CTab.Ent2 == OTab.Ent2 && CTab.Bone1 == OTab.Bone1 && CTab.Bone2 == OTab.Bone2 ) then 
 				v:SetTable(blank)
 			end 
 			 
 			if ( CTab.Type == OTab.Type && CTab.Ent2 == OTab.Ent1 && CTab.Ent1 == OTab.Ent2 && CTab.Bone2 == OTab.Bone1 && CTab.Bone1 == OTab.Bone2 ) then 
 				v:SetTable(blank)
 			end 
   
 		end 
 	end 
   
 end
