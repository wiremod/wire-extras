
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Servo"
ENT.OverlayDelay = 0

/*---------------------------------------------------------
   Name: Initialize
   Desc: First function called. Use to set up your entity
---------------------------------------------------------*/
function ENT:Initialize()

	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Entity:SetUseType( SIMPLE_USE )
	
	self:SetToggle( false )
	
	self.ToggleState = false
	self.BaseTorque = 1
	self.TorqueScale = 1
	self.SpeedMod = 0
	self.curAngle = 0
	self.acqCase = 0
	self.initAngle = 0
	self.chosenAngle = 0
	self.doAcq = 0
	self.Direct = 0
	self.WeldMode = 0
	
	self.Inputs = Wire_CreateInputs(self.Entity, { "A: Angle", "B: Direction", "C: SpeedMod" })
	self.Outputs = Wire_CreateOutputs(self.Entity, { "Angle" })
	
end

/*---------------------------------------------------------
   Sets the base torque
---------------------------------------------------------*/
function ENT:SetBaseTorque( base )

	self.BaseTorque = base
	if ( self.BaseTorque == 0 ) then self.BaseTorque = 1 end
	self:UpdateOverlayText()

end

/*---------------------------------------------------------
   Sets the base torque
---------------------------------------------------------*/
function ENT:UpdateOverlayText()

	txt = "Torque: " .. math.floor( self.TorqueScale * self.BaseTorque ) .. "\nSpeed: 0\nSpeedMod: " .. math.floor( self.SpeedMod * 100 ) .. "%"
	self:SetOverlayText( txt )

end

/*---------------------------------------------------------
   Sets the axis (world space)
---------------------------------------------------------*/
function ENT:SetAxis( vec )
	
	self.Axis = self.Entity:GetPos() + vec * 512
	self.Axis = self.Entity:NearestPoint( self.Axis )
	self.Axis = self.Entity:WorldToLocal( self.Axis )

end


/*---------------------------------------------------------
   Name: PhysicsCollide
   Desc: Called when physics collides. The table contains 
			data on the collision
---------------------------------------------------------*/
function ENT:PhysicsCollide( data, physobj )
end


/*---------------------------------------------------------
   Name: AcceptVars
   Desc: Called by STool to transmit the servo's
		base
---------------------------------------------------------*/
function ENT:AcceptVars( ent, entBone, weldmode )

	self.ServoBase = ent
	self.ServoBone = entBone
	self.WeldMode = weldmode

end


/*---------------------------------------------------------
   Name: InitWeld
   Desc: Welds the servo to its base
---------------------------------------------------------*/
function ENT:InitWeld()

	self.Constraint = constraint.Weld( self.Entity, self.ServoBase, 0, self.ServoBone, 0 )

end


/*---------------------------------------------------------
   Name: DoVectorChoice
   Desc: Chooses the baseent's comparison vector;
	without, we end up rotating wrong
---------------------------------------------------------*/
function ENT:DoVectorChoice()

	local axisVector = self.Entity:LocalToWorld( self.Axis ) - self.Entity:GetPos()
	axisVector:Normalize()
	local debugANGLE = math.deg( math.acos( self.ServoBase:GetRight():DotProduct( axisVector ) ) )
	
	if ( math.abs( debugANGLE ) < 2 ) then self.VectorChoice = 1 else self.VectorChoice = 0 end

end


/*---------------------------------------------------------
   Name: PhysicsUpdate
   Desc: Called to update the physics .. or something.
---------------------------------------------------------*/
function ENT:PhysicsUpdate( physobj )
end


/*---------------------------------------------------------
   Name: KeyValue
   Desc: Called when a keyvalue is added to us (usually from the map)
---------------------------------------------------------*/
function ENT:KeyValue( key, value )
end


