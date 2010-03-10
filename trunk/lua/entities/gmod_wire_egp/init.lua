--EGP2 Compatability
if EGP then return end -- should detect an egp2 install
if not egp_enabled then egp_enabled = CreateConVar("egp_enabled", "1", FCVAR_ARCHIVE) end
if egp_enabled:GetInt() == 0 then return end
--------------------------------

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
	self.Clear = false
end

duplicator.RegisterEntityClass("gmod_wire_EGP", MakeWireEGP, "Pos", "Ang", "Model")
