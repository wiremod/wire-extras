
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Adv. HUD Indicator"

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )

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
	
	//Angular Inputs
	self.pitch = 0
	self.yaw = 0
	self.roll = 0
	
	//--additional flags
	self.flags = 0

	//The method to use when positioning the indicators
	self.positionMethod = 0

	// List of players who have hooked this indicator
	self.RegisteredPlayers = {}
	self.PrefixText = "Adv. Hud: "
	
	self.Inputs = Wire_CreateInputs(self.Entity, { "A", "HideHUD", "ScreenX", "ScreenY" })
	
end

function ENT:Setup(a, ar, ag, ab, aa, b, br, bg, bb, ba, positionMethod)
	
	if( useWorldCoords == nil ) then
		Msg("World coordinates was NIL, so set it to zero\n")
		local useWorldCoords = 0
	end
	
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
	
	self.positionMethod = positionMethod
	
	//--if( useWorldCoords == 1 ) then
	//--	self.Inputs = Wire_AdjustInputs(self.Entity, { "A", "HideHUD", "WorldX", "WorldY", "WorldZ", "Alpha" })
	//--	self:TriggerInput("A", 0)
	//--	self:TriggerInput("HideHUD", 0)
	//--	self:TriggerInput("WorldX", 0)
	//--	self:TriggerInput("WorldY", 0)
	//--	self:TriggerInput("WorldZ", 0)
	//--	self:TriggerInput("Alpha", 255)
	//--else
	//--	self.Inputs = Wire_AdjustInputs(self, { "A", "HideHUD", "ScreenX", "ScreenY", "Alpha" })
	//--	self:TriggerInput("A", 0)
	//--	self:TriggerInput("HideHUD", 0)
	//--	self:TriggerInput("ScreenX", 22)
	//--	self:TriggerInput("ScreenY", 200)
	//--	self:TriggerInput("Alpha", 255)
	//--end
	
end

// For HUD Indicators
function ENT:HUDSetup(showinhud, huddesc, hudaddname, hudshowvalue, hudstyle, allowhook, fullcircleangle, xPosNew, yPosNew, flags)

	local ply = self:GetPlayer()
	local eindex = self.Entity:EntIndex()
	
	// If user updates with the STool to take indicator off of HUD
	if (!showinhud && self.ShowInHUD) then
		self:UnRegisterPlayer(ply)
	
		// Adjust inputs back to normal
		//Wire_AdjustInputs(self.Entity, { "A" })
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
			self.Entity:SetNetworkedString("WireName", huddesc)
		elseif (self.Entity:GetNetworkedString("WireName") == huddesc) then
			// Only remove it if the HUD Description was there
			// because there might be another name on it
			self.Entity:SetNetworkedString("WireName", "")
		end

	end
	
	self.ShowInHUD = showinhud
	self.HUDDesc = huddesc
	self.HUDAddName = hudaddname
	self.HUDShowValue = hudshowvalue
	self.HUDStyle = hudstyle
	self.AllowHook = allowhook
	self.FullCircleAngle = fullcircleangle
	self.xPos = xPosNew
	self.yPos = yPosNew
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
	local newInputs = { "A", "HideHUD" }
	
	//-- If we're at an index over 999 then its a 3D indicator, so add relavant inputs... --//
	
	if( flags == true ) then flags = 1 end
	if( flags == false ) then flags = 0 end
	
	if( flags != nil ) then
		Msg( "Flags: " ..flags.. "\n" )
		if( flags & 1 == 1 ) then
			table.insert(newInputs, "WorldX")
			table.insert(newInputs, "WorldY")
			table.insert(newInputs, "WorldZ")
		else
			table.insert(newInputs, "ScreenX")
			table.insert(newInputs, "ScreenY")
		end
		
		if( flags & 2 == 2 ) then
			table.insert(newInputs, "Alpha")
		end
	else
		Msg("NIL Flags?!?\n")
	end
	
	Msg( "HUD Style: " ..self.HUDStyle.. "\n" )
	
	//-- If we are drawing a 2-point object, then 
	if( self.HUDStyle > 199 && self.HUDStyle < 999 ) then
		//-- If we're drawing in 3D mode... --//
		if( flags & 1 == 1 ) then
			table.insert(newInputs, "WorldEndX")
			table.insert(newInputs, "WorldEndY")
			table.insert(newInputs, "WorldEndZ")
		else
			table.insert(newInputs, "EndX")
			table.insert(newInputs, "EndY")
		end
	end
	
	//-------------------//
	//-- [Extended I/O --//
	//-------------------//
	if( self.HUDStyle > 999 ) then
	
		//--Add the styles requiring a size input here--//
		if( self.HUDStyle == 1000 ) then
			table.insert(newInputs, "EXIO_Size")
		end
		
		//--Add the styles requiring L/R brace inputs here--//
		if( self.HUDStyle == 1001 ) then
			table.insert(newInputs, "EXIO_LBrace")
			table.insert(newInputs, "EXIO_RBrace")
		end
	
	end
	
	
	//--Update the SENT--//
	Wire_AdjustInputs(self.Entity, newInputs)
	
