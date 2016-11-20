
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

AddCSLuaFile( "expressions/expr_stack.lua" )
AddCSLuaFile( "expressions/expr_tokenizer.lua" )
AddCSLuaFile( "expressions/libs/corelib.lua" )
AddCSLuaFile( "expressions/libs/logiclib.lua" )
AddCSLuaFile( "expressions/libs/mathlib.lua" )
AddCSLuaFile( "expressions/libs/stringlib.lua" )
AddCSLuaFile( "parser/Constants.lua" )
AddCSLuaFile( "parser/HMLParser.lua" )
AddCSLuaFile( "renderer/HMLRenderer.lua" )
AddCSLuaFile( "renderer/valid_fonts.lua" )
AddCSLuaFile( "renderer/tags/core.lua" )
AddCSLuaFile( "renderer/tags/presets.lua" )
AddCSLuaFile( "renderer/tags/primitives.lua" )
AddCSLuaFile( "renderer/tags/vgui.lua" )
AddCSLuaFile( "util/errors.lua" )
AddCSLuaFile( "util/tables.lua" )
AddCSLuaFile( "H2Editor.lua" )
AddCSLuaFile( "expression_parser.lua" )


util.AddNetworkString( "HMLUpload" )
util.AddNetworkString( "RenderTableUpdate" )

include('shared.lua')
include('util/errors.lua')
include('parser/HMLParser.lua')
include("util/tables.lua")

ENT.WireDebugName = "Wire HUD Indicator 2"

ENT.inputLookup = {}
ENT.RegisteredPlayers = {}
ENT.LoadedCode = ""
ENT.linkedPod = nil
ENT.podPlayer = nil

//--------------------------------------------------------------------------//
//-- Functions below here are not part of the SENT, just serverside calls --//
//--------------------------------------------------------------------------//

net.Receive( "HMLUpload", function( len, ply )
	print( "Received data on server: " );

	local tbl = net.ReadTable()
	if( len <= 0 or tbl == nil or tbl.eindex == nil ) then return false end

	local sent = ents.GetByIndex( tbl.eindex )

	sent:ReloadCode( tbl.code )

	print( "OK!" )
end )


//--------------------------------------------------------------------------//
//-- The entity functions proper...                                       --//
//--------------------------------------------------------------------------//

function ENT:Initialize()
	self.Entity:SetModel( "models/jaanus/wiretool/wiretool_siren.mdl" )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self:SetOverlayText( "Adv. HUD Indicator 2" )

	//-- This causes wirelib to set up the required tables for this SENT, required before any
	//-- other call to wire I/O, lest a nil pointer error occur.
	self.Inputs = Wire_CreateInputs(self.Entity, {})


	lookupTable = {}

	//-- Rebuild the wire inputs--//
	self:BuildInputs( lookupTable )

end

