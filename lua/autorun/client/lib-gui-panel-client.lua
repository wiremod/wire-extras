include ("autorun/shared/lib-gui-panel-shared.lua")
--load schemes 
guiP_schemeTable = {}
for k,sch in pairs(guiP_colourScheme) do
	table.insert(guiP_schemeTable, k)
end

------------------------CLIENT / SERVER COMMUNICATIONS------------------------------

--For enabling / disabling panel (draw code)
function umGetPanelState()
	local ent = net.ReadEntity()
	ent.panelEnabled = net.ReadBool()
end
net.Receive("umsgPanelState", umGetPanelState)

--For waking a panel for the first time (use once)
function umPanelWake()
	local ent = net.ReadEntity()
	guiP_PanelEnable(ent, true)
	ent.panelWoken = true
end
net.Receive("umsgPanelWake", umPanelWake)

--For setting the panel colour scheme
function umGetPanelScheme()
	local ent = net.ReadEntity()
	local sNum = net.ReadInt(16)
	ent.currentScheme = guiP_colourScheme[guiP_schemeTable[sNum]]
end
net.Receive("umsgPanelScheme", umGetPanelScheme) 

--For initializing entity (use once)
function umClientPanelInit()
	--Msg("is this used?\n")
	local ent = net.ReadEntity()
	local newID = net.ReadInt(16)
	--call auto re-trying init function
	entInit(ent, newID)
	--need to make this use a failed concommand instread?
	
end
net.Receive("umsgClientPanelInit", umClientPanelInit) 

function entInit(ent, entID)
	--print ("and this?\n")
	--print ("trying ent "..tostring(ent).."\n")
	if ent:IsValid() then
		guiP_panelDatabase[entID] = ent
		gpSetupVals(ent)
		ent.initOccured = true
		print ("enabling draw on "..tostring(ent).."\n")
	else
		--auto retry until exists
		--print "retry"
		timer.Simple(0.5, entInit, ent, entID)
	end
end

--For updating variables for the draw code - i.e change the appearance of a widget
function umDrawUpdate()
	local ent = net.ReadEntity()
	local modIndex = net.ReadInt(16)
	local paramNum = net.ReadInt(16)
	local isString = net.ReadBool()
	local value
	if isString then
		value = net.ReadString()
	else
		value = net.ReadFloat()
	end
	ent.pWidgets[modIndex].modType.drawUpdate(ent.pWidgets[modIndex], paramNum, value)
end
net.Receive("umsgDrawUpdate", umDrawUpdate) 

--Recieve panel config data from server (when using server defined panels)
function umPanelConfig()
	--this sould be better in some form of startup routine
	local ent = net.ReadEntity()
	guiP_ClearWidgets(ent)
	
	if (table.Count(guiP_widgetLookup) == 0) then
		local i = 0
		for k, wid in pairs(panelWidget) do
			i = i + 1
			guiP_widgetLookup[k] = i
			guiP_widgetLookup[i] = k
		end
	end

	ent.pWidgets = {}
	ent.numWidgets = net.ReadInt(16)
	for i=1, ent.numWidgets, 1 do
		--local modType = panelWidget[net.ReadString()]
		local widT = guiP_widgetLookup[net.ReadInt(16)]
		local modType = panelWidget[widT]
	
		Msg("read modtype as "..widT.."\n")
		local X = net.ReadInt(16)
		local Y = net.ReadInt(16)
		local W = net.ReadInt(16)
		local H = net.ReadInt(16)
		local numParams = net.ReadInt(16)
		local paramTable = {}
		for i=1, numParams, 1 do
			local pNum = net.ReadInt(16)
			paramTable[pNum] = net.ReadString()
			Msg(string.format("(client) param #%d = %s\n", pNum, paramTable[pNum]))
		end
		
		ent.pWidgets[i] = {parent = ent, enabled = true, visible = true, modIndex = i, modType = modType, X = X, Y = Y, W = W, H = H, paramTable = paramTable}
		--Initialise widget
		ent.pWidgets[i].modType.modInit(ent.pWidgets[i])
		--local curMod = ent.pWidgets[i]
		
	end

	guiP_PanelEnable(ent, net.ReadBool())
end
net.Receive("umsgPanelConfig", umPanelConfig) 

--------------------------------CLIENT FUNCTIONS-----------------------------------

--set draw and cam3d2d parameters
function gpSetupVals(ent)
	ent.drawParams = {
		--add a font size scale in here
		screenWidth = 200,
		screenHeight = 200
	}
	ent:SetupParams()
	gpCalcDrawCoefs(ent)
end

--calculate draw coefficients and offsets
function gpCalcDrawCoefs(ent)
	ent.XdrawCoef = ent.w / ent.drawParams.screenWidth
	ent.XdrawOffs = ent.x
	ent.YdrawCoef = ent.h / ent.drawParams.screenHeight
	ent.YdrawOffs = ent.y
	--Msg("calc done\n")
end

--Make fonts for panel
if (!guiPfontsMade) then
	guiPfontsMade = true
	--local fontSize = 280
	local fontSize = 560
	for i = 1, 15 do
		surface.CreateFont( "guipfont" .. i, {font = "coolvetica", size = fontSize / i, weight = 400, antialias = false, additive = false} )
	end
end

------------------------------User Functions-------------------------------------------------

-- Initiate panel
function guiP_PanelInit(ent, w, h)
	--inform server that this player's entity has been created / request init.
	if (w and w > 0) then
		ent.drawParams.screenWidth = w
	else
		ent.drawParams.screenWidth = 200
	end
	if (h and h > 0) then
		ent.drawParams.screenHeight = h
	else
		ent.drawParams.screenHeight = 200
	end
	LocalPlayer():ConCommand("guiPinitMe "..ent:EntIndex().."\n")
	ent.pWidgets = {}
	ent.nameTable = {}
end

--Clear widgets ready for new ones (does not fully reset at present)
function guiP_ClearWidgets(ent)
	
	
	--global drawing variables (used in ENT:Draw and widget definitions)

end

function guiP_DrawSetup(ent, x, y, w, h, res)
	ent.drawParams.x = x
	ent.drawParams.y = y
	ent.drawParams.w = w
	ent.drawParams.h = h
	ent.drawParams.Res = res
end

--For enabling / disabling a panel
function guiP_PanelEnable(ent, val)
	--Msg("enabling "..tostring(ent).." with "..tostring(val).."\n")
	--if (ent.currentScheme) then
	ent.panelInitEnable = val
	--else
	--	Msg(guipErrorMsg.."not initing gui-panel (scheme problems)\n")
	--end
end




