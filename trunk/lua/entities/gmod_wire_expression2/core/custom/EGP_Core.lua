---------------------------------------------------
--EGP Max Elements Return Func
---------------------------------------------------
e2function number egpElements()
	return EGP.MaxElements()
end

---------------------------------------------------
--EGP Clear Function's
---------------------------------------------------
e2function void wirelink:egpClear()
	if !(EGP.IsValid(this)) then return end
	for idx,_ in pairs( this.Render or {} ) do
		this.Render[idx] = { image = "E" }
		this.RenderDirty[idx] = true
	end
end

e2function void wirelink:egpClear(array idxs)
	if !(EGP.IsValid(this)) then return end
	for _,idx in pairs(idxs) do
		if (EGP.IsValid(this, idx, true)) then
			this.Render[idx] = { image = "E" }
			this.RenderDirty[idx] = true
		end
	end
end

e2function void wirelink:egpRemove(idx)
	idx = math.Round(idx)
	if !(EGP.IsValid(this, idx, true)) then return end
	this.Render[idx] = { image = "E" }
	this.RenderDirty[idx] = true
end

---------------------------------------------------
--EGP Draw functions
---------------------------------------------------
e2function number wirelink:egpCanDraw()
	if (EGP.CanDraw(this, true)) then return 1 end
	return 0
end

e2function number wirelink:egpDraw()
	if !(EGP.CanDraw(this)) then return 0 end
	for k,_ in pairs( this.Render ) do
		EGP.SendToClients(this,k)
	end
	return 1
end

---------------------------------------------------
--Material Functions
---------------------------------------------------	
e2function void wirelink:egpMaterial(idx, string mat)
	if (EGP.IsValid(this, idx)) then
		this.Render[idx].material = mat
	end
end

e2function void wirelink:egpMaterialFromScreen(idx, entity gpu)
	if !(EGP.IsValid(this, idx)) then return end
	if !(validEntity(gpu)) then return end
	this.Render[idx].material = ("<gpu%d>"):format(gpu:EntIndex())
end
e2function void wirelink:egpMaterialFromScreen(idx, wirelink gpu) = e2function void wirelink:egpMaterialFromScreen(idx, entity gpu)

---------------------------------------------------
--Misc Functions
---------------------------------------------------
e2function void wirelink:egpAngle(idx, ang)
	if !(EGP.IsValid(this, idx)) then return end
	if !(this.Render[idx].Ang) then return end
	this.Render[idx].Ang = ang
end

---------------------------------------------------
--Set Position functions
---------------------------------------------------
local function SetPos(ent,idx,x,y,type)
	type = tostring(type) or ""
	if !(EGP.IsValid(ent,idx)) then return end
	local Mem = ent.Render[idx]
	if (Mem["X"..type]) and (x) then
		Mem["X"..type] = x end
	if (Mem["Y"..type]) and (y) then
		Mem["Y"..type] = y end
end

/*Main Positions*/
	e2function void wirelink:egpPos(idx,vector2 Pos)
		SetPos(this,idx,Pos[1],Pos[2])
	end
	e2function void wirelink:egpPos(idx,X,Y)
		SetPos(this,idx,X,Y)
	end
	e2function void wirelink:egpPosX(idx,X)
		SetPos(this,idx,X)
	end
	e2function void wirelink:egpPosY(idx,Y)
		SetPos(this,idx,Y)
	end

/*Position 1*/
	e2function void wirelink:egpPos1(idx,vector2 Pos)
		SetPos(this,idx,Pos[1],Pos[2],1)
	end
	e2function void wirelink:egpPos1(idx,X,Y)
		SetPos(this,idx,X,Y,1)
	end
	e2function void wirelink:egpPosX1(idx,X)
		SetPos(this,idx,X,1)
	end
	e2function void wirelink:egpPosY1(idx,Y)
		SetPos(this,idx,Y,1)
	end

/*Position 2*/
	e2function void wirelink:egpPos2(idx,vector2 Pos)
		SetPos(this,idx,Pos[1],Pos[2],2)
	end
	e2function void wirelink:egpPos2(idx,X,Y)
		SetPos(this,idx,X,Y,1)
	end
	e2function void wirelink:egpPosX2(idx,X)
		SetPos(this,idx,X,2)
	end
	e2function void wirelink:egpPosY2(idx,Y)
		SetPos(this,idx,Y,2)
	end

