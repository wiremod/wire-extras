/******************************************************************************\
	My custom flash sensor tracer type ( Based on wire rangers )
\******************************************************************************/

local next = next
local Angle = Angle
local Vector = Vector
local tostring = tostring
local tonumber = tonumber
local LocalToWorld = LocalToWorld
local WorldToLocal = WorldToLocal
local mathAbs = math.abs
local mathClamp = math.Clamp
local utilTraceLine = util.TraceLine
local utilGetSurfacePropName = util.GetSurfacePropName
local outError = error -- The function which generates error and prints it out

-- Register the type up here before the extension registration so that the fsensor still works
registerType("fsensor", "xfs", nil,
	nil,
	nil,
	function(retval)
		if(retval == nil) then return end
		if(not istable(retval)) then outError("Return value is neither nil nor a table, but a "..type(retval).."!",0) end
	end,
	function(v)
		return (not istable(v)) or (not v.StartPos)
	end
)

/************************************************************************************************************************************************************/

E2Lib.RegisterExtension("fsensor", true, "Lets E2 chips trace ray attachments and check for hits.")

local gaZero = Angle(0,0,0) -- Dummy zero angle for transformations
local gvZero = Vector(0,0,0) -- Dummy zero vector for transformations
local gnMaxLen = 50000 -- The tracer maximum length just about one cube map

local function isEntity(vE)
	return (vE and vE:IsValid())
end

local function convFSensorDirLocal(oFSen, vE, vA)
	if(not oFSen) then return {0,0,0} end
	local oD, oE = oFSen.Dir, (vE or oFSen.Ent)
	if(not (isEntity(oE) or vA)) then return {oD[1], oD[2], oD[3]} end
	local oV, oA = Vector(oD[1], oD[2], oD[3]), (vA and vA or oE:GetAngles())
	return {oV:Dot(oA:Forward()), -oV:Dot(oA:Right()), oV:Dot(oA:Up())}
end

local function convFSensorDirWorld(oFSen, vE, vA)
	if(not oFSen) then return {0,0,0} end
	local oD, oE = oFSen.Dir, (vE or oFSen.Ent)
	if(not (isEntity(oE) or vA)) then return {oD[1], oD[2], oD[3]} end
	local oV, oA = Vector(oD[1], oD[2], oD[3]), (vA and vA or oE:GetAngles())
	oV:Rotate(oA); return {oV[1], oV[2], oV[3]}
end

local function convFSensorOrgEnt(oFSen, sF, vE)
	if(not oFSen) then return {0,0,0} end
	local oO, oE = oFSen.Pos, (vE or oFSen.Ent)
	if(not isEntity(oE)) then return {oO[1], oO[2], oO[3]} end
	local oV = Vector(oO[1], oO[2], oO[3])
	oV:Set(oE[sF](oE, oV)); return {oV[1], oV[2], oV[3]}
end

local function convFSensorOrgUCS(oFSen, sF, vP, vA)
	if(not oFSen) then return {0,0,0} end
	local oO, oE = oFSen.Pos, (vE or oFSen.Ent)
	if(not isEntity(oE)) then return {oO[1], oO[2], oO[3]} end
	local oV, vN, aN = Vector(oO[1], oO[2], oO[3])
	if(sF == "LocalToWorld") then
		vN, aN = LocalToWorld(oV, gaZero, vP, vA); oV:Set(vN)
	elseif(sF == "WorldToLocal") then
		vN, aN = WorldToLocal(oV, gaZero, vP, vA); oV:Set(vN)
	end; return {oV[1], oV[2], oV[3]}
end

local function makeFSensor(vEnt, vPos, vDir, nLen)
	local oFSen = {}
	if(isEntity(vEnt)) then
		oFSen.Ent = vEnt -- Store attachment entity to manage local sampling
		oFSen.Ign = {[vEnt]=true} -- Store the base entity for ignore
	else
		oFSen.Ign, oFSen.Ent = {}, nil -- Make sure the entity is cleared
	end; oFSen.Cls = {} -- Table for storing the hit classes
	oFSen.Len = mathClamp(tonumber(nLen or 0),-gnMaxLen,gnMaxLen) -- How long the length is
	-- Local tracer position the trace starts from
	oFSen.Pos = Vector(vPos[1],vPos[2],vPos[3])
	-- Local tracer direction to read the data of
	oFSen.Dir = Vector(vDir[1],vDir[2],vDir[3])
	oFSen.Dir:Normalize() -- Normalize the direction
	oFSen.Dir:Mul(oFSen.Len) -- Multiply to add in real-time
	oFSen.Len = mathAbs(oFSen.Len) -- Length absolute
	-- http://wiki.garrysmod.com/page/Structures/TraceResult
	oFSen.TrO = {} -- Trace output parameters
	-- http://wiki.garrysmod.com/page/Structures/Trace
	oFSen.TrI = {
		mask = MASK_SOLID,
		start = Vector(), -- The start position of the trace
		output = oFSen.TrO,
		endpos = Vector(), -- The end position of the trace
		filter = function(oEnt)
			if(not isEntity(oEnt))) then return end
			if(oFSen.Ign[oEnt]) then return end
			local tCls, eCls = oFSen.Cls, oEnt:GetClass()
			if(next(tCls) and (not tCls[eCls])) then return end
			return true -- Finally we register the trace hit enabled
		end, ignoreworld = false, -- Should the trace ignore world or not
		collisiongroup = COLLISION_GROUP_NONE } -- Collision group control
	return oFSen
