
TOOL.Category		= "Wire - I/O"
TOOL.Name			= "Notifier"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_notifier_name", "Notifier Tool (Wire)" )
    language.Add( "Tool_wire_notifier_desc", "Spawns a Notifier for use with the wire system." )
    language.Add( "Tool_wire_notifier_0", "Primary: Create/Update Notifier" )
	language.Add( "sboxlimit_wire_notifiers", "You've hit notifiers limit!" )
	language.Add( "undone_wirenotifier", "Undone Wire Notifier" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_notifiers', 3)
end

for i = 1,24 do
TOOL.ClientConVar["text"..i] = ""
end

TOOL.Model = "models/jaanus/wiretool/wiretool_range.mdl"

cleanup.Register( "wire_notifiers" )

function TOOL:LeftClick( trace )
	if trace.Entity && trace.Entity:IsPlayer() then return false end

	// If there's no physics object then we can't constraint it!
	if ( SERVER && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end

	if (CLIENT) then return true end

	local ply = self:GetOwner()

	local lines = {}
	for i = 1,24 do
		if (self:GetClientInfo("text"..i) != "") then
			table.insert(lines,self:GetClientInfo("text"..i))
		end
	end

	// If we shot a wire_notifier change its range
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_notifier" && trace.Entity.pl == ply ) then

		trace.Entity:Setup( lines )
		
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_notifiers" ) ) then return false end

	if (not util.IsValidModel(self.Model)) then return false end
	if (not util.IsValidProp(self.Model)) then return false end		// Allow ragdolls to be used?

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	wire_notifier = MakeWireNotifier( ply, Ang, trace.HitPos, lines)

	local min = wire_notifier:OBBMins()
	wire_notifier:SetPos( trace.HitPos - trace.HitNormal * min.z )

	/*local const, nocollide

	// Don't weld to world
	if ( trace.Entity:IsValid() ) then
		const = constraint.Weld( wire_notifier, trace.Entity, 0, trace.PhysicsBone, 0, true, true )
		// Don't disable collision if it's not attached to anything
		wire_notifier:GetPhysicsObject():EnableCollisions( false )
		wire_notifier.nocollide = true
	end*/
	local const = WireLib.Weld(wire_notifier, trace.Entity, trace.PhysicsBone, true)

	undo.Create("WireNotifier")
		undo.AddEntity( wire_notifier )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_notifiers", wire_notifier )
	ply:AddCleanup( "wire_notifiers", const )
	ply:AddCleanup( "wire_notifiers", nocollide )

	return true
end

if (SERVER) then

	function MakeWireNotifier( pl, Ang, Pos, lines )
		if ( !pl:CheckLimit( "wire_notifiers" ) ) then return false end

		local wire_notifier = ents.Create( "gmod_wire_notifier" )
		if (!wire_notifier:IsValid()) then return false end

		wire_notifier:SetAngles( Ang )
		wire_notifier:SetPos( Pos )
		wire_notifier:SetModel( Model("models/jaanus/wiretool/wiretool_range.mdl") )
		wire_notifier:Spawn()
		
		local ttable = {pl = pl,}

		table.Merge(wire_notifier:GetTable(), ttable )

		wire_notifier:Setup( lines )
		wire_notifier:SetPlayer( pl )

		if ( nocollide == true ) then wire_notifier:GetPhysicsObject():EnableCollisions( false ) end

		pl:AddCount( "wire_notifiers", wire_notifier )

		return wire_notifier
	end

	duplicator.RegisterEntityClass("gmod_wire_notifier", MakeWireNotifier, "Ang", "Pos", "Lines")

end

function TOOL:UpdateGhostWirenotifier( ent, player )
	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )
	if (!trace.Hit) then return end

	if (trace.Entity && trace.Entity:GetClass() == "gmod_wire_notifier" || trace.Entity:IsPlayer()) then

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

	self:UpdateGhostWirenotifier( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_notifier_name", Description = "#Tool_wire_notifier_desc" })

	for i = 1,24 do
		panel:AddControl("TextBox", {Label = "Text "..i..":", MaxLength = tostring(80), Command = "wire_notifier_text"..i})
	end	
	
end
