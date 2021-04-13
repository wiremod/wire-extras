
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

util.AddNetworkString("AdvHUDIndicatorStylePercent")
util.AddNetworkString("AdvHUDIndicatorRegister")
util.AddNetworkString("AdvHUDIndicatorUnRegister")
util.AddNetworkString("AdvHUDIndicator_STRING")
util.AddNetworkString("AdvHUDIndicator_EXIO")
util.AddNetworkString("AdvHUDIndicatorUpdate3DPositionTwo")
util.AddNetworkString("AdvHUDIndicatorUpdatePositionTwo")
util.AddNetworkString("AdvHUDIndicatorUpdate3DPosition")
util.AddNetworkString("AdvHUDIndicatorUpdatePosition")
util.AddNetworkString("AdvHUDIndicatorFactor")
util.AddNetworkString("AdvHUDIndicatorHideHUD")

include('shared.lua')

ENT.WireDebugName = "Adv. HUD Indicator"

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.A = 0
	self.AR = 0
	self.AG = 0
	self.AB = 0
	self.AA = 0
	self.B = 0
	self.BR = 0
	self.BG = 0
	self.BB = 0
	self.BA = 0

	//New position data - Moggie100
	self.xPos = 0
	self.yPos = 0

	self.xEnd = 0
	self.yEnd = 0

	//3D position buffer
	self.world_x = 0
	self.world_y = 0
	self.world_z = 0
	self.world_end_x = 0
	self.world_end_y = 0
	self.world_end_z = 0
	self.useWorldCoords = 0

	//EXIO Stuff
	self.EXIO_width = 0
	self.EXIO_height = 0
	self.EXIO_x = 0
	self.EXIO_y = 0
	self.EXIO_size = 0

	//Angular Inputs
	self.pitch = 0
	self.yaw = 0
	self.roll = 0

	//--additional flags
	self.flags = 0

	//--The method to use when positioning the indicators
	self.positionMethod = 0

	//--String store for the EXPERIMENTAL string input--//
	self.displayText = ""

	// List of players who have hooked this indicator
	self.RegisteredPlayers = {}
	self.PrefixText = "Adv. Hud: "

	self.Inputs = Wire_CreateInputs(self, { "Value", "HideHUD", "ScreenX", "ScreenY" })

end

function ENT:Setup(a, ar, ag, ab, aa, b, br, bg, bb, ba)

	self.A = a or 0
	self.AR = ar or 255
	self.AG = ag or 0
	self.AB = ab or 0
	self.AA = aa or 255
	self.B = b or 1
	self.BR = br or 0
	self.BG = bg or 255
	self.BB = bb or 0
	self.BA = ba or 255

end

