
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Materializer"

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Inputs = WireLib.CreateSpecialInputs(self.Entity, { "Fire", "Material", "Skin" }, { "NORMAL", "STRING", "NORMAL" } )
	self.Outputs = WireLib.CreateSpecialOutputs(self.Entity, { "Out" }, { "NORMAL" })
	self.StringMaterial = ""
    self.ValueSkin = 0
    self:SetBeamRange(2048)
end

function ENT:OnRemove()
	Wire_Remove(self.Entity)
end

function ENT:Setup(outMat,Range)
    if(outMat)then
	    WireLib.AdjustSpecialOutputs(self.Entity, { "Material", "Skin" }, { "STRING", "NORMAL" } )
	end
	self:SetBeamRange(Range)
	self:ShowOutput()
end

function ENT:TriggerInput(iname, value)
	if (iname == "Fire") then
		if (value ~= 0) then
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
            if(self.StrMaterial ~= "") then trace.Entity:SetMaterial(self.StrMaterial) end
			trace.Entity:SetSkin(self.ValueSkin)
		end
	elseif(iname == "Material") then
		if value~=0 then self.StrMaterial = value end
	elseif(iname == "Skin") then
		self.ValueSkin = math.max(math.floor(value),0)
	end
end

function ENT:ShowOutput()
	local text = "Materializer"
	if (self.Outputs["Material"]) then
	    text = text.."\nMaterial = "..self.Outputs["Material"].Value.."\nSkin = "..self.Outputs["Skin"].Value
	end
	self:SetOverlayText( text )
end

function ENT:OnRestore()
    Wire_Restored(self.Entity)
end

function ENT:Think()
    self.BaseClass.Think(self)
    if(self.Outputs["Material"])then
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
    
        local mat = trace.Entity:GetMaterial()
		local skn = trace.Entity:GetSkin()
		
        Wire_TriggerOutput(self.Entity,"Material",mat)
        Wire_TriggerOutput(self.Entity,"Skin",skn)
        
        self:ShowOutput()
        
    end
    self.Entity:NextThink(CurTime()+0.25)
end
    
