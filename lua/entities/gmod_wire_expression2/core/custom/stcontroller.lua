/******************************************************************************\
  My custom state LQ-PID controller type handling process variables
\******************************************************************************/

-- Register the type up here before the extension registration so that the state controller still works
registerType("stcontroller", "xsc", nil,
	nil,
	nil,
	function(retval)
		if(retval == nil) then return end
		if(not istable(retval)) then error("Return value is neither nil nor a table, but a "..type(retval).."!",0) end
	end,
	function(v)
		return (not istable(v))
	end
)

/******************************************************************************/

E2Lib.RegisterExtension("stcontroller", true, "Lets E2 chips have dedicated state controller objects")

local getTime = SysTime

local function getSign(nV) return ((nV > 0 and 1) or (nV < 0 and -1) or 0) end
local function getValue(kV,eV,pV) return (kV*getSign(eV)*math.abs(eV)^pV) end

local function makeSControl()
  local oStCon = {}; oStCon.mType = {"",""} -- Place to store the object
  oStCon.mTimN = getTime(); oStCon.mTimO = oStCon.mTimN; -- Reset clock
  oStCon.mErrO, oStCon.mErrN = 0, 0     -- Error state values
  oStCon.mvCon, oStCon.mTimB, oStCon.meInt = 0, 0, true  -- Control value and integral enabled
  oStCon.mBias, oStCon.mSatD, oStCon.mSatU = 0, nil, nil -- Saturation limits and settings
  oStCon.mvP  , oStCon.mvI  , oStCon.mvD   = 0, 0, 0 -- Term values
  oStCon.mkP  , oStCon.mkI  , oStCon.mkD   = 0, 0, 0 -- P, I and D term gains
  oStCon.mpP  , oStCon.mpI  , oStCon.mpD   = 1, 1, 1 -- Raise the error to power of that much
  oStCon.mbCmb, oStCon.mbInv, oStCon.mbOn = true, false, true
  return oStCon
end

--[[ **************************** CONTROLLER **************************** ]]

registerOperator("ass", "xsc", "xsc", function(self, args)
	local lhs, op2, scope = args[2], args[3], args[4]
	local      rhs = op2[1](self, op2)
	self.Scopes[scope][lhs] = rhs
	self.Scopes[scope].vclk[lhs] = true
	return rhs
end)

__e2setcost(1)
e2function stcontroller noSControl()
	return nil
end

__e2setcost(20)
e2function stcontroller newSControl()
  return makeSControl()
end

__e2setcost(7) -- Kp, Ti, Td
e2function stcontroller stcontroller:setGains(nP, nI, nD)
  if(not this) then return nil end
  if(nP <= 0) then return nil end; this.mType[2] = "P"; this.mkP = nP
  if(nI > 0) then this.mkI, this.mType[2] = (nI / 2), (this.mType[2].."I")
    if(this.mbCmb) then this.mkI = this.mkI * this.mkP end
  end
  if(nD > 0) then this.mkD, this.mType[2] = nD, (this.mType[2].."D")
    if(this.mbCmb) then this.mkD = this.mkD * this.mkP end
  end; return this
end

__e2setcost(3)
e2function array stcontroller:getGains()
  if(not this) then return {0,0,0} end
  return {this.mkP, this.mkI, this.mkD}
end

__e2setcost(3)
e2function stcontroller stcontroller:setBias(nN)
  if(not this) then return nil end
  this.mBias = nN; return this
end

__e2setcost(3)
e2function number stcontroller:getBias(nN)
  if(not this) then return 0 end
  return this.mBias
end

__e2setcost(3)
e2function string stcontroller:getType()
  if(not this) then return "" end
  return table.concat(this.mType)
end

__e2setcost(3)
e2function stcontroller stcontroller:setWindup(nD, nU)
  if(not this) then return nil end
  if(nD < nU) then this.mSatD, this.mSatU = nD, nU end 
  return this
end

__e2setcost(3)
e2function stcontroller stcontroller:remWindup()
  if(not this) then return nil end
  this.mSatD, this.mSatU = nil, nil; return this
end

__e2setcost(3)
e2function stcontroller stcontroller:setWindupD(nD)
  if(not this) then return nil end
  this.mSatD = nD; return this
end

__e2setcost(3)
e2function stcontroller stcontroller:getWindupD(nD)
  if(not this) then return nil end
  return (this.mSatD or 0)
end

__e2setcost(3)
e2function stcontroller stcontroller:remWindupD(nD)
  if(not this) then return nil end
  this.mSatD = nil; return this
end

__e2setcost(3)
e2function stcontroller stcontroller:setWindupU(nU)
  if(not this) then return nil end
  this.mSatU = nU; return this
end

__e2setcost(3)
e2function stcontroller stcontroller:getWindupU(nU)
  if(not this) then return nil end
  return (this.mSatU or 0)
end

__e2setcost(3)
e2function stcontroller stcontroller:remWindupU(nU)
  if(not this) then return nil end
  this.mSatU = nil; return this
end

__e2setcost(8)
e2function stcontroller stcontroller:setPower(nP, nI, nD)
  if(not this) then return nil end
  this.mpP, this.mpI, this.mpD = nP, nI, nD
  local bP, bI, bD = (nP ~= 1), (nI ~= 1), (nD ~= 1)
  if(bP or bI or bD) then 
    this.mType[1] = ("LQ(%s%s%s)-"):format(
      bP and "P" or "", bI and "I" or "", bD and "D" or "")
  end; return this
end

__e2setcost(3)
e2function array stcontroller:getPower()
  if(not this) then return {0,0,0} end
  return {this.mpP, this.mpI, this.mpD}
end

__e2setcost(3)
e2function number stcontroller:getError()
  if(not this) then return 0 end
  return this.mErrN
