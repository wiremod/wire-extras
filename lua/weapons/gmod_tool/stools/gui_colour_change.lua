
TOOL.Category		= "GUI Panels"
TOOL.Name			= "Colour Scheme Changer"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_gui_colour_change_name", "gui-panel colour scheme changer" )
    language.Add( "Tool_gui_colour_change_desc", "Changes the colour scheme on any lib-gui-panel based device" )
    language.Add( "Tool_gui_colour_change_0", "Primary: Set panel colour scheme" )

	language.Add("GuiColourPanelTool_schemelist", "Colour scheme:")
	
end

TOOL.ClientConVar["colscheme"] = ""

function TOOL:LeftClick( trace )
	if trace.Entity && trace.Entity:IsPlayer() then return false end
	if (CLIENT) then return true end
	
	local themeName = self:GetClientInfo("colscheme")
	--Msg("new theme = "..themeName.."\n")
	if (trace.Entity.guiPanelVersion && themeName) then
		guiP_SetPanelScheme(trace.Entity, themeName)
	end
	
	return true
end

function TOOL:RightClick( trace )
	return true
end


function TOOL:Think()
end

function TOOL.BuildCPanel(panel)

	panel:AddControl("Header", { Text = "#Tool_gui_colour_change_name", Description = "#Tool_gui_colour_change_desc" })
	
	local Actions = {
	Label = "#GuiColourPanelTool_schemelist",
	MenuButton = "0",
	Height = 180,
	Options = {}
	}
	
	for k,v in pairs(guiP_colourScheme) do
	    Actions.Options[v.name] = { gui_colour_change_colscheme = k}
	end
	
	panel:AddControl("ListBox", Actions)	
	
	
end