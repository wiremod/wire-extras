
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "KeycardReader"

local MODEL = Model("models/jaanus/wiretool/wiretool_range.mdl")

function ENT:Initialize()
	self:SetModel( MODEL )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self.Inputs = Wire_CreateInputs(self, { "ReadLocation", "WriteEnabled", "WriteLocation", "WriteValue" })
	self.Outputs = Wire_CreateOutputs(self, {"Value", "SignedBy", "CardID", "Writable"})
	self:SetReadMode(0) // 0 = Beam, 1 = Area
        self:SetLCMatchMode(0) // 0 = Inclusive, 1 = Exclusive
        self:SetRange(256)
        self.Clk = 0
        self.Value = 0
        self.ReadLocation = 0
        self.WriteLocation = 0
end

function ENT:Setup(mode, range, lcmode)
	self:SetReadMode(mode)
        self:SetLCMatchMode(lcmode)
	self:SetRange(range)
	self:ShowOutput()
end

function ENT:SetLockCode(value)
	self.LockCode = (value or 0)
end

function ENT:TriggerInput(iname, value)
	if (iname == "WriteEnabled") then
		self.Clk = (value or 0)
	elseif(iname == "WriteValue") then
		self.Value = (value or 0)
	elseif(iname == "ReadLocation") then
                self.ReadLocation = (value or 0)
        elseif(iname == "WriteLocation") then
                self.WriteLocation = (value or 0)
        end
end

function ENT:ShowOutput()
	local state

	// That which we call a ternary operator
	// By any other syntax would function as elegantly

	if (self.Writable == 1) then
		state = "Writable"
	else
		state = "Read Only"
	end

	local text = "Wire Keycard Reader" ..
		"\nSigned by: " .. tostring(self.Outputs["SignedBy"].Value) ..
		"\nCard ID: " .. tostring(self.Outputs["CardID"].Value) ..
		"\nLock Code: " .. tostring(self.LockCode) ..
		"\nTarget: " .. state


	self:SetOverlayText( text )
end

function ENT:Think()
    self.BaseClass.Think(self)
        
        local foundEnt

        if(self:GetReadMode() == 0) then        

            local vStart = self:GetPos()
	    local vForward = self:GetUp()
		 
            local trace = {}
	        trace.start = vStart
                trace.endpos = vStart + (vForward * self:GetRange())
                trace.filter = { self }
            local trace = util.TraceLine( trace ) 
			
            foundEnt = trace.Entity            

            if (!foundEnt) then self:ZeroOutputs() return false end
            if (!foundEnt:IsValid() ) then self:ZeroOutputs() return false end
            if (foundEnt:IsWorld()) then self:ZeroOutputs() return false end
            if (foundEnt:GetClass() ~= "gmod_wire_keycard") then self:ZeroOutputs() return false end
            

	else
            local i
            local nearbyEnts = ents.FindInSphere(self:GetPos(), self:GetRange())
	    local keycardEnts = ents.FindByClass("gmod_wire_keycard")
	    local nkEnts = {}
            for _,k in pairs(keycardEnts) do
                for _,n in pairs(nearbyEnts) do
                    if (k == n) then
                        table.insert(nkEnts, k)
                    end
                end
            end

            if (table.Count(nkEnts) == 0) then self:ZeroOutputs() return false end

            local nearestDist = self:GetRange()

            
            for _,k in pairs(nkEnts) do
                local dist = self:GetPos():Distance(k:GetPos())
                if (dist <= nearestDist) then
                    nearestDist = dist
                    foundEnt = k
                end
            end

            if (!foundEnt) then self:ZeroOutputs() return false end
            if (!foundEnt:IsValid() ) then self:ZeroOutputs() return false end
            if (foundEnt:IsWorld()) then self:ZeroOutputs() return false end
        end
        
        if ( CLIENT ) then return true end


	local card_lockcode = foundEnt:GetLockCode()
	if (card_lockcode == self.LockCode) then
		self.Writable = 1
	else
		self.Writable = 0
	end

        // If the card isn't yours, and exclusive is on, you haven't found a match after all
        // This has the consequence of deliberately ignoring the card rather than just not
        // seeing it. A near card that isn't yours will force 0 on the outputs all the time.
        if (self.Writable == 0 and self:GetLCMatchMode() == 1) then
            self:ZeroOutputs()
            return false
        end

	if (self.Clk == 1 and self.Writable == 1) then
		foundEnt:SetValue(self.WriteLocation, self.Value)
	end

    
        local value = foundEnt:GetValue(self.ReadLocation)
	local user = foundEnt:GetCardOwner()
	local userid
	local cardid = foundEnt:GetCardID()

	if (user:IsValid() and user:IsPlayer()) then
		userid = user:UserID() + 1

	else
		userid = 0
	end

    
        Wire_TriggerOutput(self,"Value", value)
        Wire_TriggerOutput(self,"SignedBy", userid)
        Wire_TriggerOutput(self,"CardID", cardid)
	Wire_TriggerOutput(self,"Writable", self.Writable)
        self:ShowOutput()

        self:NextThink(CurTime()+0.25)
end
    
function ENT:ZeroOutputs()
	self.Writable = 0
	Wire_TriggerOutput(self,"Value", 0)
        Wire_TriggerOutput(self,"SignedBy", 0)
        Wire_TriggerOutput(self,"CardID", 0)
        Wire_TriggerOutput(self,"Writable", self.Writable)
	self:ShowOutput()
end