end

--[[ **************************** TRACER **************************** ]]

registerOperator("ass", "xfs", "xfs", function(self, args)
	local lhs, op2, scope = args[2], args[3], args[4]
	local rhs = op2[1](self, op2)
	self.Scopes[scope][lhs] = rhs
	self.Scopes[scope].vclk[lhs] = true
	return rhs
end)

__e2setcost(1)
e2function fsensor noFSensor()
	return nil
end

__e2setcost(20)
e2function fsensor entity:setFSensor(vector vP, vector vD, number nL)
	return makeFSensor(this, vP, vD, nL)
end

__e2setcost(20)
e2function fsensor newFSensor(vector vP, vector vD, number nL)
	return makeFSensor(nil, vP, vD, nL)
end

__e2setcost(20)
e2function fsensor entity:setFSensor(vector vP, vector vD)
	return makeFSensor(this, vP, vD, 0)
end

__e2setcost(20)
e2function fsensor newFSensor(vector vP, vector vD)
	return makeFSensor(nil, vP, vD, 0)
end

__e2setcost(20)
e2function fsensor entity:setFSensor(vector vP)
	return makeFSensor(this, vP, {0,0,0}, 0)
end

__e2setcost(20)
e2function fsensor newFSensor(vector vP)
	return makeFSensor(nil, vP, {0,0,0}, 0)
end

__e2setcost(20)
e2function fsensor entity:setFSensor()
	return makeFSensor(this, {0,0,0}, {0,0,0}, 0)
end

__e2setcost(20)
e2function fsensor newFSensor()
	return makeFSensor(nil, {0,0,0}, {0,0,0}, 0)
end

__e2setcost(20)
e2function fsensor fsensor:copyFSensor()
	return makeFSensor(this.Ent, this.Pos, this.Dir, this.Len)
end

__e2setcost(3)
e2function fsensor fsensor:addIgnoreEntityHit(entity vE)
	if(not this) then return nil end
	if(not isEntity(vE))) then return nil end
	this.Ign[vE] = true; return this
end

__e2setcost(3)
e2function fsensor fsensor:remIgnoreEntityHit(entity vE)
	if(not this) then return nil end
	if(not isEntity(vE))) then return nil end
	this.Ign[vE] = false; return this
end

__e2setcost(3)
e2function fsensor fsensor:addClassHit(string sC)
	if(not this) then return nil end
	this.Cls[sC] = true; return this
end

__e2setcost(3)
e2function fsensor fsensor:remClassHit(string sC)
	if(not this) then return nil end
	this.Cls[sC] = false; return this
end

__e2setcost(3)
e2function entity fsensor:getAttachEntity()
	if(not this) then return nil end; local vE = this.Ent
	if(not isEntity(vE))) then return nil end; return vE
end

__e2setcost(3)
e2function fsensor fsensor:setAttachEntity(entity eE)
	if(not this) then return nil end; local vE = this.Ent
	if(not isEntity(eE))) then return this end
	if(isEntity(vE)) then this.Ign[vE] = false end
	this.Ent = eE; this.Ign[eE] = true; return this
end

__e2setcost(3)
e2function number fsensor:getIgnoreWorld()
	if(not this) then return 0 end
	return (this.TrI.ignoreworld or 0)
end

__e2setcost(3)
e2function fsensor fsensor:setIgnoreWorld(number nN)
	if(not this) then return nil end
	this.TrI.ignoreworld = (nN ~= 0); return this
end

__e2setcost(3)
e2function vector fsensor:getOrigin()
	if(not this) then return {0,0,0} end
	return {this.Pos[1], this.Pos[2], this.Pos[3]}
end

