TOOL.Category		= "Wire - Wireless"
TOOL.Name			= "Wireless Receiver"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool.wire_data_Wireless_recv.name", "Wireless Receiver Tool (Wire)" )
    language.Add( "Tool.wire_data_Wireless_recv.desc", "Spawns a Wireless Receiver." )
    language.Add( "Tool.wire_data_Wireless_recv.0", "Primary: Create Wireless Receiver" )
    language.Add( "WireDataTransfererTool_data_btrecv", "Wireless Receiver:" )
	language.Add( "sboxlimit_wire_data_Wireless_recv", "You've hit Wireless Receiver limit!" )
	language.Add( "Undone_Wire_BTRECV", "Undone Wire Wireless Receiver" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_data_Wireless_recv', 20)
end

TOOL.ClientConVar["Model"] = "models/hammy/pci_card.mdl"

TOOL.FirstSelected = nil

cleanup.Register( "wire_data_Wireless_recv" )

function TOOL:LeftClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_data_Wireless_recv" && trace.Entity:GetTable().pl == ply ) then
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_data_Wireless_recv" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_data_Wireless_recv = MakeWirebtrecv( ply, trace.HitPos, Ang , self:GetClientInfo("Model"))

	local min = wire_data_Wireless_recv:OBBMins()
	wire_data_Wireless_recv:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld(wire_data_Wireless_recv, trace.Entity, trace.PhysicsBone, true)

	undo.Create("Wire_BTRECV")
		undo.AddEntity( wire_data_Wireless_recv )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_data_Wireless_recv", wire_data_Wireless_recv )
	ply:AddCleanup( "wire_data_Wireless_recv", const )

	return true
end

function TOOL:RightClick( trace )
	return true
end

function TOOL:Reload( trace )
	return true
end


if (SERVER) then

	function MakeWirebtrecv( pl, Pos, Ang, Model )
		if ( !pl:CheckLimit( "wire_data_Wireless_recv" ) ) then return false end
	
		local wire_data_Wireless_recv = ents.Create( "gmod_wire_Wireless_recv" )
		if (!wire_data_Wireless_recv:IsValid()) then return false end

		wire_data_Wireless_recv:SetAngles( Ang )
		wire_data_Wireless_recv:SetPos( Pos )
		wire_data_Wireless_recv:SetModel( Model )
		wire_data_Wireless_recv:Spawn()

		wire_data_Wireless_recv:SetPlayer( pl )
		wire_data_Wireless_recv.pl = pl

		pl:AddCount( "wire_data_Wireless_recv", wire_data_Wireless_recv )

		return wire_data_Wireless_recv
	end
	
	duplicator.RegisterEntityClass("gmod_wire_data_Wireless_recv", MakeWirebtrecv, "Pos", "Ang", "Model", "Vel", "aVel", "frozen")

end

function TOOL:UpdateGhostWirebtrecv( ent, player )
	if ( !ent || !ent:IsValid() ) then return end

	local tr 	= util.GetPlayerTrace( player, player:GetAimVector() )
	local trace 	= util.TraceLine( tr )

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_data_Wireless_recv" ) then
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

	self:UpdateGhostWirebtrecv( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool.wire_data_Wireless_recv.name", Description = "#Tool.wire_data_Wireless_recv.desc" })
end
