--[[ ******************************************************************************
 My custom flash tracer tracer type ( Based on wire rangers )
****************************************************************************** ]]--

-- Register the type up here before the extension registration so that the ftrace still works
registerType("ftrace", "xft", nil,
	nil,
	nil,
	function(retval)
		if(retval == nil) then return end
		if(not istable(retval)) then error("Return value is neither nil nor a table, but a "..type(retval).."!",0) end
	end,
	function(v)
		return (not istable(v)) or (not v.StartPos)
	end
)

--[[ **************************** REGISTER **************************** ]]

E2Lib.RegisterExtension("ftrace", true,
	"Lets E2 chips trace ray attachments and check for hits.",
	"Creates a dedicated object oriented class that can perform customized ray defined traces and extract every aspect of the environment trace result."
)

-- Client and server have independent value
local gnIndependentUsed = bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_PRINTABLEONLY)
-- Server tells the client what value to use
local gnServerControled = bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_PRINTABLEONLY, FCVAR_REPLICATED)

local gvTransform = Vector() -- Temporary vector for transformation calculation
local gaTransform = Angle() -- Temporary angle for transformation calculation
local gsZeroStr   = "" -- Empty string to use instead of creating one everywhere
local gsFormFnc   = " FNC: [%d]{%s} Entity" -- This stores the hit parameters dump format
local gsFormEar   = " EAR: [%d]{%d}" -- This stores the hit parameters dump format
local gsFormDump  = "  [%s] : {%s} > {%s}" -- The format used for dumping SKIP/ONLY internals
local gsNotAvStr  = "N/A" -- What to print when something is not available
local gnMaxBeam   = 50000 -- The tracer maximum length just about one cube map
local gtEmptyVar  = {["#empty"]=true}; gtEmptyVar[gsZeroStr] = true -- Variable being set to empty string
local gsVarPrefx  = "wire_expression2_ftrace" -- This is used for variable prefix
local gtBoolToNum = {[true]=1,[false]=0} -- This is used to convert between GLua boolean and wire boolean
local gtMethList  = {} -- Place holder for blacklist and convar prefix
local gtConvEnab  = {["LW"] = LocalToWorld, ["WL"] = WorldToLocal} -- Coordinate conversion list
local varMethSkip = CreateConVar(gsVarPrefx.."_skip", gsZeroStr, gnServerControled, "FTrace entity black listed methods")
local varMethOnly = CreateConVar(gsVarPrefx.."_only", gsZeroStr, gnServerControled, "FTrace entity white listed methods")
local varEnStatus = CreateConVar(gsVarPrefx.."_enst",  0, gnIndependentUsed, "FTrace status output messages")
local varDefPrint = CreateConVar(gsVarPrefx.."_dprn", "TALK", gnServerControled, "FTrace default status output")
local gsFormLogs  = "E2{%s}{%d}:ftrace: %s" -- Contains the logs format of the addon
local gsDefPrint  = varDefPrint:GetString() -- Default print location
local gtPrintName = {} -- Contains the print location specification

--[[ **************************** CONFIGURATION **************************** ]]

gtPrintName["NOTIFY" ] = HUD_PRINTNOTIFY
gtPrintName["CONSOLE"] = HUD_PRINTCONSOLE
gtPrintName["TALK"   ] = HUD_PRINTTALK
gtPrintName["CENTER" ] = HUD_PRINTCENTER

--[[ **************************** PRIMITIVES **************************** ]]

local function isValid(vE, vT)
	if(vT) then local sT = tostring(vT or "")
		if(sT ~= type(vE)) then return false end end
	return (vE and vE.IsValid and vE:IsValid())
end

local function formDump(sS, sM, sV)
	return gsFormDump:format(tostring(sS), tostring(sM), tostring(sV))
end

local function formType(iD, sT)
	return gsFormFnc:format(iD, tostring(sT))
end

local function getNorm(tV)
	local nN = 0; if(not tV) then return nN end
	if(tonumber(tV)) then return math.abs(tV) end
	for ID = 1, 3 do local nV = tonumber(tV[ID]) or 0
		nN = nN + nV ^ 2 end; return math.sqrt(nN)
end

--[[
 * Picks the table when has values. Otherwise nil
 * Empty aggument is nil as nothing to be done
 * tT > The table to checked and picked (table or nil)
]]
local function pickTable(tT)
	if(not tT) then return nil end
	return ((next(tT) ~= nil) and tT or nil)
end

--[[
 * Outputs status messages in various places
 * sMsg  > Messave as any value type
 * oChip > Reference to an E2 chip
 * nPos  > Output location `HUD_%`
]]
local function logStatus(sMsg, oChip, nPos, ...)
	if(varEnStatus:GetBool()) then
		local nPos = (tonumber(nPos) or gtPrintName[gsDefPrint])
		local oPly, oEnt = oChip.player, oChip.entity
		local sNam, nEID = oPly:Nick() , oEnt:EntIndex()
		local sTxt = gsFormLogs:format(sNam, nEID, tostring(sMsg))
		oPly:PrintMessage(nPos, sTxt:sub(1, 200))
	end; return ...
end

--[[
 * Converts array of strings to hashed booleans
 * From T = {"test"} to T = {["test"] = true}
 * Array values are usually entity methods
 * tA > The table of number-indexed strings to convert
]]
local function convArrayKeys(tA)
	if(not tA) then return nil end
	for ID = 1, #tA do -- Convert the table from array to hash bools
		local key = tostring(tA[ID] or ""):gsub("%s+", "")
		if(not gtEmptyVar[key]) then tA[key] = true end; tA[ID] = nil
	end; return pickTable(tA) -- Write empty velue when table is empty
end

--[[ **************************** CALLBACKS **************************** ]]

cvars.RemoveChangeCallback(varMethSkip:GetName(), varMethSkip:GetName().."_call")
cvars.AddChangeCallback(varMethSkip:GetName(), function(sVar, vOld, vNew)
	gtMethList.SKIP = convArrayKeys(("/"):Explode(tostring(vNew or gsZeroStr)))
end, varMethSkip:GetName().."_call")

cvars.RemoveChangeCallback(varMethOnly:GetName(), varMethOnly:GetName().."_call")
cvars.AddChangeCallback(varMethOnly:GetName(), function(sVar, vOld, vNew)
	gtMethList.ONLY = convArrayKeys(("/"):Explode(tostring(vNew or gsZeroStr)))
end, varMethOnly:GetName().."_call")

cvars.RemoveChangeCallback(varDefPrint:GetName(), varDefPrint:GetName().."_call")
cvars.AddChangeCallback(varDefPrint:GetName(), function(sVar, vOld, vNew)
	local sK = tostring(vNew):upper(); if(gtPrintName[sK]) then gsDefPrint = sK end
end, varDefPrint:GetName().."_call")

--[[ **************************** WRAPPERS **************************** ]]

local function convDirLocal(oFTrc, vE, vA)
	if(not oFTrc) then return {0,0,0} end
	local oD, oE = oFTrc.mDir, (vE or oFTrc.mEnt)
	if(not (isValid(oE) or vA)) then return {oD[1], oD[2], oD[3]} end
	local oA = Angle(); if(vA) then
		oA:SetUnpacked(vA[1], vA[2], vA[3])
	else oA:Set(oE:GetAngles()) end; local oV = Vector(oD)
	return {oV:Dot(oA:Forward()), -oV:Dot(oA:Right()), oV:Dot(oA:Up())}
