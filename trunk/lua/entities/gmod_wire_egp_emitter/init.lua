AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include('shared.lua')

ENT.WireDebugName = "E2 Graphics Processor"

function ENT:Initialize()
	self:InitializeShared()
	
	self.Entity:PhysicsInit(SOLID_VPHYSICS)
	self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
	self.Entity:SetSolid(SOLID_VPHYSICS)
	
	self.Render = {}
	self.RenderDirty = {}
	self.RenderDrawn = {}
end

duplicator.RegisterEntityClass("gmod_wire_EGP_Emitter", MakeWireEGPEmitter, "Pos", "Ang", "Model")
