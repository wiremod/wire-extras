ENT.Type 		= "anim"
ENT.Base 		= "base_wire_entity"

ENT.PrintName	= "High Speed Ranger (Wire)"
ENT.Author		= "Borsty"
ENT.Contact		= ""

ENT.Spawnable			= false
ENT.AdminSpawnable		= false

if ( SERVER ) then

	function ENT:SetSkewX( value )
		self:SetNWFloat( "SkewX", math.max( -1, math.min( value, 1 ) ) )
	end

	function ENT:SetSkewY( value )
		self:SetNWFloat( "SkewY", math.max( -1, math.min( value, 1 ) ) )
	end

	function ENT:SetBeamLength( length )
		self:SetNWFloat( "BeamLength", length )
	end
	
end

function ENT:GetSkewX()
	return self:GetNWFloat( "SkewX", 0 )
end

function ENT:GetSkewY()
	return self:GetNWFloat( "SkewY", 0 )
end

function ENT:GetBeamLength()
	return self:GetNWFloat( "BeamLength", 0 )
end