//-- Builds the inputs for this SENT, can be called at any time!
//--
//-- Note: this function also resets the input values on NEW input pins.
function ENT:BuildInputs( newInputLookup )
	local newInputs = {}
	local newInputTypes = {}
	local newInputDesc = {}

	//-- Possible types for the following table... --//
	//--
	//-- WireLib.DT = {
	//-- 	NORMAL = {},	-- Numbers
	//-- 	VECTOR = {},
	//-- 	ANGLE = {},
	//-- 	COLOR = {},
	//-- 	ENTITY = {},
	//-- 	STRING = {},
	//-- 	TABLE = {},
	//-- 	BIDIRTABLE = {},
	//-- 	ANY = {},
	//-- 	HOVERDATAPORT = {},
	//-- }

	--Iterate the newInputLookup table for inputs and generate the correct inputs...
	for k,v in pairs(newInputLookup) do
		table.insert(newInputs, k)

		--Normal numbers
		if ( v.type == "numeric" ) then
			table.insert(newInputTypes, "NORMAL")
			v.value = v.value or 0

		--Strings
		elseif ( v.type == "string" ) then
			table.insert(newInputTypes, "STRING")
			v.value = v.value or ""

		--Color
		elseif ( v.type == "color" ) then
			table.insert(newInputTypes, "VECTOR")
			v.value = v.value or { x=0, y=0, z=0 }

		--Color + ALPHA
		elseif ( v.type == "alpha_color" ) then
			table.insert(newInputTypes, "VECTOR4")
			v.value = v.value or { x=0, y=0, z=0, w=0 }

		--Vector 2D
		elseif ( v.type == "vector2" ) then
			table.insert(newInputTypes, "VECTOR2")
			v.value = v.value or { x=0, y=0 }

		--Vector 3D
		elseif ( v.type == "vector3" ) then
			table.insert(newInputTypes, "VECTOR")
			v.value = v.value or { x=0, y=0, z=0 }
		
		--Vector 4D
		elseif ( v.type == "vector4" ) then
			table.insert(newInputTypes, "VECTOR4")
			v.value = v.value or { x=0, y=0, z=0, w=0 }

		--Everything else, at the moment anyhow, as nothing supports COLOR type, etc.
		else
			print("[WW]", "Unknown input type! Possibly parser/renderer version mismatch!")
			print("[WW]", "Update your SVN(s)!")
			
			print("[DBG]", v.type )

		end
	end
	
	--Hook our input lookup table up to the new input lookup
	self.inputLookup = newInputLookup

	--Finally adjust the inputs on the SENT itself.
	WireLib.AdjustSpecialInputs(self.Entity, newInputs, newInputTypes, newInputDesc)
end


function ENT:LinkVehicle( entity )
	self.linkedPod = entity
	
	return true
end

function ENT:UnLinkVehicle()
	self.linkedPod = nil
	
	return true
end


--Hook OnRemove just so we can unhook players from the SENT.
function ENT:OnRemove()

	for id, data in pairs(self.RegisteredPlayers) do
		self:UnregisterPlayer( data.ply )
	end

end

function ENT:ToggleHooked( player )
	local id = player:UniqueID()

	if( self.RegisteredPlayers[id] ) then
		self:UnregisterPlayer( player )
	else
		self:RegisterPlayer( player )
	end

	for id, data in pairs( self.RegisteredPlayers ) do
		print( id, "= {", data, "}" )
	end

end

function ENT:RegisterPlayer( player, dataTable )
	if( player == nil or !player:IsPlayer() ) then return false end
	local id = player:UniqueID()
	self.RegisteredPlayers[id] = { ply = player }

	umsg.Start("HUD2_SYNC", player)
		umsg.Short( self.Entity:EntIndex() )
	umsg.End()

	if( self.LoadedCode != "" ) then
		--Generate a send buffer for the code to download...
		codeBuffer = { 	table = dataTable or HMLParser:new( self.LoadedCode ):exec(),
						eindex = self:EntIndex() }

		--Send to the newly hooked player
		net.Start( "RenderTableUpdate" )
			net.WriteTable( codeBuffer )
		net.Send( player )

		print( "[II] Sent render table..." )
	else
		print( "[II] No code to parse! Did nothing but registration!" )
	end

	return true
end

function ENT:UnregisterPlayer( player )
	if( !player or !player:IsPlayer() ) then return false end
	local id = player:UniqueID()
	
	umsg.Start( "HUD2_UNREG", self.RegisteredPlayers[id].ply )
		//-- Entity index, so the client can look up which table to change
		umsg.Short( self.Entity:EntIndex() )
	umsg.End()

	if( self.RegisteredPlayers[id] ) then self.RegisteredPlayers[id] = nil end

	return true
end



function ENT:ReloadCode( newCode )
	self.LoadedCode = newCode
	local parser = HMLParser:new( self.LoadedCode )
	local renderTable = parser:exec()

	self:BuildInputs( parser:getInputTable() )

	print( "Reloaded with: ", self.LoadedCode )

	//-- By re-registering hooked players, we push a code update to their clients. --//
	for index,rplayer in pairs(self.RegisteredPlayers) do
		if (rplayer.ply) then
			self:RegisterPlayer( Entity(index), renderTable )
		else
			self.RegisteredPlayers[index] = nil
		end
	end
end

