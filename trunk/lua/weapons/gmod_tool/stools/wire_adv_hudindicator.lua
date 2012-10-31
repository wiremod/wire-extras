// Created by TheApathetic, so you know who to
// blame if something goes wrong (someone else :P)

//Modified by Moggie100 to add additional functionality!

TOOL.Category		= "Wire - Display"
TOOL.Name			= "Adv. Hud Indicator"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if ( CLIENT ) then
    language.Add( "tool.wire_adv_hudindicator.name", "Adv. Hud Indicator Tool (Wire)" )
    language.Add( "tool.wire_adv_hudindicator.desc", "Spawns an Adv. Hud Indicator for use with the wire system." )
    language.Add( "tool.wire_adv_hudindicator.0", "Primary: Create/Update Hud Indicator Secondary: Hook/Unhook someone else's Hud Indicator Reload: Link Hud Indicator to vehicle" )
	language.Add( "tool.wire_adv_hudindicator.1", "Now use Reload on a vehicle to link this Hud Indicator to it, or on the same Hud Indicator to unlink it" )

	language.Add( "undone_wireadvhudindicator", "Undone Wire Adv. Hud Indicator" )

	// HUD Indicator stuff
	language.Add( "ToolWireAdvHudIndicator_showinhud", "Show in my HUD:")
	language.Add( "ToolWireAdvHudIndicator_hudheaderdesc", "HUD Indicator Settings:")
	language.Add( "ToolWireAdvHudIndicator_huddesc", "Description:")
	language.Add( "ToolWireAdvHudIndicator_hudaddname", "Add as Name:")
	language.Add( "ToolWireAdvHudIndicator_hudaddnamedesc", "Also adds description as name of indicator (like Wire Namer)")
	language.Add( "ToolWireAdvHudIndicator_hudshowvalue", "Show Value as:")
	language.Add( "ToolWireAdvHudIndicator_hudshowvaluedesc", "How to display value in HUD readout along with description")
	language.Add( "ToolWireAdvHudIndicator_hudstyle", "HUD Style:")
	language.Add( "ToolWireAdvHudIndicator_allowhook", "Allow others to hook:")
	language.Add( "ToolWireAdvHudIndicator_allowhookdesc", "Allows others to hook this indicator with right-click")
	language.Add( "ToolWireAdvHudIndicator_hookhidehud", "Allow HideHUD on hooked:")
	language.Add( "ToolWireAdvHudIndicator_hookhidehuddesc", "Whether your next hooked indicator will be subject to the HideHUD input of that indicator")
	language.Add( "ToolWireAdvHudIndicator_fullcircleangle", "Start angle for full circle gauge (deg):")
	language.Add( "ToolWireAdvHudIndicator_registeredindicators", "Registered Indicators:")
	language.Add( "ToolWireAdvHudIndicator_deleteselected", "Unregister Selected Indicator")
end

if (SERVER) then
	// Hud indicators use the original indicator CVar
	//CreateConVar('sbox_maxwire_indicators', 20)
end

TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_siren.mdl"
TOOL.ClientConVar[ "a" ] = "0"
TOOL.ClientConVar[ "ar" ] = "255"
TOOL.ClientConVar[ "ag" ] = "0"
TOOL.ClientConVar[ "ab" ] = "0"
TOOL.ClientConVar[ "aa" ] = "255"
TOOL.ClientConVar[ "b" ] = "1"
TOOL.ClientConVar[ "br" ] = "0"
TOOL.ClientConVar[ "bg" ] = "255"
TOOL.ClientConVar[ "bb" ] = "0"
TOOL.ClientConVar[ "ba" ] = "255"
TOOL.ClientConVar[ "rotate90" ] = "0"
TOOL.ClientConVar[ "material" ] = "models/debug/debugwhite"

// HUD Indicator stuff
TOOL.ClientConVar[ "showinhud" ] = "0"
TOOL.ClientConVar[ "huddesc" ] = ""
TOOL.ClientConVar[ "hudaddname" ] = "0"
TOOL.ClientConVar[ "hudshowvalue" ] = "0"
TOOL.ClientConVar[ "hudx" ] = "22"
TOOL.ClientConVar[ "hudy" ] = "200"
TOOL.ClientConVar[ "hudstyle" ] = "0"
TOOL.ClientConVar[ "allowhook" ] = "1"
TOOL.ClientConVar[ "hookhidehud" ] = "0" // Couldn't resist this name :P
TOOL.ClientConVar[ "fullcircleangle" ] = "0"
TOOL.ClientConVar[ "registerdelete" ] = "0"