end -- Gmod +Y is the left direction

local function convDirWorld(oFTrc, vE, vA)
	if(not oFTrc) then return {0,0,0} end
	local oD, oE = oFTrc.mDir, (vE or oFTrc.mEnt)
	if(not (isValid(oE) or vA)) then return {oD[1], oD[2], oD[3]} end
	local oA = Angle(); if(vA) then
		oA:SetUnpacked(vA[1], vA[2], vA[3])
	else oA:Set(oE:GetAngles()) end; local oV = Vector(oD)
	oV:Rotate(oA); return {oV[1], oV[2], oV[3]}
end

local function convOrgEnt(oFTrc, sF, vE)
	if(not oFTrc) then return {0,0,0} end
	if(not gtConvEnab[sF or gsZeroStr]) then return {0,0,0} end
	local oO, oE = oFTrc.mPos, (vE or oFTrc.mEnt)
	if(not isValid(oE)) then return {oO[1], oO[2], oO[3]} end
	local oV = Vector(oO); oV:Set(oE[sF](oE, oV))
	return {oV:Unpack()}
end

local function convOrgUCS(oFTrc, sF, vP, vA)
	if(not oFTrc) then return {0,0,0} end
	if(not gtConvEnab[sF or gsZeroStr]) then return {0,0,0} end
	local oO, oE = oFTrc.mPos, (vE or oFTrc.mEnt)
	if(not isValid(oE)) then return {oO[1], oO[2], oO[3]} end
	local oV, oA = Vector(oO), Angle()
	local uP, uA = gvTransform, gaTransform
	uP:SetUnpacked(vP[1], vP[2], vP[3])
	uA:SetUnpacked(vA[1], vA[2], vA[3])
	local vN, aN = gtConvEnab[sF](oV, oA, uP, uA); oV:Set(vN)
	return {oV:Unpack()}
end

local function vecMultiply(vV, nX, nY, nZ)
	vV.x, vV.y, vV.z = (vV.x * nX), (vV.y * nY), (vV.z * nZ)
	return vV -- returned the first argument scaled vector
end

local function vecDivide(vV, nX, nY, nZ)
	vV.x, vV.y, vV.z = (vV.x / nX), (vV.y / nY), (vV.z / nZ)
	return vV -- returned the first argument scaled vector
end

--[[ Returns the hit status based on filter parameters
 * oF > The filter to be checked
 * vK > Value key to be checked
 * Returns:
 * 1) The status of the filter (1,2,3)
 * 2) The value to return for the status
]] local vFnc, vSkp, vNop = true, nil, nil
local function getFncStatus(oF, vK)
	-- Skip current setting on empty data type
	if(not oF.TYPE) then return 1, vNop end
	if(vK ~= nil) then -- Value used for indexing
		local tO, tS = pickTable(oF.ONLY), pickTable(oF.SKIP)
		-- Check for only whitelisted method values
		if(tO) then if(tO[vK]) then return 3, vFnc else return 2, vSkp end end
		-- Check the blacklisted method values later
		if(tS) then if(tS[vK]) then return 2, vSkp else return 1, vNop end end
	end; return 1, vNop -- Check next setting on empty table
end

local function newFncFilter(oFTrc, sM)
	if(not oFTrc) then return 0 end; local oChip = oFTrc.mChip
	if(sM:sub(1,3) ~= "Get" and sM:sub(1,2) ~= "Is" and sM ~= gsZeroStr) then
		return logStatus("Method <"..sM.."> disabled", oChip, nil, 0) end
	local tFnc = oFTrc.mFnc; if(tFnc.ID[sM]) then -- Check for available method
		return logStatus("Method <"..sM.."> exists", oChip, nil, 0) end
	if(not oChip.entity[sM]) then -- Check for method availability in entity
		return logStatus("Method <"..sM.."> mismatch", oChip, nil, 0) end
	local tO = pickTable(gtMethList.ONLY); if(tO and not tO[sM]) then
		return logStatus("Method <"..sM.."> use only", oChip, nil, 0) end
	local tS = pickTable(gtMethList.SKIP); if(tS and tS[sM]) then
		return logStatus("Method <"..sM.."> use skip", oChip, nil, 0) end
	tFnc.Size = (tFnc.Size + 1); tFnc[tFnc.Size] = {CALL = sM}
	tFnc.ID[sM] = tFnc.Size; return (tFnc.Size)
end

local function remFncFilter(oFTrc, sM)
	if(not oFTrc) then return nil end
	local tFnc = oFTrc.mFnc; if(not tFnc) then return oFTrc end
	local ID = tFnc.ID[sM]; if(not ID) then return oFTrc end
	tFnc.Size = (tFnc.Size - 1); table.remove(tFnc, ID)
	for IH = 1, tFnc.Size do local HM = tFnc[IH].CALL
		tFnc.ID[HM] = IH end; tFnc.ID[sM] = nil; return oFTrc
end

--[[
 * Registers method and its return value in the function hit list
 * oFTrc > Reference to tracer object
 * sM    > Entity method to register in the configuration
 * sO    > Registration mode eithr being ( SKIP or ONLY )
 * vV    > The data that functional filter will compare
 * bS    > Status configuration flag ( any value )
]]
local function setFncFilter(oFTrc, sM, sO, vV, bS)
	if(not oFTrc) then return nil end
	local tFnc, sTyp = oFTrc.mFnc, type(vV) -- Obtain hit filter location
	local nID, oChip = tFnc.ID[sM], oFTrc.mChip -- Obtain E2 chip description
	if(not nID) then nID = newFncFilter(oFTrc, sM) end -- Obtain the current data index
	local tID = tFnc[nID]; if(not tID) then -- Check the current data type and prevent messing up
		return logStatus("ID mismatch <"..nID.."@"..sM..">", oChip, nil, oFTrc) end
	if(not tID.TYPE) then tID.TYPE = type(vV) end -- When data type is not yet present fill it up
	if(tID.TYPE ~= sTyp) then -- Check the current data type and prevent the user from messing up
		return logStatus("Type "..sTyp.." mismatch <"..tID.TYPE.."@"..sM..">", oChip, nil, oFTrc) end
	if(not tID[sO]) then tID[sO] = {} end
	if(sM:sub(1,2) == "Is" and sTyp == "number") then
		tID[sO][((vV ~= 0) and 1 or 0)] = bS
	else tID[sO][vV] = bS end; return oFTrc
end

local function convFncValue(oEnt, sM)
	local vV = oEnt[sM](oEnt) -- Call method
	if(sM:sub(1,2) == "Is") then -- Check name
		vV = gtBoolToNum[vV] -- Convert boolean
	end; return vV -- Return converted value
end

local function trcLocal(oFTrc, eB, vP, vA)
	if(not oFTrc) then return nil end
	local eE = (eB and eB or oFTrc.mEnt)
	local eP, eA = gvTransform, gaTransform
	if(isValid(eE)) then eP:Set(eE:GetPos()); eA:Set(eE:GetAngles()) end
	if(vP) then eP:SetUnpacked(vP[1], vP[2], vP[3]) end
	if(vA) then eA:SetUnpacked(vA[1], vA[2], vA[3]) end
	local trS, trE = oFTrc.mTrI.start, oFTrc.mTrI.endpos
	trS:Set(oFTrc.mPos); trS:Rotate(eA); trS:Add(eP)
	trE:Set(oFTrc.mDir); trE:Rotate(eA); trE:Add(trS)
	-- https://wiki.facepunch.com/gmod/util.TraceLine
	util.TraceLine(oFTrc.mTrI); return oFTrc
