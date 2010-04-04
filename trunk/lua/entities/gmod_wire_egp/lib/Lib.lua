Msg("EGP v2 Beta Installed & Loading\n")

--Need A Main Addon Table! (NEATNES!)
if not EGP then EGP = {} end
--User Message Tables!
if not EGP.USM then EGP.USM = {} end

--Valid Fonts
EGP.ValidFonts = {}
EGP.ValidFonts[1] = "coolvetica"
EGP.ValidFonts[2] = "arial"
EGP.ValidFonts[3] = "lucida console"
EGP.ValidFonts[4] = "trebuchet"
EGP.ValidFonts[5] = "courier new"
EGP.ValidFonts[6] = "times new roman"

--Lets Load The Stuffs
--EGP Ent Funcs
	if SERVER then

		--Server Settings
			EGP.cvar_elements = CreateConVar("sbox_maxwire_egp_elements", "100", FCVAR_ARCHIVE)
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
				if not ent:IsValid() then return false end
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
				
				--ent.Render = {} Temp disabled for a small test
				ent.RenderDirty = {}
				
			end
			
			function EGP.SendV2(ent,idx)
				if not EGP.IsValid(ent) then return false end
				local check = false
				local Drawn = ent.RenderDrawn[idx]
				local element = ent.Render[idx]
				
				if not element then
					return
				elseif not Drawn then
					check = true
				else
					for k,v in pairs( element or {} ) do
						if type(v) != "table" then
							if not Drawn[k] then check = true 
							elseif Drawn[k] != v then check = true end
						else
							for kk,vv in pairs(v) do
								if not Drawn[k][kk] then check = true
								elseif Drawn[k][kk] != vv then check = true end
							end
						end
					end
				end
				
				if check != true then return end

				ent:SendEntry(idx,element)
				if not element.image or element.image == "E" then
					element = nil
					Drawn = nil
				else
					Drawn = table.Copy(element)
				end
			end
			
			--[[function EGP.CacheCompare(ent,idx)
				if not EGP.IsValid(ent) then return false end
				local check = false
				local Drawn = ent.RenderDrawn[idx] or {}
				for k,v in pairs(ent.Render[idx]) do
					Msg("\nEGP: " .. tostring(idx) .. " " .. k .. " ")
					if not Drawn[k] then check = true Msg("not") end
					if Drawn[k] != v then check = true Msg("!=") end
				end
				return check
			end]]
		
		function EGP.USM_Bombardment(ply)
			--hmm i think this func name is an easter egg.
			local egps = ents.FindByClass("wire_egp") --These are my tanks
			for _,ent in pairs( egps or {} ) do
				ent:Retransmit(ply) --And these are my bullets
			end
		end
		hook.Add( "PlayerInitialSpawn", "egp_inital_draw", EGP.USM_Bombardment )
		
		--Log Stuff
			AddCSLuaFile("log.lua")
	end

	if CLIENT then
		--Element Table
			EGP.ELEMENT = {}
			EGP.CachedFonts = {}

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

		--EGP CLIENT LIB MAIN FUNCTION!
		--Yes EGPs Graphics Processor System is now avalible widespread
			function EGP.Process(ent,tbl)
				local tabl
				if not ent or not ent.Render then if tbl then tabl = tbl end
				else tabl = ent.Render end
				if not tabl then return end
				
				for k, v in pairs_sortkeys( tabl or {} ) do
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
					
					local func = EGP.ELEMENT[v.image]
					if func then
						--Wait so where am i drawing the elements?
						func(v,ent)--HERE!
						render.SetScissorRect(0,0,512,512,true) --Exsperment
					end
					--I love this new code!
					if OldTex then WireGPU_matScreen:SetMaterialTexture("$basetexture", OldTex) end
				end
			end		
			
			function EGP.ProcessCache(ent,idx,t)
				local v = ent.Render[idx]
				if not ent.Render[idx] then return end
				if not v.image or v.image == "E" then ent.Render[idx] = {}  end
				if ent.Render[idx].image != v.image then ent.Render[idx] = {}  end
				if not ent.Render[idx].image then table.remove(ent.Render,idx) end
			end
			
		--LOGS STUFF!
			EGP.Rev = "ERROR"
			EGP.Log = {}
			function EGP.AddLog(D,R,S)
				local tb = {D=D,R=R,S=S}
				table.insert(EGP.Log,tb)
			end
			include("log.lua")
	end