end

// This is called from RegisterPlayer to send any style-specific info
function ENT:SetupHUDStyle(hudstyle, rplayer)
	// 0 (Basic) and 1 (Gradient) don't require any extra info
	local pl = rplayer or self:GetPlayer()
	// Allow for hooked players
	//if (rplayer) then pl = rplayer end

	// Send as string (there should be a way to send colors)
	local ainfo = self.AR.."|"..self.AG.."|"..self.AB
	local binfo = self.BR.."|"..self.BG.."|"..self.BB
	umsg.Start("AdvHUDIndicatorStylePercent", pl)
		umsg.Short(self.Entity:EntIndex())
		umsg.String(ainfo)
		umsg.String(binfo)
	umsg.End()
end

// Hook this player to the HUD Indicator
function ENT:RegisterPlayer(ply, hookhidehud, podonly)
	local plyuid = ply:UniqueID()
	local eindex = self.Entity:EntIndex()

	// If player is already registered, this will send an update
	// The podonly is used for players who are registered only because they are in a linked pod
	if (!self.RegisteredPlayers[plyuid]) then
		self.RegisteredPlayers[plyuid] = { ply = ply, hookhidehud = hookhidehud, podonly = podonly }
		// This is used to check for pod-only status in ClientCheckRegister()
		self.Entity:SetNetworkedBool( plyuid, util.tobool(podonly) )
	end
	
	umsg.Start("AdvHUDIndicatorRegister", ply)
		umsg.Short(eindex)
		umsg.String(self.HUDDesc or "")
		umsg.Short(self.HUDShowValue)
		umsg.Short(self.HUDStyle)
		
		//Position data, tacked on the end. - Moggie100
		umsg.Short(self.xPos)
		umsg.Short(self.yPos)
		
		//Position style, tacked on the end of the end - Moggie100
		umsg.Short( self.positionMethod )
	umsg.End()
	self:SetupHUDStyle(self.HUDStyle, ply)
		
	// Trigger inputs to fully add this player to the list
	// Force factor to update
	self.PrevOutput = nil
	
	//--self:TriggerInput("A", self.Inputs.A.Value)
	//--if (hookhidehud) then
	//--	self:TriggerInput("HideHUD", self.Inputs.HideHUD.Value)
	//--end
end

function ENT:UnRegisterPlayer(ply)
	umsg.Start("AdvHUDIndicatorUnRegister", ply)
		umsg.Short(self.Entity:EntIndex())
	umsg.End()
	self.RegisteredPlayers[ply:UniqueID()] = nil
end

// Is this player registered?
function ENT:CheckRegister(ply)
	return (self.RegisteredPlayers[ply:UniqueID()] != nil)
end

// Is this player registered only because he is in a linked pod?
function ENT:CheckPodOnly(ply)
	local plyuid = ply:UniqueID()
	return (self.RegisteredPlayers[plyuid] != nil && self.RegisteredPlayers[plyuid].podonly)
end

