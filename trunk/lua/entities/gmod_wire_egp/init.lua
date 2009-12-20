AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include('shared.lua')

ENT.WireDebugName = "E2 Graphics Processor"

function ENT:Initialize()
	
	self.Entity:PhysicsInit(SOLID_VPHYSICS)
	self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
	self.Entity:SetSolid(SOLID_VPHYSICS)
	
	self.Render = {}
	self.RenderDirty = {}
	self.Poly = {}
	self.PolyDirty = {}
end

duplicator.RegisterEntityClass("gmod_wire_EGP", MakeWireEGP, "Pos", "Ang", "Model")
