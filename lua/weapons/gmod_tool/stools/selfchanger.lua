
TOOL.Category		= "GUI Panels"
TOOL.Name			= "Self changer"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_selfchanger_name", "Developer Tool" )
    language.Add( "Tool_selfchanger_desc", "changes self....." )
    language.Add( "Tool_selfchanger_0", "Primary: set self value, Sec: reload draw params" )
	--language.Add("Tool_selfchanger_widname", "Widget name:")
	
	language.Add("Tool_selfchanger_widvariable", "Variable:")
	language.Add("Tool_selfchanger_widvalue", "Value:")
	--language.Add("Tool_selfchanger_themename", "Colour scheme:")
	
	function umGetNewSet(um)
		
		local ent = um:ReadEntity()
		local var = um:ReadString()
		local val = um:ReadFloat()
		Msg("setting "..var.."\n")
		ent[var] = val
	end
	usermessage.Hook("umsgSelfNewSet", umGetNewSet) 


end


function TOOL:sendSetVal(ent, var, val)
	--Msg(string.format("value at ssi = %f\n", value))
	ent[var] = val
	local allPlayers = RecipientFilter()
	allPlayers:AddAllPlayers()
	umsg.Start("umsgSelfNewSet", allPlayers)	--do we need to send entity with all user messages (so we know which pannel we are talking about?)
		umsg.Entity(ent)
		umsg.String(var)
		umsg.Float(val)
	umsg.End() 
end

TOOL.ClientConVar["widvariable"] = ""
TOOL.ClientConVar["widvalue"] = ""


function TOOL:LeftClick( trace )
	if trace.Entity && trace.Entity:IsPlayer() then return false end
	if (CLIENT) then return true end
	--if (SERVER) then return true end
	
	local widVariable = self:GetClientInfo("widvariable")
	local widValue = self:GetClientInfo("widvalue")
		
	--if (trace.Entity:IsValid() && trace.Entity.guiPanelVersion && trace.Entity.pl == ply) then
	--trace.Entity[widVariable] = widValue
	self:sendSetVal(trace.Entity, widVariable, widValue)
	Msg("done\n")
		--return true
	--end
	
	return true
end

function TOOL:RightClick( trace )
	if trace.Entity && trace.Entity:IsPlayer() then return false end
	--if (CLIENT) then return true end
	if (SERVER) then return true end
	
	--local themeName = self:GetClientInfo("themename")
		
	--if (trace.Entity:IsValid() && trace.Entity.guiPanelVersion && trace.Entity.pl == ply) then
		--trace.Entity:SetPanelScheme(themeName)
		--return true
	--end
	gpSetupVals(trace.Entity)
	
	return true
end


function TOOL:Think()
end

function TOOL.BuildCPanel(panel)

	panel:AddControl("Header", { Text = "#Tool_wire_modular_panel_name", Description = "#Tool_wire_modular_panel_desc" })
	
	panel:AddControl("TextBox", {Label = "#Tool_selfchanger_widvariable", MaxLength = tostring(50), Command = "selfchanger_widvariable"})
	panel:AddControl("TextBox", {Label = "#Tool_selfchanger_widvalue", MaxLength = tostring(50), Command = "selfchanger_widvalue"})
	--panel:AddControl("TextBox", {Label = "#Tool_selfchanger_widproperty", MaxLength = tostring(50), Command = "selfchanger_widproperty"})
	--panel:AddControl("TextBox", {Label = "#Tool_selfchanger_themename", MaxLength = tostring(50), Command = "selfchanger_themename"})
end