function ENT:TriggerInput(iname, value)
	local pl = self:GetPlayer()
	
	local force_angular_update = false
	self.force_position_update = 0

	if (iname == "A") then
		local factor = math.Clamp((value-self.A)/(self.B-self.A), 0, 1)
		self:ShowOutput(factor, value)

		local r = math.Clamp((self.BR-self.AR)*factor+self.AR, 0, 255)
		local g = math.Clamp((self.BG-self.AG)*factor+self.AG, 0, 255)
		local b = math.Clamp((self.BB-self.AB)*factor+self.AB, 0, 255)
		local a = math.Clamp((self.BA-self.AA)*factor+self.AA, 0, 255)
		self.Entity:SetColor(r, g, b, a)
	elseif (iname == "HideHUD") then
		if (self.PrevHideHUD == (value > 0)) then return end
		
		self.PrevHideHUD = (value > 0)
		// Value has updated, so send information
		self:SendHUDInfo(self.PrevHideHUD)
		
	//The screen X and Y position, as changed by wire inputs.
	elseif (iname == "ScreenX") then
		self.xPos = value
		self.force_position_update = 1
		
	elseif (iname == "ScreenY") then
		self.yPos = value
		self.force_position_update = 1
	
	//The screen X and Y position, as changed by wire inputs.
	elseif (iname == "EndX") then
		self.xEnd = value
		self.force_position_update = 3
		
	elseif (iname == "EndY") then
		self.yEnd = value
		self.force_position_update = 3
		
	
	elseif (iname == "WorldX") then
		self.world_x = value
		self.force_position_update = 2
	
	elseif (iname == "WorldY") then
		self.world_y = value
		self.force_position_update = 2
	
	elseif (iname == "WorldZ") then
		self.world_z = value
		self.force_position_update = 2
	
	elseif (iname == "WorldEndX") then
		self.world_end_x = value
		self.force_position_update = 4
	
	elseif (iname == "WorldEndY") then
		self.world_end_y = value
		self.force_position_update = 4
	
	elseif (iname == "WorldEndZ") then
		self.world_end_z = value
		self.force_position_update = 4
	
	
	elseif (iname == "Pitch") then
		self.pitch = value
		force_angular_update = true
		
	elseif (iname == "Yaw") then
		self.yaw = value
		force_angular_update = true
		
	elseif (iname == "Roll") then
		self.roll = value
		force_angular_update = true
	end
	
	
	//------------------//
	//-- Extended I/O --//
	//------------------//
	local EXIO_update = 0
	local EXIO_value = 0
	if (iname == "EXIO_Size") then				//-- 0 - Size update --//
		EXIO_value = value
		EXIO_update = 1
		
	elseif( iname == "EXIO_LBrace") then		//-- 1 - lBrace update --//
		EXIO_value = value
		EXIO_update = 2
		
	elseif( iname == "EXIO_RBrace") then		//-- 2 - rBrace update --//
		EXIO_value = value
		EXIO_update = 3
		
	end
	
	//-- If we get an extended IO update, then inform players --//
	if ( EXIO_update > 0 ) then
	
		//-- Iterate the players table and update them all --//
		for index,rplayer in pairs(self.RegisteredPlayers) do
			if (rplayer.ply) then
				if (rplayer.ply != pl || (self.ShowInHUD || self.PodPly == pl)) then
					//--Build a new usermessage to update the position
					umsg.Start("AdvHUDIndicator_EXIO", rplayer.ply)
						umsg.Short(self.Entity:EntIndex())	//--Entity index
						umsg.Short( EXIO_update )			//-- The variable to update --//
						umsg.Float( EXIO_value )			//-- The value to set --//
					umsg.End()								//--Send message
				end
			else
				self.RegisteredPlayers[index] = nil
			end
		end
	
	end
	
	if( force_angular_update == true ) then
		for index,rplayer in pairs(self.RegisteredPlayers) do
			if (rplayer.ply) then
				if (rplayer.ply != pl || (self.ShowInHUD || self.PodPly == pl)) then
					//--Build a new usermessage to update the position
					umsg.Start("AdvHUDIndicatorUpdateAngles", rplayer.ply)
						umsg.Short(self.Entity:EntIndex())	//--Entity index
						umsg.Float( self.pitch )			//--Pitch update
						umsg.Float( self.yaw )				//--Yaw update
						umsg.Float( self.roll )				//--Roll update
					umsg.End()								//--Send message
				end
			else
				self.RegisteredPlayers[index] = nil
			end
		end
	end
	
	
	//--Position updates
	if( self.force_position_update > 0 ) then
	
		
		//-- If we get a force position update of '2' then its a world position that needs translating...
		if( self.force_position_update == 4 ) then
			
			for index,rplayer in pairs(self.RegisteredPlayers) do
				if (rplayer.ply) then
					if (rplayer.ply != pl || (self.ShowInHUD || self.PodPly == pl)) then
						//--Build a new usermessage to update the position
						umsg.Start("AdvHUDIndicatorUpdate3DPositionTwo", rplayer.ply)
							umsg.Short(self.Entity:EntIndex())	//--Entity index
							umsg.Float( self.world_end_x )				//--X Position update
							umsg.Float( self.world_end_y )				//--Y Position update
							umsg.Float( self.world_end_z )				//--Z Position update
						umsg.End()								//--Send message
					end
				else
					self.RegisteredPlayers[index] = nil
				end
			end
		elseif( self.force_position_update == 3 ) then
			
			for index,rplayer in pairs(self.RegisteredPlayers) do
				if (rplayer.ply) then
					if (rplayer.ply != pl || (self.ShowInHUD || self.PodPly == pl)) then
						//--Build a new usermessage to update the position
						umsg.Start("AdvHUDIndicatorUpdatePositionTwo", rplayer.ply)
							umsg.Short(self.Entity:EntIndex())	//--Entity index
							umsg.Float( self.xEnd )				//--X Position update
							umsg.Float( self.yEnd )				//--Y Position update
							umsg.Short( self.positionMethod )	//--The method to position the indicator with.
						umsg.End()								//--Send message
					end
				else
					self.RegisteredPlayers[index] = nil
				end
			end
			
		elseif( self.force_position_update == 2 ) then
			
			for index,rplayer in pairs(self.RegisteredPlayers) do
				if (rplayer.ply) then
					if (rplayer.ply != pl || (self.ShowInHUD || self.PodPly == pl)) then
						//--Build a new usermessage to update the position
						umsg.Start("AdvHUDIndicatorUpdate3DPosition", rplayer.ply)
							umsg.Short(self.Entity:EntIndex())	//--Entity index
							umsg.Float( self.world_x )				//--X Position update
							umsg.Float( self.world_y )				//--Y Position update
							umsg.Float( self.world_z )				//--Z Position update
						umsg.End()								//--Send message
					end
				else
					self.RegisteredPlayers[index] = nil
				end
			end
			
		elseif( self.force_position_update == 1 ) then
			for index,rplayer in pairs(self.RegisteredPlayers) do
				if (rplayer.ply) then
					if (rplayer.ply != pl || (self.ShowInHUD || self.PodPly == pl)) then
						//--Build a new usermessage to update the position
						umsg.Start("AdvHUDIndicatorUpdatePosition", rplayer.ply)
							umsg.Short(self.Entity:EntIndex())	//--Entity index
							umsg.Float( self.xPos )				//--X Position update
							umsg.Float( self.yPos )				//--Y Position update
							umsg.Short( self.positionMethod )	//--The method to position the indicator with.
						umsg.End()								//--Send message
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
		self:SetOverlayText( self.PrefixText .. string.format("%.1f", (factor * 100)) .. "%" )
		self.PrevOutput = factor
		
		local rf = RecipientFilter()
		local pl = self:GetPlayer()
		
		// RecipientFilter will contain all registered players
		for index,rplayer in pairs(self.RegisteredPlayers) do
			if (rplayer.ply) then
				if (rplayer.ply != pl || (self.ShowInHUD || self.PodPly == pl)) then
					rf:AddPlayer(rplayer.ply)
				end
			else
				self.RegisteredPlayers[index] = nil
			end
		end
		
		umsg.Start("AdvHUDIndicatorFactor", rf)
			umsg.Short(self.Entity:EntIndex())
			// Send both to ensure that all styles work properly
			umsg.Float(factor)
			umsg.Float(value)
		umsg.End()
	end