function ENT:Think()
	self.BaseClass.Think(self)
	
	if( self.linkedPod ) then
		--Check if the pod is still valid (present)
		if( self.linkedPod and self.linkedPod:IsValid() ) then
			local driver = self.linkedPod:GetDriver()
			
			--Check the player is valid
			if( driver == nil or !driver or !driver:IsPlayer() ) then
			
				if( self.podPlayer ) then
					self:UnregisterPlayer( self.podPlayer )
				end
				
				self.podPlayer = nil
				
			else
				--Check if the player has changed... (includes just getting out!)
				if( self.podPlayer != driver ) then
					print("", "", "Player change!!", tostring(self.podPlayer), tostring(driver) )
					
					self:RegisterPlayer( driver )
					
					if( self.podPlayer ) then
						self:UnregisterPlayer( self.podPlayer )
					end
					
					self.podPlayer = driver
				end
			end
			
		
		end
	else
		--The pod's gone! But someone was in it! Unlink!
		if( self.podPlayer != player ) then
			if( self.podPlayer ) then self.UnregisterPlayer( self.podPlayer ) end
		end
		
	end
	
	--Set ourselves to think again!
	self.Entity:NextThink(CurTime() + 0.1)
end



function ENT:TriggerInput(iname, value)
	local pl = self:GetPlayer()

	local NORMAL = 0
	local STRING = 1
	local COLOR = 2
	local COLOR_ALPHA = 3
	local VECTOR2 = 4
	local VECTOR3 = 5
	local VECTOR4 = 6
	
	//-- If we have this input (should always, but incase weirdness happens... --//
	if( self.inputLookup[iname] != nil ) then

		//-- Only update the table and the clients if stuff changes! else UBER LAG! --//
		if ( self.inputLookup[iname].value != value ) then
			self.inputLookup[iname].value = value

			//-- Iterate the players table and update them all --//
			for index,rplayer in pairs(self.RegisteredPlayers) do
				if (rplayer.ply) then

					//-- BUild a new umsg for this player
					umsg.Start("HUD2_SYNC", rplayer.ply)

						//-- Entity index, so the client can look up which table to change
						umsg.Short( self.Entity:EntIndex() )

						//-- The input name
						umsg.String( iname )

						//-- The input type, so we can correctly read the input
						if( self.inputLookup[iname].type == "numeric" ) then
							umsg.Short( NORMAL )	//-- The type
							umsg.Float( value )		//-- The value

						elseif( self.inputLookup[iname].type == "string" ) then
							umsg.Short( STRING )	//-- The type
							umsg.String( value )	//-- The value

						elseif( self.inputLookup[iname].type == "color" ) then
							umsg.Short( COLOR )		//-- The type
							umsg.Short( value.x )	//-- Data
							umsg.Short( value.y )
							umsg.Short( value.z )

						elseif( self.inputLookup[iname].type == "alpha_color" ) then
							umsg.Short( COLOR_ALPHA )	//-- The type
							umsg.Short( value[1] )		//-- Data
							umsg.Short( value[2] )
							umsg.Short( value[3] )
							umsg.Short( value[4] )

						elseif( self.inputLookup[iname].type == "vector2" ) then
							umsg.Short( VECTOR2 )	//-- The type
							umsg.Float( value[1] )	//-- Data
							umsg.Float( value[2] )

						elseif( self.inputLookup[iname].type == "vector3" ) then
							umsg.Short( VECTOR3 )	//-- The type
							--umsg.Float( value.x )	//-- Data
							--umsg.Float( value.y )
							--umsg.Float( value.z )
							umsg.Vector( value )

						elseif( self.inputLookup[iname].type == "vector4" ) then
							umsg.Short( VECTOR4 )	//-- The type
							umsg.Float( value[1] )	//-- Data
							umsg.Float( value[2] )
							umsg.Float( value[3] )
							umsg.Float( value[4] )

						end

					//--Send message
					umsg.End()
				else
					self.RegisteredPlayers[index] = nil
				end
			end
		end

	else
		print("[WW] We got an input via an unknown pin... wtf?")
		return false
	end

	return true
end