/*---------------------------------------------------------
   Name: Think
   Desc: Entity's think function. 
---------------------------------------------------------*/
function ENT:Think()

	// This looks like a lot to "think" about,
	// there must be a way to cut down on cycles here

	if !self.OutputThink then self.OutputThink = CurTime() end // Called on first think, has us update outputs right away
	// if !self.VectorChoice then Msg( "If I show up, don't take me out!\n" ) return end // If think has occured before DoVectorChoice is called, no use in doing any of this, but we shouldn't need this
	
	local chosenBaseVector
	
		if ( self.VectorChoice == 1 ) then
			chosenBaseVector = self.ServoBase:GetUp() // GetRight won't work--use this instead
		else
			chosenBaseVector = self.ServoBase:GetRight() // If we have no angle problems, GetRight works fine
		end
	
	local servoVector = self.Entity:GetRight()
	local axisVector = self.Entity:LocalToWorld( self.Axis ) - self.Entity:GetPos()
	axisVector:Normalize()
		
	local baseVector1 = chosenBaseVector:Cross( axisVector )
	local baseVector2 = baseVector1:Cross( axisVector )
	
	local angle1 = math.deg( math.acos( servoVector:DotProduct( baseVector1 ) ) )
	local angle2 = math.deg( math.acos( servoVector:DotProduct( baseVector2 ) ) )
	
		if ( angle2 >= 90 ) then // This code allows us to go between 0 and 360, instead of just 0 to 180
			self.curAngle = angle1
		else
			self.curAngle = 360 - angle1
		end
		
	// Acquisition code
	if self.doAcq == 1 then

			if ( self.acqCase == 1 && ( ( self.curAngle + .01 ) < self.initAngle  || ( self.curAngle - .01 ) > self.chosenAngle ) ) then
				self:Forward(0)
				if self.WeldMode == 1 then
					self.Constraint = constraint.Weld( self.Entity, self.ServoBase, 0, self.ServoBone, 0 )
				else
					local servV = self.Entity:GetPhysicsObject():GetAngleVelocity()
					local baseV = self.ServoBase:GetPhysicsObject():GetAngleVelocity()
					local diff = servV - baseV
					self.Entity:GetPhysicsObject():AddAngleVelocity( -1 * diff )
				end
				self.doAcq = 0
				self.acqCase = 0			
			elseif ( self.acqCase == 2 && ( self.curAngle + .01 ) < self.initAngle  && ( self.curAngle - .01 ) > self.chosenAngle ) then
				self:Forward(0)
				if self.WeldMode == 1 then
					self.Constraint = constraint.Weld( self.Entity, self.ServoBase, 0, self.ServoBone, 0 )
				else
					local servV = self.Entity:GetPhysicsObject():GetAngleVelocity()
					local baseV = self.ServoBase:GetPhysicsObject():GetAngleVelocity()
					local diff = servV - baseV
					self.Entity:GetPhysicsObject():AddAngleVelocity( -1 * diff )
				end			
				self.doAcq = 0
				self.acqCase = 0
			elseif ( self.acqCase == 3 && ( self.curAngle - .01 ) > self.initAngle  && ( self.curAngle + .01 ) < self.chosenAngle ) then
				self:Forward(0)
				if self.WeldMode == 1 then
					self.Constraint = constraint.Weld( self.Entity, self.ServoBase, 0, self.ServoBone, 0 )
				else
					local servV = self.Entity:GetPhysicsObject():GetAngleVelocity()
					local baseV = self.ServoBase:GetPhysicsObject():GetAngleVelocity()
					local diff = servV - baseV
					self.Entity:GetPhysicsObject():AddAngleVelocity( -1 * diff )
				end			
				self.doAcq = 0
				self.acqCase = 0	
			elseif ( self.acqCase == 4 && ( ( self.curAngle - .01 ) > self.initAngle || ( self.curAngle + .01 ) < self.chosenAngle ) ) then
				self:Forward(0)
				if self.WeldMode == 1 then
					self.Constraint = constraint.Weld( self.Entity, self.ServoBase, 0, self.ServoBone, 0 )
				else
					local servV = self.Entity:GetPhysicsObject():GetAngleVelocity()
					local baseV = self.ServoBase:GetPhysicsObject():GetAngleVelocity()
					local diff = servV - baseV
					self.Entity:GetPhysicsObject():AddAngleVelocity( -1 * diff )
				end		
				self.doAcq = 0
				self.acqCase = 0
			end
	
	end

		if ( CurTime() >= self.OutputThink ) then
			Wire_TriggerOutput( self.Entity, "Angle", self.curAngle )
			self.OutputThink = CurTime() + .3 // We don't want to update our wired outputs as often as we want to check our angles
		end
	
	self.Entity:NextThink( CurTime() + .001 )
	
	return true
		
