--[[ ******************************************************************************
 My custom state LQ-PID control type handling process variables
****************************************************************************** ]]--

local pairs        = pairs
local tostring     = tostring
local tonumber     = tonumber
local getmetatable = getmetatable
local CreateConVar = CreateConVar
local bitBor       = bit.bor
local mathAbs      = math.abs
local mathModf     = math.modf
local tableConcat  = table.concat
local tableInsert  = table.insert
local tableRemove  = table.remove
local getTime      = CurTime -- Using this as time benchmarking supporting game pause

-- Register the type up here before the extension registration so that the state control still works
registerType("stcontrol", "xsc", nil,
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

--[[ ****************************************************************************** ]]

E2Lib.RegisterExtension("stcontrol", true, "Lets E2 chips have dedicated state control objects")

-- Client and server have independent value
local gnIndependentUsed = bitBor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_PRINTABLEONLY)
-- Server tells the client what value to use
local gnServerControled = bitBor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_PRINTABLEONLY, FCVAR_REPLICATED)

local gtComponent = {"P", "I", "D"} -- The names of each term. This is used for indexing and checking
local gsFormatPID = "(%s%s%s)" -- The general type format for the control power setup
local gtMissName  = {"Xx", "X", "Nr"} -- This is a place holder for missing/default type
local gtStoreOOP  = {} -- Store state controllers here linked to the entity of the E2
local gsVarPrefx  = "wire_expression2_stcontrol" -- This is used for variable prefix
local gtStringMT  = getmetatable(gsVarPrefx) -- Store the string metatable
local varMaxTotal = CreateConVar(gsVarPrefx.."_max" , 20, gnServerControled, "StControl items maximum count")
local varEnStatus = CreateConVar(gsVarPrefx.."_enst",  0, gnIndependentUsed, "Enables status output messages")
local gsDefPrint  = "TALK" -- Default print location
local gtPrintName = {} -- Contains the print location specification
      gtPrintName["NOTIFY" ] = HUD_PRINTNOTIFY
      gtPrintName["CONSOLE"] = HUD_PRINTCONSOLE
      gtPrintName["TALK"   ] = HUD_PRINTTALK
      gtPrintName["CENTER" ] = HUD_PRINTCENTER

local function isEntity(vE)
  return (vE and vE:IsValid())
end

local function isHere(vV)
  return (vV ~= nil)
end

local function isString(vS)
  return (getmetatable(vS) == gtStringMT)
end

local function getSign(nV)
  return ((nV > 0 and 1) or (nV < 0 and -1) or 0)
end

local function getValue(kV,eV,pV)
  return (kV*getSign(eV)*mathAbs(eV)^pV)
end

local function remValue(tSrc, aKey)
  tSrc[aKey] = nil; return tSrc
end

local function logStatus(sMsg, oSelf, nPos, ...)
  if(varEnStatus:GetBool()) then
    local nPos = tonumber(nPos) or gtPrintName[gsDefPrint]
    local oPly, oEnt = oSelf.player, oSelf.entity
    local sNam, sEID = oPly:Nick() , tostring(oEnt:EntIndex())
    local sTxt = "E2{"..sEID.."}{"..sNam.."}:stcontrol:"..tostring(sMsg)
    oPly:PrintMessage(nPos, sTxt:sub(1, 200))
  end; return ...
end

local function getControllersCount() local mC = 0
  for ent, con in pairs(gtStoreOOP) do mC = mC + #con end; return mC
end

local function remControllersEntity(eChip)
  if(not isEntity(eChip)) then return end
  local tCon = gtStoreOOP[eChip]; if(not next(tCon)) then return end
  local mCon = #tCon; for ID = 1, mCon do tableRemove(tCon) end
end

local function setGains(oStCon, oSelf, vP, vI, vD, bZ)
  if(not oStCon) then return logStatus("Object missing", oSelf, nil, nil) end
  local nP, nI = (tonumber(vP) or 0), (tonumber(vI) or 0)
  local nD, sT = (tonumber(vD) or 0), "" -- Store control type
  if(vP and ((nP > 0) or (bZ and nP >= 0))) then oStCon.mkP = nP end
  if(vI and ((nI > 0) or (bZ and nI >= 0))) then oStCon.mkI = (nI / 2)
    if(oStCon.mbCmb) then oStCon.mkI = oStCon.mkI * oStCon.mkP end
  end -- Available settings with non-zero coefficients
  if(vD and ((nD > 0) or (bZ and nD >= 0))) then oStCon.mkD = nD
    if(oStCon.mbCmb) then oStCon.mkD = oStCon.mkD * oStCon.mkP end
  end -- Build control type
  for key, val in pairs(gtComponent) do
    if(oStCon["mk"..val] > 0) then sT = sT..val end end
  if(sT:len() == 0) then sT = gtMissName[2]:rep(3) end -- Check for invalid control
  oStCon.mType[2] = sT; collectgarbage(); return oStCon
end