end

local function trcWorld(oFTrc, eE, vP, vA)
	if(not oFTrc) then return nil end
	local eP, eA = gvTransform, gaTransform
	eP:Set(oFTrc.mPos); eA:Set(oFTrc.mDir:Angle())
	if(isValid(eE)) then eP:Set(eE:GetPos()); eA:Set(eE:GetAngles()) end
	if(vP) then eP:SetUnpacked(vP[1], vP[2], vP[3]) end
	if(vA) then eA:SetUnpacked(vA[1], vA[2], vA[3]) end
	local trS, trE = oFTrc.mTrI.start, oFTrc.mTrI.endpos
	trS:Set(eP); trE:Set(eA:Forward())
	trE:Mul(oFTrc.mLen); trE:Add(trS)
	-- https://wiki.facepunch.com/gmod/util.TraceLine
	util.TraceLine(oFTrc.mTrI); return oFTrc
end

local function updateEarSize(oFTrc)
	if(not oFTrc) then return nil end
	local tE, iE = oFTrc.mFlt.Ear, 1
	while(tE[iE]) do local vE = tE[iE]
		if(isValid(vE)) then iE = iE + 1
		else table.remove(tE, iE) end
	end; oFTrc.mFlt.Size = (iE - 1)
	return oFTrc
end

--[[
 * Moves only the entities from source to destination
 * oFTrc > Reference to tracer object
 * tData > Source data table to read from ( entity array )
 * bTab  > When enabled process as table instead of array
 * bID   > When enabled the source table contains entity ID
]]
local function putFilterEar(oFTrc, tData, bTab, bID)
	if(not oFTrc) then return nil end
	local tE = oFTrc.mFlt.Ear
	if(bTab) then
		for iD = 1, #tData do
			local vE, eE = tData[iD]
			if(bID) then
				local iE = math.floor(tonumber(vE) or 0)
				if(iE > 0) then eE = Entity(iE) end
			else eE = vE end
			if(isValid(eE, "Entity")) then
				table.insert(tE, eE)
			end
		end
	else
		for iD, vE in pairs(tData) do local eE
			if(bID) then
				local iE = math.floor(tonumber(vE) or 0)
				if(iE > 0) then eE = Entity(iE) end
			else eE = vE end
			if(isValid(eE, "Entity")) then
				table.insert(tE, eE)
			end
		end
	end; return updateEarSize(oFTrc)
end

--[[
 * Moves only the entities from source to destination
 * oFTrc > Reference to tracer object
 * tData > Source data table to read from ( function filter )
]]
local function putFilterFnc(oFTrc, tData)
	if(not oFTrc) then return nil end
	if(not tData) then return oFTrc end
	for iD = 1, tData.Size do local vD = tData[iD]
		-- Transfer the SKIP configuration for the table
		if(vD.SKIP) then for key, val in pairs(vD.SKIP) do
			setFncFilter(oFTrc, vD.CALL, "SKIP", key, true) end end
		-- Transfer the ONLY configuration for the table
		if(vD.ONLY) then for key, val in pairs(vD.ONLY) do
			setFncFilter(oFTrc, vD.CALL, "ONLY", key, true) end end
	end
	-- Transsfer referencies from the entity array
	for key, val in pairs(tData.Ent.SKIP) do
		oFTrc.mFnc.Ent.SKIP[key] = val end
	for key, val in pairs(tData.Ent.ONLY) do
		oFTrc.mFnc.Ent.ONLY[key] = val end
	return oFTrc -- Return the reference of the tracer
end

--[[
 * Returns copy array for the entity filter list
 * oFTrc > Reference to tracer object
 * bID   > When enabled the table contains entity ID
]]
local function getEntityList(oFTrc, bID)
	if(not oFTrc) then return nil end
	local tE, tO, iO = oFTrc.mFlt.Ear, {}, 0
	for iD = 1, #tE do
		local vE = tE[iD]
		if(isValid(vE)) then
			iO = iO + 1
			if(bID) then
				tO[iO] = vE:EntIndex()
			else tO[iO] = vE end
		end
	end; return tO
end

local function getFilterMode(oFTrc)
	if(not oFTrc) then return "XX" end -- Unavailable
	local tF = oFTrc.mTrI.filter -- Filter table reference
	if    (tF == oFTrc.mFlt.Ear) then return "AR" -- Entity index array
	elseif(tF == oFTrc.mFlt.Fnc) then return "FN" -- Function routine
	elseif(tF == oFTrc.mFlt.Enu) then return "EU" -- Entity unit
	end; return "NA" -- Filter for ftrace is not available
end

local function dumpTracer(oFTrc, sNam, sPos)
	local sP = tostring(sPos or gsDefPrint)
	local nP, oChip = gtPrintName[sP], oFTrc.mChip
	if(not nP) then return oFTrc end
	logStatus("["..tostring(sNam or gsNotAvStr).."] Data:", oChip, nP)
	logStatus(" LEN: "..tostring(oFTrc.mLen or gsNotAvStr), oChip, nP)
	logStatus(" POS: "..tostring(oFTrc.mPos or gsNotAvStr), oChip, nP)
	logStatus(" DIR: "..tostring(oFTrc.mDir or gsNotAvStr), oChip, nP)
	logStatus(" ENT: "..tostring(oFTrc.mEnt or gsNotAvStr), oChip, nP)
	logStatus(" E2 : "..tostring(oChip.entity or gsNotAvStr), oChip, nP)
	logStatus(" FMD: "..getFilterMode(oFTrc), oChip, nP)
	local tFnc = oFTrc.mFnc -- Read the general hit list
	local tEnt = tFnc.Ent   -- Read the direct hit entities list
	logStatus(formType(0, tEnt.TYPE), oChip, nP)
	tS = pickTable(tEnt.SKIP); if(tS) then -- Read entity skip list when available
		for kS, vS in pairs(tS) do logStatus(formDump("SKIP", kS, vS), oChip, nP) end end
	tO = pickTable(tEnt.ONLY); if(tO) then -- Read entity only list when available
		for kO, vO in pairs(tO) do logStatus(formDump("ONLY", kO, vO), oChip, nP) end end
	local nSz = tFnc.Size; if(nSz <= 0) then return oFTrc end
	for iH = 1, nSz do local tID = tFnc[iH]; tS, tO = tID.SKIP, tID.ONLY
		logStatus(formType(iH, tID.TYPE)..":"..tostring(tID.CALL or gsNotAvStr), oChip, nP)
		if(tS) then for kS, vS in pairs(tS) do logStatus(formDump("SKIP", kS, vS), oChip, nP) end end
		if(tO) then for kO, vO in pairs(tO) do logStatus(formDump("ONLY", kO, vO), oChip, nP) end end
	end
	local tF = pickTable(oFTrc.mFlt.Ear)
	if(tF) then
		local nF = oFTrc.mFlt.Size -- Total amaunt of entities in the array
		local nL = tostring(nF):len() -- Aligment length for the key index
		local fF = ("%"..nL.."d") -- Generate format string for aligment
		logStatus(gsFormEar:format(nF, nL), oChip, nP)
		for iF = 1, nF do local vE, sC, iC = tF[iF], gsNotAvStr, 0
			if(isValid(vE)) then sC, iC = vE:GetClass(), vE:EntIndex() end
			logStatus(formDump(fF:format(iF), iC, sC), oChip, nP)
		end
	end; return oFTrc -- The dump method returns a pointer to the current instance
