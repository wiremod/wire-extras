

ENT.Type 			= "anim"
ENT.Base 			= "base_wire_entity"

ENT.PrintName		= "Keycard Reader/Writer (Wire)"
ENT.Author			= "Jesse Dubay (adb)"
ENT.Contact			= "jesse@thefortytwo.net"

ENT.Spawnable			= false
ENT.AdminSpawnable		= false

function ENT:SetRange(length)
	self.Entity:SetNetworkedFloat("BeamLength", length)
end

function ENT:GetRange()
	return self.Entity:GetNetworkedFloat("BeamLength") or 0
end

function ENT:SetReadMode(mode)
	self.Entity:SetNetworkedFloat("ReadMode", mode)
end

function ENT:GetReadMode()
	return self.Entity:GetNetworkedFloat("ReadMode") or 0
end

function ENT:SetLCMatchMode(mode)
        self.Entity:SetNetworkedFloat("LCMatchMode", mode)
end

function ENT:GetLCMatchMode()
        return self.Entity:GetNetworkedFloat("LCMatchMode") or 0
end