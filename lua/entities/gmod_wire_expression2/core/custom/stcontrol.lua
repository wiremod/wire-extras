--[[ ******************************************************************************
 My custom state LQ-PID control type handling process variables
****************************************************************************** ]]--

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

--[[ **************************** CONFIGURATION **************************** ]]

E2Lib.RegisterExtension("stcontrol", true,
	"Lets E2 chips have dedicated state control objects.",
	"Creates a dedicated object oriented class that is designed to control internal in-game dynamic processes."
)

-- Client and server have independent value
local gnIndependentUsed = bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_PRINTABLEONLY)
-- Server tells the client what value to use
local gnServerControled = bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_PRINTABLEONLY, FCVAR_REPLICATED)

local gtComponent = {"P", "I", "D"} -- The names of each term. This is used for indexing and checking
local gsFormatPID = "(%s%s%s)" -- The general type format for the control power setup
local gtMissName  = {"Xx", "X", "Nr"} -- This is a place holder for missing/default type
local gsVarPrefx  = "wire_expression2_stcontrol" -- This is used for variable prefix
local varEnStatus = CreateConVar(gsVarPrefx.."_enst",  0, gnIndependentUsed, "StControl status output messages")
local varDefPrint = CreateConVar(gsVarPrefx.."_dprn", "TALK", gnServerControled, "StControl default status output")
local gsDefPrint  = varDefPrint:GetString() -- Default print location
local gsFormLogs  = "E2{%s}{%d}:stcontrol: %s" -- Contains the logs format of the addon
local gtPrintName = {} -- Contains the print location specification

--[[ **************************** CONFIGURATION **************************** ]]

gtPrintName["NOTIFY" ] = HUD_PRINTNOTIFY
gtPrintName["CONSOLE"] = HUD_PRINTCONSOLE
gtPrintName["TALK"   ] = HUD_PRINTTALK
gtPrintName["CENTER" ] = HUD_PRINTCENTER

--[[ **************************** PRIMITIVES **************************** ]]

local function isValid(vE)
	return (vE and vE:IsValid())
end

local function getSign(nV)
	return ((nV > 0 and 1) or (nV < 0 and -1) or 0)
end

local function getValue(kV,eV,pV)
	return (kV*getSign(eV)*math.abs(eV)^pV)
end

local function logStatus(sMsg, oChip, nPos, ...)
	if(varEnStatus:GetBool()) then
		local nPos = (tonumber(nPos) or gtPrintName[gsDefPrint])
		local oPly, oEnt = oChip.player, oChip.entity
		local sNam, nEID = oPly:Nick() , oEnt:EntIndex()
		local sTxt = gsFormLogs:format(sNam, nEID, tostring(sMsg))
		oPly:PrintMessage(nPos, sTxt:sub(1, 200))
	end; return ...
end

--[[ **************************** CALLBACKS **************************** ]]

cvars.RemoveChangeCallback(varDefPrint:GetName(), varDefPrint:GetName().."_call")
cvars.AddChangeCallback(varDefPrint:GetName(), function(sVar, vOld, vNew)
	local sK = tostring(vNew):upper(); if(gtPrintName[sK]) then gsDefPrint = sK end
end, varDefPrint:GetName().."_call")

--[[ **************************** WRAPPERS **************************** ]]

local function setGains(oStCon, vP, vI, vD, bZ)
	if(not oStCon) then return nil end
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
	oStCon.mType[2] = sT; return oStCon
end

local function getCode(nN)
	local nW, nF = math.modf(nN, 1)
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

local function setPower(oStCon, vP, vI, vD)
	if(not oStCon) then return nil end
	oStCon.mpP, oStCon.mpI, oStCon.mpD = (tonumber(vP) or 1), (tonumber(vI) or 1), (tonumber(vD) or 1)
	oStCon.mType[1] = gsFormatPID:format(getCode(oStCon.mpP), getCode(oStCon.mpI), getCode(oStCon.mpD))
	return oStCon
end

