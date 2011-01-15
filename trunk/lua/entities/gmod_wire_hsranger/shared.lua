ENT.Type 		= "anim"
ENT.Base 		= "base_wire_entity"

ENT.PrintName	= "High Speed Ranger (Wire)"
ENT.Author		= "Borsty"
ENT.Contact		= ""

ENT.Spawnable			= false
ENT.AdminSpawnable		= false

if ( SERVER ) then

	function ENT:SetSkewX( value )
		self:SetNetworkedFloat( "SkewX", math.max( -1, math.min( value, 1 ) ) )
	end

	function ENT:SetSkewY( value )
		self:SetNetworkedFloat( "SkewY", math.max( -1, math.min( value, 1 ) ) )
	end

	function ENT:SetBeamLength( length )
		self:SetNetworkedFloat( "BeamLength", length )
	end
	
end

function ENT:GetSkewX()
	return self:GetNetworkedFloat( "SkewX", 0 )
end

function ENT:GetSkewY()
	return self:GetNetworkedFloat( "SkewY", 0 )
end

function ENT:GetBeamLength()
	return self:GetNetworkedFloat( "BeamLength", 0 )
end
