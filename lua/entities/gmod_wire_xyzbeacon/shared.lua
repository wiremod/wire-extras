

ENT.Type 			= "anim"
ENT.Base 			= "base_wire_entity"

ENT.PrintName		= ""
ENT.Author			= ""
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""

ENT.Spawnable			= false
ENT.AdminSpawnable		= false




function ENT:SetEffect( name )
	self:SetNWString( "Effect", name )
end

function ENT:GetEffect( name )
	return self:GetNWString( "Effect" )
end


function ENT:SetOn( boolon )
	self:SetNWBool( "On", boolon, true )
end

function ENT:IsOn( name )
	return self:GetNWBool( "On" )
end

function ENT:SetOffset( v )
	self:SetNWVector( "Offset", v, true )
end

function ENT:GetOffset( name )
	return self:GetNWVector( "Offset" )
end

function ENT:SetPointing(value)
	self:SetNWFloat( "Pointing", value )
end

function ENT:GetPointing()
	return self:GetNWSFloat( "Pointing" )
end
