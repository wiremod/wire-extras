-----------------------
--EGP E2 Lib Loader!--
-----------------------
	--if not EGP then
		--include("entities/gmod_wire_egp/Lib.lua")
	--end
--------------------------
--EGP E2 Core Functions!--
--------------------------

--EGP CVAR!
e2function number egpElements()
	return EGP.MaxElements()
end

--EGP CLEAR!
e2function void wirelink:egpClear()
	if not EGP.IsValid(this) then return end
	for idx,_ in pairs(this.Render) do
		this.Render[idx] = { image = "E" }
		this.RenderDirty[idx] = true
	end
end

e2function void wirelink:egpClear(array idxs)
	if not EGP.IsValid(this) then return end
	for _,idx in pairs(idxs) do
		if EGP.IsValid(this, idx, true) then
			this.Render[idx] = { image = "E" }
			this.RenderDirty[idx] = true
		end
	end
end

--EGP Remove
e2function void wirelink:egpRemove(idx)
	idx = math.Round(idx)
	if EGP.IsValid(this, idx, true) then
		this.Render[idx] = { image = "E" }
		this.RenderDirty[idx] = true
	end
end

--EGP CanDraw
e2function number wirelink:egpCanDraw()
	--if not EGP.IsValid(this) then return 0 end
	if EGP.CanDraw(this, true) then return 1 end
	return 0
end

--EGP Draw
e2function number wirelink:egpDraw()
	--if not EGP.IsValid(this) then return 0 end
	if not EGP.CanDraw(this) then return 0 end
	for k,v in pairs(this.Render) do
		if EGP.CacheCompare(this,k) then this:SendEntry(k, v) end
	end
	EGP.ProcessCache(this)
	return 1
end

--[[e2function number wirelink:egpDraw(array idxs)
	if not EGP.CanDraw(this) then return 0 end
	for idx,v in pairs(idxs) do
		if EGP.IsValid(this, idx, true) then
			if not EGP.CacheCompare(this,idx) then return end
			this:SendEntry(idx, v)
		end
	end
	EGP.ProcessCache(this)
	return 1
end
]]--
		
--EGP Material
e2function void wirelink:egpMaterial(idx, string mat)
	if EGP.IsValid(this, idx) then
		this.Render[idx].material = mat
	end
end

--EGP Angle
e2function void wirelink:egpAngle(idx, ang)
	if not EGP.IsValid(this, idx) then return end
	if not this.Render[idx].Ang then return end
	--Yep that means we can make it only work on angle elements
	this.Render[idx].Ang = ang
end

--EGP Set Functions
	e2function void wirelink:egpPos(idx, vector2 Pos)
		if not EGP.IsValid(this, idx) then return end
		if not this.Render[idx].X then return end
		if not this.Render[idx].Y then return end
		this.Render[idx].X = Pos[1]
		this.Render[idx].Y = Pos[2]
		
	end

	e2function void wirelink:egpPos1(idx, vector2 Pos)
		if not EGP.IsValid(this, idx) then return end
		if not this.Render[idx].X1 then return end
		if not this.Render[idx].Y1 then return end
		this.Render[idx].X1 = Pos[1]
		this.Render[idx].Y1 = Pos[2]
	end
	
	e2function void wirelink:egpPos2(idx, vector2 Pos)
		if not EGP.IsValid(this, idx) then return end
		if not this.Render[idx].X2 then return end
		if not this.Render[idx].Y2 then return end
		this.Render[idx].X2 = Pos[1]
		this.Render[idx].Y2 = Pos[2]
	end

	e2function void wirelink:egpSize(idx, vector2 Size)
		if not EGP.IsValid(this, idx) then return end
		if not this.Render[idx].W then return end
		if not this.Render[idx].H then return end
		this.Render[idx].W = Size[1]
		this.Render[idx].H = Size[2]
	end
	
	e2function void wirelink:egpSetText(idx, string Text)
		if not EGP.IsValid(this, idx) then return end
		if not this.Render[idx].text then return end
		this.Render[idx].text = Text
	end
	
--EGP Color
----These Will Be Annoying
e2function void wirelink:egpColor(idx, vector4 color)
	idx = math.Round(idx)
	if not EGP.IsValid(this, idx) then return end
	EGP.SetColor(this,idx,color)
end

e2function void wirelink:egpColor(idx, vector color)
	idx = math.Round(idx)
	if not EGP.IsValid(this, idx) then return end
	EGP.SetColor(this,idx,color)
end