local function getCode(nN)
  local nW, nF = mathModf(nN, 1)
  if(nN == 1) then return gtMissName[3] end -- [Natural conventional][y=k*x]
  if(nN ==-1) then return "Rr" end -- [Reciprocal relation][y=1/k*x]
  if(nN == 0) then return "Sr" end -- [Sign function relay term][y=k*sign(x)]
  if(nF ~= 0) then
    if(nW ~= 0) then
      if(nF > 0) then return "Gs" end -- [Power positive fractional][y=x^( n); n> 1]
      if(nF < 0) then return "Gn" end -- [Power negative fractional][y=x^(-n); n<-1]
    else
      if(nF > 0) then return "Fs" end -- [Power positive fractional][y=x^( n); 0<n< 1]
      if(nF < 0) then return "Fn" end -- [Power negative fractional][y=x^(-n); 0>n>-1]
    end
  else
    if(nN > 0) then return "Ex" end -- [Exponential relation][y=x^n]
    if(nN < 0) then return "Er" end -- [Reciprocal-exp relation][y=1/x^n]
  end; return gtMissName[1] -- [Invalid settings][N/A]
end

local function setPower(oStCon, oSelf, vP, vI, vD)
  if(not oStCon) then return logStatus("Object missing", oSelf, nil, nil) end
  oStCon.mpP, oStCon.mpI, oStCon.mpD = (tonumber(vP) or 1), (tonumber(vI) or 1), (tonumber(vD) or 1)
  oStCon.mType[1] = gsFormatPID:format(getCode(oStCon.mpP), getCode(oStCon.mpI), getCode(oStCon.mpD))
  return oStCon
end

local function resState(oStCon, oSelf)
  if(not oStCon) then return logStatus("Object missing", oSelf, nil, nil) end
  oStCon.mErrO, oStCon.mErrN = 0, 0 -- Reset the error
  oStCon.mvCon, oStCon.meInt = 0, true -- Control value and integral enabled
  oStCon.mvP, oStCon.mvI, oStCon.mvD = 0, 0, 0 -- Term values
  oStCon.mTimN = getTime(); oStCon.mTimO = oStCon.mTimN; -- Update clock
  return oStCon
end

local function getType(oStCon)
  if(not oStCon) then local mP, mT = gtMissName[1], gtMissName[2]
    return (gsFormatPID:format(mP,mP,mP).."-"..mT:rep(3))
  end; return tableConcat(oStCon.mType, "-")
end

local function dumpItem(oStCon, oSelf, sNam, sPos)
  local sP = tostring(sPos or gsDefPrint)
  local nP = gtPrintName[sP] -- Print location setup
  if(not isHere(nP)) then return oStCon end
  logStatus("["..tostring(sNam).."]["..tostring(oStCon.mnTo or gtMissName[2]).."]["..getType(oStCon).."]["..tostring(oStCon.mTimN).."] Data:", oSelf, nP)
  logStatus(" Human: ["..tostring(oStCon.mbMan).."] {V="..tostring(oStCon.mvMan)..", B="..tostring(oStCon.mBias).."}", oSelf, nP)
  logStatus(" Gains: {P="..tostring(oStCon.mkP)..", I="..tostring(oStCon.mkI)..", D="..tostring(oStCon.mkD).."}", oSelf, nP)
  logStatus(" Power: {P="..tostring(oStCon.mpP)..", I="..tostring(oStCon.mpI)..", D="..tostring(oStCon.mpD).."}", oSelf, nP)
  logStatus(" Limit: {D="..tostring(oStCon.mSatD)..", U="..tostring(oStCon.mSatU).."}", oSelf, nP)
  logStatus(" Error: {O="..tostring(oStCon.mErrO)..", N="..tostring(oStCon.mErrN).."}", oSelf, nP)
  logStatus(" Value: ["..tostring(oStCon.mvCon).."] {P="..tostring(oStCon.mvP)..", I="..tostring(oStCon.mvI)..", D=" ..tostring(oStCon.mvD).."}", oSelf, nP)
  logStatus(" Flags: ["..tostring(oStCon.mbOn).."] {C="..tostring(oStCon.mbCmb)..", R=" ..tostring(oStCon.mbInv)..", I="..tostring(oStCon.meInt).."}", oSelf, nP)
  return oStCon -- The dump method
end

local function newItem(oSelf, nTo)
  local eChip = oSelf.entity; if(not isEntity(eChip)) then
    return logStatus("Entity invalid", oSelf, nil, nil) end
  local nTot, nMax = getControllersCount(), varMaxTotal:GetInt()
  if(nMax <= 0) then remControllersEntity(eChip)
    return logStatus("Limit invalid ["..tostring(nMax).."]", oSelf, nil, nil) end
  if(nTot >= nMax) then remControllersEntity(eChip)
    return logStatus("Count reached ["..tostring(nMax).."]", oSelf, nil, nil) end
  local oStCon, sM = {}, gtMissName[3]; oStCon.mnTo = tonumber(nTo) -- Place to store the object
  if(oStCon.mnTo and oStCon.mnTo <= 0) then remControllersEntity(eChip)
    return logStatus("Delta mismatch ["..tostring(oStCon.mnTo).."]", oSelf, nil, nil) end
  local sT, tCon = gsFormatPID:format(sM, sM, sM), gtStoreOOP[eChip]
  if(not tCon) then gtStoreOOP[eChip] = {}; tCon = gtStoreOOP[eChip] end
  oStCon.mTimN = getTime(); oStCon.mTimO = oStCon.mTimN; -- Reset clock
  oStCon.mErrO, oStCon.mErrN, oStCon.mType = 0, 0, {sT, gtMissName[2]:rep(3)} -- Error state values
  oStCon.mvCon, oStCon.mTimB, oStCon.meInt = 0, 0, true -- Control value and integral enabled
  oStCon.mBias, oStCon.mSatD, oStCon.mSatU = 0, nil, nil -- Saturation limits and settings
  oStCon.mvP, oStCon.mvI, oStCon.mvD = 0, 0, 0 -- Term values
  oStCon.mkP, oStCon.mkI, oStCon.mkD = 0, 0, 0 -- P, I and D term gains
  oStCon.mpP, oStCon.mpI, oStCon.mpD = 1, 1, 1 -- Raise the error to power of that much
  oStCon.mbCmb, oStCon.mbInv, oStCon.mbOn, oStCon.mbMan = false, false, false, false
  oStCon.mvMan, oStCon.mSet = 0, eChip -- Configure manual mode and store indexing
  eChip:CallOnRemove("stcontrol_remove_ent", remControllersEntity)
  tableInsert(tCon, oStCon); collectgarbage(); return oStCon