end


/*---------------------------------------------------------
   Name: OnTakeDamage
   Desc: Entity takes damage
---------------------------------------------------------*/
function ENT:OnTakeDamage( dmginfo )

	self.Entity:TakePhysicsDamage( dmginfo )

end


function ENT:SetMotor( Motor )
	self.Motor = Motor
end

function ENT:GetMotor()

	if (!self.Motor) then
		self.Motor = constraint.FindConstraintEntity( self.Entity, "Motor" )
		if (!self.Motor or !self.Motor:IsValid()) then
			self.Motor = nil
		end
	end

	return self.Motor
end

//function ENT:SetDirection( dir )
//	self.Entity:SetNetworkedInt( 1, dir )
//	self.Direction = dir
//end

function ENT:SetToggle( bool )
	self.Toggle = bool
end

function ENT:GetToggle()
	return self.Toggle
end


/*---------------------------------------------------------
   Forward
---------------------------------------------------------*/
function ENT:Forward( mul )

	// Is this key invalid now? If so return false to remove it
	if ( !self.Entity:IsValid() ) then return false end
	local Motor = self:GetMotor()
	if ( Motor and !Motor:IsValid() ) then
		Msg("Servo doesn't have a motor!\n"); 
		return false
	elseif ( !Motor ) then return false
	end

	mul = mul or 1
	local mdir = Motor.direction	
	local Speed = mdir * mul * self.TorqueScale * (1 + self.SpeedMod)
	
	txt = "Torque: " .. math.floor( self.TorqueScale * self.BaseTorque ) .. "\nSpeed: " .. ( mdir * mul * (1 + self.SpeedMod)) .. "\nSpeedMod: " .. math.floor( self.SpeedMod * 100 ) .. "%"
	//self.BaseClass.BaseClass.SetOverlayText(self, txt)
	self:SetOverlayText(txt)
	
	Motor:Fire( "Scale", Speed, 0 )
	Motor:GetTable().forcescale = Speed
	Motor:Fire( "Activate", "" , 0 )
	
	return true
	
end


