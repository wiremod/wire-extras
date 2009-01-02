-- RP Money Detector by philxyz

AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Money Detector"
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

	-- Default range
	self.range = 50
	
	self.Inputs = Wire_CreateInputs(self.Entity, {"Range"})
	self.Outputs = Wire_CreateOutputs(self.Entity, {"Amount"})
end

/*---------------------------------------------------------
   Name: TriggerInput
   Desc: the inputs
---------------------------------------------------------*/
function ENT:TriggerInput(iname, value)
	if iname == "Range" and value > 0 and value <= 500 then
		self.range = value
	end
end

/*---------------------------------------------------------
   Name: Think
   Desc: Thinks :P
---------------------------------------------------------*/
function ENT:Think()
	self.BaseClass.Think(self)

	local en = ents.FindInSphere(self:GetPos(), self.range)
	local total = 0
	for k, v in pairs(en) do
		if v.GetTable and v:GetTable().MoneyBag and v:GetTable().Amount then
			total = total + v:GetTable().Amount
		end
	end
	Wire_TriggerOutput(self.Entity, "Amount", total)
	
	self.Entity:NextThink(CurTime() + 2)
	return true
end
