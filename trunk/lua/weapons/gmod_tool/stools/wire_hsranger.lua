TOOL.Category		= "Wire Extras/Detection"
TOOL.Name			= "HighSpeed Ranger"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

if ( CLIENT ) then
    language.Add( "Tool.wire_hsranger.name", "Highspeed Ranger Tool (Wire)" )
    language.Add( "Tool.wire_hsranger.desc", "Spawns a highspeed ranger for use with the wire system." )
    language.Add( "Tool.wire_hsranger.0", "Primary: Create/Update Highspeed Ranger" )
	
	language.Add( "sboxlimit_wire_hsrangers", "You've hit highspeed rangers limit!" )
	language.Add( "undone_wirehsranger", "Undone Wire Highspeed Ranger" )
end

if (SERVER) then
	CreateConVar( 'sbox_maxwire_hsrangers', 2 )
end

TOOL.Model = "models/jaanus/wiretool/wiretool_range.mdl"

cleanup.Register( "wire_hsrangers" )

function TOOL:LeftClick( trace )
	if ( trace.Entity && trace.Entity:IsPlayer() ) then
		return false
	end
	
	if ( CLIENT ) then 
		return true
	end

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_hsranger" && trace.Entity.pl == ply ) then
		trace.Entity:Setup()
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_hsrangers" ) ) then
		return false
	end

	if ( not util.IsValidModel( self.Model ) ) then return false end
	if ( not util.IsValidProp( self.Model ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_ranger = MakeWireHSRanger( ply, Ang, trace.HitPos )

	local min = wire_ranger:OBBMins()
	wire_ranger:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld( wire_ranger, trace.Entity, trace.PhysicsBone, true )

	undo.Create( "WireHSRanger" )
		undo.AddEntity( wire_ranger )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_hsrangers", wire_ranger )

	return true
end

if (SERVER) then

	function MakeWireHSRanger( pl, Ang, Pos )
		if ( !pl:CheckLimit( "wire_hsrangers" ) ) then
			return false
		end
		
		local wire_ranger = ents.Create( "gmod_wire_hsranger" )
		if ( !wire_ranger:IsValid() ) then return false end
		
		wire_ranger:SetAngles( Ang )
		wire_ranger:SetPos( Pos )
		wire_ranger:SetModel( Model( "models/jaanus/wiretool/wiretool_range.mdl" ) )
		wire_ranger:Spawn()
		
		wire_ranger:Setup()
		wire_ranger:SetPlayer( pl )
		
		wire_ranger.pl = pl
		pl:AddCount( "wire_hsrangers", wire_ranger )		
		return wire_ranger
	end

	duplicator.RegisterEntityClass( "gmod_wire_hsranger", MakeWireHSRanger, "Ang", "Pos" )
end

function TOOL:UpdateGhostWireRanger( ent, player )
	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end

	local tr 	= util.GetPlayerTrace( player, player:GetAimVector() )
	local trace 	= util.TraceLine( tr )
	if (!trace.Hit) then return end

	if (trace.Entity && trace.Entity:GetClass() == "gmod_wire_hsranger" || trace.Entity:IsPlayer()) then
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

	self:UpdateGhostWireRanger( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool.wire_hsranger.name", Description = "#Tool.wire_hsranger.desc" })
end
