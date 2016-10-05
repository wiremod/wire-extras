--	gui Panel Test entity - greenarrow
--example:
--self:setWidgetProperty("myname", "widgetInput", value)	--sets a property of a widget

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:SpawnFunction( ply, tr )
	if ( !tr.Hit ) then return end
	local SpawnPos = tr.HitPos + tr.HitNormal * 16
	local ent = ents.Create("gmod_test_panel_adv")
	ent:SetPos(SpawnPos)
	ent:Spawn()
	ent:Activate()
	
	return ent
end

function ENT:Initialize()
	self.Entity:SetModel("models/kobilica/guipmonitorbig.mdl")		--multiple model support will be added at a later date
	self.Entity:PhysicsInit(SOLID_VPHYSICS)
	self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
	self.Entity:SetSolid(SOLID_VPHYSICS) 
	local phys = self.Entity:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
	end

	guiP_PanelInit(self.Entity, 200, 200)							-- Initialize panel
	self:BuildPanel()												-- calls function in shared.lua (in this test entity, not the library)
	
	guiP_SetPanelScheme(self.Entity, "highContWhite")				-- see 'lua\entities\base_gui_panel\schemes\base.lua' for a list of schemes, read in-file notes on creating your own.
	guiP_SetPanelState(self.Entity, true)							-- sets panel to usable mode
end

--This function is called by the library when a player clicks on a widget.
function ENT:widgetOutput (ply, widgetName, outputName, value)							--all widgets have one output, therefore we don't need to check the output name.
	print ("clk on "..widgetName..", "..outputName..", "..value.."\n")
	if (widgetName == "buttona") then
		if (value > 0) then
			Msg("Button A was clicked, setting list1\n")
			guiP_setWidgetProperty(self.Entity, "list1", "options", "god|ween|satan")	--setting some options in list1
		end

	elseif (widgetName == "buttonb") then
		if (value > 0) then
			Msg("Button B was clicked, clearing list1\n")
			guiP_setWidgetProperty(self.Entity, "list1", "options", "")					--clearing options from list1
		end

	elseif (widgetName == "toggle_button") then	
		if (value > 0) then
			Msg("Toggle Button is on\n")
		else
			Msg("Toggle Button is off\n")
		end

	elseif (widgetName == "list1") then		
		Msg("List item "..tostring(value).." selected\n")

	elseif (widgetName == "slider1") then	
		guiP_setWidgetProperty(self.Entity, "indicator1", "value", value)			 --setting brightness of indicator1 to value of slider1
		guiP_setWidgetProperty(self.Entity, "prog1", "value", value)				 --setting value of prog1 to value of slider1
		
	elseif (widgetName == "textent1") then
		Msg("'"..value.."' was typed into textent1\n")
	end
end


function ENT:OnRestore()
	self.BaseClass.OnRestore(self)
end
