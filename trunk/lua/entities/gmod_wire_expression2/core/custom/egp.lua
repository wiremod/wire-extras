local sbox_maxwire_egp_elements = CreateConVar("sbox_maxwire_egp_elements", "40", FCVAR_ARCHIVE)
--local sbox_maxwire_egp_polys = CreateConVar("sbox_maxwire_egp_polys", "40", FCVAR_ARCHIVE)
local NilTab = {
	image = "Empty",
	posX = 0,
	posY = 0,
	sizeX = 0,
	sizeY = 0,
	colR = 0,
	colG = 0,
	colB = 0,
	colA = 0,
	angle = 0,
	material = "",
	extra = 0,
	sides = 0,
}

local ValidFonts = {}
ValidFonts["coolvetica"] = 1
ValidFonts["arial"] = 2
ValidFonts["lucida console"] = 3
ValidFonts["trebuchet"] = 4
ValidFonts["arial"] = 5
ValidFonts["courier new"] = 6
ValidFonts["times new roman"] = 7

local function EGPPlayerInit(ply)
	for _,ent in pairs(ents.FindByClass("gmod_wire_egp")) do
		for k,v in pairs(ent.Render) do
			ent:SendEntry(k, v, ply) --> shared.lua
		end
	end
end
hook.Add("PlayerInitialSpawn", "EGPPlayerInit", EGPPlayerInit)

local function validEGP(ent, idx, ignore_missing)
	if not ValidEntity(ent) then return false end
	if not ent.Render then return false end
	if idx then
		if idx < 0 then return false end
		if idx > sbox_maxwire_egp_elements:GetInt() then return false end
		
		if not ignore_missing then
			if not ent.Render[idx] then return false end
		end
		
		ent.RenderDirty[idx] = true
	end
	return true
end

local function validEGPDraw(ent, noset)
	if not ent.LastPainted or (CurTime() - ent.LastPainted) >= 0.08 then 
		if not noset then ent.LastPainted = CurTime() end
		return true
	end
	return false
end

e2function void wirelink:egpClear()
	if not validEGP(this) then return end
	if not validEGPDraw(this) then return end
	for k, _ in pairs(this.RenderDirty) do
		this.Render[k] = NilTab
	end
end

e2function void wirelink:egpRemove(idx)
	if not validEGP(this, idx, true) then return end
	this.Render[idx] = NilTab
end

e2function number wirelink:egpCanDraw()
	if not validEGP(this) then return 0 end
	if validEGPDraw(this, true) then return 1 end
	return 0
end

e2function number wirelink:egpDraw()
	if not validEGP(this) then return 0 end
	if not validEGPDraw(this) then return 0 end
	for k, _ in pairs(this.RenderDirty) do
		if this.Render[k] then
			local v = this.Render[k]
			this:SendEntry(k, v) --> shared.lua
		end
		
	end
	this.RenderDirty = {}
	return 1
end

local function RenderSetColor(this, idx, R, G, B, A)
	if not validEGP(this, idx) then return false end
	local tbl = this.Render[idx]
	tbl.colR = R
	tbl.colG = G
	tbl.colB = B
	tbl.colA = A
end

local function RenderSetP1(this, idx, pos1X, pos1Y)
	if not validEGP(this, idx) then return false end
	local tbl = this.Render[idx]
	tbl.posX = pos1X
	tbl.posY = pos1Y
end

local function RenderSetP2(this, idx, pos2X, pos2Y)
	if not validEGP(this, idx) then return false end
	local tbl = this.Render[idx]
	tbl.sizeX = pos2X
	tbl.sizeY = pos2Y
end

local function AddGenericRender(this, idx, imgX, pos1X, pos1Y, sizeX, sizeY, R, G, B, A)
	idx = math.Round(idx)
	if not validEGP(this, idx, true) then return false end
	this.Render[idx] = {
		image = imgX,
		material = nil,
		extra = 7,
		sides = 64
	}
	RenderSetP1(this, idx, pos1X, pos1Y)
	RenderSetP2(this, idx, sizeX, sizeY)
	RenderSetColor(this, idx, R, G, B, A)
	return true
end

e2function void wirelink:egpBox(idx, posX, posY, sizeX, sizeY, R, G, B, A)
	AddGenericRender(this, idx, "box", posX, posY, sizeX, sizeY, R, G, B, A)
end
e2function void wirelink:egpBox(idx, vector2 pos, vector2 size, vector4 col)
	AddGenericRender(this, idx, "box", pos[1], pos[2], size[1], size[2], col[1], col[2], col[3], col[4])
end
e2function void wirelink:egpBox(idx, vector2 pos, vector2 size, vector col, A)
	AddGenericRender(this, idx, "box", pos[1], pos[2], size[1], size[2], col[1], col[2], col[3], A)
end

e2function void wirelink:egpBoxoutline(idx, posX, posY, sizeX, sizeY, R, G, B, A)
	AddGenericRender(this, idx, "boxoutline", posX, posY, sizeX, sizeY, R, G, B, A)
