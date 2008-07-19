TOOL.Category		= "Wire - Data"
TOOL.Name			= "RAM-card"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_ramcard_name", "ramcard Tool (Wire)" )
    language.Add( "Tool_wire_ramcard_desc", "Create portable media for use with the wire system." )
    language.Add( "Tool_wire_ramcard_0", "Primary: Create/Update Spawner     Secondary: Create/Update Reader" )
    language.Add( "sboxlimit_wire_ramcardspawners", "You've hit ramcard spawner limit!" )
    language.Add( "sboxlimit_wire_ramcardreaders", "You've hit ramcard reader limit!" )
    language.Add( "undone_wireramcardspawner", "Undone Wire ramcard Spawner" )
    language.Add( "undone_Wire RamCardReader", "Undone Wire RAM-Card Reader" )

    language.Add( "WireramcardTool_GeneralOpt", "General Options" )
    language.Add( "WireramcardTool_LockCode", "Lock Code Modifier" )
    language.Add( "WireramcardTool_ReaderOpt", "Reader Options" )
    language.Add( "WireramcardTool_ReadMode", "Read Mode" )
    language.Add( "WireramcardTool_LCMode", "Lock Code Matching" )
    language.Add( "WireramcardTool_BeamLength", "Range" )

	CreateClientConVar("wire_ramcardtool_lockcode", "0", true, true)
	CreateClientConVar("wire_ramcardtool_beamlength", "100", true, true)
	CreateClientConVar("wire_ramcardtool_readmode", "0", true, true)
	CreateClientConVar("wire_ramcardtool_lcmode", "0", true, true)
end

if (SERVER) then
	CreateConVar('sbox_maxwire_ramcardspawners', 10)
	CreateConVar('sbox_maxwire_ramcardreaders', 10)
end

TOOL.Model = "models/keycardspawner/keycardspawner.mdl"
cleanup.Register( "wire_ramcardreaders" )

function TOOL:LeftClick( trace )

	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_ramcardreader" && trace.Entity:GetTable().ply == ply ) then
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_ramcardreaders" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
	
	local wire_ramcardreader = MakeWireRamCardReader( ply, trace.HitPos, Ang )

	local min = wire_ramcardreader:OBBMins()
	wire_ramcardreader:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld(wire_ramcardreader, trace.Entity, trace.PhysicsBone, true)

	undo.Create("Wire RamCardReader")
		undo.AddEntity( wire_ramcardreader )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_ramcardreaders", wire_ramcardreader )

	return true
end

function TOOL:RightClick( trace )
	return false
end

if (SERVER) then
	function MakeWireRamCardReader( ply, Pos, Ang )

		if ( !ply:CheckLimit( "wire_ramcardreaders" ) ) then return false end

		local wire_ramcardreader = ents.Create( "gmod_wire_ramcardreader" )
		if (!wire_ramcardreader:IsValid()) then return false end

		wire_ramcardreader:SetAngles( Ang )
		wire_ramcardreader:SetPos( Pos )
		wire_ramcardreader:Spawn()

		ply:AddCount( "wire_ramcardreaders", wire_ramcardreader )

		return wire_ramcardreader
	end
	
	duplicator.RegisterEntityClass("gmod_wire_ramcardreader", MakeWireRamCardReader, "Pos", "Ang", "Vel", "aVel", "frozen")
end

function TOOL:UpdateGhostWireRamCardSpawner( ent, player )
	if ( !ent || !ent:IsValid() ) then return end

	local tr = utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace = util.TraceLine( tr )

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_ramcardreader" ) then
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

	self:UpdateGhostWireRamCardSpawner( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "RAM-Card Reader/Writer", Description = "This Entity is the interface between your RAM-Card and a CPU, that want's to read from it" })
end
