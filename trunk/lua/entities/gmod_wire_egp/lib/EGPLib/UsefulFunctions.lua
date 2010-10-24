--------------------------------------------------------
-- e2function Helper functions
--------------------------------------------------------
local EGP = EGP

----------------------------
-- Table IsEmpty
----------------------------

function EGP:EmptyTable( tbl ) return next(tbl) == nil end

----------------------------
-- SetScale
----------------------------

function EGP:SetScale( ent, x, y )
	if (!self:ValidEGP( ent ) or !x or !y) then return end
	ent.xScale = { x[1], x[2] }
	ent.yScale = { y[1], y[2] }
	if (x[1] != 0 or x[2] != 512 or y[1] != 0 or y[2] != 512) then
		ent.Scaling = true
	else
		ent.Scaling = false
	end
end

----------------------------
-- IsDifferent check
----------------------------
function EGP:IsDifferent( tbl1, tbl2 )
	if (self:EmptyTable( tbl1 ) != self:EmptyTable( tbl2 )) then return true end -- One is empty, the other is not

	for k,v in ipairs( tbl1 ) do
		if (!tbl2[k] or tbl2[k].ID != v.ID) then -- Different ID?
			return true
		else
			for k2,v2 in pairs( v ) do
				if (k2 != "BaseClass") then
					if (tbl2[k][k2] or tbl2[k][k2] != v2) then -- Is any setting different?
						return true
					end
				end
			end
		end
	end
	
	for k,v in ipairs( tbl2 ) do -- Were any objects removed?
		if (!tbl1[k]) then
			return true
		end
	end
	
	return false
end
			

----------------------------
-- IsAllowed check
----------------------------
function EGP:IsAllowed( E2, Ent )
	if (!EGP:ValidEGP( Ent )) then return false end
	if (E2 and E2.entity and E2.entity:IsValid()) then
		if (!E2Lib.isOwner(E2,Ent)) then
			return E2Lib.isFriend(E2.player,E2Lib.getOwner(Ent))
		else
			return true
		end
	end
	return false
end

--------------------------------------------------------
-- Transmitting / Receiving helper functions
--------------------------------------------------------
-----------------------
-- Material
-----------------------
EGP.SavedMaterials = {}
function EGP:GetSavedMaterial( Mat )
	if (!table.HasValue( self.SavedMaterials, Mat )) then
		self:SaveMaterial( Mat )
		return "?" .. Mat
	else
		local str
		for k,v in ipairs( self.SavedMaterials ) do
			if (v == Mat) then
				str = k
				break
			end
		end
		return "." .. str
	end
end