end

--[[
 * Creates a new flash tracer
 * oChip > Reference to expression chip
 * vEnt  > Tracer relation entity reference for local sampling
 * vPos  > Tracer position reference in local or word coordinates
 * vDir  > Tracer direction reference in local or word coordinates
 * nLen  > Tracer length number in source engine units
]]
local function newTracer(oChip, vEnt, vPos, vDir, nLen)
	local eChip = oChip.entity; if(not isValid(eChip)) then
		return logStatus("Entity invalid", oChip, nil, nil) end
	local oFTrc, ncDir, ncLen = {}, getNorm(vDir), (tonumber(nLen) or 0)
	oFTrc.mChip, oFTrc.mFnc, oFTrc.mFlt = oChip, {Size = 0, ID = {}}, {};
	oFTrc.mFnc.Ent = {SKIP = {}, ONLY = {}, TYPE = type(eChip)} -- No entities in ONLY or SKIP by default
	if(isValid(vEnt)) then oFTrc.mEnt = vEnt else oFTrc.mEnt = nil end -- Make sure the entity is cleared
	oFTrc.mPos, oFTrc.mDir = Vector(), Vector(0, 0, 1)
	if(vPos) then -- Local tracer position the trace starts from
		oFTrc.mPos:SetUnpacked(vPos[1], vPos[2], vPos[3]) end
	if(vDir and ncDir > 0) then -- Local tracer direction to read the data from
		oFTrc.mDir:SetUnpacked(vDir[1], vDir[2], vDir[3]) end
	-- How long the flash tracer length will be. Must be positive
	oFTrc.mLen = (ncLen == 0 and ncDir or ncLen)
	oFTrc.mLen = math.Clamp(oFTrc.mLen, -gnMaxBeam, gnMaxBeam)
	-- Internal fail safe configurations
	oFTrc.mDir:Normalize() -- Normalize the direction
	oFTrc.mDir:Mul(oFTrc.mLen) -- Multiply to add in real-time
	oFTrc.mLen = math.abs(oFTrc.mLen) -- Length to absolute
	-- Configure trace settings filter method and data
	oFTrc.mFlt.Fnc = function(oEnt) -- This is used for custom filtering
		if(not isValid(oEnt)) then return end -- Exit when entity invalid
		local tFnc = oFTrc.mFnc -- Store reference to the trace hit list
		local nS, vV = getFncStatus(tFnc.Ent, oEnt) -- Check the entity
		if(nS > 1) then return vV end -- Entity found or skipped return
		if(tFnc.Size > 0) then -- Swipe trough the other lists available
			for IH = 1, tFnc.Size do local vFnc = tFnc[IH] -- Read list conf
				local vC = convFncValue(oEnt, vFnc.CALL) -- Extract entity value
				local nS, vV = getFncStatus(vFnc, vC) -- Check extracted value
				if(nS > 1) then return vV end -- Option skipped or selected return
			end -- All options are checked then trace hit normally routine
		end; return true -- Finally we register the trace hit enabled
	end -- Defines a general universal filter finction may be slower
	oFTrc.mFlt.Enu  = nil -- Direct entity filter place holder unit
	oFTrc.mFlt.Ear  = {} -- Direct entity filter place holder array
	oFTrc.mFlt.Size = 0 -- Direct entity filter place holder size
	-- https://wiki.facepunch.com/gmod/Structures/TraceResult
	oFTrc.mTrO = {} -- Trace output parameters
	-- https://wiki.facepunch.com/gmod/Structures/Trace
	oFTrc.mTrI = { -- Trace input parameters
		mask = MASK_SOLID, -- Mask telling the trace what to hit
		start = Vector(), -- The start position of the trace
		output = oFTrc.mTrO, -- Provide output place holder table
		endpos = Vector(), -- The end position of the trace
		filter = nil, -- By default there is no filter configured
		ignoreworld = false, -- Should the trace ignore world or not
		collisiongroup = COLLISION_GROUP_NONE } -- Collision group control
	return oFTrc -- Return the created tracer object
end

--[[ **************************** TRACER **************************** ]]

registerOperator("ass", "xft", "xft", function(self, args)
	local lhs, op2, scope = args[2], args[3], args[4]
	local rhs = op2[1](self, op2)
	self.Scopes[scope][lhs] = rhs
	self.Scopes[scope].vclk[lhs] = true
	return rhs
end)

--[[ **************************** CREATE **************************** ]]

__e2setcost(1)
e2function ftrace noFTrace()
	return nil
end

__e2setcost(20)
e2function ftrace entity:setFTrace(vector vP, vector vD, number nL)
	return newTracer(self, this, vP, vD, nL)
end

__e2setcost(20)
e2function ftrace newFTrace(vector vP, vector vD, number nL)
	return newTracer(self, nil, vP, vD, nL)
end

__e2setcost(20)
e2function ftrace entity:setFTrace(vector vP, vector vD)
	return newTracer(self, this, vP, vD)
end

__e2setcost(20)
e2function ftrace newFTrace(vector vP, vector vD)
	return newTracer(self, nil, vP, vD)
end

__e2setcost(20)
e2function ftrace entity:setFTrace(vector vP, number nL)
	return newTracer(self, this, vP, nil, nL)
end

__e2setcost(20)
e2function ftrace newFTrace(vector vP, number nL)
	return newTracer(self, nil, vP, nil, nL)
end

__e2setcost(20)
e2function ftrace entity:setFTrace(vector vP)
	return newTracer(self, this, vP, nil, nil)
end

__e2setcost(20)
e2function ftrace newFTrace(vector vP)
	return newTracer(self, nil, vP, nil, nil)
end

__e2setcost(20)
e2function ftrace entity:setFTrace(number nL)
	return newTracer(self, this, nil, nil, nL)
end

__e2setcost(20)
e2function ftrace newFTrace(number nL)
	return newTracer(self, nil, nil, nil, nL)
end

__e2setcost(20)
e2function ftrace entity:setFTrace()
	return newTracer(self, this, nil, nil, nil)
end

__e2setcost(20)
e2function ftrace newFTrace()
	return newTracer(self, nil, nil, nil, nil)
end

--[[ **************************** COPY **************************** ]]

__e2setcost(20)
e2function ftrace ftrace:getCopy(entity eE, vector vP, vector vD, number nL)
	return newTracer(self, eE, vP, vD, nL)
end

__e2setcost(20)
e2function ftrace ftrace:getCopy(vector vP, vector vD, number nL)
	return newTracer(self, this.mEnt, vP, vD, nL)
end

__e2setcost(20)
e2function ftrace ftrace:getCopy(entity eE, vector vP, vector vD)
	return newTracer(self, eE, vP, vD, this.mLen)
end

__e2setcost(20)
e2function ftrace ftrace:getCopy(vector vP, vector vD)
	return newTracer(self, this.mEnt, vP, vD, this.mLen)
end

__e2setcost(20)
e2function ftrace ftrace:getCopy(entity eE, vector vP, number nL)
	return newTracer(self, eE, vP, this.mDir, nL)
end

__e2setcost(20)
e2function ftrace ftrace:getCopy(vector vP, number nL)
	return newTracer(self, this.mEnt, vP, this.mDir, nL)
end

__e2setcost(20)
e2function ftrace ftrace:getCopy(entity eE, vector vP)
	return newTracer(self, eE, vP, this.mDir, this.mLen)