/*---------------------------------------------------------
   Name: TriggerInput
   Desc: the inputs
---------------------------------------------------------*/
function ENT:TriggerInput(iname, value)
	if (iname == "A: Angle") then
		self.chosenAngle = tonumber( value )
		self.initAngle = tonumber( self.curAngle )
		
		self.chosenAngle = self.chosenAngle - 360*math.floor(self.chosenAngle/360) // Modulus application, see explanation below
		self.initAngle = self.initAngle - 360*math.floor(self.initAngle/360)
		
		local ifDiff = self.initAngle - self.chosenAngle
		local fiDiff = self.chosenAngle - self.initAngle
		
		ifDiff = ifDiff - 360*math.floor(ifDiff/360) // Could use modulus, but it won't work on negatives
		fiDiff = fiDiff - 360*math.floor(fiDiff/360) // ...so we use this method instead
		
		if ( self.Direct < 0 ) then
			if ( self.chosenAngle > self.initAngle ) then
				self.acqCase = 1
				self:Forward( -1 )
				self.doAcq = 1
				if self.Constraint then
					self.Constraint:Remove()
					self.Constraint = nil
				end
			elseif ( self.chosenAngle < self.initAngle ) then
				self.acqCase = 2
				self:Forward( -1 )
				self.doAcq = 1
				if self.Constraint then
					self.Constraint:Remove()
					self.Constraint = nil
				end
			else
				self:Forward( 0 )
			end
		elseif ( self.Direct > 0 ) then
			if ( self.chosenAngle > self.initAngle ) then
				self.acqCase = 3
				self:Forward( 1 )
				self.doAcq = 1
				if self.Constraint then
					self.Constraint:Remove()
					self.Constraint = nil
				end
			elseif ( self.chosenAngle < self.initAngle ) then
				self.acqCase = 4
				self:Forward( 1 )
				self.doAcq = 1
				if self.Constraint then
					self.Constraint:Remove()
					self.Constraint = nil
				end
			else
				self:Forward( 0 )
			end
		else // self.Direct == 0
			if ( ifDiff >= fiDiff ) then // CCW, or send -1 to Forward
				if ( self.chosenAngle > self.initAngle ) then
					self.acqCase = 1
					self:Forward( -1 )
					self.doAcq = 1
					if self.Constraint then
						self.Constraint:Remove()
						self.Constraint = nil
					end
						//Debug
						Msg( "Case1 init\n" )
				elseif ( self.chosenAngle < self.initAngle ) then
					self.acqCase = 2
					self:Forward( -1 )
					self.doAcq = 1
					if self.Constraint then
						self.Constraint:Remove()
						self.Constraint = nil
					end
						//Debug
						Msg( "Case2 init\n" )						
				else
					self:Forward( 0 )
				end
			else // CW, or send 1 to Forward
				if ( self.chosenAngle > self.initAngle ) then
					self.acqCase = 3
					self:Forward( 1 )
					self.doAcq = 1
					if self.Constraint then
						self.Constraint:Remove()
						self.Constraint = nil
					end
						//Debug
						Msg( "Case3 init\n" )					
				elseif ( self.chosenAngle < self.initAngle ) then
					self.acqCase = 4
					self:Forward( 1 )
					self.doAcq = 1
					if self.Constraint then
						self.Constraint:Remove()
						self.Constraint = nil
					end
						//Debug
						Msg( "Case4 init\n" )					
				else
					self:Forward( 0 )
				end
			end
		end
		
	elseif (iname == "B: Direction") then
	
		self.Direct = value
		
	elseif (iname == "C: SpeedMod") then
	
		self.SpeedMod = (value / 100)
		
	end
	
end



/*---------------------------------------------------------
   Name: PhysicsUpdate
   Desc: happy fun time breaking function
---------------------------------------------------------*/
function ENT:PhysicsUpdate( physobj )
//	local vel = physobj:GetVelocity()
	
//	if (self.Breaking > 0) then // to prevent badness
//		if (self.Breaking >= 100) then //100% breaking!!!
//			vel.x = 0 //full stop!
//			vel.y = 0
//		else		
//			vel.x = vel.x * ((100.0 - self.Breaking)/100.0)
//			vel.y = vel.y * ((100.0 - self.Breaking)/100.0)
//		end
//	end
	
//	physobj:SetVelocity(vel)
end


/*---------------------------------------------------------
   Todo? Scale Motor:GetTable().direction?
---------------------------------------------------------*/
function ENT:SetTorque( torque )

	if ( self.BaseTorque == 0 ) then self.BaseTorque = 1 end
	
	self.TorqueScale = torque / self.BaseTorque
	
	local Motor = self:GetMotor()
	if (!Motor || !Motor:IsValid()) then return end
	Motor:Fire( "Scale", Motor:GetTable().direction * Motor:GetTable().forcescale * self.TorqueScale , 0 )
	
	txt = "Torque: " .. math.floor( self.TorqueScale * self.BaseTorque )
	//self.BaseClass.BaseClass.SetOverlayText(self, txt)
	self:SetOverlayText(txt)
end


/*---------------------------------------------------------
   Removed use = reverse functionality
---------------------------------------------------------*/
function ENT:Use( activator, caller, type, value )
		
		
	
end


