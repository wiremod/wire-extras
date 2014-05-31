TOOL.Category		= "Wire Extras/Detection"
TOOL.Name			= "Microphone"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

if ( CLIENT ) then
    language.Add( "Tool.wire_microphone.name", "Microphone Tool (Wire)" )
    language.Add( "Tool.wire_microphone.desc", "Spawns a microphone for use with the wire system." )
    language.Add( "Tool.wire_microphone.0", "Primary: Create/Update Microphone" )
    language.Add( "WireMicrophoneTool_microphone", "Microphone:" )
    language.Add( "WireMicrophoneTool_range", "Max Range:" )
    language.Add( "WireMicrophoneTool_sen", "Sensitivity:" )
    language.Add( "WireMicrophoneTool_on", "Starts On:" )
    language.Add( "WireMicrophoneTool_hearcombat", "Hears Combat:" )
    language.Add( "WireMicrophoneTool_hearplayer", "Hears Player:" )
    language.Add( "WireMicrophoneTool_hearworld" , "Hears World:" )
    language.Add( "WireMicrophoneTool_hearbullet", "Hears Bullet Impacts:" )
    language.Add( "WireMicrophoneTool_hearexplo" , "Hears Explosions:" )
	language.Add( "sboxlimit_wire_microphones", "You've hit microphones limit!" )
	language.Add( "undone_Wire Microphone", "Undone Wire Microphone" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_microphones', 20)
end

TOOL.ClientConVar[ "range" ] = 512
TOOL.ClientConVar[ "sen" ] = 1
TOOL.ClientConVar[ "on" ] = 1
TOOL.ClientConVar[ "hearcombat" ] = 1
TOOL.ClientConVar[ "hearplayer" ] = 1
TOOL.ClientConVar[ "hearworld" ] = 1
TOOL.ClientConVar[ "hearbullet" ] = 1
TOOL.ClientConVar[ "hearexplo" ] = 1

TOOL.Model = "models/jaanus/wiretool/wiretool_range.mdl"

cleanup.Register( "wire_microphones" )

function TOOL:LeftClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()

	local range = self:GetClientNumber("range")
	local sen = self:GetClientNumber("sen")
	local on = (self:GetClientNumber("on")~=0)
	local hearcombat = self:GetClientNumber("hearcombat")
	local hearplayer = self:GetClientNumber("hearplayer")
	local hearworld  = self:GetClientNumber("hearworld")
	local hearbullet = self:GetClientNumber("hearbullet")
	local hearexplo  = self:GetClientNumber("hearexplo")
	
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_microphone" && trace.Entity:GetTable().pl == ply ) then
		trace.Entity:Setup(range, sen, 2, hearcombat, hearplayer, hearworld, hearbullet, hearexplo)
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_microphones" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_microphone = MakeWireMicrophone( ply, trace.HitPos, range, sen, on, hearcombat, hearplayer, hearworld, hearbullet, hearexplo, Ang )

	local min = wire_microphone:OBBMins()
	wire_microphone:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld(wire_microphone, trace.Entity, trace.PhysicsBone, true)

	undo.Create("Wire Microphone")
		undo.AddEntity( wire_microphone )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_microphones", wire_microphone )

	return true
end

if (SERVER) then

	function MakeWireMicrophone( pl, Pos, range, sen, on, hearcombat, hearplayer, hearworld, hearbullet, hearexplo, Ang )
		if ( !pl:CheckLimit( "wire_microphones" ) ) then return false end
	
		local wire_microphone = ents.Create( "gmod_wire_microphone" )
		if (!wire_microphone:IsValid()) then return false end

		wire_microphone:SetAngles( Ang )
		wire_microphone:SetPos( Pos )
		wire_microphone:Spawn()
		wire_microphone:Setup(range, sen, on, hearcombat, hearplayer, hearworld, hearbullet, hearexplo)

		wire_microphone:SetPlayer( pl )

		local ttable = {
		    range = range,
			sen = sen,
			on = on,
		    hearcombat = hearcombat,
		    hearplayer = hearplayer,
		    hearworld  = hearworld,
		    hearbullet = hearbullet,
		    hearexplo  = hearexplo,
			pl = pl
		}
		table.Merge(wire_microphone:GetTable(), ttable )
		
		pl:AddCount( "wire_microphones", wire_microphone )

		return wire_microphone
	end
	
	duplicator.RegisterEntityClass("gmod_wire_microphone", MakeWireMicrophone, "Pos", "range", "sen", "on", "hearcombat", "hearplayer", "hearworld", "hearbullet", "hearexplo", "Ang", "Vel", "aVel", "frozen")

end

function TOOL:UpdateGhostWireMicrophone( ent, player )
	if ( !ent || !ent:IsValid() ) then return end

	local tr 	= util.GetPlayerTrace( player, player:GetAimVector() )
	local trace 	= util.TraceLine( tr )

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_microphone" ) then
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

	self:UpdateGhostWireMicrophone( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool.wire_microphone.name", Description = "#Tool.wire_microphone.desc" })

	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_microphone",

		Options = {
			Default = {
				wire_microphone_microphone = "0",
			}
		},
		CVars = {
		}
	})
	
	panel:AddControl("Slider", {
		Label = "#WireMicrophoneTool_range",
		Type = "Float",
		Min = "0",
		Max = "1024",
		Command = "wire_microphone_range"
	})
	
	panel:AddControl("Slider", {
		Label = "#WireMicrophoneTool_sen",
		Type = "Float",
		Min = "0",
		Max = "10",
		Command = "wire_microphone_sen"
	})
	
	panel:AddControl("CheckBox", {
		Label = "#WireMicrophoneTool_on",
		Command = "wire_microphone_on"
	})
	
	panel:AddControl("CheckBox", {
		Label = "#WireMicrophoneTool_hearcombat",
		Command = "wire_microphone_hearcombat"
	})
	panel:AddControl("CheckBox", {
		Label = "#WireMicrophoneTool_hearplayer",
		Command = "wire_microphone_hearplayer"
	})
	panel:AddControl("CheckBox", {
		Label = "#WireMicrophoneTool_hearworld",
		Command = "wire_microphone_hearworld"
	})
	panel:AddControl("CheckBox", {
		Label = "#WireMicrophoneTool_hearbullet",
		Command = "wire_microphone_hearbullet"
	})
	panel:AddControl("CheckBox", {
		Label = "#WireMicrophoneTool_hearexplo",
		Command = "wire_microphone_hearexplo"
	})
end

