AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Materializer"

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self.Inputs = WireLib.CreateSpecialInputs(self, { "Fire", "Material", "Skin" }, { "NORMAL", "STRING", "NORMAL" } )
	self.Outputs = WireLib.CreateSpecialOutputs(self, { "Out" }, { "NORMAL" })
	self.StringMaterial = ""
    self.ValueSkin = 0
    self:SetBeamLength(2048)
end

function ENT:OnRemove()
	Wire_Remove(self)
end

function ENT:Setup(outMat,Range)
    if(outMat)then
	    WireLib.AdjustSpecialOutputs(self, { "Material", "Skin" }, { "STRING", "NORMAL" } )
	end
	self:SetBeamLength(Range)
	self:ShowOutput()
end

function ENT:TriggerInput(iname, value)
	if iname == "Fire" then
		if value ~= 0 then
			local vStart = self:GetPos()
			local vForward = self:GetUp()
			
			local trace = {}
				trace.start = vStart
				trace.endpos = vStart + (vForward * self:GetBeamLength())
				trace.filter = { self }
			local trace = util.TraceLine( trace ) 
			
			if not IsValid( trace.Entity ) then return end
            		if not hook.Run( "CanTool", self:GetPlayer(), trace, "material" ) then return end
            		
            		trace.Entity:SetMaterial(WireLib.IsValidMaterial(self.StrMaterial))
			trace.Entity:SetSkin(self.ValueSkin)
		end
	elseif iname == "Material" then
		self.StrMaterial = value
	elseif iname == "Skin" then
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
    Wire_Restored(self)
end

function ENT:Think()
    self.BaseClass.Think(self)
    if self.Outputs["Material"] then
        local vStart = self:GetPos()
	    local vForward = self:GetUp()
		
	    local trace = {}
			trace.start = vStart
			trace.endpos = vStart + (vForward * self:GetBeamLength())
			trace.filter = { self }
	    local trace = util.TraceLine( trace ) 
		
		if !IsValid( trace.Entity ) then return end
		
        local mat = trace.Entity:GetMaterial()
		local skn = trace.Entity:GetSkin()
		
        Wire_TriggerOutput(self,"Material",mat)
        Wire_TriggerOutput(self,"Skin",skn)
        
        self:ShowOutput()
    end
    self:NextThink(CurTime()+0.25)
	return true
end
