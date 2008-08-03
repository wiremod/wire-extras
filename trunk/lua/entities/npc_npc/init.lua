AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

local X = 0
local Y = 0
local Z = 0
local Go = 0

function ENT:Initialize()
	self:SetModel( "models/Humans/Group01/Female_01.mdl" )
	self:SetHullType( HULL_HUMAN );
	self:SetHullSizeNormal();	
	self:SetSolid( SOLID_BBOX ) 
	self:SetMoveType( MOVETYPE_STEP )	
	self:CapabilitiesAdd( CAP_MOVE_GROUND | CAP_OPEN_DOORS | CAP_ANIMATEDFACE | CAP_TURN_HEAD | CAP_USE_SHOT_REGULATOR | CAP_AIM_GUN )	
	self:SetMaxYawSpeed( 5000 )	
		//don't touch stuff above here

	self:SetHealth(30)
	self:Give( "ai_weapon_smg1" ) //Can be given sweps.
end

function ENT:OnTakeDamage(dmg)
	local NewHealth = (self:Health() - dmg:GetDamage())
  	self:SetHealth( NewHealth )
  		if self:Health() <= 0 then //run on death
			self:SetNPCState( NPC_STATE_DEAD )
  			self:SetSchedule( SCHED_FALL_TO_GROUND )
  	end
end 


function ENT:Think( Xt, Yt, Zt, Got )// recieve the vars from sendvars
	self.X, self.Y, self.Z, self.Go = Xt, Yt, Zt, Got
	self:SetLastPosition( Vector ( self.X, self.Y, self.Z ))
	Msg("The X is "..self.X.." the Y is "..self.Y.." and the Z is"..self.Z.."/n")
	if ( self.Go == 1 ) then
		self:SetSchedule( SCHED_FORCED_GO_RUN )
	elseif ( self.Go == 0 ) or ( Got == nil ) then
		self:SetSchedule( SCHED_IDLE_STAND )
	end
end






