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
	if !(isOwner(self, this)) then return end
	for idx,_ in pairs( this.Render or {} ) do
		this.Render[idx] = { image = "E" }
		this.RenderDirty[idx] = true
	end
end
e2function void entity:egpClear() = e2function void wirelink:egpClear()

e2function void wirelink:egpClear(array idxs)
	if !(EGP.IsValid(this)) then return end
	if !(isOwner(self, this)) then return end
	for _,idx in pairs(idxs) do
		if (EGP.IsValid(this, idx, true)) then
			this.Render[idx] = { image = "E" }
			this.RenderDirty[idx] = true
		end
	end
end
e2function void entity:egpClear(array idxs) = e2function void wirelink:egpClear(array idxs)

e2function void wirelink:egpRemove(idx)
	idx = math.Round(idx)
	if !(EGP.IsValid(this, idx, true)) then return end
	if !(isOwner(self, this)) then return end
	this.Render[idx] = { image = "E" }
	this.RenderDirty[idx] = true
end
e2function void entity:egpRemove(idx) = e2function void wirelink:egpRemove(idx)

---------------------------------------------------
--EGP Draw functions
---------------------------------------------------
e2function number wirelink:egpCanDraw()
	if (EGP.CanDraw(this, true)) then return 1 end
	return 0
end
e2function number entity:egpCanDraw() = e2function number wirelink:egpCanDraw()

e2function number wirelink:egpDraw()
	if !(EGP.CanDraw(this)) then return 0 end
	if !(isOwner(self, this)) then return 0 end
	for k,_ in pairs( this.Render ) do
		EGP.SendToClients(this,k)
	end
	return 1
end
e2function number entity:egpDraw() = e2function number wirelink:egpDraw()

---------------------------------------------------
--Material Functions
---------------------------------------------------	
e2function void wirelink:egpMaterial(idx, string mat)
	if !(EGP.IsValid(this, idx)) then return end
	if !(isOwner(self, this)) then return end
	this.Render[idx].material = mat
end
e2function void entity:egpMaterial(idx, string mat) = e2function void wirelink:egpMaterial(idx, string mat)

e2function void wirelink:egpMaterialFromScreen(idx, entity gpu)
	if !(EGP.IsValid(this, idx)) then return end
	if !(isOwner(self, this)) then return end
	if !(validEntity(gpu)) then return end
	this.Render[idx].material = ("<gpu%d>"):format(gpu:EntIndex())
end
e2function void entity:egpMaterialFromScreen(idx, entity gpu) = e2function void wirelink:egpMaterialFromScreen(idx, entity gpu)

e2function void wirelink:egpMaterialFromScreen(idx, wirelink gpu) = e2function void wirelink:egpMaterialFromScreen(idx, entity gpu)
e2function void entity:egpMaterialFromScreen(idx, wirelink gpu) = e2function void entity:egpMaterialFromScreen(idx, entity gpu)

---------------------------------------------------
--Misc Functions
---------------------------------------------------
e2function void wirelink:egpAngle(idx, ang)
	if !(EGP.IsValid(this, idx)) then return end
	if !(isOwner(self, this)) then return end
	if !(this.Render[idx].Ang) then return end
	this.Render[idx].Ang = ang
end
e2function void entity:egpAngle(idx, ang) = e2function void wirelink:egpAngle(idx, ang)

---------------------------------------------------
--Set Position functions
---------------------------------------------------
local function SetPos(ent,idx,x,y,type)
	type = tostring(type) or ""
	if !(EGP.IsValid(ent,idx)) then return end
	if !(isOwner(self, this)) then return end
	local Mem = ent.Render[idx]
	if (Mem["X"..type]) and (x) then
		Mem["X"..type] = x end
	if (Mem["Y"..type]) and (y) then
		Mem["Y"..type] = y end
end

/*Main Positions*/
	e2function void wirelink:egpPos(idx,vector2 Pos)
		if !(isOwner(self, this)) then return end
		SetPos(this,idx,Pos[1],Pos[2])
	end
	e2function void entity:egpPos(idx,vector2 Pos) = e2function void wirelink:egpPos(idx,vector2 Pos)
	
	e2function void wirelink:egpPos(idx,X,Y)
		if !(isOwner(self, this)) then return end
		SetPos(this,idx,X,Y)
	end
	e2function void entity:egpPos(idx,X,Y) = e2function void wirelink:egpPos(idx,X,Y)
	
	e2function void wirelink:egpPosX(idx,X)
		if !(isOwner(self, this)) then return end
		SetPos(this,idx,X)
	end
	e2function void entity:egpPosX(idx,X) = e2function void wirelink:egpPosX(idx,X)
	
	e2function void wirelink:egpPosY(idx,Y)
		if !(isOwner(self, this)) then return end
		SetPos(this,idx,Y)
	end
	e2function void entity:egpPosY(idx,Y) = e2function void wirelink:egpPosY(idx,Y)
	