e2function void wirelink:egpColor(idx, vector color, alpha)
	idx = math.Round(idx)
	if not EGP.IsValid(this, idx) then return end
	color[4] = alpha
	EGP.SetColor(this,idx,color)
end

e2function void wirelink:egpColor(idx,r,g,b)
	idx = math.Round(idx)
	if not EGP.IsValid(this, idx) then return end
	EGP.SetColor(this,idx,{r,g,b})
end

e2function void wirelink:egpColor(idx,r,g,b,a)
	idx = math.Round(idx)
	if not EGP.IsValid(this, idx) then return end
	EGP.SetColor(this,idx,{r,g,b,a})
end
----WOW how meany more possible ways can ppl think of to input color?


-----------------------------
--EGP E2 Element Functions!--
-----------------------------

--EGP box
e2function void wirelink:egpBox(idx,vector2 Pos ,vector2 Size)
	idx = math.Round(idx)
	if not EGP.IsValid(this, idx, true) then return end
	this.Render[idx] = {
		image="box",
		X=Pos[1],Y=Pos[2],
		W=Size[1],H=Size[2],
		material="",Ang=0
	}
	EGP.SetColor(this,idx,{})
end

--EGP boxoutline
e2function void wirelink:egpBoxOutline(idx,vector2 Pos ,vector2 Size)
	idx = math.Round(idx)
	if not EGP.IsValid(this, idx, true) then return end
	this.Render[idx] = {
		image="boxoutline",
		X=Pos[1],Y=Pos[2],
		W=Size[1],H=Size[2],
		material=""
	}
	EGP.SetColor(this,idx,{})
end

--EGP line
e2function void wirelink:egpLine(idx,vector2 Start ,vector2 End)
	idx = math.Round(idx)
	if not EGP.IsValid(this, idx, true) then return end
	this.Render[idx] = {
		image="line",
		X=Start[1],Y=Start[2],
		X1=End[1],Y1=End[2]
	}
	EGP.SetColor(this,idx,{})
end

--EGP circle
e2function void wirelink:egpCircle(idx,vector2 Pos ,vector2 Size)
	idx = math.Round(idx)
	if not EGP.IsValid(this, idx, true) then return end
	this.Render[idx] = {
		image="circle",
		X=Pos[1],Y=Pos[2],
		W=Size[1],H=Size[2],
		material=""
	}
	EGP.SetColor(this,idx,{})
end

--EGP triangle
e2function void wirelink:egpTriangle(idx, vector2 Pos1, vector2 Pos2, vector2 Pos3)
	idx = math.Round(idx)
	if not EGP.IsValid(this, idx, true) then return end
	this.Render[idx] = {
		image="triangle",
		X=Pos1[1],Y=Pos1[2],
		X1=Pos2[1],Y1=Pos2[2],
		X2=Pos3[1],Y2=Pos3[2],
		material=""
	}
	EGP.SetColor(this,idx,{})
end

--EGP TEXT STUFF FOR TEXT!
	--EGP text
	e2function void wirelink:egpText(idx, string Text, vector2 Pos)
		idx = math.Round(idx)
		if not EGP.IsValid(this, idx, true) then return end
		this.Render[idx] = {
			image="text",
			X=Pos[1],Y=Pos[2],
			text=Text,
			falign=0
		}
		EGP.SetColor(this,idx,{})
	end

	--EGP textlayout
	e2function void wirelink:egpTextLayout(idx, string Text, vector2 Pos, vector2 Size)
		idx = math.Round(idx)
		if not EGP.IsValid(this, idx, true) then return end
		this.Render[idx] = {
			image="text1",
			X=Pos[1],Y=Pos[2],
			W=Size[1],H=Size[2],
			text=Text,
			falign=0
		}
		EGP.SetColor(this,idx,{})
	end

	--EGP font
	e2function void wirelink:egpFont(idx, string Font, Size)
		local fid = EGP.ValidFonts[string.lower(Font)]
		if not fid then fid = 1 end
		if not EGP.IsValid(this, idx) then return end
		
		this.Render[idx].fsize = Size
		this.Render[idx].fid = fid
		
	end
	e2function void wirelink:egpSetFont(idx, string Font, Size) = e2function void wirelink:egpFont(idx, string Font, Size)
	
	--EGP text-align
	e2function void wirelink:egpTextAlign(idx, halign, valign)
		idx = math.Round(idx)
		if not EGP.IsValid(this, idx) then return end
		if not this.Render[idx].falign then return end
		this.Render[idx].falign = math.Clamp(math.floor(halign), 0, 2) + 10*math.Clamp(math.floor(valign), 0, 2)
	end