// Adv. HUD Indicator Stuff
TOOL.ClientConVar[ "useworldcoords" ] = "0"
TOOL.ClientConVar[ "positionmethod" ] = "0"
TOOL.ClientConVar[ "transitionstyle" ] = nil
TOOL.ClientConVar[ "stringinput" ] = "0"
TOOL.ClientConVar[ "usevectorinputs" ] = 0;

cleanup.Register( "wire_indicators" )

function TOOL:LeftClick( trace )

	local wire_adv_indicator = nil

	if trace.Entity && trace.Entity:IsPlayer() then return false end

	// If there's no physics object then we can't constraint it!
	if ( SERVER && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end

	if (CLIENT) then return true end

	local ply = self:GetOwner()

	local model			= self:GetClientInfo( "model" )
	local a				= self:GetClientNumber("a")
	local ar			= math.min(self:GetClientNumber("ar"), 255)
	local ag			= math.min(self:GetClientNumber("ag"), 255)
	local ab			= math.min(self:GetClientNumber("ab"), 255)
	local aa			= math.min(self:GetClientNumber("aa"), 255)
	local b				= self:GetClientNumber("b")
	local br			= math.min(self:GetClientNumber("br"), 255)
	local bg			= math.min(self:GetClientNumber("bg"), 255)
	local bb			= math.min(self:GetClientNumber("bb"), 255)
	local ba			= math.min(self:GetClientNumber("ba"), 255)
	local material		= self:GetClientInfo( "material" )

	local showinhud		= (self:GetClientNumber( "showinhud" ) > 0)
	local huddesc		= self:GetClientInfo( "huddesc" )
	local hudaddname	= (self:GetClientNumber( "hudaddname" ) > 0)
	local hudshowvalue	= self:GetClientNumber( "hudshowvalue" )
	local hudstyle		= self:GetClientNumber( "hudstyle" )
	local allowhook		= (self:GetClientNumber( "allowhook" ) > 0)
	local fullcircleangle = self:GetClientNumber( "fullcircleangle" )
	local useWorldCoords = 0	//--Redundant, but here incase anything needs it... REMOVE SOON --//
	local positionMethod = self:GetClientNumber("positionmethod")

	local flags = 0

	//--Flag Options--//
	local flag_worldcoords = 1
	local flag_alphainput = 2
	local flag_position_by_pixel = 4
	local flag_position_by_percent = 8
	local flag_position_by_decimal = 16
	local flag_string_input = 32
	local flag_vector_inputs = 64

	Msg( "World Coords Checkbox: " ..self:GetClientNumber( "useworldcoords" ).. "\n" )
	Msg( "Alpha Checkbox: " ..self:GetClientNumber( "alpha" ).. "\n" )

	if( self:GetClientNumber( "useworldcoords" ) == 1 ) then flags = bit.bor( flags, flag_worldcoords ) end
	if( self:GetClientNumber( "alpha" ) == 1 ) then flags = bit.bor( flags, flag_alphainput) end

	if( positionMethod == 0 ) then		//-- Pixels
		flags = bit.bor( flags, flag_position_by_pixel )
	elseif( positionMethod == 1 ) then	//-- Percent
		flags = bit.bor( flags, flag_position_by_percent )
	elseif( positionMethod == 2 ) then	//-- -1 to 1
		flags = bit.bor( flags, flag_position_by_decimal )
	end

	if( self:GetClientNumber("stringinput") == 1 ) then flags = bit.bor( flags, flag_string_input ) end				//--BETA! String input!--//

	//--Cope with vector inputs too!--//
	if( self:GetClientNumber("usevectorinputs") == 1 ) then flags = bit.bor( flags, flag_vector_inputs ) end

	// If we shot a wire_indicator change its data
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_adv_hudindicator" && trace.Entity.pl == ply ) then

		trace.Entity:Setup(a, ar, ag, ab, aa, b, br, bg, bb, ba)
		trace.Entity:SetMaterial( material )

		trace.Entity.a	= a
		trace.Entity.ar	= ar
		trace.Entity.ag	= ag
		trace.Entity.ab	= ab
		trace.Entity.aa	= aa
		trace.Entity.b	= b
		trace.Entity.br	= br
		trace.Entity.bg	= bg
		trace.Entity.bb	= bb
		trace.Entity.ba	= ba

		// This will un-register if showinhud is false
		trace.Entity:HUDSetup(showinhud, huddesc, hudaddname, hudshowvalue, hudstyle, allowhook, fullcircleangle, flags)

		trace.Entity.showinhud = showinhud
		trace.Entity.huddesc = huddesc
		trace.Entity.hudaddname = hudaddname
		trace.Entity.hudshowvalue = hudshowvalue
		trace.Entity.hudstyle = hudstyle
		trace.Entity.allowhook = allowhook
		trace.Entity.fullcircleangle = fullcircleangle

		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_indicators" ) ) then return false end

	if (not util.IsValidModel(model)) then return false end
	if (not util.IsValidProp(model)) then return false end		// Allow ragdolls to be used?

	//local Ang = trace.HitNormal:Angle()
	local Ang = self:GetSelectedAngle(trace.HitNormal:Angle())
	Ang.pitch = Ang.pitch + 90

	Msg("Tool FLAGS: "..flags.."\n")

	wire_adv_indicator = MakeWireAdvHudIndicator( ply, model, Ang, trace.HitPos, a, ar, ag, ab, aa, b, br, bg, bb, ba, material, showinhud, huddesc, hudaddname, hudshowvalue, hudstyle, allowhook, fullcircleangle, false,    false, flags, positionMethod )
					 //--MakeWireAdvHudIndicator( pl, Model, Ang, Pos, 			a, ar, ag, ab, aa, b, br, bg, bb, ba, material, showinhud, huddesc, hudaddname, hudshowvalue, hudstyle, allowhook, fullcircleangle, nocollide, frozen, flags, positionMethod )
	//-- Check that it was created properly...
	if( wire_adv_indicator == nil ) then
		Msg("Something went wrong with this entity, and it was not created :/ what the hell?\n");
		return false
	end

	local min = wire_adv_indicator:OBBMins()
	wire_adv_indicator:SetPos( trace.HitPos - trace.HitNormal * self:GetSelectedMin(min) )

	local const = WireLib.Weld(wire_adv_indicator, trace.Entity, trace.PhysicsBone, true)

	undo.Create("WireAdvHudIndicator")
		undo.AddEntity( wire_adv_indicator )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_indicators", wire_adv_indicator )

	return true
end

function TOOL:RightClick( trace )
	// Can only right-click on HUD Indicators
	if (!trace.Entity || !trace.Entity:IsValid() || trace.Entity:GetClass() != "gmod_wire_adv_hudindicator") then return false end

	if (CLIENT) then return true end

	local ply = self:GetOwner()
	local hookhidehud = (self:GetClientNumber( "hookhidehud" ) > 0)

	// Can't hook your own HUD Indicators
	if (ply == trace.Entity:GetPlayer()) then
		self:GetOwner():SendLua( "GAMEMODE:AddNotify('You cannot hook your own HUD Indicators!', NOTIFY_GENERIC, 7);" )
		return false
	end

	if (!trace.Entity:GetTable():CheckRegister(ply)) then
		// Has the creator allowed this HUD Indicator to be hooked?
		if (!trace.Entity:GetTable().AllowHook) then
			self:GetOwner():SendLua( "GAMEMODE:AddNotify('You are not allowed to hook this HUD Indicator.', NOTIFY_GENERIC, 7);" )
			return false
		end

		trace.Entity:GetTable():RegisterPlayer(ply, hookhidehud)
	else
		trace.Entity:GetTable():UnRegisterPlayer(ply)
	end

	return true
end

// Hook HUD Indicator to vehicle
function TOOL:Reload( trace )
	// Can only use this on HUD Indicators and vehicles
	// The class checks are done later on, no need to do it twice
	if (!trace.Entity || !trace.Entity:IsValid()) then return false end

	if (CLIENT) then return true end

	local iNum = self:NumObjects()

	if (iNum == 0) then
		if (trace.Entity:GetClass() != "gmod_wire_adv_hudindicator") then
			self:GetOwner():SendLua( "GAMEMODE:AddNotify('You must select a HUD Indicator to link first.', NOTIFY_GENERIC, 7);" )
			return false
		end

		local Phys = trace.Entity:GetPhysicsObjectNum( trace.PhysicsBone )
		self:SetObject( 1, trace.Entity, trace.HitPos, Phys, trace.PhysicsBone, trace.HitNormal )
		self:SetStage(1)
	elseif (iNum == 1) then
		if (trace.Entity != self:GetEnt(1)) then
			if (!string.find(trace.Entity:GetClass(), "prop_vehicle_")) then
				self:GetOwner():SendLua( "GAMEMODE:AddNotify('HUD Indicators can only be linked to vehicles.', NOTIFY_GENERIC, 7);" )
				self:ClearObjects()
				self:SetStage(0)
				return false
			end

			local ent = self:GetEnt(1)
			local bool = ent:GetTable():LinkVehicle(trace.Entity)

			if (!bool) then
				self:GetOwner():SendLua( "GAMEMODE:AddNotify('Could not link HUD Indicator!', NOTIFY_GENERIC, 7);" )
				return false
			end
		else
			// Unlink HUD Indicator from this vehicle
			trace.Entity:GetTable():UnLinkVehicle()
		end

		self:ClearObjects()
		self:SetStage(0)
	end

	return true
end

if (SERVER) then

	function MakeWireAdvHudIndicator( pl, Model, Ang, Pos, a, ar, ag, ab, aa, b, br, bg, bb, ba, material, showinhud, huddesc, hudaddname, hudshowvalue, hudstyle, allowhook, fullcircleangle, nocollide, frozen, flags, positionMethod )
		if ( !pl:CheckLimit( "wire_indicators" ) ) then return false end

		local positionMethod = 0
		local flags = flags

		if( flags == nil ) then
			flags = 0
			Msg("[WW] Adv. HUD::Flags auto-set!\n")
		end

		local wire_adv_indicator = ents.Create( "gmod_wire_adv_hudindicator" )
		if (!wire_adv_indicator:IsValid()) then return false end

		wire_adv_indicator:SetModel( Model )
		wire_adv_indicator:SetMaterial( material )
		wire_adv_indicator:SetAngles( Ang )
		wire_adv_indicator:SetPos( Pos )
		wire_adv_indicator:Spawn()

		wire_adv_indicator:Setup(a, ar, ag, ab, aa, b, br, bg, bb, ba)
		wire_adv_indicator:SetPlayer(pl)

		wire_adv_indicator:HUDSetup(showinhud, huddesc, hudaddname, hudshowvalue, hudstyle, allowhook, fullcircleangle, flags)

		if (nocollide) then
			local phys = wire_adv_indicator:GetPhysicsObject()
			if ( phys:IsValid() ) then phys:EnableCollisions(false) end
		end

		local ttable = {
			a	= a,
			ar	= ar,
			ag	= ag,
			ab	= ab,
			aa	= aa,
			b	= b,
			br	= br,
			bg	= bg,
			bb	= bb,
			ba	= ba,
			material = material,
			pl	= pl,
			nocollide = nocollide,
			showinhud = showinhud,
			huddesc = huddesc,
			hudaddname = hudaddname,
			hudshowvalue = hudshowvalue,
			hudstyle = hudstyle,
			allowhook = allowhook,
			fullcircleangle = fullcircleangle,
			force_position_update = 0,
		}
		table.Merge(wire_adv_indicator:GetTable(), ttable )

		pl:AddCount( "wire_indicators", wire_adv_indicator )

		return wire_adv_indicator
	end

	duplicator.RegisterEntityClass("gmod_wire_adv_hudindicator", MakeWireAdvHudIndicator, "Model", "Ang", "Pos", "a", "ar", "ag", "ab", "aa", "b", "br",
	  "bg", "bb", "ba", "material", "showinhud", "huddesc", "hudaddname", "hudshowvalue", "hudstyle", "allowhook", "fullcircleangle", "nocollide", "frozen", "flags", "positionMethod" )

end

function TOOL:UpdateGhostWireAdvHudIndicator( ent, player )

	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end

	local tr 	= util.GetPlayerTrace( player, player:GetAimVector() )
	local trace 	= util.TraceLine( tr )
	if (!trace.Hit) then return end

	if (trace.Entity && trace.Entity:GetClass() == "gmod_wire_adv_hudindicator" || trace.Entity:IsPlayer()) then
		ent:SetNoDraw( true )
		return
	end

	local Ang = self:GetSelectedAngle(trace.HitNormal:Angle())
	Ang.pitch = Ang.pitch + 90

	local min = ent:OBBMins()
	ent:SetPos( trace.HitPos - trace.HitNormal * self:GetSelectedMin(min) )
	ent:SetAngles( Ang )

	ent:SetNoDraw( false )

end

function TOOL:GetSelectedAngle( Ang )
	local Model = self:GetClientInfo( "model" )
	//these models get mounted differently
	if (Model == "models/props_borealis/bluebarrel001.mdl" || Model == "models/props_junk/PopCan01a.mdl") then
		return Ang + Angle(180, 0, 0)
	elseif (Model == "models/props_trainstation/trainstation_clock001.mdl" || Model == "models/segment.mdl" || Model == "models/segment2.mdl") then
		return Ang + Angle(-90, 0, (self:GetClientNumber("rotate90") * 90))
	else
		return Ang
	end
end

function TOOL:GetSelectedMin( min )
	local Model = self:GetClientInfo( "model" )
	//these models are different
	if (Model == "models/props_trainstation/trainstation_clock001.mdl" || Model == "models/segment.mdl" || Model == "models/segment2.mdl") then
		return min.x
	else
		return min.z
	end
end

function TOOL:Think()
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || self.GhostEntity:GetModel() != self:GetClientInfo( "model" )) then
		self:MakeGhostEntity( self:GetClientInfo( "model" ), Vector(0,0,0), self:GetSelectedAngle(Angle(0,0,0)) )
	end

	self:UpdateGhostWireAdvHudIndicator( self.GhostEntity, self:GetOwner() )

	if (SERVER) then
		// Add check to see if player is registered with
		// the HUD Indicator at which he is pointing
		if ((self.NextCheckTime or 0) < CurTime()) then
			local ply = self:GetOwner()
			local tr = util.GetPlayerTrace(ply, ply:GetAimVector())
			local trace = util.TraceLine(tr)

			if (trace.Hit && trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_adv_hudindicator" && trace.Entity:GetPlayer() != ply) then
				local currentcheck = trace.Entity:GetTable():CheckRegister(ply)
				if (currentcheck != self.LastRegisterCheck) then
					self.LastRegisterCheck = currentcheck
					self:GetWeapon():SetNetworkedBool("HUDIndicatorCheckRegister", currentcheck)
				end
			else
				if (self.LastRegisterCheck == true) then
					// Don't need to set this every 1/10 of a second
					self.LastRegisterCheck = false
					self:GetWeapon():SetNetworkedBool("HUDIndicatorCheckRegister", false)
				end
			end
			self.NextCheckTime = CurTime() + 0.10
		end
	end
end

if (CLIENT) then
	function TOOL:DrawHUD()
		local isregistered = self:GetWeapon():GetNetworkedBool("AdvHUDIndicatorCheckRegister")

		if (isregistered) then
			draw.WordBox(8, ScrW() / 2 + 10, ScrH() / 2 + 10, "Registered", "Default", Color(50, 50, 75, 192), Color(255, 255, 255, 255))
		end
	end
end

function TOOL:Holster()
	self:ReleaseGhostEntity()
	self:GetWeapon():SetNetworkedBool("HUDIndicatorCheckRegister", false)
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Header", { Text = "#Tool.wire_adv_hudindicator.name", Description = "#Tool.wire_adv_hudindicator.desc" })

	panel:AddControl("ComboBox", {
		Label = "#Presets",
		MenuButton = "1",
		Folder = "wire_adv_hudindicator",

		Options = {
			["#Default"] = {
				wire_hudindicator_a = "0",
				wire_hudindicator_ar = "255",
				wire_hudindicator_ag = "0",
				wire_hudindicator_ab = "0",
				wire_hudindicator_aa = "255",
				wire_hudindicator_b = "1",
				wire_hudindicator_br = "0",
				wire_hudindicator_bg = "255",
				wire_hudindicator_bb = "0",
				wire_hudindicator_ba = "255",
				wire_hudindicator_model = "models/jaanus/wiretool/wiretool_siren.mdl",
				wire_hudindicator_material = "models/debug/debugwhite",
				wire_hudindicator_rotate90 = "0",
				wire_hudindicator_showinhud = "0",
				wire_hudindicator_huddesc = "",
				wire_hudindicator_hudaddname = "0",
				wire_hudindicator_hudshowvalue = "0",
				wire_hudindicator_hudstyle = "0"
			}
		},

		CVars = {
			[0] = "wire_adv_hudindicator_a",
			[1] = "wire_adv_hudindicator_ar",
			[2] = "wire_adv_hudindicator_ag",
			[3] = "wire_adv_hudindicator_ab",
			[4] = "wire_adv_hudindicator_aa",
			[5] = "wire_adv_hudindicator_b",
			[6] = "wire_adv_hudindicator_br",
			[7] = "wire_adv_hudindicator_bg",
			[8] = "wire_adv_hudindicator_bb",
			[9] = "wire_adv_hudindicator_ba",
			[10] = "wire_adv_hudindicator_model",
			[11] = "wire_adv_hudindicator_material",
			[12] = "wire_adv_hudindicator_rotate90",
			[13] = "wire_adv_hudindicator_showinhud",
			[14] = "wire_adv_hudindicator_huddesc",
			[15] = "wire_adv_hudindicator_hudaddname",
			[16] = "wire_adv_hudindicator_hudshowvalue",
			[17] = "wire_adv_hudindicator_hudstyle",

			[18] = "wire_adv_hudindicator_worldcoords"
		}
	})

	panel:AddControl("Slider", {
		Label = "A value",
		Type = "Float",
		Min = "-10",
		Max = "10",
		Command = "wire_adv_hudindicator_a"
	})
	panel:AddControl("Color", {
		Label = "#ToolWireAdvHudIndicator_a_colour",
		Red = "wire_adv_hudindicator_ar",
		Green = "wire_adv_hudindicator_ag",
		Blue = "wire_adv_hudindicator_ab",
		Alpha = "wire_adv_hudindicator_aa",
		ShowAlpha = "1",
		ShowHSV = "1",
		ShowRGB = "1",
		Multiplier = "255"
	})

	panel:AddControl("Slider", {
		Label =	"B Value",
		Type = "Float",
		Min = "-10",
		Max = "10",
		Command = "wire_adv_hudindicator_b"
	})
	panel:AddControl("Color", {
		Label = "#ToolWireAdvHudIndicator_b_colour",
		Red = "wire_adv_hudindicator_br",
		Green = "wire_adv_hudindicator_bg",
		Blue = "wire_adv_hudindicator_bb",
		Alpha = "wire_adv_hudindicator_ba",
		ShowAlpha = "1",
		ShowHSV = "1",
		ShowRGB = "1",
		Multiplier = "255"
	})

	panel:AddControl("Label", {
		Text = "Indicator model:",
		Description = "The model to use for the Adv, HUD Indicator..."
	})

	ModelPlug_AddToCPanel(panel, "indicator", "wire_adv_hudindicator", "#ToolWireIndicator_Model", nil, "#ToolWireIndicator_Model")

	panel:AddControl("Label", {
		Text = "HUD Type",
		Description = "The style of HUD to display..."
	})

	//--["Gradient"]	= { wire_adv_hudindicator_hudstyle = "1" },
	//--["Percent Bar"]	= { wire_adv_hudindicator_hudstyle = "2" },
	//--["Full Circle"] = { wire_adv_hudindicator_hudstyle = "3" },
	//--["Semi-circle"] = { wire_adv_hudindicator_hudstyle = "4" },

	panel:AddControl("ComboBox", {
		Label = "#ToolWireAdvHudIndicator_hudstyle",
		MenuButton = "0",
		Options = {
			["Text (Basic)"]							= { wire_adv_hudindicator_hudstyle = "0" },
			["Text (Boxed)"]							= { wire_adv_hudindicator_hudstyle = "1" },
			["[BETA] Multiline Box"]					= { wire_adv_hudindicator_hudstyle = "2" },
			["Percent Bar (Basic,Horizontal)"]			= { wire_adv_hudindicator_hudstyle = "10" },
			["Percent Bar (Line,Horizontal)"]			= { wire_adv_hudindicator_hudstyle = "11" },
			["Percent Bar (Basic,Vertical)"]			= { wire_adv_hudindicator_hudstyle = "20" },
			["Percent Bar (Line,Vertical)"]				= { wire_adv_hudindicator_hudstyle = "21" },
			["Basic Target Marker"] 					= { wire_adv_hudindicator_hudstyle = "30" },
			["Triangular Target Marker"] 				= { wire_adv_hudindicator_hudstyle = "40" },
			["Crosshair Style 1"] 						= { wire_adv_hudindicator_hudstyle = "50" },
			["Crosshair Style 2"] 						= { wire_adv_hudindicator_hudstyle = "51" },
			["Crosshair Style 3"] 						= { wire_adv_hudindicator_hudstyle = "52" },
			["Crosshair Style 4"] 						= { wire_adv_hudindicator_hudstyle = "53" },
			["[BETA] Sci-Fi Style Crosshair"]			= { wire_adv_hudindicator_hudstyle = "54" },
			["[Corner-to-corner] Crosshair"]			= { wire_adv_hudindicator_hudstyle = "31" },
			["Triangular Rotating"]						= { wire_adv_hudindicator_hudstyle = "100" },
			["[Point-To-Point] Line"]					= { wire_adv_hudindicator_hudstyle = "200" },
			["[Point-To-Point] Box"]					= { wire_adv_hudindicator_hudstyle = "201" },
			["[Point-To-Point] Rounded Box"]			= { wire_adv_hudindicator_hudstyle = "202" },
			["[Extended I/O] Basic Target Marker"]		= { wire_adv_hudindicator_hudstyle = "1000" },
			["[Extended I/O] Crosshair Style 3"]		= { wire_adv_hudindicator_hudstyle = "1001" },
			["[BETA][Extended I/O] Divided Box"]		= { wire_adv_hudindicator_hudstyle = "1002" }
		}
	})

	//--panel:AddControl("ComboBox", {
	//--	Label = "Transition style",
	//--	MenuButton = "0",
	//--	Options = {
	//--		["None"] = { wire_adv_hudindicator_transitionstyle = nil },
	//--		["Fade"] = { wire_adv_hudindicator_transitionstyle = "fade" },
	//--		["Blink"] = { wire_adv_hudindicator_transitionstyle = "blink" },
	//--		["Scale Up"] = { wire_adv_hudindicator_transitionstyle = "scale up" },
	//--		["Scale Down"] = { wire_adv_hudindicator_transitionstyle = "scale down" }
	//--	}
	//--})

	panel:AddControl("TextBox", {
		Label = "#ToolWireHudIndicator_huddesc",
		Command = "wire_adv_hudindicator_huddesc",
		MaxLength = "20"
	})

	panel:AddControl("ComboBox", {
		Label = "Show value as:",
		MenuButton = "0",
		Options = {
			["None"]	= { wire_adv_hudindicator_hudshowvalue = "0" },
			["Percent"] = { wire_adv_hudindicator_hudshowvalue = "1" },
			["Value"]	= { wire_adv_hudindicator_hudshowvalue = "2" }
		}
	})

	panel:AddControl("CheckBox", {
		Label = "#ToolWireHudIndicator_showinhud",
		Command = "wire_adv_hudindicator_showinhud"
	})

	panel:AddControl("CheckBox", {
		Label = "World coordinates",
		Command = "wire_adv_hudindicator_useworldcoords",
		Description = "Allow world coordinate input rather than screen positions"
	})

	panel:AddControl("CheckBox", {
		Label = "Vector Inputs",
		Command = "wire_adv_hudindicator_usevectorinputs",
		Description = "Use vector inputs instead of regular wires for positions"
	})

	panel:AddControl("ComboBox", {
		Label = "2D Position using method: ",
		MenuButton = "0",
		Options = {
			["Pixels"]	= { wire_adv_hudindicator_positionmethod = "0" },
			["Percent"] = { wire_adv_hudindicator_positionmethod = "1" },
			["-1 to 1"]	= { wire_adv_hudindicator_positionmethod = "2" }
		}
	})

	panel:AddControl("TextBox", {
		Label = "Text X offset",
		Command = "wire_adv_hudindicator_hudx",
		MaxLength = "20"
	})

	panel:AddControl("TextBox", {
		Label = "Text Y offset",
		Command = "wire_adv_hudindicator_hudy",
		MaxLength = "20"
	})

	panel:AddControl("CheckBox", {
		Label = "[BETA] Additional string input for UI text",
		Command = "wire_adv_hudindicator_stringinput"
	})


end

// Concommand to unregister HUD Indicator through control panel
local function HUDIndicator_RemoteUnRegister(ply, cmd, arg)
	local eindex = ply:GetInfoNum("wire_hudindicator_registerdelete", 0)
	if (eindex == 0) then return end
	local ent = ents.GetByIndex(eindex)
	if (ent && ent:IsValid()) then
		ent:UnRegisterPlayer(ply)
	end
end
concommand.Add("wire_adv_hudindicator_delete", HUDIndicator_RemoteUnRegister)