/*Position 1*/
	e2function void wirelink:egpPos1(idx,vector2 Pos)
		if !(isOwner(self, this)) then return end
		SetPos(this,idx,Pos[1],Pos[2],1)
	end
	e2function void entity:egpPos1(idx,vector2 Pos) = e2function void wirelink:egpPos1(idx,vector2 Pos)
	
	e2function void wirelink:egpPos1(idx,X,Y)
		if !(isOwner(self, this)) then return end
		SetPos(this,idx,X,Y,1)
	end
	e2function void entity:egpPos1(idx,X,Y) = e2function void wirelink:egpPos1(idx,X,Y)
	
	e2function void wirelink:egpPosX1(idx,X)
		if !(isOwner(self, this)) then return end
		SetPos(this,idx,X,1)
	end
	e2function void entity:egpPosX1(idx,X) = e2function void wirelink:egpPosX1(idx,X)
	
	e2function void wirelink:egpPosY1(idx,Y)
		if !(isOwner(self, this)) then return end
		SetPos(this,idx,Y,1)
	end
	e2function void entity:egpPosY1(idx,Y) = e2function void wirelink:egpPosY1(idx,Y)
	
/*Position 2*/
	e2function void wirelink:egpPos2(idx,vector2 Pos)
		if !(isOwner(self, this)) then return end
		SetPos(this,idx,Pos[1],Pos[2],2)
	end
	e2function void entity:egpPos2(idx,vector2 Pos) = e2function void wirelink:egpPos2(idx,vector2 Pos)
	
	e2function void wirelink:egpPos2(idx,X,Y)
		if !(isOwner(self, this)) then return end
		SetPos(this,idx,X,Y,1)
	end
	e2function void entity:egpPos2(idx,X,Y) = e2function void wirelink:egpPos2(idx,X,Y)
	
	e2function void wirelink:egpPosX2(idx,X)
		if !(isOwner(self, this)) then return end
		SetPos(this,idx,X,2)
	end
	e2function void entity:egpPosX2(idx,X) = e2function void wirelink:egpPosX2(idx,X)
	
	e2function void wirelink:egpPosY2(idx,Y)
		if !(isOwner(self, this)) then return end
		SetPos(this,idx,Y,2)
	end
	e2function void entity:egpPosY2(idx,Y) = e2function void wirelink:egpPosY2(idx,Y)
	
---------------------------------------------------
--Set Size functions
---------------------------------------------------
local function SetSize(ent,idx,W,H)
	if !(EGP.IsValid(ent, idx)) then return end
	if (W) then ent.Render[idx].W = W end
	if (H) then ent.Render[idx].H = H end
end

e2function void wirelink:egpSize(idx, vector2 Size)
	if !(isOwner(self, this)) then return end
	SetSize(ent,idx,Size[1],Size[2])
end
e2function void entity:egpSize(idx, vector2 Size) = e2function void wirelink:egpSize(idx, vector2 Size)

e2function void wirelink:egpSize(idx,W,H)
	if !(isOwner(self, this)) then return end
	SetSize(ent,idx,W,H)
end
e2function void entity:egpSize(idx,W,H) = e2function void wirelink:egpSize(idx,W,H)

---------------------------------------------------
--Set TextElement functions
---------------------------------------------------	
e2function void wirelink:egpSetText(idx, string Text)
	if !(EGP.IsValid(this, idx)) then return end
	if !(isOwner(self, this)) then return end
	if !(this.Render[idx].text) then return end
	this.Render[idx].text = Text
end
e2function void entity:egpSetText(idx, string Text) = e2function void wirelink:egpSetText(idx, string Text)

e2function void wirelink:egpFont(idx, string Font, Size)
	if !(EGP.IsValid(this, idx)) then return end
	if !(isOwner(self, this)) then return end
	if !(this.Render[idx].text) then return end
	local fid = EGP.ValidFonts[string.lower(Font)]
	if !(fid) then fid = 1 end
	this.Render[idx].fsize = Size
	this.Render[idx].fid = fid
end
e2function void entity:egpFont(idx, string Font, Size) = e2function void wirelink:egpFont(idx, string Font, Size)
e2function void wirelink:egpSetFont(idx, string Font, Size) = e2function void wirelink:egpFont(idx, string Font, Size)
e2function void entity:egpSetFont(idx, string Font, Size) = e2function void entity:egpFont(idx, string Font, Size)

e2function void wirelink:egpTextAlign(idx, halign, valign)
	idx = math.Round(idx)
	if !(EGP.IsValid(this, idx)) then return end
	if !(isOwner(self, this)) then return end
	if !(this.Render[idx].falign) then return end
	this.Render[idx].falign = math.Clamp(math.floor(halign), 0, 2) + 10*math.Clamp(math.floor(valign), 0, 2)
