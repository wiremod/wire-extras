TOOL.Category   = "Wire Extras/Physics"
TOOL.Name       = "Adv. Dupe. Teleporter"
TOOL.Command    = nil
TOOL.ConfigName = ""
TOOL.Tab        = "Wire"

local gsModel = "models/jaanus/wiretool/wiretool_speed.mdl"

if ( CLIENT ) then
	language.Add( "Tool.wire_dupeport.name", "Adv. Dupe. Teleporter Tool (Wire)" )
	language.Add( "Tool.wire_dupeport.desc", "Spawns an Adv. Dupe. Teleporter for use with the wire system." )
	language.Add( "Tool.wire_dupeport.0", "Primary: Create/Update Adv. Dupe. Teleporter" )
	language.Add( "sboxlimit_wire_dupeports", "You've hit Adv. Dupe. Teleporters limit!" )
	language.Add( "undone_wiredupeport", "Undone Wire Adv. Dupe. Teleporter" )
end

if ( SERVER ) then
	CreateConVar( "sbox_maxwire_dupeports", 10 )
end

cleanup.Register( "wire_dupeports" )

function TOOL:LeftClick( trace )
	if trace.Entity && trace.Entity:IsPlayer() then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()

	-- If we shot a wire_dupeport do nothing
	if ( trace.Entity:IsValid() &&
			 trace.Entity.pl == ply &&
			 trace.Entity:GetClass() == "gmod_wire_dupeport" ) then
			 trace.Entity:Setup()
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_dupeports" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_dupeport = MakeWireDupePort( ply, Ang, trace.HitPos )
	if ( !wire_dupeport ) then return false end
	if ( !wire_dupeport:IsValid() ) then return false end

	local min = wire_dupeport:OBBMins()
	wire_dupeport:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local weld = WireLib.Weld(wire_dupeport, trace.Entity, trace.PhysicsBone, true)

	undo.Create( "WireDupePort" )
		undo.AddEntity( wire_dupeport )
		undo.AddEntity( weld )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_dupeports", wire_dupeport )

	return true
end

if ( SERVER ) then

	function MakeWireDupePort( ply, Ang, Pos)
		if ( ply:IsAdmin() || ply:IsSuperAdmin() ) then

			if ( !ply:CheckLimit( "wire_dupeports" ) ) then return false end

			local wire_dupeport = ents.Create( "gmod_wire_dupeport" )
			if ( !wire_dupeport:IsValid() ) then return false end

			wire_dupeport:SetModel( Model( gsModel ) )
			wire_dupeport:SetBeamLength( 100 )
			wire_dupeport:SetAngles( Ang )
			wire_dupeport:SetPos( Pos )
			wire_dupeport:SetOverlayText( "Adv. Dupe.Teleporter" )
			wire_dupeport:Spawn()

			wire_dupeport:SetPlayer(ply)

			if ( game.SinglePlayer() ) then
				wire_dupeport.OwnerSteamID = ply
				wire_dupeport.SpawnSteamID = ply
			else
				wire_dupeport.OwnerSteamID = ply:SteamID()
				wire_dupeport.SpawnSteamID = ply:SteamID()
			end

			ply:AddCount( "wire_dupeports", wire_dupeport )

			return wire_dupeport
		else
			ply:SendLua( "GAMEMODE:AddNotify(\"A non-admin cannot spawn a Adv. Dupe Teleporter!\", NOTIFY_GENERIC, 5); surface.PlaySound(\"ambient/water/drip"..math.random(1, 4)..".wav\")" )
			return nil
		end
	end

	duplicator.RegisterEntityClass( "gmod_wire_dupeport", MakeWireDupePort, "Ang", "Pos" )

end

function TOOL:UpdateGhostWireDupePort( ent, player )
	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end

	local trace = player:GetEyeTrace()
	if ( !trace.Hit ) then return end

	if ( trace.Entity &&
		   trace.Entity:IsValid() &&
		 ( trace.Entity:GetClass() == "gmod_wire_dupeport" ||
		 	 trace.Entity:IsPlayer() ) ) then
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
	if ( !self.GhostEntity ||
			 !self.GhostEntity:IsValid() ||
			  self.GhostEntity:GetModel() ~= gsModel ) then
		self:MakeGhostEntity( gsModel, Vector(0,0,0), Angle(0,0,0) )
	end

	self:UpdateGhostWireDupePort( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool.wire_dupeport.name", Description = "#Tool.wire_dupeport.desc" })
end
