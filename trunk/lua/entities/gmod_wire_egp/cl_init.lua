--ToDo: add angle and texture
--Note: anybody that knows how to do this pleae do.
include('shared.lua')

local ValidFonts = {}
ValidFonts[1] = "coolvetica"
ValidFonts[2] = "arial"
ValidFonts[3] = "lucida console"
ValidFonts[4] = "trebuchet"
ValidFonts[5] = "arial"
ValidFonts[6] = "courier new"
ValidFonts[7] = "times new roman"

local CachedFonts = {}

local function validEGP(ent)
	if not ValidEntity(ent) then return false end
	if not ent.Render then return false end
	return true
end

function ENT:Initialize()
	self.Poly = {}
	self.Render = {}
	self.GPU = WireGPU(self.Entity)
	self.Render[1] = {
						image = "box",
						posX = 100,
						posY = 100,
						sizeX = 300,
						sizeY = 300,
						colR = 255,
						colG = 0,
						colB = 0,
						colA = 255,
						angle = 0,
						material = "expression 2/cog",
						extra = 0
					}
	self.Render[2] = {
						image = "text",
						posX = 170,
						posY = 200,
						sizeX = 100,
						sizeY = 4,
						colR = 0,
						colG = 0,
						colB = 0,
						colA = 255,
						angle = 0,
						material = "EGP",
						extra = 0
					}
	self.Render[3] = {
						image = "text",
						posX = 175,
						posY = 205,
						sizeX = 90,
						sizeY = 4,
						colR = 255,
						colG = 0,
						colB = 0,
						colA = 255,
						angle = 0,
						material = "EGP",
						extra = 0
					}
	self.FirstDraw = true
	self.NeedsRender = true
end

function ENT:OnRemove()
	self.GPU:Finalize()
end

local MatCache = {}
local function GetCachedMaterial(mat)
	if not mat then return nil end
	if not MatCache[mat] then
		local tmp = 0
		if #file.Find("../materials/"..mat..".*") > 0 then
			tmp = surface.GetTextureID(mat)
		end
		if not tmp then tmp = 0 end
		MatCache[mat] = tmp
	end
	return MatCache[mat]
end

usermessage.Hook("EGPU", function(um)
	local ent = um:ReadEntity()
	local id = um:ReadLong()
	if not validEGP(ent) then return end
	if id == 1 then
		ent.Render = {}
		if ent.FirstDraw then ent.FirstDraw = nil end
	elseif id == 2 then
		if ent.FirstDraw then
			ent.Render = {}
			ent.FirstDraw = nil
		end
		local idx = um:ReadLong()
		ent.Render[idx] = {
						image = um:ReadString(),
						posX = um:ReadShort(),
						posY = um:ReadShort(),
						sizeX = um:ReadShort(),
						sizeY = um:ReadShort(),
						colR = um:ReadShort(),
						colG = um:ReadShort(),
						colB = um:ReadShort(),
						colA = um:ReadShort(),
						angle = um:ReadShort(),
						material = um:ReadString(),
						extra = um:ReadShort(),
						sides = um:ReadShort()
					}
		if ent.Render[idx].material == "" then ent.Render[idx].material = nil end
	elseif id == 3 then
		ent.Render[um:ReadLong()] = nil
	end
	ent.NeedsRender = true
end)

usermessage.Hook("EGPPoly", function(um)
	local ent = um:ReadEntity()
	if not validEGP(ent) then return end
	local idx = um:ReadLong()
	ent.Poly[idx] = {
						colR = um:ReadShort(),
						colG = um:ReadShort(),
						colB = um:ReadShort(),
						colA = um:ReadShort(),
						material = um:ReadString(),
						vertexs = {}
					}
	for i=1,um:ReadShort() do 
		ent.Poly[idx].vertexs[i] = {
										x = um:ReadShort(),
										y = um:ReadShort(),
										u = um:ReadShort(),
										v = um:ReadShort()
									}
	end
					
	if ent.Poly[idx].material"" then ent.Render[idx].material = nil end
	ent.NeedsRender = true
end)

function ENT:clearAll()
	self.GPU:Finalize()
end