end
e2function void entity:egpTextAlign(idx, halign, valign) = e2function void wirelink:egpTextAlign(idx, halign, valign)

---------------------------------------------------
--Set Color functions (Uses EGP Lib)
---------------------------------------------------
e2function void wirelink:egpColor(idx, vector4 color)
	if !(isOwner(self, this)) then return end
	EGP.SetColor(this,idx,color)
end
e2function void entity:egpColor(idx, vector4 color) = e2function void wirelink:egpColor(idx, vector4 color)

e2function void wirelink:egpColor(idx, vector color)
	if !(isOwner(self, this)) then return end
	EGP.SetColor(this,idx,color)
end
e2function void entity:egpColor(idx, vector color) = e2function void wirelink:egpColor(idx, vector color)

e2function void wirelink:egpColor(idx, vector color, alpha)
	if !(isOwner(self, this)) then return end
	color[4] = alpha
	EGP.SetColor(this,idx,color)
end
e2function void entity:egpColor(idx, vector color, alpha) = e2function void wirelink:egpColor(idx, vector color, alpha)

e2function void wirelink:egpColor(idx,r,g,b)
	if !(isOwner(self, this)) then return end
	EGP.SetColor(this,idx,{r,g,b})
end
e2function void entity:egpColor(idx,r,g,b) = e2function void wirelink:egpColor(idx,r,g,b)

e2function void wirelink:egpColor(idx,r,g,b,a)
	if !(isOwner(self, this)) then return end
	EGP.SetColor(this,idx,{r,g,b,a})
end
e2function void entity:egpColor(idx,r,g,b,a) = e2function void wirelink:egpColor(idx,r,g,b,a)

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
		if !(isOwner(self, this)) then return end
		MakeBox(this,idx,Pos[1],Pos[2],Size[1],Size[2],{})
	end
	e2function void entity:egpBox(idx,vector2 Pos ,vector2 Size) = e2function void wirelink:egpBox(idx,vector2 Pos ,vector2 Size)
	
	e2function void wirelink:egpBox(idx,vector2 Pos ,vector2 Size ,vector Color)
		if !(isOwner(self, this)) then return end
		MakeBox(this,idx,Pos[1],Pos[2],Size[1],Size[2],Color)
	end
	e2function void entity:egpBox(idx,vector2 Pos ,vector2 Size ,vector Color) = e2function void wirelink:egpBox(idx,vector2 Pos ,vector2 Size ,vector Color)
	
	e2function void wirelink:egpBox(idx,vector2 Pos ,vector2 Size ,vector4 Color)
		if !(isOwner(self, this)) then return end
		MakeBox(this,idx,Pos[1],Pos[2],Size[1],Size[2],Color)
	end
	e2function void entity:egpBox(idx,vector2 Pos ,vector2 Size ,vector4 Color) = e2function void wirelink:egpBox(idx,vector2 Pos ,vector2 Size ,vector4 Color)
	
/*Numbers*/
	e2function void wirelink:egpBox(idx, X,Y, W,H)
		if !(isOwner(self, this)) then return end
		MakeBox(this,idx,X,Y, W,H,{})
	end
	e2function void entity:egpBox(idx, X,Y, W,H) = e2function void wirelink:egpBox(idx, X,Y, W,H)
	
	e2function void wirelink:egpBox(idx, X,Y, W,H,vector Color)
		if !(isOwner(self, this)) then return end
		MakeBox(this,idx,X,Y, W,H,Color)
	end
	e2function void entity:egpBox(idx, X,Y, W,H,vector Color) = e2function void wirelink:egpBox(idx, X,Y, W,H,vector Color)
	
	e2function void wirelink:egpBox(idx, X,Y, W,H,vector4 Color)
		if !(isOwner(self, this)) then return end
		MakeBox(this,idx,X,Y, W,H,Color)
	end
	e2function void entity:egpBox(idx, X,Y, W,H,vector4 Color) = e2function void wirelink:egpBox(idx, X,Y, W,H,vector4 Color)

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
		if !(isOwner(self, this)) then return end
		MakeBoxOutLine(this,idx,Pos[1],Pos[2],Size[1],Size[2],{})
	end
	e2function void entity:egpBoxOutline(idx,vector2 Pos ,vector2 Size) = e2function void wirelink:egpBoxOutline(idx,vector2 Pos ,vector2 Size)

	e2function void wirelink:egpBoxOutline(idx,vector2 Pos ,vector2 Size ,vector Color)
		if !(isOwner(self, this)) then return end
		MakeBoxOutLine(this,idx,Pos[1],Pos[2],Size[1],Size[2],Color)
	end
	e2function void entity:egpBoxOutline(idx,vector2 Pos ,vector2 Size ,vector Color) = e2function void wirelink:egpBoxOutline(idx,vector2 Pos ,vector2 Size ,vector Color)
	
	e2function void wirelink:egpBoxOutline(idx,vector2 Pos ,vector2 Size ,vector4 Color)
		if !(isOwner(self, this)) then return end
		MakeBoxOutLine(this,idx,Pos[1],Pos[2],Size[1],Size[2],Color)
	end
	e2function void entity:egpBoxOutline(idx,vector2 Pos ,vector2 Size ,vector4 Color) = e2function void wirelink:egpBoxOutline(idx,vector2 Pos ,vector2 Size ,vector4 Color)
	
