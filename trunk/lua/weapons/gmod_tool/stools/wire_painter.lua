TOOL.Category		= "Wire Extras/Visuals"
TOOL.Name			= "Painter"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

if ( CLIENT ) then
    language.Add( "Tool.wire_painter.name", "Painter Tool (Wire)" )
    language.Add( "Tool.wire_painter.desc", "Spawns a decal painter for use with the wire system." )
    language.Add( "Tool.wire_painter.0", "Primary: Create/Update Painter" )
    language.Add( "WirePainterTool_painter", "Painter:" )
    language.Add( "WirePainterTool_playsnd", "Play Sound:" )
    language.Add( "WirePainterTool_paintrate", "Paint Rate:" )
    language.Add( "WirePainterTool_decal", "Decal:" )
    language.Add( "WirePainterTool_Range", "Max Range:" )
    language.Add( "WirePainterTool_Model", "Choose a Model:")
	language.Add( "sboxlimit_wire_painters", "You've hit painters limit!" )
	language.Add( "undone_Wire Painter", "Undone Wire Painter" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_painters', 20)
	CreateConVar('sbox_wire_painters_maxlen', 30)
	CreateConVar('sbox_wire_painters_allowtrgply',1)
end

TOOL.ClientConVar[ "playsnd" ] = "1"
TOOL.ClientConVar[ "paintrate" ] = "0"
TOOL.ClientConVar[ "decal" ] = "Blood"
TOOL.ClientConVar[ "Range" ] = 2048
TOOL.ClientConVar[ "Model" ] = "models/jaanus/wiretool/wiretool_siren.mdl"

local paintermodels = {
    ["models/jaanus/wiretool/wiretool_beamcaster.mdl"] = {},
    ["models/jaanus/wiretool/wiretool_siren.mdl"] = {}};

cleanup.Register( "wire_painters" )

function TOOL:LeftClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()

	local playsnd = (self:GetClientNumber( "playsnd" ) ~= 0)
	local paintrate = self:GetClientNumber("paintrate")
	local decal = self:GetClientInfo("decal")
	local Range = self:GetClientNumber("Range")
	local model = self:GetClientInfo("Model")
	
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_painter" && trace.Entity:GetTable().pl == ply ) then
		trace.Entity:Setup(Range, decal, playsnd, paintrate)
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_painters" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
	
	

	local wire_painter = MakeWirePainter( ply, trace.HitPos, Range, decal, playsnd, paintrate, model, Ang )

	local min = wire_painter:OBBMins()
	wire_painter:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld(wire_painter, trace.Entity, trace.PhysicsBone, true)

	undo.Create("Wire Painter")
		undo.AddEntity( wire_painter )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_painters", wire_painter )

	return true
end

if (SERVER) then

	function MakeWirePainter( pl, Pos, Range, decal, playsnd, paintrate, Model, Ang )
		if ( !pl:CheckLimit( "wire_painters" ) ) then return false end
	
		local wire_painter = ents.Create( "gmod_wire_painter" )
		if (!wire_painter:IsValid()) then return false end

		wire_painter:SetAngles( Ang )
		wire_painter:SetPos( Pos )
		wire_painter:SetModel( Model )
		wire_painter:Spawn()
		wire_painter:Setup(Range, decal, playsnd, paintrate)

		wire_painter:SetPlayer( pl )

		local ttable = {
		    Range = Range,
			Decal = decal,
			PlaySound = playsnd,
			PaintRate = paintrate,
			pl = pl
		}
		table.Merge(wire_painter:GetTable(), ttable )
		
		pl:AddCount( "wire_painters", wire_painter )

		return wire_painter
	end
	
	duplicator.RegisterEntityClass("gmod_wire_painter", MakeWirePainter, "Pos", "Range", "Decal", "PlaySound", "PaintRate", "Model", "Ang", "Vel", "aVel", "frozen")

end

function TOOL:UpdateGhostWirePainter( ent, player )
	if ( !ent || !ent:IsValid() ) then return end

	local tr 	= util.GetPlayerTrace( player, player:GetAimVector() )
	local trace 	= util.TraceLine( tr )

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_painter" ) then
		ent:SetNoDraw( true )
		return
	end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local min = ent:OBBMins()
	ent:SetPos( trace.HitPos - trace.HitNormal * min.z )
	ent:SetAngles( Ang )

	ent:SetNoDraw( false )
end

function TOOL:Think()
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self:GetClientInfo("Model") ) then
		self:MakeGhostEntity( self:GetClientInfo("Model"), Vector(0,0,0), Angle(0,0,0) )
	end

	self:UpdateGhostWirePainter( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool.wire_painter.name", Description = "#Tool.wire_painter.desc" })

	panel:AddControl( "PropSelect", { Label = "#WirePainterTool_Model",
									 ConVar = "wire_painter_Model",
									 Category = "Wire Painter",
									 Models = paintermodels } )
									 
	local Options = list.Get( "PaintMaterials" )
	table.sort( Options )
	
	local RealOptions = {}

	for k, decal in pairs( Options ) do	
		RealOptions[ decal ] = { wire_painter_decal = decal }
	end
		
	panel:AddControl( "ListBox", {
		Label = "#WirePainterTool_decal",
		Height = "300",
		Options = RealOptions
	} )
	
	panel:AddControl("CheckBox", {
		Label = "#WirePainterTool_playsnd",
		Command = "wire_painter_playsnd"
	})
	
	panel:AddControl("Slider", {
		Label = "#WirePainterTool_paintrate",
		Type = "Float",
		Min = "0",
		Max = "2",
		Command = "wire_painter_paintrate"
	})
	
	panel:AddControl("Slider", {
		Label = "#WirePainterTool_Range",
		Type = "Float",
		Min = "1",
		Max = "10000",
		Command = "wire_painter_Range"
	})
end

