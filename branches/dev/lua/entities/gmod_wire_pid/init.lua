
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "PID"

function ENT:Initialize()
	/* Make Physics work */
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	/* Set wire I/O */
	self.Inputs = Wire_CreateInputs(self, { "In", "Set Point", "Enable" })
	self.Outputs = Wire_CreateOutputs(self, { "Out" })

	/* Initialize values */
	self.set = 0
	self.inval = 0
	self.p = 0
	self.i = 0
	self.d = 0
	self.dcut = 0
	self.ilim = 0
	self.iterm = 0
	self.enabled = 1
	self.limit = 100

	local phys = self:GetPhysicsObject()
	if (phys:IsValid() == true) then
		phys:Wake()
	end
end

function ENT:Think()
	/* Make sure the gate updates even if we don't receive any input */
	self:TriggerInput()
end

function ENT:SetupGains(p, i, d, dcut, ilim, limit)
	/* Called by creator to set options */
	self.p = p
	self.i = i
	self.d = d
	self.dcut = dcut
	self.ilim = ilim
	self.limit = limit
	self.lasttime = CurTime()
	self.lasterror = 0
	self.iterm = 0
end

function ENT:TriggerInput(iname, value)
	/* Change variables to reflect input */
	if (iname == "Set Point") then
		self.set = value
		return
	end
	if (iname == "In") then
		self.inval = value
	end

	if (iname == "Enable") then
		self.enabled = value
		return
	end

	/* If we're not enabled, set the output to zero and exit */
	if (self.enabled == 0) then
		Wire_TriggerOutput(self, "Out", 0)
		return
	end

	/* Define some local variables */
	local error = self.set - self.inval
	local dt = CurTime() - self.lasttime

	/* Calculate derivative term (de/dt) , check for divide by zero */
	local dterm = 0
	if (dt>0) then
		dterm = (error - self.lasterror)/dt
	end
	dterm = dterm * self.d

	/* If the derivative term is less than the cutoff, evaluate the integral term */
	if (math.abs(dterm) < self.dcut) then
		self.iterm = self.iterm + self.i * error * dt
	end

	/* Bound the integral term to the user limit */
	if (self.iterm > self.ilim && error > 0) then
		self.iterm = self.ilim
	end
	if (self.iterm < -self.ilim && error < 0) then
		self.iterm = -self.ilim
	end

	/* Setup for next time */
	self.lasttime = CurTime()
	self.lasterror = error

	/* Output it */
	self.out = (self.p * error) + self.iterm + dterm

	/* Limit the output to whatever */
	if (math.abs(self.out) > self.limit) then
		if (self.out>=0) then
			self.out = self.limit
		else
			self.out = -self.limit
		end
	end

	Wire_TriggerOutput(self, "Out", self.out)
end



