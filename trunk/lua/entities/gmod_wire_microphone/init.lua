
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Microphone"

local MODEL = Model("models/jaanus/wiretool/wiretool_range.mdl")

function ENT:Initialize()
	self:SetModel( MODEL )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self.Inputs = Wire_CreateInputs(self, { "On" })
	self.Outputs = Wire_CreateOutputs(self, { "Level" })
	self.Range = 512
	self.Sensitivity = 1
	self.Level = 0
	self.IsOn = true
	self:SetName("wiremicrophone"..tostring(self))
	
	self:ShowOutput()
end

function ENT:AcceptInput(input, activator, caller, value)
	if input=="OnSoundLevelChanged" then
		self.Level = value
		Wire_TriggerOutput(self, "Level", self.Level)
		self:ShowOutput()
		return true
	end
	return false
end

function ENT:TriggerInput(iname, value)
	if iname=="On" then
		self.IsOn = (value~=0)
		if self.IsOn then
			self.Microphone:Fire("Enable","",0)
		else
			self.Microphone:Fire("Disable","",0)
			self.Level = 0
			Wire_TriggerOutput(self, "Level", 0)
			self:ShowOutput()
		end
	end
end

function ENT:OnRemove()
	if self.Microphone and self.Microphone:IsValid() then
		self.Microphone:Fire("Disable","",0)
		self.Microphone:Remove()
	end
	Wire_Remove(self)
end

function ENT:Setup(range, sen, on, hearcombat, hearworld, hearplayer, hearbullet, hearexplo)
	if range<0 then range=0 end
	if sen<0 then sen=0 end
	if sen>10 then sen=10 end
	
	if on==2 then
		on = self.IsOn
	end
	
	self.Range = range
	self.Sensitivity = sen
	
	-- If it has already a microphone, delete it
	if self.Microphone and self.Microphone:IsValid() then
		self.Microphone:Fire("Disable","",0)
		self.Microphone:Remove()
	end
	
	-- Create teh microphone
	self.Microphone = ents.Create("env_microphone")
	self.Microphone:SetPos(self:GetPos())
	self.Microphone:SetKeyValue("target","wiremicrophone"..tostring(self))
	self.Microphone:SetKeyValue("Sensitivity",sen)
	self.Microphone:SetKeyValue("MaxRange",range)
	self.Microphone:SetKeyValue("spawnflags",hearcombat + 2*hearworld + 4*hearplayer + 8*hearbullet + 32*hearexplo)
	self.Microphone:Spawn()
	self.Microphone:Activate()
	
	if on then
		self.Microphone:Fire("Enable","",0)
	else
		self.Microphone:Fire("Disable","",0)
	end
	self.IsOn = on
	
	self.Microphone:Fire("addoutput","SoundLevel wiremicrophone"..tostring(self)..",OnSoundLevelChanged",0)
	
	self.Microphone:SetParent(self)
end

function ENT:Think()
	self.BaseClass.Think(self)
end

function ENT:ShowOutput()
    local txt = "Sound level: "..self.Level
	if not self.IsOn then txt = txt.." (disabled)" end
	self:SetOverlayText( txt )
end

function ENT:OnRestore()
    Wire_Restored(self)
end

