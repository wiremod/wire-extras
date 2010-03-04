--Wire EGP by Goluch
--YAY Wire Lib GPU Thanx dude
--And yes i copied the graphic tablet tool SO WHAT!
TOOL.Category		= "Wire - Display"
TOOL.Name			= "EGP -> E2 Graphics Processor"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

if ( CLIENT ) then
    language.Add( "Tool_wire_egp_name", "EGP -> E2 Graphics Processor (Wire)" )
    language.Add( "Tool_wire_egp_desc", "Spawns an EGP" )
    language.Add( "Tool_wire_egp_0", "Primary: Create EGP" )
	language.Add( "sboxlimit_wire_egps", "You've hit EGP limit!" )
	language.Add( "Undone_wireegp", "Undone Wire E2 Graphics Processor" )
	language.Add("Tool_wire_egp_createflat", "Create flat to surface")
end

if (SERVER) then
	CreateConVar('sbox_maxwire_egps', 20)
end

TOOL.ClientConVar["model"] = "models/kobilica/wiremonitorbig.mdl"
TOOL.ClientConVar["createflat"] = 1

cleanup.Register( "wire_egps" )

function TOOL:LeftClick( trace )
	if trace.Entity && trace.Entity:IsPlayer() then return false end
	if (CLIENT) then return true end
	
	if ( !self:GetSWEP():CheckLimit( "wire_egps" ) ) then return false end
	
	if (not util.IsValidModel(self:GetClientInfo( "model" ))) then return false end
	if (not util.IsValidProp(self:GetClientInfo( "model" ))) then return false end
	
	local ply = self:GetOwner()
	local Ang = trace.HitNormal:Angle()
	local model = self:GetClientInfo("model")
	local CreateFlat = self:GetClientNumber("createflat")
	
	if (CreateFlat == 0) then
		Ang.pitch = Ang.pitch + 90
	end
	
	if (string.find(self:GetClientInfo( "model" ),"models/hunter/plates/"))  or (string.find(self:GetClientInfo( "model" ),"models/cheeze/pcb")) then
		Ang.pitch = Ang.pitch + 90
	end
	
	local wire_egp = MakeWireEGP(ply, trace.HitPos, Ang, model)
	local min = wire_egp:OBBMins()
	wire_egp:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld(wire_egp, trace.Entity, trace.PhysicsBone, true)
	
	undo.Create("wireegp")
		undo.AddEntity( wire_egp )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_egps", wire_egp )

	return true
end

if (SERVER) then
	function MakeWireEGP( pl, Pos, Ang, model )
		if ( !pl:CheckLimit( "wire_egps" ) ) then return false end
		
		local wire_egp = ents.Create( "gmod_wire_egp" )
		if (!wire_egp:IsValid()) then return false end
		wire_egp:SetModel(model)

		wire_egp:SetAngles( Ang )
		wire_egp:SetPos( Pos )
		wire_egp:Spawn()
		wire_egp:SetPlayer(pl)
			
		local ttable = {
			pl = pl,
			model = model
		}
		table.Merge(wire_egp:GetTable(), ttable )
		pl:AddCount( "wire_egps", wire_egp )
		return wire_egp
	end
	duplicator.RegisterEntityClass("gmod_wire_egp", MakeWireEGP, "Pos", "Ang", "Model")
end

function TOOL:UpdateGhostWireEGP( ent, player )
	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end

	local tr = utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace = util.TraceLine( tr )
	if (!trace.Hit) then return end
	local Ang = trace.HitNormal:Angle()
	if (self:GetClientNumber("createflat") == 0) then
		Ang.pitch = Ang.pitch + 90
	end
	
	if (string.find(self:GetClientInfo( "model" ),"models/hunter/plates/")) then
		Ang.pitch = Ang.pitch + 90
	end
	
	local min = ent:OBBMins()
	ent:SetPos( trace.HitPos - trace.HitNormal * min.z )
	ent:SetAngles( Ang )
	ent:SetNoDraw( false )
end

function TOOL:Think()
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self:GetClientInfo( "model" ) || (not self.GhostEntity:GetModel()) ) then
		self:MakeGhostEntity( self:GetClientInfo( "model" ), Vector(0,0,0), Angle(0,0,0) )
	end
	self:UpdateGhostWireEGP( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_wire_egp_name", Description = "#Tool_wire_egp_desc" })
	WireDermaExts.ModelSelect(panel, "wire_egp_model", list.Get( "WireScreenModels" ), 2)
	panel:AddControl("Checkbox", {
		Label = "#Tool_wire_egp_createflat",
		Command = "wire_egp_createflat"
	})
end
	