/*Numbers*/
	e2function void wirelink:egpBoxOutline(idx, X,Y, W,H)
		if !(isOwner(self, this)) then return end
		MakeBoxOutLine(this,idx,X,Y, W,H,{})
	end
	e2function void entity:egpBoxOutline(idx, X,Y, W,H) = e2function void wirelink:egpBoxOutline(idx, X,Y, W,H)
	
	e2function void wirelink:egpBoxOutline(idx, X,Y, W,H,vector Color)
		if !(isOwner(self, this)) then return end
		MakeBoxOutLine(this,idx,X,Y, W,H,Color)
	end
	e2function void entity:egpBoxOutline(idx, X,Y, W,H,vector Color) = e2function void wirelink:egpBoxOutline(idx, X,Y, W,H,vector Color)
	
	e2function void wirelink:egpBoxOutline(idx, X,Y, W,H,vector4 Color)
		if !(isOwner(self, this)) then return end
		MakeBoxOutLine(this,idx,X,Y, W,H,Color4)
	end
	e2function void entity:egpBoxOutline(idx, X,Y, W,H,vector4 Color) = e2function void wirelink:egpBoxOutline(idx, X,Y, W,H,vector4 Color)
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
		if !(isOwner(self, this)) then return end
		MakeLine(this,idx,Start[1],Start[2],End[1],End[2],{})
	end
	e2function void entity:egpLine(idx,vector2 Start ,vector2 End) = e2function void wirelink:egpLine(idx,vector2 Start ,vector2 End)
	
	e2function void wirelink:egpLine(idx,vector2 Start ,vector2 End ,vector Color)
		if !(isOwner(self, this)) then return end
		MakeLine(this,idx,Start[1],Start[2],End[1],End[2],Color)
	end
	e2function void entity:egpLine(idx,vector2 Start ,vector2 End ,vector Color) = e2function void wirelink:egpLine(idx,vector2 Start ,vector2 End ,vector Color)
	
	e2function void wirelink:egpLine(idx,vector2 Start ,vector2 End ,vector4 Color)
		if !(isOwner(self, this)) then return end
		MakeLine(this,idx,Start[1],Start[2],End[1],End[2],Color)
	end
	e2function void entity:egpLine(idx,vector2 Start ,vector2 End ,vector4 Color) = e2function void wirelink:egpLine(idx,vector2 Start ,vector2 End ,vector4 Color)
	
/*Numbers*/
	e2function void wirelink:egpLine(idx,X,Y,X1,Y1)
		if !(isOwner(self, this)) then return end
		MakeLine(this,idx,X,Y,X1,Y1,{})
	end
	e2function void entity:egpLine(idx,X,Y,X1,Y1) = e2function void wirelink:egpLine(idx,X,Y,X1,Y1)
	
	e2function void wirelink:egpLine(idx,X,Y,X1,Y1,vector Color)
		if !(isOwner(self, this)) then return end
		MakeLine(this,idx,X,Y,X1,Y1,Color)
	end
	e2function void entity:egpLine(idx,X,Y,X1,Y1,vector Color) = e2function void wirelink:egpLine(idx,X,Y,X1,Y1,vector Color)
	
	e2function void wirelink:egpLine(idx,X,Y,X1,Y1,vector4 Color)
		if !(isOwner(self, this)) then return end
		MakeLine(this,idx,X,Y,X1,Y1,Color)
	end
	e2function void entity:egpLine(idx,X,Y,X1,Y1,vector4 Color) = e2function void wirelink:egpLine(idx,X,Y,X1,Y1,vector4 Color)
	
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
		if !(isOwner(self, this)) then return end
		MakeCircle(this,idx,Pos[1],Pos[2],Size[1],Size[2],{})
	end
	e2function void entity:egpCircle(idx,vector2 Pos ,vector2 Size) = e2function void wirelink:egpCircle(idx,vector2 Pos ,vector2 Size)

	e2function void wirelink:egpCircle(idx,vector2 Pos ,vector2 Size ,vector Color)
		if !(isOwner(self, this)) then return end
		MakeCircle(this,idx,Pos[1],Pos[2],Size[1],Size[2],Color)
	end
	e2function void entity:egpCircle(idx,vector2 Pos ,vector2 Size ,vector Color) = e2function void wirelink:egpCircle(idx,vector2 Pos ,vector2 Size ,vector Color)

	e2function void wirelink:egpCircle(idx,vector2 Pos ,vector2 Size ,vector4 Color)
		if !(isOwner(self, this)) then return end
		MakeCircle(this,idx,Pos[1],Pos[2],Size[1],Size[2],Color)
	end
	e2function void entity:egpCircle(idx,vector2 Pos ,vector2 Size ,vector4 Color) = e2function void wirelink:egpCircle(idx,vector2 Pos ,vector2 Size ,vector4 Color)
	