// For HUD Indicators
function ENT:HUDSetup(showinhud, huddesc, hudaddname, hudshowvalue, hudstyle, allowhook, fullcircleangle, flags)

	local ply = self:GetPlayer()
	// If user updates with the STool to take indicator off of HUD
	if (!showinhud && self.ShowInHUD) then
		self:UnRegisterPlayer(ply)

		// Adjust inputs back to normal
		//Wire_AdjustInputs(self, { "Value" })
	elseif (showinhud) then
		// Basic style is useless without a value
		// to show so set a default if necessary
		if (hudstyle == 0 && hudshowvalue == 0) then
			hudshowvalue = 1
		end

		if (!self:CheckRegister(ply)) then
			// First-time register
			// Updating this player is handled further down
			self:RegisterPlayer(ply, true)
		end

		// Add name if desired
		if (hudaddname) then
			self:SetNWString("WireName", huddesc)
		elseif (self:GetNWString("WireName") == huddesc) then
			// Only remove it if the HUD Description was there
			// because there might be another name on it
			self:SetNWString("WireName", "")
		end

	end

	self.ShowInHUD = showinhud
	self.HUDDesc = huddesc
	self.HUDAddName = hudaddname
	self.HUDShowValue = hudshowvalue
	self.HUDStyle = hudstyle
	self.AllowHook = allowhook
	self.FullCircleAngle = fullcircleangle
	self.flags = flags

	// To tell if you can hook a HUD Indicator at a glance
	if (allowhook) then
		self.PrefixText = "(Hud) Color = "
	else
		self.PrefixText = "(Hud - Locked) Color = "
	end

	// Update all registered players with this info
	for k,v in pairs(self.RegisteredPlayers) do
		self:RegisterPlayer(v.ply, v.hookhidehud)
	end

	// Only trigger this input on the
	// first time that Setup() is called
	if (!self.HasBeenSetup) then
		self:TriggerInput("A", self.A)
		self:TriggerInput("HideHUD", 0)
		self.PrevHideHUD = false
		self.HasBeenSetup = true
	end


	//-- Update the inputs to match the style... --//
	//--local newInputs = { "A", "HideHUD" }

	local newInputs = {}
	local newInputTypes = {}
	local newInputDesc = {}

	table.insert(newInputs, "A")
	table.insert(newInputTypes, "NORMAL")
	//--table.insert(newInputDesc, "The value to display on the indicator (if any)")

	table.insert(newInputs, "HideHUD")
	table.insert(newInputTypes, "NORMAL")
	//--table.insert(newInputDesc, "Hide the HUD Indicator")


	//-- Translate the flags values... --//

	//--Flag Options--//
	local flag_worldcoords = 1
	local flag_position_by_pixel = 4
	local flag_position_by_percent = 8
	local flag_position_by_decimal = 16
	local flag_string_input = 32
	local flag_vector_inputs = 64

	if( flags == true ) then
		flags = 1
		Msg("[WW] Adv. HUD::Flags auto-translated to '1' from 'true'\n")
	end
	if( flags == false ) then
		flags = 0
		Msg("[WW] Adv. HUD::Flags auto-translated to '0' from 'false'\n")
	end

	if( flags != nil ) then
		if( bit.band( flags, flag_worldcoords ) == flag_worldcoords ) then

			//--Determine if we're using vector iniputs...--//
			if( bit.band( flags, flag_vector_inputs ) == flag_vector_inputs ) then
				table.insert(newInputs, "WorldPos")
				table.insert(newInputTypes, "VECTOR")
				//--table.insert(newInputDesc, "World position, as a vector")
			else
				table.insert(newInputs, "WorldX")
				table.insert(newInputTypes, "NORMAL")
				//--table.insert(newInputDesc, "World-space 'X' ordinate")

				table.insert(newInputs, "WorldY")
				table.insert(newInputTypes, "NORMAL")
				//--table.insert(newInputDesc, "World-space 'Y' ordinate")

				table.insert(newInputs, "WorldZ")
				table.insert(newInputTypes, "NORMAL")
				//--table.insert(newInputDesc, "World-space 'Z' ordinate")
			end
		else
			//--Determine if we're using vector iniputs...--//
			if( bit.band( flags, flag_vector_inputs ) == flag_vector_inputs ) then
				table.insert(newInputs, "ScreenPos")
				table.insert(newInputTypes, "VECTOR2")
				//--table.insert(newInputDesc, "Screen-space position vector")
			else
				table.insert(newInputs, "ScreenX")
				table.insert(newInputTypes, "NORMAL")
				//--table.insert(newInputDesc, "Screen-space 'X' ordinate")

				table.insert(newInputs, "ScreenY")
				table.insert(newInputTypes, "NORMAL")
				//--table.insert(newInputDesc, "Screen-space 'Y' ordinate")
			end
		end

		//--Manage position methods--//
		if( bit.band( flags, flag_position_by_pixel ) == flag_position_by_pixel ) then
			self.positionMethod = 0
		elseif( bit.band( flags, flag_position_by_percent ) == flag_position_by_percent ) then
			self.positionMethod = 1
		elseif( bit.band( flags, flag_position_by_decimal ) == flag_position_by_decimal ) then
			self.positionMethod = 2
		end


		//--Create a STRING input for the text on the indicator--//
		if( bit.band( flags, flag_string_input ) == flag_string_input ) then
			table.insert(newInputs, "DisplayText")
			table.insert(newInputTypes, "STRING")
			//--table.insert(newInputDesc, "The text to display on the indicator")
		end

	else
		Msg("[EE] Adv. HUD::NIL Flags?!?\n")
	end


	//-- If we are drawing a 2-point object, then
	if( self.HUDStyle > 199 && self.HUDStyle < 999 ) then

		//-- If we're drawing in 3D mode... --//
		if( bit.band( flags, 1 ) == 1 ) then

			//--Determine if we're using vector iniputs...--//
			if( bit.band( flags, flag_vector_inputs ) == flag_vector_inputs ) then
				table.insert(newInputs, "WorldEndPos")
				table.insert(newInputTypes, "VECTOR")
				//--table.insert(newInputDesc, "The end position in world space, as a vector")
			else
				table.insert(newInputs, "WorldEndX")
				table.insert(newInputTypes, "NORMAL")
				//--table.insert(newInputDesc, "The end X position in world space")

				table.insert(newInputs, "WorldEndY")
				table.insert(newInputTypes, "NORMAL")
				//--table.insert(newInputDesc, "The end Y position in world space")

				table.insert(newInputs, "WorldEndZ")
				table.insert(newInputTypes, "NORMAL")
				//--table.insert(newInputDesc, "The end Z position in world space")
			end

		else

			//--Determine if we're using vector iniputs...--//
			if( bit.band( flags, flag_vector_inputs ) == flag_vector_inputs ) then
				table.insert(newInputs, "EndPos")
				table.insert(newInputTypes, "VECTOR2")
				//--table.insert(newInputDesc, "The end X position in screen space")
			else
				table.insert(newInputs, "EndX")
				table.insert(newInputTypes, "NORMAL")
				//--table.insert(newInputDesc, "The end X position in screen space")

				table.insert(newInputs, "EndY")
				table.insert(newInputTypes, "NORMAL")
				//--table.insert(newInputDesc, "The end Y position in screen space")
			end

		end
	end

	//-------------------//
	//-- [Extended I/O --//
	//-------------------//
	if( self.HUDStyle > 999 ) then

		//--Add the styles requiring a size input here--//
		if( self.HUDStyle == 1000 ) then
			table.insert(newInputs, "EXIO_Size")
			table.insert(newInputTypes, "NORMAL")
			//--table.insert(newInputDesc, "Extended IO - Size parameter")
		end

		//--Add the styles requiring L/R brace inputs here--//
		if( self.HUDStyle == 1001 ) then
			table.insert(newInputs, "EXIO_LBrace")
			table.insert(newInputTypes, "NORMAL")
			//--table.insert(newInputDesc, "Extended IO - Left brace presence")

			table.insert(newInputs, "EXIO_RBrace")
			table.insert(newInputTypes, "NORMAL")
			//--table.insert(newInputDesc, "Extended IO - Right brace presence")
		end

		if( self.HUDStyle == 1002 ) then
			table.insert(newInputs, "EXIO_Width")
			table.insert(newInputTypes, "NORMAL")
			//--table.insert(newInputDesc, "Extended IO - Width")

			table.insert(newInputs, "EXIO_Height")
			table.insert(newInputTypes, "NORMAL")
			//--table.insert(newInputDesc, "Extended IO - Height")

			table.insert(newInputs, "EXIO_X")
			table.insert(newInputTypes, "NORMAL")
			//--table.insert(newInputDesc, "Extended IO - Internal X Offset")

			table.insert(newInputs, "EXIO_Y")
			table.insert(newInputTypes, "NORMAL")
			//--table.insert(newInputDesc, "Extended IO - Internal Y Offset")
		end

	end

	//--Update the SENT--//
	//--Wire_AdjustInputs(self, newInputs)
	WireLib.AdjustSpecialInputs(self, newInputs, newInputTypes, newInputDesc)

	for k,inputName in pairs(newInputs) do
		if( inputName == "Value" ) then self:TriggerInput("Value", self.A)
		elseif( inputName == "HideHUD" ) then self:TriggerInput("HideHUD", 0)
		elseif( inputName == "WorldX" ) then self:TriggerInput("WorldX", self.world_x)
		elseif( inputName == "WorldY" ) then self:TriggerInput("WorldY", self.world_y)
		elseif( inputName == "WorldZ" ) then self:TriggerInput("WorldZ", self.world_z)
		elseif( inputName == "ScreenX" ) then self:TriggerInput("ScreenX", self.xPos)
		elseif( inputName == "ScreenY" ) then self:TriggerInput("ScreenY", self.yPos)
		elseif( inputName == "DisplayText" ) then self:TriggerInput("DisplayText", self.displayText)
		elseif( inputName == "WorldEndX" ) then self:TriggerInput("WorldEndX", self.world_end_x)
		elseif( inputName == "WorldEndY" ) then self:TriggerInput("WorldEndY", self.world_end_y)
		elseif( inputName == "WorldEndZ" ) then self:TriggerInput("WorldEndZ", self.world_end_z)
		elseif( inputName == "EndX" ) then self:TriggerInput("EndX", self.xEnd)
		elseif( inputName == "EndY" ) then self:TriggerInput("EndY", self.yEnd)
		elseif( inputName == "EXIO_Width" ) then self:TriggerInput("EXIO_Width", self.EXIO_width)
		elseif( inputName == "EXIO_Height" ) then self:TriggerInput("EXIO_Height", self.EXIO_height)
		elseif( inputName == "EXIO_X" ) then self:TriggerInput("EXIO_X", self.EXIO_x)
		elseif( inputName == "EXIO_Y" ) then self:TriggerInput("EXIO_Y", self.EXIO_x)
		elseif( inputName == "EXIO_Size" ) then self:TriggerInput("EXIO_Size", self.EXIO_size)
		end
	end

