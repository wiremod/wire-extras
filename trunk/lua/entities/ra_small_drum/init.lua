AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
	self.gain = 17.5 -- dB
	self.pol = 0 -- Cross Polarization
	self.beamWidth = 5.0 -- Degrees
	self.active = false -- TX enabled (if TX)
	self.txchannels = {} -- tx data
	self.txwatts = 0 -- tx power
	self:SetModel("models/radio/ra_small_drum.mdl")
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:PhysicsInit(SOLID_VPHYSICS)

	local phys = self:GetPhysicsObject()
	if phys:IsValid() then phys:Wake() end
end