local function resState(oStCon)
	if(not oStCon) then return nil end
	oStCon.mErrO, oStCon.mErrN = 0, 0 -- Reset the error
	oStCon.mvCon, oStCon.meInt, oStCon.meDif = 0, true, true -- Control value and integral enabled
	oStCon.mvP, oStCon.mvI, oStCon.mvD, oStCon.meZcx = 0, 0, 0, false -- Term values
	oStCon.mTimN = CurTime(); oStCon.mTimO = oStCon.mTimN; -- Update clock
	return oStCon
end

local function getType(oStCon)
	if(not oStCon) then local mP, mT = gtMissName[1], gtMissName[2]
		return (gsFormatPID:format(mP,mP,mP).."-"..mT:rep(3))
	end; return table.concat(oStCon.mType, "-")
end

local function dumpItem(oStCon, sNam, sPos)
	if(not oStCon) then return nil end
	local sP = tostring(sPos or gsDefPrint)
	local nP, oChip = gtPrintName[sP], oStCon.mChip -- Print location setup
	if(not nP) then return oStCon end
	logStatus("Controller ["..tostring(sNam).."]["..tostring(oStCon.mnTo or gtMissName[2]).."]["..getType(oStCon).."]:", oChip, nP)
	logStatus(" Manual mode enabled: "..tostring(oStCon.mbMan), oChip, nP)
	logStatus("  Value: "..tostring(oStCon.mvMan), oChip, nP)
	logStatus("   Bias: "..tostring(oStCon.mBias), oChip, nP)
	logStatus(" Gains for terms:", oChip, nP)
	for iD = 1, #gtComponent do local sC = gtComponent[iD]
		logStatus("      "..sC..": "..tostring(oStCon["mk"..sC]), oChip, nP) end
	logStatus(" Power for terms:", oChip, nP)
	for iD = 1, #gtComponent do local sC = gtComponent[iD]
		logStatus("      "..sC..": "..tostring(oStCon["mp"..sC]), oChip, nP) end
	logStatus(" Control state value: "..tostring(oStCon.mvCon), oChip, nP)
	for iD = 1, #gtComponent do local sC = gtComponent[iD]
		logStatus("      "..sC..": "..tostring(oStCon["mv"..sC]), oChip, nP) end
	logStatus(" Saturation limits:", oChip, nP)
	logStatus("    Max: "..tostring(oStCon.mSatU), oChip, nP)
	logStatus("    Min: "..tostring(oStCon.mSatD), oChip, nP)
	logStatus(" Time memory state:", oChip, nP)
	logStatus("    Now: "..tostring(oStCon.mTimN), oChip, nP)
	logStatus("   Past: "..tostring(oStCon.mTimO), oChip, nP)
	logStatus(" Error memory state:", oChip, nP)
	logStatus("    Now: "..tostring(oStCon.mErrN), oChip, nP)
	logStatus("   Past: "..tostring(oStCon.mErrO), oChip, nP)
	logStatus(" Control enable flag: "..tostring(oStCon.mbOn), oChip, nP)
	logStatus("   BCmb: "..tostring(oStCon.mbCmb), oChip, nP)
	logStatus("   BInv: "..tostring(oStCon.mbInv), oChip, nP)
	logStatus("   EInt: "..tostring(oStCon.meInt), oChip, nP)
	logStatus("   EDif: "..tostring(oStCon.meDif), oChip, nP)
	logStatus("   EZcx: "..tostring(oStCon.meZcx), oChip, nP)
	return oStCon -- The dump method
end

