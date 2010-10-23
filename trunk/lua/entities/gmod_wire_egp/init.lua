AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include('shared.lua')

ENT.WireDebugName = "E2 Graphics Processor"

function ENT:Initialize()	
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	
	self.RenderTable = {}
	self.OldRenderTable = {}
	
	self.Outputs = WireLib.CreateOutputs( self, { "link [WIRELINK]" } )
	WireLib.TriggerOutput( self, "link", self )
	
	self.xScale = { 0, 512 }
	self.yScale = { 0, 512 }
	self.Scaling = false
end

function ENT:UpdateTransmitState() return TRANSMIT_ALWAYS end