end

__e2setcost(3)
e2function number stcontroller:getErrorDelta()
  if(not this) then return 0 end
  return (this.mErrN - this.mErrO)
end

__e2setcost(3)
e2function number stcontroller:getTime()
  if(not this) then return 0 end
  return this.mTimN
end

__e2setcost(3)
e2function number stcontroller:getTimeDelta()
  if(not this) then return 0 end
  return (this.mTimN - this.mTimO)
end

__e2setcost(3)
e2function number stcontroller:getTimeBench()
  if(not this) then return nil end
  return (this.mTimB or 0)
end

__e2setcost(3)
e2function number stcontroller:getTimeRatio()
  if(not this) then return nil end
  return (this.mTimB or 0) / (this.mTimN - this.mTimO))
end

__e2setcost(3)
e2function stcontroller stcontroller:setFlagIntegral(number nN)
  if(not this) then return nil end
  this.meInt = (nN ~= 0); return this
end

__e2setcost(3)
e2function number stcontroller:getFlagIntegral()
  if(not this) then return nil end
  return (this.meInt and 1 or 0)
end

__e2setcost(3)
e2function stcontroller stcontroller:setCombined(number nN)
  if(not this) then return nil end
  this.mbCmb = (nN ~= 0); return this
end

__e2setcost(3)
e2function number stcontroller:getCombined()
  if(not this) then return nil end
  return (this.mbCmb and 1 or 0)
end

__e2setcost(3)
e2function stcontroller stcontroller:setInverted(number nN)
  if(not this) then return nil end
  this.mbInv = (nN ~= 0); return this
end

__e2setcost(3)
e2function number stcontroller:getInverted()
  if(not this) then return nil end
  return (this.mbInv and 1 or 0)
end

__e2setcost(3)
e2function stcontroller stcontroller:setToggle(number nN)
  if(not this) then return nil end
  this.mbOn = (nN ~= 0); return this
end

__e2setcost(3)
e2function number stcontroller:getToggle()
  if(not this) then return nil end
  return (this.mbOn and 1 or 0)
end

__e2setcost(3)
e2function number stcontroller:getControl()
  if(not this) then return nil end
  return (this.mvCon or 0)
end

__e2setcost(3)
e2function stcontroller stcontroller:resState()
  if(not this) then return nil end
  this.mErrO, this.mErrN = 0, 0 -- Reset the error
  this.mvCon, this.meInt = 0, true  -- Control value and integral enabled
  this.mvP, this.mvI, this.mvD = 0, 0, 0 -- Term values
  this.mTimN = getTime(); this.mTimO = this.mTimN; -- Reset clock
  return this
end

__e2setcost(20)
e2function stcontroller stcontroller:setState(number nR, number nY)
  if(not this) then return nil end
  if(not this.mbOn) then
    this.mErrO, this.mErrN = 0, 0 -- Reset the error
    this.mvCon, this.meInt = 0, true  -- Control value and integral enabled
    this.mvP, this.mvI, this.mvD = 0, 0, 0 -- Term values
    this.mTimN = getTime(); this.mTimO = this.mTimN; -- Reset clock
  else this.mTimN = getTime()
    this.mErrN  = (this.mbInv and (nY-nR) or (nR-nY))
    local timDt = (this.mTimN - this.mTimO)
    if(this.mkP > 0) then -- P-Term
      this.mvP = getValue(this.mkP, this.mErrN, this.mpP) end
    if((this.mkI > 0) and (this.mErrN ~= 0) and this.meInt) then -- I-Term
      local arInt = (this.mErrN + this.mErrO) * timDt -- The current integral value
      this.mvI = getValue(this.mkI * timDt, arInt, this.mpI) + this.mvI end
    if((this.mkD > 0) and (this.mErrN ~= this.mErrO) and (timDt ~= 0)) then -- D-Term
      local arDif = (this.mErrN - this.mErrO) / timDt -- Derivative dY/dT
      this.mvD = getValue(this.mkD * timDt, arDif, this.mpD) end
    this.mvCon = this.mvP + this.mvI + this.mvD         -- Calculate the control signal
    if(this.mSatD and this.mvCon < this.mSatD) then     -- Satuarate lower limit
      this.mvCon, this.meInt = this.mSatD, false        -- Integral is disabled
    elseif(this.mSatU and this.mvCon > this.mSatU) then -- Satuarate upper limit
      this.mvCon, this.meInt = this.mSatU, false        -- Integral is disabled
    else this.meInt = true end -- Saturation disables the integrator
    this.mvCon = (this.mvCon + this.mBias) -- Apply the saturated signal bias
    this.mTimB = (getTime() - this.mTimN)  -- Benchmark the process
    this.mTimO, this.mErrO = this.mTimN, this.mErrN -- Prepare for the next iteration
  end; return this
end

__e2setcost(15)
e2function stcontroller stcontroller:dumpConsole(string sI)
  print("["..sI.."]["..table.concat(this.mType).."] Properties:")
  print("  Gains: {P="..tostring(this.mkP)  ..", I=" ..tostring(this.mkI)  ..", D="..tostring(this.mkD).."}")
  print("  Power: {P="..tostring(this.mpP)  ..", I=" ..tostring(this.mpI)  ..", D="..tostring(this.mpD).."}")
  print("  Limit: {D="..tostring(this.mSatD)..", U=" ..tostring(this.mSatU).."}")
  print("  Error: {O="..tostring(this.mErrO)..", N=" ..tostring(this.mErrN).."}")
  print("  Value: ["  ..tostring(this.mvCon).."] {P="..tostring(this.mvP)  ..", I="
                      ..tostring(this.mvI)  ..", D=" ..tostring(this.mvD)  .."}")
  return this -- The dump method
end
