AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
	self.BaseClass:Initialize()
	self.gain = 9.6 -- dB
	self.pol = 2 -- Horizontal Polarization
	self.beamWidth = 20.0 -- Degrees
	self.active = false -- TX enabled (if TX)
	self.txchannels = {} -- tx data
	self.txwatts = 0 -- tx power
	self:SetModel("models/radio/ra_log.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	local phys = self:GetPhysicsObject()
	if(phys:IsValid()) then phys:Wake() end
end