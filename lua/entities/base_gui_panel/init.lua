--gui Panel by greenarrow

AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

ENT.pWidgets = {}
ENT.nameTable = {}
ENT.widgetLookup = {}
ENT.schemeTable = {}
ENT.clientExists = false
ENT.serverExists = false
ENT.initOccured = false
ENT.entID = 0
ENT.currentScheme = nil
ENT.firstRun = {scheme = false, init = false, enable = false}

--[[
function ENT:Use(activator, caller)
	if(!activator:IsPlayer()) then return false end
	if (!activator:KeyPressed(IN_USE)) then return false end
	gpCursorClick (activator)
end
]]--



function ENT:Think()
end