end

--[[
 * Tunes a controller using the Ziegler-Nichols method
 * When `bP` is true, then 3-parameter model is used
 * otherwise P-controller is hooked to the plant and uK, uT (no model)
 * are obtained from the output. The value `sM` is a additional
 * tunning option for a PID controller.
]]
local function tuneZieglerNichols(oStCon, oSelf, uK, uT, uL, sM, bP)
  if(not oStCon) then return logStatus("Object missing", oSelf, nil, nil) end
  local sM, sT = tostring(sM or "classic"), oStCon.mType[2]
  local uK, uT = (tonumber(uK) or 0), (tonumber(uT) or 0)
  if(bP) then if(uT <= 0 or uL <= 0) then return oStCon end
    if(sT == "P") then return setGains(oStCon, oSelf, (uT/uL), 0, 0, true)
    elseif(sT == "PI") then return setGains(oStCon, oSelf, (0.9*(uT/uL)), (0.3/uL), 0, true)
    elseif(sT == "PD") then return setGains(oStCon, oSelf, (1.1*(uT/uL)), 0, (0.8/uL), true)
    elseif(sT == "PID") then return setGains(oStCon, oSelf, (1.2*(uT/uL)), 1/(2*uL), 2/uL)
    else return logStatus("Type mismatch <"..sT..">", oSelf, nil, oStCon) end
  else if(uK <= 0 or uT <= 0) then return oStCon end
    if(sT == "P") then return setGains(oStCon, oSelf, (0.5*uK), 0, 0, true)
    elseif(sT == "PI") then return setGains(oStCon, oSelf, (0.45*uK), (1.2/uT), 0, true)
    elseif(sT == "PD") then return setGains(oStCon, oSelf, (0.80*uK), 0, (uT/8), true)
    elseif(sT == "PID") then
      if(sM == "classic") then return setGains(oStCon, oSelf, 0.60 * uK, 2.0 / uT, uT / 8.0)
      elseif(sM == "pessen" ) then return setGains(oStCon, oSelf, (7*uK)/10, 5/(2*uT), (3*uT)/20)
      elseif(sM == "sovers") then return setGains(oStCon, oSelf, (uK/3), (2/uT), (uT/3))
      elseif(sM == "novers") then return setGains(oStCon, oSelf, (uK/5), (2/uT), (uT/3))
      else return logStatus("Method mismatch <"..sM..">", oSelf, nil, oStCon) end
    else return logStatus("Type mismatch <"..sT..">", oSelf, nil, oStCon) end
  end; return oStCon
end

--[[
 * Tunes a controller using the Choen-Coon method
 * Three parameter model: Gain nK, Time nT, Delay nL
]]
local function tuneChoenCoon(oStCon, oSelf, nK, nT, nL)
  if(not oStCon) then return logStatus("Object missing", oSelf, nil, nil) end
  if(nK <= 0 or nT <= 0 or nL <= 0) then return oStCon end
  local sT, mT = oStCon.mType[2], (nL/nT)
  if(sT == "P") then
    local kP = (1/(nK*mT))*(1+(1/3)*mT)
    return setGains(oStCon, oSelf, kP, 0, 0, true)
  elseif(sT == "PI") then
    local kP = (1/(nK*mT))*(9/10+(1/12)*mT)
    local kI = 1/(nL*((30+3*mT)/(9+20*mT)))
    return setGains(oStCon, oSelf, kP, kI, 0, true)
  elseif(sT == "PD") then
    local kP = (1/(nK*mT))*(5/4+(1/6)*mT)
    local kD = nL*((6-2*mT)/(22+3*mT))
    return setGains(oStCon, oSelf, kP, 0, kD, true)
  elseif(sT == "PID") then
    local kP = (1/(nK*mT))*(4/3+(1/4)*mT)
    local kI = 1/(nL*((32+6*mT)/(13+8*mT)))
    local kD = nL*(4/(11+2*mT))
    return setGains(oStCon, oSelf, kP, kI, kD)
  else return logStatus("Type mismatch <"..sT..">", oSelf, nil, oStCon) end
end

