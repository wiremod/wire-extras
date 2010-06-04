Msg("EGP Installed & Loading\n")

---------------------------------------------------
--EGP Global Tables
---------------------------------------------------
EGP = {}
EGP.USM = {}

---------------------------------------------------
--EGP Font List (Got more contact me)
---------------------------------------------------
EGP.ValidFonts = {}
EGP.ValidFonts[1] = "coolvetica"
EGP.ValidFonts[2] = "arial"
EGP.ValidFonts[3] = "lucida console"
EGP.ValidFonts[4] = "trebuchet"
EGP.ValidFonts[5] = "courier new"
EGP.ValidFonts[6] = "times new roman"

---------------------------------------------------
--EGP Home Screen (mattwd0526)
---------------------------------------------------
EGP.HomeScreen = {
		{image="box",X=0,Y=0,W=512,H=512,material="",Ang=0,R=10, G=10, B=10, A=255},
		{image="box",X=256,Y=256,W=362,H=362,material="",Ang=135,R=75, G=75, B=200, A=255},
		{image="box",X=256,Y=256,W=340,H=340,material="",Ang=135,R=10, G=10, B=10, A=255},
		{image="text",X=229,Y=28,text="E",falign=0,fsize=100,fid=4,R=200, G=50, B=50, A=255},
		{image="text",X=50,Y=200,text="G",falign=0,fsize=100,fid=4,R=200, G=50, B=50, A=255},
		{image="text",X=400,Y=200,text="P",falign=0,fsize=100,fid=4,R=200, G=50, B=50, A=255},
		{image="text",X=228,Y=375,text="2",falign=0,fsize=100,fid=4,R=200, G=50, B=50, A=255},
		{image="box",X=256,Y=256,W=256,H=256,material="expression 2/cog",Ang=45,R=255, G=50, B=50, A=255},
		{image="box",X=128,Y=241,W=256,H=30,material="",Ang=0,R=10, G=10, B=10, A=255},
		{image="box",X=241,Y=128,W=30,H=256,material="",Ang=0,R=10, G=10, B=10, A=255},
		{image="circle",X=256,Y=256,W=70,H=70,material="",R=255,G=50,B=50,A=255},
		{image="box",X=256,Y=256,W=362,H=362,material="gui/center_gradient",Ang=135,R=75, G=75, B=200, A=75},
		{image="box",X=256,Y=256,W=362,H=362,material="gui/center_gradient",Ang=45,R=75, G=75, B=200, A=75}
	}

/*Server Side Secion Of Code*/
if (SERVER) then

---------------------------------------------------
--Files
---------------------------------------------------
AddCSLuaFile("log.lua")
AddCSLuaFile("Lib.lua")
AddCSLuaFile("Usm.lua")
AddCSLuaFile("Element.lua")
include("Usm.lua")

---------------------------------------------------
--Cvars
---------------------------------------------------
EGP.cvar_elements = CreateConVar("sbox_maxwire_egp_elements", "100", FCVAR_ARCHIVE)
function EGP.MaxElements()
	return EGP.cvar_elements:GetInt()
end
function EGP.MaxFrames()
	--return ( 1 / EGP.cvar_frames:GetInt() )
	--$TODO: fix this ouputs 1 all the time
end

---------------------------------------------------
--Is EGP Checker
---------------------------------------------------
function EGP.IsValid(ent, idx, ignore_missing)
	if !(ent) then return false end
	if !(ent:IsValid()) then return false end
	if !(ent.Render) then return false end
	if (idx) then
		if (idx < 0) then return false end
		if (idx > EGP.MaxElements()) then return false end
		if !(ignore_missing) then
			if !(ent.Render[idx]) then return false end
		end
		ent.RenderDirty[idx] = true
	end
	return true
end
--$Usage: Will return true if the entity is a valid EGP
--if an idx is specified it will cache it.

---------------------------------------------------
--EGP Can Draw Checker
---------------------------------------------------
function EGP.CanDraw(ent, noset)
	if !(EGP.IsValid(ent)) then return false end
	if !(ent.LastPainted) or ((CurTime() - ent.LastPainted) >= 0.08) then 
		if !(noset) then ent.LastPainted = CurTime() end
		return true
	end
	return false
end

---------------------------------------------------
--EGP Element Color helper func
---------------------------------------------------
function EGP.SetColor(ent,idx,c)
	idx = math.Round(idx)
	if !(EGP.IsValid(ent, idx, true)) then return end
	local tbl = ent.Render[idx]
	tbl.R = c[1] or 255
	tbl.G = c[2] or 255
	tbl.B = c[3] or 255
	tbl.A = c[4] or 255
end

---------------------------------------------------
--EGP Cache Processor (Used to Lower USM Count)
---------------------------------------------------
/* This may look complicated but all its doing is checking to see if any of the data in the element tabels
have changed so it knows if it should send it. Also if the element if empty or cleared it will remove itself.
This system may need to be looked at for alternative and faster means in future.*/
function EGP.SendToClients(ent,idx)
	if !(EGP.IsValid(ent)) then return false end
	local check = false
	local Drawn = ent.RenderDrawn[idx] or {}
	local element = ent.Render[idx] or {}
	if !(element) then return
	elseif !(Drawn) then check = true
	else
		for k,v in pairs( element ) do
			if type(v) != "table" then
				if !(Drawn[k]) then check = true 
				elseif (Drawn[k] != v) then check = true end
			else
				for kk,vv in pairs(v) do
					local Mem = Drawn[k] or {}
					if !(Mem[kk]) then check = true
					elseif (Mem[kk] != vv) then check = true end
				end
			end
		end
	end
	if (check != true) then return end
	ent:SendEntry(idx,element)
	if !(element.image) or (element.image == "E") then
		element = nil
		Drawn = nil
	else
		Drawn = table.Copy(element)
	end
