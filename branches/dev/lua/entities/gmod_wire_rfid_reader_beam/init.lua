
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "RFID Beam Reader"

local MODEL = Model("models/jaanus/wiretool/wiretool_range.mdl")

function ENT:Initialize()
	self:SetModel( MODEL )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self.Outputs = Wire_CreateOutputs(self, { "State", "A", "B", "C", "D" })
	self:SetBeamLength(2048)
	self.A=0
	self.B=0
	self.C=0
	self.D=0
	self.State=0
	self.NoColorChg=false
	Wire_TriggerOutput(self,"State",0)
	Wire_TriggerOutput(self,"A",0)
	Wire_TriggerOutput(self,"B",0)
	Wire_TriggerOutput(self,"C",0)
	Wire_TriggerOutput(self,"D",0)
	self:ShowOutput()
end

function ENT:OnRemove()
	Wire_Remove(self)
end

function ENT:Setup(Range,col)
    self:SetBeamLength(Range)
	self.NoColorChg=col
end

function ENT:Think()
	self.BaseClass.Think(self)

	local vStart = self:GetPos()
	local vForward = self:GetUp()
	
    local trace = {}
	   trace.start = vStart
	   trace.endpos = vStart + (vForward * self:GetBeamLength())
	   trace.filter = { self }
	local trace = util.TraceLine( trace ) 
	
	local ent = trace.Entity

	if (!trace.Entity or !trace.Entity:IsValid() or trace.Entity:IsWorld() or !trace.Entity:GetPhysicsObject()) then
		if(self.State!=0)then
            if !self.NoColorChg then self:SetColor(Color(255, 255, 255, 255)) end
			Wire_TriggerOutput(self,"State",0) self.State=0
			Wire_TriggerOutput(self,"A",0)     self.A=0
			Wire_TriggerOutput(self,"B",0)     self.B=0
			Wire_TriggerOutput(self,"C",0)     self.C=0
			Wire_TriggerOutput(self,"D",0)     self.D=0
			self:ShowOutput()
        end
		return false
	end
    
	if(trace.Entity.__RFID_HASRFID) then
		if !self.NoColorChg then self:SetColor(Color(0, 255, 0, 255)) end
		Wire_TriggerOutput(self,"State",1)                 self.State=1
		Wire_TriggerOutput(self,"A",trace.Entity.__RFID_A) self.A=trace.Entity.__RFID_A
		Wire_TriggerOutput(self,"B",trace.Entity.__RFID_B) self.B=trace.Entity.__RFID_B
		Wire_TriggerOutput(self,"C",trace.Entity.__RFID_C) self.C=trace.Entity.__RFID_C
		Wire_TriggerOutput(self,"D",trace.Entity.__RFID_D) self.D=trace.Entity.__RFID_D
		self:ShowOutput()
	else
		if !self.NoColorChg then self:SetColor(Color(255, 0, 0, 255)) end
		Wire_TriggerOutput(self,"State",-1) self.State=-1
		Wire_TriggerOutput(self,"A",0)      self.A=0
		Wire_TriggerOutput(self,"B",0)      self.B=0
		Wire_TriggerOutput(self,"C",0)      self.C=0
		Wire_TriggerOutput(self,"D",0)      self.D=0
		self:ShowOutput()
	end
    
    self:NextThink(CurTime()+0.125)
end

function ENT:ShowOutput()
    txt = "RFID Beam Reader\n"
	if self.Outputs["State"].Value==0 then
		txt=txt.."No object found"
	elseif self.Outputs["State"].Value==-1 then
		txt=txt.."Object without RFID found"
	else
		txt=txt.."Reading\nA="..tostring(self.Outputs["A"].Value)..";B="..tostring(self.Outputs["B"].Value)..";C="..tostring(self.Outputs["C"].Value)..";D="..tostring(self.Outputs["D"].Value)
	end
	self:SetOverlayText( txt )
end

function ENT:OnRestore()
    Wire_Restored(self)
end