end

util.AddNetworkString("AdvHUDIndicatorStylePercent")
util.AddNetworkString("AdvHUDIndicatorRegister")
// This is called from RegisterPlayer to send any style-specific info
function ENT:SetupHUDStyle(hudstyle, rplayer)
	// 0 (Basic) and 1 (Gradient) don't require any extra info
	local pl = rplayer or self:GetPlayer()
	// Allow for hooked players
	//if (rplayer) then pl = rplayer end

	// Send as string (there should be a way to send colors)
	local ainfo = self.AR.."|"..self.AG.."|"..self.AB
	local binfo = self.BR.."|"..self.BG.."|"..self.BB
	net.Start("AdvHUDIndicatorStylePercent")
		net.WriteInt(self:EntIndex(), 16)
		net.WriteString(ainfo)
		net.WriteString(binfo)
	net.Send(pl)
end

// Hook this player to the HUD Indicator
function ENT:RegisterPlayer(ply, hookhidehud, podonly)
	local plyuid = ply:UniqueID()
	local eindex = self:EntIndex()


	//--Flag Options--//
	local flag_worldcoords = 1
	/*local flag_alphainput = 2
	local flag_position_by_pixel = 4
	local flag_position_by_percent = 8
	local flag_position_by_decimal = 16
	local flag_string_input = 32
	local flag_vector_inputs = 64*/


	// If player is already registered, this will send an update
	// The podonly is used for players who are registered only because they are in a linked pod
	if (!self.RegisteredPlayers[plyuid]) then
		self.RegisteredPlayers[plyuid] = { ply = ply, hookhidehud = hookhidehud, podonly = podonly }
		// This is used to check for pod-only status in ClientCheckRegister()
		self:SetNWBool( plyuid, tobool(podonly) )
	end

	net.Start("AdvHUDIndicatorRegister")
		net.WriteInt(eindex, 16)
		net.WriteString(self.HUDDesc or "")
		net.WriteInt(self.HUDShowValue, 16)
		net.WriteInt(self.HUDStyle, 16)

		//--Position style, tacked on the end of the end - Moggie100--//
		net.WriteInt( self.positionMethod , 16)

		if( bit.band( self.flags, flag_worldcoords ) == flag_worldcoords ) then

			//--Set the 3D position number--//
			net.WriteInt( 1 , 16);

			//--Start XYZ position data--//
			net.WriteFloat( self.world_x )
			net.WriteFloat( self.world_y )
			net.WriteFloat( self.world_z )

			//--End XYZ position data--//
			net.WriteFloat( self.world_end_x )
			net.WriteFloat( self.world_end_y )
			net.WriteFloat( self.world_end_z )
		else

			//--Set the 2D position number--//
			net.WriteInt( 0 , 16);

			//--Position data, tacked on the end. - Moggie100--//
			net.WriteFloat(self.xPos)
			net.WriteFloat(self.yPos)

			//--End XY Position--//
			net.WriteFloat( self.xEnd )
			net.WriteFloat( self.yEnd )
		end

		//--Display text--//
		net.WriteString( self.displayText )

	net.Send(ply)
	self:SetupHUDStyle(self.HUDStyle, ply)

	// Trigger inputs to fully add this player to the list
	// Force factor to update
	self.PrevOutput = nil

