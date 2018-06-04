TOOL.Category		= "Wire Extras/Physics/Force"
TOOL.Name			= "Wire Magnet"
TOOL.Command		= nil
TOOL.ConfigName		= nil
TOOL.Tab			= "Wire"

if ( CLIENT ) then
    language.Add( "Tool.wire_magnet.name", "Wired Magnet Tool" )
    language.Add( "Tool.wire_magnet.desc", "Spawns a realistic magnet for use with the wire system." )
    language.Add( "Tool.wire_magnet.0", "Primary: Create/Update Magnet Secondary: Grab model to use" )
    language.Add( "WiremagnetTool_len", "Effect Length:" )
    language.Add( "WiremagnetTool_stren", "Effect Strength:" )
    language.Add( "WiremagnetTool_propfil", "Prop Filter:" )
    language.Add( "WiremagnetTool_metal", "Attract Metal Only:" )
    language.Add( "WiremagnetTool_starton", "Start On:" )
	language.Add( "undone_wiremagnet", "Undone Wire Magnet" )
	language.Add( "sboxlimit_wire_magnet", "You've hit wired magnets limit!" )
end

if (SERVER) then
    CreateConVar('sbox_maxwire_magnets', 30)
    CreateConVar('sbox_wire_magnets_maxstrength', 10000)
    CreateConVar('sbox_wire_magnets_maxlen', 300)
    CreateConVar('sbox_wire_magnets_tickrate', 0.01)
end 

TOOL.ClientConVar[ "leng" ] = "100"
TOOL.ClientConVar[ "streng" ] = "2000"
TOOL.ClientConVar[ "propfilter" ] = ""
TOOL.ClientConVar[ "targetOnlyMetal" ] = 0
TOOL.ClientConVar[ "startOn" ] = 1
TOOL.ClientConVar[ "model" ] = "models/props_junk/PopCan01a.mdl"

cleanup.Register( "wire_magnets" )

function TOOL:LeftClick( trace )

	if ( trace.Entity && trace.Entity:IsPlayer() ) then return false end
	
	// If there's no physics object then we can't constraint it!
	if ( SERVER && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end
	
	if (CLIENT) then return true end
	
	local ply = self:GetOwner()
	
	local leng 		= tonumber(self:GetClientNumber( "leng" ))
	local strength	 	= tonumber(self:GetClientNumber("streng" ))
	local propfilter	 	= string.lower( self:GetClientInfo( "propfilter" ) )
	local targetmetal	 	= tonumber(self:GetClientNumber( "targetOnlyMetal" ))==1
	local starton	 	= tonumber(self:GetClientNumber( "startOn" ))==1
	

	//update
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_realmagnet") then
	
		
		trace.Entity:SetModel(self.ClientConVar[ "model" ]) 
		
		trace.Entity:SetLength(leng)
		trace.Entity:SetStrength(strength)
		trace.Entity:SetPropFilter(propfilter)
		trace.Entity:SetTargetOnlyMetal(targetmetal)
		trace.Entity:ShowOutput()
		
	
		return true
	
	end
	
	if ( !self:GetSWEP():CheckLimit( "wire_magnets" ) ) then return false end
		
	local wire_ball = MakeWireMagnet( ply, trace.HitPos, leng, strength, targetmetal, self.ClientConVar[ "model" ],propfilter)
	wire_ball:SetOn(util.tobool(starton))
	local const = WireLib.Weld(wire_ball, trace.Entity, trace.PhysicsBone, true)
	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
	wire_ball:SetAngles(Ang)
	
	local min = wire_ball:OBBMins()
	wire_ball:SetPos( trace.HitPos - trace.HitNormal * min.z )
	
	undo.Create("WireMagnet")
		undo.AddEntity( wire_ball )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()
	
	ply:AddCleanup( "wire_magnets", wire_ball )
	ply:AddCleanup( "wire_magnets", const )
	
	
	return true

end
function TOOL:RightClick(trace)
	if trace.Entity==nil or not trace.Entity:IsValid() then return false end
	if trace.Entity:IsWorld() then return false end
	self.ClientConVar[ "model" ]=trace.Entity:GetModel()
	return true
end
if (SERVER) then

	function MakeWireMagnet( ply, Pos, leng, strength, targetOnlyMetal,model,propfilter, starton )
	
		if ( !ply:CheckLimit( "wire_magnets" ) ) then return nil end
	
		local wire_ball = ents.Create( "gmod_wire_realmagnet" )
		if (!wire_ball:IsValid()) then return false end

		wire_ball:SetPos( Pos )
		
		wire_ball:PhysicsInit( SOLID_VPHYSICS )
		wire_ball:SetMoveType( MOVETYPE_VPHYSICS )
		wire_ball:SetSolid( SOLID_VPHYSICS )
		
		wire_ball:SetStrength( strength )
		wire_ball:SetLength( leng )
		wire_ball:SetTargetOnlyMetal( targetOnlyMetal )
		wire_ball:SetPropFilter( propfilter )
		wire_ball:SetPlayer( ply )
		wire_ball:SetModel(model)
		wire_ball:Spawn()
		wire_ball:SetOn(starton and tobool(starton))
		
		ply:AddCount( "wire_magnets", wire_ball )
		
		return wire_ball
		
	end
	
	duplicator.RegisterEntityClass("gmod_wire_realmagnet", MakeWireMagnet, "Pos", "Len", "Strength", "TargetOnlyMetal", "Model", "PropFilter", "On" )

end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool.wire_magnet.name", Description = "#Tool.wire_magnet.desc" })
	
	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_magnet",

		Options = {
			Default = {
				wire_magnet_len = "100",
				wire_magnet_strength = "2000",
				wire_magnet_starton = "1",
				wire_magnet_propfilter = ""
			}
		},

		CVars = {
			[0] = "wire_magnet_len",
			[1] = "wire_magnet_strength",
			[2] = "wire_magnet_starton",
			[3] = "wire_magnet_propfilter"
		}
	})

	panel:AddControl("Slider", {
		Label = "#WiremagnetTool_len",
		Type = "Float",
		Min = "1",
		Max = "100",
		Command = "wire_magnet_leng"
	})
	
	panel:AddControl("Slider", {
		Label = "#WiremagnetTool_stren",
		Type = "Float",
		Min = "1",
		Max = "2000",
		Command = "wire_magnet_streng"
	})
	
	
	panel:AddControl("CheckBox", {
		Label = "#WiremagnetTool_starton",
		Command = "wire_magnet_starton"
	})
	panel:AddControl("TextBox",{
		Label="#WiremagnetTool_propfil",
		MaxLen=500,
		Text="",
		command="wire_magnet_propfilter"
	})

end


function TOOL:UpdateGhostWireMagnet( ent, player )

	if ( !ent || !ent:IsValid() ) then return end
	
	local tr 	= util.GetPlayerTrace( player, player:GetAimVector() )
	local trace 	= util.TraceLine( tr )
	
	if (!trace.Hit || trace.Entity:IsPlayer() ) then 
		ent:SetNoDraw( true )
		return
	end
	if (trace.Entity:GetClass()=="gmod_wire_realmagnet") then
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
	
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || string.lower(self.GhostEntity:GetModel()) != string.lower(self.ClientConVar[ "model" ])) then
		
		local _model = self.ClientConVar[ "model" ]
		if (!_model) then return end
		
		self:MakeGhostEntity( _model, Vector(0,0,0), Angle(0,0,0) )
	end
	
	self:UpdateGhostWireMagnet( self.GhostEntity, self:GetOwner() )
	
end