--[[
 * Calculates the control signal and updates the internal controller state
 * oStCon > Pointer to internal state controller object type
 * nRef   > The value for the reference given my the user
 * nOut   > The dynamic system current output value
]]
local function conProcess(oStCon, nRef, nOut)
	if(not oStCon) then return nil end
	if(oStCon.mbOn) then
		if(oStCon.mbMan) then
			oStCon.mvCon = (oStCon.mvMan + oStCon.mBias); return oStCon
		end -- If manual mode is enabled add bias and go to the output
		local satU, satD = oStCon.mSatU, oStCon.mSatD -- Saturation access
		local errPs = oStCon.mErrN -- When called the error from previous tick
		local errNw = (oStCon.mbInv and (nOut - nRef) or (nRef - nOut))
		oStCon.mErrO = errPs; oStCon.mErrN = errNw -- Sync internal state
		oStCon.mTimO = oStCon.mTimN; oStCon.mTimN = CurTime() -- Sync the time
		local timDt = (oStCon.mnTo and oStCon.mnTo or (oStCon.mTimN - oStCon.mTimO))
		-- Does not get affected by the time and just multiplies. Not approximated
		if(oStCon.mkP > 0) then
			oStCon.mvP = getValue(oStCon.mkP, errNw, oStCon.mpP)
		end
		-- Direct approximation with error sampling average for calculating the integral term
		if((oStCon.mkI > 0) and oStCon.meInt and (timDt > 0)) then
			if(oStCon.meZcx and (getSign(errNw) ~= getSign(errPs))) then
				oStCon.mvI = 0 -- Reset on zero for avoid having the same value in the other direction
			else -- If the flag is not set and an error delta is present calculate the integral area
				local arInt = (errNw + errPs) * timDt -- Integral error area
				oStCon.mvI = getValue(oStCon.mkI * timDt, arInt, oStCon.mpI) + oStCon.mvI
			end
		end
		-- Direct approximation for calculating the derivative term
		if((oStCon.mkD > 0) and (errNw ~= errPs) and oStCon.meDif and (timDt > 0)) then
			local arDif = (errNw - errPs) / timDt -- Error derivative slope dE/dT
			oStCon.mvD = getValue(oStCon.mkD * timDt, arDif, oStCon.mpD)
		else -- Reset the derivative as there is no slope to be used
			oStCon.mvD = 0
		end
		oStCon.mvCon = oStCon.mvP + oStCon.mvI + oStCon.mvD -- Calculate the control signal
		if(satD and oStCon.mvCon < satD) then -- Saturate lower limit
			oStCon.mvCon, oStCon.meInt = satD, false -- Integral is disabled
		elseif(satU and oStCon.mvCon > satU) then -- Saturate upper limit
			oStCon.mvCon, oStCon.meInt = satU, false -- Integral is disabled
		else oStCon.meInt = true end -- Saturation enables the integrator in determined bounds
		oStCon.mvCon = (oStCon.mvCon + oStCon.mBias) -- Apply the saturated signal bias
		oStCon.mTimB = (CurTime()    - oStCon.mTimN) -- Benchmark the process
	else return resState(oStCon) end; return oStCon
end

