
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Exit Point Controller"
ENT.OverlayDelay = 0

CreateConVar("sbox_maxwire_exit_points", 6)

if (CLIENT) then
	language.Add( "sboxlimit_wire_exit_point", "You've hit the Exit Point Controller limit!" )
end

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	
	self.Entities = {}
	self.Position = Vector(50,0,10)
	self.Global = false
	
	AddExitPoint( self )
	
	self.Inputs = WireLib.CreateInputs( self.Entity, { "Entities [ARRAY]", "Position [VECTOR]", "Global" } )
	self:SetOverlayText( "Number of entities linked: 0\nPosition: " .. tostring(self.Position) .. "\nGlobal: No" )
end

function ENT:ShowOutput()
	local str = "No"
	if (self.Global) then str = "Yes" end
	self:SetOverlayText( "Number of entities linked: " .. #self.Entities .. "\nPosition: " .. tostring(self.Position) .. "\nGlobal: " .. str )
end

function ENT:TriggerInput( name, value )
	if (name == "Entities") then
		self.Entities = value
		self:ShowOutput()
	elseif (name == "Position") then
		self.Position = value
		self:ShowOutput()
	elseif (name == "Global") then
		local bool = false
		if (value != 0) then
			bool = true
		end
		self.Global = bool
		self:ShowOutput()
	end
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	if (!ply:CheckLimit("wire_exit_points")) then 
		ent:Remove()
		return
	end
	ply:AddCount( "wire_exit_points", ent )
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)
end

