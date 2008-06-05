AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

Keypad = {}
Keypad.Passwords = {}
Keypad.CurrentNum = {}

util.PrecacheSound("buttons/button14.wav")
util.PrecacheSound("buttons/button9.wav")
util.PrecacheSound("buttons/button11.wav")
util.PrecacheSound("buttons/button15.wav")


function ENT:Initialize()
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
	self.Entity:SetNetworkedInt("keypad_rand", math.random(0, 10000))

	self.Entity:NextThink(CurTime()+10)
	return true
end

function ENT:OnRemove()
	local Index = self.Entity:EntIndex()

	for k,v in pairs(Keypad.Passwords) do
		if (Index == v.Ent) then
			table.remove(Keypad.Passwords, k)
		end
	end
end

function ENT:OnRestore()
	table.insert(Keypad.Passwords, {Ent = self.Entity:EntIndex(), Pass = self.Entity.Pass})
end

function ENT:AddPassword(pass)
	self:OnRemove()

	self.Entity.Pass = pass
	table.insert(Keypad.Passwords, {Ent = self.Entity:EntIndex(), Pass = pass})
end

local function CorrectPassword(Ent, Pass)
	Ent = tonumber(Ent)
	Pass = tonumber(Pass)

	for k,v in pairs(Keypad.Passwords) do
		if (Ent == v.Ent) then
			if (Pass == v.Pass) then
				return true
			end
		end
	end

	return false
end

local function RunKeypad(Repeats, Length, Delay, Key, Owner)
	for i = 0, Repeats do
		timer.Simple(Length*(i)+Delay*i, function () Owner:ConCommand("+gm_special "..Key.."\n") end)
		timer.Simple(Length*(i+1)+Delay*i, function () Owner:ConCommand("-gm_special "..Key.."\n") end)
	end

end

local function KeypadCommand(Ply, Command, Args)
	if (Args == nil) then return end

	local Ent = ents.GetByIndex(Args[1])
	local Rand = Ent:GetNetworkedInt("keypad_rand")
	local Show = Ent:GetNetworkedBool("keypad_showaccess")

	if (Show) then return end
	if (tonumber(Rand) != tonumber(Args[3])) then return end

	if (Args[2] == "reset") then
		Ent:SetNetworkedInt("keypad_num", 0)
		Ent:EmitSound("buttons/button14.wav")
	elseif (Args[2] == "accept") then
		local Num = Ent:GetNetworkedInt("keypad_num")
		local Owner = Ent:GetNetworkedEntity("keypad_owner")
		local Simple = Ent:GetNetworkedBool("keypad_simple")
		local Key
		local Length
		local Delay
		local InitDelay
		local Repeats

		if (CorrectPassword(Args[1], Num)) then
				Key = Ent:GetNetworkedInt("keypad_keygroup1")
				Length = Ent:GetNetworkedInt("keypad_length1")
				Delay = Ent:GetNetworkedInt("keypad_delay1")
				InitDelay = Ent:GetNetworkedInt("keypad_initdelay1")
				Repeats = Ent:GetNetworkedInt("keypad_repeats1")
			Ent:SetNetworkedBool("keypad_access", true)
			Ent:EmitSound("buttons/button9.wav")
		else
				Key = Ent:GetNetworkedInt("keypad_keygroup2")
				Length = Ent:GetNetworkedInt("keypad_length2")
				Delay = Ent:GetNetworkedInt("keypad_delay2")
				InitDelay = Ent:GetNetworkedInt("keypad_initdelay2")
				Repeats = Ent:GetNetworkedInt("keypad_repeats2")
			Ent:SetNetworkedBool("keypad_access", false)
			Ent:EmitSound("buttons/button11.wav")
		end


		if (Key != nil) and (Key != -1) then
			if (Simple) then
				Owner:ConCommand("+gm_special "..Key.."\n")
				timer.Simple(Length, function() Owner:ConCommand("-gm_special "..Key.."\n") end)
			else
				if (InitDelay != 0) then
					timer.Simple(InitDelay, function() RunKeypad(Repeats, Length, Delay, Key, Owner) end)
				else
					RunKeypad(Repeats, Length, Delay, Key, Owner)
				end
			end
		end

		Ent:SetNetworkedBool("keypad_showaccess", true)
		timer.Simple(2, function()
						Ent:SetNetworkedInt("keypad_num", 0)
						Ent:SetNetworkedBool("keypad_showaccess", false)
						end)
	else
		local Num = Ent:GetNetworkedInt("keypad_num")*10 + Args[2]

		if (Num < 10000) then
			Ent:SetNetworkedInt("keypad_num", Num)
			Ent:EmitSound("buttons/button15.wav")
		end
	end
end
concommand.Add("gmod_keypad", KeypadCommand)
