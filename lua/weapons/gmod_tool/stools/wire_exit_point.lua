-- Wire Advanced Entity Marker
-- Made by Divran

TOOL.Category		= "Wire - Physics"
TOOL.Name			= "Multi Exit Point Controller"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

if ( CLIENT ) then
    language.Add( "Tool_wire_exit_point_name", "Multi Exit Point Controller Tool (Wire)" )
    language.Add( "Tool_wire_exit_point_desc", "Primary: Spawns and welds an Exit Point, Secondary: Spawns an Exit Point and doesn't weld it." )
    language.Add( "Tool_wire_exit_point_0", "Primary: Spawn Exit Point" )
elseif ( SERVER ) then
    CreateConVar('sbox_maxwire_exit_points',5)
end

TOOL.ClientConVar[ "model" ] = "models/jaanus/thruster_flat.mdl"
cleanup.Register( "wire_exit_points" )


function TOOL:GetModel()
	local mdl = self:GetClientInfo("model")
	if (!util.IsValidModel(mdl) or !util.IsValidProp(mdl)) then return "models/jaanus/thruster_flat.mdl" end
	return mdl
end

if (SERVER) then

	function TOOL:Create( ply, trace, model )
		if (!trace or !trace.Hit) then return end
		if (!ply:CheckLimit("wire_exit_points")) then return end
		local ent = ents.Create("gmod_wire_exit_point")
		if (!ent) then return end
		ent:SetModel( model or "models/jaanus/thruster_flat.mdl" )
		ent:SetPos( trace.HitPos - trace.HitNormal * ent:OBBMins().z )
		ent:SetAngles( trace.HitNormal:Angle() + Angle(90,0,0) )
		ent:SetPlayer( ply )
		ent:Spawn()
		ent:Activate()
		ply:AddCount( "wire_exit_points", ent )
		return ent
	end
	
end
	
function TOOL:LeftClick( trace )
	if (!trace) then return end
	if (CLIENT) then return true end
	local ply = self:GetOwner()

	local ent = self:Create( ply, trace, self:GetModel() )
	
	local const = WireLib.Weld( ent, trace.Entity, trace.PhysicsBone, true )
	undo.Create("wire_exit_point")
		undo.AddEntity( ent )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_exit_points", ent )

	return true
end

function TOOL:RightClick( trace )
	if (!trace) then return end
	if (CLIENT) then return true end
	
	local ply = self:GetOwner()

	local ent = self:Create( ply, trace, self:GetModel() )
	
	undo.Create("wire_exit_point")
		undo.AddEntity( ent )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_exit_points", ent )

	return true
end

if (CLIENT) then
	function TOOL.BuildCPanel(panel)
		panel:AddControl("Header", { Text = "#Tool_wire_exit_point_name", Description = "#Tool_wire_exit_point_desc" })
		WireDermaExts.ModelSelect(panel, "wire_exit_point_model", list.Get( "ThrusterModels" ), 8)
	end
end
	
function TOOL:UpdateGhost( ent, ply )
	if (!ent or !ent:IsValid()) then return end
	local trace = ply:GetEyeTrace()
	if (!trace.Hit or trace.Entity:IsPlayer()) then
		ent:SetNoDraw( true )
		return
	end
	
	local Ang = trace.HitNormal:Angle() + Angle(90,0,0)
	ent:SetAngles(Ang)
	
	local Pos = trace.HitPos - trace.HitNormal * ent:OBBMins().z
	ent:SetPos( Pos )
	
	ent:SetNoDraw( false )
end

TOOL.viewing = nil

function TOOL:Think()
	local model = self:GetModel()
	
	if (!self.GhostEntity or !self.GhostEntity:IsValid() or self.GhostEntity:GetModel() != model ) then
		self:MakeGhostEntity( Model(model), Vector(0,0,0), Angle(0,0,0) )
	end
	
	self:UpdateGhost( self.GhostEntity, self:GetOwner() )
end