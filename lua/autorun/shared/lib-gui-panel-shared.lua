guipErrorMsg = "guiPanel ERROR: "

--Load all colour schemes found in schemes folder
guiP_colourScheme = {}
local schemePath = "autorun/schemes/"
local schemeList = file.Find(schemePath.."*.lua", "LUA")
for k, file in ipairs(schemeList) do
	if (SERVER) then
		AddCSLuaFile(schemePath..file)
		--Msg("(server)")
	end
	include(schemePath..file)
	--Msg("loaded scheme file "..file.."\n")
end

panelWidget = {}

--guip

--Load all widgets found in the widgets folder
local widgetPath = "autorun/widgets/"
local widgetList = file.Find(widgetPath.."*.lua", "LUA")
for k, file in ipairs(widgetList) do
	if (SERVER) then
		AddCSLuaFile(widgetPath..file)
		--Msg("(server)")
	end
	include(widgetPath..file)
	--Msg("loaded widget "..file.."\n")
end

--are we even still using this?
guiP_widgetLookup = {}
local i = 0
for k, wid in pairs(panelWidget) do
	i = i + 1
	guiP_widgetLookup[k] = i
	guiP_widgetLookup[i] = k
end

--Add a widget to a panel
function guiP_AddWidget(ent, newName, modType, X, Y, W, H, paramTable)
	local newKey = table.getn(ent.pWidgets) + 1
	local newParTable = {}
	if (panelWidget[modType]) then
		local pNum = 1
		for k, par in pairs(panelWidget[modType].paramTable) do
			if (SERVER) then
				if (paramTable[k]) then
					newParTable[par.index] = paramTable[k]
				else
					newParTable[k] = par.default
				end
			else
				if (paramTable[k]) then
					newParTable[par.index] = paramTable[k]
				else
					newParTable[par.index] = par.default
				end
			end
			pNum = pNum + 1
		end
				
		table.insert(ent.pWidgets, {parent = ent.Entity, modName = newName, enabled = true, visible = true, modIndex = newKey, modType = panelWidget[modType], X = X, Y = Y, W = W, H = H, paramTable = newParTable})
		ent.nameTable[newName] = newKey	--reversable lookup table
		ent.nameTable[newKey] = newName
	else
		Msg(ent.errorMsg.."widget type '"..modType.."' unknown\n")
	end
	--Msg("serv = "..tostring(SERVER)..", widget.H = "..ent.pWidgets[newKey].H.."\n")
	ent.pWidgets[newKey].modType.modInit(ent.pWidgets[newKey])
end

guiP_panelIDRegister = {}

--Create a new panel
function guiPanelCreateNew(ent)
	local newID = table.getn(guiP_panelIDRegister) + 1
	table.insert(guiP_panelIDRegister, ent.Entity)
	--Msg("creating new panel with id "..newID.." ("..table.getn(guiP_panelIDRegister)..")\n")
	ent.panelID = newID
	--Msg("ent = "..tostring(ent).."  ")
	if CLIENT then
		--Msg("client")
	else
		--Msg("server")
	end
	--Msg("  verified val = "..ent.panelID.."\n")
end

guiP_panelDatabase = {}


