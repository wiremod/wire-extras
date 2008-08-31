AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

function ENT:Initialize()
	self:SetModel( "models/Humans/Group01/Female_01.mdl" )
	self:SetHullType( HULL_HUMAN ) //Used to be a ";" here
	self:SetHullSizeNormal() //And Here	
	self:SetSolid( SOLID_BBOX ) 
	self:SetMoveType( MOVETYPE_STEP )	
	self:CapabilitiesAdd( CAP_MOVE_GROUND | CAP_OPEN_DOORS | CAP_ANIMATEDFACE | CAP_TURN_HEAD | CAP_USE_SHOT_REGULATOR | CAP_AIM_GUN )	
	self:SetMaxYawSpeed( 5000 )	
		//don't touch stuff above here

	self:SetHealth(50)
	self:Give( "ai_weapon_smg1" ) //Can be given sweps.
end

function ENT:OnTakeDamage(dmg) //Possibly add retaliation to attacker
	local NewHealth = (self:Health() - dmg:GetDamage())
  	self:SetHealth( NewHealth )
  		if self:Health() <= 0 then //run on death
			self:SetNPCState( NPC_STATE_DEAD )
  			self:SetSchedule( SCHED_FALL_TO_GROUND )
  	end
	if dmg:GetAttacker():IsPlayer() then //Used to tell the assailant the damage on the npc
		//RunConsoleCommand("say", "You hit my wired npc!")
		self:SetTarget(dmg:GetAttacker())
		dmg:GetAttacker():PrintMessage(3, "You hit the wired npc for "..dmg:GetDamage().." damage!\n")  
	end 
end 

function ENT:Think() 
	if NPCGPS then //If no-go on this variable then cower
		self.Xn = NPCGPS[1] or 0
		self.Yn = NPCGPS[2] or 0
		self.Zn = NPCGPS[3] or 0 //Z is screwing up so I did this
		self.Go = NPCGPS[4] or 0
			if ( self.Go == 1 ) then
				self:SetLastPosition( Vector( self.Xn, self.Yn, self.Zn ) )
				self:SetSchedule( SCHED_FORCED_GO_RUN )	//This is assuming the Set was done right and go has a value	
			else 
				self:SetSchedule( SCHED_IDLE_STAND ) //This is done when Go does have a value, it's just not 1.
			end
		self.Entity:NextThink( CurTime() + 1 ) //To slow possible twitchy-ness
	else //The variable isn't set until input from the controller is there so....
		self:SetSchedule( SCHED_COWER ) //If this occurs then NPCGPS wasn't set properly = very bad. Hence the cower
		self.Entity:NextThink( CurTime() + 1 ) //This is to delay the npc 10 seconds to wait for the controller variable to be set
		return true
	end 
end

function TellGps()
	if NPCGPS then
		local a = RunConsoleCommand
		a("say",("The X is "..self.Xn)) //It's "\n" and not "/n". Might've been a comment lol
		a("say",("The Y is "..self.Yn)) //Split for debugging
		a("say",("The Z is "..self.Zn))
	end
end

concommand.Add( "Tell_Gps", TellGps )