/*Numbers*/
	e2function void wirelink:egpCircle(idx, X,Y, W,H)
		if !(isOwner(self, this)) then return end
		MakeCircle(this,idx,X,Y, W,H,{})
	end
	e2function void entity:egpCircle(idx, X,Y, W,H) = e2function void wirelink:egpCircle(idx, X,Y, W,H)
	
	e2function void wirelink:egpCircle(idx, X,Y, W,H,vector Color)
		if !(isOwner(self, this)) then return end
		MakeCircle(this,idx,X,Y, W,H,Color)
	end
	e2function void entity:egpCircle(idx, X,Y, W,H,vector Color) = e2function void wirelink:egpCircle(idx, X,Y, W,H,vector Color)
	
	e2function void wirelink:egpCircle(idx, X,Y, W,H,vector4 Color)
		if !(isOwner(self, this)) then return end
		MakeCircle(this,idx,X,Y, W,H,Color)
	end
	e2function void entity:egpCircle(idx, X,Y, W,H,vector4 Color) = e2function void wirelink:egpCircle(idx, X,Y, W,H,vector4 Color)
	
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
		if !(isOwner(self, this)) then return end
		MakeTriangle(this,idx,Pos1[1],Pos1[2],Pos2[1],Pos2[2],Pos3[1],Pos3[2],{})
	end
	e2function void entity:egpTriangle(idx,vector2 Pos1 ,vector2 Pos2,vector2 Pos3) = e2function void wirelink:egpTriangle(idx,vector2 Pos1 ,vector2 Pos2,vector2 Pos3)
	
	e2function void wirelink:egpTriangle(idx,vector2 Pos1 ,vector2 Pos2,vector2 Pos3,vector Color)
		if !(isOwner(self, this)) then return end
		MakeTriangle(this,idx,Pos1[1],Pos1[2],Pos2[1],Pos2[2],Pos3[1],Pos3[2],Color)
	end
	e2function void entity:egpTriangle(idx,vector2 Pos1 ,vector2 Pos2,vector2 Pos3,vector Color) = e2function void wirelink:egpTriangle(idx,vector2 Pos1 ,vector2 Pos2,vector2 Pos3,vector Color)
	
	e2function void wirelink:egpTriangle(idx,vector2 Pos1 ,vector2 Pos2,vector2 Pos3,vector4 Color)
		if !(isOwner(self, this)) then return end
		MakeTriangle(this,idx,Pos1[1],Pos1[2],Pos2[1],Pos2[2],Pos3[1],Pos3[2],Color)
	end
	e2function void entity:egpTriangle(idx,vector2 Pos1 ,vector2 Pos2,vector2 Pos3,vector4 Color) = e2function void wirelink:egpTriangle(idx,vector2 Pos1 ,vector2 Pos2,vector2 Pos3,vector4 Color)
	
/*Numbers*/
	e2function void wirelink:egpTriangle(idx,X1,Y1,X2,Y2,X3,Y3)
		if !(isOwner(self, this)) then return end
		MakeTriangle(this,idx,X1,Y1,X2,Y2,X3,Y3,{})
	end
	e2function void entity:egpTriangle(idx,X1,Y1,X2,Y2,X3,Y3) = e2function void wirelink:egpTriangle(idx,X1,Y1,X2,Y2,X3,Y3)
	
	e2function void wirelink:egpTriangle(idx,X1,Y1,X2,Y2,X3,Y3,vector Color)
		if !(isOwner(self, this)) then return end
		MakeTriangle(this,idx,X1,Y1,X2,Y2,X3,Y3,color)
	end
	e2function void entity:egpTriangle(idx,X1,Y1,X2,Y2,X3,Y3,vector Color) = e2function void wirelink:egpTriangle(idx,X1,Y1,X2,Y2,X3,Y3,vector Color)
	
	e2function void wirelink:egpTriangle(idx,X1,Y1,X2,Y2,X3,Y3,vector4 Color)
		if !(isOwner(self, this)) then return end
		MakeTriangle(this,idx,X1,Y1,X2,Y2,X3,Y3,color)
	end
	e2function void entity:egpTriangle(idx,X1,Y1,X2,Y2,X3,Y3,vector4 Color) = e2function void wirelink:egpTriangle(idx,X1,Y1,X2,Y2,X3,Y3,vector4 Color)