end

__e2setcost(20)
e2function ftrace ftrace:getCopy(vector vP)
	return newTracer(self, this.mEnt, vP, this.mDir, this.mLen)
end

__e2setcost(20)
e2function ftrace ftrace:getCopy(entity eE, number nL)
	return newTracer(self, eE, this.mPos, this.mDir, nL)
end

__e2setcost(20)
e2function ftrace ftrace:getCopy(number nL)
	return newTracer(self, this.mEnt, this.mPos, this.mDir, nL)
end

__e2setcost(20)
e2function ftrace ftrace:getCopy(entity eE)
	return newTracer(self, eE, this.mPos, this.mDir, this.mLen)
end

__e2setcost(20)
e2function ftrace ftrace:getCopy()
	return newTracer(self, this.mEnt, this.mPos, this.mDir, this.mLen)
end

--[[ **************************** FILTER COPY **************************** ]]

__e2setcost(3)
e2function ftrace ftrace:useFilterUnit(ftrace oT)
	if(not this) then return nil end
	if(not oT) then return this end
	this.mFlt.Enu = oT.mFlt.Enu; return this
end

__e2setcost(3)
e2function ftrace ftrace:useFilterArray(ftrace oT)
	if(not this) then return nil end
	if(not oT) then return this end
	this.mFlt.Ear = oT.mFlt.Ear; return this
end

__e2setcost(12)
e2function ftrace ftrace:cpyFilterArray(ftrace oT)
	if(not this) then return nil end
	if(not oT) then return this end
	return putFilterEar(this, oT.mFlt.Ear, false, false)
end

__e2setcost(3)
e2function ftrace ftrace:useFilterAction(ftrace oT)
	if(not this) then return nil end
	if(not oT) then return this end
	this.mFlt.Fnc = oT.mFlt.Fnc; return this
end

__e2setcost(12)
e2function ftrace ftrace:cpyFilterAction(ftrace oT)
	return putFilterFnc(this, oT.mFnc)
end

--[[ **************************** FILTER CHANGE **************************** ]]

__e2setcost(3)
e2function string ftrace:getFilterMode()
	return getFilterMode(this)
end

__e2setcost(3)
e2function ftrace ftrace:remFilter()
	if(not this) then return nil end
	this.mTrI.filter = nil; return this
end

__e2setcost(3)
e2function ftrace ftrace:setFilterArray()
	if(not this) then return nil end
	this.mTrI.filter = this.mFlt.Ear; return this
end

__e2setcost(3)
e2function ftrace ftrace:setFilterUnit()
	if(not this) then return nil end
	if(not isValid(vE)) then return nil end
	this.mTrI.filter = this.mFlt.Enu; return this
end

__e2setcost(3)
e2function ftrace ftrace:setFilterAction()
	if(not this) then return nil end
	this.mTrI.filter = this.mFlt.Fnc; return this
end

--[[ **************************** ENTITY UNIT FILTER **************************** ]]

__e2setcost(3)
e2function ftrace ftrace:putUnit(entity vE)
	if(not this) then return nil end
	if(not isValid(vE)) then return this end
	this.mFlt.Enu = vE; return this
end

__e2setcost(3)
e2function entity ftrace:getUnit()
	if(not this) then return nil end
	return this.mFlt.Enu
end

__e2setcost(3)
e2function ftrace ftrace:remUnit()
	if(not this) then return nil end
	if(not isValid(vE)) then return this end
	this.mFlt.Enu = nil; return this
end

--[[ **************************** FUNCTION ENTITY FILTER **************************** ]]

__e2setcost(3)
e2function ftrace ftrace:putActionSkipEnt(entity vE)
	if(not this) then return nil end
	if(not isValid(vE)) then return this end
	this.mFnc.Ent.SKIP[vE] = true; return this
end

e2function ftrace ftrace:addEntHitSkip(entity vE) = e2function ftrace ftrace:putActionSkipEnt(entity vE)

__e2setcost(3)
e2function ftrace ftrace:remActionSkipEnt(entity vE)
	if(not this) then return nil end
	if(not isValid(vE)) then return this end
	this.mFnc.Ent.SKIP[vE] = nil; return this
end

e2function ftrace ftrace:remEntHitSkip(entity vE) = e2function ftrace ftrace:remActionSkipEnt(entity vE)

__e2setcost(3)
e2function ftrace ftrace:remActionSkipEnt()
	if(not this) then return nil end
	table.Empty(this.mFnc.Ent.SKIP); return this
end

e2function ftrace ftrace:remEntHitSkip() = e2function ftrace ftrace:remActionSkipEnt()

__e2setcost(3)
e2function ftrace ftrace:putActionOnlyEnt(entity vE)
	if(not this) then return nil end
	if(not isValid(vE)) then return this end
	this.mFnc.Ent.ONLY[vE] = true; return this
end

e2function ftrace ftrace:addEntHitOnly(entity vE) = e2function ftrace ftrace:putActionOnlyEnt(entity vE)

__e2setcost(3)
e2function ftrace ftrace:remActionOnlyEnt(entity vE)
	if(not this) then return nil end
	if(not isValid(vE)) then return this end
	this.mFnc.Ent.ONLY[vE] = nil; return this
end

e2function ftrace ftrace:remEntHitOnly(entity vE) = e2function ftrace ftrace:remActionOnlyEnt(entity vE)

__e2setcost(3)
e2function ftrace ftrace:remActionOnlyEnt()
	if(not this) then return nil end
	table.Empty(this.mFnc.Ent.ONLY); return this
end

e2function ftrace ftrace:remEntHitOnly() = e2function ftrace ftrace:remActionOnlyEnt()

__e2setcost(3)
e2function ftrace ftrace:remActionEnt()
	if(not this) then return nil end
	table.Empty(this.mFnc.Ent.SKIP)
	table.Empty(this.mFnc.Ent.ONLY); return this
end

e2function ftrace ftrace:remEntHit() = e2function ftrace ftrace:remActionEnt()

--[[ **************************** ENTITY ARRAY FILTER **************************** ]]

__e2setcost(3)
e2function ftrace ftrace:putArray(array vR)
	return putFilterEar(this, vR, false, false)
end

__e2setcost(3)
e2function ftrace ftrace:putArray(table vT)
	return putFilterEar(this, vT, true, false)
end

__e2setcost(3)
e2function ftrace ftrace:putArray(entity vE)
	return putFilterEar(this, {vE}, false, false)
end

__e2setcost(3)
e2function array ftrace:getArray()
	return getEntityList(this, false)
end

__e2setcost(3)
e2function ftrace ftrace:putArrayID(array vR)
	return putFilterEar(this, vR, false, true)
end

__e2setcost(3)
e2function ftrace ftrace:putArrayID(table vT)
	return putFilterEar(this, vT, true, true)
end

__e2setcost(3)
e2function ftrace ftrace:putArrayID(number iE)
	return putFilterEar(this, {math.floor(iE)}, false, true)
end

__e2setcost(3)
e2function array ftrace:getArrayID()
	return getEntityList(this, true)
end

__e2setcost(3)
e2function number ftrace:getArraySZ()
	if(not this) then return nil end
	return this.mFlt.Size
end

__e2setcost(3)
e2function ftrace ftrace:updArraySZ()
	return updateEarSize()
end

--[[ **************************** REMOVE ENTITY ARRAY ITEMS **************************** ]]

