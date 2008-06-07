
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "RFID Implanter"

local MODEL = Model("models/jaanus/wiretool/wiretool_beamcaster.mdl")

function ENT:ShowOutput(a,b,c,d)
	self:SetOverlayText( "RFID Implanter\nA="..a..";B="..b..";C="..c..";D="..d )
end

function ENT:Initialize()
	self.Entity:SetModel( MODEL )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Inputs = Wire_CreateInputs(self.Entity, { "Fire", "A", "B", "C", "D", "Remove" })
	self.Outputs = Wire_CreateOutputs(self.Entity, { "Out" })
	self.A = 0;
	self.B = 0;
	self.C = 0;
	self.D = 0;
	self.NoColorChg = false;
	self:SetBeamRange(2048)
	self:ShowOutput(0,0,0,0)
end

function ENT:OnRemove()
	Wire_Remove(self.Entity)
end

function ENT:Setup(Range, col)
    self:SetBeamRange(Range)
	self.NoColorChg = col
end

function ENT:TriggerInput(iname, value)
	if ((iname == "Fire" or iname=="Remove") and value~=0) then
		local vStart = self.Entity:GetPos()
		local vForward = self.Entity:GetUp()
		
		local trace = {}
		  trace.start = vStart
		  trace.endpos = vStart + (vForward * self:GetBeamRange())
		  trace.filter = { self.Entity }
		local trace = util.TraceLine( trace ) 
		
		if (!trace.Entity) then return false end
        if (!trace.Entity:IsValid() ) then return false end
        if (trace.Entity:IsWorld()) then return false end
        if ( CLIENT ) then return true end
        if(iname == "Fire") then -- Implant/Update RFID
			trace.Entity.__RFID_HASRFID = true;
			trace.Entity.__RFID_A = self.A;
			trace.Entity.__RFID_B = self.B;
			trace.Entity.__RFID_C = self.C;
			trace.Entity.__RFID_D = self.D;
		else                     -- Remove RFID
			trace.Entity.__RFID_HASRFID = false;
			trace.Entity.__RFID_A = nil;
			trace.Entity.__RFID_B = nil;
			trace.Entity.__RFID_C = nil;
			trace.Entity.__RFID_D = nil;
		end
		-- Generate spark effect
		local effectdata = EffectData()
		 effectdata:SetOrigin( trace.HitPos )
		 effectdata:SetNormal( trace.HitNormal )
		 effectdata:SetMagnitude( 5 )
		 effectdata:SetScale( 1 )
		 effectdata:SetRadius( 10 )
		util.Effect( "Sparks", effectdata )
	elseif iname=="A" or iname=="B" or iname=="C" or iname=="D" then
	    self[iname] = value;
		self:ShowOutput(self.A,self.B,self.C,self.D)
	end
end

function ENT:Think()
	self.BaseClass.Think(self)
	
	local vStart = self.Entity:GetPos()
	local vForward = self.Entity:GetUp()
	
    local trace = {}
	   trace.start = vStart
	   trace.endpos = vStart + (vForward * self:GetBeamRange())
	   trace.filter = { self.Entity }
	local trace = util.TraceLine( trace ) 
	
	local ent = trace.Entity

	if (!trace.Entity or !trace.Entity:IsValid() or trace.Entity:IsWorld() or !trace.Entity:GetPhysicsObject()) then
		if(!self.NoColorChg and Color(self.Entity:GetColor()) != Color(255,255,255,255))then
            self.Entity:SetColor(255, 255, 255, 255)
        end
		return false
	end
    
    if(!self.NoColorChg and Color(self.Entity:GetColor()) != Color(0,255,0,255))then
        self.Entity:SetColor(0, 255, 0, 255)
    end
    
    self.Entity:NextThink(CurTime()+0.125)
end

function ENT:OnRestore()
    Wire_Restored(self.Entity)
end

