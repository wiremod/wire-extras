--Element Table
EGP.ELEMENT = {}
EGP.CachedFonts = {}

--Includes!
local EGP_USM = file.FindInLua( "EGP/USM/*.lua")
local EGP_ELEMENT = file.FindInLua( "EGP/ELEMENT/*.lua")
for _,file in pairs(EGP_USM) do
	include("EGP/USM/"..file)
end
for _,file in pairs(EGP_ELEMENT) do
	include("EGP/ELEMENT/"..file)
end

--Textures
EGP.MatCache = {}
function EGP.GetCachedMaterial(mat)
	if not mat then return nil end
	if not EGP.MatCache[mat] then
		local tmp = 0
		if #file.Find("../materials/"..mat..".*") > 0 then
			tmp = surface.GetTextureID(mat)
		end
		if not tmp then tmp = 0 end
		EGP.MatCache[mat] = tmp
	end
	return EGP.MatCache[mat]
end

--EGP GRAPHICS PROCESSOR FUNCTION
--Yes EGPs Graphics Processor System is now avalible widespread
function EGP.Process(tab)
	for k, v in pairs_sortkeys(tab) do
		local OldTex
		if type(v.material) == "Entity" then
			if v.material:IsValid() and v.material.GPU and v.material.GPU.RT then
				OldTex = WireGPU_matScreen:GetMaterialTexture("$basetexture")
				WireGPU_matScreen:SetMaterialTexture("$basetexture", v.material.GPU.RT)
				surface.SetTexture(WireGPU_texScreen)
			end
		else
			surface.SetTexture(EGP.GetCachedMaterial(v.material))
		end
		--Wait so where am i drawing the elements?
		surface.SetDrawColor(v.R,v.G,v.B,v.A)
		EGP.ELEMENT[v.image](v)--HERE!
		--I love this new code!
		if OldTex then WireGPU_matScreen:SetMaterialTexture("$basetexture", OldTex) end
	end
end		

--Processor?
function EGP.ProcessCache(ent,idx,t)
	local v = ent.Render[idx]
	if not ent.Render[idx] then return end
	if not v.image or v.image == "E" then ent.Render[idx] = {}  end
	if ent.Render[idx].image != v.image then ent.Render[idx] = {}  end
	if not ent.Render[idx].image then table.remove(ent.Render,idx) end
end
--Mabey i do need a betetr name.

--LOGS STUFF!
EGP.Rev = "ERROR"
EGP.Log = {}
function EGP.AddLog(D,R,S)
	local tb = {D=D,R=R,S=S}
	table.insert(EGP.Log,tb)
end
include("EGP/log.lua")