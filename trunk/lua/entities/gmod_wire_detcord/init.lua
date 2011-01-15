AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Detonation Cord"
ENT.OverlayDelay = 0

/*---------------------------------------------------------
   Name: Initialize
   Desc: First function called. Use to set up your entity
---------------------------------------------------------*/
function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	
	local phys = self:GetPhysicsObject()
	if phys:IsValid() then phys:Wake() end
	self.isDetcord = true
	
	self.Inputs = Wire_CreateInputs(self, {"Detonate"})
end

/*---------------------------------------------------------
   Name: TriggerInput
   Desc: the inputs
---------------------------------------------------------*/
function ENT:TriggerInput(iname, value)
	if iname == "Detonate" and value ~= 0 then
		self:Detonate()
	end
end

/*---------------------------------------------------------
   Name: Setup
   Desc: does not a whole lot of setting up
---------------------------------------------------------*/
function ENT:Setup()
	-- Random Color Detcord
	local color = {255, 255, 255}
	for k=1,3 do
		if math.random(0, 1) == 1 then color[k] = 0 end
	end
	self:SetColor(color[1], color[2], color[3], 255)
end

/*---------------------------------------------------------
   Name: SetRange
   Desc: Sets the radius of effect
---------------------------------------------------------*/
function ENT:SetRange(range)
	if range < 0 then range = 0 end
	if range > 200 then range = 200 end
	self.range = range
end

/*---------------------------------------------------------
   Name: CleanDebris
   Desc: Remove the Crap
---------------------------------------------------------*/
local function CleanDebris(e)
	if not ValidEntity(e) then return end
        e:Remove()
end

/*---------------------------------------------------------
   Name: Detonate
   Desc: Trigger the detcord
---------------------------------------------------------*/
function ENT:Detonate()
	local en = ents.FindInSphere(self:GetPos(), self.range)

	local effectdata = EffectData()
        effectdata:SetOrigin( self:GetPos() )
        util.Effect( "Explosion", effectdata, true, true )
	
	for k,v in pairs(en) do
		if v:IsPlayer() then
			v:TakeDamage(30, self, self)
		end

		if not v.isDetcord and not v.going and v:GetClass() == "prop_physics" and self:CheckOwner( v ) then
			v.going = true
			v:Fire("enablemotion","",0)
			constraint.RemoveAll(v)
			timer.Simple(math.random(8, 15), CleanDebris, v)
		end
	end
	self:Remove()
end


-- Free Fall's Owner Check Code
function ENT:CheckOwner(ent)
	ply = self.pl
	
	hasCPPI = (type( CPPI ) == "table")
	hasEPS = type( eps ) == "table"
	hasPropSecure = type( PropSecure ) == "table"
	hasProtector = type( Protector ) == "table"
	
	if not hasCPPI and not hasPropProtection and not hasSPropProtection and not hasEPS and not hasPropSecure and not hasProtector then return true end
	
	local t = hook.GetTable()
	
	local fn = t.CanTool.PropProtection
	hasPropProtection = type( fn ) == "function"
	if hasPropProtection then
		-- We're going to get the function we need now. It's local so this is a bit dirty			
		local gi = debug.getinfo( fn )
		for i=1, gi.nups do
			local k, v = debug.getupvalue( fn, i )
			if k == "Appartient" then
				propProtectionFn = v
			end
		end
	end
	
	local fn = t.CanTool[ "SPropProtection.EntityRemoved" ]	
	hasSPropProtection = type( fn ) == "function"
	if hasSPropProtection then
		local gi = debug.getinfo( fn )
		for i=1, gi.nups do
			local k, v = debug.getupvalue( fn, i )
			if k == "SPropProtection" then
				SPropProtectionFn = v.PlayerCanTouch
			end
		end
	end
	
	local owns
	if hasCPPI then
		owns = ent:CPPICanPhysgun( ply )
	elseif hasPropProtection then -- Chaussette's Prop Protection (preferred over PropSecure)
		owns = propProtectionFn( ply, ent )
	elseif hasSPropProtection then -- Simple Prop Protection by Spacetech
		if ent:GetNetworkedString( "Owner" ) ~= "" then -- So it doesn't give an unowned prop
			owns = SPropProtectionFn( ply, ent )
		else
			owns = false
		end
	elseif hasEPS then -- EPS
		owns = eps.CanPlayerTouch( ply, ent )
	elseif hasPropSecure then -- PropSecure
		owns = PropSecure.IsPlayers( ply, ent )
	elseif hasProtector then -- Protector
		owns = Protector.Owner( ent ) == ply:UniqueID()
	end
	
	return owns
end
