
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

ENT.WireDebugName = "Motor"

include('shared.lua')

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )

	self.Inputs = Wire_CreateInputs( self.Entity, { "Mul" } )
end

function ENT:Think()
	self.BaseClass.Think(self)
end

function ENT:SetConstraint( c )
	self.constraint = c
	self.Mul = 0
	self:ShowOutput()
end

function ENT:SetAxis( a )
	self.axis = a
end


function ENT:TriggerInput(iname, value)
	if (iname == "Mul") then
		self.Mul = value
		self:ShowOutput()
		local Motor = self.constraint
		if ( !Motor:IsValid() ) then
			Msg("Controller doesn't have motor!\n"); 
			return false
		end
		Motor:Fire( "Scale", value, 0 )
		Motor:Fire( "Activate", "" , 0 )
	end
end


function ENT:ShowOutput()
	if self.constraint and self.constraint:IsValid() then
		self:SetOverlayText( "Torque: "..math.floor( self.constraint:GetTable().torque * self.Mul ) )
	end
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID, GetConstByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID, GetConstByID)
	
	if (GetConstByID) then
		if (info.constraint) and (info.constraint > 0) then
		    local const = GetConstByID(info.constraint)
			if (const) then
				self:SetConstraint(const)
			end
		end
		
		if (info.axis) and (info.axis > 0) then
		    local axis = GetConstByTable(info.axis)
			if (axis) then
				self:SetAxis(axis)
			end
		end
	end
end

