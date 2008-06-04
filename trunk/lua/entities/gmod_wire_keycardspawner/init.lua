AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "KeycardSpawner"

util.PrecacheSound('buttons/button9.wav')

util.PrecacheSound('buttons/button11.wav')

local MODEL = Model("models/keycardspawner/keycardspawner.mdl")
function ENT:Initialize()
	self.Entity:SetModel( MODEL )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Inputs = Wire_CreateInputs(self.Entity, { "Spawn" })
	self:ShowOutput()
end

function ENT:SetLockCode(value)
	self.LockCode = (value or 0)
end

function ENT:TriggerInput(iname, value)
	if (iname == "Spawn" and value == 1) then
                local keycard = MakeWireKeycard(self.Entity:GetOwner(), self.Entity:GetAngles(), self.Entity:GetPos() + (self.Entity:GetUp() * 4), self.LockCode)
		if (keycard) then
			self.Entity:EmitSound('buttons/button9.wav')
        	else
			self.Entity:EmitSound('buttons/button11.wav')
		end
	end
end


function MakeWireKeycard( pl, ang, Pos, lockcode )
	local wire_keycard = ents.Create( "gmod_wire_keycard" )
	// ang.Pitch = ang.Pitch + 90
	if (!wire_keycard:IsValid()) then return false end
	wire_keycard:SetPos( Pos )
	wire_keycard:SetAngles( ang )
	wire_keycard:Setup(pl)
	wire_keycard:SetLockCode(lockcode)
        wire_keycard:ResetValues()
	wire_keycard:Spawn()
	return wire_keycard
end

function ENT:ShowOutput()
	self:SetOverlayText("Wire Keycard Spawner\nLock Code: "..self.LockCode)
end