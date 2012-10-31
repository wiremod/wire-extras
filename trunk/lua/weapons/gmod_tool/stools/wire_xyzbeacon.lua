TOOL.Category		= "Wire - Beacon"
TOOL.Name			= "XYZ Beacon"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool.wire_xyzbeacon.name", "XYZ Beacon Tool (Wire)" )
    language.Add( "Tool.wire_xyzbeacon.desc", "Spawns a constant XYZ Beacon prop for use with the wire system." )
    language.Add( "Tool.wire_xyzbeacon.0", "Primary: Create/Update XYZ Beacon" )
    language.Add( "WireIXYZBeaconTool_ixyzbeacon", "XYZ Beacon:" )
	language.Add( "sboxlimit_wire_xyzbeacons", "You've hit XYZ Beacons limit!" )
	language.Add( "undone_wireigniter", "Undone Wire XYZ Beacon" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_xyzbeacons', 20)
end

TOOL.Model = "models/jaanus/wiretool/wiretool_range.mdl"

cleanup.Register( "wire_xyzbeacons" )

function TOOL:LeftClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_xyzbeacon" && trace.Entity:GetTable().pl == ply ) then
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_xyzbeacons" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_xyzbeacon = MakeWireXYZBeacon( ply, trace.HitPos, Ang )

	local min = wire_xyzbeacon:OBBMins()
	wire_xyzbeacon:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld(wire_xyzbeacon, trace.Entity, trace.PhysicsBone, true)

	undo.Create("Wire XYZ Beacon")
		undo.AddEntity( wire_xyzbeacon )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_xyzbeacons", wire_xyzbeacon )

	return true
end

if (SERVER) then

	function MakeWireXYZBeacon( pl, Pos, Ang )
		if ( !pl:CheckLimit( "wire_xyzbeacons" ) ) then return false end
	
		local wire_xyzbeacon = ents.Create( "gmod_wire_xyzbeacon" )
		if (!wire_xyzbeacon:IsValid()) then return false end

		wire_xyzbeacon:SetAngles( Ang )
		wire_xyzbeacon:SetPos( Pos )
		wire_xyzbeacon:SetModel( Model("models/jaanus/wiretool/wiretool_range.mdl") )
		wire_xyzbeacon:Spawn()

		wire_xyzbeacon:SetPlayer( pl )
		wire_xyzbeacon.pl = pl
		
		pl:AddCount( "wire_xyzbeacons", wire_xyzbeacon )

		return wire_xyzbeacon
	end
	
	duplicator.RegisterEntityClass("gmod_wire_xyzbeacon", MakeWireXYZBeacon, "Pos", "Ang", "Vel", "aVel", "frozen")

end

function TOOL:UpdateGhostWireXYZBeacon( ent, player )
	if ( !ent || !ent:IsValid() ) then return end

	local tr 	= util.GetPlayerTrace( player, player:GetAimVector() )
	local trace 	= util.TraceLine( tr )

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_xyzbeacon" ) then
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

	self:UpdateGhostWireXYZBeacon( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool.wire_xyzbeacon.name", Description = "#Tool.wire_xyzbeacon.desc" })

	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_xyzbeacon",

		Options = {
			Default = {
				wire_xyzbeacon_xyzbeacon = "0",
			}
		},
		CVars = {
		}
	})
end