---------------------------------------------------
--Set Size functions
---------------------------------------------------
local function SetSize(ent,idx,W,H)
	if !(EGP.IsValid(ent, idx)) then return end
	if (W) then ent.Render[idx].W = W end
	if (H) then ent.Render[idx].H = H end
end

e2function void wirelink:egpSize(idx, vector2 Size)
	SetSize(ent,idx,Size[1],Size[2])
end

e2function void wirelink:egpSize(idx,W,H)
	SetSize(ent,idx,W,H)
end

---------------------------------------------------
--Set TextElement functions
---------------------------------------------------	
e2function void wirelink:egpSetText(idx, string Text)
	if !(EGP.IsValid(this, idx)) then return end
	if !(this.Render[idx].text) then return end
	this.Render[idx].text = Text
end

e2function void wirelink:egpFont(idx, string Font, Size)
	if !(EGP.IsValid(this, idx)) then return end
	if !(this.Render[idx].text) then return end
	local fid = EGP.ValidFonts[string.lower(Font)]
	if !(fid) then fid = 1 end
	this.Render[idx].fsize = Size
	this.Render[idx].fid = fid
end
e2function void wirelink:egpSetFont(idx, string Font, Size) = e2function void wirelink:egpFont(idx, string Font, Size)

e2function void wirelink:egpTextAlign(idx, halign, valign)
	idx = math.Round(idx)
	if !(EGP.IsValid(this, idx)) then return end
	if !(this.Render[idx].falign) then return end
	this.Render[idx].falign = math.Clamp(math.floor(halign), 0, 2) + 10*math.Clamp(math.floor(valign), 0, 2)
end
	
---------------------------------------------------
--Set Color functions (Uses EGP Lib)
---------------------------------------------------
e2function void wirelink:egpColor(idx, vector4 color)
	EGP.SetColor(this,idx,color)
end

e2function void wirelink:egpColor(idx, vector color)
	EGP.SetColor(this,idx,color)
end

e2function void wirelink:egpColor(idx, vector color, alpha)
	color[4] = alpha
	EGP.SetColor(this,idx,color)
end

e2function void wirelink:egpColor(idx,r,g,b)
	EGP.SetColor(this,idx,{r,g,b})
end

e2function void wirelink:egpColor(idx,r,g,b,a)
	EGP.SetColor(this,idx,{r,g,b,a})
end

---------------------------------------------------
--BOX
---------------------------------------------------
local function MakeBox(ent,idx,X,Y,W,H,Col)
	idx = math.Round(idx)
	if !(EGP.IsValid(ent, idx, true)) then return end
	ent.Render[idx] = {
		image="box",
		X=X,Y=Y,
		W=W,H=H,
		material="",Ang=0
	}
	EGP.SetColor(ent,idx,Col)
end

/*Vector 2*/
	e2function void wirelink:egpBox(idx,vector2 Pos ,vector2 Size)
		MakeBox(this,idx,Pos[1],Pos[2],Size[1],Size[2],{})
	end

	e2function void wirelink:egpBox(idx,vector2 Pos ,vector2 Size ,vector Color)
		MakeBox(this,idx,Pos[1],Pos[2],Size[1],Size[2],Color)
	end
	
	e2function void wirelink:egpBox(idx,vector2 Pos ,vector2 Size ,vector4 Color)
		MakeBox(this,idx,Pos[1],Pos[2],Size[1],Size[2],Color)
	end
	
/*Numbers*/
	e2function void wirelink:egpBox(idx, X,Y, W,H)
		MakeBox(this,idx,X,Y, W,H,{})
	end
	
	e2function void wirelink:egpBox(idx, X,Y, W,H,vector Color)
		MakeBox(this,idx,X,Y, W,H,Color)
	end
	
	e2function void wirelink:egpBox(idx, X,Y, W,H,vector4 Color)
		MakeBox(this,idx,X,Y, W,H,Color)
	end

---------------------------------------------------
--BOXOutLine
---------------------------------------------------
local function MakeBoxOutLine(ent,idx,X,Y,W,H,Col)
	idx = math.Round(idx)
	if !(EGP.IsValid(ent, idx, true)) then return end
	ent.Render[idx] = {
		image="boxoutline",
		X=X,Y=Y,
		W=W,H=H,
		material=""
	}
	EGP.SetColor(ent,idx,Col)
end

