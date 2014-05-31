
TOOL.Category		= "Wire Extras/RFID"
TOOL.Name			= "Beam Reader"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

if ( CLIENT ) then
    language.Add( "Tool.wire_rfid_reader_beam.name", "RFID Beam Reader Tool (Wire)" )
    language.Add( "Tool.wire_rfid_reader_beam.desc", "Spawns a RFID reader for use with the wire system." )
    language.Add( "Tool.wire_rfid_reader_beam.0", "Primary: Create/Update Beam Reader" )
    language.Add( "WireBeamReaderTool_reader_beam", "RFID Beam Reader:" )
    language.Add( "WireBeamReaderTool_Range", "Max Range:" )
    language.Add( "WireBeamReaderTool_NoColorChg", "Don't change colour on state changed" )
	language.Add( "sboxlimit_wire_rfid_reader_beams", "You've hit readers limit!" )
	language.Add( "undone_Wire Beam Reader", "Undone Wire Beam Reader" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_rfid_reader_beams', 20)
	CreateConVar('sbox_wire_rfid_reader_beams_maxlen', 30)
end

TOOL.ClientConVar[ "Range" ] = 2048
TOOL.ClientConVar[ "NoColorChg" ] = 0

TOOL.Model = "models/jaanus/wiretool/wiretool_range.mdl"

cleanup.Register( "wire_rfid_reader_beams" )

function TOOL:LeftClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_rfid_reader_beam" && trace.Entity:GetTable().pl == ply ) then
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_rfid_reader_beams" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
	
	local Range = self:GetClientNumber("Range")
	local NoColorChg = (self:GetClientNumber("NoColorChg")!=0)

	local wire_rfid_reader_beam = MakeWireBeamReader( ply, trace.HitPos, Range, NoColorChg, Ang )

	local min = wire_rfid_reader_beam:OBBMins()
	wire_rfid_reader_beam:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld(wire_rfid_reader_beam, trace.Entity, trace.PhysicsBone, true)

	undo.Create("Wire Beam Reader")
		undo.AddEntity( wire_rfid_reader_beam )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()


	ply:AddCleanup( "wire_rfid_reader_beams", wire_rfid_reader_beam )

	return true
end

function TOOL:RightClick( trace )
	return false
end

if (SERVER) then

	function MakeWireBeamReader( pl, Pos, Range, NoColorChg, Ang )
		if ( !pl:CheckLimit( "wire_rfid_reader_beams" ) ) then return false end
	
		local wire_rfid_reader_beam = ents.Create( "gmod_wire_rfid_reader_beam" )
		if (!wire_rfid_reader_beam:IsValid()) then return false end

		wire_rfid_reader_beam:SetAngles( Ang )
		wire_rfid_reader_beam:SetPos( Pos )
		wire_rfid_reader_beam:SetModel( Model("models/jaanus/wiretool/wiretool_range.mdl") )
		wire_rfid_reader_beam:Spawn()
		wire_rfid_reader_beam:Setup(Range,NoColorChg)

		wire_rfid_reader_beam:SetPlayer( pl )

		local ttable = {
		    Range = Range,
		    NoColorChg = NoColorChg,
			pl = pl
		}

		table.Merge(wire_rfid_reader_beam:GetTable(), ttable )
		
		pl:AddCount( "wire_rfid_reader_beams", wire_rfid_reader_beam )

		return wire_rfid_reader_beam
	end
	
	duplicator.RegisterEntityClass("gmod_wire_rfid_reader_beam", MakeWireBeamReader, "Pos", "Range", "NoColorChg", "Ang", "Vel", "aVel", "frozen")

end

function TOOL:UpdateGhostWireBeamReader( ent, player )
	if ( !ent || !ent:IsValid() ) then return end

	local tr 	= util.GetPlayerTrace( player, player:GetAimVector() )
	local trace 	= util.TraceLine( tr )

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_rfid_reader_beam" ) then
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
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self.Model ) then
		self:MakeGhostEntity( self.Model, Vector(0,0,0), Angle(0,0,0) )
	end

	self:UpdateGhostWireBeamReader( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool.wire_rfid_reader_beam.name", Description = "#Tool.wire_rfid_reader_beam.desc" })

	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_rfid_reader_beam",

		Options = {
			Default = {
				wire_rfid_reader_beam_reader_beam = "0",
			}
		},
		CVars = {
		}
	})
	
	panel:AddControl("Slider", {
		Label = "#WireBeamReaderTool_Range",
		Type = "Float",
		Min = "1",
		Max = "10000",
		Command = "wire_rfid_reader_beam_Range"
	})
	
	panel:AddControl("CheckBox", {
		Label = "#WireBeamReaderTool_NoColorChg",
		Command = "wire_rfid_reader_beam_NoColorChg"
	})
end