--[[
 * Tunes a controller using the Ziegler-Nichols method
 * When `bP` is true, then 3-parameter model is used
 * otherwise P-controller is hooked to the plant and uK, uT (no model)
 * are obtained from the output. The value `sM` is a additional
 * tuning option for a PID controller.
 * oStCon > Pointer to controller object
 * uK     > Auto-oscillation P-gain coefficient of unknown model plant
						Plant gain when the mathematical model is known
 * uT     > Auto-oscillation time difference of unknown model plant
						Plant time constant when the mathematical model is known
 * uL     > Plant time delay when the mathematical model is known
 * sM     > Method especially for PID controller setup. Default is `classic`
 * vT     > Type of the actual tuning for plant mathematical model present
]]
local function tuneZieglerNichols(oStCon, uK, uT, uL, sM, vT)
	if(not oStCon) then return nil end; local oChip = oStCon.mChip
	local sM, sT = tostring(sM or "classic"):lower(), oStCon.mType[2]
	local uK, uT = (tonumber(uK) or 0), (tonumber(uT) or 0)
	if(vT) then if(uT <= 0 or uL <= 0) then return oStCon end
		local nT = (tonumber(vT) or 0) -- Try converting it to number
		if(nT == 1) then -- Do we have a mathematical model present
			if(sT == "P") then return setGains(oStCon, (uT/uL), 0, 0, true)
			elseif(sT == "PI") then return setGains(oStCon, (0.9*(uT/uL)), (0.3/uL), 0, true)
			elseif(sT == "PD") then return setGains(oStCon, (1.1*(uT/uL)), 0, (0.8/uL), true)
			elseif(sT == "PID") then return setGains(oStCon, (1.2*(uT/uL)), 1/(2*uL), 2/uL)
			else return logStatus("Controller mismatch <"..sT..">", oChip, nil, oStCon) end
		elseif(nT == 2) then local mA = (nK * nL / nT)
			if(sT == "P") then return setGains(oStCon, (0.7/mA), 0, 0, true)
			elseif(sT == "PI") then return setGains(oStCon, (0.6/mA), (1/uT), 0, true)
			elseif(sT == "PD") then return setGains(oStCon, (0.84/mA), 0, (0.35/uT), true)
			elseif(sT == "PID") then return setGains(oStCon, (0.95/mA), 1/(1.4*uT), (0.47*uT))
			else return logStatus("Controller mismatch <"..sT..">", oChip, nil, oStCon) end
		else return logStatus("Method mismatch <"..tostring(vT)..">"..nT, oChip, nil, oStCon) end
	else if(uK <= 0 or uT <= 0) then return oStCon end
		if(sT == "P") then return setGains(oStCon, (0.5*uK), 0, 0, true)
		elseif(sT == "PI") then return setGains(oStCon, (0.45*uK), (1.2/uT), 0, true)
		elseif(sT == "PD") then return setGains(oStCon, (0.80*uK), 0, (uT/8), true)
		elseif(sT == "PID") then
			if(sM == "classic") then return setGains(oStCon, 0.60 * uK, 2.0 / uT, uT / 8.0)
			elseif(sM == "pessen" ) then return setGains(oStCon, (7*uK)/10, 5/(2*uT), (3*uT)/20)
			elseif(sM == "sovers") then return setGains(oStCon, (uK/3), (2/uT), (uT/3))
			elseif(sM == "novers") then return setGains(oStCon, (uK/5), (2/uT), (uT/3))
			else return logStatus("Method mismatch <"..sM..">", oChip, nil, oStCon) end
		else return logStatus("Controller mismatch <"..sT..">", oChip, nil, oStCon) end
	end; return oStCon
end

--[[
 * Tunes a controller using the Choen-Coon method
 * oStCon > Pointer to controller object
 * nK     > Plant model gain
 * nT     > Plant model time constant
 * nL     > Plant model time delay
]]
local function tuneChoenCoon(oStCon, nK, nT, nL)
	if(not oStCon) then return nil end; local oChip = oStCon.mChip
	if(nT <= 0 or nL <= 0) then return oStCon end
	local sT, mT = oStCon.mType[2], (nL/nT)
	if(sT == "P") then
		local kP = (1/(nK*mT))*(1+(1/3)*mT)
		return setGains(oStCon, kP, 0, 0, true)
	elseif(sT == "PI") then
		local kP = (1/(nK*mT))*(9/10+(1/12)*mT)
		local kI = 1/(nL*((30+3*mT)/(9+20*mT)))
		return setGains(oStCon, kP, kI, 0, true)
	elseif(sT == "PD") then
		local kP = (1/(nK*mT))*(5/4+(1/6)*mT)
		local kD = nL*((6-2*mT)/(22+3*mT))
		return setGains(oStCon, kP, 0, kD, true)
	elseif(sT == "PID") then
		local kP = (1/(nK*mT))*(4/3+(1/4)*mT)
		local kI = 1/(nL*((32+6*mT)/(13+8*mT)))
		local kD = nL*(4/(11+2*mT))
		return setGains(oStCon, kP, kI, kD)
	else return logStatus("Type mismatch <"..sT..">", oChip, nil, oStCon) end
end

