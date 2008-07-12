TOOL.Category		= "Wire - Control"
TOOL.Name			= "PID"
TOOL.Command		= nil
TOOL.ConfigName		= ""

/* Con vars for this stool */
TOOL.ClientConVar[ "pgain" ] = "0"
TOOL.ClientConVar[ "igain" ] = "0"
TOOL.ClientConVar[ "dgain" ] = "0"
TOOL.ClientConVar[ "dcut" ] = "1000"
TOOL.ClientConVar[ "ilim" ] = "1000"
TOOL.ClientConVar[ "limit" ] = "1000"

TOOL.Model = "models/jaanus/wiretool/wiretool_siren.mdl"

/* If we're running on the client, setup the description strings */
if ( CLIENT ) then
    language.Add( "Tool_wire_pid_name", "PID Tool (Wire)" )
    language.Add( "Tool_wire_pid_desc", "Spawns a PID Loop." )
    language.Add( "Tool_wire_pid_0", "Primary: Create/Update Controller   Secondary: Copy Settings" )
    language.Add( "undone_Wire PID", "Undone Wire PID" )
end


function TOOL:LeftClick( trace )
	/* Everything is server except the trace */
	if (!SERVER) then return true end
	
	/* Setup all of our local variables */
	local ply = self:GetOwner()
	local pgain = self:GetClientNumber("pgain")
	local igain = self:GetClientNumber("igain")
	local dgain = self:GetClientNumber("dgain")
	local dcut = self:GetClientNumber("dcut")
	local ilim = self:GetClientNumber("ilim")
	local limit = self:GetClientNumber("limit")

	/* If we're just updating, call the PID's SetupGains and exit */
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_pid") then
		trace.Entity:SetupGains(pgain, igain, dgain, dcut, ilim, limit)
		return true
	end

	/* Don't want to put one on a player */
	if (trace.Entity:IsPlayer()) then return end

	/* Normal to hit surface */
	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	/* Make the PID loop */
	local ent = MakeWirePID(ply, self.Model, trace.HitPos, Ang, pgain, igain, dgain, dcut, ilim, limit)
	
	local min = ent:OBBMins()
	ent:SetPos( trace.HitPos - trace.HitNormal * min.z )

	/* Weld it to the surface, as long as it isn't the ground */
	if (!trace.HitWorld) then
		local const = WireLib.Weld(ent, trace.Entity, trace.PhysicsBone, true)
	end

	/* Add us to the undo list */
	undo.Create("Wire PID")
		undo.AddEntity(ent)
		if (!(const == nil)) then
			undo.AddEntity(const)
		end
		undo.SetPlayer(ply)
	undo.Finish()
	return true
end

function TOOL:RightClick( trace )
	
	/* Get our player */
	local ply = self:GetOwner()

	/* If we hit a PID loop that's ours, get its settings and change the tool's to match */
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_pid" && trace.Entity:GetPlayer() == ply ) then
		local pgain, igain, dgain, dcut, ilim, limit = trace.Entity.p, trace.Entity.i, trace.Entity.d, trace.Entity.dcut, trace.Entity.ilim, trace.Entity.limit
		local ply = self:GetOwner()
		ply:ConCommand("wire_pid_pgain "..pgain)
		ply:ConCommand("wire_pid_igain "..igain)
		ply:ConCommand("wire_pid_dgain "..dgain)
		ply:ConCommand("wire_pid_dcut "..dcut)
		ply:ConCommand("wire_pid_ilim "..ilim)
		ply:ConCommand("wire_pid_limit "..limit)

		return true
	end
end

if (SERVER) then
	/* Makes a PID loop */
	function MakeWirePID(pl, Model, Pos, Ang, p, i, d, dcut, ilim, limit, nocollide, Vel, aVel, frozen)
		local ent = ents.Create("gmod_wire_pid")
		ent:SetAngles(Ang)
		ent:SetPos(Pos)
		ent:SetModel(Model)
		ent:Spawn()
		ent:SetupGains(p, i, d, dcut, ilim, limit)
		ent:SetPlayer(pl)
		return ent
	end
	
	/* Register us for duplicator compatibility */
	duplicator.RegisterEntityClass("gmod_wire_pid", MakeWirePID, "Model", "Pos", "Ang", "p", "i", "d", "dcut", "ilim", "limit", "nocollide", "Vel", "aVel", "frozen")
end

function TOOL:UpdateGhostWirePID( ent, player )
	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )
	if (!trace.Hit) then return end

	if (trace.Entity && trace.Entity:GetClass() == "gmod_wire_pid" || trace.Entity:IsPlayer()) then
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

	self:UpdateGhostWirePID( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel( panel )
	panel:AddControl("Header", { 
		Text = "#Tool_wire_pid_name", 
		Description = "#Tool_wire_pid_desc" 
	})

	panel:AddControl("Slider", {
		Label = "P Gain",
		Type = "Float", 
		Min = "0", 
		Max = "1000", 
		Command = "wire_pid_pgain"
	})
	panel:AddControl("Slider", {
		Label = "I Gain",
		Type = "Float", 
		Min = "0", 
		Max = "10", 
		Command = "wire_pid_igain"
	})
	panel:AddControl("Slider", {
		Label = "D Gain",
		Type = "Float", 
		Min = "0", 
		Max = "1000", 
		Command = "wire_pid_dgain"
	})
	panel:AddControl("Slider", {
		Label = "D Cutoff for Integral",
		Type = "Float", 
		Min = "0", 
		Max = "1000", 
		Command = "wire_pid_dcut"
	})
	panel:AddControl("Slider", {
		Label = "Integral Limit",
		Type = "Float", 
		Min = "0", 
		Max = "10000", 
		Command = "wire_pid_ilim"
	})
	panel:AddControl("Slider", {
		Label = "Output Limit",
		Type = "Float", 
		Min = "0", 
		Max = "10000", 
		Command = "wire_pid_limit"
	})
end