end

function ENT:SendHUDInfo(hidehud)
	// Sends information to player
	local pl = self:GetPlayer()
	
	for index,rplayer in pairs(self.RegisteredPlayers) do
		if (rplayer.ply) then
			if (rplayer.ply != pl || (self.ShowInHUD || self.PodPly == pl)) then
				umsg.Start("AdvHUDIndicatorHideHUD", rplayer.ply)
					umsg.Short(self.Entity:EntIndex())
					// Check player's preference
					if (rplayer.hookhidehud) then
						umsg.Bool(hidehud)
					else
						umsg.Bool(false)
					end
				umsg.End()
			end
		else
			self.RegisteredPlayers[index] = nil
		end
	end
end

// Despite everything being named "pod", any vehicle will work
function ENT:LinkVehicle(pod)
	if (!pod || !pod:IsValid() || !string.find(pod:GetClass(), "prop_vehicle_")) then return false end
	
	local ply = nil
	// Check if a player is in pod first
	for k,v in pairs(player.GetAll()) do
		if (v:GetVehicle() == pod) then
			ply = v
			break
		end
	end
	
	if (ply && !self:CheckRegister(ply)) then
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

	if (ply && self:CheckPodOnly(ply)) then
		// Only unregister if player is registered only because he is in a linked pod
		self:UnRegisterPlayer(ply)
	end
	self.Pod = nil
	self.PodPly = nil
end

function ENT:Think()
	self.BaseClass.Think(self)
	
	if (self.Pod && self.Pod:IsValid()) then
		local ply = nil
		
		if (!self.PodPly || self.PodPly:GetVehicle() != self.Pod) then
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
			if (self.PodPly && self:CheckPodOnly(self.PodPly)) then // Don't send umsg if player disconnected or is registered otherwise
				self:UnRegisterPlayer(self.PodPly)
			end
			
			self.PodPly = ply
			
			if (self.PodPly && !self:CheckRegister(self.PodPly)) then
				self:RegisterPlayer(self.PodPly, false, true)
				
				// Force factor to update
				self.PrevOutput = nil
				self:TriggerInput("A", self.Inputs.A.Value)
			end
		end
	else
		// If we deleted this pod and there was a player in it
		if (self.PodPly && self:CheckPodOnly(self.PodPly)) then
			self:UnRegisterPlayer(self.PodPly)
		end
		self.PodPly = nil
	end
	
	self.Entity:NextThink(CurTime() + 0.025)
	return true
end

// Advanced Duplicator Support
function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}

	if (self.Pod) and (self.Pod:IsValid()) then
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
