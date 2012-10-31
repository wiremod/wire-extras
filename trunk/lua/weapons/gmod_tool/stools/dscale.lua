TOOL.Category		= "Wire - Physics"
TOOL.Name			= "Damage Scale"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_dscale_name", "Damage Scale Tool (Wire)" )
    language.Add( "Tool_dscale_desc", "Spawns a Scale" )
    language.Add( "Tool_dscale_0", "Primary: Create Scale, Secondary: Change model" )
	language.Add( "Undone_dscale", "Undone Wired Damage Scale" )//Typo
end

TOOL.ClientConVar["Model"] = "models/kobilica/wiremonitorrtbig.mdl"
cleanup.Register("wire_dm_scale")

function TOOL:LeftClick( trace )
	if (!trace.HitPos) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local s = MakeScaleEnt( ply, trace.HitPos, Ang , self:GetClientInfo("model"))

	local min = s:OBBMins()
	s:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld(s, trace.Entity, trace.PhysicsBone, true)

	undo.Create("Wire Damage Scale")
		undo.AddEntity( s )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "dscale", s )
	ply:AddCleanup( "dscale", const )

	return true
end

function TOOL:RightClick( trace )
	local ply = self:GetOwner()
	if (CLIENT) then return true end
	
	if (trace.Entity and trace.Entity:IsValid()) then
		if (trace.Entity:GetClass() == "prop_physics") then
			ply:ConCommand('dscale_Model "'..trace.Entity:GetModel()..'"\n')

			Msg("Damage Scale model set to "..trace.Entity:GetModel().."\n")
		else
			ply:PrintMessage(3,"Damage Scales only accept physics models!")
		end
	end
	
	return true
end

function TOOL:Reload( trace )
    
end


if (SERVER) then

	function MakeScaleEnt( pl, Pos, Ang, Model )
		local w = ents.Create( "damage_scaler" )
		if (!w:IsValid()) then return false end

		w:SetAngles( Ang )
		w:SetPos( Pos )
		w:SetModel( Model )//Changed here
		w:Spawn()

		w:SetPlayer( pl )
		w.pl = pl
		
		pl:AddCount("dscale", w)

		return w
	end
	
	//duplicator.RegisterEntityClass("damage_scaler", MakeScaleEnt, "pl", "Pos", "Model", "frozen") //Changed to match
	duplicator.RegisterEntityClass("Pos", "Ang", "Model", "Vel", "aVel", "frozen")

end

function TOOL:UpdateGhostW( ent, player )
	if ( !ent || !ent:IsValid() ) then return end

	local tr 	= utilx.GetPlayerTrace( player, player:GetCursorAimVector() )
	local trace 	= util.TraceLine( tr )

	if (!trace.Hit || trace.Entity:IsPlayer() || trace.Entity:GetClass() == "damage_scaler" ) then
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

	self:UpdateGhostW( self.GhostEntity, self:GetOwner() )
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool_dscale_name", Description = "#Tool_dscale_desc" })
end