--[[
 * Tunes a controller using the Chien-Hrones-Reswick (CHR) method
 * Three parameter model: Gain nK, Time nT, Delay nL
 * The flag `bM` if enabled tuning is done for 20% overshot
 * The flag `bR` if enabled tuning is done for load rejection
 * else the tuning is done for set point tracking
]]
local function tuneChienHronesReswick(oStCon, oSelf, nK, nT, nL, bM, bR)
  if(not oStCon) then return logStatus("Object missing", oSelf, nil, nil) end
  if(nK <= 0 or nT <= 0 or nL <= 0) then return oStCon end
  local mA, sT = (nK * nL / nT), oStCon.mType[2]
  if(bR) then -- Load rejection
    if(bM) then -- Overshoot 20%
      if(sT == "P") then return setGains(oStCon, oSelf, 0.7/mA, 0, 0, true)
      elseif(sT == "PI") then return setGains(oStCon, oSelf, (0.7/mA), (1/(2.3*nT)), 0, true)
      elseif(sT == "PD") then return setGains(oStCon, oSelf, (0.82/mA), 0, (0.5*uL), true)
      elseif(sT == "PID") then return setGains(oStCon, oSelf, (1.2/mA), 1/(2*nT), 0.42*uL)
      else return logStatus("Type mismatch <"..sT..">", oSelf, nil, oStCon) end
    else
      if(sT == "P") then return setGains(oStCon, oSelf, (0.3/mA), 0, 0, true)
      elseif(sT == "PI") then return setGains(oStCon, oSelf, (0.6/mA), (1/(4*nT)), 0, true)
      elseif(sT == "PD") then return setGains(oStCon, oSelf, (0.75/mA), 0, (0.5*uL), true)
      elseif(sT == "PID") then return setGains(oStCon, oSelf, (0.95/mA), (1/(2.4*nT)), (0.42*uL))
      else return logStatus("Type mismatch <"..sT..">", oSelf, nil, oStCon) end
    end
  else -- Set point tracking
    if(bM) then -- Overshoot 20%
      if(sT == "P") then return setGains(oStCon, oSelf, 0.7/mA, 0, 0, true)
      elseif(sT == "PI") then return setGains(oStCon, oSelf, (0.6/mA), 1/nT, 0, true)
      elseif(sT == "PD") then return setGains(oStCon, oSelf, (0.7/mA), 0, (0.45*uL), true)
      elseif(sT == "PID") then return setGains(oStCon, oSelf, (0.95/mA), 1/(1.4*nT), 0.47*uL)
      else return logStatus("Type mismatch <"..sT..">", oSelf, nil, oStCon) end
    else
      if(sT == "P") then return setGains(oStCon, oSelf, (0.3/mA), 0, 0, true)
      elseif(sT == "PI") then return setGains(oStCon, oSelf, (0.35/mA), (1/(1.2*nT)), 0, true)
      elseif(sT == "PD") then return setGains(oStCon, oSelf, (0.45/mA), 0, (0.45*uL), true)
      elseif(sT == "PID") then return setGains(oStCon, oSelf, (0.6/mA), (1/nT), (0.5*uL))
      else return logStatus("Type mismatch <"..sT..">", oSelf, nil, oStCon) end
    end
  end
end

--[[
 * Tunes a controller using the Astrom-Hagglund method
 * Three parameter model: Gain nK, Time nT, Delay nL
]]
local function tuneAstromHagglund(oStCon, oSelf, nK, nT, nL)
  if(not oStCon) then return logStatus("Object missing", oSelf, nil, nil) end
  if(nK <= 0 or nT <= 0 or nL <= 0) then return oStCon end
  local kP = (1/nK)*(0.2+0.45*(nT/nL))
  local kI = 1/(((0.4*nL+0.8*nT)/(nL+0.1*nT))*nL)
  local kD = (0.5*nL*nT)/(0.3*nL+nT)
  return setGains(oStCon, oSelf, kP, kI, kD)
end

--[[
 * Tunes a controller using the integral error method
 * Three parameter model: Gain nK, Time nT, Delay nL
]]
local tIE ={
  ISE  = {
    PI  = {1.305, -0.959, 0.492, 0.739, 0    , 0    },
    PID = {1.495, -0.945, 1.101, 0.771, 0.560, 1.006}
  },
  IAE  = {
    PI  = {0.984, -0.986, 0.608, 0.707, 0    , 0    },
    PID = {1.435, -0.921, 0.878, 0.749, 0.482, 1.137}
  },
  ITAE = {
    PI  = {0.859, -0.977, 0.674, 0.680, 0    , 0    },
    PID = {1.357, -0.947, 0.842, 0.738, 0.381, 0.995}
  }
}
local function tuneIE(oStCon, oSelf, nK, nT, nL, sM)
  if(not oStCon) then return logStatus("Object missing", oSelf, nil, nil) end
  if(nK <= 0 or nT <= 0 or nL <= 0) then return oStCon end
  local sM, sT, tT = tostring(sM or "ISE"), oStCon.mType[2], nil
  tT = tIE[sM]; if(not isHere(tT)) then
    return logStatus("Mode mismatch <"..sM..">", oSelf, nil, oStCon) end
  tT = tT[sT]; if(not isHere(tT)) then
    return logStatus("Type mismatch <"..sT..">", oSelf, nil, oStCon) end
  local A, B, C, D, E, F = unpack(tT)
  local kP = (A*(nL/nT)^B)/nK
  local kI = 1/((nT/C)*(nL/nT)^D)
  local kD = nT*E*(nL/nT)^F
  return setGains(oStCon, oSelf, kP, kI, kD)
end

--[[ **************************** CONTROLLER **************************** ]]

registerOperator("ass", "xsc", "xsc", function(self, args)
  local lhs, op2, scope = args[2], args[3], args[4]
  local rhs = op2[1](self, op2)
  self.Scopes[scope][lhs] = rhs
  self.Scopes[scope].vclk[lhs] = true
  return rhs
end)

__e2setcost(1)
e2function stcontrol noStControl()
  return nil
end

__e2setcost(20)
e2function stcontrol newStControl()
  return newItem(self)