__e2setcost(3)
e2function ftrace ftrace:remArrayN(number iN)
	if(not this) then return nil end
	table.remove(this.mFlt.Ear, math.floor(iN))
	return updateEarSize(this)
end

__e2setcost(3)
e2function ftrace ftrace:remArrayID(number iE)
	if(not this) then return nil end
	local tE = this.mFlt.Ear
	local vE = Entity(math.floor(iE))
	local iN = table.KeyFromValue(tE, vE)
	if(iN) then table.remove(tE, iN) end
	return updateEarSize(this)
end

__e2setcost(3)
e2function ftrace ftrace:remArray(entity vE)
	if(not this) then return nil end
	if(not isValid(vE)) then return this end
	local tE = this.mFlt.Ear
	local iN = table.KeyFromValue(tE, vE)
	if(iN) then table.remove(tE, iN) end
	return updateEarSize(this)
end

__e2setcost(3)
e2function ftrace ftrace:remArray()
	if(not this) then return nil end
	table.Empty(this.mFlt.Ear)
	return updateEarSize(this)
end

--[[ **************************** REMOVE FUNCTION ITEMS **************************** ]]

__e2setcost(3)
e2function ftrace ftrace:remAction()
	if(not this) then return nil end
	local tID = this.mFnc.ID
	for key, id in pairs(tID) do
		remFncFilter(this, key)
	end; return this
end

e2function ftrace ftrace:remHit() = e2function ftrace ftrace:remAction()

__e2setcost(3)
e2function ftrace ftrace:remAction(string sM)
	return remFncFilter(this, sM)
end

e2function ftrace ftrace:remHit(string sM) = e2function ftrace ftrace:remAction(string sM)

--[[ **************************** FUNCTION NUMBER **************************** ]]

__e2setcost(3)
e2function ftrace ftrace:putActionSkip(string sM, number vN)
	return setFncFilter(this, sM, "SKIP", vN, true)
end

e2function ftrace ftrace:addHitSkip(string sM, number vN) = e2function ftrace ftrace:putActionSkip(string sM, number vN)

__e2setcost(3)
e2function ftrace ftrace:remActionSkip(string sM, number vN)
	return setFncFilter(this, sM, "SKIP", vN, nil)
end

e2function ftrace ftrace:remHitSkip(string sM, number vN) = e2function ftrace ftrace:remActionSkip(string sM, number vN)

__e2setcost(3)
e2function ftrace ftrace:putActionOnly(string sM, number vN)
	return setFncFilter(this, sM, "ONLY", vN, true)
end

e2function ftrace ftrace:addHitOnly(string sM, number vN) = e2function ftrace ftrace:putActionOnly(string sM, number vN)

__e2setcost(3)
e2function ftrace ftrace:remActionOnly(string sM, number vN)
	return setFncFilter(this, sM, "ONLY", vN, nil)
end

e2function ftrace ftrace:remHitOnly(string sM, number vN) = e2function ftrace ftrace:remActionOnly(string sM, number vN)

--[[ **************************** FUNCTION STRING **************************** ]]

__e2setcost(3)
e2function ftrace ftrace:putActionSkip(string sM, string vS)
	return setFncFilter(this, sM, "SKIP", vS, true)
end

e2function ftrace ftrace:addHitSkip(string sM, string vS) = e2function ftrace ftrace:putActionSkip(string sM, string vS)

__e2setcost(3)
e2function ftrace ftrace:remActionSkip(string sM, string vS)
	return setFncFilter(this, sM, "SKIP", vS, nil)
end

e2function ftrace ftrace:remHitSkip(string sM, string vS) = e2function ftrace ftrace:remActionSkip(string sM, string vS)

__e2setcost(3)
e2function ftrace ftrace:putActionOnly(string sM, string vS)
	return setFncFilter(this, sM, "ONLY", vS, true)
end

e2function ftrace ftrace:addHitOnly(string sM, string vS) = e2function ftrace ftrace:putActionOnly(string sM, string vS)

__e2setcost(3)
e2function ftrace ftrace:remActionOnly(string sM, string vS)
	return setFncFilter(this, sM, "ONLY", vS, nil)
end

e2function ftrace ftrace:remHitOnly(string sM, string vS) = e2function ftrace ftrace:remActionOnly(string sM, string vS)

--[[ **************************** RAY **************************** ]]

__e2setcost(3)
e2function ftrace ftrace:rayMove()
	if(not this) then return nil end
	this.mPos:Add(this.mDir); return this
end

__e2setcost(3)
e2function ftrace ftrace:rayMove(number nL)
	if(not this) then return nil end
	local vD = this.mDir:GetNormalized()
	vD:Mul(nL); this.mPos:Add(vD); return this
end

__e2setcost(3)
e2function ftrace ftrace:rayMove(vector vV)
	if(not this) then return nil end
	local vD = Vector(vV[1], vV[2], vV[3])
	this.mPos:Add(vD); return this
end

__e2setcost(3)
e2function ftrace ftrace:rayMove(number nX, number nY, number nZ)
	if(not this) then return nil end
	local vD = Vector(nX, nY, nZ)
	this.mPos:Add(vD); return this
end

__e2setcost(3)
e2function ftrace ftrace:rayMove(vector vV, number nL)
	if(not this) then return nil end
	local vD = Vector(vV[1], vV[2], vV[3])
	vD:Normalize(); vD:Mul(nL); this.mPos:Add(vD); return this
end

__e2setcost(3)
e2function ftrace ftrace:rayAmend(vector vV)
	if(not this) then return nil end
	local vD = Vector(vV[1], vV[2], vV[3])
	this.mDir:Add(vD); return this
end

__e2setcost(3)
e2function ftrace ftrace:rayAmend(number nX, number nY, number nZ)
	if(not this) then return nil end
	local vD = Vector(nX, nY, nZ)
	this.mDir:Add(vD); return this
end

__e2setcost(3)
e2function ftrace ftrace:rayAmend(vector vV, number nL)
	if(not this) then return nil end
	local vD = Vector(vV[1], vV[2], vV[3])
	vD:Normalize(); vD:Mul(nL); this.mDir:Add(vD); return this
end

__e2setcost(3)
e2function ftrace ftrace:rayMul(number nN)
	if(not this) then return nil end
	this.mLen = this.mLen * nN; this.mDir:Normalize()
	this.mDir:Mul(this.mLen); return this
end

__e2setcost(3)
e2function ftrace ftrace:rayMul(vector vV)
	if(not this) then return nil end
	vecMultiply(this.mDir, vV[1], vV[2], vV[3])
	this.mLen = this.mDir:Length(); return this
end

__e2setcost(3)
e2function ftrace ftrace:rayMul(number nX, number nY, number nZ)
	if(not this) then return nil end
	vecMultiply(this.mDir, nX, nY, nZ)
	this.mLen = this.mDir:Length(); return this
end

__e2setcost(3)
e2function ftrace ftrace:rayDiv(number nN)
	if(not this) then return nil end
	this.mLen = this.mLen / nN; this.mDir:Normalize()
	this.mDir:Mul(this.mLen); return this
end

__e2setcost(3)
e2function ftrace ftrace:rayDiv(vector vV)
	if(not this) then return nil end
	vecDivide(this.mDir, vV[1], vV[2], vV[3])
	this.mLen = this.mDir:Length(); return this
end

__e2setcost(3)
e2function ftrace ftrace:rayDiv(number nX, number nY, number nZ)
	if(not this) then return nil end
	vecDivide(this.mDir, nX, nY, nZ)
	this.mLen = this.mDir:Length(); return this
