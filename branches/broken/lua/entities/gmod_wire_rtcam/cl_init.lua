/*******************************
	Wired RT Camera
	  for Wiremod
	  
	(C) Sebastian J.
********************************/

local cl_drawcameras = CreateConVar( "cl_drawcameras", "1" )

ENT.Spawnable			= false
ENT.AdminSpawnable		= false

local E_PLAYER 			= 0
local E_TRACK			= 1
local V_TRACK			= 0

/*---------------------------------------------------------
   Name: Initialize
---------------------------------------------------------*/
function ENT:Initialize()

	self.ShouldDrawInfo 	= false
	self.ShouldDraw 		= 1

end

/*---------------------------------------------------------
   Name: Draw
---------------------------------------------------------*/
function ENT:Draw()

	if (self.ShouldDraw == 0) then return end
	if (self:GetNWInt("hide",0) == 1) then return end

	// Don't draw the camera if we're taking pics
	local ply = LocalPlayer()
	local wep = ply:GetActiveWeapon()
	if ( wep:IsValid() ) then 
		local weapon_name = wep:GetClass()
		if ( weapon_name == "gmod_camera" ) then return end
	end

	self:DrawModel()
	
	if ( !self.ShouldDrawInfo || !self.Texture ) then return end
	
	
	render.SetMaterial( self.Texture )
	render.DrawSprite( self:GetPos() + Vector( 0, 0, 32), 16, 16, color_white )
	

end

/*---------------------------------------------------------
   Name: Think
   Desc: Client Think - called every frame
---------------------------------------------------------*/
function ENT:Think()

	self.TrackEnt = self:GetNWEntity( E_TRACK )
	self:TrackEntity( self.TrackEnt, self:GetNWVector( V_TRACK ) )

	self.ShouldDraw = cl_drawcameras:GetBool()
	if (self.ShouldDraw == 0) then return end

	// Are we the owner of this camera?
	// If we are then draw the overhead text info
	local Player = self:GetNWEntity( E_PLAYER )
	if ( Player == LocalPlayer() ) then
	
		self.ShouldDrawInfo = true
		
	else
	
		self.ShouldDrawInfo = false
	
	end	
end

function ENT:SetPlayer( pl )
end

include('shared.lua')