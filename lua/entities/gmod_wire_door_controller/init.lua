AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

ENT.WireDebugName = "Door Controller"


function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	
	self.Inputs = WireLib.CreateSpecialInputs(self, {
		"Open",
		"Toggle",
		"Lock",
		"Speed",
		"ReturnDelay",
		"ForceClosed",
		"FullOpenSound",
		"FullCloseSound",
		"MoveSound",
		"LockedSound",
		"UnlockedSound"
	}, {
		"NORMAL",
		"NORMAL",
		"NORMAL",
		"NORMAL",
		"NORMAL",
		"NORMAL",
		"STRING",
		"STRING",
		"STRING",
		"STRING",
		"STRING"
	})
	self.Outputs = WireLib.CreateSpecialOutputs(self, {"Blocker", "Activator", "IsOpened", "IsLocked", "DoorState"}, {"ENTITY", "ENTITY", "NORMAL", "NORMAL", "NORMAL"})
	
	self:SetOverlayText("Door Controller\n(Not linked)")
end

function ENT:SetOverlayText(txt)
	self:SetNWString("GModOverlayText", txt)
end

// Unlink if door removed
hook.Add("EntityRemoved", "WireDoorController.linkRemoved", function(ent)
	for k,v in pairs(ents.FindByClass("gmod_wire_door_controller")) do
		if v.Door == ent then
			v:Unlink()
		end
	end
end)


// Inputs
function ENT:TriggerInput(iname, value)
	local ent = self.Door
	if not ent or not IsValid(ent) then return end
	
	if iname == "Open" then
		self:OpenDoor(value)
	elseif iname == "Toggle" then
		if value > 0 then
			self:ToggleDoor()
		end
	elseif iname == "Lock" then
		self:LockDoor(value)
	elseif iname == "Speed" then
		self:SetSpeedDoor(value)
	elseif iname == "ReturnDelay" then
		ent:SetSaveValue("returndelay", value)
	elseif iname == "ForceClosed" then
		ent:SetSaveValue("forceclosed", tobool(value))
	elseif iname == "FullOpenSound" then
		ent:SetSaveValue("soundopenoverride", value)
	elseif iname == "FullCloseSound" then
		ent:SetSaveValue("soundcloseoverride", value)
	elseif iname == "MoveSound" then
		ent:SetSaveValue("soundmoveoverride", value)
	elseif iname == "LockedSound" then
		ent:SetSaveValue("soundlockedoverride", value)
	elseif iname == "UnlockedSound" then
		ent:SetSaveValue("soundunlockedoverride", value)
	end
end

function ENT:Link(Door)
	self.Door = Door
	self:SetOverlayText("Door Controller\nLinked - "..self.Door:GetModel())
end

function ENT:Unlink()
	self.Door = nil
	self:SetOverlayText("Door Controller\n(Not linked)")
end

function ENT:OpenDoor(value)
	local ent = self.Door
	if not ent or not IsValid(ent) then return end
	
	if value > 0 then
		ent:Fire("open")
	else
		ent:Fire("close")
	end
end

function ENT:ToggleDoor()
	local ent = self.Door
	if not ent or not IsValid(ent) then return end
	
	ent:Fire("Toggle")
end

function ENT:LockDoor(value)
	local ent = self.Door
	if not ent or not IsValid(ent) then return end
	
	if value > 0 then
		ent:Fire("lock")
	else
		ent:Fire("unlock")
	end
end

function ENT:SetSpeedDoor(value)
	local ent = self.Door
	if not ent or not IsValid(ent) then return end
	
	if value > 0 then
		ent:Fire("SetSpeed", value)
	end
end


// Outputs
function ENT:Think()
	local ent = self.Door
	if not ent or not IsValid(ent) then return end
	
	local EntTable = ent:GetSaveTable()
	
	
	// Blocker
	if IsValid(EntTable.m_hBlocker) then
		WireLib.TriggerOutput(self, "Blocker", EntTable.m_hBlocker)
	end
	
	// Activator
	if IsValid(EntTable.m_hActivator) then
		WireLib.TriggerOutput(self, "Activator", EntTable.m_hActivator)
	end
	
	// IsOpened
	local IsOpened = 0
	if EntTable.m_eDoorState == 2 then IsOpened = 1 end
	WireLib.TriggerOutput(self, "IsOpened", IsOpened)
	
	// IsLocked
	local IsLocked = 0
	if EntTable.m_bLocked then IsLocked = 1 end
	WireLib.TriggerOutput(self, "IsLocked", IsLocked)
	
	// DoorState
	WireLib.TriggerOutput(self, "DoorState", EntTable.m_eDoorState)
	
	
	self:NextThink(CurTime() + 1)
	return true
end