
TOOL.Category		= "Wire - Render"
TOOL.Name			= "Materializer"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if CLIENT then
    language.Add( "Tool.wire_materializer.name", "Materializer Tool (Wire)" )
    language.Add( "Tool.wire_materializer.desc", "Spawns a constant materializer prop for use with the wire system." )
    language.Add( "Tool.wire_materializer.0", "Primary: Create/Update Materializer" )
    language.Add( "WireMaterializerTool_materializer", "Materializer:" )
    language.Add( "WireMaterializerTool_outMat", "Output Material:" )
    language.Add( "WireMaterializerTool_Range", "Max Range:" )
    language.Add( "WireMaterializerTool_Model", "Choose a Model:")
	language.Add( "sboxlimit_wire_materializers", "You've hit Materializers limit!" )
	language.Add( "undone_Wire Materializer", "Undone Wire Materializer" )
end

if SERVER then
	CreateConVar('sbox_maxwire_materializers', 20)
end

local matmodels = {
    ["models/jaanus/wiretool/wiretool_siren.mdl"] = {},
    ["models/jaanus/wiretool/wiretool_beamcaster.mdl"] = {},
	["models/jaanus/wiretool/wiretool_range.mdl"] = {}
}
	
--TOOL.Model = "models/jaanus/wiretool/wiretool_siren.mdl"
TOOL.ClientConVar[ "Model" ] = "models/jaanus/wiretool/wiretool_siren.mdl"
TOOL.ClientConVar[ "outMat" ] = "0"
TOOL.ClientConVar[ "Range" ] = "2000"

cleanup.Register( "wire_materializers" )

function TOOL:LeftClick( trace )
	if !trace.HitPos then return false end
	if trace.Entity:IsPlayer() then return false end
	if CLIENT then return true end
	
	local ply = self:GetOwner()
	
	if IsValid(trace.Entity) and trace.Entity:GetClass() == "gmod_wire_materializer" and trace.Entity:GetTable().pl == ply then
		trace.Entity:SetBeamLength( self:GetClientNumber( "Range" ) )
		return true
	end
	
	if !self:GetSWEP():CheckLimit( "wire_materializers" ) then return false end
	
	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
	
    local outMat = (self:GetClientNumber( "outMat" ) ~= 0)
    local range = self:GetClientNumber( "Range" )
    local model = self:GetClientInfo( "Model" )
	
	local wire_materializer = MakeWireMaterializer( ply, trace.HitPos, outMat, range, model, Ang )
	
	local min = wire_materializer:OBBMins()
	wire_materializer:SetPos( trace.HitPos - trace.HitNormal * min.z )
	
	local const = WireLib.Weld( wire_materializer, trace.Entity, trace.PhysicsBone, true )
	
	undo.Create( "Wire Materializer" )
		undo.AddEntity( wire_materializer )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()
	
	ply:AddCleanup( "wire_materializers", wire_materializer )
	
	return true
end

function TOOL:RightClick( trace )
	return false
end

if SERVER then
	
	function MakeWireMaterializer( pl, Pos, outMat, Range, Model, Ang )
		if !pl:CheckLimit( "wire_materializers" ) then return false end
		
		local wire_materializer = ents.Create( "gmod_wire_materializer" )
		if !IsValid(wire_materializer) then return false end
		
		wire_materializer:SetAngles( Ang )
		wire_materializer:SetPos( Pos )
		wire_materializer:SetModel( Model )
		wire_materializer:Spawn()
		wire_materializer:Setup( outMat, Range )
		
		wire_materializer:SetPlayer( pl )
		
		local ttable = {
		    outMat = outMat,
		    Range = Range,
			pl = pl
		}
		
		table.Merge(wire_materializer:GetTable(), ttable )
		
		pl:AddCount( "wire_materializers", wire_materializer )
		
		return wire_materializer
	end
	
	duplicator.RegisterEntityClass("gmod_wire_materializer", MakeWireMaterializer, "Pos", "outMat", "Range", "Model", "Ang", "Vel", "aVel", "frozen")
	
end

function TOOL:UpdateGhostWireMaterializer( ent, player )
	if !IsValid(ent) then return end
	
	local tr 	= util.GetPlayerTrace( player, player:GetAimVector() )
	local trace 	= util.TraceLine( tr )
	
	if !trace.Hit or trace.Entity:IsPlayer() or trace.Entity:GetClass() == "gmod_wire_materializer" then
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
	if !self.GhostEntity or !self.GhostEntity:IsValid() or self.GhostEntity:GetModel() != self:GetClientInfo("Model") then
		self:MakeGhostEntity( self:GetClientInfo("Model"), Vector(0,0,0), Angle(0,0,0) )
	end
	
	self:UpdateGhostWireMaterializer( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool.wire_materializer.name", Description = "#Tool.wire_materializer.desc" })

	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_materializer",

		Options = {
			Default = {
				wire_materializer_outMat = "0",
			}
		},
		CVars = {
		  [0] = "wire_materializer_outMat"
		}
	})
	
	panel:AddControl( "PropSelect", { Label = "#WireMaterializerTool_Model",
									 ConVar = "wire_materializer_Model",
									 Category = "Wire Materializers",
									 Models = matmodels } )
	
	panel:AddControl("CheckBox", {
		Label = "#WireMaterializerTool_outMat",
		Command = "wire_materializer_outMat"
	})
	
	panel:AddControl("Slider", {
		Label = "#WireMaterializerTool_Range",
		Type = "Float",
		Min = "1",
		Max = "10000",
		Command = "wire_materializer_Range"
	})
end

