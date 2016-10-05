AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua' )

ENT.WireDebugName = "Modular Panel"
ENT.wireData = {}

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
end

function ENT:Setup(widgetTable)
	--if (!file.IsDir("modular_panels")) then	--just use this on writefile
	--	file.CreateDir("modular_panels")
	--end 
	--self:PanelInit()
	
	--Msg("setup, wid1 name = "..widgetTable[1].name.."\n")
	
	--new code, just commented cos gmod crashing
	for k, w in ipairs (widgetTable) do
		Msg("ent setup got widget "..w.name..", x = "..w.x.."\n")
	end
	
	guiP_PanelInit(self.Entity, 200, 200)	--only do once. need to get clear function working to allow re-setup
	
	self.wireData = guiP_loadWidgetsFromTable(self.Entity, widgetTable)	--load widgets from table passed from stool
	guiP_SendClientWidgets(self.Entity)	--send widget information to clients , need to change this so clients request instead
	
	self.Outputs = Wire_CreateOutputs(self.Entity, self.wireData.outputs)
	self.Inputs = Wire_CreateInputs(self.Entity, self.wireData.inputs)	
	
	guiP_SetPanelScheme(self.Entity, "highContWhite")
	guiP_SetPanelState(self.Entity, true)
	
	for k,op in ipairs(self.wireData.outputs) do
		Wire_TriggerOutput(self.Entity, op, 0)
	end
	
	--old code
	--[[
	Msg("loading panel file: "..fileName.."\n")
	if (file.Exists("modular_panels/"..fileName)) then
		local pFile = file.Read("modular_panels/"..fileName) 
		
	else
		Msg("file not found\n") --make say in stool panel
	end

	]]--
end

function ENT:widgetOutput (ply, widgetName, outputName, value)
	--Msg(string.format("output %s of widget(%s) = %d\n", outputName, widgetName, value))
	--Msg("table says output "..self.wireData.outputMap[widgetName].."\n")
	
	Wire_TriggerOutput(self.Entity, self.wireData.outputMap[widgetName], value)
end

function ENT:TriggerInput(iname, value)
	guiP_setWidgetProperty(self.Entity, self.wireData.inputMap[iname], "value", value)
end

function ENT:ShowOutput(slider, togA, togB)
	self:SetOverlayText(string.format("Slider = %f, TogA = %f, TogB = %f", slider, togA, togB))
end

function ENT:OnRestore()
    self.BaseClass.OnRestore(self)	--see what wire base does with this
	Wire_AdjustOutputs(self.Entity, self.wireData.outputs)
end
