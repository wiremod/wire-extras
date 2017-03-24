TOOL.Category		= "Wire - I/O"
TOOL.Name			= "Modular Panel"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.currentState = 1
modularPanelTraceBuffer = {}

if ( CLIENT ) then
	language.Add( "Tool_wire_modular_panel_name", "Modular Panel Tool (Wire)" )
	language.Add( "Tool_wire_modular_panel_desc", "Custom wire panel" )
	language.Add( "Tool_wire_modular_panel_0", "Primary: Create/Update modular panel " )
	language.Add( "sboxlimit_wire_modular_panels", "You've hit modular panels limit!" )
	language.Add( "undone_wire_modular_panel", "Undone Wire Modular Panel " )
	language.Add("WireModularPanelTool_filelist", "Filename:")
	language.Add("WireModularPanelTool_widgetlist", "Widget:")
	language.Add("WireModularPanelTool_widgettypelist", "Widget Type:")
	language.Add("Tool_wire_modular_panel_wxpos", "X:")
	language.Add("Tool_wire_modular_panel_wypos", "Y:")
	language.Add("Tool_wire_modular_panel_wwidth", "W:")
	language.Add("Tool_wire_modular_panel_wheight", "H:")
	language.Add("Tool_wire_modular_panel_widgetname", "Widget Name:")
	language.Add("Tool_wire_modular_panel_wirename", "Wire I/O:")
	language.Add("WireModularPanelTool_panelTheme", "Panel Theme:")
end

if (SERVER) then
	CreateConVar('sbox_maxwire_modular_panels', 20)
end

TOOL.ClientConVar["fileselect"] = ""
TOOL.ClientConVar["widgetname"] = "newname"
TOOL.ClientConVar["wirename"] = "newio"
TOOL.ClientConVar["currentStoolPanel"] = 1
TOOL.ClientConVar["model"] = "models/kobilica/wiremonitorbig.mdl"

--add disable screen saver option

--TOOL.Model = "models/kobilica/guipmonitorbig.mdl"

cleanup.Register( "wire_modular_panels" )
wire_modular_panel_widget_message = ""

-------------------------------------------------------------------Stool code ------------------------------------------------------------

function TOOL:LeftClick( trace )
	--if not (type(Wire_CreateOutputs) == "function" and type(Wire_CreateInputs) == "function") then return false end
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end
	
	local ply = self:GetOwner()
	--local model = "models/kobilica/guipmonitorbig.mdl"
	--self.Model = "models/kobilica/guipmonitorbig.mdl"
	local currentState = tonumber(self:GetClientInfo("currentStoolPanel"))
	local CreateFlat	= self:GetClientNumber("createflat")
	local Smodel	= self:GetClientInfo( "model" )

	if (not util.IsValidModel(Smodel)) then return false end
	if (not util.IsValidProp(Smodel)) then return false end
	--if (CreateFlat == 0) then
	--	Ang.pitch = Ang.pitch + 90
	--end

	if  (currentState == 1) then
		--local filename = self:GetClientInfo("filename")
		local fileselect = self:GetClientInfo("fileselect")
		--Msg("filelist sel = "..fileselect.."\n")
		if (file.Exists("modular_panels/"..fileselect)) then
		local pFile = file.Read("modular_panels/"..fileselect) 
			local widTable = guiP_fileDataToTable (pFile)
			Msg ("loaded widgets from file:\n")
			for k, wid in ipairs (widTable) do
				Msg (wid.name.."\n"..wid.wire.name.."\nw = "..wid.w.."\n")
			end
			SaveTableToFile (widTable, "modular_panels/testout.txt")
			
			spawnModularPanel(ply, trace, widTable, (Smodel))
			
		else
			Msg("file not found\n") --make say in stool panel
		end
		
		
	elseif (currentState == 2) then
		--get config
		Msg("sending request\n")
		modularPanelTraceBuffer[ply:UniqueID()] = trace
			umsg.Start("umsgRequestModularPanel", ply)
			umsg.Bool(true)
		umsg.End()
		--spawn code will be called by returning server message
	end
	return true
end