--[[
 * Tunes a controller using the Chien-Hrones-Reswick (CHR) method
 * by using a three parameter model
 * oStCon > Pointer to controller object
 * nK     > Plant model gain
 * nT     > Plant model time constant
 * nL     > Plant model time delay
 * bM     > Flag tuning is done for 20% overshot
 * bR     > Flag tuning is done for load rejection
 * Else the tuning is done for set point tracking
]]
local function tuneChienHronesReswick(oStCon, nK, nT, nL, bM, bR)
	if(not oStCon) then return nil end; local oChip = oStCon.mChip
	if(nK <= 0 or nT <= 0 or nL <= 0) then return oStCon end
	local mA, sT = (nK * nL / nT), oStCon.mType[2]
	if(bR) then -- Load disturbance rejection
		if(bM) then -- Overshoot 20%
			if(sT == "P") then return setGains(oStCon, 0.7/mA, 0, 0, true)
			elseif(sT == "PI") then return setGains(oStCon, (0.7/mA), (1/(2.3*nT)), 0, true)
			elseif(sT == "PD") then return setGains(oStCon, (0.82/mA), 0, (0.5*uL), true)
			elseif(sT == "PID") then return setGains(oStCon, (1.2/mA), 1/(2*nT), 0.42*uL)
			else return logStatus("Type mismatch <"..sT..">", oChip, nil, oStCon) end
		else
			if(sT == "P") then return setGains(oStCon, (0.3/mA), 0, 0, true)
			elseif(sT == "PI") then return setGains(oStCon, (0.6/mA), (1/(4*nT)), 0, true)
			elseif(sT == "PD") then return setGains(oStCon, (0.75/mA), 0, (0.5*uL), true)
			elseif(sT == "PID") then return setGains(oStCon, (0.95/mA), (1/(2.4*nT)), (0.42*uL))
			else return logStatus("Type mismatch <"..sT..">", oChip, nil, oStCon) end
		end
	else -- Set point tracking
		if(bM) then -- Overshoot 20%
			if(sT == "P") then return setGains(oStCon, 0.7/mA, 0, 0, true)
			elseif(sT == "PI") then return setGains(oStCon, (0.6/mA), 1/nT, 0, true)
			elseif(sT == "PD") then return setGains(oStCon, (0.7/mA), 0, (0.45*uL), true)
			elseif(sT == "PID") then return setGains(oStCon, (0.95/mA), 1/(1.4*nT), 0.47*uL)
			else return logStatus("Type mismatch <"..sT..">", oChip, nil, oStCon) end
		else
			if(sT == "P") then return setGains(oStCon, (0.3/mA), 0, 0, true)
			elseif(sT == "PI") then return setGains(oStCon, (0.35/mA), (1/(1.2*nT)), 0, true)
			elseif(sT == "PD") then return setGains(oStCon, (0.45/mA), 0, (0.45*uL), true)
			elseif(sT == "PID") then return setGains(oStCon, (0.6/mA), (1/nT), (0.5*uL))
			else return logStatus("Type mismatch <"..sT..">", oChip, nil, oStCon) end
		end
	end
end

--[[
 * Tunes a controller using the Astrom-Hagglund method
 * oStCon > Pointer to controller object
 * nK     > Plant model gain
 * nT     > Plant model time constant
 * nL     > Plant model time delay
]]
local function tuneAstromHagglund(oStCon, nK, nT, nL)
	if(not oStCon) then return nil end
	if(nT <= 0 or nL <= 0) then return oStCon end
	local kP = (1/nK)*(0.2+0.45*(nT/nL))
	local kI = 1/(((0.4*nL+0.8*nT)/(nL+0.1*nT))*nL)
	local kD = (0.5*nL*nT)/(0.3*nL+nT)
	return setGains(oStCon, kP, kI, kD)
end

