
TOOL.Category		= "Wire - RFID"
TOOL.Name			= "Reader"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_rfid_reader_prox_name", "RFID Reader Tool (Wire)" )
    language.Add( "Tool_wire_rfid_reader_prox_desc", "Spawns a RFID reader for use with the wire system." )
    language.Add( "Tool_wire_rfid_reader_prox_0", "Primary: Create/Update Proximity Reader" )
    language.Add( "WireReaderTool_reader_prox", "RFID Reader:" )
    language.Add( "WireReaderTool_Range", "Max Range:" )
    language.Add( "WireReaderTool_NoColorChg", "Don't change colour on state changed" )
	language.Add( "sboxlimit_wire_rfid_reader_proxs", "You've hit readers limit!" )
	language.Add( "undone_Wire Reader", "Undone Wire Reader" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_rfid_reader_proxs', 20)
	CreateConVar('sbox_wire_rfid_reader_proxs_maxlen', 30)
end

TOOL.ClientConVar[ "Range" ] = 100
TOOL.ClientConVar[ "NoColorChg" ] = 0

TOOL.Model = "models/jaanus/wiretool/wiretool_input.mdl"

cleanup.Register( "wire_rfid_reader_proxs" )

function TOOL:LeftClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()

	local Range = self:GetClientNumber("Range")
	local NoColorChg = (self:GetClientNumber("NoColorChg")!=0)
	
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_rfid_reader_prox" && trace.Entity:GetTable().pl == ply ) then
		trace.Entity:Setup( Range, NoColorChg )
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_rfid_reader_proxs" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
	

	local wire_rfid_reader_prox = MakeWireReader( ply, trace.HitPos, Range, NoColorChg, Ang )

	local min = wire_rfid_reader_prox:OBBMins()
	wire_rfid_reader_prox:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld(wire_rfid_reader_prox, trace.Entity, trace.PhysicsBone, true)

	undo.Create("Wire Reader")
		undo.AddEntity( wire_rfid_reader_prox )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()


	ply:AddCleanup( "wire_rfid_reader_proxs", wire_rfid_reader_prox )

	return true
end

function TOOL:RightClick( trace )
	return false
end

if (SERVER) then

	function MakeWireReader( pl, Pos, Range, NoColorChg, Ang )
		if ( !pl:CheckLimit( "wire_rfid_reader_proxs" ) ) then return false end
	
		local wire_rfid_reader_prox = ents.Create( "gmod_wire_rfid_reader_prox" )
		if (!wire_rfid_reader_prox:IsValid()) then return false end

		wire_rfid_reader_prox:SetAngles( Ang )
		wire_rfid_reader_prox:SetPos( Pos )
		wire_rfid_reader_prox:SetModel( Model("models/jaanus/wiretool/wiretool_input.mdl") )
		wire_rfid_reader_prox:Spawn()
		wire_rfid_reader_prox:Setup(Range,NoColorChg)

		wire_rfid_reader_prox:SetPlayer( pl )

		local ttable = {
		    Range = Range,
			NoColorChg = NoColorChg,
			pl = pl
		}

		table.Merge(wire_rfid_reader_prox:GetTable(), ttable )
		
		pl:AddCount( "wire_rfid_reader_proxs", wire_rfid_reader_prox )

		return wire_rfid_reader_prox
	end
	
	duplicator.RegisterEntityClass("gmod_wire_rfid_reader_prox", MakeWireReader, "Pos", "Range", "NoColorChg", "Ang", "Vel", "aVel", "frozen")

end

function TOOL:UpdateGhostWireReader( ent, player )
	if ( !ent || !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_rfid_reader_prox" ) then
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

	self:UpdateGhostWireReader( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_rfid_reader_prox_name", Description = "#Tool_wire_rfid_reader_prox_desc" })

	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_rfid_reader_prox",

		Options = {
			Default = {
				wire_rfid_reader_prox_reader_prox = "0",
			}
		},
		CVars = {
		}
	})
	
	panel:AddControl("Slider", {
		Label = "#WireReaderTool_Range",
		Type = "Float",
		Min = "1",
		Max = "10000",
		Command = "wire_rfid_reader_prox_Range"
	})
	
	
	panel:AddControl("CheckBox", {
		Label = "#WireReaderTool_NoColorChg",
		Command = "wire_rfid_reader_prox_NoColorChg"
	})
end