if (SERVER) then
	function spawnModularPanel(ply, trace, widgetTable, params)
		if (trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_modular_panel" && trace.Entity.pl == ply) then
			trace.Entity:Setup(widgetTable)
			--BuildModPanel(trace.Entity, filename)
			return true
		end
		
		
		local Ang = trace.HitNormal:Angle()
		--local Smodel = self.Model
		Ang.pitch = Ang.pitch + 90
		local model = params
		wire_modular_panel = MakeWireModularPanel( ply, Ang, trace.HitPos, Model(model), widgetTable )
		local min = wire_modular_panel:OBBMins()
		wire_modular_panel:SetPos( trace.HitPos - trace.HitNormal * min.z )

		undo.Create("WireModularPanel")
			undo.AddEntity( wire_modular_panel )
			undo.SetPlayer( ply )
		undo.Finish()

		ply:AddCleanup( "wire_modular_panels", wire_modular_panel )
	end


	function MakeWireModularPanel( pl, Ang, Pos, Smodel, widgetTable )
		if ( !pl:CheckLimit( "wire_modular_panels" ) ) then return false end
		
		local wire_modular_panel = ents.Create( "gmod_wire_modular_panel" )
		if (!wire_modular_panel:IsValid()) then return false end
		wire_modular_panel:SetModel(Smodel)

		wire_modular_panel:SetAngles( Ang )
		wire_modular_panel:SetPos( Pos )
		wire_modular_panel:Setup(widgetTable)
		wire_modular_panel:Spawn()
	
		local ttable = {
			pl = pl,
			Smodel = Smodel,
			widgetTable = widgetTable
		}
		table.Merge(wire_modular_panel:GetTable(), ttable )
		pl:AddCount( "wire_modular_panels", wire_modular_panel )
		return wire_modular_panel
	end
	duplicator.RegisterEntityClass("gmod_wire_modular_panel", MakeWireModularPanel, "Ang", "Pos", "Smodel", "widgetTable")
end


function TOOL:UpdateGhostWireTextScreen( ent, player )

	if ( !ent ) then return end

	if ( !ent:IsValid() ) then return end

	local trace 	= player:GetEyeTrace()

	if (!trace.Hit) then return end

	if (trace.Entity && trace.Entity:GetClass() == "gmod_wire_modular_panel" || trace.Entity:IsPlayer()) then
		ent:SetNoDraw( true )
		return
	end

	local Ang = trace.HitNormal:Angle()
	
	if (self:GetClientNumber("createflat") == 0) then
		Ang.pitch = Ang.pitch + 90
	end

	local min = ent:OBBMins()

	ent:SetPos( trace.HitPos - trace.HitNormal * min.z )
	ent:SetAngles( Ang )
	ent:SetNoDraw( false )

end

function TOOL:Think()
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self:GetClientInfo( "model" ) || (not self.GhostEntity:GetModel()) ) then
		self:MakeGhostEntity( self:GetClientInfo( "model" ), Vector(0,0,0), Angle(0,0,0) )
	end
	self:UpdateGhostWireTextScreen( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	--if (type(Wire_CreateOutputs) == "function" and type(Wire_CreateInputs) == "function") then
		modularPanelRebuildPanel(panel, 1)
	--else
	--	panel:AddControl("Label", {
	--		Label = "",
	--		Text = "Wire must be installed in order to use this tool"
	--	})
	--end
end

-------------------------------------------------------------------END Stool code ------------------------------------------------------------


-------------------------------------------------------------------Communications ------------------------------------------------------------

if CLIENT then
	--client to server send panel
	function umRequestModularPanel(um)
		Msg("sending config\n")
		local conf = um:ReadBool()		
		smsg.Start("smsgModularPanel")
			smsg.Short (table.getn(modular_panel_current_panel.widgets))
			
			for k, wid in ipairs (modular_panel_current_panel.widgets) do
				if (wid and wid.name) then
					Msg("trying "..wid.name.."\n")
					--Msg ("widget = "..table.concat (wid, ", "))
					smsg.String (wid.name)
					smsg.Short (wid.widgetType)
					smsg.Short (wid.x)
					smsg.Short (wid.y)
					smsg.Short (wid.w)
					smsg.Short (wid.h)
					
					local numParams = table.Count(wid.params)
					smsg.Short (numParams)
					Msg("sending "..numParams..", params\n")
					for pk, par in pairs (wid.params) do
						Msg("write param #"..pk.." = "..par.."\n")
						smsg.String (pk)
						smsg.String (par)
					end
					
					if (wid.wire.wireType > 0) then
						Msg("send wire\n")
						smsg.Bool (true)
						Msg("sending wire, type = "..wid.wire.wireType..", name = "..wid.wire.name.."\n")
						smsg.Short (wid.wire.wireType)
						smsg.String (wid.wire.name)
					else
						smsg.Bool (false)
					end
				end
			end
		smsg.End() 
	end
	usermessage.Hook("umsgRequestModularPanel", umRequestModularPanel) 
	
	--client rec panel
	function umClRecModularPanel(um)
		local recWidgets = {}
		local numWidgets = um:ReadShort()
		for i = 1, numWidgets do
			table.insert (recWidgets, {
				name = um:ReadString(),
				widgetType = um:ReadShort(),
				x = um:ReadShort(),
				y = um:ReadShort(),
				w = um:ReadShort(),
				h = um:ReadShort(),
				params = {},
				wire = {name = "", type = 0}
			})
			local numParams = um:ReadShort()
			Msg("rec "..numParams..", params\n")
			for n = 1, numParams do
				local paramIndex = um:ReadString()
				local paramData = um:ReadString()
				recWidgets[table.getn(recWidgets)].params[paramIndex] = paramData
				Msg("read param index = "..paramIndex..", data = "..paramData..", for "..recWidgets[table.getn(recWidgets)].name.."\n")
			end
			local hasWire = um:ReadBool()
			if hasWire then
				Msg("rec wire\n")
				recWidgets[table.getn(recWidgets)].wire.wireType = um:ReadShort()
				recWidgets[table.getn(recWidgets)].wire.name = um:ReadString()
			end
		end
		Msg("recieved "..numWidgets.." widgets from "..tostring(um.player).."\n")
		for k, w in ipairs (recWidgets) do
			Msg("recieved widget "..w.name..", x = "..w.x..", y = "..w.y..", w = "..w.w..", h = "..w.h.."\n")
		end
		modular_panel_current_panel.widgets = table.Copy (recWidgets)
		modularPanelRebuildPanel(nil, 2)
	end
	usermessage.Hook("umsgclRecModularPanel", umClRecModularPanel) 
else
	--client to server rec panel
	function smModularPanel(sm)
		local recWidgets = {}
		local numWidgets = sm:ReadShort()
		for i = 1, numWidgets do
			table.insert (recWidgets, {
				name = sm:ReadString(),
				widgetType = sm:ReadShort(),
				x = sm:ReadShort(),
				y = sm:ReadShort(),
				w = sm:ReadShort(),
				h = sm:ReadShort(),
				params = {},
				wire = {name = "", type = 0}
			})
			local numParams = sm:ReadShort()
			Msg("rec "..numParams..", params\n")
			for n = 1, numParams do
				local paramIndex = sm:ReadString()
				local paramData = sm:ReadString()
				recWidgets[table.getn(recWidgets)].params[paramIndex] = paramData
				Msg("read param index = "..paramIndex..", data = "..paramData..", for "..recWidgets[table.getn(recWidgets)].name.."\n")
			end
			local hasWire = sm:ReadBool()
			if hasWire then
				Msg("rec wire\n")
				recWidgets[table.getn(recWidgets)].wire.wireType = sm:ReadShort()
				recWidgets[table.getn(recWidgets)].wire.name = sm:ReadString()
			end
		end
		Msg("recieved "..numWidgets.." widgets from "..tostring(sm.player).."\n")
		for k, w in ipairs (recWidgets) do
			Msg("recieved widget "..w.name..", x = "..w.x..", y = "..w.y..", w = "..w.w..", h = "..w.h.."\n")
		end
		local trace = modularPanelTraceBuffer[sm.player:UniqueID()]
		Msg("about to spawn (stopped?)\n")
		spawnModularPanel(sm.player, trace, recWidgets)
	end
	servermessage.Hook("smsgModularPanel", smModularPanel) 
	
	--server to client send panel
	function sendClientPanel(player, widgetTable)
		Msg("sending config\n")
		local conf = sm:ReadBool()		
		umsg.Start("smsgModularPanel", player)
			smsg.Short (table.getn(widgetTable))
			
			for k, wid in ipairs (widgetTable) do
				if (wid and wid.name) then
					Msg("trying "..wid.name.."\n")
					--Msg ("widget = "..table.concat (wid, ", "))
					umsg.String (wid.name)
					umsg.Short (wid.widgetType)
					umsg.Short (wid.x)
					umsg.Short (wid.y)
					umsg.Short (wid.w)
					umsg.Short (wid.h)
					
					local numParams = table.Count(wid.params)
					umsg.Short (numParams)
					Msg("sending "..numParams..", params\n")
					for pk, par in pairs (wid.params) do
						Msg("write param #"..pk.." = "..par.."\n")
						umsg.String (pk)
						umsg.String (par)
					end
					
					if (wid.wire.wireType > 0) then
						Msg("send wire\n")
						umsg.Bool (true)
						Msg("sending wire, type = "..wid.wire.wireType..", name = "..wid.wire.name.."\n")
						umsg.Short (wid.wire.wireType)
						umsg.String (wid.wire.name)
					else
						umsg.Bool (false)
					end
				end
			end
		umsg.End() 
	end

end

-------------------------------------------------------------------END Communications ------------------------------------------------------------



--------------------------------------------------------------------Stool panels-----------------------------------------------------------------------
--try local
function modularPanelBuildBrowsePanel(panel)
	local Actions = {
		Label = "#WireModularPanelTool_filelist",
		MenuButton = "0",
		Height = 180,
		Options = {}
	}
	
	local fileList = file.Find("modular_panels/*.txt")
	local fileTable = {}
	for k, file in ipairs(fileList) do
		if(string.sub(file, -4) == ".txt") then
			table.insert(fileTable, file)
		end
	end

	for k,v in pairs(fileTable) do
		Actions.Options[v] = { wire_modular_panel_fileselect = v }
	end
	panel:AddControl("ListBox", Actions)
	
	panel:AddControl("ComboBox",
		{	Label		= "#Tool_wire_textscreen_model",
			MenuButton	= 0,
			Options		=
			{	["#Small tv"]		= { wire_modular_panel_model = "models/props_lab/monitor01b.mdl" },
				["#Plasma tv"]		= { wire_modular_panel_model = "models/props/cs_office/TV_plasma.mdl" },
				["#LCD monitor"]	= { wire_modular_panel_model = "models/props/cs_office/computer_monitor.mdl" },
				["#Monitor Big"]	= { wire_modular_panel_model = "models/kobilica/wiremonitorbig.mdl" },
				["#Monitor Small"]	= { wire_modular_panel_model = "models/kobilica/wiremonitorsmall.mdl" }
			}
	})
	
	panel:AddControl("Button", {
		Text = "New",
		Name = "New",
		Command = "wire_modular_panel_new"
	})
	panel:AddControl("Button", {
		Text = "Edit",
		Name = "Edit",
		Command = "wire_modular_panel_edit"
	})
end

function modularPanelBuildEditPanel(panel)
	local Actions = {
		Label = "#WireModularPanelTool_panelTheme",
		MenuButton = "0",
		Options = {},
		Description = ""
	}
	for key, wid in pairs(guiP_colourScheme) do
		Actions.Options[wid.name] = { wire_modular_panel_panelTheme = key }
	end
	--panel:AddControl("ListBox", Actions)	
	panel:AddControl("ComboBox", Actions)	--todo: set wire to i/o when this is selected
	
	local Actions = {
		Label = "#WireModularPanelTool_widgetlist",
		MenuButton = "0",
		Height = 120,
		Options = {}
	}
	for key, wid in pairs(modular_panel_current_panel.widgets) do
		Msg("wid key = "..key.."\n")
		Msg("wid = "..tostring(wid).."\n")
		if wid.name then
			Actions.Options[wid.name] = {wire_modular_panel_widgetselect = key}
		else
			Msg("name error\n")
		end
	end
	panel:AddControl("ListBox", Actions)
	
	panel:AddControl("Button", {
		Text = "Add",
		Name = "Add",
		Command = "wire_modular_panel_widgetAdd"
	})
	panel:AddControl("Button", {
		Text = "Edit",
		Name = "Edit",
		Command = "wire_modular_panel_widgetEdit"
	})
	panel:AddControl("Button", {
		Text = "Remove",
		Name = "Remove",
		Command = "wire_modular_panel_widgetRemove"
	})
	--[[
	panel:AddControl("Button", {
		Text = "Toggle Preview",
		Name = "Toggle Preview",
		Command = "wire_modular_panel_togglePreview"
	})
	]]--
	panel:AddControl("Button", {
		Text = "Save",
		Name = "Save",
		Command = "wire_modular_panel_save"
	})
	panel:AddControl("Button", {
		Text = "Return",
		Name = "Return",
		Command = "wire_modular_panel_return"
	})
	
end

--Widget editing panel
function modularPanelBuildWidgetEditPanel(panel)
	local widgetType = tonumber(LocalPlayer():GetInfo("wire_modular_panel_widgettype"))
	if widgetType and guiP_widgetLookup[widgetType] then
		local Actions = {
				Label = "#WireModularPanelTool_widgettypelist",
				MenuButton = "0",
				Options = {},
				Description = ""
			}
		for key, wid in pairs(panelWidget) do
			Actions.Options[wid.realName] = { wire_modular_panel_widgettype = guiP_widgetLookup[key] }
		end
		--panel:AddControl("ListBox", Actions)	
		panel:AddControl("ComboBox", Actions)	--todo: set wire to i/o when this is selected
		--LocalPlayer():ConCommand('wire_modular_panel_widgettype_command "'..wType..'"')
		
		panel:AddControl("Button", {
			Text = "Update",
			Name = "Update",
			Command = "wire_modular_panel_widgetTypeUpdate"
		})
		Msg ("type = "..widgetType.."\n")
		Msg ("lookup = "..guiP_widgetLookup[widgetType].."\n")
		panel:AddControl("Label", {
			Label = "",
			Text = "Current Widget Type: " .. panelWidget[guiP_widgetLookup[widgetType]].realName
		})
		
		panel:AddControl("TextBox", {
			Label = "#Tool_wire_modular_panel_widgetname",
			MaxLength = tostring(50),
			Command = "wire_modular_panel_widgetname"
		})
		panel:AddControl("Slider", {
			Label = "#Tool_wire_modular_panel_wxpos",
			Description = "", Type = "Integer",
			Min = "1", Max = "200",
			Command = "wire_modular_panel_wxpos"
		})
		panel:AddControl("Slider", {
			Label = "#Tool_wire_modular_panel_wypos",
			Description = "",
			Type = "Integer",
			Min = "1",
			Max = "200",
			Command = "wire_modular_panel_wypos"
		})
		panel:AddControl("Slider", {
			Label = "#Tool_wire_modular_panel_wwidth",
			Description = "",
			Type = "Integer",
			Min = "1",
			Max = "200",
			Command = "wire_modular_panel_wwidth"
		})
		panel:AddControl("Slider", {
			Label = "#Tool_wire_modular_panel_wheight",
			Description = "", Type = "Integer",
			Min = "1", Max = "200",
			Command = "wire_modular_panel_wheight"
		})
		
		local wireText = ""
		if (panelWidget[guiP_widgetLookup[widgetType]].wireType == 1) then
			wireText = "Wire Input Name"
		elseif (panelWidget[guiP_widgetLookup[widgetType]].wireType == 2) then
			wireText = "Wire Output Name"
		end
		if (panelWidget[guiP_widgetLookup[widgetType]].wireType > 0) then
			panel:AddControl("TextBox", {
				Label = wireText,
				MaxLength = tostring(50),
				Command = "wire_modular_panel_wirename"
			})
		end
		--panel:AddControl("TextBox", {Label = "#Tool_wire_modular_panel_extraparams", MaxLength = tostring(50), Command = "wire_modular_panel_extraparams"})
		
		local wid = panelWidget[guiP_widgetLookup[widgetType]]
		for pk, par in pairs (wid.paramTable) do
			Msg("widget has parameter "..pk.."\n")
			if (par.stool.stype == 1) then
				panel:AddControl("Slider", {
					Label = par.realName,
					Description = "", Type = "Integer",
					Min = par.stool.smin, Max = par.stool.smax,
					Command = "wire_modular_panel_widgetParam"..par.index
				})
			elseif (par.stool.stype == 2) then
				panel:AddControl("TextBox", {
					Label = par.realName,
					MaxLength = tostring(50),
					Command = "wire_modular_panel_widgetParam"..par.index
				})
			elseif (par.stool.stype == 3) then
				panel:AddControl("Checkbox", {
					Label = par.realName,
					Command = "wire_modular_panel_widgetParam"..par.index
				})
			else
				Msg ("modular panel parameter error\n")
			end
			
		end
	else
		wire_modular_panel_widget_message = "Update widget type"
	end

	panel:AddControl("Label", {
		Label = "",
		Text = wire_modular_panel_widget_message
	})
	panel:AddControl("Button", {
		Text = "Return",
		Name = "Return",
		Command = "wire_modular_panel_widgetReturn"
	})
	
end

--main panel rebuild function
function modularPanelRebuildPanel(panel, state)
	LocalPlayer():ConCommand("wire_modular_panel_currentStoolPanel "..state)
	if !panel then
		panel = GetControlPanel("wire_modular_panel")
		if !panel then return end
	end

	panel:ClearControls()
	panel:AddControl("Header", { Text = "#Tool_wire_modular_panel_name", Description = "#Tool_wire_modular_panel_desc" })
	
	if (state == 1) then
		modularPanelBuildBrowsePanel(panel)
	elseif (state == 2) then
		modularPanelBuildEditPanel(panel)
	elseif (state == 3) then
		modularPanelBuildWidgetEditPanel(panel)
	end
end

--------------------------------------------------------------------END Stool panels-----------------------------------------------------------------------

-------------------------------------------------------------------Button event calls------------------------------------------------------------------------
function ModularPanelAddPanel(player, command, args)
	if SERVER then
		player:SendLua('ModularPanelAddPanel()')
	else
		modular_panel_current_panel = {widgets = {}}
		modularPanelRebuildPanel(nil, 2)
	end
end

--edit button (mode)
function ModularPanelEditPanel(player, command, args)
	if SERVER then
		local fileselect = self:GetClientInfo("fileselect")
		if (file.Exists("modular_panels/"..fileselect)) then
		local pFile = file.Read("modular_panels/"..fileselect) 
			local widTable = guiP_fileDataToTable (pFile)
			sendClientPanel(player, widTable)
		else
			Msg("file not found\n") --make say in stool panel
		end
		
		--player:SendLua('ModularPanelEditPanel()')
	else
		
		--modularPanelRebuildPanel(nil, 2)
	end
end

--browse button (mode)
function ModularPanelReturn(player, command, args)
	if SERVER then
		player:SendLua('ModularPanelReturn()')
	else
		modularPanelRebuildPanel(nil, 1)
	end
end

--add a new widget (and go to edit panel)
function ModularPanelWidgetAdd(player, command, args)
	if SERVER then
		player:SendLua('ModularPanelWidgetAdd()')
	else
		
		table.insert(modular_panel_current_panel.widgets, {})
		local newIndex = table.getn(modular_panel_current_panel.widgets)
		Msg("new index = "..newIndex.."\n")
		modular_panel_current_widget = table.Copy(modular_panel_blank_widget)
		modular_panel_current_widget.name = "newWidget"	--todo: search widgets, add #1, #2 etc to end if already exists
		modular_panel_current_widget.index = newIndex
		wire_modular_panel_widget_message = ""
		--clientPanelUpdateWidget()
		clientPanelClearAll()
		clientPanelLoadDefaults()
		modularPanelRebuildPanel(nil, 3)
	end
end

--edit current widget
function ModularPanelWidgetEdit(player, command, args)
	if SERVER then
		player:SendLua('ModularPanelWidgetEdit()')
	else
		local editWidget = tonumber(LocalPlayer():GetInfo("wire_modular_panel_widgetselect"))
		Msg ("opening "..editWidget.."\n")
		modular_panel_current_widget = table.Copy(modular_panel_current_panel.widgets[editWidget])
		clientPanelUpdateWidget()
		--modular_panel_toolEnabled = false
		wire_modular_panel_widget_message = ""
		modularPanelRebuildPanel(nil, 3)
	end
end

--remove current widget
function ModularPanelWidgetRemove(player, command, args)
	if SERVER then
		player:SendLua('ModularPanelWidgetRemove()')
	else
		local removeWidget = LocalPlayer():GetInfo("wire_modular_panel_widgetselect") 
		table.remove(modular_panel_current_panel.widgets, removeWidget)
		modularPanelRebuildPanel(nil, 2)
	end
end

function ModularPanelTogglePreview(player, command, args)
	if SERVER then
		player:SendLua('ModularPanelTogglePreview()')
	else
		modular_panel_preview_enabled = !modular_panel_preview_enabled
	end
end

--return to main panel editing
function ModularPanelWidgetReturn(player, command, args)
	if SERVER then
		player:SendLua('ModularPanelWidgetReturn()')
	else
		if (modular_panel_current_widget_update == tonumber(LocalPlayer():GetInfo("wire_modular_panel_widgettype"))) then
			wire_modular_panel_widget_message = ""
			clientPanelReadWidget()
			if (modular_panel_current_widget.name ~= "") then
				if (not (modular_panel_current_widget.wire.wireType > 0 and modular_panel_current_widget.wire.name == "")) then
					for k, par in pairs (modular_panel_current_widget.params) do
						--if 
					end
					modular_panel_current_panel.widgets[modular_panel_current_widget.index] = table.Copy(modular_panel_current_widget)
					Msg("curname = "..modular_panel_current_widget.name.."\n")
					Msg("widget "..modular_panel_current_widget.index.." name = "..modular_panel_current_panel.widgets[modular_panel_current_widget.index].name.."\n")
					modular_panel_toolEnabled = true
					modularPanelRebuildPanel(nil, 2)
					Msg("client listing widgets:\n")
					for k, w in ipairs (modular_panel_current_panel.widgets) do
						Msg(w.name.."\n")
					end
				else
					wire_modular_panel_widget_message = "You must enter a wire name"
					modularPanelRebuildPanel(nil, 3)
				end
			else
				wire_modular_panel_widget_message = "You must enter a widget name"
				modularPanelRebuildPanel(nil, 3)
			end
		else
			wire_modular_panel_widget_message = "Updating widget type"
			ModularPanelWidgetUpdate()
		end
		wire_modular_panel_widget_message = ""
		--ModularPanelWidgetUpdate()
	end
end

function ModularPanelWidgetUpdate(player, command, args)
	if SERVER then
		player:SendLua('ModularPanelWidgetUpdate()')
	else
		modular_panel_current_widget_update = tonumber(LocalPlayer():GetInfo("wire_modular_panel_widgettype"))
		clientPanelReadWidget()
		modularPanelRebuildPanel(nil, 3)
		
		clientPanelUpdateWidget()
		clientPanelClearParams()
		clientPanelLoadDefaults()
	end
end

-------------------------------------------------------------------END Button event calls------------------------------------------------------------------------

--Button concommands
if SERVER then
	concommand.Add("wire_modular_panel_new", ModularPanelAddPanel)
	concommand.Add("wire_modular_panel_edit", ModularPanelEditPanel)
	concommand.Add("wire_modular_panel_return", ModularPanelReturn)
	concommand.Add("wire_modular_panel_widgetEdit", ModularPanelWidgetEdit)
	concommand.Add("wire_modular_panel_widgetReturn", ModularPanelWidgetReturn)
	concommand.Add("wire_modular_panel_widgetAdd", ModularPanelWidgetAdd)
	concommand.Add("wire_modular_panel_widgetRemove", ModularPanelWidgetRemove)
	concommand.Add("wire_modular_panel_widgetTypeUpdate", ModularPanelWidgetUpdate)
	concommand.Add("wire_modular_panel_togglePreview", ModularPanelTogglePreview)
	

else


end


if CLIENT then
	function clientPanelUpdateWidget()
		LocalPlayer():ConCommand('wire_modular_panel_widgetname "'..modular_panel_current_widget.name..'"')
		LocalPlayer():ConCommand('wire_modular_panel_wxpos "'..modular_panel_current_widget.x..'"')
		LocalPlayer():ConCommand('wire_modular_panel_wypos "'..modular_panel_current_widget.y..'"')
		LocalPlayer():ConCommand('wire_modular_panel_wwidth "'..modular_panel_current_widget.w..'"')
		LocalPlayer():ConCommand('wire_modular_panel_wheight "'..modular_panel_current_widget.h..'"')
		LocalPlayer():ConCommand('wire_modular_panel_widgettype "'..modular_panel_current_widget.widgetType..'"')
		LocalPlayer():ConCommand('wire_modular_panel_wirename "'..modular_panel_current_widget.wire.name..'"')
		for k, par in ipairs (modular_panel_current_widget.params) do
			LocalPlayer():ConCommand("wire_modular_panel_widgetParam"..k.." "..par)
		end
	end
	
	function clientPanelReadWidget()
		modular_panel_current_widget.name = LocalPlayer():GetInfo("wire_modular_panel_widgetname")
		modular_panel_current_widget.widgetType = tonumber(LocalPlayer():GetInfo("wire_modular_panel_widgettype"))
		modular_panel_current_widget.x = tonumber(LocalPlayer():GetInfo("wire_modular_panel_wxpos"))
		modular_panel_current_widget.y = tonumber(LocalPlayer():GetInfo("wire_modular_panel_wypos"))
		modular_panel_current_widget.w = tonumber(LocalPlayer():GetInfo("wire_modular_panel_wwidth"))
		modular_panel_current_widget.h = tonumber(LocalPlayer():GetInfo("wire_modular_panel_wheight"))
		modular_panel_current_widget.wire.name = LocalPlayer():GetInfo("wire_modular_panel_wirename")
		Msg("getting wire info from widget #"..modular_panel_current_widget.widgetType.."\n")
		Msg(" = "..guiP_widgetLookup[modular_panel_current_widget.widgetType].."\n")
		Msg("name = "..panelWidget[guiP_widgetLookup[modular_panel_current_widget.widgetType]].name.."\n")
		Msg("wire type = "..panelWidget[guiP_widgetLookup[modular_panel_current_widget.widgetType]].wireType.."\n")
		modular_panel_current_widget.wire.wireType = panelWidget[guiP_widgetLookup[modular_panel_current_widget.widgetType]].wireType
		
		for k, par in pairs (panelWidget[guiP_widgetLookup[modular_panel_current_widget.widgetType]].paramTable) do
			modular_panel_current_widget.params[k] = LocalPlayer():GetInfo("wire_modular_panel_widgetParam"..par.index)
		end
	end
	
	function clientPanelClearParams()
		for i = 1, 6 do
			LocalPlayer():ConCommand('wire_modular_panel_widgetParam'..i..' ""')
		end
	end
	
	function clientPanelClearAll()
		LocalPlayer():ConCommand('wire_modular_panel_widgetname ""')
		LocalPlayer():ConCommand('wire_modular_panel_wxpos "0"')
		LocalPlayer():ConCommand('wire_modular_panel_wypos "0"')
		LocalPlayer():ConCommand('wire_modular_panel_wwidth "0"')
		LocalPlayer():ConCommand('wire_modular_panel_wheight "0"')
		LocalPlayer():ConCommand('wire_modular_panel_widgettype "0"')
		LocalPlayer():ConCommand('wire_modular_panel_wirename ""')
		
		clientPanelClearParams()
	end
	
	function clientPanelLoadDefaults()
		for k, par in ipairs (modular_panel_current_widget.params) do
			--modular_panel_current_widget.params[par.index] = LocalPlayer():GetInfo("wire_modular_panel_widgetParam"..par.index)
			local defVal = panelWidget[guiP_widgetLookup[modular_panel_current_widget.widgetType]].paramTable[k].default
			LocalPlayer():ConCommand("wire_modular_panel_widgetParam"..k.." "..defVal)
		end
	end
end





----------------------------------------------------------

if CLIENT then
	modular_panel_blank_widget = {
		name = "",
		index = 0,
		widgetType = 1,--use text?
		x = 0,
		y = 0,
		w = 0,
		h = 0,
		params = {},
		wire = {name = "", wireType = nil}
	}
		
	modular_panel_current_panel = {widgets = {}}
	modular_panel_current_widget = table.Copy(modular_panel_blank_widget)
	
	--panel editing panel
	CreateClientConVar("wire_modular_panel_widgetselect", "0", false, false)
	
	--widget editing panel
	CreateClientConVar("wire_modular_panel_wxpos", "0", false, false)
	CreateClientConVar("wire_modular_panel_wypos", "0", false, false)
	CreateClientConVar("wire_modular_panel_wwidth", "0", false, false)
	CreateClientConVar("wire_modular_panel_wheight", "0", false, false)
	CreateClientConVar("wire_modular_panel_widgettype", "0", false, false)
	
	CreateClientConVar("wire_modular_panel_widgetname", "", false, false)
	CreateClientConVar("wire_modular_panel_wirename", "", false, false)
	--CreateClientConVar("wire_modular_panel_wiretype", "", false, false)
	
	CreateClientConVar("wire_modular_panel_panelTheme", "0", false, false)
	
	CreateClientConVar("wire_modular_panel_widgetParam1", "0", false, false)
	CreateClientConVar("wire_modular_panel_widgetParam2", "0", false, false)
	CreateClientConVar("wire_modular_panel_widgetParam3", "0", false, false)
	CreateClientConVar("wire_modular_panel_widgetParam4", "0", false, false)
	CreateClientConVar("wire_modular_panel_widgetParam5", "0", false, false)
	CreateClientConVar("wire_modular_panel_widgetParam6", "0", false, false)
	
	
	function modpanDrawHud()
		if modular_panel_preview_enabled then
			local sh = surface.ScreenHeight( )
			local sw = surface.ScreenWidth( )
			surface.SetDrawColor( 50, 255, 50, 50 )
			local prevWidth = 200
			local prevHeight = 200
			local prevX = (sw - prevWidth) / 2
			local prevY = (sh - prevHeight) / 2
			surface.DrawOutlinedRect( prevX, prevY, prevWidth, prevHeight ) 
			
			--draw all stored widgets
			surface.SetDrawColor( 255, 255, 255, 50 )
			for k, wid in ipairs (modular_panel_current_panel.widgets) do
				surface.DrawOutlinedRect( prevX + wid.x, prevY + wid.y, wid.w, wid.h ) 
			end
						
			--draw currently editing widget
			local curX = tonumber(LocalPlayer():GetInfo("wire_modular_panel_wxpos"))
			local curY = tonumber(LocalPlayer():GetInfo("wire_modular_panel_wypos"))
			local curW = tonumber(LocalPlayer():GetInfo("wire_modular_panel_wwidth"))
			local curH = tonumber(LocalPlayer():GetInfo("wire_modular_panel_wheight"))
			
			surface.SetDrawColor( 50, 50, 255, 50 ) 
			surface.DrawOutlinedRect( prevX + modular_panel_current_widget.x, prevY + modular_panel_current_widget.y, modular_panel_current_widget.w, modular_panel_current_widget.h ) 
		end
	end
	hook.Add("HUDPaint", "modpanePreview", modpanDrawHud)
	
end





