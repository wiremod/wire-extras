WireToolSetup.open( "touchplate", "Touchplate", "gmod_wire_touchplate", nil, "Touchplates" )
WireToolSetup.SetupMax( 40, "wire_touchplates" , "You've hit the touchplates limit!" )

if CLIENT then
	language.Add( "Tool_wire_touchplate_name", "Wired Touch Plate" )
	language.Add( "Tool_wire_touchplate_desc", "Spawns a touch plate for use with the wire system." )
	language.Add( "Tool_wire_touchplate_0", "Primary: Create/Update touch plate, Secondary: Copy settings" )
end
WireToolSetup.BaseLang()

--WireToolSetup.SetupMax( 20, "wire_indicators", "You've hit indicators limit!" )

if SERVER then
	function TOOL:GetConVars()
		return self:GetClientNumber( "only_players" ) ~= 0
	end

	function TOOL:MakeEnt( ply, model, Ang, trace )
		return MakeWireTouchplate( ply, trace.HitPos, Ang, model, self:GetConVars() )
	end
end

TOOL.ClientConVar = {
	model = "models/props_phx/construct/metal_plate1.mdl",
	only_players = "1",
}

function TOOL.BuildCPanel(panel)
	panel:CheckBox("Only trigger for players", "wire_touchplate_only_players")
end
