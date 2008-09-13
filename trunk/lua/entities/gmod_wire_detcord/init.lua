AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Detonation Cord"
ENT.OverlayDelay = 0

/*---------------------------------------------------------
   Name: Initialize
   Desc: First function called. Use to set up your entity
---------------------------------------------------------*/
function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	
	local phys = self.Entity:GetPhysicsObject()
	if phys:IsValid() then phys:Wake() end
	self.isDetcord = true
	
	self.Inputs = Wire_CreateInputs(self.Entity, {"Detonate"})
end

/*---------------------------------------------------------
   Name: TriggerInput
   Desc: the inputs
---------------------------------------------------------*/
function ENT:TriggerInput(iname, value)
	if iname == "Detonate" and value ~= 0 then
		self:Detonate()
	end
end

/*---------------------------------------------------------
   Name: Setup
   Desc: does not a whole lot of setting up
---------------------------------------------------------*/
function ENT:Setup()
	-- Random Color Detcord
	local color = {255, 255, 255}
	for k=1,3 do
		if math.random(0, 1) == 1 then color[k] = 0 end
	end
	self:SetColor(color[1], color[2], color[3], 255)
end

/*---------------------------------------------------------
   Name: Think
   Desc: Thinks :P
---------------------------------------------------------*/
function ENT:Think()
	self.BaseClass.Think(self)
	
	self.Entity:NextThink(CurTime() + 0.05)
	return true
end

/*---------------------------------------------------------
   Name: SetRange
   Desc: Sets the radius of effect
---------------------------------------------------------*/
function ENT:SetRange(range)
	if range < 0 then range = 0 end
	if range > 200 then range = 200 end
	self.range = range
end

/*---------------------------------------------------------
   Name: CleanDebris
   Desc: Remove the Crap
---------------------------------------------------------*/
local function CleanDebris(e)
	if not ValidEntity(e) then return end
        e:Remove()
end

/*---------------------------------------------------------
   Name: Detonate
   Desc: Trigger the detcord
---------------------------------------------------------*/
function ENT:Detonate()
	local en = ents.FindInSphere(self:GetPos(), self.range)

	local effectdata = EffectData()
        effectdata:SetOrigin( self.Entity:GetPos() )
        util.Effect( "Explosion", effectdata, true, true )
	
	for k,v in pairs(en) do
		if v:IsPlayer() then
			v:TakeDamage(30, self, self)
		end

		if not v.isDetcord and not v.going and v:GetClass() == "prop_physics" then
			v.going = true
			v:Fire("enablemotion","",0)
			constraint.RemoveAll(v)
			timer.Simple(math.random(8, 15), CleanDebris, v)
		end
	end
	self:Remove()
end
