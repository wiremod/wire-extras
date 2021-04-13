
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')
ENT.OverlayUpdateRate=2
ENT.LastOverlayUpdate=1
ENT.WireDebugName = "Magnet"

function ENT:Initialize()
	--self:SetModel("models/props_junk/gascan001a.mdl")
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self.Inputs = Wire_CreateInputs(self, { "On", "Strength", "Effect length" })
	
	self.TargetPlayers = false
	
	--self:SetBeamLength(2048)
	--self:ShowOutput()
	self:SetOn(false)
	self:TriggerInput("On", 0)
	self:ShowOutput()
end

function ENT:OnRemove()
	Wire_Remove(self)
end

function ENT:Setup(mdl,trgmetal,str,leng,mdlfilter)
	self:SetModel(mdl)
    self:SetPropFilter(mdlfilter)
	self:SetTargetOnlyMetal(trgmetal)
	self:SetStrength(str)
    self:SetLength(leng)
	
end

function ENT:CheckFilter(ent, phys)
	local filter = self:GetPropFilter()
	if filter and filter ~= "" and not string.find(string.lower(ent:GetModel() or ""), filter) then
		return false
	end
	if self:IsTargetOnlyMetal() and not string.find(string.lower(phys:GetMaterial()), "metal") then
		return false
	end
	return true
end

function ENT:Think()
	if self:IsOn() then 
		local myPos=self:GetPos()
		local entsTA=ents.FindInSphere(myPos,self:GetLength())
		for k, ent in pairs(entsTA) do
			local phys = ent:GetPhysicsObject()
			if phys:IsValid() and ent:IsValid() and ent!=self and self:CheckFilter(ent, phys) then
				local direction = ent:GetPos() - myPos
				local dist = math.max(direction:Length(), 1e-6)

				local strength = self.Strength*math.abs(dist/self:GetLength() - 1)
				if not self:IsBackwards() then strength = -strength end

				phys:ApplyForceCenter(direction*(strength/dist))
			end
		end
	end

	self:NextThink(CurTime() + self.CachedTickRate) 
	return true
end

function ENT:TriggerInput(iname, value)
	self.CachedTickRate=GetConVarNumber("sbox_wire_magnets_tickrate")
	if (iname == "On") then
		if (value > 0) then
			self:SetOn(true)
		else
			self:SetOn(false)
		end
		self:ShowOutput()
	else
	   if(iname == "Strength") then
			
	       self:SetStrength(value)
	       self:ShowOutput()
	   end
	   if(iname == "Effect length") then
	       self:SetLength(value)
	       self:ShowOutput()
	   end
	end
end



function ENT:ShowOutput()
	//set overlay
	if self:IsOn()==true then ontxt="On" end
	self:SetOverlayText(
		"Wire Magnet"
	)
end

function ENT:OnRestore()
    Wire_Restored(self)
end
function ENT:SpawnFunction( ply, tr)

	if ( !tr.Hit ) then return end
	
	local SpawnPos = tr.HitPos + tr.HitNormal * 16
	
	local ent = ents.Create( "gmod_wire_realmagnet" )
		ent:SetPos( SpawnPos )

	ent:Spawn()
	ent:Activate()
	
	return ent

end