end
e2function void wirelink:egpBoxoutline(idx, vector2 pos, vector2 size, vector4 col)
	AddGenericRender(this, idx, "boxoutline", pos[1], pos[2], size[1], size[2], col[1], col[2], col[3], col[4])
end
e2function void wirelink:egpBoxoutline(idx, vector2 pos, vector2 size, vector col, A)
	AddGenericRender(this, idx, "boxoutline", pos[1], pos[2], size[1], size[2], col[1], col[2], col[3], A)
end

e2function void wirelink:egpCircle(idx, posX, posY, sizeX, sizeY, R, G, B, A)
	AddGenericRender(this, idx, "cir", posX, posY, sizeX, sizeY, R, G, B, A)
end
e2function void wirelink:egpCircle(idx, vector2 pos, vector2 size, vector4 col)
	AddGenericRender(this, idx, "cir", pos[1], pos[2], size[1], size[2], col[1], col[2], col[3], col[4])
end
e2function void wirelink:egpCircle(idx, vector2 pos, vector2 size, vector col, A)
	AddGenericRender(this, idx, "cir", pos[1], pos[2], size[1], size[2], col[1], col[2], col[3], A)
end

e2function void wirelink:egpTriangle(idx, posX1, posY1, posX2, posY2, posX3, posY3, sizeX, sizeY, R, G, B, A)
	idx = math.Round(idx)
	AddGenericRender(this, idx, "tri", posX1, posY1, posX2, posY2, posX3, posY3, R, G, B, A)
	this.Render[idx]["angle"] = posX3
	this.Render[idx]["extra"] = posY3
end
e2function void wirelink:egpTriangle(idx, vector2 pos1, vector2 pos2, vector2 pos3, vector4 col)
	idx = math.Round(idx)
	AddGenericRender(this, idx, "tri", pos1[1], pos1[2], pos2[1], pos2[2], col[1], col[2], col[3], col[4])
	this.Render[idx]["angle"] = pos3[1]
	this.Render[idx]["extra"] = pos3[2]
end
e2function void wirelink:egpTriangle(idx, vector2 pos1, vector2 pos2, vector2 pos3, vector col, A)
	idx = math.Round(idx)
	AddGenericRender(this, idx, "tri", pos1[1], pos1[2], pos2[1], pos2[2], col[1], col[2], col[3], A)
	this.Render[idx]["angle"] = pos3[1]
	this.Render[idx]["extra"] = pos3[2]
end



e2function void wirelink:egpLine(idx, posX, posY, sizeX, sizeY, R, G, B, A)
	AddGenericRender(this, idx, "line", posX, posY, sizeX, sizeY, R, G, B, A)
end
e2function void wirelink:egpLine(idx, vector2 pos, vector2 size, vector4 col)
	AddGenericRender(this, idx, "line", pos[1], pos[2], size[1], size[2], col[1], col[2], col[3], col[4])
end
e2function void wirelink:egpLine(idx, vector2 pos, vector2 size, vector col, A)
	AddGenericRender(this, idx, "line", pos[1], pos[2], size[1], size[2], col[1], col[2], col[3], A)
end


e2function void wirelink:egpCircleStart(idx, i)
	idx = math.Round(idx)
	if not validEGP(this, idx) then return end
	this.Render[idx]["angle"] = i
end
e2function void wirelink:egpCircleEnd(idx, i)
	idx = math.Round(idx)
	if not validEGP(this, idx) then return end
	this.Render[idx]["extra"] = i
end
e2function void wirelink:egpCirclePoints(idx, vector2 i)
	idx = math.Round(idx)
	if not validEGP(this, idx) then return end
	this.Render[idx]["angle"] = i[1]
	this.Render[idx]["extra"] = i[2]
end
e2function void wirelink:egpCirclePoints(idx, s, e)
	idx = math.Round(idx)
	if not validEGP(this, idx) then return end
	this.Render[idx]["angle"] = s
	this.Render[idx]["extra"] = e
end
e2function void wirelink:egpCircleSides(idx, s)
	idx = math.Round(idx)
	if not validEGP(this, idx) then return end
	this.Render[idx]["sides"] = math.Clamp(math.Round(s), 3, 64)
end

--X, Y
e2function void wirelink:egpPos(idx, posX, posY)
	RenderSetP1(this, idx, posX, posY)
end
e2function void wirelink:egpPos1(idx, posX, posY)
	RenderSetP1(this, idx, posX, posY)
end
e2function void wirelink:egpPos2(idx, posX, posY)
	RenderSetP2(this, idx, posX, posY)
end
e2function void wirelink:egpSize(idx, posX, posY)
	RenderSetP2(this, idx, posX, posY)
end

--V2
e2function void wirelink:egpPos(idx, vector2 pos)
	RenderSetP1(this, idx, pos[1], pos[2])
end
e2function void wirelink:egpPos1(idx, vector2 pos)
	RenderSetP1(this, idx, pos[1], pos[2])
