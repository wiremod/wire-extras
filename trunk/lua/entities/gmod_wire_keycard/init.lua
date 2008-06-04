AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Keycard"

local MODEL = Model("models/keycard/keycard.mdl")
local numValues = 32

function ENT:Initialize()
	self.Entity:SetModel( MODEL )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Entity:SetUseType( SIMPLE_USE )
        self.Entity:ResetValues()
        Msg("Initialized\n")
end

function ENT:Setup(pl)
	self.CardID = math.random(1000000)
	self.Entity:SetCardOwner(pl)
end

function ENT:Use(activator, caller)
	if (!activator:IsValid() or !activator:IsPlayer()) then return false end
	self.Entity:SetCardOwner(activator)
end

function ENT:SetValue(index, value)
        Msg("Setting value "..index.." to  "..value.."\n")
        index = math.Clamp(index, 0, numValues - 1)
	self.Values[index] = (value or 0)
	self.Entity:ShowOutput()
end

function ENT:SetLockCode(value)
	self.LockCode = (value or 0)
	self.Entity:ShowOutput()
end

function ENT:GetLockCode()
	return self.LockCode
end

function ENT:GetValue(index)
        index = math.Clamp(index, 0, numValues - 1)
	return self.Values[index]
end

function ENT:ResetValues()
        Msg("Resetting values\n")
        self.Values = {}
        for index = 0, numValues - 1 do
          self.Values[index] = 0
        end
end

function ENT:GetCardID()
	return self.CardID
end

function ENT:GetCardOwner()
	return self.CardOwner
end

function ENT:SetCardOwner(owner)
	self.CardOwner = owner
	self.Entity:ShowOutput()
end

function ENT:ShowOutput()
	local owner = self.CardOwner
	if (!owner:IsValid() or !owner:IsPlayer()) then
		owner = 'no signature\n(use to sign)'
	else
		owner = owner:GetName() .. ' (ID #' .. (owner:UserID() + 1) .. ')'
	end

	self:SetOverlayText(
		"Wire Keycard\nSigned: "..owner..
		"\nCard ID: "..tostring(self.CardID)..
		"\nLock Code: "..tostring(self.LockCode)
	)
end