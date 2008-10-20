AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "HighSpeed Ranger"

local MODEL = Model( "models/jaanus/wiretool/wiretool_range.mdl" )

	
--[[
	0 = Trace!
	1 = Result // Read only!
	
	2 = MaxLength
	3 = Default to Zero
	4 = SkewX
	5 = SkewY
	6 = Trace Water
	
	7 = unused
]]--

function ENT:Initialize()
	self:SetModel( MODEL )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Outputs = Wire_CreateOutputs( self, { "Memory" } )
	
	self:Setup()
end

function ENT:Setup()
	self.tps = 0
	self.tpsout = 0
	self.tpstime = CurTime() + 1
	
	self.Memory = {}
	
	for i = 0, 7 do
		self.Memory[i] = 0
	end
	
	self:ShowOutput()
end

function ENT:Trace()
	self.BaseClass.Think( self )
	
	local trace = {}
	trace.start = self:GetPos()
	
	if ( self.Memory[4] == 0 and self.Memory[5] == 0 ) then
		trace.endpos = trace.start + self:GetUp() * self.Memory[2]
	else
		local skew = Vector( self.Memory[4], self.Memory[5], 1 )		
		skew = skew * ( self.Memory[2] / skew:Length() )
		local beam_x = self:GetRight() * skew.x
		local beam_y = self:GetForward() * skew.y
		local beam_z = self:GetUp() * skew.z
		trace.endpos = trace.start + beam_x + beam_y + beam_z
	end	
	
	trace.filter = { self }
	
	if ( self.Memory[6] > 0 ) then 
		trace.mask = -1
	end
	trace = util.TraceLine( trace )
	
	local dist = 0
	
	if ( trace.Hit ) then
		dist = trace.Fraction * self.Memory[2]
	else
		if ( not ( self.Memory[3] > 0 ) ) then
			dist = self.Memory[2]
		end
	end
	
	self.Memory[1] = dist or 0
	self:UpdateTPS( true )
end

function ENT:UpdateTPS( add )
	if ( self.tpstime <= CurTime() ) then
		self.tpstime = CurTime() + 1		
		self.tpsout = self.tps
		self.tps = 0
		self:ShowOutput()
	end	
	if ( add ) then
		self.tps = self.tps + 1
	end
end

function ENT:ShowOutput()
	local txt = "High Speed Ranger\nTraces per second: " .. self.tpsout
	self:SetOverlayText(txt)
end

function ENT:ReadCell( Address )
	if ( Address >= 0 and Address <= 7 ) then
		return self.Memory[Address]
	end
end

function ENT:WriteCell( Address, Value )
	if ( Address == 0 and Value > 0 ) then
		self:Trace()
		return true
	elseif ( Address >= 2 and Address <= 7 ) then
		self.Memory[Address] = Value
		return true
	end
end

function ENT:Think()
	self:SetBeamLength( math.min( self.Memory[2], 2000 ) )
	self:SetSkewX( self.Memory[4] )
	self:SetSkewY( self.Memory[5] )
	self:UpdateTPS( false )
end
