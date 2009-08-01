AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

util.PrecacheSound("buttons/button14.wav")
util.PrecacheSound("buttons/button9.wav")
util.PrecacheSound("buttons/button8.wav")
util.PrecacheSound("buttons/button15.wav")

ENT.WireDebugName = "Keypad"

function ENT:Initialize()
	self.Entity:SetModel( "models/props_lab/keypad.mdl" )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	
	local phys = self.Entity:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
	end
	
	if self.AddOutputs then self.Outputs = Wire_CreateOutputs(self.Entity, { "Valid", "Invalid" }) end
end

function ENT:AddPassword(Pass)
	self:OnRemove()
	
	Pass = util.CRC(Pass)
	
	self.Entity.Pass = Pass
end

local function CorrectPassword(Ent, Pass)
	Pass = util.CRC(tonumber(Pass) or 0)
	
	return Ent.Pass == Pass
end

local function RunKeypad(self, Repeats, Length, Delay, Output, Owner, Toggle, ValueOn, ValueOff, Key)
	for i = 0, Repeats do
		if Key and Key ~= -1 then
			if i == 0 then
				numpad.Activate(Owner, nil, {Key}, Owner:UniqueID())
			else
				timer.Simple(Length*(i)+Delay*i, numpad.Activate, Owner, nil, {Key}, Owner:UniqueID())
			end
			timer.Simple(Length*(i+1)+Delay*i, numpad.Deactivate, Owner, nil, {Key}, Owner:UniqueID())
		end
		if (Toggle) then
			if (self.Outputs[Output].Value == ValueOff) then
				if (i%2 == 1) then
					timer.Simple(Delay*i, Wire_TriggerOutput, self, Output, ValueOff)
				else
					timer.Simple(Delay*i, Wire_TriggerOutput, self, Output, ValueOn)
				end
			else
				if (i%2 == 1) then
					timer.Simple(Delay*i, Wire_TriggerOutput, self, Output, ValueOn)
				else
					timer.Simple(Delay*i, Wire_TriggerOutput, self, Output, ValueOff)
				end
			end
		else
			timer.Simple(Length*(i)+Delay*i, Wire_TriggerOutput, self, Output, ValueOn)
			timer.Simple(Length*(i+1)+Delay*i, Wire_TriggerOutput, self, Output, ValueOff)
		end
	end
end


local function KeyCommand(Ply, EntId, command)
	
	local self = ents.GetByIndex(EntId)
	local Show = self:GetNetworkedBool("keypad_showaccess")
	local Secure = self:GetNetworkedBool("keypad_secure")
	
	if (Show) then return end
	if ((Ply:GetShootPos() - self:GetPos()):Length() > 50) then return end
	
	if (command == "reset") then
		self:SetNetworkedInt("keypad_num", 0)
		self:EmitSound("buttons/button14.wav")
		self.CurrentNum = nil
	elseif (command == "accept") then
		local Num = self.CurrentNum
		local Owner = self:GetPlayer()
		local Simple = self.simple -- non-wire
		local Key
		local Length
		local Delay
		local InitDelay
		local Repeats
		local Toggle -- wire
		local Output -- wire
		local ValueOn -- wire
		local ValueOff -- wire
		
		local access = CorrectPassword(self, self.CurrentNum)
		if access then
			Key = self.keygroup1 -- non-wire
			Length = self.length1
			Delay = self.delay1
			InitDelay = self.initdelay1
			Repeats = self.repeats1
			Toggle = self.keypad_toggle1 -- wire
			ValueOn = self.valueon1 -- wire
			ValueOff = self.valueoff1 -- wire
			Output = "Valid"
			self:SetNetworkedBool("keypad_access", true)
			self:EmitSound("buttons/button9.wav")
			
			self:SetNetworkedBool("keypad_showaccess", true)
		else
			Key = self.keygroup2 -- non-wire
			Length = self.length2
			Delay = self.delay2
			InitDelay = self.initdelay2
			Repeats = self.repeats2
			Toggle = self.keypad_toggle2 -- wire
			ValueOn = self.valueon2 -- wire
			ValueOff = self.valueoff2 -- wire
			Output = "Invalid"
			self:SetNetworkedBool("keypad_access", false)
			self:EmitSound("buttons/button8.wav")
			
			timer.Simple(0.25,	function()
				if (ValidEntity(self)) then
					self:SetNetworkedBool("keypad_showaccess", true)
				end
			end)
		end
		
		if Simple then
			Delay = 0
			InitDelay = 0
			Repeats = 0
		end
		
		if InitDelay ~= 0 then
			timer.Simple(InitDelay, RunKeypad, self, Repeats, Length, Delay, Output, Owner, Toggle, ValueOn, ValueOff, Key)
		else
			RunKeypad(self, Repeats, Length, Delay, Output, Owner, Toggle, ValueOn, ValueOff, Key)
		end
		
		timer.Simple(2,	function()
			if (ValidEntity(self)) then
				self:SetNetworkedInt("keypad_num", 0)
				self:SetNetworkedBool("keypad_showaccess", false)
			end
			
			self.CurrentNum = nil
		end)
	else
		self.CurrentNum = self.CurrentNum or 0
		local Num = self.CurrentNum *10 + command
		
		if (Num < 10000) then
			self.CurrentNum = Num
			if (Secure) then
				self:SetNetworkedInt("keypad_num", 10 ^ (string.len(Num)-1))
			else
				self:SetNetworkedInt("keypad_num", Num)
			end
			self:EmitSound("buttons/button15.wav")
		end
	end
end

concommand.Add("gmod_keypad", function(Ply, Command, Args)
	if (Args == nil) then return end
	KeyCommand(Ply, tonumber(Args[1]), Args[2])
end)


local dupevars = {
	"length1", "keygroup1", "delay1", "initdelay1", "repeats1", "toggle1", "valueon1", "valueoff1",
	"length2", "keygroup2", "delay2", "initdelay2", "repeats2", "toggle2", "valueon2", "valueoff2",
	"secure", "Pass", "simple",
}
function MakeKeypad( pl, Model, Ang, Pos, nocollide, frozen, ... )
	if not pl:CheckLimit("keypads") then return false end

	local keypad = ents.Create( "sent_keypad" )
	if not keypad:IsValid() then return false end

	keypad:SetAngles(Ang)
	keypad:SetPos(Pos)
	keypad:SetModel(Model)
	keypad:Spawn()

	keypad:SetPlayer(pl)

	if nocollide then keypad:GetPhysicsObject():EnableCollisions(false) end

	for index,varname in ipairs(dupevars) do
		keypad[varname] = arg[index]
	end
	keypad:SetNetworkedBool("keypad_secure", keypad.secure) -- feed client

	pl:AddCount( "keypads", keypad )

	return keypad
end

duplicator.RegisterEntityClass("sent_keypad", MakeKeypad, "Model", "Ang", "Pos", "nocollide", "frozen", unpack(dupevars))