/*Vector 2*/
	e2function void wirelink:egpBoxOutline(idx,vector2 Pos ,vector2 Size)
		MakeBoxOutLine(this,idx,Pos[1],Pos[2],Size[1],Size[2],{})
	end

	e2function void wirelink:egpBoxOutline(idx,vector2 Pos ,vector2 Size ,vector Color)
		MakeBoxOutLine(this,idx,Pos[1],Pos[2],Size[1],Size[2],Color)
	end
	
	e2function void wirelink:egpBoxOutline(idx,vector2 Pos ,vector2 Size ,vector4 Color)
		MakeBoxOutLine(this,idx,Pos[1],Pos[2],Size[1],Size[2],Color)
	end
	
/*Numbers*/
	e2function void wirelink:egpBoxOutline(idx, X,Y, W,H)
		MakeBoxOutLine(this,idx,X,Y, W,H,{})
	end
	
	e2function void wirelink:egpBoxOutline(idx, X,Y, W,H,vector Color)
		MakeBoxOutLine(this,idx,X,Y, W,H,Color)
	end
	
	e2function void wirelink:egpBoxOutline(idx, X,Y, W,H,vector4 Color)
		MakeBoxOutLine(this,idx,X,Y, W,H,Color4)
	end
--Note may need to do egpBoxOutLine in future (Ask Comunity)

---------------------------------------------------
--Line
---------------------------------------------------
local function MakeLine(ent,idx,X,Y,X1,Y1,Col)
	idx = math.Round(idx)
	if !(EGP.IsValid(ent, idx, true)) then return end
	ent.Render[idx] = {
		image="line",
		X=X,Y=Y,
		X1=X1,Y1=Y1,
		material=""
	}
	EGP.SetColor(ent,idx,Col)
end

/*Vector 2*/
	e2function void wirelink:egpLine(idx,vector2 Start ,vector2 End)
		MakeLine(this,idx,Start[1],Start[2],End[1],End[2],{})
	end

	e2function void wirelink:egpLine(idx,vector2 Start ,vector2 End ,vector Color)
		MakeLine(this,idx,Start[1],Start[2],End[1],End[2],Color)
	end

	e2function void wirelink:egpLine(idx,vector2 Start ,vector2 End ,vector4 Color)
		MakeLine(this,idx,Start[1],Start[2],End[1],End[2],Color)
	end
	
/*Numbers*/
	e2function void wirelink:egpLine(idx,X,Y,X1,Y1)
		MakeLine(this,idx,X,Y,X1,Y1,{})
	end
	
	e2function void wirelink:egpLine(idx,X,Y,X1,Y1,vector Color)
		MakeLine(this,idx,X,Y,X1,Y1,Color)
	end
	
	e2function void wirelink:egpLine(idx,X,Y,X1,Y1,vector4 Color)
		MakeLine(this,idx,X,Y,X1,Y1,Color)
	end

---------------------------------------------------
--Circle
---------------------------------------------------
local function MakeCircle(ent,idx,X,Y,W,H,Col)
	idx = math.Round(idx)
	if !(EGP.IsValid(ent, idx, true)) then return end
	ent.Render[idx] = {
		image="circle",
		X=X,Y=Y,
		W=W,H=H,
		material=""
	}
	EGP.SetColor(ent,idx,Col)
end

/*Vector 2*/
	e2function void wirelink:egpCircle(idx,vector2 Pos ,vector2 Size)
		MakeCircle(this,idx,Pos[1],Pos[2],Size[1],Size[2],{})
	end

	e2function void wirelink:egpCircle(idx,vector2 Pos ,vector2 Size ,vector Color)
		MakeCircle(this,idx,Pos[1],Pos[2],Size[1],Size[2],Color)
	end

	e2function void wirelink:egpCircle(idx,vector2 Pos ,vector2 Size ,vector4 Color)
		MakeCircle(this,idx,Pos[1],Pos[2],Size[1],Size[2],Color)
	end
	
/*Numbers*/
	e2function void wirelink:egpCircle(idx, X,Y, W,H)
		MakeCircle(this,idx,X,Y, W,H,{})
	end
	
	e2function void wirelink:egpCircle(idx, X,Y, W,H,vector Color)
		MakeCircle(this,idx,X,Y, W,H,Color)
	end
	
	e2function void wirelink:egpCircle(idx, X,Y, W,H,vector4 Color)
		MakeCircle(this,idx,X,Y, W,H,Color)
	end