end

---------------------------------------------------
--Send the EGP data to newly joined players.
---------------------------------------------------
/*Yes the name of this function was intended as a pun.*/
function EGP.USM_Bombardment(ply)
	local egps = ents.FindByClass("wire_egp")
	for _,ent in pairs( egps or {} ) do
		ent:Retransmit(ply)
	end
end
hook.Add( "PlayerInitialSpawn", "egp_inital_draw", EGP.USM_Bombardment )

---------------------------------------------------
--EGP Refresher
---------------------------------------------------
function EGP.Refresh(ent)
	if !(EGP.IsValid(ent)) then return end
	for idx,_ in pairs( ent.Render ) do
		ent.Render[idx] = { image = "E" }
		ent.RenderDirty[idx] = true
		EGP.SendToClients(ent,idx)
	end
end

/*Client Side Part of Code*/	
else
---------------------------------------------------
--EGP Client Tables
---------------------------------------------------
EGP.ELEMENT = {}
EGP.CachedFonts = {}
EGP.MatCache = {}

---------------------------------------------------
--EGP Material Cach (Needs Revising)
---------------------------------------------------	
function EGP.GetCachedMaterial(mat)
	if !(mat) then return nil end
	if !(EGP.MatCache[mat]) then
		local tmp = 0
		if #file.Find("../materials/"..mat..".*") > 0 then
			tmp = surface.GetTextureID(mat)
		end
		if !(tmp) then tmp = 0 end
		EGP.MatCache[mat] = tmp
	end
	return EGP.MatCache[mat]
end

---------------------------------------------------
--EGP Texture Copyer (GPU Helper Func)
---------------------------------------------------	
/*Remeber kids: Always reset the base texture back after wards*/	
EGP.BaseTexture = Material("EGP->Ignore")
EGP.BaseTextureID = surface.GetTextureID("EGP->Ignore")
function EGP.CopyEGPMaterial(ent)
	if !(ent:IsValid()) then return end
	if !(ent.GPU) then return end
	if !(ent.GPU.RT) then return end
	local OldTex = EGP.BaseTexture:GetMaterialTexture("$basetexture")
	EGP.BaseTexture:SetMaterialTexture("$basetexture", ent.GPU.RT)
	surface.SetTexture(EGP.BaseTextureID)
	return OldTex
end

---------------------------------------------------
--EGP Set Material (Use's Texture Copyer)
---------------------------------------------------	
function EGP.SetMaterial( mat )
	if (type(mat) == "Entity") then
		return EGP.CopyEGPMaterial( mat )
	else
		surface.SetTexture(EGP.GetCachedMaterial(mat))
	end
end
---------------------------------------------------
--EGP Main Processor Function (How EGP Draws)
---------------------------------------------------	
function EGP.Process(ent,tbl)
	local tabl
	if !(ent) or !(ent.Render) then
		if (tbl) then tabl = tbl end
		/*Allowing you to provide a custom element table
		by defult is uses entity's Render table*/
	else tabl = ent.Render end
	
	if !(tabl) then return end --No Element Table Quit before we fps lag the client!
	
	/*Ok here we start to process the element table into elements*/
	for k,v in pairs_sortkeys( tabl ) do
		--(Stage 1) Set Material
		local OldTex = EGP.SetMaterial(v.material)
		
		--(Stage 2) Find Element
		local func = EGP.ELEMENT[v.image]
		
		--(Stage 3) Draw Element Using pcall
		local ok,report
		if (func) then ok,report = pcall(func,v,ent)
		else report = "Unkown element " .. v.image end
		
		--(Stage 4) Report Erorrs
		if !(ok) then
			if !(EGP.ErrorTime) or ((CurTime() - EGP.ErrorTime) >= 10) then
				report = report or "Unkown Error occured"
				print( "EGP Error: " .. report )
				GAMEMODE:AddNotify("EGP has encountered an error!", NOTIFY_ERROR , 5);
				surface.PlaySound( "Resource/warning.wav" )
				EGP.ErrorTime = CurTime()
			end
		end
		
		--(Stage 5) Reset base texture if we need to.
		if (OldTex) then EGP.BaseTexture:SetMaterialTexture("$basetexture", OldTex) end
	end
end		

---------------------------------------------------
--EGP Process Cache (Removes empty elements)
---------------------------------------------------			
function EGP.ProcessCache(ent,idx,t)
	local v = ent.Render[idx]
	if !(ent.Render[idx]) then return end
	if !(v.image) or (v.image == "E") then ent.Render[idx] = {}  end
	if (ent.Render[idx].image != v.image) then ent.Render[idx] = {}  end
	if !(ent.Render[idx].image) then table.remove(ent.Render,idx) end
end

---------------------------------------------------
--EGP SVN Log (I seriosuly need to remove this)
---------------------------------------------------
EGP.Rev = "ERROR"
EGP.Log = {}
function EGP.AddLog(D,R,S)
	local tb = {D=D,R=R,S=S}
	table.insert(EGP.Log,tb)
end

---------------------------------------------------
--Files
---------------------------------------------------
print("EGP Loading USM Layouts")
include("Usm.lua")
print("EGP Loading Elements")
include("Element.lua")
for k,v in pairs(EGP.ELEMENT) do
	print("--Added: " .. k)
end
include("log.lua")

/*End of Client Side Code*/	
end