--[[
 * Tunes a controller using the integral error method
 * oStCon > Pointer to controller object
 * nK     > Plant model gain
 * nT     > Plant model time constant
 * nL     > Plant model time delay
 * sM     > Controller tuning method
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
local function tuneIE(oStCon, nK, nT, nL, sM)
	if(not oStCon) then return nil end; local oChip = oStCon.mChip
	if(nK <= 0 or nT <= 0 or nL <= 0) then return oStCon end
	local sM, sT, tT = tostring(sM or "ISE"), oStCon.mType[2], nil
	tT = tIE[sM]; if(not tT) then
		return logStatus("Mode mismatch <"..sM..">", oChip, nil, oStCon) end
	tT = tT[sT]; if(not tT) then
		return logStatus("Type mismatch <"..sT..">", oChip, nil, oStCon) end
	local A, B, C, D, E, F = unpack(tT)
	local kP = (A*(nL/nT)^B)/nK
	local kI = 1/((nT/C)*(nL/nT)^D)
	local kD = nT*E*(nL/nT)^F
	return setGains(oStCon, kP, kI, kD)
end

local function tuneTyreusLuyben(uK, uT)
	if(not oStCon) then return nil end
	if(nT <= 0 or nL <= 0) then return oStCon end; local sT = oStCon.mType[2]
	if(sT == "P") then return setGains(oStCon, (uK/2.8), 0, 0, true)
	elseif(sT == "PI") then return setGains(oStCon, (uK/3.2), 1/(2.2*uT), 0, true)
	elseif(sT == "PD") then return setGains(oStCon, (uK/2.8), 0, (uT/5.2), true)
	elseif(sT == "PID") then return setGains(oStCon, (uK/2.2), 1/(2.2*uT), (uT/6.3), true)
	else return logStatus("Type mismatch <"..sT..">", oChip, nil, oStCon) end
end

local function newItem(oChip, nTo)
	local eChip = oChip.entity; if(not isValid(eChip)) then
		return logStatus("Entity invalid", oChip, nil, nil) end
	local oStCon, sM = {}, gtMissName[3]; oStCon.mnTo = tonumber(nTo) -- Place to store the object
	if(oStCon.mnTo and oStCon.mnTo <= 0) then
		return logStatus("Delta mismatch ["..tostring(oStCon.mnTo).."]", oChip, nil, nil) end
	local sType = gsFormatPID:format(sM, sM, sM) -- Error state values
	oStCon.mTimN = CurTime(); oStCon.mTimO = oStCon.mTimN; -- Reset clock
	oStCon.mErrO, oStCon.mErrN, oStCon.mType = 0, 0, {sType, gtMissName[2]:rep(3)}
	oStCon.mvCon, oStCon.mTimB, oStCon.meInt, oStCon.meDif = 0, 0, true, true -- Control value and integral enabled
	oStCon.mBias, oStCon.mSatD, oStCon.mSatU = 0, nil, nil -- Saturation limits and settings
	oStCon.mvP, oStCon.mvI, oStCon.mvD = 0, 0, 0 -- Term values
	oStCon.mkP, oStCon.mkI, oStCon.mkD = 0, 0, 0 -- P, I and D term gains
	oStCon.mpP, oStCon.mpI, oStCon.mpD = 1, 1, 1 -- Raise the error to power of that much
	oStCon.mbCmb, oStCon.mbInv, oStCon.mbOn, oStCon.mbMan = false, false, false, false
	oStCon.mvMan, oStCon.mChip, oStCon.meZcx = 0, oChip, false -- Configure manual mode and store indexing
	return oStCon -- Return the created controller object
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

__e2setcost(20)
e2function stcontrol stcontrol:getCopy()
	return newItem(self, this.mnTo)
end

__e2setcost(20)
e2function stcontrol stcontrol:getCopy(number nT)
	return newItem(self, nT)
end

__e2setcost(7)
e2function stcontrol stcontrol:setGainP(number nP)
	return setGains(this, nP, nil, nil)
end

__e2setcost(7)
e2function stcontrol stcontrol:setGainI(number nI)
	return setGains(this, nil, nI, nil)
end

__e2setcost(7)
e2function stcontrol stcontrol:setGainD(number nD)
	return setGains(this, nil, nil, nD)
end

__e2setcost(7)
e2function stcontrol stcontrol:setGainPI(number nP, number nI)
	return setGains(this, nP, nI, nil)
end

__e2setcost(7)
e2function stcontrol stcontrol:setGainPI(vector2 vV)
	return setGains(this, vV[1], vV[2], nil)
end

__e2setcost(7)
e2function stcontrol stcontrol:setGainPI(array aA)
	return setGains(this, aA[1], aA[2], nil)
end

__e2setcost(7)
e2function stcontrol stcontrol:setGainPD(number nP, number nD)
	return setGains(this, nP, nil, nD)
end

__e2setcost(7)
e2function stcontrol stcontrol:setGainPD(vector2 vV)
	return setGains(this, vV[1], nil, vV[2])
end

__e2setcost(7)
e2function stcontrol stcontrol:setGainPD(array aA)
	return setGains(this, aA[1], nil, aA[2])
end

__e2setcost(7)
e2function stcontrol stcontrol:setGainID(number nI, number nD)
	return setGains(this, nil, nI, nD)
end

__e2setcost(7)
e2function stcontrol stcontrol:setGainID(vector2 vV)
	return setGains(this, nil, vV[1], vV[2])
end

__e2setcost(7)
e2function stcontrol stcontrol:setGainID(array aA)
	return setGains(this, nil, aA[1], aA[2])
end

__e2setcost(7)
e2function stcontrol stcontrol:setGain(number nP, number nI, number nD)
	return setGains(this, nP, nI, nD)
end

__e2setcost(7)
e2function stcontrol stcontrol:setGain(array aA)
	return setGains(this, aA[1], aA[2], aA[3])
end

__e2setcost(7)
e2function stcontrol stcontrol:setGain(vector vV)
	return setGains(this, vV[1], vV[2], vV[3])
end

__e2setcost(7)
e2function stcontrol stcontrol:remGainP()
	return setGains(this, 0, nil, nil, true)
end

__e2setcost(7)
e2function stcontrol stcontrol:remGainI()
	return setGains(this, nil, 0, nil, true)
end

__e2setcost(7)
e2function stcontrol stcontrol:remGainD()
	return setGains(this, nil, nil, 0, true)
end

__e2setcost(7)
e2function stcontrol stcontrol:remGainPI()
	return setGains(this, 0, 0, nil, true)
end

__e2setcost(7)
e2function stcontrol stcontrol:remGainPD()
	return setGains(this, 0, nil, 0, true)
end

__e2setcost(7)
e2function stcontrol stcontrol:remGainID()
	return setGains(this, nil, 0, 0, true)
end

__e2setcost(7)
e2function stcontrol stcontrol:remGain()
	return setGains(this, 0, 0, 0, true)
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
e2function stcontrol stcontrol:setWindupMin(number nD)
	if(not this) then return nil end
	this.mSatD = nD; return this
end

__e2setcost(3)
e2function stcontrol stcontrol:setWindupMax(number nU)
	if(not this) then return nil end
	this.mSatU = nU; return this
end

__e2setcost(3)
e2function stcontrol stcontrol:remWindup()
	if(not this) then return nil end
	this.mSatD = nil; this.mSatU = nil; return this
end

__e2setcost(3)
e2function stcontrol stcontrol:remWindupMin()
	if(not this) then return nil end
	this.mSatD = nil; return this
end

__e2setcost(3)
e2function stcontrol stcontrol:remWindupMax()
	if(not this) then return nil end
	this.mSatU = nil; return this
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
e2function number stcontrol:getWindupMin()
	if(not this) then return 0 end
	return (this.mSatD or 0)
end

__e2setcost(3)
e2function number stcontrol:getWindupMax()
	if(not this) then return 0 end
	return (this.mSatU or 0)
end

__e2setcost(8)
e2function stcontrol stcontrol:setPowerP(number nP)
	return setPower(this, nP, nil, nil)
end

__e2setcost(8)
e2function stcontrol stcontrol:setPowerI(number nI)
	return setPower(this, nil, nI, nil)
end

__e2setcost(8)
e2function stcontrol stcontrol:setPowerD(number nD)
	return setPower(this, nil, nil, nD)
end

__e2setcost(8)
e2function stcontrol stcontrol:setPowerPI(number nP, number nI)
	return setPower(this, nP, nI, nil)
end

__e2setcost(8)
e2function stcontrol stcontrol:setPowerPI(vector2 vV)
	return setPower(this, vV[1], vV[2], nil)
end

__e2setcost(8)
e2function stcontrol stcontrol:setPowerPI(array aA)
	return setPower(this, aA[1], aA[2], nil)
end

__e2setcost(8)
e2function stcontrol stcontrol:setPowerPD(number nP, number nD)
	return setPower(this, nP, nil, nD)
end

__e2setcost(8)
e2function stcontrol stcontrol:setPowerPD(vector2 vV)
	return setPower(this, vV[1], nil, vV[2])
end

__e2setcost(8)
e2function stcontrol stcontrol:setPowerPD(array aA)
	return setPower(this, aA[1], nil, aA[2])
end

__e2setcost(8)
e2function stcontrol stcontrol:setPowerID(number nI, number nD)
	return setPower(this, nil, nI, nD)
end

__e2setcost(8)
e2function stcontrol stcontrol:setPowerID(vector2 vV)
	return setPower(this, nil, vV[1], vV[2])
end

__e2setcost(8)
e2function stcontrol stcontrol:setPowerID(array aA)
	return setPower(this, nil, aA[1], aA[2])
end

__e2setcost(8)
e2function stcontrol stcontrol:setPower(number nP, number nI, number nD)
	return setPower(this, nP, nI, nD)
end

__e2setcost(8)
e2function stcontrol stcontrol:setPower(array aA)
	return setPower(this, aA[1], aA[2], aA[3])
end

__e2setcost(8)
e2function stcontrol stcontrol:setPower(vector vV)
	return setPower(this, vV[1], vV[2], vV[3])
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
e2function number stcontrol:getErrorPast()
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
e2function number stcontrol:getTimePast()
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
	this.mnTo = nil; return this
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
e2function stcontrol stcontrol:setIsIntegral(number nN)
	if(not this) then return nil end
	this.meInt = (nN ~= 0); return this
end

__e2setcost(3)
e2function number stcontrol:isIntegral()
	if(not this) then return 0 end
	return (this.meInt and 1 or 0)
end

__e2setcost(3)
e2function stcontrol stcontrol:setIsDerivative(number nN)
	if(not this) then return nil end
	this.meDif = (nN ~= 0); return this
end

__e2setcost(3)
e2function number stcontrol:isDerivative()
	if(not this) then return 0 end
	return (this.meDif and 1 or 0)
end

__e2setcost(3)
e2function stcontrol stcontrol:setIsZeroCross(number nN)
	if(not this) then return nil end
	this.meZcx = (nN ~= 0); return this
end

__e2setcost(3)
e2function number stcontrol:isZeroCross()
	if(not this) then return 0 end
	return (this.meZcx and 1 or 0)
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
	return resState(this)
end

__e2setcost(20)
e2function stcontrol stcontrol:setState(number nR, number nO)
	if(not this) then return nil end
	return conProcess(this, nR, nO)
end

__e2setcost(7)
e2function stcontrol stcontrol:tuneAutoZN(number uK, number uT)
	return tuneZieglerNichols(this, uK, uT)
end

__e2setcost(7)
e2function stcontrol stcontrol:tuneAutoZN(number uK, number uT, string sM)
	return tuneZieglerNichols(this, uK, uT, nil, sM)
end

__e2setcost(7)
e2function stcontrol stcontrol:tuneProcZN(number uK, number uT, number uL, number nM)
	return tuneZieglerNichols(this, uK, uT, uL, nil, nM)
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
e2function stcontrol stcontrol:tuneProcAH(number nK, number nT, number nL)
	return tuneAstromHagglund(this, nK, nT, nL)
end

__e2setcost(7)
e2function stcontrol stcontrol:tuneProcISE(number nK, number nT, number nL)
	return tuneIE(this, nK, nT, nL, "ISE")
end

__e2setcost(7)
e2function stcontrol stcontrol:tuneProcIAE(number nK, number nT, number nL)
	return tuneIE(this, nK, nT, nL, "IAE")
end

__e2setcost(7)
e2function stcontrol stcontrol:tuneProcITAE(number nK, number nT, number nL)
	return tuneIE(this, nK, nT, nL, "ITAE")
end

__e2setcost(7)
e2function stcontrol stcontrol:tuneAutoTL(number uK, number uT)
	return tuneTyreusLuyben(this, uK, uT)
end

__e2setcost(15)
e2function stcontrol stcontrol:dumpItem(number nN)
	return dumpItem(this, nN)
end

__e2setcost(15)
e2function stcontrol stcontrol:dumpItem(string sN)
	return dumpItem(this, sN)
end

__e2setcost(15)
e2function stcontrol stcontrol:dumpItem(string nT, number nN)
	return dumpItem(this, nN, nT)
end

__e2setcost(15)
e2function stcontrol stcontrol:dumpItem(string nT, string sN)
	return dumpItem(this, sN, nT)
end
