
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
function ENT:Think()
	if self:IsOn()==true then 
		--print(tostring(self:GetLength()))
		local entsTA=ents.FindInSphere(self:GetPos(),self:GetLength())
		local myPos=self:GetPos()
		for k,ent in pairs(entsTA) do
			if ent:IsValid() and ent!=self and ent:GetModel()!=nil and ent:GetModel()!="" then
				//model
				if self:GetPropFilter()==nil or self:GetPropFilter()=="" or (self:GetPropFilter()!="" and string.find( string.lower( ent:GetModel() ),self:GetPropFilter())!=nil) then//(self:IsTargetOnlyMetal()==false) or (self:IsTargetOnlyMetal()==true and tr.MatType != MAT_METAL Stuff not done yet
					local phys = ent:GetPhysicsObject(); 
					if phys:IsValid() then
						
						
						--[[local tdata={}
						tdata.start=myPos
						tdata.endpos=ent:GetPos()
						local tr=util.TraceLine(tdata)]]
						local direction = ent:GetPos()-myPos
						local dist=math.sqrt(((ent:GetPos().x-myPos.x)^2)+((ent:GetPos().y-myPos.y)^2)+((ent:GetPos().z-myPos.z)^2))
						
						dist=dist/self:GetLength()
						dist=math.abs(dist-1)
						if self:IsBackwards()==true then dist=-dist end
						
						direction:Normalize()
						direction = direction*(1*-(self.Strength*dist))
						phys:ApplyForceCenter(direction)
						
						
						
						phys:Wake()
					end
				end
			end
			
		end
	end
	
	//WHY DOESNT THE OVERLAY WORK?!?
	/*if self.LastOverlayUpdate+self.OverlayUpdateRate<CurTime() then
		self:ShowOutput()
		self.LastOverlayUpdate=CurTime()
	end*/
	self:NextThink( CurTime() +  self.CachedTickRate) 
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
	
	local ontxt="Off"
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