end

__e2setcost(20)
e2function stcontrol newStControl(number nTo)
  return newItem(self, nTo)
end

__e2setcost(1)
e2function number maxStControls()
  return varMaxTotal:GetInt()
end

__e2setcost(1)
e2function number sumStControls()
  return getControllersCount()
end

__e2setcost(15)
e2function number stcontrol:remSelf()
  if(not this) then return 0 end
  local tSet = gtStoreOOP[this.mSet]
  if(not tSet) then return 0 end
  for ID = 1, #tSet do
    if(tSet[ID] == this) then
      tableRemove(tSet, ID)
      return ID -- Remove ID found
    end -- All other IDs
  end; return 0
end

__e2setcost(20)
e2function stcontrol stcontrol:getCopy()
  return newItem(self, this.mnTo)
end

__e2setcost(7)
e2function stcontrol stcontrol:setGainP(number nP)
  return setGains(this, self, nP, nil, nil)
end

__e2setcost(7)
e2function stcontrol stcontrol:setGainI(number nI)
  return setGains(this, self, nil, nI, nil)
end

__e2setcost(7)
e2function stcontrol stcontrol:setGainD(number nD)
  return setGains(this, self, nil, nil, nD)
end

__e2setcost(7)
e2function stcontrol stcontrol:setGainPI(number nP, number nI)
  return setGains(this, self, nP, nI, nil)
end

__e2setcost(7)
e2function stcontrol stcontrol:setGainPI(vector2 vV)
  return setGains(this, self, vV[1], vV[2], nil)
end

__e2setcost(7)
e2function stcontrol stcontrol:setGainPI(array aA)
  return setGains(this, self, aA[1], aA[2], nil)
end

__e2setcost(7)
e2function stcontrol stcontrol:setGainPD(number nP, number nD)
  return setGains(this, self, nP, nil, nD)
end

__e2setcost(7)
e2function stcontrol stcontrol:setGainPD(vector2 vV)
  return setGains(this, self, vV[1], nil, vV[2])
end

__e2setcost(7)
e2function stcontrol stcontrol:setGainPD(array aA)
  return setGains(this, self, aA[1], nil, aA[2])
end

__e2setcost(7)
e2function stcontrol stcontrol:setGainID(number nI, number nD)
  return setGains(this, self, nil, nI, nD)
end

__e2setcost(7)
e2function stcontrol stcontrol:setGainID(vector2 vV)
  return setGains(this, self, nil, vV[1], vV[2])
end

__e2setcost(7)
e2function stcontrol stcontrol:setGainID(array aA)
  return setGains(this, self, nil, aA[1], aA[2])
end

__e2setcost(7)
e2function stcontrol stcontrol:setGain(number nP, number nI, number nD)
  return setGains(this, self, nP, nI, nD)
end

__e2setcost(7)
e2function stcontrol stcontrol:setGain(array aA)
  return setGains(this, self, aA[1], aA[2], aA[3])
end

__e2setcost(7)
e2function stcontrol stcontrol:setGain(vector vV)
  return setGains(this, self, vV[1], vV[2], vV[3])
end

__e2setcost(7)
e2function stcontrol stcontrol:remGainP()
  return setGains(this, self, 0, nil, nil, true)
end

__e2setcost(7)
e2function stcontrol stcontrol:remGainI()
  return setGains(this, self, nil, 0, nil, true)
end

__e2setcost(7)
e2function stcontrol stcontrol:remGainD()
  return setGains(this, self, nil, nil, 0, true)
end

__e2setcost(7)
e2function stcontrol stcontrol:remGainPI()
  return setGains(this, self, 0, 0, nil, true)
end

__e2setcost(7)
e2function stcontrol stcontrol:remGainPD()
  return setGains(this, self, 0, nil, 0, true)
end

__e2setcost(7)
e2function stcontrol stcontrol:remGainID()
  return setGains(this, self, nil, 0, 0, true)
end

__e2setcost(7)
e2function stcontrol stcontrol:remGain()
  return setGains(this, self, 0, 0, 0, true)
end

__e2setcost(3)
e2function array stcontrol:getGain()
  if(not this) then return {0,0,0} end
  return {this.mkP, this.mkI, this.mkD}
end

__e2setcost(3)
e2function vector stcontrol:getGain()
  if(not this) then return {0,0,0} end
  return {this.mkP, this.mkI, this.mkD}
end

__e2setcost(3)
e2function array stcontrol:getGainPI()
  if(not this) then return {0,0} end
  return {this.mkP, this.mkI}
end

__e2setcost(3)
e2function vector2 stcontrol:getGainPI()
  if(not this) then return {0,0} end
  return {this.mkP, this.mkI}
end

__e2setcost(3)
e2function array stcontrol:getGainPD()
  if(not this) then return {0,0} end
  return {this.mkP, this.mkD}
end

__e2setcost(3)
e2function vector2 stcontrol:getGainPD()
  if(not this) then return {0,0} end
  return {this.mkP, this.mkD}
end

__e2setcost(3)
e2function array stcontrol:getGainID()
  if(not this) then return {0,0} end
  return {this.mkI, this.mkD}
end

__e2setcost(3)
e2function vector2 stcontrol:getGainID()
  if(not this) then return {0,0} end
  return {this.mkI, this.mkD}
end

__e2setcost(3)
e2function number stcontrol:getGainP()
  if(not this) then return 0 end
  return (this.mkP or 0)
end

