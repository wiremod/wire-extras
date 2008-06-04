AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Notifier"

local MODEL = Model("models/jaanus/wiretool/wiretool_range.mdl")

function ENT:Initialize()
	self.Entity:SetModel( MODEL )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Entity:StartMotionController()

	self.Inputs = Wire_CreateInputs(self.Entity, { "Error"})
end

function ENT:Setup( Lines )
	local inames = {"Line","Player","Send"}
	self.lines = {}
	self.Lines = Lines
	self.lastsend = 0
	self.ID = "(" .. self.pl:SteamID() .. ")"
	local i = 1
	for k,v in pairs(Lines) do
		self.lines[i] = {}
		self.lines[i].line = v
		self.lines[i].args = self:ParseArgs(v,"<",">",0)
		if (self.lines[i].args != nil) then
			for k2,v2 in pairs(self.lines[i].args) do
				table.insert(inames,v2)
			end
		end
		i = i + 1
	end
	Wire_AdjustInputs(self.Entity,inames)
end
function ENT:ParseArgs(line,char1,char2,remov)
	if !(string.find(line,char1) && string.find(line,char2)) then return nil end
	local ret = {}
	local p = string.find(line,char1)
	local n = 1
	local i = 1
	while(p) do
		n = string.find(line,char2,p + 1)
		if (string.sub(line,p + remov,n - remov) != "")  then
			ret[i] = {}
			ret[i] = string.sub(line,p + remov,n - remov)
			i = i + 1
		end
		p = string.find(line,char1,n + 1)
	end
	return ret
end
//OMG STACK TO HELL!!!
function ENT:TriggerInput(iname, value)
	if (iname == "Send" && value != 0) then
		if (self.Inputs.Line.Value > 0 && self.Inputs.Line.Value < 25) then
			if (self.Inputs.Player.Value == 0 || (IsEntity(Entity(self.Inputs.Player.Value)) == true && Entity(self.Inputs.Player.Value):IsPlayer() == true)) then
				if (CurTime() > self.lastsend) then
					self.front = ""
					if (NotifierSilent == 0) then
						self.front = "(" .. self.pl:Nick() .. ") "
					end
					local line = self.lines[self.Inputs.Line.Value].line
					if (self.lines[self.Inputs.Line.Value] != nil && self.lines[self.Inputs.Line.Value].args != nil) then
						for k2,args in pairs(self.lines[self.Inputs.Line.Value].args) do
							line =string.gsub(line,args,tostring(self.Inputs[args].Value) or tostring(0))
						end
					end
					if (self.Inputs.Player.Value == 0) then
						for kply,ply in pairs(ents.FindByClass("Player")) do
							ply:PrintMessage(3,self.front .. (line or ""))
							if (NotifierConsole == 1) then Msg(self.ID .. self.front .. (line or "") .. "\n") end
						end
					else									
						Entity(self.Inputs.Player.Value):PrintMessage(3,self.front .. (line or ""))
						if (NotifierConsole == 1) then Msg(self.ID .. self.front .. (line or "") .. "\n") end
					end
					self.lastsend = CurTime() + NotifierDelay
				end
			end
		end
	end
	if (iname == "Line") then
		self.Inputs.Line.Value = value
	end
	if (iname == "Player") then
		self.Inputs.Player.Value = value
	end
end
