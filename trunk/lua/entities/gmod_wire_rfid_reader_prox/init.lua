
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "RFID Reader"

local MODEL = Model("models/jaanus/wiretool/wiretool_input.mdl")

function ENT:Initialize()
	self.Entity:SetModel( MODEL )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Outputs = Wire_CreateOutputs(self.Entity, { "State", "A", "B", "C", "D" })
	self.MaxRange=100
	self.A=0
	self.B=0
	self.C=0
	self.D=0
	self.State=0
	self.NoColorChg=false
	Wire_TriggerOutput(self.Entity,"State",0)
	Wire_TriggerOutput(self.Entity,"A",0)
	Wire_TriggerOutput(self.Entity,"B",0)
	Wire_TriggerOutput(self.Entity,"C",0)
	Wire_TriggerOutput(self.Entity,"D",0)
	self:ShowOutput(0,0,0,0,0)
end

function ENT:OnRemove()
	Wire_Remove(self.Entity)
end

function ENT:Setup(Range,col)
    self.MaxRange=Range
	self.NoColorChg=col
end

function ENT:Think()
	self.BaseClass.Think(self)

	local ent = nil
	local mypos = self.Entity:GetPos()
	local mindist = -1
	for _,contact in pairs(ents.FindInSphere(self.Entity:GetPos(), self.MaxRange or 10)) do
		if contact.__RFID_HASRFID then
			ent=contact;
			local dist = (contact:GetPos() - mypos):Length()
			if (mindist<0 or dist<mindist) then
				mindist = dist
				ent=contact
			end
		end
	end

	if (!ent) then
		if(self.State!=0)then
            if !self.NoColorChg then self.Entity:SetColor(255, 255, 255, 255) end
			Wire_TriggerOutput(self.Entity,"State",0) self.State=0
			Wire_TriggerOutput(self.Entity,"A",0)     self.A=0
			Wire_TriggerOutput(self.Entity,"B",0)     self.B=0
			Wire_TriggerOutput(self.Entity,"C",0)     self.C=0
			Wire_TriggerOutput(self.Entity,"D",0)     self.D=0
			self:ShowOutput(0,0,0,0,0)
        end
		return false
	end
    
	if !self.NoColorChg then self.Entity:SetColor(0, 255, 0, 255) end
	Wire_TriggerOutput(self.Entity,"State",1)        self.State=1
	Wire_TriggerOutput(self.Entity,"A",ent.__RFID_A) self.A=ent.__RFID_A
	Wire_TriggerOutput(self.Entity,"B",ent.__RFID_B) self.B=ent.__RFID_B
	Wire_TriggerOutput(self.Entity,"C",ent.__RFID_C) self.C=ent.__RFID_C
	Wire_TriggerOutput(self.Entity,"D",ent.__RFID_D) self.D=ent.__RFID_D
	self:ShowOutput(self.State, self.A, self.B, self.C, self.D)
    
    self.Entity:NextThink(CurTime()+0.125)
end

function ENT:ShowOutput(s,a,b,c,d)
    txt = "RFID Reader\n"
	if s==0 then
		txt=txt.."No object found"
	else
		txt=txt.."Reading\nA="..a..";B="..b..";C="..c..";D="..d
	end
	self:SetOverlayText( txt )
end

function ENT:OnRestore()
    Wire_Restored(self.Entity)
end