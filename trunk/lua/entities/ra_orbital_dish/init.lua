AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
	self.BaseClass:Initialize()
	self.gain = 20.0 -- dB
	self.pol = 1 -- Vertical Polarization
	self.beamWidth = 15.0 -- Degrees
	self.active = false -- TX enabled (if TX)
	self.txchannels = {} -- tx data
	self.txwatts = 0 -- tx power
	self.Entity:SetModel("models/radio/ra_orbital_dish.mdl")
	self.Entity:PhysicsInit(SOLID_VPHYSICS)
	self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
	self.Entity:SetSolid(SOLID_VPHYSICS)
	local phys = self.Entity:GetPhysicsObject()
	if(phys:IsValid()) then phys:Wake() end
end