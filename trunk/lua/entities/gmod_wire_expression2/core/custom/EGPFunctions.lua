local function Update(self,this)
	self.data.EGP.UpdatesNeeded[this] = true
end

--------------------------------------------------------
-- Frames
--------------------------------------------------------
-------------
-- Save
-------------

__e2setcost(15)

-- the commented out parts in the frame saving/loading don't work, that's why they're commented out. But don't worry, people cant freeze servers by spamming them.

e2function void wirelink:egpSaveFrame( string index )
	if (!EGP:ValidEGP( this )) then return end
	if (!index or index == "") then return end
	local bool, frame = EGP:LoadFrame( self.player, nil, index )
	if (bool) then
		if (!EGP:IsDifferent( this.RenderTable, frame )) then return end
	end
	EGP:DoAction( this, self, "SaveFrame", index )
	Update(self,this)
end

e2function void wirelink:egpSaveFrame( index )
	if (!EGP:ValidEGP( this )) then return end
	if (!index) then return end
	local bool, frame = EGP:LoadFrame( self.player, nil, tostring(index) )
	if (bool) then
		if (!EGP:IsDifferent( this.RenderTable, frame )) then return end
	end
	EGP:DoAction( this, self, "SaveFrame", tostring(index) )
	Update(self,this)
end

-------------
-- Load
-------------

__e2setcost(15)

e2function void wirelink:egpLoadFrame( string index )
	if (!EGP:IsAllowed( self, this )) then return end
	if (!index or index == "") then return end
	local bool, frame = EGP:LoadFrame( self.player, nil, index )
	if (bool) then
		if (EGP:IsDifferent( this.RenderTable, frame )) then
			EGP:DoAction( this, self, "LoadFrame", index )
			Update(self,this)
		end
	end
end

e2function void wirelink:egpLoadFrame( number index )
	if (!EGP:IsAllowed( self, this )) then return end
	if (!index) then return end
	local bool, frame = EGP:LoadFrame( self.player, nil, tostring(index) )
	if (bool) then
		if (EGP:IsDifferent( this.RenderTable, frame )) then
			EGP:DoAction( this, self, "LoadFrame", tostring(index) )
			Update(self,this)
		end
	end
end

--------------------------------------------------------
-- Order
--------------------------------------------------------

e2function void wirelink:egpOrder( number index, number order )
	if (!EGP:IsAllowed( self, this )) then return end
	if (index == order) then return end
	local bool, k, v = EGP:HasObject( this, index )
	if (bool) then
		local bool2 = EGP:SetOrder( this, k, order )
		if (bool2) then
			EGP:DoAction( this, self, "SendObject", v )
			Update(self,this)
		end
	end
end

e2function number wirelink:egpOrder( number index )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, k, v = EGP:HasObject( this, index )
	if (bool) then
		return k
	end
	return 0
end

__e2setcost(15)

--------------------------------------------------------
-- Box
--------------------------------------------------------
e2function void wirelink:egpBox( number index, vector2 pos, vector2 size )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, obj = EGP:CreateObject( this, EGP.Objects.Names["Box"], { index = index, w = size[1], h = size[2], x = pos[1], y = pos[2] }, self.player )
	if (bool) then EGP:DoAction( this, self, "SendObject", obj ) Update(self,this) end
end

--------------------------------------------------------
-- Text
--------------------------------------------------------
e2function void wirelink:egpText( number index, string text, vector2 pos )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, obj = EGP:CreateObject( this, EGP.Objects.Names["Text"], { index = index, text = text, x = pos[1], y = pos[2] }, self.player )
	if (bool) then EGP:DoAction( this, self, "SendObject", obj ) Update(self,this) end
end

e2function void wirelink:egpTextLayout( number index, string text, vector2 pos, vector2 size )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, obj = EGP:CreateObject( this, EGP.Objects.Names["TextLayout"], { index = index, text = text, x = pos[1], y = pos[2], w = size[1], h = size[2] }, self.player )
	if (bool) then EGP:DoAction( this, self, "SendObject", obj ) Update(self,this) end
end