end

function ENT:UnRegisterPlayer(ply)
	if IsValid(ply) then
		net.Start("AdvHUDIndicatorUnRegister")
			net.WriteInt(self:EntIndex(), 16)
		net.Send(ply)
	end
	self.RegisteredPlayers[ply:UniqueID()] = nil
end

// Is this player registered?
function ENT:CheckRegister(ply)
	return self.RegisteredPlayers[ply:UniqueID()] != nil
end

// Is this player registered only because he is in a linked pod?
function ENT:CheckPodOnly(ply)
	if IsValid(ply) then
		local plyuid = ply:UniqueID()
		return self.RegisteredPlayers[plyuid] != nil && self.RegisteredPlayers[plyuid].podonly
	end
	return false
end

function ENT:TriggerInput(iname, value)
	local pl = self:GetPlayer()

	local force_position_update = 0

	if (iname == "A") then
		local factor = math.Clamp((value-self.A)/(self.B-self.A), 0, 1)
		self:ShowOutput(factor, value)

		//--local r = math.Clamp((self.BR-self.AR)*factor+self.AR, 0, 255)
		//--local g = math.Clamp((self.BG-self.AG)*factor+self.AG, 0, 255)
		//--local b = math.Clamp((self.BB-self.AB)*factor+self.AB, 0, 255)
		//--local a = math.Clamp((self.BA-self.AA)*factor+self.AA, 0, 255)
		//--self:SetColor(r, g, b, a)
		self:SetColor(Color(255, 255, 255, 255))
	elseif (iname == "HideHUD") then
		if (self.PrevHideHUD == (value > 0)) then return end

		self.PrevHideHUD = (value > 0)
		// Value has updated, so send information
		self:SendHUDInfo(self.PrevHideHUD)

	//The screen X and Y position, as changed by wire inputs.
	elseif (iname == "ScreenX") then
		self.xPos = value
		force_position_update = 1

	elseif (iname == "ScreenY") then
		self.yPos = value
		force_position_update = 1

	elseif (iname == "ScreenPos") then
		self.xPos = value[1]
		self.yPos = value[2]
		force_position_update = 1

	//The screen X and Y position, as changed by wire inputs.
	elseif (iname == "EndX") then
		self.xEnd = value
		force_position_update = 3

	elseif (iname == "EndY") then
		self.yEnd = value
		force_position_update = 3

	elseif (iname == "EndPos") then
		self.xEnd = value[1]
		self.yEnd = value[2]
		force_position_update = 3


	elseif (iname == "WorldX") then
		self.world_x = value
		force_position_update = 2

	elseif (iname == "WorldY") then
		self.world_y = value
		force_position_update = 2

	elseif (iname == "WorldZ") then
		self.world_z = value
		force_position_update = 2

	elseif (iname == "WorldPos") then
		self.world_x = value[1]
		self.world_y = value[2]
		self.world_z = value[3]
		force_position_update = 2

	elseif (iname == "WorldEndX") then
		self.world_end_x = value
		force_position_update = 4

	elseif (iname == "WorldEndY") then
		self.world_end_y = value
		force_position_update = 4

	elseif (iname == "WorldEndZ") then
		self.world_end_z = value
		force_position_update = 4

	elseif (iname == "WorldEndPos") then
		self.world_end_x = value[1]
		self.world_end_y = value[2]
		self.world_end_z = value[3]
		force_position_update = 4


	//--BETA! String input for text control--//
	elseif (iname == "DisplayText") then
		self.displayText = value

		//-- Iterate the players table and update them all --//
		for index,rplayer in pairs(self.RegisteredPlayers) do
			if IsValid(rplayer.ply) then
				if (rplayer.ply != pl || (self.ShowInHUD || self.PodPly == pl)) then
					//--Build a new usermessage to update the position
					net.Start("AdvHUDIndicator_STRING")
						net.WriteInt(self:EntIndex(), 16)	//--Entity inded
						net.WriteString( self.displayText )				//-- The new string to set --//
					net.Send(rplayer.ply)								//--Send message
				end
			else
				self.RegisteredPlayers[index] = nil
			end
		end


	end


	//------------------//
	//-- Extended I/O --//
	//------------------//
	local EXIO_update = 0
	local EXIO_value = 0
	if (iname == "Size") then				//-- 0 - Size update --//
		self.EXIO_size = value
		EXIO_value = value
		EXIO_update = 1

	elseif( iname == "EXIO_LBrace") then		//-- 1 - lBrace update --//
		EXIO_value = value
		EXIO_update = 2

	elseif( iname == "EXIO_RBrace") then		//-- 2 - rBrace update --//
		EXIO_value = value
		EXIO_update = 3

	elseif( iname == "EXIO_Width" ) then
		self.EXIO_width = value
		EXIO_value = value
		EXIO_update = 4

	elseif( iname == "EXIO_Height" ) then
		self.EXIO_height = value
		EXIO_value = value
		EXIO_update = 5

	elseif( iname == "EXIO_X" ) then
		self.EXIO_x = value
		EXIO_value = value
		EXIO_update = 6

	elseif( iname == "EXIO_Y" ) then
		self.EXIO_y = value
		EXIO_value = value
		EXIO_update = 7

	end

	//-- If we get an extended IO update, then inform players --//
	if ( EXIO_update > 0 ) then

		//-- Iterate the players table and update them all --//
		for index,rplayer in pairs(self.RegisteredPlayers) do
			if IsValid(rplayer.ply) then
				if (rplayer.ply != pl || (self.ShowInHUD || self.PodPly == pl)) then
					//--Build a new usermessage to update the position
					net.Start("AdvHUDIndicator_EXIO")
						net.WriteInt(self:EntIndex(), 16)	//--Entity index
						net.WriteInt( EXIO_update , 16)			//-- The variable to update --//
						net.WriteFloat( EXIO_value )			//-- The value to set --//
					net.Send(rplayer.ply)								//--Send message
				end
			else
				self.RegisteredPlayers[index] = nil
			end
		end

	end


	//--Position updates
	if( force_position_update > 0 ) then


		//-- If we get a force position update of '2' then its a world position that needs translating...
		if( force_position_update == 4 ) then

			for index,rplayer in pairs(self.RegisteredPlayers) do
				if IsValid(rplayer.ply) then
					if (rplayer.ply != pl || (self.ShowInHUD || self.PodPly == pl)) then
						//--Build a new usermessage to update the position
						net.Start("AdvHUDIndicatorUpdate3DPositionTwo")
							net.WriteInt(self:EntIndex(), 16)	//--Entity index
							net.WriteFloat( self.world_end_x )				//--X Position update
							net.WriteFloat( self.world_end_y )				//--Y Position update
							net.WriteFloat( self.world_end_z )				//--Z Position update
						net.Send(rplayer.ply)								//--Send message
					end
				else
					self.RegisteredPlayers[index] = nil
				end
			end
		elseif( force_position_update == 3 ) then

			for index,rplayer in pairs(self.RegisteredPlayers) do
				if IsValid(rplayer.ply) then
					if (rplayer.ply != pl || (self.ShowInHUD || self.PodPly == pl)) then
						//--Build a new usermessage to update the position
						net.Start("AdvHUDIndicatorUpdatePositionTwo")
							net.WriteInt(self:EntIndex(), 16)	//--Entity index
							net.WriteFloat( self.xEnd )				//--X Position update
							net.WriteFloat( self.yEnd )				//--Y Position update
							net.WriteInt( self.positionMethod , 16)	//--The method to position the indicator with.
						net.Send(rplayer.ply)								//--Send message
					end
				else
					self.RegisteredPlayers[index] = nil
				end
			end

		elseif( force_position_update == 2 ) then

			for index,rplayer in pairs(self.RegisteredPlayers) do
				if IsValid(rplayer.ply) then
					if (rplayer.ply != pl || (self.ShowInHUD || self.PodPly == pl)) then
						//--Build a new usermessage to update the position
						net.Start("AdvHUDIndicatorUpdate3DPosition")
							net.WriteInt(self:EntIndex(), 16)	//--Entity index
							net.WriteFloat( self.world_x )				//--X Position update
							net.WriteFloat( self.world_y )				//--Y Position update
							net.WriteFloat( self.world_z )				//--Z Position update
						net.Send(rplayer.ply)								//--Send message
					end
				else
					self.RegisteredPlayers[index] = nil
				end
			end

		elseif( force_position_update == 1 ) then

			for index,rplayer in pairs(self.RegisteredPlayers) do
				if IsValid(rplayer.ply) then
					if (rplayer.ply != pl || (self.ShowInHUD || self.PodPly == pl)) then
						//--Build a new usermessage to update the position
						net.Start("AdvHUDIndicatorUpdatePosition")
							net.WriteInt(self:EntIndex(), 16)	//--Entity index
							net.WriteFloat( self.xPos )				//--X Position update
							net.WriteFloat( self.yPos )				//--Y Position update
							net.WriteInt( self.positionMethod , 16)	//--The method to position the indicator with.
						net.Send(rplayer.ply)								//--Send message
					end
				else
					self.RegisteredPlayers[index] = nil
				end
			end

		end
	end


