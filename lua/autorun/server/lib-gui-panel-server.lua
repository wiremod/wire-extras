AddCSLuaFile ("autorun/shared/lib-gui-panel-shared.lua")
AddCSLuaFile ("autorun/client/lib-gui-panel-client.lua")

include ("autorun/shared/lib-gui-panel-shared.lua")

guiP_schemeTable = {}
local nVal = 1
for k,sch in pairs(guiP_colourScheme) do
	--Msg("found scheme "..k.."\n")
	guiP_schemeTable[k] = nVal
	nVal = nVal + 1
end

------------------------CLIENT / SERVER COMMUNICATIONS------------------------------

--Console variables for recieved data
--CreateConVar("wmpcldata", "0", false, false )
--CreateConVar("wmpcldwait", 0, false, false )

--Called by a client to request panel setup information
function clientPanelInitRequest(player, commandName, args)
	--Msg ("responding to init request\n")
	local ent = ents.GetByIndex(args[1])
	--ent = guipLastNewEnt
	
	umSendPanelInit(ent, ent.entID)
	umSendPanelScheme(ent, ent.currentScheme)
	umSendPanelWake(ent)
	umSendPanelState(ent, true) 
	
end
concommand.Add("guiPinitMe", clientPanelInitRequest)

function umSendPanelInit(ent, entID)
	umsg.Start("umsgClientPanelInit", player)
		umsg.Entity(ent)
		umsg.Short(entID)
	umsg.End() 
end
	
function umSendPanelScheme(ent, scheme)
	umsg.Start("umsgPanelScheme", player)
		umsg.Entity(ent)
		umsg.Short(guiP_schemeTable[scheme])
	umsg.End() 
end

function umSendPanelWake(ent)	
	umsg.Start("umsgPanelWake", player)
		umsg.Short(42)
		umsg.Entity(ent)
	umsg.End() 
end

function umSendPanelState(ent, state)	
	umsg.Start("umsgPanelState", player)
		umsg.Entity(ent)
		umsg.Bool(state)
	umsg.End() 
end

function guiP_cl_drawUpdate(widget, paramNum, value)
	local allPlayers = RecipientFilter()
	allPlayers:AddAllPlayers()
	isString = (type(value) == "string")
	umsg.Start("umsgDrawUpdate", allPlayers)
		umsg.Entity(widget.parent)
		umsg.Short(widget.modIndex)
		umsg.Short(paramNum)
		umsg.Bool(isString)
		if (isString) then
			umsg.String(value)
		else
			umsg.Float(value)
		end
	umsg.End()
end

--[[
 print(type(Function)) // Prints "function"
 print(type(String)) // Prints "string"
 print(type(Number)) // Prints "number"
 print(type(Table)) // Prints "table" 
]]--


function gpCursorClick (ply)
	local trace = {}
	trace.start = ply:GetShootPos()
	trace.endpos = ply:GetAimVector() * 64 + trace.start
	trace.filter = ply
	local trace = util.TraceLine(trace)
	local ent = trace.Entity
	if (ent.Base == "base_gui_panel") then
		if !ent.paramsSetup then
			ent:SetupParams()
		end
		local pos = ent.Entity:WorldToLocal(trace.HitPos)
		local xval = (ent.x1 - pos.y) / (ent.x1 - ent.x2)
		local yval = (ent.y1 - pos.z) / (ent.y1 - ent.y2)
		
		if (xval >= 0 and yval >= 0 and xval <= 1 and yval <= 1) then
			--Msg ("clicked at ( "..xval.." , "..yval.." )\n")
			for k, widget in ipairs(ent.pWidgets) do
				if (xval * ent.drawParams.screenWidth > widget.X) && (yval * ent.drawParams.screenHeight > widget.Y) && (xval * ent.drawParams.screenWidth < widget.X + widget.W) && (yval * ent.drawParams.screenHeight < widget.Y + widget.H) then
				--Msg("clicked on widget\n")
					if (widget.enabled) then
						widget.modType.modClicked (ply, widget, (xval * ent.drawParams.screenWidth) - widget.X, (yval * ent.drawParams.screenHeight) - widget.Y)
					end
				end
			end
		end
		return true
	end