__e2setcost(3)
e2function vector fsensor:getOriginLocal()
	return convFSensorOrgEnt(this, "WorldToLocal", nil)
end

__e2setcost(3)
e2function vector fsensor:getOriginWorld()
	return convFSensorOrgEnt(this, "LocalToWorld", nil)
end

__e2setcost(3)
e2function vector fsensor:getOriginLocal(entity vE)
	return convFSensorOrgEnt(this, "WorldToLocal", vE)
end

__e2setcost(3)
e2function vector fsensor:getOriginWorld(entity vE)
	return convFSensorOrgEnt(this, "LocalToWorld", vE)
end

__e2setcost(7)
e2function vector fsensor:getOriginLocal(vector vP, angle vA)
	return convFSensorOrgUCS(this, "WorldToLocal", vP, vA)
end

__e2setcost(7)
e2function vector fsensor:getOriginWorld(vector vP, angle vA)
	return convFSensorOrgUCS(this, "LocalToWorld", vP, vA)
end

__e2setcost(3)
e2function fsensor fsensor:setOrigin(vector vO)
	if(not this) then return nil end
	this.Pos[1], this.Pos[2], this.Pos[3] = vO[1], vO[2], vO[3]
	return this
end

__e2setcost(3)
e2function vector fsensor:getDirection()
	if(not this) then return nil end
	return {this.Dir[1], this.Dir[2], this.Dir[3]}
end

__e2setcost(3)
e2function vector fsensor:getDirectionLocal()
	return convFSensorDirLocal(this, nil, nil)
end

__e2setcost(3)
e2function vector fsensor:getDirectionWorld()
	return convFSensorDirWorld(this, nil, nil)
end

__e2setcost(3)
e2function vector fsensor:getDirectionLocal(entity vE)
	return convFSensorDirLocal(this, vE, nil)
end

__e2setcost(3)
e2function vector fsensor:getDirectionWorld(entity vE)
	return convFSensorDirWorld(this, vE, nil)
end

__e2setcost(3)
e2function vector fsensor:getDirectionLocal(angle vA)
	return convFSensorDirLocal(this, nil, vA)
end

__e2setcost(3)
e2function vector fsensor:getDirectionWorld(angle vA)
	return convFSensorDirWorld(this, nil, vA)
end

__e2setcost(3)
e2function fsensor fsensor:setDirection(vector vD)
	if(not this) then return nil end
	this.Dir[1], this.Dir[2], this.Dir[3] = vD[1], vD[2], vD[3]
	this.Dir:Normalize(); this.Dir:Mul(this.Len or 0)
	return this
end

__e2setcost(3)
e2function number fsensor:getLength()
	if(not this) then return nil end
	return (this.Len or 0)
end

__e2setcost(3)
e2function fsensor fsensor:setLength(number nL)
	if(not this) then return nil end
	this.Len = mathClamp(nL,-gnMaxLen,gnMaxLen)
	this.Dir:Normalize(); this.Dir:Mul(this.Len)
	this.Len = mathAbs(this.Len); return this
end

__e2setcost(3)
e2function number fsensor:getMask()
	if(not this) then return 0 end
	return (this.TrI.mask or 0)
end

__e2setcost(3)
e2function fsensor fsensor:setMask(number nN)
	if(not this) then return nil end
	this.TrI.mask = nN; return this
end

__e2setcost(3)
e2function number fsensor:getCollisionGroup()
	if(not this) then return nil end
	return (this.TrI.collisiongroup or 0)
end

__e2setcost(3)
e2function fsensor fsensor:setCollisionGroup(number nN)
	if(not this) then return nil end
	this.TrI.collisiongroup = nN; return this
end

__e2setcost(12)
e2function fsensor fsensor:smpLocal()
	if(not this) then return nil end; local entLoc = this.Ent
	if(not isEntity(entLoc))) then return this end
	local entAng, trData = entLoc:GetAngles(), this.TrI
	trData.start:Set(this.Pos)
	trData.start:Rotate(entAng)
	trData.start:Add(entLoc:GetPos())
	trData.endpos:Set(this.Dir)
	trData.endpos:Rotate(entAng)
	trData.endpos:Add(trData.start)
	-- http://wiki.garrysmod.com/page/util/TraceLine
	utilTraceLine(trData); return this
end

__e2setcost(8)
e2function fsensor fsensor:smpWorld()
	if(not this) then return nil end
	local trData = this.TrI
	trData.start:Set(this.Pos)
	trData.endpos:Set(this.Dir)
	trData.endpos:Add(trData.start)
	-- http://wiki.garrysmod.com/page/util/TraceLine
	utilTraceLine(trData); return this