__e2setcost(10)

----------------------------
-- Set Text
----------------------------
e2function void wirelink:egpSetText( number index, string text )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, k, v = EGP:HasObject( this, index )
	if (bool) then
		if (EGP:EditObject( v, { text = text } )) then EGP:DoAction( this, self, "SendObject", v ) Update(self,this) end
	end
end

----------------------------
-- Alignment
----------------------------
e2function void wirelink:egpAlign( number index, number halign )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, k, v = EGP:HasObject( this, index )
	if (bool) then
		if (EGP:EditObject( v, { halign = math.Clamp(halign,0,2) } )) then EGP:DoAction( this, self, "SendObject", v ) Update(self,this) end
	end
end

e2function void wirelink:egpAlign( number index, number halign, number valign )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, k, v = EGP:HasObject( this, index )
	if (bool) then
		if (EGP:EditObject( v, { valign = math.Clamp(valign,0,2), halign = math.Clamp(halign,0,2) } )) then EGP:DoAction( this, self, "SendObject", v ) Update(self,this) end
	end
end

----------------------------
-- Font
----------------------------
e2function void wirelink:egpFont( number index, string font )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, k, v = EGP:HasObject( this, index )
	if (bool) then
		local fontid = 0
		for k,v in ipairs( EGP.ValidFonts ) do
			if (v:lower() == font:lower()) then
				fontid = k
				break
			end
		end
		if (EGP:EditObject( v, { fontid = fontid }, self.player )) then EGP:DoAction( this, self, "SendObject", v ) Update(self,this) end
	end
end

e2function void wirelink:egpFont( number index, string font, number size )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, k, v = EGP:HasObject( this, index )
	if (bool) then
		local fontid = 0
		for k,v in ipairs( EGP.ValidFonts ) do
			if (v:lower() == font:lower()) then
				fontid = k
				break
			end
		end
		if (EGP:EditObject( v, { fontid = fontid, size = size }, self.player )) then EGP:DoAction( this, self, "SendObject", v ) Update(self,this) end
	end
end


__e2setcost(15)

--------------------------------------------------------
-- BoxOutline
--------------------------------------------------------
e2function void wirelink:egpBoxOutline( number index, vector2 pos, vector2 size )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, obj = EGP:CreateObject( this, EGP.Objects.Names["BoxOutline"], { index = index, w = size[1], h = size[2], x = pos[1], y = pos[2] }, self.player )
	if (bool) then EGP:DoAction( this, self, "SendObject", obj ) Update(self,this) end
end

--------------------------------------------------------
-- Poly
--------------------------------------------------------

__e2setcost(20)