end

function AttackKeyPress (ply, key)
	if (key == IN_ATTACK or key == IN_USE) then
		gpCursorClick (ply)
		--add keyboard (text entry) support here
	end
end
hook.Add( "KeyPress", "guipanelKeyHook", AttackKeyPress ) 

--------------------------User Functions----------------------------------------------------

function guiP_PanelInit(ent, w, h)
	local newID = table.getn(guiP_panelDatabase) + 1
	table.insert(guiP_panelDatabase, ent)
	guipLastNewEnt = ent
	ent.entID = newID
	ent.initOccured = true
	--make transmit to client, or just add this to client code also?
	ent.drawParams = {}
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
	ent.pWidgets = {}
	ent.nameTable = {}
end

function guiP_SetPanelState(ent, enabled)
	if (!ent.firstRun.enable) then
			umSendPanelState(ent, enabled)
			ent.firstRun.enable = true
	end
end

function guiP_SetPanelScheme(ent, scheme)
	--Msg ("scheme "..scheme.."\n")
	if (guiP_schemeTable[scheme]) then
		ent.currentScheme = guiP_colourScheme[scheme]
		--Msg(string.format("using scheme #%d (%s)\n", guiP_schemeTable[scheme], scheme))
		ent.currentScheme = scheme
		--[[
		if (!ent.firstRun.scheme) then
			umSendPanelScheme(ent, scheme)
			ent.firstRun.scheme = true
		end
		]]--
		umSendPanelScheme(ent, scheme)
	else
		Msg(ent.errorMsg.."colour scheme '"..scheme.."' not found\n")
	end
end

--Clear all widgets
function guiP_ClearWidgets(ent)
	
end

--Set widget variable
function guiP_setWidgetProperty (ent, modName, inpName, value)
	local modNum = ent.nameTable[modName]
	--Msg(string.format("value at smv = %f\n", value))
	--servSendInput(ent, modNum, ent.pWidgets[modNum].modType.inputs[inpName].index, ent.pWidgets[modNum].modType.inputs[inpName].msgType, value)
	if (ent.pWidgets[modNum]) then
		ent.pWidgets[modNum].modType.triggerInput(ent.pWidgets[modNum], inpName, value)
	else
		Msg(ent.errorMsg.."invalid widget number\n")
	end
end

function guiP_loadWidgetsFromTable(ent, widTable)
	local wireData = {inputs = {}, inputMap = {}, outputs = {}, outputMap = {}}
	for k, wid in ipairs (widTable) do
		Msg("adding widget "..wid.name..", x = "..wid.x.."\n")
		--wid.paramTable = {} --not supported yet
		for tk, tp in pairs (wid.params) do
			Msg("wid has param "..tk..", "..tp.."\n")
		end
		guiP_AddWidget(ent, wid.name, guiP_widgetLookup[wid.widgetType], wid.x, wid.y, wid.w, wid.h, wid.params)
		Msg("wire name = "..wid.wire.name..", type = "..wid.wire.wireType.."\n")
		if (wid.wire.wireType == 1) then
			table.insert(wireData.inputs, wid.wire.name)
			wireData.inputMap[wid.wire.name] = wid.name
		elseif (wid.wire.wireType == 2) then
			table.insert(wireData.outputs, wid.wire.name)
			wireData.outputMap[wid.name] = wid.wire.name
		end
	end
	return wireData	
end

