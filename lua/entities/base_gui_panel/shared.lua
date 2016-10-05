ENT.Type 			= "anim"
--ENT.Base 			= "base_gmodentity"
ENT.PrintName		= ""
ENT.Author			= ""
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""
ENT.Spawnable			= false
ENT.AdminSpawnable		= false

ENT.guiPanelVersion = 0.4
ENT.errorMsg = "guiPanel ERROR: "
ENT.debug = true
ENT.panelID = 0

ENT.paramSetup = false

--(future plans)
-- ability for server to show/hide (and enable/disble all functions) of a widget, this will allow different 'windows' to be moved between on the panel (widget.visible variable) -- use standard input to do this

--multi model support

--make label, button put text into centre (vertically)


function ENT:OnRemove()
	if CLIENT then
		--self.screen:Remove()
	end
end


ENT.drawParameters = {}

util.PrecacheModel("models/props/cs_office/TV_plasma.mdl") 
util.PrecacheModel("models/props/cs_office/computer_monitor.mdl")
util.PrecacheModel("models/props_lab/monitor01b.mdl")
util.PrecacheModel("models/kobilica/wiremonitorsmall.mdl")
util.PrecacheModel("models/kobilica/wiremonitorbig.mdl")
util.PrecacheModel("models/kobilica/guipmonitorbig.mdl")

ENT.drawParameters["models/props/cs_office/TV_plasma.mdl"] = {
	x1 = -28.5,
	x2 = 28.5,
	y1 = 36,
	y2 = 2,
	z = 6.1
}
ENT.drawParameters["models/props/cs_office/computer_monitor.mdl"] = {
	x1 = -10.5,
	x2 = 10.5,
	y1 = 24.7,
	y2 = 8.6,
	z = 3.33
}
ENT.drawParameters["models/props_lab/monitor01b.mdl"] = {
	x1 = -5.535,
	x2 = 3.5,
	y1 = 5.091,
	y2 = -4.1,
	z = 6.4
}
ENT.drawParameters["models/kobilica/wiremonitorsmall.mdl"] = {
	x1 = -4.4,
	x2 = 4.5,
	y1 = 9.5,
	y2 = 0.6,
	z = 0.2
}

ENT.drawParameters["models/kobilica/wiremonitorbig.mdl"] = {
	x1 = -11.5,
	x2 = 11.6,
	y1 = 24.5,
	y2 = 1.6,
	z = 0.2
}
ENT.drawParameters["models/kobilica/guipmonitorbig.mdl"] = {
	x1 = -11.5,
	x2 = 11.6,
	y1 = 24.5,
	y2 = 1.6,
	z = 0.2
}
ENT.drawParameters["default"] = {
	x1 = -10.5,
	x2 = 10.5,
	y1 = 24.7,
	y2 = 8.6,
	z = 6
}


function ENT:SetupParams()
	local model = tostring(self.Entity:GetModel())
	--Msg("setting draw params, serv = "..tostring(SERVER)..", model = "..model.."\n")
	
	if self.drawParameters[model] then
		self.x1 = self.drawParameters[model].x1
		self.x2 = self.drawParameters[model].x2
		self.y1 = self.drawParameters[model].y1
		self.y2 = self.drawParameters[model].y2
		self.z  = self.drawParameters[model].z
		self.paramsSetup = true
	else
		Msg ("model not found\n")
		self.x1 = self.drawParameters["default"].x1
		self.x2 = self.drawParameters["default"].x2
		self.y1 = self.drawParameters["default"].y1
		self.y2 = self.drawParameters["default"].y2
		self.z  = self.drawParameters["default"].z
	end
	
	--begin adapted nighteagle code 
	self.res = 0.05
	--self.workingDistance = 64
	self.workingDistance = 100
	
	self.x = self.x1 / self.res
	self.y = -self.y1 / self.res
	self.x0 = self.x + (self.x2 / self.res) - self.x * 2
	self.y0 = self.y + (-self.y2 / self.res) - self.y * 2
	self.w = (self.x2 / self.res) - self.x
	self.h = math.abs((self.y2 / self.res) + self.y)
	
	self.ox = 5
	self.oy = 5
	--end adapted nighteagle code
end

function ENT:HasWire()
	if (Wire_CreateInputs and Wire_CreateOutputs) then
		return true
	else
		return false
	end
end