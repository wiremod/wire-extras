TOOL.Category		= "Wire Extras/Input, Output"
TOOL.Name			= "Keycard"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

if ( CLIENT ) then
    language.Add( "Tool.wire_keycard.name", "Keycard Tool (Wire)" )
    language.Add( "Tool.wire_keycard.desc", "Create portable media for use with the wire system." )
    language.Add( "Tool.wire_keycard.0", "Primary: Create/Update Spawner     Secondary: Create/Update Reader" )
    language.Add( "sboxlimit_wire_keycardspawners", "You've hit keycard spawner limit!" )
    language.Add( "sboxlimit_wire_keycardreaders", "You've hit keycard reader limit!" )
    language.Add( "undone_wirekeycardspawner", "Undone Wire Keycard Spawner" )
    language.Add( "undone_wirekeycardreader", "Undone Wire Keycard Reader" )

    language.Add( "WireKeycardTool_GeneralOpt", "General Options" )
    language.Add( "WireKeycardTool_LockCode", "Lock Code Modifier" )
    language.Add( "WireKeycardTool_ReaderOpt", "Reader Options" )
    language.Add( "WireKeycardTool_ReadMode", "Read Mode" )
    language.Add( "WireKeycardTool_LCMode", "Lock Code Matching" )
    language.Add( "WireKeycardTool_BeamLength", "Range" )

	CreateClientConVar("wire_keycardtool_lockcode", "0", true, true)
	CreateClientConVar("wire_keycardtool_beamlength", "100", true, true)
	CreateClientConVar("wire_keycardtool_readmode", "0", true, true)
	CreateClientConVar("wire_keycardtool_lcmode", "0", true, true)
end

if (SERVER) then
	CreateConVar('sbox_maxwire_keycardspawners', 10)
	CreateConVar('sbox_maxwire_keycardreaders', 10)
end

// TOOL.ClientConVar[ "z_only" ] = "1"

TOOL.Model = "models/keycardspawner/keycardspawner.mdl"
cleanup.Register( "wire_keycardspawners" )
cleanup.Register( "wire_keycardreaders" )