__e2setcost(3)
e2function number stcontrol:getGainI()
  if(not this) then return 0 end
  return (this.mkI or 0)
end

__e2setcost(3)
e2function number stcontrol:getGainD()
  if(not this) then return 0 end
  return (this.mkD or 0)
end

__e2setcost(3)
e2function stcontrol stcontrol:setBias(number nN)
  if(not this) then return nil end
  this.mBias = nN; return this
end

__e2setcost(3)
e2function number stcontrol:getBias()
  if(not this) then return 0 end
  return (this.mBias or 0)
end

__e2setcost(3)
e2function string stcontrol:getType()
  return getType(this)
end

__e2setcost(3)
e2function stcontrol stcontrol:setWindup(number nD, number nU)
  if(not this) then return nil end
  if(nD < nU) then this.mSatD, this.mSatU = nD, nU end
  return this
end

__e2setcost(3)
e2function stcontrol stcontrol:setWindup(array aA)
  if(not this) then return nil end
  if(aA[1] < aA[2]) then this.mSatD, this.mSatU = aA[1], aA[2] end
  return this
end

__e2setcost(3)
e2function stcontrol stcontrol:setWindup(vector2 vV)
  if(not this) then return nil end
  if(vV[1] < vV[2]) then this.mSatD, this.mSatU = vV[1], vV[2] end
  return this
end

__e2setcost(3)
e2function stcontrol stcontrol:setWindupD(number nD)
  if(not this) then return nil end
  this.mSatD = nD; return this
end

__e2setcost(3)
e2function stcontrol stcontrol:setWindupU(number nU)
  if(not this) then return nil end
  this.mSatU = nU; return this
end

__e2setcost(3)
e2function stcontrol stcontrol:remWindup()
  if(not this) then return nil end
  remValue(this, "mSatD"); remValue(this, "mSatU"); return this
end

__e2setcost(3)
e2function stcontrol stcontrol:remWindupD()
  if(not this) then return nil end
  remValue(this, "mSatD"); return this
end

__e2setcost(3)
e2function stcontrol stcontrol:remWindupU()
  if(not this) then return nil end
  remValue(this, "mSatU"); return this
end

__e2setcost(3)
e2function array stcontrol:getWindup()
  if(not this) then return {0,0} end
  return {this.mSatD, this.mSatU}
end

__e2setcost(3)
e2function vector2 stcontrol:getWindup()
  if(not this) then return {0,0} end
  return {this.mSatD, this.mSatU}
end

__e2setcost(3)
e2function number stcontrol:getWindupD()
  if(not this) then return 0 end
  return (this.mSatD or 0)
end

__e2setcost(3)
e2function number stcontrol:getWindupU()
  if(not this) then return 0 end
  return (this.mSatU or 0)
end

__e2setcost(8)
e2function stcontrol stcontrol:setPowerP(number nP)
  return setPower(this, self, nP, nil, nil)
end

__e2setcost(8)
e2function stcontrol stcontrol:setPowerI(number nI)
  return setPower(this, self, nil, nI, nil)
end

__e2setcost(8)
e2function stcontrol stcontrol:setPowerD(number nD)
  return setPower(this, self, nil, nil, nD)
end

__e2setcost(8)
e2function stcontrol stcontrol:setPowerPI(number nP, number nI)
  return setPower(this, self, nP, nI, nil)
end

__e2setcost(8)
e2function stcontrol stcontrol:setPowerPI(vector2 vV)
  return setPower(this, self, vV[1], vV[2], nil)
end

__e2setcost(8)
e2function stcontrol stcontrol:setPowerPI(array aA)
  return setPower(this, self, aA[1], aA[2], nil)
end

__e2setcost(8)
e2function stcontrol stcontrol:setPowerPD(number nP, number nD)
  return setPower(this, self, nP, nil, nD)
end

__e2setcost(8)
e2function stcontrol stcontrol:setPowerPD(vector2 vV)
  return setPower(this, self, vV[1], nil, vV[2])
end

__e2setcost(8)
e2function stcontrol stcontrol:setPowerPD(array aA)
  return setPower(this, self, aA[1], nil, aA[2])
end

__e2setcost(8)
e2function stcontrol stcontrol:setPowerID(number nI, number nD)
  return setPower(this, self, nil, nI, nD)
end

__e2setcost(8)
e2function stcontrol stcontrol:setPowerID(vector2 vV)
  return setPower(this, self, nil, vV[1], vV[2])
end

__e2setcost(8)
e2function stcontrol stcontrol:setPowerID(array aA)
  return setPower(this, self, nil, aA[1], aA[2])
end

__e2setcost(8)
e2function stcontrol stcontrol:setPower(number nP, number nI, number nD)
  return setPower(this, self, nP, nI, nD)
end

__e2setcost(8)
e2function stcontrol stcontrol:setPower(array aA)
  return setPower(this, self, aA[1], aA[2], aA[3])
end

__e2setcost(8)
e2function stcontrol stcontrol:setPower(vector vV)
  return setPower(this, self, vV[1], vV[2], vV[3])
end

__e2setcost(3)
e2function array stcontrol:getPower()
  if(not this) then return {0,0,0} end
  return {this.mpP, this.mpI, this.mpD}
end

__e2setcost(3)
e2function vector stcontrol:getPower()
  if(not this) then return {0,0,0} end
  return {this.mpP, this.mpI, this.mpD}
end