end
e2function void wirelink:egpPos2(idx, vector2 pos)
	RenderSetP2(this, idx, pos[1], pos[2])
end
e2function void wirelink:egpSize(idx, vector2 pos)
	RenderSetP2(this, idx, pos[1], pos[2])
end

e2function void wirelink:egpColor(idx, vector4 color)
	idx = math.Round(idx)
	if not validEGP(this, idx) then return end
	local entry = this.Render[idx]
	entry.colR = color[1]
	entry.colG = color[2]
	entry.colB = color[3]
	entry.colA = color[4]
end

e2function void wirelink:egpMaterial(idx, string mat)
	if not validEGP(this, idx) then return end
	this.Render[idx].material = mat
end

--------------------------------- text drawing --------------------------------

e2function void wirelink:egpText(idx, string text, vector2 pos, vector4 col)
	if !AddGenericRender(this, idx, "text", pos[1], pos[2], 0, 0, col[1], col[2], col[3], col[4]) then return end
	this.Render[idx].falign = 0
	this.Render[idx].text = text
end
e2function void wirelink:egpText(idx, string text, vector2 pos, vector col, A)
	if !AddGenericRender(this, idx, "text", pos[1], pos[2], 0, 0, col[1], col[2], col[3], A) then return end
	this.Render[idx].falign = 0
	this.Render[idx].text = text
end
e2function void wirelink:egpText(idx, string text, posX, posY, R, G, B, A)
	if !AddGenericRender(this, idx, "text", posX, posY, 0, 0, R, G, B, A) then return end
	this.Render[idx].falign = 0
	this.Render[idx].text = text
end

e2function void wirelink:egpTextLayout(idx, string text, vector2 pos, vector2 size, vector4 col)
	if !AddGenericRender(this, idx, "textl", pos[1], pos[2], size[1], size[2], col[1], col[2], col[3], col[4]) then return end
	this.Render[idx].falign = 0
	this.Render[idx].text = text
end
e2function void wirelink:egpTextLayout(idx, string text, vector2 pos, vector2 size, vector col, A)
	if !AddGenericRender(this, idx, "textl", pos[1], pos[2], size[1], size[2], col[1], col[2], col[3], A) then return end
	this.Render[idx].falign = 0
	this.Render[idx].text = text
end
e2function void wirelink:egpTextLayout(idx, string text, posX, posY, sizeX, sizeY, R, G, B, A)
	if !AddGenericRender(this, idx, "textl", posX, posY, sizeX, sizeY, R, G, B, A) then return end
	this.Render[idx].falign = 0
	this.Render[idx].text = text
end

e2function void wirelink:egpSetText(idx, string text)
	if not validEGP(this, idx) then return end
	this.Render[idx].text = text
end

e2function void wirelink:egpSetFont(idx, string name, number size)
	local fid = ValidFonts[string.lower(name)]
	if not fid then return end
	if not validEGP(this, idx) then return end
	
	local tbl = this.Render[idx]
	tbl.fsize = size
	tbl.fid = fid
end

e2function void wirelink:egpTextAlign(idx, halign, valign)
	idx = math.Round(idx)
	if not validEGP(this, idx) then return end
	if not this.Render[idx].image == "text" then return end
	this.Render[idx].falign = math.Clamp(math.floor(halign), 0, 2) + 10*math.Clamp(math.floor(valign), 0, 2)
end

-------------------------------- polygon drawing -------------------------------

--TomyLobo Made These, Thanks :)
local function Draw_Poly(ent, idx, vertex_array)
	--I lied i made this one.
	ent.Render[idx] = {
		image = "poly",
		vertices = vertex_array,
		colR = 255,
		colG = 255,
		colB = 255,
		colA = 255,
		material = ""
	}
end

e2function void wirelink:egpPoly(idx, array arr)
	idx = math.Round(idx)
	if not validEGP(this, idx, true) then return end
	--I lied again he actualy did make this one.
	local vertex_array = {}
	
	for k, v in pairs_sortkeys(arr) do
		local tp = type(v) == "table" and #v
		if tp == 2 then
			v = { v[1], v[2], 0, 0 }
		elseif tp ~= 4 then
			v = nil
		end
		
		vertex_array[#vertex_array+1] = v
	end
	
	Draw_Poly(this, idx, vertex_array)
end

e2function void wirelink:egpPoly(idx, ...)
	idx = math.Round(idx)
	if not validEGP(this, idx, true) then return end
	--oh he made this one also.
	local arr = { ... }
	local vertex_array = {}
	
	for k, v in ipairs(arr) do
		local tp = typeids[k]
		if tp == "xv2" then
			v = { v[1], v[2], 0, 0 }
		elseif tp ~= "xv4" then
			v = nil
		end
		
		vertex_array[#vertex_array+1] = v
	end
	
	Draw_Poly(this, idx, vertex_array)
end

--this is where i take over the coding again.

-- http://www.weebls-stuff.com/toons/magical+trevor/ :)
-- Tomy Sugested this random link. =P
