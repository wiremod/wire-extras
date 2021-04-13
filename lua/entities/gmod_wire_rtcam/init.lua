/*******************************
	Wired RT Camera
	  for Wiremod
	  
	(C) Sebastian J.
********************************/

AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

local CAMERA_MODEL = "models/dav0r/camera.mdl"

local E_PLAYER 			= 0
local E_TRACK			= 1
local V_TRACK			= 0

/*---------------------------------------------------------
   Name: Initialize
---------------------------------------------------------*/
function ENT:Initialize()

	self:SetModel( CAMERA_MODEL )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:DrawShadow( false )
	
	// Don't collide with the player
	self:SetCollisionGroup( COLLISION_GROUP_WEAPON )
	
	local phys = self:GetPhysicsObject()
	
	self.Inputs = Wire_CreateInputs( self, {"Activate","Hide"} )
	
	if (phys:IsValid()) then
		phys:Sleep()
	end
	
	self:ShowOutput()
end

function ENT:TriggerInput(iname, value)
	if (iname == "Activate") then
		if (value == 1) then
			UpdateRenderTarget( self )
		end
	elseif (iname == "Hide") then
		self:SetNWInt("hide",tonumber(value))
	end
end

function ENT:ReadCell( Address )
	if ( Address >= 0 && Address <= 1 ) then
		local ret = 0
		
		if ( Address == 0 && ( RenderTargetCameraProp != self ) ) || ( Address == 1 && ( self:GetNWInt( "hide", 0 ) > 0 ) ) then
			ret = 1
		end
		
		return ret
	end
end

function ENT:WriteCell( Address, Value )
	if ( Address == 0 ) then
		if ( Value > 0 ) then
			UpdateRenderTarget( self )
		end
		return true
	elseif ( Address == 1 ) then
		self:SetNWInt( "hide",tonumber( Value ) )
		return true
	end
	return false
end

function ENT:ShowOutput()
	local text = "Wired RT Camera"
	self:SetOverlayText( text )
end

function ENT:SetTracking( Ent, LPos )

	if ( Ent:IsValid() ) then	
		self:SetMoveType( MOVETYPE_NONE )
		self:SetSolid( SOLID_BBOX )	
	else	
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )	
	end

	self:SetNWVector( V_TRACK, LPos)
	self:SetNWEntity( E_TRACK, Ent )
	self:NextThink( CurTime() )
	
	self.TrackEnt = Ent
end


function ENT:Think()
	self.TrackEnt = self:GetNWEntity( E_TRACK )
	self:TrackEntity( self.TrackEnt, self:GetNWVector( V_TRACK ) )	
	self:NextThink( CurTime() )	
end

function ENT:SetPlayer( ply )
	if ( ply && ply:IsValid() ) then
		self:SetNWEntity( E_PLAYER, ply )
	end
end

function ENT:SetLocked( locked )
	if (locked == 1) then	
		self.PhysgunDisabled = true		
		local phys = self:GetPhysicsObject()
		if ( phys:IsValid() ) then
			phys:EnableMotion( false )
		end	
	else	
		self.PhysgunDisabled = false
	end	
	self.locked = locked
end

function ENT:OnTakeDamage( dmginfo )
	self:TakePhysicsDamage( dmginfo )
end

function ENT:OnRemove()
	if RenderTargetCameraProp != self then return end
	Cameras = ents.FindByClass( "gmod_rtcameraprop" )
	if ( #Cameras > 0 ) then
		CameraIdx = math.random( #Cameras )		
		if Cameras[CameraIdx] == self then
			self:OnRemove()
		end		
		local Camera = Cameras[ CameraIdx ]
		UpdateRenderTarget( Camera )
	end
end
include('shared.lua')