end

function ENT:ShowOutput(factor, value)
	if (factor ~= self.PrevOutput) then
		self:SetOverlayText( self.PrefixText .. string.format("%.1f", factor * 100) .. "%" )
		self.PrevOutput = factor

		local rf = RecipientFilter()
		local pl = self:GetPlayer()

		// RecipientFilter will contain all registered players
		for index,rplayer in pairs(self.RegisteredPlayers) do
			if IsValid(rplayer.ply) then
				if (rplayer.ply != pl || (self.ShowInHUD || self.PodPly == pl)) then
					rf:AddPlayer(rplayer.ply)
				end
			else
				self.RegisteredPlayers[index] = nil
			end
		end

		net.Start("AdvHUDIndicatorFactor")
			net.WriteInt(self:EntIndex(), 16)
			// Send both to ensure that all styles work properly
			net.WriteFloat(factor)
			net.WriteFloat(value)
		net.Send(rf)
	end
end

function ENT:SendHUDInfo(hidehud)
	// Sends information to player
	local pl = self:GetPlayer()

	for index,rplayer in pairs(self.RegisteredPlayers) do
		if IsValid(rplayer.ply) then
			if (rplayer.ply != pl || (self.ShowInHUD || self.PodPly == pl)) then
				net.Start("AdvHUDIndicatorHideHUD")
					net.WriteInt(self:EntIndex(), 16)
					// Check player's preference
					if (rplayer.hookhidehud) then
						net.WriteBool(hidehud)
					else
						net.WriteBool(false)
					end
				net.Send(rplayer.ply)
			end
		else
			self.RegisteredPlayers[index] = nil
		end
	end