e2function void wirelink:egpPoly( number index, ... )
	if (!EGP:IsAllowed( self, this )) then return end
	if (!EGP:ValidEGP( this )) then return end
	local args = {...}
	if (#args<3) then return end -- No less than 3
	
	-- Each arg must be a vec2 or vec4
	local vertices = {}
	for k,v in ipairs( args ) do
		if (typeids[k] == "xv2" or typeids[k] == "xv4") then
			n = #vertices
			if (n > 17) then break end -- No more than 17
			vertices[n+1] = { x = v[1], y = v[2] }
			if (typeids[k] == "xv4") then
				vertices[n+1].u = v[3]
				vertices[n+1].v = v[4]
			end
		end
	end
	
	local bool, obj = EGP:CreateObject( this, EGP.Objects.Names["Poly"], { index = index, vertices = vertices }, self.player )
	if (bool) then EGP:DoAction( this, self, "SendObject", obj ) Update(self,this) end
end

e2function void wirelink:egpPoly( number index, array args )
	if (!EGP:IsAllowed( self, this )) then return end
	if (!EGP:ValidEGP( this )) then return end
	if (#args<3) then return end -- No less than 3
	
	-- Each arg must be a vec2 or vec4
	local vertices = {}
	for k,v in ipairs( args ) do
		if (type(v) == "table" and (#v == 2 or #v == 4)) then
			n = #vertices
			if (n > 17) then break end -- No more than 17
			vertices[n+1] = { x = v[1], y = v[2] }
			if (#v == 4) then
				vertices[n+1].u = v[3]
				vertices[n+1].v = v[4]
			end
		end
	end
	
	local bool, obj = EGP:CreateObject( this, EGP.Objects.Names["Poly"], { index = index, vertices = vertices }, self.player )
	if (bool) then EGP:DoAction( this, self, "SendObject", obj ) Update(self,this) end
end

__e2setcost(15)

--------------------------------------------------------
-- Line
--------------------------------------------------------
e2function void wirelink:egpLine( number index, vector2 pos1, vector2 pos2 )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, obj = EGP:CreateObject( this, EGP.Objects.Names["Line"], { index = index, x = pos1[1], y = pos1[2], x2 = pos2[1], y2 = pos2[2] }, self.player )
	if (bool) then EGP:DoAction( this, self, "SendObject", obj ) Update(self,this) end
end

--------------------------------------------------------
-- Circle
--------------------------------------------------------
e2function void wirelink:egpCircle( number index, vector2 pos, vector2 size )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, obj = EGP:CreateObject( this, EGP.Objects.Names["Circle"], { index = index, x = pos[1], y = pos[2], w = size[1], h = size[2] }, self.player )
	if (bool) then EGP:DoAction( this, self, "SendObject", obj ) Update(self,this) end
end

--------------------------------------------------------
-- Circle Outline
--------------------------------------------------------
e2function void wirelink:egpCircleOutline( number index, vector2 pos, vector2 size )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, obj = EGP:CreateObject( this, EGP.Objects.Names["CircleOutline"], { index = index, x = pos[1], y = pos[2], w = size[1], h = size[2] }, self.player )
	if (bool) then EGP:DoAction( this, self, "SendObject", obj ) Update(self,this) end
end

--------------------------------------------------------
-- Triangle
--------------------------------------------------------
e2function void wirelink:egpTriangle( number index, vector2 vert1, vector2 vert2, vector2 vert3 )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, obj = EGP:CreateObject( this, EGP.Objects.Names["Triangle"], { index = index, x = vert1[1], y = vert1[2], x2 = vert2[1], y2 = vert2[2], x3 = vert3[1], y3 = vert3[2] }, self.player )
	if (bool) then EGP:DoAction( this, self, "SendObject", obj ) Update(self,this) end
end

--------------------------------------------------------
-- Triangle Outline
--------------------------------------------------------
e2function void wirelink:egpTriangleOutline( number index, vector2 vert1, vector2 vert2, vector2 vert3 )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, obj = EGP:CreateObject( this, EGP.Objects.Names["TriangleOutline"], { index = index, x = vert1[1], y = vert1[2], x2 = vert2[1], y2 = vert2[2], x3 = vert3[1], y3 = vert3[2] }, self.player )
	if (bool) then EGP:DoAction( this, self, "SendObject", obj ) Update(self,this) end
end

--------------------------------------------------------
-- Wedge
--------------------------------------------------------
e2function void wirelink:egpWedge( number index, vector2 pos, vector2 size )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, obj = EGP:CreateObject( this, EGP.Objects.Names["Wedge"], { index = index, x = pos[1], y = pos[2], w = size[1], h = size[2] }, self.player )
	if (bool) then EGP:DoAction( this, self, "SendObject", obj ) Update(self,this) end
end

--[[ I'm sticking to my policy of not spamming pointless functions.
e2function void wirelink:egpWedge( number index, vector2 pos, vector2 size, number angle, number mouthsize )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, obj = EGP:CreateObject( this, EGP.Objects.Names["Wedge"], { index = index, x = pos[1], y = pos[2], w = size[1], h = size[2], size = mouthsize, angle = angle }, self.player )
	if (bool) then EGP:DoAction( this, self, "SendObject", obj ) Update(self,this) end
end
]]

--------------------------------------------------------
-- Wedge Outline
--------------------------------------------------------
e2function void wirelink:egpWedgeOutline( number index, vector2 pos, vector2 size )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, obj = EGP:CreateObject( this, EGP.Objects.Names["WedgeOutline"], { index = index, x = pos[1], y = pos[2], w = size[1], h = size[2] }, self.player )
	if (bool) then EGP:DoAction( this, self, "SendObject", obj ) Update(self,this) end
end

--[[ I'm sticking to my policy of not spamming pointless functions.
e2function void wirelink:egpWedgeOutline( number index, vector2 pos, vector2 size, number angle, number mouthsize )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, obj = EGP:CreateObject( this, EGP.Objects.Names["WedgeOutline"], { index = index, x = pos[1], y = pos[2], w = size[1], h = size[2], size = mouthsize, angle = angle }, self.player )
	if (bool) then EGP:DoAction( this, self, "SendObject", obj ) Update(self,this) end
end
]]

--------------------------------------------------------
-- Set functions
--------------------------------------------------------

__e2setcost(10)

----------------------------
-- Size
----------------------------
e2function void wirelink:egpSize( number index, vector2 size )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, k, v = EGP:HasObject( this, index )
	if (bool) then
		if (EGP:EditObject( v, { w = size[1], h = size[2] }, self.player )) then EGP:DoAction( this, self, "SendObject", v ) Update(self,this) end
	end
end

e2function void wirelink:egpSize( number index, number size )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, k, v = EGP:HasObject( this, index )
	if (bool) then
		if (EGP:EditObject( v, { size = size }, self.player )) then EGP:DoAction( this, self, "SendObject", v ) Update(self,this) end
	end
end

----------------------------
-- Position
----------------------------
e2function void wirelink:egpPos( number index, vector2 pos )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, k, v = EGP:HasObject( this, index )
	if (bool) then
		if (EGP:EditObject( v, { x = pos[1], y = pos[2] }, self.player )) then EGP:DoAction( this, self, "SendObject", v ) Update(self,this) end
	end
end

----------------------------
-- Angle
----------------------------

e2function void wirelink:egpAngle( number index, number angle )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, k, v = EGP:HasObject( this, index )
	if (bool) then
		if (EGP:EditObject( v, { angle = angle }, self.player )) then EGP:DoAction( this, self, "SendObject", v ) Update(self,this) end
	end
end

-------------
-- Position & Angle
-------------

e2function void wirelink:egpAngle( number index, vector2 worldpos, vector2 axispos, number angle )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, k, v = EGP:HasObject( this, index )
	if (bool) then
		if (v.x and v.y) then
			
			local vec, ang = LocalToWorld(Vector(axispos[1],axispos[2],0), Angle(0,0,0), Vector(worldpos[1],worldpos[2],0), Angle(0,angle,0))
			
			local x = vec.x
			local y = vec.y
			
			angle = -ang.yaw
			
			local t = { x = x, y = y }
			if (v.angle) then t.angle = angle end
			
			if (EGP:EditObject( v, t, self.player )) then EGP:DoAction( this, self, "SendObject", v ) Update(self,this) end
		end
	end
end

----------------------------
-- Color
----------------------------
e2function void wirelink:egpColor( number index, vector4 color )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, k, v = EGP:HasObject( this, index )
	if (bool) then
		if (EGP:EditObject( v, { r = color[1], g = color[2], b = color[3], a = color[4] }, self.player )) then EGP:DoAction( this, self, "SendObject", v ) Update(self,this) end
	end
end

e2function void wirelink:egpColor( number index, vector color )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, k, v = EGP:HasObject( this, index )
	if (bool) then
		if (EGP:EditObject( v, { r = color[1], g = color[2], b = color[3] }, self.player )) then EGP:DoAction( this, self, "SendObject", v ) Update(self,this) end
	end
end

e2function void wirelink:egpColor( number index, r,g,b,a )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, k, v = EGP:HasObject( this, index )
	if (bool) then
		if (EGP:EditObject( v, { r = r, g = g, b = b, a = a }, self.player )) then EGP:DoAction( this, self, "SendObject", v ) Update(self,this) end
	end
end

e2function void wirelink:egpAlpha( number index, number a )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, k, v = EGP:HasObject( this, index )
	if (bool) then
		if (EGP:EditObject( v, { a = a }, self.player )) then EGP:DoAction( this, self, "SendObject", v ) Update(self,this) end
	end
end


----------------------------
-- Material
----------------------------
e2function void wirelink:egpMaterial( number index, string material )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, k, v = EGP:HasObject( this, index )
	if (bool) then
		if (EGP:EditObject( v, { material = material }, self.player )) then EGP:DoAction( this, self, "SendObject", v ) Update(self,this) end
	end
end

--[[ I'm removing this function for now because I've been unable to get it working. If you can fix it, please do.
e2function void wirelink:egpMaterialFromScreen( number index, entity gpu )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, k, v = EGP:HasObject( this, index )
	if (bool and gpu and gpu:IsValid()) then
		if (EGP:EditObject( v, { material = gpu }, self.player )) then EGP:DoAction( this, self, "SendObject", v ) Update(self,this) end
	end
end
]]

----------------------------
-- Parenting
----------------------------
e2function void wirelink:egpParent( number index, number parentindex )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, v = EGP:SetParent( this, index, parentindex )
	if (bool) then EGP:DoAction( this, self, "SendObject", v ) Update(self,this) end
end

e2function void wirelink:egpParentToCursor( number index )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, v = EGP:SetParent( this, index, -1 )
	if (bool) then EGP:DoAction( this, self, "SendObject", v ) Update(self,this) end
end

e2function void wirelink:egpUnParent( number index )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, v = EGP:UnParent( this, index )
	if (bool) then EGP:DoAction( this, self, "SendObject", v ) Update(self,this) end
end

e2function number wirelink:egpParent( number index )
	local bool, k, v = EGP:HasObject( this, index )
	if (bool) then
		if (v.parent) then
			return v.parent
		end
	end
	return 0
end
	
--------------------------------------------------------
-- Clear & Remove
--------------------------------------------------------
e2function void wirelink:egpClear()
	if (!EGP:IsAllowed( self, this )) then return end
	if (EGP:ValidEGP( this )) then
		EGP:DoAction( this, self, "ClearScreen" )
		Update(self,this)
	end
end

e2function void wirelink:egpRemove( number index )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, k, v = EGP:HasObject( this, index )
	if (bool) then
		EGP:DoAction( this, self, "RemoveObject", index )
		Update(self,this)
	end
end

--------------------------------------------------------
-- Get functions
--------------------------------------------------------

__e2setcost(5)

e2function vector2 wirelink:egpPos( number index )
	local bool, k, v = EGP:HasObject( this, index )
	if (bool) then
		if (v.x and v.y) then
			return {v.x, v.y}
		end
	end
	return {-1,-1}
end

e2function vector2 wirelink:egpSize( number index )
	local bool, k, v = EGP:HasObject( this, index )
	if (bool) then
		if (v.w and v.h) then
			return {v.w, v.h}
		end
	end
	return {-1,-1}
end

e2function number wirelink:egpSizeNum( number index )
	local bool, k, v = EGP:HasObject( this, index )
	if (bool) then
		if (v.size) then
			return v.size
		end
	end
	return -1
end

e2function vector4 wirelink:egpColor4( number index )
	local bool, k, v = EGP:HasObject( this, index )
	if (bool) then
		if (v.r and v.g and v.b and v.a) then
			return {v.r,v.g,v.b,v.a}
		end
	end
	return {-1,-1,-1,-1}
end

e2function vector wirelink:egpColor( number index )
	local bool, k, v = EGP:HasObject( this, index )
	if (bool) then
		if (v.r and v.g and v.b) then
			return {v.r,v.g,v.b}
		end
	end
	return {-1,-1,-1}
end

e2function number wirelink:egpAlpha( number index )
	local bool, k, v = EGP:HasObject( this, index )
	if (bool) then
		if (v.a) then
			return v.a
		end
	end
	return -1
end

e2function number wirelink:egpAngle( number index )
	local bool, k, v = EGP:HasObject( this, index )
	if (bool) then
		if (v.angle) then
			return v.angle
		end
	end
	return -1
end

e2function string wirelink:egpMaterial( number index )
	local bool, k, v = EGP:HasObject( this, index )
	if (bool) then
		if (v.material) then
			return v.material
		end
	end
	return ""
end

__e2setcost(10)

e2function array wirelink:egpVertices( number index )
	local bool, k, v = EGP:HasObject( this, index )
	if (bool) then
		if (v.vertices) then
			local ret = {}
			for k2,v2 in ipairs( v.vertices ) do
				table.insert( ret, {v2.x,v2.y} )
			end
			return ret
		elseif (v.x and v.y and v.x2 and v.y2 and v.x3 and v.y3) then
			return {{v.x,v.y},{v.x2,v.y2},{v.x3,v.y3}}
		elseif (v.x and v.y and v.x2 and v.y2) then
			return {{v.x,v.y},{v.x2,v.y2}}
		end
	end
	return {}
end


--------------------------------------------------------
-- Additional Functions
--------------------------------------------------------

__e2setcost(15)

e2function void wirelink:egpCopy( index, fromindex )
	if (!EGP:IsAllowed( self, this )) then return end
	local bool, k, v = EGP:HasObject( this, fromindex )
	if (bool) then
		local copy = table.Copy( v )
		copy.index = index
		local bool2, obj = EGP:CreateObject( this, v.ID, copy, self.player )
		if (bool2) then EGP:DoAction( this, self, "SendObject", obj ) Update(self,this) end
	end
end

__e2setcost(20)

e2function vector2 wirelink:egpCursor( entity ply )
	return EGP:EGPCursor( this, ply )
end

__e2setcost(10)

e2function vector2 egpScrSize( entity ply )
	if (!ply or !ply:IsValid() or !ply:IsPlayer() or !EGP.ScrHW[ply]) then return {-1,-1} end
	return EGP.ScrHW[ply]
end

e2function number egpScrW( entity ply )
	if (!ply or !ply:IsValid() or !ply:IsPlayer() or !EGP.ScrHW[ply]) then return -1 end
	return EGP.ScrHW[ply][1]
end

e2function number egpScrH( entity ply )
	if (!ply or !ply:IsValid() or !ply:IsPlayer() or !EGP.ScrHW[ply]) then return -1 end
	return EGP.ScrHW[ply][2]
end

__e2setcost(15)

e2function number wirelink:egpHasObject( index )
	local bool, _, _ = EGP:HasObject( this, index )
	return bool and 1 or 0
end

__e2setcost(10)

local function errorcheck( x, y )
	local xMul = x[2]-x[1]
	local yMul = y[2]-y[1]
	if (xMul == 0 or yMul == 0) then error("Invalid EGP scale") end
end

e2function void wirelink:egpScale( vector2 xScale, vector2 yScale )
	if (!EGP:IsAllowed( self, this )) then return end
	errorcheck(xScale,yScale)
	EGP:DoAction( this, self, "SetScale", xScale, yScale )
end

e2function void wirelink:egpResolution( vector2 topleft, vector2 bottomright )
	if (!EGP:IsAllowed( self, this )) then return end
	local xScale = { topleft[1], bottomright[1] }
	local yScale = { topleft[2], bottomright[2] }
	errorcheck(xScale,yScale)
	EGP:DoAction( this, self, "SetScale", xScale, yScale )
end

--------------------------------------------------------
-- Useful functions
--------------------------------------------------------

-----------------------------
-- ConVars
-----------------------------

__e2setcost(10)

e2function number wirelink:egpNumObjects()
	if (!EGP:ValidEGP( this )) then return -1 end
	return #this.RenderTable
end

e2function number egpMaxObjects()
	return EGP.ConVars.MaxObjects:GetInt()
end

e2function number egpMaxUmsgPerSecond()
	return EGP.ConVars.MaxPerSec:GetInt()
end

__e2setcost(5)

e2function number egpCanSendUmsg()
	return (EGP:CheckInterval( self.player, true ) and 1 or 0)
end

-----------------------------
-- Queue system
-----------------------------

e2function number egpClearQueue()
	if (EGP.Queue[self.player]) then
		EGP.Queue[self.player] = {}
		EGP:StopQueueTimer( self.player )
		return 1
	end
	return 0
end

--[[ currently does not work
e2 function number wirelink:egpClearQueue()
	if (!EGP:ValidEGP( this )) then return end
	if (EGP.Queue[self.player]) then
		EGP:StopQueueTimer( self.player )
		EGP.Queue[self.player].DONTADDMORE = true
		local removetable = {}
		for k,v in ipairs( EGP.Queue[self.player] ) do
			if (v.Ent == this) then
				table.insert( removetable, k )
				return 1
			end
		end
		for k,v in ipairs( removetable ) do
			table.remove( EGP.Queue[self.player], v )
		end
		EGP:SendQueueItem( self.player )
		EGP:StartQueueTimer( self.player )
		timer.Simple(1,function() EGP.Queue[self.player].DONTADDMORE = nil end)
	end
	return 0
end
]]

__e2setcost(10)

-- Returns the amount of items in your queue
e2function number egpQueue()
	if (EGP.Queue[self.player]) then
		return #EGP.Queue[self.player]
	end
	return 0
end

-- Choose whether or not to make this E2 run when the queue has finished sending all items for <this>
e2function void wirelink:egpRunOnQueue( yesno )
	if (!EGP:ValidEGP( this )) then return end
	local bool = false
	if (yesno != 0) then bool = true end
	self.data.EGP.RunOnEGP[this] = bool
end

-- Returns 1 if the current execution was caused by the EGP queue system OR if the EGP queue system finished in the current execution
e2function number egpQueueClk()
	if (EGP.RunByEGPQueue) then
		return 1
	end
	return 0
end

-- Returns 1 if the current execution was caused by the EGP queue system regarding the entity <screen> OR if the EGP queue system finished in the current execution
e2function number egpQueueClk( wirelink screen )
	if (EGP.RunByEGPQueue and EGP.RunByEGPQueue_Ent == screen) then
		return 1
	end
	return 0
end

-- Returns 1 if the current execution was caused by the EGP queue system regarding the entity <screen> OR if the EGP queue system finished in the current execution
e2function number egpQueueClk( entity screen )
	if (EGP.RunByEGPQueue and EGP.RunByEGPQueue_Ent == screen) then
		return 1
	end
	return 0
end

-- Returns the screen which the queue finished sending items for
e2function entity egpQueueScreen()
	if (EGP.RunByEGPQueue) then
		return EGP.RunByEGPQueue_Ent
	end
end

-- Same as above, except returns wirelink
e2function wirelink egpQueueScreenWirelink()
	if (EGP.RunByEGPQueue) then
		return EGP.RunByEGPQueue_Ent
	end
end

-- Returns the player which ordered the current items to be sent (This is usually yourself, but if you're sharing pp with someone it might be them. Good way to check if someone is fucking with your screens)
e2function entity egpQueuePlayer()
	if (EGP.RunByEGPQueue) then
		return EGP.RunByEGPQueue_ply
	end
end

-- Returns 1 if the current execution was caused by the EGP queue system and the player <ply> was the player whom ordered the item to be sent (This is usually yourself, but if you're sharing pp with someone it might be them.)
e2function number egpQueueClkPly( entity ply )
	if (EGP.RunByEGPQueue and EGP.RunByEGPQueue_ply == ply) then
		return 1
	end
	return 0
end

--------------------------------------------------------
-- Callbacks
--------------------------------------------------------

__e2setcost(nil)

registerCallback("postexecute",function(self)
	for k,v in pairs( self.data.EGP.UpdatesNeeded ) do
		if (k and k:IsValid()) then
			if (v == true) then
				EGP:SendQueueItem( self.player )
				EGP:StartQueueTimer( self.player )
				self.data.EGP[k] = nil
			end
		else
			self.data.EGP[k] = nil
		end
	end
end)

registerCallback("construct",function(self)
	self.data.EGP = {}
	self.data.EGP.RunOnEGP = {}
	self.data.EGP.UpdatesNeeded = {}
end)