end

__e2setcost(3)
e2function number fsensor:isHitNoDraw()
	if(not this) then return 0 end
	local trV = this.TrO.HitNoDraw
	return (trV and 1 or 0)
end

__e2setcost(3)
e2function number fsensor:isHitNonWorld()
	if(not this) then return 0 end
	local trV = this.TrO.HitNonWorld
	return (trV and 1 or 0)
end

__e2setcost(3)
e2function number fsensor:isHit()
	if(not this) then return 0 end
	local trV = this.TrO.Hit
	return (trV and 1 or 0)
end

__e2setcost(3)
e2function number fsensor:isHitSky()
	if(not this) then return 0 end
	local trV = this.TrO.HitSky
	return (trV and 1 or 0)
end

__e2setcost(3)
e2function number fsensor:isHitWorld()
	if(not this) then return 0 end
	local trV = this.TrO.HitWorld
	return (trV and 1 or 0)
end

__e2setcost(3)
e2function number fsensor:getHitBox()
	if(not this) then return 0 end
	local trV = this.TrO.HitBox
	return (trV and trV or 0)
end

__e2setcost(3)
e2function number fsensor:getMatType()
	if(not this) then return 0 end
	local trV = this.TrO.MatType
	return (trV and trV or 0)
end

__e2setcost(3)
e2function number fsensor:getHitGroup()
	if(not this) then return 0 end
	local trV = this.TrO.HitGroup
	return (trV and trV or 0)
end

__e2setcost(8)
e2function vector fsensor:getHitPos()
	if(not this) then return {0,0,0} end
	local trV = this.TrO.HitPos
	return (trV and {trV[1], trV[2], trV[3]} or {0,0,0})
end

__e2setcost(8)
e2function vector fsensor:getHitNormal()
	if(not this) then return {0,0,0} end
	local trV = this.TrO.HitNormal
	return (trV and {trV[1], trV[2], trV[3]} or {0,0,0})
end

__e2setcost(8)
e2function vector fsensor:getNormal()
	if(not this) then return {0,0,0} end
	local trV = this.TrO.Normal
	return (trV and {trV[1], trV[2], trV[3]} or {0,0,0})
end

__e2setcost(8)
e2function string fsensor:getHitTexture()
	if(not this) then return "" end
	local trV = this.TrO.HitTexture
	return tostring(trV or "")
end

__e2setcost(8)
e2function vector fsensor:getStartPos()
	if(not this) then return {0,0,0} end
	local trV = this.TrO.StartPos
	return (trV and {trV[1], trV[2], trV[3]} or {0,0,0})
end

__e2setcost(3)
e2function number fsensor:getSurfaceProps()
	if(not this) then return 0 end
	local trV = this.TrO.SurfaceProps
	return (trV and trV or 0)
end

__e2setcost(3)
e2function string fsensor:getSurfacePropsName()
	if(not this) then return "" end
	local trV = this.TrO.SurfaceProps
	return (trV and utilGetSurfacePropName(trV) or "")
end

__e2setcost(3)
e2function number fsensor:getPhysicsBone()
	if(not this) then return 0 end
	local trV = this.TrO.PhysicsBone
	return (trV and trV or 0)
end

__e2setcost(3)
e2function number fsensor:getFraction()
	if(not this) then return 0 end
	local trV = this.TrO.Fraction
	return (trV and trV or 0)
end

__e2setcost(3)
e2function number fsensor:getFractionLength()
	if(not this) then return 0 end
	local trV = this.TrO.Fraction
	return (trV and (trV * this.Len) or 0)
end

__e2setcost(3)
e2function number fsensor:isStartSolid()
	if(not this) then return 0 end
	local trV = this.TrO.StartSolid
	return (trV and 1 or 0)
end

__e2setcost(3)
e2function number fsensor:isAllSolid()
	if(not this) then return 0 end
	local trV = this.TrO.AllSolid
	return (trV and 1 or 0)
end

__e2setcost(3)
e2function number fsensor:getFractionLeftSolid()
	if(not this) then return 0 end
	local trV = this.TrO.FractionLeftSolid
	return (trV and trV or 0)
end

__e2setcost(3)
e2function number fsensor:getFractionLeftSolidLength()
	if(not this) then return 0 end
	local trV = this.TrO.FractionLeftSolid
	return (trV and (trV * this.Len) or 0)
end

__e2setcost(3)
e2function entity fsensor:getEntity()
	if(not this) then return nil end
	local trV = this.TrO.Entity
	return (trV and trV or nil)
end
