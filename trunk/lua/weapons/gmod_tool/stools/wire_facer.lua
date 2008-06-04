TOOL.Category		= "Wire - Physics"
TOOL.Name			= "Facer"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.ClientConVar[ "model" ] = "models/props_vehicles/carparts_wheel01a.mdl"

if ( CLIENT ) then
    language.Add( "Tool_wire_facer_name", "Facer (Wire)" )
    language.Add( "Tool_wire_facer_desc", "Spawns a Facer" )
    language.Add( "Tool_wire_facer_0", "Primary: Create Facer. Secondary: Get Model" )
    language.Add( "WireDatafacerTool_facer", "Facer:" )
	language.Add( "sboxlimit_wire_facers", "You've hit facers limit!" )
	language.Add( "undone_Wire facer", "Undone Wire Facer" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_facers', 20)
end

cleanup.Register( "wire_facers" )

function TOOL:LeftClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_facer" && trace.Entity:GetTable().pl == ply ) then
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_facers" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
	
	local Model	= self:GetClientInfo( "model" )

	local wire_facer = MakeWirefacer( ply, Model, trace.HitPos, Ang )

	local min = wire_facer:OBBMins()
	wire_facer:SetPos( trace.HitPos - trace.HitNormal * min.z )
		
	undo.Create("Wire facer")
		undo.AddEntity( wire_facer )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_facers", wire_facer )

	return true
end

function TOOL:RightClick( trace )
	if CLIENT and trace.Entity:IsValid() then return true end
	if not trace.Entity:IsValid() then return end
	local model = trace.Entity:GetModel()
	self:GetOwner():ConCommand("wire_facer_model "..model);
	self.Model = model
	return true;
end

if (SERVER) then

	function MakeWirefacer( pl, Model, Pos, Ang )
		if ( !pl:CheckLimit( "wire_facers" ) ) then return false end
	
		local wire_facer = ents.Create( "gmod_wire_facer" )
		if (!wire_facer:IsValid()) then return false end

		wire_facer:SetAngles(Ang)
		wire_facer:SetPos(Pos)
		wire_facer:SetModel(Model)
		wire_facer:Spawn()

		wire_facer:GetTable():SetPlayer( pl )

		local ttable = {
			pl = pl
		}

		table.Merge(wire_facer:GetTable(), ttable )
		
		pl:AddCount( "wire_facers", wire_facer )

		return wire_facer
	end
	
	duplicator.RegisterEntityClass("gmod_wire_facer", MakeWirefacer, "Model", "Pos", "Ang", "Vel", "aVel", "frozen")

end

function TOOL:UpdateGhostWireFacer( ent, player )
	if ( !ent || !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "gmod_wire_facer" ) then
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
		self:MakeGhostEntity( self:GetClientInfo("model"), Vector(0,0,0), Angle(0,0,0) )
	end

	self:UpdateGhostWireFacer( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)

	panel:AddControl("Header", { Text = "#Tool_wire_facer_name", Description = "#Tool_wire_facer_desc" })
	
end