--EGP POLY FUNCTION STUFF! By TOMYLOBO!
	local function Draw_Poly(ent, idx, vertex_array)
		ent.Render[idx] = {
			image = "poly",
			vertices = vertex_array,
			material = ""
		}
		EGP.SetColor(ent,idx,{})
	end

	e2function void wirelink:egpPoly(idx, array arr)
		idx = math.Round(idx)
		if not EGP.IsValid(this, idx, true) then return end
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
		if not EGP.IsValid(this, idx, true) then return end
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
	
	e2function void wirelink:egpPolyColor(idx, vector4 color, ...)
		idx = math.Round(idx)
		if not EGP.IsValid(this, idx, true) then return end
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
		EGP.SetColor(this,idx,color)
	end	
	
	e2function void wirelink:egpPolyColor(idx, vector4 color, array arr)
		idx = math.Round(idx)
		if not EGP.IsValid(this, idx, true) then return end
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
		EGP.SetColor(this,idx,color)
	end
	
------------------------------
--EGP E2 Advanced Functions!--
------------------------------

e2function vector2 wirelink:egpToMouse(entity ply)
	--Taken from Wire Graphics Tablet.
	if not EGP.IsValid(this) then return {-1,-1}  end
	if not ply:IsPlayer() or not ply:IsValid() or not ply then return {-1,-1}  end
	
	local monitor = WireGPU_Monitors[this:GetModel()]
	local ang = this:LocalToWorldAngles(monitor.rot)
	local pos = this:LocalToWorld(monitor.offset)
	local h = 512
	local w = h/monitor.RatioX
	local x = -w/2
	local y = -h/2

	local trace = ply:GetEyeTraceNoCursor()
	local ent = trace.Entity

	local cx = -1
	local cy = -1
	if not ent then return end
	if ent == this then
		local dist = trace.Normal:Dot(trace.HitNormal)*trace.Fraction*-16384
		dist = math.max(dist, trace.Fraction*16384-ent:BoundingRadius())
		local cpos = WorldToLocal(trace.HitPos, Angle(), pos, ang)
		cx = (0.5+cpos.x/(monitor.RS*w)) * 512
		cy = (0.5-cpos.y/(monitor.RS*h)) * 512	
	end
	--Thank you eurocracy for telling me the most ovious thing in the world.

	return {cx,cy}
end

--Tomy Lobob
e2function void wirelink:egpMaterialFromScreen(idx, entity gpu)
	if not EGP.IsValid(this, idx) then return end
	if not validEntity(gpu) then return end
	this.Render[idx].material = ("<gpu%d>"):format(gpu:EntIndex())
end
e2function void wirelink:egpMaterialFromScreen(idx, wirelink gpu) = e2function void wirelink:egpMaterialFromScreen(idx, entity gpu)

------------------------------
--EGP E2 EGP1 Old Functions!--
------------------------------

--These allow you to use functions based on EGP V1
--May Be Removed at some point!

--Box
e2function void wirelink:egpBox(idx, posX, posY, sizeX, sizeY, R, G, B, A)
	idx = math.Round(idx)
	if not EGP.IsValid(this, idx ,true) then return end
	
	this.Render[idx] = {
		image="box",
		X=posX,Y=posY,
		W=sizeX,H=sizeY,
		material="",Ang=0
	}
	
	EGP.SetColor(this,idx,{R,G,B,A})
end

e2function void wirelink:egpBox(idx, vector2 pos, vector2 size, vector4 col)
	idx = math.Round(idx)
	if not EGP.IsValid(this, idx ,true) then return end
	
	this.Render[idx] = {
		image="box",
		X=pos[1],Y=pos[2],
		W=size[1],H=size[2],
		material="",Ang=0
	}
	
	EGP.SetColor(this,idx,{col[1],col[2],col[3],col[4]})
end

e2function void wirelink:egpBox(idx, vector2 pos, vector2 size, vector col, A)
	idx = math.Round(idx)
	if not EGP.IsValid(this, idx ,true) then return end
	
	this.Render[idx] = {
		image="box",
		X=pos[1],Y=pos[2],
		W=size[1],H=size[2],
		material="",Ang=0
	}
	
	EGP.SetColor(this,idx,{col[1],col[2],col[3],A})
end

--BoxOutLine
e2function void wirelink:egpBoxoutline(idx, posX, posY, sizeX, sizeY, R, G, B, A)
	idx = math.Round(idx)
	if not EGP.IsValid(this, idx ,true) then return end
	
	this.Render[idx] = {
		image="boxoutline",
		X=posX,Y=posY,
		W=sizeX,H=sizeY,
		material=""
	}
	EGP.SetColor(this,idx,{R,G,B,A})
