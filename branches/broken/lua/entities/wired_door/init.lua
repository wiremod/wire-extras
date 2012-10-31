AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Door Controller"

function ENT:Initialize()
	self.isopen = 0
	self.xautoclose = 0
	self.autoclose = 0
	self.closetime = 1
	self.blocked = 0

	self.animov = 0

	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	if WireAddon ~= nil then
		self.Inputs = Wire_CreateInputs(self, { "Open", "Close", "Lock", "AutoClose", "CloseTime" })
		self.Outputs = Wire_CreateOutputs(self, { "IsOpened", "FullyOpen", "FullyClosed", "Blocked" })
	end
	
	self.xent = nil
	self.xclass = ""

	self.xswitch = switch {
		["xtopen"] = function(x) self:SetOpen(1) end,		
		["xtclose"] = function(x) self:SetOpen(0) end,
		["xtbopen"] = function(x) self:SetOpen(0) self:SetBlocked(1) end,
		["xtbclose"] = function(x) self:SetOpen(1) self:SetBlocked(1) end,
		["xtubopen"] = function(x) self:SetOpen(1) self:SetBlocked(0) end,
		["xtubclose"] = function(x) self:SetOpen(0) self:SetBlocked(0) end,
		["xtfopen"] = function(x) self:SetFully(1) end,
		["xtfclose"] = function(x) self:SetFully(0) end,
		["xtabegun"] = function(x) if(self.animov <= 0) then self:SetOpen(1 - self.isopen) else self.animov = (self.animov - 1) end end,
		["xtadone"] = function(x) self:SetFully(self.isopen) end,
		-- ["xtremove"] = function(x) self:Remove() end, --damn, there is no OnRemove event fired :/
	}

end

function ENT:OnRemove()
	self.xent:Remove()
end

function ENT:TriggerInput(iname, value)
	if (iname == "Open") and (value != 0) then
		self:openself()
	elseif(iname == "Close") and (value != 0) then
		self:closeself()
	elseif(iname == "Lock") then
		if(value != 0) then
			self.xent:Fire("lock","",0)
		else
			self.xent:Fire("unlock","",0)
		end
	elseif(iname == "AutoClose") then
		if(value == 0) then
			self.autoclose = 0
		else
			self.autoclose = 1
		end
	elseif(iname == "CloseTime") then
		if(value == 0) then
			self.autoclose = 0
			self.closetime = 0
		else
			self.closetime = value
		end
	end
end

function ENT:Think()
	self.BaseClass.Think(self)
	if(self.animov < 0) then self.animov = 0 end
	if (self.autoclose == 1) and (self.isopen == 1) then
		if self.xautoclose <= CurTime() then
			self:closeself()
		end
	end
	self:NextThink(CurTime()+0.5)
	return true
end

function ENT:closeself()
	if (self.isopen == 1) then
		self.animov = self.animov + 1
		self:SetOpen(0)
		if (self.xclass == "prop_dynamic") then
			self.xent:Fire("setanimation","close",0)
		elseif (self.xclass == "prop_door_rotating") then
			self.xent:Fire("setanimation","open",0)
		end
	end	
end

function ENT:openself()
	if (self.isopen == 0) then
		self.animov = self.animov + 1
		self.xent:Fire("setanimation","open","0")
		self:SetOpen(1)
	end
end

function ENT:SetOpen(val)
	if(val == self.isopen) then return end
	if (val == 1) then
		if self.autoclose == 1 then self.xautoclose = (CurTime() + self.closetime) end
		self.isopen = 1
	elseif (val == 0) then
		self.xautoclose = 0
		self.isopen = 0
	else
		return		
	end

	Wire_TriggerOutput(self, "FullyOpen", 0)
	Wire_TriggerOutput(self, "FullyClosed", 0)
	Wire_TriggerOutput(self, "IsOpened", val)
end

function ENT:SetFully(val)
	if (val == 0) then
		self:SetOpen(0)
	elseif (val == 1) then
		self:SetOpen(1)
	else
		return	
	end

	self:SetBlocked(0)
	Wire_TriggerOutput(self, "FullyOpen", self.isopen)
	Wire_TriggerOutput(self, "FullyClosed", (1 - self.isopen))
end

function ENT:SetBlocked(val)
	if(val == self.blocked) then return end
	if(val == 0) then
		self.blocked = 0
	elseif(val == 1) then
		self.blocked = 1
	else
		return
	end

	Wire_TriggerOutput(self, "Blocked", self.blocked)
end

function ENT:AcceptInput(name, activator, caller)
	self.xswitch:case(name)
end

function ENT:makedoor(ply,trace,ang,model,open,close,autoclose,closetime,class,hardware)
	if ( !ply:CheckLimit( "doors" ) ) then return nil end
	self.autoclose = autoclose
	self.closetime = closetime
	local entit = ents.Create(class)
	entit:SetModel(model)
	local minn = entit:OBBMins()
	local newpos = Vector(trace.HitPos.X,trace.HitPos.Y,trace.HitPos.Z - (trace.HitNormal.z * minn.z) )
	entit:SetPos( newpos )
	entit:SetAngles(Angle(0,ang.Yaw,0))
	if tostring(class) == "prop_dynamic" then
		entit:SetKeyValue("solid","6")
		entit:SetKeyValue("MinAnimTime","1")
		entit:SetKeyValue("MaxAnimTime","5")
	elseif tostring(class) == "prop_door_rotating" then
		entit:SetKeyValue("hardware",hardware)
		entit:SetKeyValue("distance","90")
		entit:SetKeyValue("speed","100")
		entit:SetKeyValue("returndelay","-1")
		entit:SetKeyValue("spawnflags","8192")
		entit:SetKeyValue("forceclosed","0")
	else
		Msg(class .. " is not a valid class. Bitch at high6 about this error.\n") --HeHe
		return
	end
	entit:Spawn()	
	entit:Activate() 
	local xuuid = "door_" .. tostring(CurTime())
	self:Fire("addoutput","targetname " .. xuuid,0)
	if tostring(class) == "prop_dynamic" then
		entit:Fire("addoutput","OnAnimationBegun " .. xuuid .. ",xtabegun",0)
		entit:Fire("addoutput","OnAnimationDone " .. xuuid .. ",xtadone",0)
	elseif tostring(class) == "prop_door_rotating" then
		entit:Fire("addoutput","OnOpen " .. xuuid .. ",xtopen",0)
		entit:Fire("addoutput","OnClose " .. xuuid .. ",xtclose",0)
		entit:Fire("addoutput","OnBlockedOpening " .. xuuid .. ",xtbopen",0)
		entit:Fire("addoutput","OnBlockedClosing " .. xuuid .. ",xtbclose",0)
		entit:Fire("addoutput","OnUnblockedOpening " .. xuuid .. ",xtubopen",0)
		entit:Fire("addoutput","OnUnblockedClosing " .. xuuid .. ",xtubclose",0)
		entit:Fire("addoutput","OnFullyOpen " .. xuuid .. ",xtfopen",0)
		entit:Fire("addoutput","OnFullyClosed " .. xuuid .. ",xtfclose",0)
	end

	self.xent = entit
	self.xclass = tostring(class)
end

function switch(t)
  t.case = function (self,x)
    local f=self[x] or self.default
    if f then
      if type(f)=="function" then
        f(x,self)
      else
        error("case "..tostring(x).." not a function")
      end
    end
  end
  return t
end