function guiP_fileDataToTable (fileData)
	--local wireData = {inputs = {}, inputMap = {}, outputs = {}, outputMap = {}}
	local widgetTable = {}
	local lineTable = string.Explode(string.char(10), fileData)
	--for each widgets (line)
	for k, line in ipairs(lineTable) do
		local newWidget = {
			name = "",
			index = 0,
			widgetType = 1,
			x = 0,
			y = 0,
			w = 0,
			h = 0,
			params = {},
			wire = {name = "", wireType = nil}
		}
		if (string.Left(line, 1) == string.char(34)) then
			local lineData = string.Explode(string.char(9), line)
			local stillTabs = true
			--parse line, remove all tabs
			while (stillTabs) do
				stillTabs = false
				for dk, dItem in ipairs(lineData) do
					if (string.byte(dItem) == 9 or not string.byte(dItem)) then
						table.remove(lineData, dk)
						stillTabs = true
					elseif (string.Left(dItem, 1) == string.char(9)) then
						lineData[dk] = string.Right(dItem, string.len(dItem) - 1)
					end
				end
			end

			--remove  speeh marks
			for dk, dItem in ipairs(lineData) do
				if (string.Left(dItem, 1) == string.char(34)) then
					lineData[dk] = string.sub(lineData[dk], 2, string.len(lineData[dk]) - 1)
				end
			end
			
			for k, nn in ipairs (lineData) do
				Msg("dat "..k.." : '"..nn.."'\n")
			end
			
			local mName = lineData[1]
			local mType = lineData[2]
			Msg("tryconv '"..lineData[3].."'\n")
			local mLeft = tonumber(lineData[3])
			local mTop = tonumber(lineData[4])
			local mWidth = tonumber(lineData[5])
			local mHeight = tonumber(lineData[6])
			local parmTable = {}
			local parmStart = 7
			
			--read wire settings
			if (lineData[7] == "WIREI" || lineData[7] == "WIREO") then
				if (lineData[7] == "WIREI") then
					newWidget.wire.wireType = 1
					newWidget.wire.name = lineData[8]
				else
					newWidget.wire.wireType = 2
					newWidget.wire.name = lineData[8]
				end
				parmStart = 9
			end
			--read extra parameters
			if (table.getn(lineData) > parmStart) then
				for iv=parmStart, table.getn(lineData), 2 do
					newWidget.params[lineData[iv]] = lineData[iv + 1]
				end
			end
			Msg(string.format("complete widget: '%s' '%s' '%d' '%d '%d' '%d' + parmtable?\n", mName, mType, mLeft, mTop, mWidth, mHeight))
			newWidget.name = mName
			newWidget.widgetType = guiP_widgetLookup[mType]
			newWidget.x = mLeft
			newWidget.y = mTop
			newWidget.w = mWidth
			newWidget.h = mHeight
			table.insert (widgetTable, table.Copy (newWidget))
			Msg("widget.y = "..newWidget.w.."\n")
			widgetTable[table.getn (widgetTable)].index = table.getn (widgetTable)
		end	
		
	end
	return widgetTable
end

--"modular_panels/"..fileselect
function SaveTableToFile (widgetTable, filename)
	local fileString = ""
	for k, wid in ipairs (widgetTable) do
		Msg("adding to save, wid "..wid.name..", x = "..wid.x..", y = "..wid.y..", w = "..wid.w..", h = "..wid.h.."\n")
		local wireString = ""
		if (wid.wire.wireType == 1) then
			wireString = string.format ('WIREI\t"%s"', wid.wire.name)
		elseif (wid.wire.wireType == 2) then
			wireString = string.format ('WIREO\t"%s"', wid.wire.name)
		end
		Msg("wt lookup = "..guiP_widgetLookup[wid.widgetType]..", ws = "..wireString.."\n")
		local newLine = string.format ('"%s"\t%s\t%d\t%d\t%d\t%d\t%s\n', wid.name, guiP_widgetLookup[wid.widgetType], wid.x, wid.y, wid.w, wid.h, wireString)
		fileString = fileString .. newLine
	end

	file.Write (filename, fileString)
end