function TOOL:LeftClick( trace )

	if trace.Entity && trace.Entity:IsPlayer() then return false end

	// If there's no physics object then we can't constraint it!
	if ( SERVER && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end

	if (CLIENT) then return true end

	local ply = self:GetOwner()

	// local z_only = (self:GetClientNumber("z_only") ~= 0)

	// If we shot a wire_keycardspawner or wire_keycardreader do nothing
	if ( trace.Entity:IsValid() && trace.Entity.pl == ply ) then
		if (trace.Entity:GetClass() == "gmod_wire_keycardspawner") then
			// trace.Entity:Setup(z_only)
			// trace.Entity.z_only = z_only
			return true
		elseif (trace.Entity:GetClass() == "gmod_wire_keycardreader") then
			// Handle card reader stuff on right-click.
			return true
		end
	end

	if ( !self:GetSWEP():CheckLimit( "wire_keycardspawners" ) ) then return false end

	if (not util.IsValidModel(self.Model)) then return false end
	if (not util.IsValidProp(self.Model)) then return false end		// Allow ragdolls to be used?

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	wire_keycardspawner = MakeWireKeycardSpawner( ply, Ang, trace.HitPos ) // TODO: pass configs as parameters to this fn (eg. z_only)

	local min = wire_keycardspawner:OBBMins()
	wire_keycardspawner:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld(wire_keycardspawner, trace.Entity, trace.PhysicsBone, true)

	undo.Create("WireKeycardSpawner")
		undo.AddEntity( wire_keycardspawner )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_keycardspawner", wire_keycardspawner )
	ply:AddCleanup( "wire_keycardspawner", const )

	return true

end

function TOOL:RightClick( trace )

	if trace.Entity && trace.Entity:IsPlayer() then return false end

	// If there's no physics object then we can't constraint it!
	if ( SERVER && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end

	if (CLIENT) then return true end

	local ply = self:GetOwner()

	// local z_only = (self:GetClientNumber("z_only") ~= 0)

	// If we shot a wire_keycardspawner or wire_keycardreader do nothing
	if ( trace.Entity:IsValid() && trace.Entity.pl == ply ) then
		if (trace.Entity:GetClass() == "gmod_wire_keycardspawner") then
			// Handle card spawner stuff on right-click.
			return true
		elseif (trace.Entity:GetClass() == "gmod_wire_keycardreader") then
			// trace.Entity:Setup(z_only)
			// trace.Entity.z_only = z_only
			return true
		end
	end

	if ( !self:GetSWEP():CheckLimit( "wire_keycardreaders" ) ) then return false end

	if (not util.IsValidModel(self.Model)) then return false end
	if (not util.IsValidProp(self.Model)) then return false end		// Allow ragdolls to be used?

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	wire_keycardreader = MakeWireKeycardReader( ply, Ang, trace.HitPos ) // TODO: pass configs as parameters to this fn (eg. z_only)

	local min = wire_keycardreader:OBBMins()
	wire_keycardreader:SetPos( trace.HitPos - trace.HitNormal * min.z )
	wire_keycardreader:SetRange(math.Max(0, ply:GetInfoNum("wire_keycardtool_beamlength", 100)))
	wire_keycardreader:SetReadMode(ply:GetInfoNum("wire_keycardtool_readmode", 0))

	wire_keycardreader:SetLCMatchMode(ply:GetInfoNum("wire_keycardtool_lcmode", 0))


	local const = WireLib.Weld(wire_keycardreader, trace.Entity, trace.PhysicsBone, true)

	undo.Create("WireKeycardReader")
		undo.AddEntity( wire_keycardreader )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_keycardreader", wire_keycardreader )
	ply:AddCleanup( "wire_keycardreader", const )

	return true

end

if (SERVER) then

	function MakeWireKeycardSpawner( pl, Ang, Pos )

		if ( !pl:CheckLimit( "wire_keycardspawners" ) ) then return false end

		local wire_keycardspawner = ents.Create( "gmod_wire_keycardspawner" )
		if (!wire_keycardspawner:IsValid()) then return false end

		wire_keycardspawner:SetAngles( Ang )
		wire_keycardspawner:SetPos( Pos )
		wire_keycardspawner:SetModel( Model("models/keycardspawner/keycardspawner.mdl") )
		wire_keycardspawner:SetLockCode((pl:UserID() + 1) * 100 + math.Clamp(math.Round(pl:GetInfoNum("wire_keycardtool_lockcode", 0)), 0, 99))
		wire_keycardspawner:Spawn()

		pl:AddCount( "wire_keycardspawners", wire_keycardspawner )

		return wire_keycardspawner

	end

	function MakeWireKeycardReader( pl, Ang, Pos )

		if ( !pl:CheckLimit( "wire_keycardreaders" ) ) then return false end

		local wire_keycardreader = ents.Create( "gmod_wire_keycardreader" )
		if (!wire_keycardreader:IsValid()) then return false end

		wire_keycardreader:SetAngles( Ang )
		wire_keycardreader:SetPos( Pos )
		wire_keycardreader:SetModel( Model("models/jaanus/wiretool/wiretool_range.mdl") )
		wire_keycardreader:SetLockCode((pl:UserID() + 1) * 100 + math.Clamp(math.Round(pl:GetInfoNum("wire_keycardtool_lockcode", 0)), 0, 99))
		wire_keycardreader:SetRange(math.Max(0, pl:GetInfoNum("wire_keycardtool_beamlength", 100)))
		wire_keycardreader:SetReadMode(pl:GetInfoNum("wire_keycardtool_readmode", 0))
		wire_keycardreader:SetLCMatchMode(pl:GetInfoNum("wire_keycardtool_lcmode", 0))
		wire_keycardreader:Spawn()

		pl:AddCount( "wire_keycardreaders", wire_keycardreader )

		return wire_keycardreader

	end

        // TODO: Examine this. Keycards need to be Duplicator compatible.
	// duplicator.RegisterEntityClass("gmod_wire_keycardspawner", MakeWireKeycardSpawner, "Ang", "Pos", "z_only", "nocollide", "Vel", "aVel", "frozen")
	// duplicator.RegisterEntityClass("gmod_wire_keycardreader", MakeWireKeycardReader, "Ang", "Pos", "z_only", "nocollide", "Vel", "aVel", "frozen")

end

function TOOL:UpdateGhostWireKeycardSpawner( ent, player )

	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end

	local tr 	= util.GetPlayerTrace( player, player:GetAimVector() )
	local trace 	= util.TraceLine( tr )
	if (!trace.Hit) then return end

	if (trace.Entity && trace.Entity:GetClass() == "gmod_wire_keycardspawner" || trace.Entity:IsPlayer()) then

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

	self:UpdateGhostWireKeycardSpawner( self.GhostEntity, self:GetOwner() )

end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool.wire_keycard.name", Description = "#Tool.wire_keycard.desc" })
	panel:AddControl("Header", { Text = "#WireKeycardTool_GeneralOpt" } )
	panel:AddControl("Slider", { Label = "#WireKeycardTool_LockCode", Description = "", Type = "Integer", Min = "0", Max = "99", Command = "wire_keycardtool_lockcode"})
	panel:AddControl("Header", { Text = "#WireKeycardTool_ReaderOpt" } )

        local combobox = {}
        combobox.Label = "#WireKeycardTool_ReadMode"
        combobox.MenuButton = 0
        combobox.Options = {}
        combobox.Options["Read with a beam"] = {wire_keycardtool_readmode = 0}
        combobox.Options["Read nearest keycard"] = {wire_keycardtool_readmode = 1}
        panel:AddControl("ComboBox", combobox)

        local combobox = {}
        combobox.Label = "#WireKeycardTool_LCMode"
        combobox.MenuButton = 0
        combobox.Options = {}
        combobox.Options["Inclusive (read even if lock code is different)"] = {wire_keycardtool_lcmode = 0}
        combobox.Options["Exclusive (ignore if lock code is different)"] = {wire_keycardtool_lcmode = 1}
        panel:AddControl("ComboBox", combobox)

	panel:AddControl("Slider", { Label = "#WireKeycardTool_BeamLength", Description = "", Type = "Float", Min = "1", Max = "1000", Command = "wire_keycardtool_beamlength"})
end
