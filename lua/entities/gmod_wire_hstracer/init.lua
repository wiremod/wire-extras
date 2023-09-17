AddCSLuaFile( "shared.lua" )
include('shared.lua')

ENT.WireDebugName = "HighSpeed Tracer"

--[[
	0 = Clk / Trace

	1 = StartPosition X
	2 = StartPosition Y
	3 = StartPosition Z

	4 = EndPosition X
	5 = EndPosition Y
	6 = EndPosition Z

	7 = Mask
	8 = CollisionGroup

	9 = Hit
	10 = HitSky
	11 = HitWorld
	12 = Fraction

	13 = HitPos X
	14 = HitPos Y
	15 = HitPos Z

	16 = HitNormal X
	17 = HitNormal Y
	18 = HitNormal Z
]]

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	self.tps = 0
	self.tpsout = 0
	self.tpstime = CurTime() + 1

	self.Outputs = Wire_CreateOutputs(self, { "Memory" })
	self.Memory = {}

	self.Memory[7] = MASK_SOLID
	self.Memory[8] = COLLISION_GROUP_NONE

	self:UpdateOverlay()
end

function ENT:Trace()
	self.BaseClass.Think(self)

	local memory = self.Memory

	local trace = {}
	trace.start = Vector(memory[1], memory[2], memory[3])
	trace.endpos = Vector(memory[4], memory[5], memory[6])
	trace.mask = memory[7]
	trace.collisiongroup = memory[8]

	local traceResult = util.TraceLine(trace)

	memory[9] = traceResult.Hit and 1 or 0
	memory[10] = traceResult.HitSky and 1 or 0
	memory[11] = traceResult.HitWorld and 1 or 0
	memory[12] = traceResult.Fraction

	local hitPos = traceResult.HitPos
	memory[13] = hitPos.x
	memory[14] = hitPos.y
	memory[15] = hitPos.z

	local hitNormal = traceResult.HitNormal
	memory[16] = hitNormal.x
	memory[17] = hitNormal.y
	memory[18] = hitNormal.z

	self.tps = self.tps + 1
end

function ENT:ReadCell(address)
	address = math.floor(address)
	if address < 0 then return end
	if address > 18 then return end

	return self.Memory[address] or 0
end

function ENT:WriteCell(address, value)
	if address < 0 then return false end
	if address > 18 then return false end

	if address == 0 and value > 0 then -- Clk / Trace
		self:Trace()
	end

	self.Memory[address] = value
	return true
end

function ENT:UpdateOverlay(update)
	if update then
		self.tpsout = self.tps
		self.tps = 0
	end

	self:SetOverlayText(string.format("High Speed Tracer\nTraces per second: %d", self.tpsout))
end

function ENT:Think()
	local curTime = CurTime()
	if curTime > self.tpstime then
		self.tpstime = curTime + 1
		self:UpdateOverlay(true)
	end
end

