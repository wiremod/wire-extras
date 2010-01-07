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
	self.GPU = WireGPU(self.Entity)
	self.Render = {
		{
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
		},
		{
			image = "text",
			posX = 170,
			posY = 200,
			colR = 0,
			colG = 0,
			colB = 0,
			colA = 255,
			text = "EGP",
			fsize = 100,
			fid = 4,
			falign = 0,
		},
		{
			image = "text",
			posX = 175,
			posY = 205,
			colR = 255,
			colG = 0,
			colB = 0,
			colA = 255,
			text = "EGP",
			fsize = 90,
			fid = 4,
			falign = 0,
		},
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
	local id = um:ReadChar()
	if not validEGP(ent) then return end
	if id == 1 then
		ent.Render = {}
		ent.FirstDraw = nil
		
	elseif id == 2 then
		if ent.FirstDraw then
			ent.Render = {}
			ent.FirstDraw = nil
		end
		ent:ReceiveEntry(um)
		
	elseif id == 3 then
		local idx = um:ReadLong()
		ent.Render[idx] = nil
	end
	ent.NeedsRender = true
end)

function ENT:clearAll()
	self.GPU:Finalize()
end


function ENT:Draw()
	self:DrawEntityOutline( 0.1 )
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
				if v.image == "box" and v.angle == 0 then
					if v.material then
						surface.SetTexture(GetCachedMaterial(v.material))
						surface.DrawTexturedRect(v.posX,v.posY,v.sizeX,v.sizeY)
					else
						surface.DrawRect(v.posX,v.posY,v.sizeX,v.sizeY)
					end
				elseif v.image == "box" then
					
					local SX = (v.sizeX / 2)
					local SY = (v.sizeY / 2)
					local PX = v.posX + SX
					local PY = v.posY + SY
					local R = v.angle
					local P1 = {x= PX + (math.cos(R) * SX),
								y=PY + (math.sin(R) * SY),
								u=0,v=0}
					local P2 = {x= PX + (math.cos(R+90) * SX),
								y=PY + (math.sin(R+90) * SY),
								u=0,v=0}
					local P3 = {x= PX + (math.cos(R+180) * SX),
								y=PY + (math.sin(R+180) * SY),
								u=0,v=0}
					local P4 = {x= PX + (math.cos(R+270) * SX),
								y=PY + (math.sin(R+270) * SY),
								u=0,v=0}
					local poly = {P1,P2,P3,P4}
					surface.SetDrawColor(v.colR,v.colG,v.colB,v.colA)
					if v.material then
						surface.SetTexture(GetCachedMaterial(v.material))
						surface.DrawPoly(poly)
					else
						surface.DrawPoly(poly)
					end
				elseif v.image == "boxoutline" then
					surface.DrawOutlinedRect(v.posX,v.posY,v.sizeX,v.sizeY)
				elseif v.image == "text" then
					surface.SetTextColor(v.colR,v.colG,v.colB,v.colA)
					local fsize = math.floor(math.Clamp(v.fsize,4,200))
					local fname = ValidFonts[v.fid]
					local ffname = "WireGPU_ConsoleFont"
					if fname then
						ffname = "WireEGP_"..fsize.."_"..fname
						if not CachedFonts[ffname] then
							surface.CreateFont(fname,fsize,800,true,false,ffname)
							CachedFonts[ffname] = true
						end
					end
					surface.SetFont(ffname)
					local textwidth, textheight = surface.GetTextSize(v.text)
					local falign = v.falign
					local halign, valign = falign%10, math.floor(falign/10)
					
					local X = v.posX - (textwidth * (halign/2))
					local Y = v.posY - (textheight * (valign/2))
					surface.SetTextPos(X,Y)
					surface.DrawText(v.text)
				elseif v.image == "textl" then
					surface.SetTextColor(v.colR,v.colG,v.colB,v.colA)
					local fsize = math.floor(math.Clamp(v.fsize,4,200))
					local fname = ValidFonts[v.fid]
					local ffname = "WireGPU_ConsoleFont"
					if fname then
						ffname = "WireEGP_"..fsize.."_"..fname
						if not CachedFonts[ffname] then
							surface.CreateFont(fname,fsize,800,true,false,ffname)
							CachedFonts[ffname] = true
						end
					end
					surface.SetFont(ffname)
					local falign = v.falign
					local halign, valign = falign%10, math.floor(falign/10)
					
					self.layouter = MakeTextScreenLayouter()
					self.layouter:DrawText(v.text, v.posX, v.posY, v.sizeX, v.sizeY, halign, valign) -- vertical alignment is not (yet) supported, but i'll pass it anyway...
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
						local vertices = {
							{
								x = x + w*math.sin(astart+astep*(i+0)),
								y = y + h*math.cos(astart+astep*(i+0)),
								u = 0,
								v = 0,
							},
							{
								x = x,
								y = y,
								u = 0,
								v = 0,
							},
							{
								x = x + w*math.sin(astart+astep*(i+1)),
								y = y + h*math.cos(astart+astep*(i+1)),
								u = 0,
								v = 0,
							},
						}
						
						surface.SetDrawColor(v.colR,v.colG,v.colB,v.colA)
						surface.DrawPoly(vertices)
					end
					
				elseif v.image == "tri" then
					local vertices = {
						{
							x = v.posX,
							y = v.posY,
							u = 0,
							v = 0,
						},
						{
							x = v.sizeX,
							y = v.sizeY,
							u = 0,
							v = 0,
						},
						{
							x = v.angle,
							y = v.extra,
							u = 0,
							v = 0,
						},
					}
					
					surface.SetDrawColor(v.colR,v.colG,v.colB,v.colA)
					surface.DrawPoly(vertices)
				elseif v.image == "poly" then
					if v.material then
						surface.SetTexture(GetCachedMaterial(v.material))
					end
					surface.SetDrawColor(v.colR,v.colG,v.colB,v.colA)
					surface.DrawPoly(v.vertices)
				end
			end
		end)
		self.NeedsRender = false
	end
	
	self.GPU:Render()
	Wire_Render(self.Entity)
end

function egp_clear( um )
   local ent = umsg.ReadEntity()
   ent.Render = {}
   ent.NeedsRender = true
end
usermessage.Hook("EGPClear", egp_clear)