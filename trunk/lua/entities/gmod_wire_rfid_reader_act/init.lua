
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "RFID User Reader"

local MODEL = Model("models/jaanus/wiretool/wiretool_siren.mdl")

function ENT:Initialize()
	self:SetModel( MODEL )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self.Outputs = Wire_CreateOutputs(self, { "State", "A", "B", "C", "D" })
	self.A=0
	self.B=0
	self.C=0
	self.D=0
	self.State=0
	self.Target=nil
	self.NoColorChg=false
	Wire_TriggerOutput(self,"State",0)
	Wire_TriggerOutput(self,"A",0)
	Wire_TriggerOutput(self,"B",0)
	Wire_TriggerOutput(self,"C",0)
	Wire_TriggerOutput(self,"D",0)
	self:ShowOutput()
end

function ENT:OnRemove()
	if(self.Target and self.Target:IsValid() and self.Target.Use_OMGRFIDBACKUPLOL) then -- Restore the default "Use" function, and delete the backup
		self.Target.Use = self.Target.Use_OMGRFIDBACKUPLOL
		self.Target.Use_OMGRFIDBACKUPLOL = nil
		self.Target.RFID_READER_ACT_LINKED = nil
	end
	Wire_Remove(self)
end

function ENT:Setup(ent_target,col)
	if col!=nil then self.NoColorChg=col end
	if !ent_target then return end
	
	if ent_target.RFID_READER_ACT_LINKED then -- Already have a linked filter ?
		ent_target.RFID_READER_ACT_LINKED.Target = nil
		ent_target.Use = ent_target.Use_OMGRFIDBACKUPLOL
		ent_target.Use_OMGRFIDBACKUPLOL = nil
	end -- Cleaned up !
	
	ent_target.RFID_READER_ACT_LINKED = self
	
	ent_target.Use_OMGRFIDBACKUPLOL = ent_target.Use -- Create a OMG BACKUP OF TEH USE FUNCTION
	ent_target.Use = function(this,ply)
		this.RFID_READER_ACT_LINKED:UseLinkedEntity(ply)
		this:Use_OMGRFIDBACKUPLOL(ply)
	end
	self.Target = ent_target
	self:ShowOutput(self.Target, self.State, self.A,self.B,self.C,self.D)
end

function ENT:UseLinkedEntity(ply)
	if (not ply:IsPlayer()) then return end
	if (self.PrevUser) and (self.PrevUser:IsValid()) then return end

	if (self:IsOn()) then
		return
	end

	self.PrevUser = ply
	self:Switch(true)
end

function ENT:Think()
	self.BaseClass.Think(self)

	if ( self:IsOn() ) then
		if (not self.PrevUser) or (not self.PrevUser:IsValid()) or (not self.PrevUser:KeyDown(IN_USE)) then
			self:Switch(false)
			self.PrevUser = nil
		end

		self:NextThink(CurTime()+0.05)
		return true
	end
	self:NextThink(CurTime()+0.05)
end

function ENT:Switch(on)
	if (not self:IsValid()) then return end

	self:SetOn( on )

	if (on) then
		if (self.PrevUser and self.PrevUser.__RFID_HASRFID) then
			if !self.NoColorChg then self:SetColor(Color(0, 255, 0, 255)) end
			Wire_TriggerOutput(self,"State",1)                  self.State=1
			Wire_TriggerOutput(self,"A",self.PrevUser.__RFID_A) self.A=self.PrevUser.__RFID_A
			Wire_TriggerOutput(self,"B",self.PrevUser.__RFID_B) self.B=self.PrevUser.__RFID_B
			Wire_TriggerOutput(self,"C",self.PrevUser.__RFID_C) self.C=self.PrevUser.__RFID_C
			Wire_TriggerOutput(self,"D",self.PrevUser.__RFID_D) self.D=self.PrevUser.__RFID_D
		else
			if !self.NoColorChg then self:SetColor(Color(255, 0, 0, 255)) end
			Wire_TriggerOutput(self,"State",-1) self.State=-1
			Wire_TriggerOutput(self,"A",0)      self.A=0
			Wire_TriggerOutput(self,"B",0)      self.B=0
			Wire_TriggerOutput(self,"C",0)      self.C=0
			Wire_TriggerOutput(self,"D",0)      self.D=0
		end
	else
		if !self.NoColorChg then self:SetColor(Color(255, 255, 255, 255)) end
		Wire_TriggerOutput(self,"State",0)  self.State=0
		Wire_TriggerOutput(self,"A",0)      self.A=0
		Wire_TriggerOutput(self,"B",0)      self.B=0
		Wire_TriggerOutput(self,"C",0)      self.C=0
		Wire_TriggerOutput(self,"D",0)      self.D=0
	end
	self:ShowOutput(self.Target, self.State, self.A,self.B,self.C,self.D)
	return true
end

function ENT:ShowOutput(t,s,a,b,c,d)
    txt = "RFID User Reader\nState:"
	if t then
		txt=txt.."Linked"
		if s==1 then
			txt=txt.."\nReading : A="..a..";B="..b..";C="..c..";D="..d
		end
	else
		txt=txt.."Not linked"
	end
	self:SetOverlayText( txt )
end

function ENT:OnRestore()
    Wire_Restored(self)
end