__e2setcost(3)
e2function number stcontrol:getPowerP()
  if(not this) then return 0 end
  return (this.mpP or 0)
end

__e2setcost(3)
e2function number stcontrol:getPowerI()
  if(not this) then return 0 end
  return (this.mpI or 0)
end

__e2setcost(3)
e2function number stcontrol:getPowerD()
  if(not this) then return 0 end
  return (this.mpD or 0)
end

__e2setcost(3)
e2function array stcontrol:getPowerPI()
  if(not this) then return {0,0} end
  return {this.mpP, this.mpI}
end

__e2setcost(3)
e2function vector2 stcontrol:getPowerPI()
  if(not this) then return {0,0} end
  return {this.mpP, this.mpI}
end

__e2setcost(3)
e2function array stcontrol:getPowerPD()
  if(not this) then return {0,0} end
  return {this.mpP, this.mpD}
end

__e2setcost(3)
e2function vector2 stcontrol:getPowerPD()
  if(not this) then return {0,0} end
  return {this.mpP, this.mpD}
end

__e2setcost(3)
e2function array stcontrol:getPowerID()
  if(not this) then return {0,0} end
  return {this.mpI, this.mpD}
end

__e2setcost(3)
e2function vector2 stcontrol:getPowerID()
  if(not this) then return {0,0} end
  return {this.mpI, this.mpD}
end


__e2setcost(3)
e2function number stcontrol:getErrorNow()
  if(not this) then return 0 end
  return (this.mErrN or 0)
end

__e2setcost(3)
e2function number stcontrol:getErrorOld()
  if(not this) then return 0 end
  return (this.mErrO or 0)
end

__e2setcost(3)
e2function number stcontrol:getErrorDelta()
  if(not this) then return 0 end
  return (this.mErrN - this.mErrO)
end

__e2setcost(3)
e2function number stcontrol:getTimeNow()
  if(not this) then return 0 end
  return (this.mTimN or 0)
end

__e2setcost(3)
e2function number stcontrol:getTimeOld()
  if(not this) then return 0 end
  return (this.mTimO or 0)
end

__e2setcost(3)
e2function number stcontrol:getTimeDelta()
  if(not this) then return 0 end
  return ((this.mTimN or 0) - (this.mTimO or 0))
end

__e2setcost(3)
e2function number stcontrol:getTimeSample()
  if(not this) then return 0 end; local nT = this.mnTo
  return ((nT and nT > 0) and nT or 0)
end

__e2setcost(3)
e2function stcontrol stcontrol:setTimeSample(number nT)
  if(not this) then return 0 end
  this.mnTo = ((nT and nT > 0) and nT or nil)
  return this
end

__e2setcost(3)
e2function stcontrol stcontrol:remTimeSample()
  if(not this) then return 0 end
  remValue(this, "mnTo"); return this
end

__e2setcost(3)
e2function number stcontrol:getTimeBench()
  if(not this) then return 0 end
  return (this.mTimB or 0)
end

__e2setcost(3)
e2function number stcontrol:getTimeRatio()
  if(not this) then return 0 end
  local timDt = (this.mTimN - this.mTimO)
  if(timDt == 0) then return 0 end
  return ((this.mTimB or 0) / timDt)
end

__e2setcost(3)
e2function stcontrol stcontrol:setIsIntegrating(number nN)
  if(not this) then return nil end
  this.meInt = (nN ~= 0); return this
end

__e2setcost(3)
e2function number stcontrol:isIntegrating()
  if(not this) then return 0 end
  return (this.meInt and 1 or 0)
end

__e2setcost(3)
e2function stcontrol stcontrol:setIsCombined(number nN)
  if(not this) then return nil end
  this.mbCmb = (nN ~= 0); return this
end

__e2setcost(3)
e2function number stcontrol:isCombined()
  if(not this) then return 0 end
  return (this.mbCmb and 1 or 0)
end

__e2setcost(3)
e2function stcontrol stcontrol:setIsManual(number nN)
  if(not this) then return nil end
  this.mbMan = (nN ~= 0); return this
end

__e2setcost(3)
e2function number stcontrol:isManual()
  if(not this) then return 0 end
  return (this.mbMan and 1 or 0)
end

__e2setcost(3)
e2function stcontrol stcontrol:setManual(number nN)
  if(not this) then return nil end
  this.mvMan = nN; return this
end

__e2setcost(3)
e2function number stcontrol:getManual()
  if(not this) then return 0 end
  return (this.mvMan or 0)
end

__e2setcost(3)
e2function stcontrol stcontrol:setIsInverted(number nN)
  if(not this) then return nil end
  this.mbInv = (nN ~= 0); return this
end

__e2setcost(3)
e2function number stcontrol:isInverted()
  if(not this) then return 0 end
  return (this.mbInv and 1 or 0)
end

__e2setcost(3)
e2function stcontrol stcontrol:setIsActive(number nN)
  if(not this) then return nil end
  this.mbOn = (nN ~= 0); return this
end

__e2setcost(3)
e2function number stcontrol:isActive()
  if(not this) then return 0 end
  return (this.mbOn and 1 or 0)
end

__e2setcost(3)
e2function number stcontrol:getControl()
  if(not this) then return 0 end
  return (this.mvCon or 0)
end

__e2setcost(3)
e2function array stcontrol:getControlTerm()
  if(not this) then return {0,0,0} end
  return {this.mvP, this.mvI, this.mvD}
end

__e2setcost(3)
e2function vector stcontrol:getControlTerm()
  if(not this) then return {0,0,0} end
  return {this.mvP, this.mvI, this.mvD}