---------------------------------------------------
--Text
---------------------------------------------------
local function MakeText(ent,idx,X,Y,Text,Col)
	idx = math.Round(idx)
	if !(EGP.IsValid(ent, idx, true)) then return end
	ent.Render[idx] = {
		image="text",
		X=X,Y=Y,
		text=Text,
		falign=0
	}
	EGP.SetColor(ent,idx,Col)
end

/*Vector 2*/
	e2function void wirelink:egpText(idx,string Text,vector2 Pos)
		if !(isOwner(self, this)) then return end
		MakeText(this,idx,Pos[1],Pos[2],Text,{})
	end
	e2function void entity:egpText(idx,string Text,vector2 Pos) = e2function void wirelink:egpText(idx,string Text,vector2 Pos)

	e2function void wirelink:egpText(idx,string Text,vector2 Pos,vector Color)
		if !(isOwner(self, this)) then return end
		MakeText(this,idx,Pos[1],Pos[2],Text,Color)
	end
	e2function void entity:egpText(idx,string Text,vector2 Pos,vector Color) = e2function void wirelink:egpText(idx,string Text,vector2 Pos,vector Color)
	
	e2function void wirelink:egpText(idx,string Text,vector2 Pos,vector4 Color)
		if !(isOwner(self, this)) then return end
		MakeText(this,idx,Pos[1],Pos[2],Text,Color)
	end
	e2function void entity:egpText(idx,string Text,vector2 Pos,vector4 Color) = e2function void wirelink:egpText(idx,string Text,vector2 Pos,vector4 Color)
	
/*Numbers*/
	e2function void wirelink:egpText(idx,string Text,X,Y)
		if !(isOwner(self, this)) then return end
		MakeText(this,idx,X,Y,Text,{})
	end
	e2function void entity:egpText(idx,string Text,X,Y) = e2function void wirelink:egpText(idx,string Text,X,Y)
	
	e2function void wirelink:egpText(idx,string Text,X,Y,vector Color)
		if !(isOwner(self, this)) then return end
		MakeText(this,idx,X,Y,Text,Color)
	end
	e2function void entity:egpText(idx,string Text,X,Y,vector Color) = e2function void wirelink:egpText(idx,string Text,X,Y,vector Color)
	
	e2function void wirelink:egpText(idx,string Text,X,Y,vector4 Color)
		if !(isOwner(self, this)) then return end
		MakeText(this,idx,X,Y,Text,Color)
	end
	e2function void entity:egpText(idx,string Text,X,Y,vector4 Color) = e2function void wirelink:egpText(idx,string Text,X,Y,vector4 Color)
	
---------------------------------------------------
--Text Layout
---------------------------------------------------
local function MakeTextLayout(ent,idx,X,Y,W,H,Text,Col)
	idx = math.Round(idx)
	if !(EGP.IsValid(ent, idx, true)) then return end
	ent.Render[idx] = {
		image="text1",
		X=X,Y=Y,
		W=W,H=H,
		text=Text,
		falign=0
	}
	EGP.SetColor(ent,idx,Col)
end

/*Vector 2*/
	e2function void wirelink:egpTextLayout(idx,string Text,vector2 Pos,vector2 Size)
		if !(isOwner(self, this)) then return end
		MakeTextLayout(this,idx,Pos[1],Pos[2],Size[1],Size[2],Text,{})
	end
	e2function void entity:egpTextLayout(idx,string Text,vector2 Pos,vector2 Size) = e2function void wirelink:egpTextLayout(idx,string Text,vector2 Pos,vector2 Size)
	
	e2function void wirelink:egpTextLayout(idx,string Text,vector2 Pos,vector2 Size,vector Color)
		if !(isOwner(self, this)) then return end
		MakeTextLayout(this,idx,Pos[1],Pos[2],Size[1],Size[2],Text,Color)
	end
	e2function void entity:egpTextLayout(idx,string Text,vector2 Pos,vector2 Size,vector Color) = e2function void wirelink:egpTextLayout(idx,string Text,vector2 Pos,vector2 Size,vector Color)

	e2function void wirelink:egpTextLayout(idx,string Text,vector2 Pos,vector2 Size,vector4 Color)
		if !(isOwner(self, this)) then return end
		MakeTextLayout(this,idx,Pos[1],Pos[2],Size[1],Size[2],Text,Color)
	end
	e2function void entity:egpTextLayout(idx,string Text,vector2 Pos,vector2 Size,vector4 Color) = e2function void wirelink:egpTextLayout(idx,string Text,vector2 Pos,vector2 Size,vector4 Color)
	
