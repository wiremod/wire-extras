

ENT.Type 			= "anim"
ENT.Base 			= "base_wire_entity"

ENT.PrintName		= "Keycard Reader/Writer (Wire)"
ENT.Author			= "Jesse Dubay (adb)"
ENT.Contact			= "jesse@thefortytwo.net"

ENT.Spawnable			= false
ENT.AdminSpawnable		= false

function ENT:SetRange(length)
	self:SetNWFloat("BeamLength", length)
end

function ENT:GetRange()
	return self:GetNWFloat("BeamLength") or 0
end

function ENT:SetReadMode(mode)
	self:SetNWFloat("ReadMode", mode)
end

function ENT:GetReadMode()
	return self:GetNWFloat("ReadMode") or 0
end

function ENT:SetLCMatchMode(mode)
        self:SetNWFloat("LCMatchMode", mode)
end

function ENT:GetLCMatchMode()
        return self:GetNWFloat("LCMatchMode") or 0
end