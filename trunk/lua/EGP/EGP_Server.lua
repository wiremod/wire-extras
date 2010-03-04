--Includes!
local EGP_USM = file.FindInLua( "EGP/USM/*.lua")
local EGP_ELEMENT = file.FindInLua( "EGP/ELEMENT/*.lua")
for _,file in pairs(EGP_USM) do
	include("EGP/USM/"..file)
	AddCSLuaFile("EGP/USM/"..file)
end
for _,file in pairs(EGP_ELEMENT) do
	AddCSLuaFile("EGP/ELEMENT/"..file)
end
--EGP Cvarse
EGP.cvar_elements = CreateConVar("sbox_maxwire_egp_elements", "100", FCVAR_ARCHIVE)
--EGP.cvar_frames = CreateConVar("sbox_maxwire_egp_frames", "12", FCVAR_ARCHIVE)
--Cvar Functions
function EGP.MaxElements()
	return EGP.cvar_elements:GetInt()
end
function EGP.MaxFrames()
	--return ( 1 / EGP.cvar_frames:GetInt() )
	--$TODO: fix this ouputs 1 all the time
end

--EGP E2 interface functions!
function EGP.IsValid(ent, idx, ignore_missing)
	if not ent then return false end
	if not ValidEntity(ent) then return false end
	if not ent.Render then return false end
	if idx then
		if idx < 0 then return false end
		if idx > EGP.MaxElements() then  return false end
		if not ignore_missing then
			if not ent.Render[idx] then  return false end
		end
		ent.RenderDirty[idx] = true
	end
	return true
end

function EGP.CanDraw(ent, noset)
	if not EGP.IsValid(ent) then return false end
	if not ent.LastPainted or (CurTime() - ent.LastPainted) >= 0.08 then 
		if not noset then ent.LastPainted = CurTime() end
		return true
	end
	
	return false
end

function EGP.SetColor(ent,idx,c)
	if not EGP.IsValid(ent, idx, true) then return end
	local tbl = ent.Render[idx]
	tbl.R = c[1] or 255
	tbl.G = c[2] or 255
	tbl.B = c[3] or 255
	tbl.A = c[4] or 255
end

--Processor?
function EGP.ProcessCache(ent)
	if not EGP.IsValid(ent) then return end
	
	for idx,v in pairs(ent.Render) do
		ent.RenderDrawn[idx] = v
		if not v.image or v.image == "E" then ent.RenderDrawn[idx] = {}  end
		if ent.Render[idx].image != v.image then ent.RenderDrawn[idx] = {}  end
	end
	
	for idx,v in pairs(ent.RenderDrawn) do
		if not v.image then table.remove(ent.RenderDrawn,idx) end
	end
	
	ent.Render = {}
	ent.RenderDirty = {}
	
end
--Mabey i do need a betetr name.

function EGP.CacheCompare(ent,idx)
	if not EGP.IsValid(ent) then return false end
	local check = false
	local Drawn = ent.RenderDrawn[idx] or {}
	for k,v in pairs(ent.Render[idx]) do
		if not Drawn[k] then check = true end
		if Drawn[k] != v then check = true end
	end
	return check
end

--Log Stuff
AddCSLuaFile("EGP/log.lua")