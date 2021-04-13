

ENT.Type 			= "anim"
ENT.Base 			= "base_wire_entity"

ENT.PrintName		= "Wire Magnet"
ENT.Author			= "cpf"
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""

ENT.Spawnable			= false
ENT.AdminSpawnable		= false

function ENT:SetOn( boolon )
	
	self:SetNWBool( "On", boolon, true )
	self:GetTable().On=boolon
end

function ENT:IsOn( name )
	if SERVER then return self:GetTable().On end
	return self:GetNWBool( "On" )
end

function ENT:SetBackwards( boolon )
	
	self:SetNWBool( "Backwards", boolon, true )
	self:GetTable().Backwards=boolon
end

function ENT:IsBackwards( name )
	if SERVER then return self:GetTable().Backwards end
	return self:GetNWBool( "Backwards" )
end


function ENT:SetTargetOnlyMetal( boolon )
	self:SetNWBool( "TargetOnlyMetal", boolon, true )
	self:GetTable().TargetOnlyMetal=boolon
end

function ENT:IsTargetOnlyMetal( name )
	if SERVER then return self:GetTable().TargetOnlyMetal end
	return self:GetNWBool( "TargetOnlyMetal" ) or true
end


function ENT:SetStrength(Strength)
	
	if Strength<0 then 
		self:SetBackwards(true)
		Strength=math.abs(Strength)
	end
	Strength=math.min(Strength,GetConVarNumber("sbox_wire_magnets_maxstrength"))
	self:SetNWFloat("Strength", Strength)
	self:GetTable().Strength=Strength
end

function ENT:GetStrength()
	if SERVER then return self:GetTable().Strength or 0 end
	return self:GetNWFloat("Strength") or 0
end
function ENT:SetLength(len)
	--print("set len:"..len)
	self:SetNWFloat("Length", math.min(len,GetConVarNumber("sbox_wire_magnets_maxlen")))
	self:GetTable().Len=math.min(len,GetConVarNumber("sbox_wire_magnets_maxlen"))
end

function ENT:GetLength()
	--PrintTable(self:GetTable())
	if SERVER then return self:GetTable().Len or 0 end
	return self:GetNWFloat("Length") or 0
end
function ENT:SetPropFilter(pf)
	self:SetNWString("PropFilter", pf)
	self:GetTable().PropFilter=pf
end

function ENT:GetPropFilter()
	if SERVER then return self:GetTable().PropFilter end
	return self:GetNWString("PropFilter") or ""
end

