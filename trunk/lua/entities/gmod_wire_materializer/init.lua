
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
    self:SetBeamLength(2048)
end

function ENT:OnRemove()
	Wire_Remove(self.Entity)
end

function ENT:Setup(outMat,Range)
    if(outMat)then
	    WireLib.AdjustSpecialOutputs(self.Entity, { "Material", "Skin" }, { "STRING", "NORMAL" } )
	end
	self:SetBeamLength(Range)
	self:ShowOutput()
end

local function CheckPP(ply, ent)
	if !IsValid(ply) or !IsValid(ent) then return false end
	if ent:IsPlayer() then return false end
	if CPPI then
		-- Temporary, done this way due to certain PP implementations not always returning a value for CPPICanTool
		if ent == ply then return true end
		if ent:CPPICanTool( ply, "material" ) == false then return false end
	end
	return true
end

function ENT:TriggerInput(iname, value)
	if iname == "Fire" then
		if value ~= 0 then
			local vStart = self.Entity:GetPos()
			local vForward = self.Entity:GetUp()
			
			local trace = {}
				trace.start = vStart
				trace.endpos = vStart + (vForward * self:GetBeamLength())
				trace.filter = { self.Entity }
			local trace = util.TraceLine( trace ) 
			
            if !CheckPP( self.pl, trace.Entity ) then return end
            trace.Entity:SetMaterial(self.StrMaterial)
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
    Wire_Restored(self.Entity)
end

function ENT:Think()
    self.BaseClass.Think(self)
    if self.Outputs["Material"] then
        local vStart = self.Entity:GetPos()
	    local vForward = self.Entity:GetUp()
		
	    local trace = {}
			trace.start = vStart
			trace.endpos = vStart + (vForward * self:GetBeamLength())
			trace.filter = { self.Entity }
	    local trace = util.TraceLine( trace ) 
		
		if !IsValid( trace.Entity ) then return end
		
        local mat = trace.Entity:GetMaterial()
		local skn = trace.Entity:GetSkin()
		
        Wire_TriggerOutput(self.Entity,"Material",mat)
        Wire_TriggerOutput(self.Entity,"Skin",skn)
        
        self:ShowOutput()
    end
    self.Entity:NextThink(CurTime()+0.25)
	return true
end