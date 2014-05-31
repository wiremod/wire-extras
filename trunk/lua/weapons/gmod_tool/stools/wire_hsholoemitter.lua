TOOL.Category		= "Wire Extras/Visuals/Holographic"
TOOL.Name			= "HighSpeed Holoemitter"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

if ( CLIENT ) then
    language.Add( "Tool.wire_hsholoemitter.name", "Highspeed Holoemitter Tool (Wire)" )
    language.Add( "Tool.wire_hsholoemitter.desc", "Spawns a highspeed holoemitter for use with the wire system." )
    language.Add( "Tool.wire_hsholoemitter.0", "Primary: Create/Update Highspeed Holoemitter" )
	
	language.Add( "sboxlimit_wire_hsholoemitters", "You've hit highspeed holoemitters limit!" )
	language.Add( "undone_wirehsholoemitter", "Undone Wire Highspeed Holoemitter" )
end

if (SERVER) then
	CreateConVar( 'sbox_maxwire_hsholoemitters', 1 )
end
   
CreateConVar( 'hsholoemitter_max_points', 681 , FCVAR_REPLICATED )

TOOL.ClientConVar[ "a" ] = "255"
TOOL.ClientConVar[ "b" ] = "255"
TOOL.ClientConVar[ "g" ] = "255"
TOOL.ClientConVar[ "r" ] = "255"

TOOL.Model = "models/jaanus/wiretool/wiretool_range.mdl"

cleanup.Register( "wire_hsholoemitters" )

function TOOL:LeftClick( trace )
	if ( trace.Entity && trace.Entity:IsPlayer() ) then
		return false
	end
	
	if ( CLIENT ) then 
		return true
	end

	local ply = self:GetOwner()
	local r = self:GetClientNumber("r")
	local g = self:GetClientNumber("g")
	local b = self:GetClientNumber("b")
	local a = self:GetClientNumber("a")
	
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_hsholoemitter" && trace.Entity.pl == ply ) then
		trace.Entity:Setup()
		trace.Entity:SetColor( Color(r, g, b, a) );
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_hsholoemitters" ) ) then
		return false
	end

	if ( not util.IsValidModel( self.Model ) ) then return false end
	if ( not util.IsValidProp( self.Model ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_emitter = MakeWireHSHoloemitter( ply, trace.HitPos, Ang, r, g, b, a, 0)

	local min = wire_emitter:OBBMins()
	wire_emitter:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld( wire_emitter, trace.Entity, trace.PhysicsBone, true )

	undo.Create( "WireHSHoloemitter" )
		undo.AddEntity( wire_emitter )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_hsholoemitters", wire_emitter )

	return true
end

if ( SERVER ) then
	function MakeWireHSHoloemitter( pl, pos, ang, r, g, b, a, frozen )
		// check the players limit
		if( !pl:CheckLimit( "wire_hsholoemitters" ) ) then return; end
		
		// create the emitter
		local emitter = ents.Create( "gmod_wire_hsholoemitter" );
		emitter:SetPos( pos );
		emitter:SetAngles( ang );
		emitter:Setup();
		emitter:Spawn();
		emitter:Activate();
		
		if emitter:GetPhysicsObject():IsValid() then
			local Phys = emitter:GetPhysicsObject()
			Phys:EnableMotion(!frozen)
		end

		// setup the emitter.
		emitter:SetColor( Color(r, g, b, a) );
		emitter:SetPlayer( pl );
		
		// store the color on the table.
		local tbl = {
			r = r,
			g = g,
			b = b,
			a = a,
		};
		table.Merge( emitter:GetTable(), tbl );
		
		// add to the players count
		pl:AddCount( "wire_hsholoemitters", emitter );
		
		//
		return emitter;
	end
	
	duplicator.RegisterEntityClass("gmod_wire_hsholoemitter",MakeWireHSHoloemitter,"Pos","Ang","r", "g", "b", "a","frozen");
end

function TOOL:UpdateGhostWireHSHoloemitter( ent, player )
	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end

	local tr 	= util.GetPlayerTrace( player, player:GetAimVector() )
	local trace 	= util.TraceLine( tr )
	if (!trace.Hit) then return end

	if (trace.Entity && trace.Entity:GetClass() == "gmod_wire_hsholoemitter" || trace.Entity:IsPlayer()) then
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

	self:UpdateGhostWireHSHoloemitter( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool.wire_hsholoemitter.name", Description = "#Tool.wire_hsholoemitter.desc" })
	panel:AddControl( "Color", {
		Label 	= "Color",
		Red 	= "wire_hsholoemitter_r",
		Green 	= "wire_hsholoemitter_g",
		Blue 	= "wire_hsholoemitter_b",
		Alpha 	= "wire_hsholoemitter_a",
		ShowAlpha	= "1",
		ShowHSV		= "1",
		ShowRGB		= "1",
		Multiplier	= "255",
	})
end