end
e2function void wirelink:egpBoxoutline(idx, vector2 pos, vector2 size, vector4 col)
	idx = math.Round(idx)
	if not EGP.IsValid(this, idx ,true) then return end
	
	this.Render[idx] = {
		image="boxoutline",
		X=pos[1],Y=pos[2],
		W=size[1],H=size[2],
		material=""
	}
	
	EGP.SetColor(this,idx,{col[1],col[2],col[3],col[4]})
end

e2function void wirelink:egpBoxoutline(idx, vector2 pos, vector2 size, vector col, A)
	idx = math.Round(idx)
	if not EGP.IsValid(this, idx ,true) then return end
	
	this.Render[idx] = {
		image="boxoutline",
		X=pos[1],Y=pos[2],
		W=size[1],H=size[2],
		material=""
	}
	EGP.SetColor(this,idx,{col[1],col[2],col[3],A})
end

--Circle
e2function void wirelink:egpCircle(idx, posX, posY, sizeX, sizeY, R, G, B, A)
	idx = math.Round(idx)
	if not EGP.IsValid(this, idx ,true) then return end
	
	this.Render[idx] = {
		image="circle",
		X=posX,Y=posY,
		W=sizeX,H=sizeY,
		material=""
	}
	
	EGP.SetColor(this,idx,{R,G,B,A})
end

e2function void wirelink:egpCircle(idx, vector2 pos, vector2 size, vector4 col)
	idx = math.Round(idx)
	if not EGP.IsValid(this, idx ,true) then return end
	
	this.Render[idx] = {
		image="circle",
		X=pos[1],Y=pos[2],
		W=size[1],H=size[2],
		material=""
	}
	
	EGP.SetColor(this,idx,{col[1],col[2],col[3],col[4]})
end

e2function void wirelink:egpCircle(idx, vector2 pos, vector2 size, vector col, A)
	idx = math.Round(idx)
	if not EGP.IsValid(this, idx ,true) then return end
	
	this.Render[idx] = {
		image="circle",
		X=pos[1],Y=pos[2],
		W=size[1],H=size[2],
		material=""
	}
	
	EGP.SetColor(this,idx,{col[1],col[2],col[3],A})
end

--Triangle
e2function void wirelink:egpTriangle(idx, posX1, posY1, posX2, posY2, posX3, posY3, sizeX, sizeY, R, G, B, A)
	idx = math.Round(idx)
	if not EGP.IsValid(this, idx ,true) then return end
	
	this.Render[idx] = {
		image="triangle",
		X=posX1,Y=posY1,
		X1=posX2,Y1=posY2,
		X2=posX3,Y2=posY3,
		material=""
	}
	
	EGP.SetColor(this,idx,{R,G,B,A})
end

e2function void wirelink:egpTriangle(idx, vector2 pos1, vector2 pos2, vector2 pos3, vector4 col)
	idx = math.Round(idx)
	if not EGP.IsValid(this, idx ,true) then return end
	
	this.Render[idx] = {
		image="triangle",
		X=pos1[1],Y=pos1[2],
		X1=pos2[1],Y1=pos2[2],
		X2=pos3[1],Y2=pos3[2],
		material=""
	}
	EGP.SetColor(this,idx,{col[1],col[2],col[3],col[4]})
end
e2function void wirelink:egpTriangle(idx, vector2 pos1, vector2 pos2, vector2 pos3, vector col, A)
	idx = math.Round(idx)
	if not EGP.IsValid(this, idx ,true) then return end
	
	this.Render[idx] = {
		image="triangle",
		X=pos1[1],Y=pos1[2],
		X1=pos2[1],Y1=pos2[2],
		X2=pos3[1],Y2=pos3[2],
		material=""
	}
	
	EGP.SetColor(this,idx,{col[1],col[2],col[3],A})
end

--Line
e2function void wirelink:egpLine(idx, posX, posY, sizeX, sizeY, R, G, B, A)
	idx = math.Round(idx)
	if not EGP.IsValid(this, idx ,true) then return end
	
	this.Render[idx] = {
		image="line",
		X=posX,Y=posY,
		X1=sizeX,Y1=sizeY
	}
	
	EGP.SetColor(this,idx,{R,G,B,A})
end

