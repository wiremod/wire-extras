WireToolSetup.setCategory("Wire Extras/Detection")
WireToolSetup.open("hstracer", "Highspeed Tracer", "gmod_wire_hstracer", nil, "Highspeed Rangers")

if CLIENT then
	language.Add( "Tool.wire_hstracer.name", "Highspeed Tracer Tool (Wire)" )
	language.Add( "Tool.wire_hstracer.desc", "Spawns a Highspeed Tracer for use with the wire system." )
	TOOL.Information = { { name = "left", text = "Create/Update " .. TOOL.Name } }
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax(10)

TOOL.ClientConVar.model = "models/jaanus/wiretool/wiretool_range.mdl"

function TOOL.BuildCPanel(panel)
	ModelPlug_AddToCPanel(panel, "gate", "wire_hstracer")
end