---------------------------------------------------
--Triangle
---------------------------------------------------
local function MakeTriangle(ent,idx,X,Y,X1,Y1,X2,Y2,Col)
	idx = math.Round(idx)
	if !(EGP.IsValid(ent, idx, true)) then return end
	ent.Render[idx] = {
		image="triangle",
		X=X,Y=Y,
		X1=X1,Y1=Y1,
		X2=X2,Y2=Y2,
		material=""
	}
	EGP.SetColor(ent,idx,Col)
end

/*Vector 2*/
	e2function void wirelink:egpTriangle(idx,vector2 Pos1 ,vector2 Pos2,vector2 Pos3)
		MakeTriangle(this,idx,Pos1[1],Pos1[2],Pos2[1],Pos2[2],Pos3[1],Pos3[2],{})
	end

	e2function void wirelink:egpTriangle(idx,vector2 Pos1 ,vector2 Pos2,vector2 Pos3,vector Color)
		MakeTriangle(this,idx,Pos1[1],Pos1[2],Pos2[1],Pos2[2],Pos3[1],Pos3[2],Color)
	end

	e2function void wirelink:egpTriangle(idx,vector2 Pos1 ,vector2 Pos2,vector2 Pos3,vector4 Color)
		MakeTriangle(this,idx,Pos1[1],Pos1[2],Pos2[1],Pos2[2],Pos3[1],Pos3[2],Color)
	end
	
/*Numbers*/
	e2function void wirelink:egpTriangle(idx,X1,Y1,X2,Y2,X3,Y3)
		MakeTriangle(this,idx,X1,Y1,X2,Y2,X3,Y3,{})
	end
	
	e2function void wirelink:egpTriangle(idx,X1,Y1,X2,Y2,X3,Y3,vector Color)
		MakeTriangle(this,idx,X1,Y1,X2,Y2,X3,Y3,color)
	end
	
	e2function void wirelink:egpTriangle(idx,X1,Y1,X2,Y2,X3,Y3,vector4 Color)
		MakeTriangle(this,idx,X1,Y1,X2,Y2,X3,Y3,color)
	end

---------------------------------------------------
--Text
---------------------------------------------------
local function MakeText(ent,idx,X,Y,Text,Col)
	idx = math.Round(idx)
	if !(EGP.IsValid(ent, idx, true)) then return end
	ent.Render[idx] = {
		image="text",
		X=X,Y=X,
		text=Text,
		falign=0
	}
	EGP.SetColor(ent,idx,Col)
end

/*Vector 2*/
	e2function void wirelink:egpText(idx,string Text,vector2 Pos)
		MakeText(this,idx,Pos[1],Pos[2],Text,{})
	end

	e2function void wirelink:egpText(idx,string Text,vector2 Pos,vector Color)
		MakeText(this,idx,Pos[1],Pos[2],Text,Color)
	end

	e2function void wirelink:egpText(idx,string Text,vector2 Pos,vector4 Color)
		MakeText(this,idx,Pos[1],Pos[2],Text,Color)
	end
	
/*Numbers*/
	e2function void wirelink:egpText(idx,string Text,X,Y)
		MakeText(this,idx,X,Y,Text,{})
	end
	
	e2function void wirelink:egpText(idx,string Text,X,Y,vector Color)
		MakeText(this,idx,X,Y,Text,Color)
	end
	
	e2function void wirelink:egpText(idx,string Text,X,Y,vector4 Color)
		MakeText(this,idx,X,Y,Text,Color)
	end

---------------------------------------------------
--Text Layout
---------------------------------------------------
local function MakeTextLayout(ent,idx,X,Y,W,H,Text,Col)
	idx = math.Round(idx)
	if !(EGP.IsValid(ent, idx, true)) then return end
	ent.Render[idx] = {
		image="text1",
		X=X,Y=X,
		W=W,H=H,
		text=Text,
		falign=0
	}
	EGP.SetColor(ent,idx,Col)
end

/*Vector 2*/
	e2function void wirelink:egpTextLayout(idx,string Text,vector2 Pos,vector2 Size)
		MakeTextLayout(this,idx,Pos[1],Pos[2],Size[1],Size[2],Text,{})
	end

	e2function void wirelink:egpTextLayout(idx,string Text,vector2 Pos,vector2 Size,vector Color)
		MakeTextLayout(this,idx,Pos[1],Pos[2],Size[1],Size[2],Text,Color)
	end

	e2function void wirelink:egpTextLayout(idx,string Text,vector2 Pos,vector2 Size,vector4 Color)
		MakeTextLayout(this,idx,Pos[1],Pos[2],Size[1],Size[2],Text,Color)
	end
	