end

__e2setcost(3)
e2function number stcontrol:getControlTermP()
  if(not this) then return 0 end
  return (this.mvP or 0)
end

__e2setcost(3)
e2function number stcontrol:getControlTermI()
  if(not this) then return 0 end
  return (this.mvI or 0)
end

__e2setcost(3)
e2function number stcontrol:getControlTermD()
  if(not this) then return 0 end
  return (this.mvD or 0)
end

__e2setcost(3)
e2function stcontrol stcontrol:resState()
  return resState(this, self)
end

__e2setcost(20)
e2function stcontrol stcontrol:setState(number nR, number nY)
  if(not this) then return nil end
  if(this.mbOn) then
    if(this.mbMan) then this.mvCon = (this.mvMan + this.mBias); return this end
    this.mTimO = this.mTimN; this.mTimN = getTime()
    this.mErrO = this.mErrN; this.mErrN = (this.mbInv and (nY-nR) or (nR-nY))
    local timDt = (this.mnTo and this.mnTo or (this.mTimN - this.mTimO))
    if(this.mkP > 0) then -- This does not get affected by the time and just multiplies
      this.mvP = getValue(this.mkP, this.mErrN, this.mpP) end
    if((this.mkI > 0) and (this.mErrN ~= 0) and this.meInt and (timDt > 0)) then -- I-Term
      local arInt = (this.mErrN + this.mErrO) * timDt -- Integral error function area
      this.mvI = getValue(this.mkI * timDt, arInt, this.mpI) + this.mvI end
    if((this.mkD > 0) and (this.mErrN ~= this.mErrO) and (timDt > 0)) then -- D-Term
      local arDif = (this.mErrN - this.mErrO) / timDt -- Derivative dY/dT
      this.mvD = getValue(this.mkD * timDt, arDif, this.mpD) else this.mvD = 0 end
    this.mvCon = this.mvP + this.mvI + this.mvD -- Calculate the control signal
    if(this.mSatD and this.mvCon < this.mSatD) then -- Saturate lower limit
      this.mvCon, this.meInt = this.mSatD, false -- Integral is disabled
    elseif(this.mSatU and this.mvCon > this.mSatU) then -- Saturate upper limit
      this.mvCon, this.meInt = this.mSatU, false -- Integral is disabled
    else this.meInt = true end -- Saturation disables the integrator
    this.mvCon = (this.mvCon + this.mBias) -- Apply the saturated signal bias
    this.mTimB = (getTime() - this.mTimN) -- Benchmark the process
  else return resState(this, self) end; return this
end

__e2setcost(7)
e2function stcontrol stcontrol:tuneAutoZN(number uK, number uT)
  return tuneZieglerNichols(this, uK, uT, nil, nil, false)
end

__e2setcost(7)
e2function stcontrol stcontrol:tuneAutoZN(number uK, number uT, string sM)
  return tuneZieglerNichols(this, uK, uT, nil, sM, false)
end

__e2setcost(7)
e2function stcontrol stcontrol:tuneProcZN(number uK, number uT, number uL)
  return tuneZieglerNichols(this, uK, uT, uL, nil, true)
end

__e2setcost(7)
e2function stcontrol stcontrol:tuneProcCC(number nK, number nT, number nL)
  return tuneChoenCoon(this, nK, nT, nL)
end

__e2setcost(7)
e2function stcontrol stcontrol:tuneProcCHRSP(number nK, number nT, number nL)
  return tuneChienHronesReswick(this, nK, nT, nL, false, false)
end

__e2setcost(7)
e2function stcontrol stcontrol:tuneOverCHRSP(number nK, number nT, number nL)
  return tuneChienHronesReswick(this, nK, nT, nL, true, false)
end

__e2setcost(7)
e2function stcontrol stcontrol:tuneProcCHRLR(number nK, number nT, number nL)
  return tuneChienHronesReswick(this, nK, nT, nL, false, true)
end

__e2setcost(7)
e2function stcontrol stcontrol:tuneOverCHRLR(number nK, number nT, number nL)
  return tuneChienHronesReswick(this, nK, nT, nL, true, true)
end

__e2setcost(7)
e2function stcontrol stcontrol:tuneAH(number nK, number nT, number nL)
  return tuneAstromHagglund(this, nK, nT, nL)
end

__e2setcost(7)
e2function stcontrol stcontrol:tuneISE(number nK, number nT, number nL)
  return tuneIE(this, nK, nT, nL, "ISE")
end

__e2setcost(7)
e2function stcontrol stcontrol:tuneIAE(number nK, number nT, number nL)
  return tuneIE(this, nK, nT, nL, "IAE")
end

__e2setcost(7)
e2function stcontrol stcontrol:tuneITAE(number nK, number nT, number nL)
  return tuneIE(this, nK, nT, nL, "ITAE")
end

__e2setcost(15)
e2function stcontrol stcontrol:dumpItem(number nN)
  return dumpItem(this, self, nN)
end

__e2setcost(15)
e2function stcontrol stcontrol:dumpItem(string sN)
  return dumpItem(this, self, sN)
end

__e2setcost(15)
e2function stcontrol stcontrol:dumpItem(string nT, number nN)
  return dumpItem(this, self, nN, nT)
end

__e2setcost(15)
e2function stcontrol stcontrol:dumpItem(string nT, string sN)
  return dumpItem(this, self, sN, nT)
end