end

// Despite everything being named "pod", any vehicle will work
function ENT:LinkVehicle(pod)
	if !IsValid(pod) or !string.find(pod:GetClass(), "prop_vehicle_") then return false end

	local ply = nil
	// Check if a player is in pod first
	for k,v in pairs(player.GetAll()) do
		if (v:GetVehicle() == pod) then
			ply = v
			break
		end
	end

	if IsValid(ply) and !self:CheckRegister(ply) then
		// Register as "only in pod" if not registered before
		self:RegisterPlayer(ply, false, true)

		// Force factor to update
		self.PrevOutput = nil
		self:TriggerInput("A", self.Inputs.A.Value)
	end
	self.Pod = pod
	self.PodPly = ply

	return true
end

function ENT:UnLinkVehicle()
	local ply = self.PodPly

	if IsValid(ply) and self:CheckPodOnly(ply) then
		// Only unregister if player is registered only because he is in a linked pod
		self:UnRegisterPlayer(ply)
	end
	self.Pod = nil
	self.PodPly = nil
end

function ENT:Think()
	self.BaseClass.Think(self)

	if IsValid(self.Pod) then
		local ply = nil

		if !IsValid(self.PodPly) or self.PodPly:GetVehicle() != self.Pod then
			for k,v in pairs(player.GetAll()) do
				if (v:GetVehicle() == self.Pod) then
					ply = v
					break
				end
			end
		else
			ply = self.PodPly
		end

		// Has the player changed?
		if (ply != self.PodPly) then
			if self.PodPly and self:CheckPodOnly(self.PodPly) then // Don't send umsg if player disconnected or is registered otherwise
				self:UnRegisterPlayer(self.PodPly)
			end

			self.PodPly = ply

			if IsValid(self.PodPly) and self.PodPly and !self:CheckRegister(self.PodPly) then
				self:RegisterPlayer(self.PodPly, false, true)
			end
		end
	else
		// If we deleted this pod and there was a player in it
		if self.PodPly and self:CheckPodOnly(self.PodPly) then
			self:UnRegisterPlayer(self.PodPly)
		end
		self.PodPly = nil
	end

	self:NextThink(CurTime() + 0.025)
	return true
end

// Advanced Duplicator Support
function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}

	if IsValid(self.Pod) then
	    info.pod = self.Pod:EntIndex()
	end

	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	if (info.pod) then
		self.Pod = GetEntByID(info.pod)
		if (!self.Pod) then
			self.Pod = ents.GetByIndex(info.pod)
		end
	end
end