/*Numbers*/
	e2function void wirelink:egpTextLayout(idx,string Text,X,Y,W,H)
		if !(isOwner(self, this)) then return end
		MakeTextLayout(this,idx,X,Y,W,H,Text,{})
	end
	e2function void entity:egpTextLayout(idx,string Text,X,Y,W,H) = e2function void wirelink:egpTextLayout(idx,string Text,X,Y,W,H)
	
	e2function void wirelink:egpTextLayout(idx,string Text,X,Y,W,H,vector Color)
		if !(isOwner(self, this)) then return end
		MakeTextLayout(this,idx,X,Y,W,HText,Color)
	end
	e2function void entity:egpTextLayout(idx,string Text,X,Y,W,H,vector Color) = e2function void wirelink:egpTextLayout(idx,string Text,X,Y,W,H,vector Color)
	
	e2function void wirelink:egpTextLayout(idx,string Text,X,Y,W,H,vector4 Color)
		if !(isOwner(self, this)) then return end
		MakeTextLayout(this,idx,X,Y,W,HText,Color)
	end
	e2function void entity:egpTextLayout(idx,string Text,X,Y,W,H,vector4 Color) = e2function void wirelink:egpTextLayout(idx,string Text,X,Y,W,H,vector4 Color)

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
	if !(isOwner(self, this)) then return end
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
e2function void entity:egpPoly(idx, array arr) = e2function void wirelink:egpPoly(idx, array arr)

e2function void wirelink:egpPoly(idx, ...)
	idx = math.Round(idx)
	if !(EGP.IsValid(this, idx, true)) then return end
	if !(isOwner(self, this)) then return end
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
e2function void entity:egpPoly(idx, ...) = e2function void wirelink:egpPoly(idx, ...)

e2function void wirelink:egpPolyColor(idx, vector4 color, ...)
	idx = math.Round(idx)
	if !(EGP.IsValid(this, idx, true)) then return end
	if !(isOwner(self, this)) then return end
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
e2function void entity:egpPolyColor(idx, vector4 color, ...) = e2function void wirelink:egpPolyColor(idx, vector4 color, ...)

e2function void wirelink:egpPolyColor(idx, vector4 color, array arr)
	idx = math.Round(idx)
	if !(EGP.IsValid(this, idx, true)) then return end
	if !(isOwner(self, this)) then return end
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
e2function void entity:egpPolyColor(idx, vector4 color, array arr) = e2function void wirelink:egpPolyColor(idx, vector4 color, array arr)

e2function void wirelink:egpPolyColor(idx, vector color, ...)
	idx = math.Round(idx)
	if !(EGP.IsValid(this, idx, true)) then return end
	if !(isOwner(self, this)) then return end
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
e2function void entity:egpPolyColor(idx, vector color, ...) = e2function void wirelink:egpPolyColor(idx, vector color, ...)

e2function void wirelink:egpPolyColor(idx, vector color, array arr)
	idx = math.Round(idx)
	if !(EGP.IsValid(this, idx, true)) then return end
	if !(isOwner(self, this)) then return end
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
e2function void entity:egpPolyColor(idx, vector color, array arr) = e2function void wirelink:egpPolyColor(idx, vector color, array arr)

---------------------------------------------------
--Element Return Functions
---------------------------------------------------
local function returnData(ent,idx,type)
	if !(EGP.IsValid(ent, idx)) then return {} end
	idx = math.Round(idx)
	local data = {}
	if (type == 0 ) then data = ent.Drawn[idx]
	elseif (type == 1 ) then data = ent.Render[idx]
	else 
		if !(this.Frames[idx]) then this.Frames[idx] = {} end
		data = this.Frames[idx]
	end
	return data or {}
end

e2function table wirelink:egpGetElement(idx,type)
	if !(EGP.IsValid(this)) then return {} end
	if !(isOwner(self, this)) then return {} end
	return returnData(this,idx,type)
end
e2function table entity:egpGetElement(idx,type) = e2function table wirelink:egpGetElement(idx,type)

e2function array wirelink:egpGetElements(type)
	if !(EGP.IsValid(this, idx)) then return {} end
	if !(isOwner(self, this)) then return {} end
	local data = {}
	if (type == 0 ) then data = ent.Drawn
	elseif (type == 1 ) then data = ent.Render
	else 
		if !(this.Frames) then this.Frames = {} end
		data = this.Frames
	end
	local idxs = {}
	for idx,_ in pairs(data) do
		table.insert(idxs,idx)
	end
	return idxs
end
e2function array entity:egpGetElements(idx) = e2function array wirelink:egpGetElements(idx)


