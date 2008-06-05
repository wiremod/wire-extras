AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

KeypadWire = {}
KeypadWire.Passwords = {}
KeypadWire.CurrentNum = {}

util.PrecacheSound("buttons/button14.wav")
util.PrecacheSound("buttons/button9.wav")
util.PrecacheSound("buttons/button11.wav")
util.PrecacheSound("buttons/button15.wav")

ENT.WireDebugName = "Keypad"

function ENT:Initialize()
    self.Outputs = Wire_CreateOutputs(self.Entity, { "Valid", "Invalid" })

	self.Entity:SetModel( "models/props_lab/keypad.mdl" )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )

	local phys = self.Entity:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
	end
end

function ENT:Think()
	self.BaseClass:Think()

	self.Entity:SetNetworkedInt("keypad_rand", math.random(0, 10000))

	self.Entity:NextThink(CurTime()+10)
	return true
end

function ENT:OnRemove()
	local Index = self.Entity:EntIndex()

	for k,v in pairs(KeypadWire.Passwords) do
		if (Index == v.Ent) then
			table.remove(KeypadWire.Passwords, k)
		end
	end
end

function ENT:OnRestore()
	table.insert(KeypadWire.Passwords, {Ent = self.Entity:EntIndex(), Pass = self.Entity.Pass})
end

function ENT:AddPassword(pass)
	self:OnRemove()

	table.insert(KeypadWire.Passwords, {Ent = self.Entity:EntIndex(), Pass = pass})
end

local function CorrectPassword(Ent, Pass)
	Ent = tonumber(Ent)
	Pass = tonumber(Pass)

	for k,v in pairs(KeypadWire.Passwords) do
		if (Ent == v.Ent) then
			if (Pass == v.Pass) then
				return true
			end
		end
	end

	return false
end

local function RunKeypad(Ent, Repeats, Length, Delay, Var, Owner, Toggle, ValueOn, ValueOff)
	for i = 0, Repeats do
		if (Toggle) then
			if (Ent.Outputs[Var].Value == ValueOff) then
				if (i%2 == 1) then
					timer.Simple(Delay*i, function() Wire_TriggerOutput(Ent, Var, ValueOff) end)
				else
					timer.Simple(Delay*i, function() Wire_TriggerOutput(Ent, Var, ValueOn) end)
				end
			else
				if (i%2 == 1) then
					timer.Simple(Delay*i, function() Wire_TriggerOutput(Ent, Var, ValueOn) end)
				else
					timer.Simple(Delay*i, function() Wire_TriggerOutput(Ent, Var, ValueOff) end)
				end
			end
		else
			timer.Simple(Length*(i)+Delay*i, function() Wire_TriggerOutput(Ent, Var, ValueOn) end)
			timer.Simple(Length*(i+1)+Delay*i, function() Wire_TriggerOutput(Ent, Var, ValueOff) end)
		end
	end
end

local function KeypadCommand(Ply, Command, Args)
	if (Args == nil) then return end

	local Ent = ents.GetByIndex(Args[1])
	local Rand = Ent:GetNetworkedInt("keypad_rand")
	local Show = Ent:GetNetworkedBool("keypad_showaccess")
	local Secure = Ent:GetNetworkedBool("keypad_secure")

	if (Show) then return end
	if (tostring(Rand) != tostring(Args[3])) then return end

	if (Args[2] == "reset") then
		Ent:SetNetworkedInt("keypad_num", 0)
		KeypadWire.CurrentNum[Args[1]] = 0
		Ent:EmitSound("buttons/button14.wav")
	elseif (Args[2] == "accept") then
		local Num = KeypadWire.CurrentNum[Args[1]]
		local Owner = Ent:GetNetworkedEntity("keypad_owner")
		local Length
		local Delay
		local InitDelay
		local Repeats
		local Toggle
		local Var
		local ValueOn
		local ValueOff

		if (CorrectPassword(Args[1], Num)) then
				Length = Ent:GetNetworkedInt("keypad_length1")
				Delay = Ent:GetNetworkedInt("keypad_delay1")
				InitDelay = Ent:GetNetworkedInt("keypad_initdelay1")
				Repeats = Ent:GetNetworkedInt("keypad_repeats1")
				Toggle = Ent:GetNetworkedBool("keypad_toggle1")
				ValueOn = Ent:GetNetworkedInt("keypad_valueon1")
				ValueOff = Ent:GetNetworkedInt("keypad_valueoff1")
				Var = "Valid"
			Ent:SetNetworkedBool("keypad_access", true)
			Ent:EmitSound("buttons/button9.wav")
		else
				Length = Ent:GetNetworkedInt("keypad_length2")
				Delay = Ent:GetNetworkedInt("keypad_delay2")
				InitDelay = Ent:GetNetworkedInt("keypad_initdelay2")
				Repeats = Ent:GetNetworkedInt("keypad_repeats2")
				Toggle = Ent:GetNetworkedBool("keypad_toggle2")
				ValueOn = Ent:GetNetworkedInt("keypad_valueon2")
				ValueOff = Ent:GetNetworkedInt("keypad_valueoff2")
				Var = "Invalid"
			Ent:SetNetworkedBool("keypad_access", false)
			Ent:EmitSound("buttons/button11.wav")
		end


		if (InitDelay != 0) then
			timer.Simple(InitDelay, function() RunKeypad(Ent, Repeats, Length, Delay, Var, Owner, Toggle, ValueOn, ValueOff) end)
		else
			RunKeypad(Ent, Repeats, Length, Delay, Var, Owner, Toggle, ValueOn, ValueOff)
		end

		Ent:SetNetworkedBool("keypad_showaccess", true)
		timer.Simple(2, function()
						Ent:SetNetworkedInt("keypad_num", 0)
						KeypadWire.CurrentNum[Args[1]] = 0
						Ent:SetNetworkedBool("keypad_showaccess", false)
						end)
	else
		--local Num = Ent:GetNetworkedInt("keypad_num")*10 + Args[2]
		if not (KeypadWire.CurrentNum[Args[1]]) then KeypadWire.CurrentNum[Args[1]] = 0 end
		local Num = KeypadWire.CurrentNum[Args[1]] *10 + Args[2]

		if (Num < 10000) then
			KeypadWire.CurrentNum[Args[1]] = Num
			if (Secure) then
				Ent:SetNetworkedInt("keypad_num", string.len(Num))
			else
				Ent:SetNetworkedInt("keypad_num", Num)
			end
			Ent:EmitSound("buttons/button15.wav")
		end
	end
end
concommand.Add("gmod_keypadwire", KeypadCommand)