function EGP:SaveMaterial( Mat )
	if (!Mat or #Mat == 0) then return end
	if (!table.HasValue( self.SavedMaterials, Mat )) then
		table.insert( self.SavedMaterials, Mat )
	end
end

function EGP:SendMaterial( obj ) -- ALWAYS use this when sending material
	local str
	
	-- "!" = entity
	-- "?" = string
	-- "." = number
	
	if (type(obj.material) == "Entity") then
		if (!obj.material:IsValid()) then 
			str = ""
		else
			str = "!" .. obj.material:EntIndex()
		end
	elseif (type(obj.material) == "string") then
		if (obj.material == "") then
			str = ""
		else
			str = self:GetSavedMaterial( obj.material )
		end
	end
	EGP.umsg.String( str )
end

function EGP:ReceiveMaterial( tbl, um ) -- ALWAYS use this when receiving material
	local mat = um:ReadString()
	local first = mat:Left(1)
	if (first == "!" or first == "?" or first == ".") then
		mat = mat:Right(-2)
		if (first == "!") then
			mat = Entity(tonumber(mat))
		elseif (first == ".") then
			for k,v in pairs( self.SavedMaterials ) do
				if (mat == tostring(k)) then
					mat = v
					break
				end
			end
		elseif (first == "?") then
			self:SaveMaterial( mat )
		end
	end
	tbl.material = mat
end

-----------------------
-- Other
-----------------------
function EGP:SendPosSize( obj )
	EGP.umsg.Short( obj.w )
	EGP.umsg.Short( obj.h )
	EGP.umsg.Short( obj.x )
	EGP.umsg.Short( obj.y )
end

function EGP:SendColor( obj )
	EGP.umsg.Char( obj.r - 128 )
	EGP.umsg.Char( obj.g - 128 )
	EGP.umsg.Char( obj.b - 128 )
	if (obj.a) then EGP.umsg.Char( obj.a - 128 ) end
end

function EGP:ReceivePosSize( tbl, um ) -- Used with SendPosSize
	tbl.w = um:ReadShort()
	tbl.h = um:ReadShort()
	tbl.x = um:ReadShort()
	tbl.y = um:ReadShort()
end

function EGP:ReceiveColor( tbl, obj, um ) -- Used with SendColor
	tbl.r = um:ReadChar() + 128
	tbl.g = um:ReadChar() + 128
	tbl.b = um:ReadChar() + 128
	if (obj.a) then tbl.a = um:ReadChar() + 128 end
end

--------------------------------------------------------
-- Other
--------------------------------------------------------
function EGP:ValidEGP( Ent )
	return (Ent and ValidEntity( Ent ) and (Ent:GetClass() == "gmod_wire_egp" or Ent:GetClass() == "gmod_wire_egp_hud" or Ent:GetClass() == "gmod_wire_egp_emitter"))
end


-- Saving Screen width and height
if (CLIENT) then
	usermessage.Hook("EGP_ScrWH_Request",function(um)
		RunConsoleCommand("EGP_ScrWH",ScrW(),ScrH())
	end)
else
	hook.Add("PlayerInitialSpawn","EGP_ScrHW_Request",function(ply)
		timer.Simple(1,function()
			if (ply and ply:IsValid() and ply:IsPlayer()) then
				umsg.Start("EGP_ScrWH_Request",ply) umsg.End()
			end
		end)
	end)
	
	EGP.ScrHW = {}
	
	concommand.Add("EGP_ScrWH",function(ply,cmd,args)
		if (args and args[1] and args[2]) then
			EGP.ScrHW[ply] = { args[1], args[2] }
		end
	end)
end

-- Line drawing helper function
function EGP:DrawLine( x, y, x2, y2, size )
	if (size < 1) then size = 1 end
	if (size == 1) then
		surface.DrawLine( x, y, x2, y2 )
	else
		-- Calculate position
		local x3 = (x + x2) / 2
		local y3 = (y + y2) / 2
		
		-- calculate height
		local w = math.sqrt( (x2-x) ^ 2 + (y2-y) ^ 2 )
		
		-- Calculate angle (Thanks to Fizyk)
		local angle = math.deg(math.atan2(y-y2,x2-x))
		
		surface.DrawTexturedRectRotated( x3, y3, w, size, angle )
	end
end

local function ScaleCursor( this, x, y )
	if (this.Scaling) then			
		local xMin = this.xScale[1]
		local xMax = this.xScale[2]
		local yMin = this.yScale[1]
		local yMax = this.yScale[2]
		
		x = (x * (xMax-xMin)) / 512 + xMin
		y = (y * (yMax-yMin)) / 512 + yMin
	end
	
	return x, y
end

local function ReturnFailure( this )
	if (this.Scaling) then
		return {this.xScale[1]-1,this.yScale[1]-1}
	end
	return {-1,-1}
end

function EGP:EGPCursor( this, ply )
	if (!EGP:ValidEGP( this )) then return {-1,-1} end
	if (!ply or !ply:IsValid() or !ply:IsPlayer()) then return ReturnFailure( this ) end
	
	local Normal, Pos, monitor, Ang
	-- If it's an emitter, set custom normal and pos
	if (this:GetClass() == "gmod_wire_egp_emitter") then
		Normal = this:GetRight()
		Pos = this:LocalToWorld( Vector( -64, 0, 135 ) )
		
		monitor = { Emitter = true }
	else
		-- Get monitor screen pos & size
		monitor = WireGPU_Monitors[ this:GetModel() ]
		
		-- Monitor does not have a valid screen point
		if (!monitor) then return {-1,-1} end
		
		Ang = this:LocalToWorldAngles( monitor.rot )
		Pos = this:LocalToWorld( monitor.offset )
		
		Normal = Ang:Up()
	end
	
	local Start = ply:GetShootPos()
	local Dir = ply:GetAimVector()
	
	local A = Normal:Dot(Dir)
	
	-- If ray is parallel or behind the screen
	if (A == 0 or A > 0) then return ReturnFailure( this ) end
	
	local B = Normal:Dot(Pos-Start) / A

	if (B >= 0) then
		if (monitor.Emitter) then
			local HitPos = Start + Dir * B
			HitPos = this:WorldToLocal( HitPos ) - Vector( -64, 0, 135 )
			local x = HitPos.x*(512/128)
			local y = HitPos.z*-(512/128)
			x, y = ScaleCursor( this, x, y )
			return {x,y}			
		else
			local HitPos = WorldToLocal( Start + Dir * B, Angle(), Pos, Ang )
			local x = (0.5+HitPos.x/(monitor.RS*512/monitor.RatioX)) * 512
			local y = (0.5-HitPos.y/(monitor.RS*512)) * 512	
			if (x < 0 or x > 512 or y < 0 or y > 512) then return ReturnFailure( this ) end -- Aiming off the screen 
			x, y = ScaleCursor( this, x, y )
			return {x,y}
		end
	end

	return ReturnFailure( this )
end