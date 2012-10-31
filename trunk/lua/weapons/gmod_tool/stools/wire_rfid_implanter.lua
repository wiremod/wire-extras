
TOOL.Category		= "Wire - RFID"
TOOL.Name			= "Implanter"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_rfid_implanter_name", "RFID Implanter Tool (Wire)" )
    language.Add( "Tool_wire_rfid_implanter_desc", "Spawns a RFID implanter prop for use with the wire system." )
    language.Add( "Tool_wire_rfid_implanter_0", "Primary: Create/Update Implanter" )
    language.Add( "WireImplanterTool_implanter", "RFID Implanter:" )
    language.Add( "WireImplanterTool_Range", "Max Range:" )
    language.Add( "WireImplanterTool_NoColorChg", "Don't change colour on state changed" )
	language.Add( "sboxlimit_wire_rfid_implanters", "You've hit implanters limit!" )
	language.Add( "undone_Wire Implanter", "Undone Wire Implanter" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_rfid_implanters', 20)
	CreateConVar('sbox_wire_rfid_implanters_maxlen', 30)
end

TOOL.ClientConVar[ "Range" ] = 2048
TOOL.ClientConVar[ "NoColorChg" ] = 0

TOOL.Model = "models/jaanus/wiretool/wiretool_beamcaster.mdl"

cleanup.Register( "wire_rfid_implanters" )

function TOOL:LeftClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()

	local Range = self:GetClientNumber("Range")
	local NoColorChg = (self:GetClientNumber("NoColorChg")!=0)
	
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_rfid_implanter" && trace.Entity:GetTable().pl == ply ) then
		trace.Entity:Setup( Range, NoColorChg )
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_rfid_implanters" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_rfid_implanter = MakeWireImplanter( ply, trace.HitPos, Range, NoColorChg, Ang )

	local min = wire_rfid_implanter:OBBMins()
	wire_rfid_implanter:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld(wire_rfid_implanter, trace.Entity, trace.PhysicsBone, true)

	undo.Create("Wire Implanter")
		undo.AddEntity( wire_rfid_implanter )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()


	ply:AddCleanup( "wire_rfid_implanters", wire_rfid_implanter )

	return true
end

function TOOL:RightClick( trace )
	return false
end

if (SERVER) then

	function MakeWireImplanter( pl, Pos, Range, NoColorChg, Ang )
		if ( !pl:CheckLimit( "wire_rfid_implanters" ) ) then return false end
	
		local wire_rfid_implanter = ents.Create( "gmod_wire_rfid_implanter" )
		if (!wire_rfid_implanter:IsValid()) then return false end

		wire_rfid_implanter:SetAngles( Ang )
		wire_rfid_implanter:SetPos( Pos )
		wire_rfid_implanter:SetModel( Model("models/jaanus/wiretool/wiretool_beamcaster.mdl") )
		wire_rfid_implanter:Spawn()
		wire_rfid_implanter:Setup(Range,NoColorChg)

		wire_rfid_implanter:SetPlayer( pl )

		local ttable = {
		    Range = Range,
		    NoColorChg = NoColorChg,
			pl = pl
		}

		table.Merge(wire_rfid_implanter:GetTable(), ttable )
		
		pl:AddCount( "wire_rfid_implanters", wire_rfid_implanter )

		return wire_rfid_implanter
	end
	
	duplicator.RegisterEntityClass("gmod_wire_rfid_implanter", MakeWireImplanter, "Pos", "Range", "NoColorChg", "Ang", "Vel", "aVel", "frozen")

end

function TOOL:UpdateGhostWireImplanter( ent, player )
	if ( !ent || !ent:IsValid() ) then return end

	local tr 	= util.GetPlayerTrace( player, player:GetAimVector() )
	local trace 	= util.TraceLine( tr )

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_rfid_implanter" ) then
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

	self:UpdateGhostWireImplanter( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_rfid_implanter_name", Description = "#Tool_wire_rfid_implanter_desc" })

	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_rfid_implanter",

		Options = {
			Default = {
				wire_rfid_implanter_implanter = "0",
			}
		},
		CVars = {
		}
	})
	
	panel:AddControl("Slider", {
		Label = "#WireImplanterTool_Range",
		Type = "Float",
		Min = "1",
		Max = "10000",
		Command = "wire_rfid_implanter_Range"
	})
	
	panel:AddControl("CheckBox", {
		Label = "#WireImplanterTool_NoColorChg",
		Command = "wire_rfid_implanter_NoColorChg"
	})
end

