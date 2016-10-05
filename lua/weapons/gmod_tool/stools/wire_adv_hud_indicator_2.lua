TOOL.Category		= "Wire - Display"
TOOL.Name			= "Adv. Hud Indicator 2"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "Tool_wire_adv_hud_indicator_2_name", "Adv. HUD Indicator 2 ! (Wire)" )
    language.Add( "Tool_wire_adv_hud_indicator_2_desc", "Spawns an Adv. HUD Indicator 2 for use with the wire system." )
    language.Add( "Tool_wire_adv_hud_indicator_2_0", "Primary: Create/Update Hud Indicator Secondary: Hook/Unhook a HUD Indicator" )
	language.Add( "Tool_wire_adv_hud_indicator_2_1", "Now use Reload on a vehicle to link this HUD Indicator to it, or on the same HUD Indicator to unlink it" )
	
	language.Add( "Tool_wire_adv_hud_menu_showEditor", "Open the HML Editor" )
	
	language.Add( "undone_gmod_wire_hud_indicator_2", "Undone Wire Adv. HUD Indicator 2" )
end

//--Runs SERVERSIDE--//
function TOOL:LeftClick( trace )
	if (CLIENT) then return true end

	if trace.Entity:IsPlayer() then return false end
	local player = self:GetOwner()

	local model = "models/jaanus/wiretool/wiretool_siren.mdl"
	local position = trace.HitPos
	local material = "models/debug/debugwhite"
	local ent = nil

	local hmlCode = self:GetClientInfo( "hml_code" )

	--Angle and correction--
	local angle = trace.HitNormal:Angle()
	angle.pitch = angle.pitch + 90

	-- If we've clicked an already active SENT...
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_hud_indicator_2" && trace.Entity.pl == ply ) then
		ent = trace.Entity
		-- Update code here! FIXME!
	else
		-- Build the entity, and set its parameters
		ent = BuildWireAdvHudIndicator2( player, model, angle, position, material )
		if(ent == false) then return false end
	end
	local const = WireLib.Weld(ent, trace.Entity, trace.PhysicsBone, true)

	undo.Create("gmod_wire_hud_indicator_2")
		undo.AddEntity( ent )
		undo.AddEntity( const )
		undo.SetPlayer( player )
	undo.Finish()

	//-- Now that we have an entity, invoke its owner to send us code!
	player:SendLua("HUD2_uploadCode(" .. ent:EntIndex() .. ")")


	return true
end


if SERVER then
	function BuildWireAdvHudIndicator2( pl, Model, Ang, Pos, material, hml )
		local sent = ents.Create( "gmod_wire_hud_indicator_2" )
		if( sent:IsValid() ) then

			sent:SetModel( Model )
			sent:SetMaterial( material )
			sent:SetAngles( Ang )
			sent:SetPos( Pos )
			sent:Spawn()

			local phys = sent:GetPhysicsObject()
			if ( phys:IsValid() ) then
				phys:EnableCollisions(true)
			end

			//-- Breaks for some reason...?
			//--pl:AddCount( "wire_adv_indicators", wire_adv_indicator )

			print("<HML>: ", hml )
			--sent:RegisterPlayer( pl )
			sent:ReloadCode( hml or "" ) //-- DONT SEND NIL HML! --//

			return sent
		end

		Msg("[WW] Got a nil entity!\n")
		return false
	end
	duplicator.RegisterEntityClass("gmod_wire_hud_indicator_2", BuildWireAdvHudIndicator2, "Model", "Ang", "Pos", "material" )
end



function TOOL:RightClick( trace )
	if trace.Entity:IsPlayer() then return false end
	local player = self:GetOwner()
	
	if (trace.Entity && trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_hud_indicator_2") then
		local sent = trace.Entity
		sent:ToggleHooked( player )
		return true
	end
	
	return false
end

// Hook HUD Indicator to vehicle
function TOOL:Reload( trace )

	if (!trace.Entity || !trace.Entity:IsValid()) then return false end
	if trace.Entity:IsPlayer() then return false end
	
	if (CLIENT) then return true end
	
	local iNum = self:NumObjects()
	
	if (iNum == 0) then
		if (trace.Entity:GetClass() != "gmod_wire_hud_indicator_2") then
			WireLib.AddNotify(self:GetOwner(), "You must select a HUD Indicator to link first.", NOTIFY_GENERIC, 7)
			return false
		end
		
		local Phys = trace.Entity:GetPhysicsObjectNum( trace.PhysicsBone )
		self:SetObject( 1, trace.Entity, trace.HitPos, Phys, trace.PhysicsBone, trace.HitNormal )
		self:SetStage(1)
	elseif (iNum == 1) then
		if (trace.Entity != self:GetEnt(1)) then
			if (!string.find(trace.Entity:GetClass(), "prop_vehicle_")) then
				WireLib.AddNotify(self:GetOwner(), "HUD Indicators can only be linked to vehicles.", NOTIFY_GENERIC, 7)
				self:ClearObjects()
				self:SetStage(0)
				return false
			end
			
			local ent = self:GetEnt(1)
			local bool = ent:GetTable():LinkVehicle(trace.Entity)
			
			if (!bool) then
				WireLib.AddNotify(self:GetOwner(), "Could not link HUD Indicator!", NOTIFY_GENERIC, 7)
				return false
			end
			
			WireLib.AddNotify(self:GetOwner(), "HUD Linked!", NOTIFY_GENERIC, 5)
		else
			// Unlink HUD Indicator from this vehicle
			trace.Entity:GetTable():UnLinkVehicle()
			
			WireLib.AddNotify(self:GetOwner(), "HUD UnLinked!", NOTIFY_GENERIC, 5)
		end
		
		self:ClearObjects()
		self:SetStage(0)
	end

	return true
end

function TOOL:Holster()
	self:ReleaseGhostEntity()
	self:GetWeapon():SetNetworkedBool("HUDIndicatorCheckRegister", false)


end

function TOOL.BuildCPanel( panel )
	panel:ClearControls()
	panel:AddControl("Header", { Text = "#Tool_wire_adv_hud_menu_name", Description = "#Tool_wire_adv_hud_menu_desc" })

	panel:AddControl("Label", { Text = "HML is loaded to the entity from whatever is open in the editor."})

	panel:AddControl("Button", {
			Label = "#Tool_wire_adv_hud_menu_showEditor",
			Text = "Open Editor",
			Command = "openH2Editor"
		})
	
	panel:AddControl("Label", {
		Text = ""
	})
	
	panel:AddControl("CheckBox", {
		Label = "Show stats?",
		Command = "HUD2_showStats"
	})

end
