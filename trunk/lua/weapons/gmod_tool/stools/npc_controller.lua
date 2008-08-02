AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

TOOL.AddToMenu	= false //This is so the beta test can go on but still be in the svn

function ENT:Initialize()

	self:SetModel( "models/Humans/Group01/Female_01.mdl" )
	
	self:SetHullType( HULL_HUMAN );
	self:SetHullSizeNormal();
	
	self:SetSolid( SOLID_BBOX ) 
	self:SetMoveType( MOVETYPE_STEP )
	
	self:CapabilitiesAdd( CAP_MOVE_GROUND | CAP_OPEN_DOORS | CAP_ANIMATEDFACE | CAP_TURN_HEAD | CAP_USE_SHOT_REGULATOR | CAP_AIM_GUN )
	
	self:SetMaxYawSpeed( 5000 )
	
	//don't touch stuff above here
	self:SetHealth(100)
	self:Give( "ai_weapon_smg1" ) //Can be given sweps.
end

function ENT:OnTakeDamage(dmg)
	local NewHealth = (self:Health() - dmg:GetDamage())
  	self:SetHealth( NewHealth )
  		if self:Health() <= 0 then //run on death
			self:SetNPCState( NPC_STATE_DEAD )
  			self:SetSchedule( SCHED_FALL_TO_GROUND ) //because it's given a new schedule, the old one will end.
  	end
end 
/**
function ENT:TaskFinished()
	//return true
end
**/
function ENT:Think()// Get Npc_C_271 then set the X, and Y to it
	local m = Npc_C_271
	local X = m.X
	local Y = m.Y
	local GO = m.GO
	self:SetLastPosition( vector( X, Y, 0 ))
	if ( GO == 1 ) then
		self:SetSchedule( SCHED_FORCED_GO_RUN )
	else
		self:SetSchedule( SCHED_IDLE_STAND )
	end
end