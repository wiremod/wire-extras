ENT.Type 			= "anim"
ENT.Base 			= "base_wire_entity"

ENT.PrintName		= "Wired Wirer"
ENT.Author			= "Jeremydeath"
ENT.Contact			= "Nope"
ENT.Purpose			= "To wire two entities together(like a nailer)"
ENT.Instructions	= ""

ENT.Spawnable			= false
ENT.AdminSpawnable		= false


function ENT:SetBeamRange(length)
	self:SetNetworkedFloat("BeamLength", length)
end

function ENT:GetBeamRange()
	return self:GetNetworkedFloat("BeamLength") or 0
end

function ENT:GetBeamLength()
	return self:GetNetworkedFloat("BeamLength") or 0
end

function ENT:SetSkewX(value)
	self:SetNetworkedFloat("SkewX", math.max(-100, math.min(value, 100)))
end

function ENT:SetSkewY(value)
	self:SetNetworkedFloat("SkewY", math.max(-100, math.min(value, 100)))
end

function ENT:SetBeamLength(length)
	self:SetNetworkedFloat("BeamLength", length)
end

function ENT:GetSkewX()
	return self:GetNetworkedFloat("SkewX") or 0
end

function ENT:GetSkewY()
	return self:GetNetworkedFloat("SkewY") or 0
end