--Load widgets from a file (including wire i/o)
function guiP_LoadWidgetsFromFileData(ent, fileData)
	local wireData = {inputs = {}, inputMap = {}, outputs = {}, outputMap = {}}
	local lineTable = string.Explode(string.char(10), fileData)
	for k, line in ipairs(lineTable) do
		if (string.Left(line, 1) == string.char(34)) then
			--Msg(string.format("Line #%d = '%s'\n", k, line))
			local lineData = string.Explode(string.char(9), line)
			local stillTabs = true
			--parse line, remove all tabs
			while (stillTabs) do
				stillTabs = false
				--Msg("parsing for tabs\n")
				for dk, dItem in ipairs(lineData) do
					--Msg("instecting #"..tostring(dk).." = "..dItem.."\n")
					if (dItem == string.char(9)) then
						--Msg("removing\n")
						table.remove(lineData, dk)
						stillTabs = true
					elseif (string.Left(dItem, 1) == string.char(9)) then
						--Msg("needs cropping\n")
						--Msg(string.format("replacing '%s' with '%s'\n", dItem, string.Right(dItem, string.len(dItem) - 1)))
						lineData[dk] = string.Right(dItem, string.len(dItem) - 1)
						--Msg(string.format("verified '%s'\n", dItem))
						--stillTabs = true
					end
				end
			end

			--remove  speeh marks
			for dk, dItem in ipairs(lineData) do
				if (string.Left(dItem, 1) == string.char(34)) then
					lineData[dk] = string.sub(lineData[dk], 2, string.len(lineData[dk]) - 1)
				end
			end
			
			local mName = lineData[1]
			local mType = lineData[2]
			local mLeft = tonumber(lineData[3])
			local mTop = tonumber(lineData[4])
			local mWidth = tonumber(lineData[5])
			local mHeight = tonumber(lineData[6])
			local parmTable = {}
			local parmStart = 7
			
			--read wire settings
			if (lineData[7] == "WIREI" || lineData[7] == "WIREO") then
				if (lineData[7] == "WIREI") then
					--Msg("adding wire input "..lineData[8].."\n")
					table.insert(wireData.inputs, lineData[8])
					wireData.inputMap[lineData[8]] = mName
				else
					--Msg("adding wire output "..lineData[8].."\n")
					table.insert(wireData.outputs, lineData[8])
					wireData.outputMap[mName] = lineData[8]
				end
				parmStart = 9
			end
			--read extra parameters
			if (table.getn(lineData) > parmStart) then
				for iv=parmStart, table.getn(lineData), 2 do
					parmTable[lineData[iv]] = lineData[iv + 1]
					--Msg("added param "..lineData[iv].." = "..lineData[iv + 1].."\n")
				end
			end
			Msg(string.format("complete widget: '%s' '%s' '%d' '%d '%d' '%d' + parmtable?\n", mName, mType, mLeft, mTop, mWidth, mHeight))
			guiP_AddWidget(ent, mName, mType, mLeft, mTop, mWidth, mHeight, parmTable)
		end	
	end
	return wireData
end

--Send panel config to client
function guiP_SendClientWidgets(ent)
	local allPlayers = RecipientFilter()
	allPlayers:AddAllPlayers()
	umsg.Start("umsgPanelConfig", allPlayers)
		--Msg("starting panel usmg\n")
		umsg.Entity(ent)
		umsg.Short(table.getn(ent.pWidgets))
		for key, modu in ipairs(ent.pWidgets) do
			Msg(string.format("sending panel #%d\n", key))
			--umsg.String(modu.modType.name)
			Msg("sending type = "..tostring(modu.modType.name).."\n")
			Msg("modindex "..tostring(guiP_widgetLookup[modu.modType.name]).."\n")
			umsg.Short(guiP_widgetLookup[modu.modType.name])
			--umsg.Short(key)
			umsg.Short(modu.X)
			umsg.Short(modu.Y)
			umsg.Short(modu.W)
			umsg.Short(modu.H)
			--check extra params
			local numParams = table.Count(modu.paramTable)
			umsg.Short(numParams)
			local keysend = 0
						
			for pkey, param in pairs(modu.paramTable) do
				--Msg(string.format("key = %s, param = %s, cms = '%s'\n", pkey, param, table.concat(modu.modType.paramTable)))
				Msg("cs param "..pkey.." = "..param.."\n")
				--if (modu.modType.paramTable[pkey]) then
					--Msg("param verified for client\n")
				--Msg("looking up param "..pkey..", index = "..modu.modType.paramTable[pkey].index.."\n")
				--keysend = modu.modType.paramTable[pkey].index
				--else
				---	Msg(ent.errorMsg.."param error\n")
				--end
				--Msg("(server) param #"..tostring(keysend).." = "..tostring(param).."\n")
				umsg.Short(pkey)
				umsg.String(tostring(param))
			end
		end
	umsg.Bool(true)
	umsg.End() 
end

--function guiP_PanelEnable(ent)
--end

