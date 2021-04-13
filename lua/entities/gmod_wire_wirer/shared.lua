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
	self:SetNWFloat("BeamLength", length)
end

function ENT:GetBeamRange()
	return self:GetNWFloat("BeamLength") or 0
end

function ENT:GetBeamLength()
	return self:GetNWFloat("BeamLength") or 0
end

function ENT:SetSkewX(value)
	self:SetNWFloat("SkewX", math.max(-100, math.min(value, 100)))
end

function ENT:SetSkewY(value)
	self:SetNWFloat("SkewY", math.max(-100, math.min(value, 100)))
end

function ENT:SetBeamLength(length)
	self:SetNWFloat("BeamLength", length)
end

function ENT:GetSkewX()
	return self:GetNWFloat("SkewX") or 0
end

function ENT:GetSkewY()
	return self:GetNWFloat("SkewY") or 0
end