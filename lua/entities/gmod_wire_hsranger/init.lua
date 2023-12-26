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
	
	7 = HitNormal X
	8 = HitNormal Y
	9 = HitNormal Z

	10 = Enable extended info
	11 = Collision Group mask
	12 = Mask
	13 = Entity ID to check disposition against
	14 = Unused
	15 = Unused

	16 = Collision Group Hit Mask
	17 = Surface Flags
	18 = Material Type Enum
	19 = Hit Entity ID
	20 = Is NPC?
	(EXTENDED INFO)
	21 = Entity's Max Health
	22 = Entity's Health
	23 = Disposition Enum towards Ent ID in Mem[13]
	24-31 unused
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
	self.TraceCollisionGroupMask = 0 -- COLLISION_GROUP_NONE
	self.TraceContentMask = 33570827 -- MASK_SOLID
	self.ExtendedInfo = false
	self.Memory = {}
	
	for i = 0, 31 do
		self.Memory[i] = 0
	end
	self.Memory[11] = self.TraceCollisionGroupMask
	self.Memory[12] = self.TraceContentMask
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
	trace.collisiongroup = self.TraceCollisionGroupMask
	trace.mask = self.TraceContentMask
	
	if ( self.Memory[6] > 0 ) then 
		trace.mask = -1
	end
	trace = util.TraceLine( trace )
	
	local dist = 0
	local hitnormal = Vector( 0, 0, 0 )
	if ( trace.Hit ) then
		dist = trace.Fraction * self.Memory[2]
		hitnormal = trace.HitNormal
	else
		if ( not ( self.Memory[3] > 0 ) ) then
			dist = self.Memory[2]
		end
	end
	
	self.Memory[1] = dist or 0
	self.Memory[7] = hitnormal.x or 0
	self.Memory[8] = hitnormal.y or 0
	self.Memory[9] = hitnormal.z or 0
	self.Memory[16] = trace.Contents
	self.Memory[17] = trace.SurfaceFlags
	self.Memory[18] = trace.MatType
	if ( trace.Entity:IsValid() ) then 
		self.Memory[19] = trace.Entity:EntIndex()
		if ( self.ExtendedInfo ) then
				self.Memory[21] = trace.Entity:GetMaxHealth()
				self.Memory[22] = trace.Entity:Health()
		else
			self.Memory[21] = 0
			self.Memory[22] = 0
		end
		if( trace.Entity:IsNPC() ) then
			self.Memory[20] = 1
			if ( self.ExtendedInfo ) then
				if ( self.FriendlyEnt and self.FriendlyEnt:IsValid() ) then
					self.Memory[23] = trace.Entity:Disposition( self.FriendlyEnt )
				else
					self.Memory[23] = 0
				end
			else
				self.Memory[23] = 0
			end
		else
			self.Memory[20] = 0
			self.Memory[23] = 0
		end
	else
		self.Memory[19] = -1
		self.Memory[20] = 0
		self.Memory[21] = 0
		self.Memory[22] = 0
		self.Memory[23] = 0
	end
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
	if ( Address >= 0 and Address <= 31 ) then
		return self.Memory[Address]
	end
end

function ENT:WriteCell( Address, Value )
	if ( Address == 0 and Value > 0 ) then
		self:Trace()
		return true
	elseif ( Address >= 2 and Address <= 6 ) then
		self.Memory[Address] = Value
		return true
	elseif ( Address >= 10 and Address <= 15) then
		local flooredvalue = math.floor(Value)
		if ( Address == 10 ) then
			if( flooredvalue > 0 ) then
				self.ExtendedInfo = true
			else
				self.ExtendedInfo = false
			end
		elseif( Address == 11 ) then
			self.TraceCollisionGroupMask = flooredvalue
		elseif( Address == 12 ) then
			self.TraceContentMask = flooredvalue
		elseif( Address == 13 ) then
			if ( flooredvalue > 0 ) then
				self.FriendlyEnt = Entity(flooredvalue)
			else
				self.FriendlyEnt = nil
			end
		end
		self.Memory[Address] = flooredvalue
		return true
	end
end

function ENT:Think()
	self:SetBeamLength( math.min( self.Memory[2], 2000 ) )
	self:SetSkewX( self.Memory[4] )
	self:SetSkewY( self.Memory[5] )
	self:UpdateTPS( false )
end