function ENT:Draw()
	self:DrawEntityOutline( 0 )
	self.Entity:DrawModel()
	if self.NeedsRender then
		self.GPU:RenderToGPU(function()
			local RatioX = 1
			local w = 512
			local h = 512
			--add changable backround colour some time.
			surface.SetDrawColor(0, 0, 0, 255)
			surface.DrawRect(0, 0, w, h)
			
			for k, v in pairs_sortkeys(self.Render) do
				surface.SetTexture(GetCachedMaterial(v.material))
				surface.SetDrawColor(v.colR,v.colG,v.colB,v.colA)
				if v.image == "box" then
					if v.material then
						surface.SetTexture(GetCachedMaterial(v.material))
						surface.DrawTexturedRect(v.posX,v.posY,v.sizeX,v.sizeY)
					else
						surface.DrawRect(v.posX,v.posY,v.sizeX,v.sizeY)
					end
				elseif v.image == "boxoutline" then
					surface.DrawOutlinedRect(v.posX,v.posY,v.sizeX,v.sizeY)
				elseif v.image == "text" then
					surface.SetTextColor(v.colR,v.colG,v.colB,v.colA)
					local fsize = math.floor(math.Clamp(v.sizeX,4,200))
					local fname = ValidFonts[v.sizeY]
					local ffname = "WireGPU_ConsoleFont"
					if fname then
						ffname = "WireEGP_"..fsize.."_"..fname
						if not CachedFonts[ffname] then
							surface.CreateFont(fname,fsize,800,true,false,ffname)
							CachedFonts[ffname] = true
						end
					end
					surface.SetFont(ffname)
					local textwidth, textheight = surface.GetTextSize(v.material)
					local falign = v.extra or 0
					local X = v.posX - (textwidth * (falign/2))
					local Y = v.posY
					surface.SetTextPos(X,Y)
					surface.DrawText(v.material)
				elseif v.image == "textl" then
					surface.SetTextColor(v.colR,v.colG,v.colB,v.colA)
					local fsize = math.floor(math.Clamp(v.sizeX,4,200))
					local fname = ValidFonts[v.sizeY]
					local ffname = "WireGPU_ConsoleFont"
					if fname then
						ffname = "WireEGP_"..fsize.."_"..fname
						if not CachedFonts[ffname] then
							surface.CreateFont(fname,fsize,800,true,false,ffname)
							CachedFonts[ffname] = true
						end
					end
					surface.SetFont(ffname)
					self.layouter = MakeTextScreenLayouter()
					local falign = v.extra or 0
					self.layouter:layout(v.material, v.posX, v.posY, v.sizeX, v.sizeY, falign)
				elseif v.image == "line" then
					surface.DrawLine(v.posX,v.posY,v.sizeX,v.sizeY)
				elseif v.image == "cir" then
					local h = v.sizeX / 2
					local w  = v.sizeY / 2
					local x = v.posX
					local y = v.posY
					local numsides = v.sides
					local astart = v.angle //0
					local aend = v.extra //7
					local astep = (aend-astart) / numsides
										
					for i=1,numsides do
					local poly = { {} , {} , {} }
											
						poly[1].x = x + w*math.sin(astart+astep*(i+0))
						poly[1].y = y + h*math.cos(astart+astep*(i+0))
						poly[1].u = 0
						poly[1].v = 0

						poly[2].x = x
						poly[2].y = y
						poly[2].u = 0
						poly[2].v = 0

						poly[3].x = x + w*math.sin(astart+astep*(i+1))
						poly[3].y = y + h*math.cos(astart+astep*(i+1))
						poly[3].u = 0
						poly[3].v = 0

						surface.SetDrawColor(v.colR,v.colG,v.colB,v.colA)
						surface.DrawPoly(poly)
					end
					
				elseif v.image == "tri" then
					local poly = { {} , {} , {} }
											
						poly[1].x = v.posX
						poly[1].y = v.posY
						poly[1].u = 0
						poly[1].v = 0

						poly[2].x = v.sizeX
						poly[2].y = v.sizeY
						poly[2].u = 0
						poly[2].v = 0

						poly[3].x = v.angle
						poly[3].y = v.extra
						poly[3].u = 0
						poly[3].v = 0

						surface.SetDrawColor(v.colR,v.colG,v.colB,v.colA)
						surface.DrawPoly(poly)
				end
			end
			if not self.Poly then return end
			for k, v in pairs_sortkeys(self.Poly) do
				if v.material then
							surface.SetTexture(GetCachedMaterial(v.material))
				end
				surface.SetDrawColor(v.colR,v.colG,v.colB,v.colA)
				surface.DrawPoly(v.vertexs)
			end
			
		end)
		self.NeedsRender = false
	end
	
	self.GPU:Render()
	Wire_Render(self.Entity)
end
