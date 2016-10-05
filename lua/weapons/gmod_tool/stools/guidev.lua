
TOOL.Category		= "GUI Panels"
TOOL.Name			= "guiPanel Dev"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_guidev_name", "gui Panel Developer Tool" )
    language.Add( "Tool_guidev_desc", "Does stuff to gui panels...." )
    language.Add( "Tool_guidev_0", "Primary: Set widget propery\nSecondary: Set panel colour scheme" )
	language.Add("Tool_guidev_widname", "Widget name:")
	language.Add("Tool_guidev_widinput", "Widget input:")
	language.Add("Tool_guidev_widproperty", "Widget property:")
	language.Add("Tool_guidev_themename", "Colour scheme:")
	
end

TOOL.ClientConVar["widinput"] = ""
TOOL.ClientConVar["widproperty"] = ""
TOOL.ClientConVar["widname"] = ""
TOOL.ClientConVar["themename"] = ""

function TOOL:LeftClick( trace )
	if trace.Entity && trace.Entity:IsPlayer() then return false end
	if (CLIENT) then return true end
	
	local widName = self:GetClientInfo("widname")
	local widInput = self:GetClientInfo("widinput")
	local widProperty = self:GetClientInfo("widproperty")
		
	if (trace.Entity.guiPanelVersion) then
		guiP_setWidgetProperty(trace.Entity, widName, widInput, widProperty)
	end
	
	return true
end

function TOOL:RightClick( trace )
	if trace.Entity && trace.Entity:IsPlayer() then return false end
	if (CLIENT) then return true end
	
	local themeName = self:GetClientInfo("themename")
	if (trace.Entity.guiPanelVersion) then
		guiP_SetPanelScheme(trace.Entity, themeName)
	end
	
	return true
end


function TOOL:Think()
end

function TOOL.BuildCPanel(panel)

	panel:AddControl("Header", { Text = "#Tool_wire_modular_panel_name", Description = "#Tool_wire_modular_panel_desc" })
	
	panel:AddControl("TextBox", {Label = "#Tool_guidev_widname", MaxLength = tostring(50), Command = "guidev_widname"})
	panel:AddControl("TextBox", {Label = "#Tool_guidev_widinput", MaxLength = tostring(50), Command = "guidev_widinput"})
	panel:AddControl("TextBox", {Label = "#Tool_guidev_widproperty", MaxLength = tostring(50), Command = "guidev_widproperty"})
	panel:AddControl("TextBox", {Label = "#Tool_guidev_themename", MaxLength = tostring(50), Command = "guidev_themename"})
end