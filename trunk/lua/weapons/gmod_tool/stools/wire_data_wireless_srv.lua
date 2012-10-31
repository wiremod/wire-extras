TOOL.Category		= "Wire - Wireless"
TOOL.Name			= "Wireless Hub"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_data_Wireless_srv_name", "Wireless Hub Tool (Wire)" )
    language.Add( "Tool_wire_data_Wireless_srv_desc", "Spawns a Wireless Hub." )
    language.Add( "Tool_wire_data_Wireless_srv_0", "Primary: Create Wireless Hub" )
    language.Add( "WireDataTransfererTool_data_btsrv", "Wireless Hub:" )
	language.Add( "sboxlimit_wire_data_Wireless_srv", "You've hit Wireless Hub limit!" )
	language.Add( "Undone_Wire_BTSRV", "Undone Wire Wireless Hub" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_data_Wireless_srv', 20)
end

TOOL.ClientConVar["Model"] = "models/hammy/pci_card.mdl"

TOOL.FirstSelected = nil

cleanup.Register( "wire_data_Wireless_srv" )

function TOOL:LeftClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_data_Wireless_srv" && trace.Entity:GetTable().pl == ply ) then
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_data_Wireless_srv" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_data_Wireless_srv = MakeWirebtsrv( ply, trace.HitPos, Ang , self:GetClientInfo("Model"))

	local min = wire_data_Wireless_srv:OBBMins()
	wire_data_Wireless_srv:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld(wire_data_Wireless_srv, trace.Entity, trace.PhysicsBone, true)

	undo.Create("Wire_BTSRV")
		undo.AddEntity( wire_data_Wireless_srv )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_data_Wireless_srv", wire_data_Wireless_srv )
	ply:AddCleanup( "wire_data_Wireless_srv", const )

	return true
end

function TOOL:RightClick( trace )
	return true
end

function TOOL:Reload( trace )
	return true
end


if (SERVER) then

	function MakeWirebtsrv( pl, Pos, Ang, Model )
		if ( !pl:CheckLimit( "wire_data_Wireless_srv" ) ) then return false end
	
		local wire_data_Wireless_srv = ents.Create( "gmod_wire_Wireless_srv" )
		if (!wire_data_Wireless_srv:IsValid()) then return false end

		wire_data_Wireless_srv:SetAngles( Ang )
		wire_data_Wireless_srv:SetPos( Pos )
		wire_data_Wireless_srv:SetModel( Model )
		wire_data_Wireless_srv:Spawn()

		wire_data_Wireless_srv:SetPlayer( pl )
		wire_data_Wireless_srv.pl = pl

		pl:AddCount( "wire_data_Wireless_srv", wire_data_Wireless_srv )

		return wire_data_Wireless_srv
	end
	
	duplicator.RegisterEntityClass("gmod_wire_data_Wireless_srv", MakeWirebtsrv, "Pos", "Ang", "Model", "Vel", "aVel", "frozen")

end

function TOOL:UpdateGhostWirebtsrv( ent, player )
	if ( !ent || !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_data_Wireless_srv" ) then
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
		self:MakeGhostEntity( self:GetClientInfo("Model"), Vector(0,0,0), Angle(0,0,0) )
	end

	self:UpdateGhostWirebtsrv( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_data_Wireless_srv_name", Description = "#Tool_wire_data_Wireless_srv_desc" })
end
