TOOL.Category		= "Wire Extras/GUI Panels"
TOOL.Name			= "Set Draw Params"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.ClientConVar["drawx"] = ""
TOOL.ClientConVar["drawy"] = ""
TOOL.ClientConVar["draww"] = ""
TOOL.ClientConVar["drawh"] = ""
TOOL.ClientConVar["drawres"] = ""

if CLIENT then
    language.Add( "Tool_drawchanger_name", "Developer Tool" )
    language.Add( "Tool_drawchanger_desc", "change draw params" )
    language.Add( "Tool_drawchanger_0", "Primary: set draw params, Sec: " )
	language.Add("Tool_drawchanger_drawvariable", "Variable:")
	language.Add("Tool_drawchanger_drawvalue", "Value:")
	language.Add("Tool_drawchanger_drawx", "X:")
	language.Add("Tool_drawchanger_drawy", "Y:")
	language.Add("Tool_drawchanger_draww", "W:")
	language.Add("Tool_drawchanger_drawh", "H:")
	language.Add("Tool_drawchanger_drawres", "Res:")

	net.Receive("umsgDrawChangerCfg", function()
		local ent = net.ReadEntity()
		if not IsValid(ent) then return end

		ent.drawParams = ent.drawParams or {}
		ent.drawParams.x = net.ReadFloat()
		ent.drawParams.y = net.ReadFloat()
		ent.drawParams.w = net.ReadFloat()
		ent.drawParams.h = net.ReadFloat()
		ent.drawParams.Res = net.ReadFloat()

		gpCalcDrawCoefs(ent)
	end) 
end

if SERVER then
	util.AddNetworkString("umsgDrawChangerCfg")
	function TOOL:sendSetVal(ent, x, y, w, h, res)
		net.Start("umsgDrawChangerCfg")
			net.WriteEntity(ent)
			net.WriteFloat(x)
			net.WriteFloat(y)
			net.WriteFloat(w)
			net.WriteFloat(h)
			net.WriteFloat(res)
		net.Broadcast()	--do we need to send entity with all user messages (so we know which pannel we are talking about?) 
	end
end

function TOOL:LeftClick( trace )
	if not IsValid(trace.Entity) then return false end
	if trace.Entity:IsPlayer() then return false end
	if CLIENT then return true end

	local x = self:GetClientNumber("drawx", 0)
	local y = self:GetClientNumber("drawy", 0)
	local w = self:GetClientNumber("draww", 0)
	local h = self:GetClientNumber("drawh", 0)
	local res = self:GetClientNumber("drawres", 0)
	
	self:sendSetVal(trace.Entity, x, y, w, h, res)
	
	return true
end

function TOOL:RightClick( trace )
	return false
end

function TOOL:Think()
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_modular_panel_name", Description = "#Tool_wire_modular_panel_desc" })
	panel:AddControl("TextBox", {Label = "#Tool_drawchanger_drawx", MaxLength = tostring(50), Command = "drawchanger_drawx"})
	panel:AddControl("TextBox", {Label = "#Tool_drawchanger_drawy", MaxLength = tostring(50), Command = "drawchanger_drawy"})
	panel:AddControl("TextBox", {Label = "#Tool_drawchanger_draww", MaxLength = tostring(50), Command = "drawchanger_draww"})
	panel:AddControl("TextBox", {Label = "#Tool_drawchanger_drawh", MaxLength = tostring(50), Command = "drawchanger_drawh"})
	panel:AddControl("TextBox", {Label = "#Tool_drawchanger_drawres", MaxLength = tostring(50), Command = "drawchanger_drawres"})
end