end

__e2setcost(3)
e2function ftrace ftrace:rayAim(vector vV)
	if(not this) then return nil end
	local vD = Vector(vV[1], vV[2], vV[3])
	vD:Sub(this.mPos); vD:Normalize()
	vD:Mul(this.mLen); this.mDir:Set(vD)
	return this
end

__e2setcost(3)
e2function ftrace ftrace:rayAim(number nX, number nY, number nZ)
	if(not this) then return nil end
	local vD = Vector(nX, nY, nZ)
	vD:Sub(this.mPos); vD:Normalize()
	vD:Mul(this.mLen); this.mDir:Set(vD)
	return this
end

--[[ **************************** CHIP **************************** ]]

__e2setcost(3)
e2function entity ftrace:getChip()
	if(not this) then return nil end;
	local vE = this.mChip.entity
	if(not isValid(vE)) then return nil end; return vE
end

__e2setcost(3)
e2function entity ftrace:getPlayer()
	if(not this) then return nil end;
	local vE = this.mChip.player
	if(not isValid(vE)) then return nil end; return vE
end

--[[ **************************** BASE **************************** ]]

__e2setcost(3)
e2function entity ftrace:getBase()
	if(not this) then return nil end; local vE = this.mEnt
	if(not isValid(vE)) then return nil end; return vE
end

__e2setcost(3)
e2function ftrace ftrace:setBase(entity eE)
	if(not this) then return nil end
	if(not isValid(eE)) then return this end
	this.mEnt = eE; return this
end

__e2setcost(3)
e2function ftrace ftrace:remBase()
	if(not this) then return nil end
	this.mEnt = nil; return this
end

--[[ **************************** MANAGMENT **************************** ]]

__e2setcost(3)
e2function number ftrace:isIgnoreWorld()
	if(not this) then return 0 end
	return (this.mTrI.ignoreworld and 1 or 0)
end

__e2setcost(3)
e2function ftrace ftrace:setIsIgnoreWorld(number nN)
	if(not this) then return nil end
	this.mTrI.ignoreworld = (nN ~= 0); return this
end

__e2setcost(3)
e2function vector ftrace:getPos()
	if(not this) then return {0,0,0} end
	return {this.mPos:Unpack()}
end

__e2setcost(3)
e2function vector ftrace:getPosLocal()
	return convOrgEnt(this, "WL", nil)
end

__e2setcost(3)
e2function vector ftrace:getPosWorld()
	return convOrgEnt(this, "LW", nil)
end

__e2setcost(3)
e2function vector ftrace:getPosLocal(entity vE)
	return convOrgEnt(this, "WL", vE)
end

__e2setcost(3)
e2function vector ftrace:getPosWorld(entity vE)
	return convOrgEnt(this, "LW", vE)
end

__e2setcost(7)
e2function vector ftrace:getPosLocal(vector vP, angle vA)
	return convOrgUCS(this, "WL", vP, vA)
end

__e2setcost(7)
e2function vector ftrace:getPosWorld(vector vP, angle vA)
	return convOrgUCS(this, "LW", vP, vA)
end

__e2setcost(3)
e2function ftrace ftrace:setPos(array aO)
	if(not this) then return nil end
	this.mPos:SetUnpacked(aO[1], aO[2], aO[3])
	return this
end

__e2setcost(3)
e2function ftrace ftrace:setPos(vector vO)
	if(not this) then return nil end
	this.mPos:SetUnpacked(vO[1], vO[2], vO[3])
	return this
end

__e2setcost(3)
e2function ftrace ftrace:setPos(number nX, number nY, number nZ)
	if(not this) then return nil end
	this.mPos:SetUnpacked(nX, nY, nZ)
	return this
end

__e2setcost(3)
e2function vector ftrace:getDir()
	if(not this) then return nil end
	return {this.mDir:Unpack()}
end

__e2setcost(3)
e2function vector ftrace:getDirLocal()
	return convDirLocal(this, nil, nil)
end

__e2setcost(3)
e2function vector ftrace:getDirWorld()
	return convDirWorld(this, nil, nil)
end

__e2setcost(3)
e2function vector ftrace:getDirLocal(entity vE)
	return convDirLocal(this, vE, nil)
end

__e2setcost(3)
e2function vector ftrace:getDirWorld(entity vE)
	return convDirWorld(this, vE, nil)
end

__e2setcost(3)
e2function vector ftrace:getDirLocal(angle vA)
	return convDirLocal(this, nil, vA)
end

__e2setcost(3)
e2function vector ftrace:getDirWorld(angle vA)
	return convDirWorld(this, nil, vA)
end

__e2setcost(3)
e2function ftrace ftrace:setDir(array aD)
	if(not this) then return nil end
	this.mDir:SetUnpacked(aD[1], aD[2], aD[3])
	this.mDir:Normalize(); this.mDir:Mul(this.mLen)
	return this
end

__e2setcost(3)
e2function ftrace ftrace:setDir(vector vD)
	if(not this) then return nil end
	this.mDir:SetUnpacked(vD[1], vD[2], vD[3])
	this.mDir:Normalize(); this.mDir:Mul(this.mLen)
	return this
end

__e2setcost(3)
e2function ftrace ftrace:setDir(number nX, number nY, number nZ)
	if(not this) then return nil end
	this.mDir:SetUnpacked(nX, nY, nZ)
	this.mDir:Normalize(); this.mDir:Mul(this.mLen)
	return this
end

__e2setcost(3)
e2function number ftrace:getLen()
	if(not this) then return nil end
	return (this.mLen or 0)
end

__e2setcost(3)
e2function ftrace ftrace:setLen(number nL)
	if(not this) then return nil end
	this.mLen = math.Clamp(nL,-gnMaxBeam,gnMaxBeam)
	this.mDir:Normalize(); this.mDir:Mul(this.mLen)
	this.mLen = math.abs(this.mLen); return this
end

__e2setcost(3)
e2function number ftrace:getMask()
	if(not this) then return 0 end
	return (this.mTrI.mask or 0)
end

__e2setcost(3)
e2function ftrace ftrace:setMask(number nN)
	if(not this) then return nil end
	this.mTrI.mask = nN; return this
end

__e2setcost(3)
e2function number ftrace:getCollideGroup()
	if(not this) then return nil end
	return (this.mTrI.collisiongroup or 0)
end

__e2setcost(3)
e2function ftrace ftrace:setCollideGroup(number nN)
	if(not this) then return nil end
	this.mTrI.collisiongroup = nN; return this
end

__e2setcost(3)
e2function vector ftrace:getStart()
	if(not this) then return {0,0,0} end
	local vT = this.mTrI.start
	return {vT:Unpack()}
end

__e2setcost(3)
e2function vector ftrace:getStop()
	if(not this) then return {0,0,0} end
	local vT = this.mTrI.endpos
	return {vT:Unpack()}
end

__e2setcost(12)
e2function ftrace ftrace:smpLocal()
	return trcLocal(this, nil, nil, nil)
end

__e2setcost(12)
e2function ftrace ftrace:smpLocal(entity vE)
	return trcLocal(this, vE, nil, nil)
end

__e2setcost(12)
e2function ftrace ftrace:smpLocal(angle vA)
	return trcLocal(this, nil, nil, vA)
end

__e2setcost(12)
e2function ftrace ftrace:smpLocal(vector vP)
	return trcLocal(this, nil, vP, nil)
end

