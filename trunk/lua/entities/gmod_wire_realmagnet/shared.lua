

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
	
	self.Entity:SetNetworkedBool( "On", boolon, true )
	self.Entity:GetTable().On=boolon
end

function ENT:IsOn( name )
	if SERVER then return self.Entity:GetTable().On end
	return self.Entity:GetNetworkedBool( "On" )
end

function ENT:SetBackwards( boolon )
	
	self.Entity:SetNetworkedBool( "Backwards", boolon, true )
	self.Entity:GetTable().Backwards=boolon
end

function ENT:IsBackwards( name )
	if SERVER then return self.Entity:GetTable().Backwards end
	return self.Entity:GetNetworkedBool( "Backwards" )
end


function ENT:SetTargetOnlyMetal( boolon )
	self.Entity:SetNetworkedBool( "TargetOnlyMetal", boolon, true )
	self.Entity:GetTable().TargetOnlyMetal=boolon
end

function ENT:IsTargetOnlyMetal( name )
	if SERVER then return self.Entity:GetTable().TargetOnlyMetal end
	return self.Entity:GetNetworkedBool( "TargetOnlyMetal" ) or true
end


function ENT:SetStrength(Strength)
	
	if Strength<0 then 
		self:SetBackwards(true)
		Strength=math.abs(Strength)
	end
	Strength=math.min(Strength,GetConVarNumber("sbox_wire_magnets_maxstrength"))
	self.Entity:SetNetworkedFloat("Strength", Strength)
	self.Entity:GetTable().Strength=Strength
end

function ENT:GetStrength()
	if SERVER then return self.Entity:GetTable().Strength or 0 end
	return self.Entity:GetNetworkedFloat("Strength") or 0
end
function ENT:SetLength(len)
	--print("set len:"..len)
	self.Entity:SetNetworkedFloat("Length", math.min(len,GetConVarNumber("sbox_wire_magnets_maxstrength")))
	self.Entity:GetTable().Len=math.min(len,GetConVarNumber("sbox_wire_magnets_maxstrength"))
end

function ENT:GetLength()
	--PrintTable(self.Entity:GetTable())
	if SERVER then return self.Entity:GetTable().Len or 0 end
	return self.Entity:GetNetworkedFloat("Length") or 0
end
function ENT:SetPropFilter(pf)
	self.Entity:SetNetworkedString("PropFilter", pf)
	self.Entity:GetTable().PropFilter=pf
end

function ENT:GetPropFilter()
	if SERVER then return self.Entity:GetTable().PropFilter end
	return self.Entity:GetNetworkedString("PropFilter") or ""
end

