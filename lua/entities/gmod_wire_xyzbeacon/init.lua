
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "XYZBeacon"

local MODEL = Model("models/jaanus/wiretool/wiretool_range.mdl")

function ENT:Initialize()
	self:SetModel( MODEL )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self.Inputs = Wire_CreateInputs(self,{"X","Y","Z"})
	self.VPos = Vector(0,0,0)
end

function ENT:OnRemove()
	Wire_Remove(self)
end

function ENT:Setup()
end

function ENT:GetBeaconPos(sensor)
	return self.VPos
end

function ENT:GetBeaconVelocity(sensor)
	return Vector()
end

function ENT:ShowOutput(value)
	if (value ~= self.PrevOutput) then
		self:SetOverlayText( "XYZ Beacon" )
		self.PrevOutput = value
	end
end
function ENT:TriggerInput(iname, value)
	if (iname == "X") then
		self.VPos.x=value
	end
	if (iname == "Y") then
	self.VPos.y=value
	end 
	if (iname == "Z") then
	self.VPos.z=value
	end
end

function ENT:OnRestore()
    Wire_Restored(self)
end