__e2setcost(12)
e2function ftrace ftrace:smpLocal(vector vP, angle vA)
	return trcLocal(this, nil, vP, vA)
end

__e2setcost(12)
e2function ftrace ftrace:smpLocal(entity vE, vector vP)
	return trcLocal(this, vE, vP, nil)
end

__e2setcost(12)
e2function ftrace ftrace:smpLocal(entity vE, angle vA)
	return trcLocal(this, vE, nil, vA)
end

__e2setcost(12)
e2function ftrace ftrace:smpWorld()
	return trcWorld(this)
end

__e2setcost(12)
e2function ftrace ftrace:smpWorld(entity vE)
	return trcWorld(this, vE, nil, nil)
end

__e2setcost(12)
e2function ftrace ftrace:smpWorld(angle vA)
	return trcWorld(this, nil, nil, vA)
end

__e2setcost(12)
e2function ftrace ftrace:smpWorld(vector vP)
	return trcWorld(this, nil, vP, nil)
end

__e2setcost(12)
e2function ftrace ftrace:smpWorld(vector vP, angle vA)
	return trcWorld(this, nil, vP, vA)
end

__e2setcost(12)
e2function ftrace ftrace:smpWorld(entity vE, vector vP)
	return trcWorld(this, vE, vP, nil)
end

__e2setcost(12)
e2function ftrace ftrace:smpWorld(entity vE, angle vA)
	return trcWorld(this, vE, nil, vA)
end

__e2setcost(3)
e2function number ftrace:isHitNoDraw()
	if(not this) then return 0 end
	local trV = this.mTrO.HitNoDraw
	return (trV and 1 or 0)
end

__e2setcost(3)
e2function number ftrace:isHitNonWorld()
	if(not this) then return 0 end
	local trV = this.mTrO.HitNonWorld
	return (trV and 1 or 0)
end

__e2setcost(3)
e2function number ftrace:isHit()
	if(not this) then return 0 end
	local trV = this.mTrO.Hit
	return (trV and 1 or 0)
end

__e2setcost(3)
e2function number ftrace:isHitSky()
	if(not this) then return 0 end
	local trV = this.mTrO.HitSky
	return (trV and 1 or 0)
end

__e2setcost(3)
e2function number ftrace:isHitWorld()
	if(not this) then return 0 end
	local trV = this.mTrO.HitWorld
	return (trV and 1 or 0)
end

__e2setcost(3)
e2function number ftrace:getHitBox()
	if(not this) then return 0 end
	local trV = this.mTrO.HitBox
	return (trV and trV or 0)
end

__e2setcost(3)
e2function number ftrace:getMatType()
	if(not this) then return 0 end
	local trV = this.mTrO.MatType
	return (trV and trV or 0)
end

__e2setcost(3)
e2function number ftrace:getHitGroup()
	if(not this) then return 0 end
	local trV = this.mTrO.HitGroup
	return (trV and trV or 0)
end

__e2setcost(8)
e2function vector ftrace:getHitPos()
	if(not this) then return {0,0,0} end
	local trV = this.mTrO.HitPos
	return (trV and {trV:Unpack()} or {0,0,0})
end

__e2setcost(8)
e2function vector ftrace:getHitNormal()
	if(not this) then return {0,0,0} end
	local trV = this.mTrO.HitNormal
	return (trV and {trV:Unpack()} or {0,0,0})
end

__e2setcost(8)
e2function vector ftrace:getNormal()
	if(not this) then return {0,0,0} end
	local trV = this.mTrO.Normal
	return (trV and {trV:Unpack()} or {0,0,0})
end

__e2setcost(8)
e2function string ftrace:getHitTexture()
	if(not this) then return gsZeroStr end
	local trV = this.mTrO.HitTexture
	return tostring(trV or gsZeroStr)
end

__e2setcost(8)
e2function vector ftrace:getStartPos()
	if(not this) then return {0,0,0} end
	local trV = this.mTrO.StartPos
	return (trV and {trV:Unpack()} or {0,0,0})
end

__e2setcost(3)
e2function number ftrace:getSurfacePropsID()
	if(not this) then return 0 end
	local trV = this.mTrO.SurfaceProps
	return (trV and trV or 0)
end

e2function number ftrace:getSurfPropsID() = e2function number ftrace:getSurfacePropsID()

__e2setcost(3)
e2function string ftrace:getSurfacePropsName()
	if(not this) then return gsZeroStr end
	local trV = this.mTrO.SurfaceProps
	return (trV and util.GetSurfacePropName(trV) or gsZeroStr)
end

e2function string ftrace:getSurfPropsName() = e2function string ftrace:getSurfacePropsName()

__e2setcost(3)
e2function number ftrace:getPhysicsBoneID()
	if(not this) then return 0 end
	local trV = this.mTrO.PhysicsBone
	return (trV and trV or 0)
end

__e2setcost(3)
e2function number ftrace:getFraction()
	if(not this) then return 0 end
	local trV = this.mTrO.Fraction
	return (trV and trV or 0)
end

__e2setcost(3)
e2function number ftrace:getFractionLen()
	if(not this) then return 0 end
	local trV = this.mTrO.Fraction
	return (trV and (trV * this.mLen) or 0)
end

__e2setcost(3)
e2function number ftrace:isStartSolid()
	if(not this) then return 0 end
	local trV = this.mTrO.StartSolid
	return (trV and 1 or 0)
end

__e2setcost(3)
e2function number ftrace:isAllSolid()
	if(not this) then return 0 end
	local trV = this.mTrO.AllSolid
	return (trV and 1 or 0)
end

__e2setcost(3)
e2function number ftrace:getFractionLS()
	if(not this) then return 0 end
	local trV = this.mTrO.FractionLeftSolid
	return (trV and trV or 0)
end

__e2setcost(3)
e2function number ftrace:getFractionLenLS()
	if(not this) then return 0 end
	local trV = this.mTrO.FractionLeftSolid
	return (trV and (trV * this.mLen) or 0)
end

__e2setcost(3)
e2function entity ftrace:getEntity()
	if(not this) then return nil end
	local trV = this.mTrO.Entity
	return (trV and trV or nil)
end

__e2setcost(3)
e2function number ftrace:getSurfaceFlags()
	if(not this) then return 0 end
	local trV = this.mTrO.SurfaceFlags
	return (trV and trV or 0)
end

__e2setcost(3)
e2function number ftrace:getDispFlags()
	if(not this) then return 0 end
	local trV = this.mTrO.DispFlags
	return (trV and trV or 0)
end

e2function number ftrace:getDisplaceFlags()     = e2function number ftrace:getDispFlags()
e2function number ftrace:getDisplacementFlags() = e2function number ftrace:getDispFlags()

__e2setcost(3)
e2function number ftrace:getContents()
	if(not this) then return 0 end
	local trV = this.mTrO.Contents
	return (trV and trV or 0)
end

e2function number ftrace:getHitContents() = e2function number ftrace:getContents()

__e2setcost(15)
e2function ftrace ftrace:dumpItem(number nN)
	return dumpTracer(this, nN)
end

__e2setcost(15)
e2function ftrace ftrace:dumpItem(string sN)
	return dumpTracer(this, sN)
end

__e2setcost(15)
e2function ftrace ftrace:dumpItem(string nT, number nN)
	return dumpTracer(this, nN, nT)
end

__e2setcost(15)
e2function ftrace ftrace:dumpItem(string nT, string sN)
	return dumpTracer(this, sN, nT)
end