---------------------------------------------------
--Get Pos
---------------------------------------------------
e2function vector2 wirelink:egpGetPos(idx,type)
	if !(EGP.IsValid(this)) then return {0,0} end
	if !(isOwner(self, this)) then return {0,0} end
	local data = returnData(this,idx,type)
	return {data.X or 0,data.Y or 0}
end
e2function vector2 entity:egpGetPos(idx,type) = e2function vector2 wirelink:egpGetPos(idx,type)

e2function vector2 wirelink:egpGetPos1(idx,type)
	if !(EGP.IsValid(this)) then return {0,0} end
	if !(isOwner(self, this)) then return {0,0} end
	local data = returnData(this,idx,type)
	return {data.X1 or 0,data.Y1 or 0}
end
e2function vector2 entity:egpGetPos1(idx,type) = e2function vector2 wirelink:egpGetPos1(idx,type)

e2function vector2 wirelink:egpGetPos2(idx,type)
	if !(EGP.IsValid(this)) then return {0,0} end
	if !(isOwner(self, this)) then return {0,0} end
	local data = returnData(this,idx,type)
	return {data.X2 or 0,data.Y2 or 0}
end
e2function vector2 entity:egpGetPos2(idx,type) = e2function vector2 wirelink:egpGetPos2(idx,type)

---------------------------------------------------
--Get Size
---------------------------------------------------
e2function vector2 wirelink:egpGetSize(idx,type)
	if !(EGP.IsValid(this)) then return {0,0} end
	if !(isOwner(self, this)) then return {0,0} end
	local data = returnData(this,idx,type)
	return {data.W or 0,data.H or 0}
end
e2function vector2 entity:egpGetSize(idx,type) = e2function vector2 wirelink:egpGetSize(idx,type)

---------------------------------------------------
--Get Text
---------------------------------------------------
e2function string wirelink:egpGetText(idx,type)
	if !(EGP.IsValid(this)) then return {} end
	if !(isOwner(self, this)) then return "" end
	local data = returnData(this,idx,type)
	return data.text or ""
end
e2function string entity:egpGetText(idx,type) = e2function string wirelink:egpGetText(idx,type)

---------------------------------------------------
--Get Color
---------------------------------------------------
e2function vector4 wirelink:egpGetColor(idx,type)
	if !(EGP.IsValid(this)) then return {0,0,0,0} end
	if !(isOwner(self, this)) then return {0,0,0,0} end
	local data = returnData(this,idx,type)
	return {data.R or 0,data.G or 0,data.B or 0,data.A or 0}
end
e2function vector4 entity:egpGetColor(idx,type) = e2function vector4 wirelink:egpGetColor(idx,type)

---------------------------------------------------
--To Mouse Co-Ords (Needs Revising)
---------------------------------------------------
e2function vector2 wirelink:egpToMouse(entity ply)
	if !(EGP.IsValid(this)) then return {-1,-1}  end
	if !(isOwner(self, this)) then return {-1,-1} end
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
e2function vector2 entity:egpToMouse(entity ply) = e2function vector2 wirelink:egpToMouse(entity ply)

---------------------------------------------------
--Frame Saving (BETA)
---------------------------------------------------
e2function void wirelink:egpSaveFrame(idx,type)
	if !(EGP.IsValid(this)) then return end
	idx = math.Round(idx)
	local data = {}
	if (idx <= 1) or (idx >= 11) then return end
	if !(this.Frames) then this.Frames = {} end
	local frame = table.Copy(data)
	for k,v in pairs( frame ) do
		if v.image == "E" then v = {} end
	end
	this.Frames[idx] = frame
end
e2function void entity:egpSaveFrame(idx,type) = e2function void wirelink:egpSaveFrame(idx,type)

e2function void wirelink:egpDeleteFrame(idx)
	if !(EGP.IsValid(this)) then return end
	idx = math.Round(idx)
	if !(this.Frames) then this.Frames = {} end
	this.Frames[idx] = nil
end
e2function void entity:egpDeleteFrame(idx) = e2function void wirelink:egpDeleteFrame(idx)

e2function void wirelink:egpLoadFrame(idx)
	if !(EGP.IsValid(this)) then return end
	idx = math.Round(idx)
	if !(this.Frames) then this.Frames = {} end
	if !(this.Frames[idx]) then this.Frames[idx] = {} end
	for k,v in pairs( this.Render ) do
		v.image = "E"
	end
	for k,v in pairs( this.Frames[idx] ) do
		this.Render[k] = table.Copy(v)
	end
end
e2function void entity:egpLoadFrame(idx) = e2function void wirelink:egpLoadFrame(idx)

-------------------------------------------------------
-- http://www.weebls-stuff.com/toons/magical+trevor/ :)
-------------------------------------------------------
--Is this an easter egg? Who knows?