/*Numbers*/
	e2function void wirelink:egpTextLayout(idx,string Text,X,Y,W,H)
		MakeTextLayout(this,idx,X,Y,W,H,Text,{})
	end
	
	e2function void wirelink:egpTextLayout(idx,string Text,X,Y,W,H,vector Color)
		MakeTextLayout(this,idx,X,Y,W,HText,Color)
	end
	
	e2function void wirelink:egpTextLayout(idx,string Text,X,Y,W,H,vector4 Color)
		MakeTextLayout(this,idx,X,Y,W,HText,Color)
	end

---------------------------------------------------
--PolyGons (TomyLobo)
---------------------------------------------------
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
	if !(EGP.IsValid(this, idx, true)) then return end
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
	if !(EGP.IsValid(this, idx, true)) then return end
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
	if !(EGP.IsValid(this, idx, true)) then return end
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
	if !(EGP.IsValid(this, idx, true)) then return end
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

e2function void wirelink:egpPolyColor(idx, vector color, ...)
	idx = math.Round(idx)
	if !(EGP.IsValid(this, idx, true)) then return end
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
	
e2function void wirelink:egpPolyColor(idx, vector color, array arr)
	idx = math.Round(idx)
	if !(EGP.IsValid(this, idx, true)) then return end
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

---------------------------------------------------
--Element Return Functions
---------------------------------------------------
local function returnData(ent,idx,type)
	if !(EGP.IsValid(ent, idx)) then return {} end
	if !(type) then return {} end
	local data = {}
	if (type <= 0 ) then data = ent.Drawn[idx]
	else data = ent.Render[idx] end
	return data or {}
end

e2function table wirelink:egpGetElement(idx,type)
	return returnData(this,idx,type)
end

e2function array wirelink:egpGetElements(type)
	if !(EGP.IsValid(this, idx)) then return {} end
	local data = {}
	if (type <= 0 ) then data = this.Drawn
	else data = this.Render end
	local idxs = {}
	for idx,_ in pairs(data) do
		table.insert(idxs,idx)
	end
	return idxs
end
e2function table wirelink:egpGetElements(idx) = e2function array wirelink:egpGetElements(idx)


---------------------------------------------------
--Get Pos
---------------------------------------------------
e2function vector2 wirelink:egpGetPos(idx,type)
	local data = returnData(this,idx,type)
	return {data.X or 0,data.Y or 0}
end

e2function vector2 wirelink:egpGetPos1(idx,type)
	local data = returnData(this,idx,type)
	return {data.X1 or 0,data.Y1 or 0}
end

e2function vector2 wirelink:egpGetPos2(idx,type)
	local data = returnData(this,idx,type)
	return {data.X2 or 0,data.Y2 or 0}
end

---------------------------------------------------
--Get Size
---------------------------------------------------
e2function vector2 wirelink:egpGetSize(idx,type)
	local data = returnData(this,idx,type)
	return {data.W or 0,data.H or 0}
end

---------------------------------------------------
--Get Text
---------------------------------------------------
e2function string wirelink:egpGetText(idx,type)
	local data = returnData(this,idx,type)
	return data.text or ""
end

---------------------------------------------------
--Get Color
---------------------------------------------------
e2function vector4 wirelink:egpGetColor(idx,type)
	local data = returnData(this,idx,type)
	return {data.R or 0,data.G or 0,data.B or 0,data.A or 0}
end
---------------------------------------------------
--To Mouse Co-Ords (Needs Revising)
---------------------------------------------------
e2function vector2 wirelink:egpToMouse(entity ply)
	if !(EGP.IsValid(this)) then return {-1,-1}  end
	if !(ply) or !(ply:IsValid()) or !(ply:IsPlayer()) then return {-1,-1}  end
	
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
	if !(ent) then return end
	if (ent == this) then
		local dist = trace.Normal:Dot(trace.HitNormal)*trace.Fraction*-16384
		dist = math.max(dist, trace.Fraction*16384-ent:BoundingRadius())
		local cpos = WorldToLocal(trace.HitPos, Angle(), pos, ang)
		cx = (0.5+cpos.x/(monitor.RS*w)) * 512
		cy = (0.5-cpos.y/(monitor.RS*h)) * 512	
	end
	return {cx,cy}
end

-------------------------------------------------------
-- http://www.weebls-stuff.com/toons/magical+trevor/ :)
-------------------------------------------------------
--Is this an easter egg? Who knows?