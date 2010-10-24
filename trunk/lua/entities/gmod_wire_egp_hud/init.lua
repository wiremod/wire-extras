AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include('shared.lua')
AddCSLuaFile("HUDDraw.lua")
include("HUDDraw.lua")

ENT.WireDebugName = "E2 Graphics Processor HUD"

function ENT:Initialize()	
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	
	self.RenderTable = {}
	
	self:SetUseType(SIMPLE_USE)
	
	self.Inputs = WireLib.CreateInputs( self, { "0 to 512" } )
	self.Outputs = WireLib.CreateOutputs( self, { "link [WIRELINK]" } )
	WireLib.TriggerOutput( self, "link", self )
	
	self.xScale = { 0, 512 }
	self.yScale = { 0, 512 }
	self.Scaling = false
end

function ENT:TriggerInput( name, value )
	if (name == "0 to 512") then
		self:SetNWBool( "Resolution", value != 0 )
	end
end

function ENT:Use( ply )
	umsg.Start( "EGP_HUD_Use", ply ) umsg.Entity( self ) umsg.End()
end

function ENT:UpdateTransmitState() return TRANSMIT_ALWAYS end
