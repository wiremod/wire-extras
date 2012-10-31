
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Simple Servo"

/*---------------------------------------------------------
   Name: Initialize
   Desc: First function called. Use to set up your entity
---------------------------------------------------------*/
function ENT:Initialize()

	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetUseType( SIMPLE_USE )
	
    self.Inputs = Wire_CreateInputs(self, { "Angle", "Speed" })
	
	self.Angle = 0
	self.Speed = 0
	
end

/*---------------------------------------------------------
   Name: TriggerInput
   Desc: the inputs
---------------------------------------------------------*/
function ENT:TriggerInput(iname, value)
	if (iname == "Angle") then
	   self.Angle = value%360;
	elseif (iname == "Speed") then
	   if(value>=0&&value<360)then
	       self.Speed = value
	   end
	end
	return true
end

function ENT:Think()
    self.BaseClass:Think()
    
    local Angles = {};
    Angles = self:GetAngles()
    
    local finalAngle = 0
    
    if(Angles.y != self.Angle)then
        if(Angles.y < self.Angle)then
            if((self.Angle-Angles.y < self.Speed)||(self.Speed == 0))then
                finalAngle = self.Angle
            else
                finalAngle = Angles.y+self.Speed
            end
        else
            if((Angles.y-self.Angle < self.Speed)||(self.Speed == 0))then
                finalAngle = self.Angle
            else
                finalAngle = Angles.y-self.Speed
            end
        end
        self:SetAngles(Angle(Angles.p,finalAngle,Angles.r))
    end
    self:NextThink(CurTime())
	return true
end
