--------------------------------------------------------
-- Objects
--------------------------------------------------------
local EGP = EGP

EGP.Objects = {}
EGP.Objects.Names = {}

-- This object is not used. It's only a base
EGP.Objects.Base = {}
EGP.Objects.Base.ID = 0
EGP.Objects.Base.x = 0
EGP.Objects.Base.y = 0
EGP.Objects.Base.w = 0
EGP.Objects.Base.h = 0
EGP.Objects.Base.r = 255
EGP.Objects.Base.g = 255
EGP.Objects.Base.b = 255
EGP.Objects.Base.a = 255
EGP.Objects.Base.material = ""
EGP.Objects.Base.parent = 0
EGP.Objects.Base.Transmit = function( self )
	EGP:SendPosSize( self )
	EGP:SendColor( self )
	EGP:SendMaterial( self )
	EGP.umsg.Short( self.parent )
end
EGP.Objects.Base.Receive = function( self, um )
	local tbl = {}
	EGP:ReceivePosSize( tbl, um )
	EGP:ReceiveColor( tbl, self, um )
	EGP:ReceiveMaterial( tbl, um )
	tbl.parent = um:ReadShort()
	return tbl
end
EGP.Objects.Base.DataStreamInfo = function( self )
	return { x = self.x, y = self.y, w = self.w, h = self.h, r = self.r, g = self.g, b = self.b, a = self.a }
end

function EGP:NewObject( Name )
	self.Objects[Name] = {}
	table.Inherit( self.Objects[Name], self.Objects.Base )
	local ID = table.Count(self.Objects)
	self.Objects[Name].ID = ID
	self.Objects.Names[Name] = ID 
	return self.Objects[Name]
end

function EGP:GetObjectByID( ID )
	for k,v in pairs( EGP.Objects ) do
		if (v.ID == ID) then return table.Copy( v ) end
	end
	ErrorNoHalt( "[EGP] Error! Object with ID '" .. ID .. "' does not exist. Please post this bug message on the EGP thread on the wiremod forums." )
end

local folder = "entities/gmod_wire_egp/lib/objects/"
local files = file.FindInLua(folder.."*.lua")
for _,v in pairs( files ) do
	include(folder..v)
	if (SERVER) then AddCSLuaFile(folder..v) end
end



--------------------------------------------------------
--  Homescreen
--------------------------------------------------------

EGP.HomeScreen = {}

-- Create table
local tbl = {
	{ ID = EGP.Objects.Names["Box"], Settings = { x = 256, y = 256, h = 356, w = 356, material = "expression 2/cog", r = 150, g = 34, b = 34, a = 255 } },
	{ ID = EGP.Objects.Names["Text"], Settings = {x = 256, y = 256, text = "EGP 3", fontid = 1, valign = 1, halign = 1, size = 50, r = 135, g = 135, b = 135, a = 255 } }
}
	
--[[ Old homescreen (EGP v2 home screen design contest winner)
local tbl = {
	{ ID = EGP.Objects.Names["Box"], Settings = {		x = 256, y = 256, w = 362, h = 362, material = "", angle = 135, 					r = 75,  g = 75, b = 200, a = 255 } },
	{ ID = EGP.Objects.Names["Box"], Settings = {		x = 256, y = 256, w = 340, h = 340, material = "", angle = 135, 					r = 10,  g = 10, b = 10,  a = 255 } },
	{ ID = EGP.Objects.Names["Text"], Settings = {		x = 229, y = 28,  text =   "E", 	size = 100, fontid = 4, 						r = 200, g = 50, b = 50,  a = 255 } },
	{ ID = EGP.Objects.Names["Text"], Settings = {	 	x = 50,  y = 200, text =   "G", 	size = 100, fontid = 4, 						r = 200, g = 50, b = 50,  a = 255 } },
	{ ID = EGP.Objects.Names["Text"], Settings = {		x = 400, y = 200, text =   "P", 	size = 100, fontid = 4, 						r = 200, g = 50, b = 50,  a = 255 } },
	{ ID = EGP.Objects.Names["Text"], Settings = {		x = 228, y = 375, text =   "2", 	size = 100, fontid = 4, 						r = 200, g = 50, b = 50,  a = 255 } },
	{ ID = EGP.Objects.Names["Box"], Settings = {		x = 256, y = 256, w = 256, h = 256, material = "expression 2/cog", angle = 45, 		r = 255, g = 50, b = 50,  a = 255 } },
	{ ID = EGP.Objects.Names["Box"], Settings = {		x = 128, y = 241, w = 256, h = 30, 	material = "", 									r = 10,  g = 10, b = 10,  a = 255 } },
	{ ID = EGP.Objects.Names["Box"], Settings = {		x = 241, y = 128, w = 30,  h = 256, material = "", 									r = 10,  g = 10, b = 10,  a = 255 } },
	{ ID = EGP.Objects.Names["Circle"], Settings = {	x = 256, y = 256, w = 70,  h = 70, 	material = "", 									r = 255, g = 50, b = 50,  a = 255 } },
	{ ID = EGP.Objects.Names["Box"], Settings = {	 	x = 256, y = 256, w = 362, h = 362, material = "gui/center_gradient", angle = 135, 	r = 75,  g = 75, b = 200, a = 75  } },
	{ ID = EGP.Objects.Names["Box"], Settings = {		x = 256, y = 256, w = 362, h = 362, material = "gui/center_gradient", angle = 135, 	r = 75,  g = 75, b = 200, a = 75  } }
}
]]

-- Convert table
for k,v in pairs( tbl ) do
	local obj = EGP:GetObjectByID( v.ID )
	obj.index = k
	for k2,v2 in pairs( v.Settings ) do
		if (obj[k2]) then obj[k2] = v2 end
	end
	table.insert( EGP.HomeScreen, obj )
end