e2function void wirelink:egpLine(idx, vector2 pos, vector2 size, vector4 col)
	idx = math.Round(idx)
	if not EGP.IsValid(this, idx ,true) then return end
	
	this.Render[idx] = {
		image="line",
		X=pos[1],Y=pos[2],
		X1=size[1],Y1=size[2],
	}
	
	EGP.SetColor(this,idx,{col[1],col[2],col[3],col[4]})
end
e2function void wirelink:egpLine(idx, vector2 pos, vector2 size, vector col, A)
	idx = math.Round(idx)
	if not EGP.IsValid(this, idx ,true) then return end
	
	this.Render[idx] = {
		image="line",
		X=pos[1],Y=pos[2],
		X1=size[1],Y1=size[2],
	}
	
	EGP.SetColor(this,idx,{col[1],col[2],col[3],A})
end

--X, Y
e2function void wirelink:egpPos(idx, posX, posY)
	if not EGP.IsValid(this, idx) then return end
	if not this.Render[idx].X then return end
	if not this.Render[idx].Y then return end
	this.Render[idx].X = PosX
	this.Render[idx].Y = PosY
end

e2function void wirelink:egpSize(idx, posX, posY)
	if not EGP.IsValid(this, idx) then return end
	if not this.Render[idx].W then return end
	if not this.Render[idx].H then return end
	this.Render[idx].W = PosX
	this.Render[idx].H = PosY
end

--Text
e2function void wirelink:egpText(idx, string text, vector2 pos, vector4 col)
	idx = math.Round(idx)
	if not EGP.IsValid(this, idx ,true) then return end
	
	this.Render[idx] = {
		image="text",
		text = text,
		X=pos[1],Y=pos[2],
		falign=0
	}
	
	EGP.SetColor(this,idx,{col[1],col[2],col[3],col[4]})
end

e2function void wirelink:egpText(idx, string text, vector2 pos, vector col, A)
	idx = math.Round(idx)
	if not EGP.IsValid(this, idx ,true) then return end
	
	this.Render[idx] = {
		image="text",
		text = text,
		X=pos[1],Y=pos[2],
		falign=0
	}
	
	EGP.SetColor(this,idx,{col[1],col[2],col[3],A})
end

e2function void wirelink:egpText(idx, string text, posX, posY, R, G, B, A)
	idx = math.Round(idx)
	if not EGP.IsValid(this, idx ,true) then return end
	
	this.Render[idx] = {
		image="text",
		text = text,
		X=posX,Y=posY,
		falign=0
	}
	
	EGP.SetColor(this,idx,{R,G,B,A})
end

--Text Layout
e2function void wirelink:egpTextLayout(idx, string text, vector2 pos, vector2 size, vector4 col)
	idx = math.Round(idx)
	if not EGP.IsValid(this, idx ,true) then return end
	
	this.Render[idx] = {
		image="text1",
		text = text,
		X=pos[1],Y=pos[2],
		W=size[1],H=size[2],
		falign=0
	}
	
	EGP.SetColor(this,idx,{col[1],col[2],col[3],col[4]})
end

e2function void wirelink:egpTextLayout(idx, string text, vector2 pos, vector2 size, vector col, A)
	idx = math.Round(idx)
	if not EGP.IsValid(this, idx ,true) then return end
	
	this.Render[idx] = {
		image="text1",
		text = text,
		X=pos[1],Y=pos[2],
		W=size[1],H=size[2],
		falign=0
	}
	
	EGP.SetColor(this,idx,{col[1],col[2],col[3],A})
end

e2function void wirelink:egpTextLayout(idx, string text, posX, posY, sizeX, sizeY, R, G, B, A)
	idx = math.Round(idx)
	if not EGP.IsValid(this, idx ,true) then return end
	
	this.Render[idx] = {
		image="text1",
		text = text,
		X=posX,Y=posY,
		W=sizeX,H=sizeY,
		falign=0
	}
	
	EGP.SetColor(this,idx,{R,G,B,A})
end

---------------------------------
--EGP E2 Data Return Functions!--
---------------------------------

e2function table wirelink:egpGetElement(idx)
	if not EGP.IsValid(this, idx) then return {} end
	return this.Render[idx]
end

e2function array wirelink:egpGetElements()
	if not EGP.IsValid(this, idx) then return {} end
	local idxs = {}
	for idx,_ in pairs(this.Render) do
		table.insert(idxs,idx)
	end
	return idxs
end
e2function table wirelink:egpGetElements(idx) = e2function array wirelink:egpGetElements(idx)




-------------------------------------------------------
-- http://www.weebls-stuff.com/toons/magical+trevor/ :)
-- ----------------------------------------------------
--Is this an easter egg? Who knows?