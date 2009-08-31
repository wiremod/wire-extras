
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "String"
ENT.OverlayDelay = 0

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )

	self.Outputs = Wire_CreateOutputs(self.Entity, { "Out" })
end

function ENT:Setup(value)
	
	if type(value) != "table" then 
		local v = value
		value = {}
		value[1] = v
	end
	
	local adjoutputs = {}
	local adjoutputtypes = {}
	for k,v in pairs(value) do
		adjoutputs[k] = "String"..k
		adjoutputtypes[k] = "STRING"
	end
	
	self.value = value
	WireLib.AdjustSpecialOutputs(self.Entity, adjoutputs, adjoutputtypes, value)
	
	local txt = ""
	local i = 1
	for k,v in pairs(value) do
		txt = txt .. i..": " .. v
		if (k < #value) then txt = txt .. "\n" end
		Wire_TriggerOutput(self.Entity, adjoutputs[k], v)
		i=i+1
	end
	
	self:SetOverlayText(txt)
	
end


function ENT:ReadCell( Address )
	if (Address >= 0) && (Address < table.Count(self.value)) then
		return self.value[Address+1]
	else
		return nil
	end
end

function ENT:WriteCell( Address, value )
	if (Address >= 0) && (Address < table.Count(self.value)) then
		return true
	else
		return false
	end
end
