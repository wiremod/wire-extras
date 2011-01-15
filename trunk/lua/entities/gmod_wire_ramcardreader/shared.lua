

ENT.Type 			= "anim"
ENT.Base 			= "base_wire_entity"

ENT.PrintName		= "Keycard Reader/Writer (Wire)"
ENT.Author			= "Jesse Dubay (adb)"
ENT.Contact			= "jesse@thefortytwo.net"

ENT.Spawnable			= false
ENT.AdminSpawnable		= false

function ENT:SetRange(length)
	self:SetNetworkedFloat("BeamLength", length)
end

function ENT:GetRange()
	return self:GetNetworkedFloat("BeamLength") or 0
end

function ENT:SetReadMode(mode)
	self:SetNetworkedFloat("ReadMode", mode)
end

function ENT:GetReadMode()
	return self:GetNetworkedFloat("ReadMode") or 0
end

function ENT:SetLCMatchMode(mode)
        self:SetNetworkedFloat("LCMatchMode", mode)
end

function ENT:GetLCMatchMode()
        return self:GetNetworkedFloat("LCMatchMode") or 0
end