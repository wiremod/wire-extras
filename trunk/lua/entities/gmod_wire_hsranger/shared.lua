ENT.Type 		= "anim"
ENT.Base 		= "base_wire_entity"

ENT.PrintName	= "High Speed Ranger (Wire)"
ENT.Author		= "Borsty"
ENT.Contact		= ""

if ( SERVER ) then

	function ENT:SetSkewX( value )
		self.Entity:SetNetworkedFloat( "SkewX", math.max( -1, math.min( value, 1 ) ) )
	end

	function ENT:SetSkewY( value )
		self.Entity:SetNetworkedFloat( "SkewY", math.max( -1, math.min( value, 1 ) ) )
	end

	function ENT:SetBeamLength( length )
		self.Entity:SetNetworkedFloat( "BeamLength", length )
	end
	
end

function ENT:GetSkewX()
	return self.Entity:GetNetworkedFloat( "SkewX", 0 )
end

function ENT:GetSkewY()
	return self.Entity:GetNetworkedFloat( "SkewY", 0 )
end

function ENT:GetBeamLength()
	return self.Entity:GetNetworkedFloat( "BeamLength", 0 )
end
