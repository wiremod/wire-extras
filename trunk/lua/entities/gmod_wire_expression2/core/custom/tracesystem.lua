/***********************************************************************************************************************
Credits


Feha - I am coding the stuff

gmod lua wiki - they got a list of functions you can use.

Inspired by the e2 extensions: holo, datasignals, gvars, entity and ranger.
***********************************************************************************************************************/

E2Lib.RegisterExtension("tracesystem", false)

/****************************
*****     Helper functions     *****
****************************/

--[
local v = _R.Vector
local Length = v.Length
local Dot = v.Dot
local Distance = v.Distance
local sqrt = math.sqrt
--]]

local function E2VecToLuaVec( Vec )
	
	return Vector(Vec[1],Vec[2],Vec[3])
	
end

local function LuaVecToE2Vec( Vec )
	
	if (Vec) then return {Vec.x,Vec.y,Vec.z} end
	
	return {0,0,0}
	
end

local function E2AngToLuaAng( Ang )
	
	return Angle(Ang[1],Ang[2],Ang[3])
	
end

local function LuaAngToE2Ang( Ang )
	
	if (Ang) then return {Ang.p,Ang.y,Ang.r} end
	
	return {0,0,0}
	
end

//Default function make 1,0,0 have a length below 1
local function Norm( Vec )
	
	return Vec / Length(Vec)
	
end



/*********************************
*****     Intersection functions     *****
*********************************/

local function RayPlaneIntersection( Start, Dir, Pos, Normal )
	
	local A = Dot(Normal, Dir)
	
	//Check if the ray is aiming towards the plane (fail if it origin behind the plane, but that is checked later)
	if (A < 0) then
		
		local B = Dot(Normal, Pos-Start)
		
		//Check if the ray origin in front of plane
		if (B < 0) then
			return (Start + Dir * (B/A))
		end
		
	//Check if the ray is parallel to the plane
	elseif (A == 0) then
		
		//Check if the ray origin inside the plane
		if (Dot(Normal, Pos-Start) == 0) then
			return Start
		end
		
	end
	
	return false
	
end

local function RayFaceIntersection( Start, Dir, Pos, Normal, Size, Rotation )
	
	local hitPos = RayPlaneIntersection( Start, Dir, Pos, Normal )
	
	if (hitPos) then
		
		faceAngle = Normal:Angle()+Angle(0,0,Rotation)
		
		local localHitPos = WorldToLocal( hitPos, Angle(0,0,0), Pos, faceAngle )
		
		local min = Size/-2
		local max = Size/2
		
		//Because using Normal:Angle() for WorldToLocal() makes it think that axis is x, we need to use the local hitpos z as x.
		if (localHitPos.z >= min.x and localHitPos.z <= max.x) then
			if (localHitPos.y >= min.y and localHitPos.y <= max.y) then
				
				return hitPos
				
			end
		end
		
	end
	
	return false
	
end

local boxNormals = {
	Vector(1,0,0),
	Vector(0,1,0),
	Vector(0,0,1),
	Vector(-1,0,0),
	Vector(0,-1,0),
	Vector(0,0,-1)
}
local function RayAABBoxIntersection( Start, Dir, Pos, Size )
	
	//Getting the sizes for the faces let us scale the box a lil.
	local boxSizes = {
		Vector(Size.z,Size.y,0),
		Vector(Size.z,Size.x,0),
		Vector(Size.x,Size.y,0),
		Vector(Size.z,Size.y,0),
		Vector(Size.z,Size.x,0),
		Vector(Size.x,Size.y,0)
	}
	
	local closestDist
	local closestHitPos
	local closestNormal
	
	for i=1,6 do
		
		local normal = boxNormals[i]
		local faceSize = boxSizes[i]
		
		if (Dot(normal, Dir) < 0) then
			
			local planePos = Pos + normal * (Size/2)
			local HitPos = RayFaceIntersection( Start, Dir, planePos, normal, faceSize, 0 )
			
			if (HitPos) then
				local dist = Distance(HitPos, Start) 
				if (!closestDist or dist < closestDist) then
					closestDist = dist
					closestHitPos = HitPos
					closestNormal = normal
				end
			end
			
		end
		
	end
	
	if (closestHitPos) then return closestHitPos, closestNormal end
	
	return false
	
end

local function RayOBBoxIntersection( Start, Dir, Pos, Size, Ang )
	
	//To use an oriented-bounding-box we make the ray local (so we can use the AABB code)
	local localRayStart = WorldToLocal( Start, Angle(0,0,0), Pos, Ang )
	
	//The direction need to be local to 0,0,0 though
	local localRayDir = WorldToLocal( Dir, Angle(0,0,0), Vector(0,0,0), Ang )
	
	//Use AABB code as that is easyer than calculating the normals of the faces and their angle aroudn that axis
	local localHitPos, localHitNormal = RayAABBoxIntersection( localRayStart, localRayDir, Vector(0,0,0), Size )
	
	//But we want the returned hitpos to be a world coord
	if (localHitPos) then
		local hitPos = LocalToWorld( localHitPos, Angle(0,0,0), Pos, Ang )
		local hitNormal = LocalToWorld( localHitNormal, Angle(0,0,0), Vector(0,0,0), Ang )
		
		return hitPos, hitNormal
	end
	
	return false
	
end

local function RayCircleIntersection( Start, Dir, Pos, Normal, Radius )
	
	local HitPos = RayPlaneIntersection( Start, Dir, Pos, Normal )
	
	if (HitPos) then
		local Dist = Distance(Pos, HitPos)
		
		if (Dist < Radius) then return HitPos, Dist end
	end
	
	return false
	
end

local function RaySphereIntersection( Start, Dir, Pos, Radius )
	
	//New ray-sphere intersection code
	--[
	local A = 2 * Length(Dir)^2
	local B = 2 * Dot(Dir,Start - Pos)
	local C = Length(Pos)^2 + Length(Start)^2 - 2 * Dot(Pos,Start) - Radius^2
	
	local BAC4 = B^2-(2*A*C)
	
	if (BAC4 >= 0 and B < 0) then
		//Enter sphere
		return Start + ((-sqrt(BAC4) - B) / A)*Dir
		
		//Exits sphere
		//return Start + ((sqrt(BAC4) - B) / A)*Dir
	end
	--]]
	
	//Old ray-sphere intersection code (slower)
	--[[
	local Normal = Dir * -1
	local B = Normal:Dot(Pos-Start) / Normal:Dot(Dir)
	
	//It is a ray, not line, for a line segment, just add a distance chek.
	if (B >= 0) then
		
		local HitPos = Start + Dir * B
		
		local Dist = Distance(Pos, HitPos)
		
		if (Dist < Radius) then
			HitPos = HitPos - Dir * sqrt(Radius ^ 2 - Dist ^ 2)
			
			return HitPos
		end
		
	end
	--]]
	
	return false
	
end

local function ConeSphereIntersection( Start, Dir, Pos, Radius, Ang )
	
	local HitPos = RaySphereIntersection( Start, Dir, Pos, Radius )
	
	//If we hit with a normal trace we dont need to calculate for a cone
	if (HitPos) then return HitPos, 0 end
	if (Ang == 0) then return false end
	
	//Normal of the plane is -Dir because that makes the face perfectly perpendicular to the trace, and facing towards the origin
	HitPos = RayPlaneIntersection( Start, Dir, Pos, Dir * -1 )
	
	if (!HitPos) then return false end
	
	//Calculate where on a circle would be closest to the plane hitpos
	HitPos = Pos + Norm(HitPos-Pos) * Radius
	
	//Get angle between the vector we aim and vector to the circle "hitpos"
	VecAng = math.Rad2Deg( math.acos( Dot( Norm(Dir), Norm(HitPos-Start) ) ) )
	
	if (VecAng <= Ang) then return HitPos, VecAng end
	
	return false
	
end



/************************
*****     * functions     *****
*************************/


local playerAmount = {}
local shapes = {}
local sharing = {}

CreateConVar("wire_shapes_max","50")
local function ShapeCanCreate( ply )
	if (playerAmount[ply] < GetConVar("wire_shapes_max"):GetInt()) then return true end
end

local function ShapeShare( share, self )
	if (share) then
		sharing[self.player][self.entity] = math.Clamp(share,0,2)
	end
end


local models = {
	"",
	"plane",
	"face",
	"box",
	"circle",
	"sphere"
}

local function ShapeCreate( index, model, radius, rotation, pos, normal, size, ang, self )
	
	if (!table.HasValue( models, model )) then return "Invalid model." end
	
	if (!shapes[self.player][self.entity][index]) then
		playerAmount[self.player] = playerAmount[self.player]+1
	end
	
	local shape = {}
	
	//Unmodifiable
	shape.Index = index
	shape.Entity = self.entity
	shape.Owner = self.player
	
	//Modifiable
	shape.Model = model
	shape.Radius = radius
	shape.Rotation = rotation
	shape.Pos = pos
	shape.Normal = normal
	shape.Size = size
	shape.Ang = ang
	
	shapes[self.player][self.entity][index] = shape
	
	return ""
	
end

local function ShapeModel( index, model, self )
	
	if (!table.HasValue( models, model )) then return "Invalid model." end
	
	local shape = shapes[self.player][self.entity][index]
	if (!shape) then return "Invalid index." end
	
	shape.Model = model
	
	return ""
	
end

local function ShapeRadius( index, radius, self )
	
	local shape = shapes[self.player][self.entity][index]
	if (!shape) then return "Invalid index." end
	
	shape.Radius = radius
	
	return ""
	
end

local function ShapeRotation( index, rotation, self )
	
	local shape = shapes[self.player][self.entity][index]
	if (!shape) then return "Invalid index." end
	
	shape.Rotation = rotation
	
	return ""
	
end

local function ShapePos( index, pos, self )
	
	local shape = shapes[self.player][self.entity][index]
	if (!shape) then return "Invalid index." end
	
	if (shape.Parent) then
		shape.Pos = shape.Parent.WorldToLocal(pos)
	else
		shape.Pos = pos
	end
	
	return ""
	
end

local function ShapeAng( index, ang, self )
	
	local shape = shapes[self.player][self.entity][index]
	if (!shape) then return "Invalid index." end
	
	if (shape.Parent) then
		shape.Ang = shape.Parent.WorldToLocal(ang)
	else
		shape.Ang = ang
	end
	
	return ""
	
end

local function ShapeNormal( index, normal, self )
	
	local shape = shapes[self.player][self.entity][index]
	if (!shape) then return "Invalid index." end
	
	if (shape.Parent) then
		shape.Normal = WorldToLocal( normal, Angle(0,0,0), Vector(0,0,0), shape.Parent:GetAngles() )
	else
		shape.Normal = normal
	end
	
	return ""
	
end

local function ShapeSize( index, size, self )
	
	local shape = shapes[self.player][self.entity][index]
	if (!shape) then return "Invalid index." end
	
	shape.Size = size
	
	return ""
	
end

local function ShapeParent( index, parent, self )
	
	local shape = shapes[self.player][self.entity][index]
	if (!shape) then return "Invalid index." end
	
	if (parent) then
		
		local pos, ang, normal, rotation
		if (shape.Parent) then
			pos, ang, normal, rotation = GetWorldData(shape)
		else
			pos, ang, normal, rotation = shape.Pos, shape.Ang, shape.Normal, shape.Rotation
		end
		
		shape.Pos = parent:WorldToLocal(pos)
		shape.Ang = parent:WorldToLocalAngles(ang)
		shape.Normal = WorldToLocal( normal, Angle(0,0,0), Vector(0,0,0), parent:GetAngles() )
		shape.Rotation = rotation //Work on
		
	end
	
	shape.Parent = parent
	
	return ""
	
end

local function ShapeRemove( index, self )
	
	local shape = shapes[self.player][self.entity][index]
	if (!shape) then return "Invalid index." end
	
	playerAmount[self.player] = playerAmount[self.player]-1
	shapes[self.player][self.entity][index] = nil
	
	return ""
	
end

local function ShapeClear( self )
	for index,shape in pairs(shapes[self.player][self.entity]) do
		playerAmount[self.player] = playerAmount[self.player]-1
		shapes[self.player][self.entity][index] = nil
	end
end



/***********************************
*****     Ts intersection functions     *****
***********************************/

local function GetWorldData(shape)
	
	local parent = shape.Parent
	
	local pos = parent:LocalToWorld(shape.Pos)
	local ang = parent:LocalToWorldAngles(shape.Ang)
	
	local normal = LocalToWorld( shape.Normal, Angle(0,0,0), Vector(0,0,0), shape.Parent:GetAngles() )
	local rotation = shape.Rotation //Work On
	
	return pos, ang, normal, rotation
	
end

local function FillTraceData( trace, shape )
	
	local pos, ang, normal, rotation
	if (shape.Parent) then
		pos, ang, normal, rotation = GetWorldData(shape)
	else
		pos, ang, normal, rotation = shape.Pos, shape.Ang, shape.Normal, shape.Rotation
	end
	
	trace.Hit = 1
	trace.Index = shape.Index
	trace.Radius = shape.Radius
	trace.Rotation = rotation
	trace.Model = shape.Model
	trace.HitNormal = normal
	trace.Size = shape.Size
	trace.Pos = pos
	trace.Ang = ang
	trace.Parent = shape.Parent
	trace.HitEntity = shape.Entity
	trace.HitOwner = shape.Owner
	
end


local function TsRayPlaneIntersection( start, dir, self )
	
	local traces = {}
	
	for ply,plyGates in pairs(shapes) do
		
		for gate,gateShapes in pairs(plyGates) do
			
			local continue = false
			
			//If player is not same player who trace and e2's does not share with other players e2
			if (ply ~= self.player and (sharing[ply][gate] ~= 2 or sharing[self.player][self.entity] ~= 2)) then continue = true end
			
			//If e2 is not same as e2 that trace and e2 does not share at all
			if (gate ~= self.entity and (sharing[ply][gate] == 0 or sharing[self.player][self.entity] == 0)) then continue = true end
			
			if (!continue) then
				for k,shape in pairs(gateShapes) do
					
					if (shape.Model == "plane") then 
						
						local pos, ang, normal, rotation
						if (shape.Parent) then
							pos, ang, normal, rotation = GetWorldData(shape)
						else
							pos, ang, normal, rotation = shape.Pos, shape.Ang, shape.Normal, shape.Rotation
						end
						
						local hitPos = RayPlaneIntersection( start, dir, pos, normal )
						
						if (hitPos) then
							local trace = {}
							
							FillTraceData( trace, shape )
							
							trace.HitAngle = 0
							trace.StartPos = start
							trace.HitPos = hitPos
							
							table.insert( traces, trace )
						end
						
					end
					
				end
			end
			
		end
		
	end
	
	return traces
	
end

local function TsRayFaceIntersection( start, dir, self )
	
	local traces = {}
	
	for ply,plyGates in pairs(shapes) do
		
		for gate,gateShapes in pairs(plyGates) do
			
			local continue = false
			
			//If player is not same player who trace and e2's does not share with other players e2
			if (ply ~= self.player and (sharing[ply][gate] ~= 2 or sharing[self.player][self.entity] ~= 2)) then continue = true end
			
			//If e2 is not same as e2 that trace and e2 does not share at all
			if (gate ~= self.entity and (sharing[ply][gate] == 0 or sharing[self.player][self.entity] == 0)) then continue = true end
			
			if (!continue) then
				for k,shape in pairs(gateShapes) do
					
					if (shape.Model == "face") then
						
						local pos, ang, normal, rotation
						if (shape.Parent) then
							pos, ang, normal, rotation = GetWorldData(shape)
						else
							pos, ang, normal, rotation = shape.Pos, shape.Ang, shape.Normal, shape.Rotation
						end
						
						local hitPos = RayFaceIntersection( start, dir, pos, normal, shape.Size, rotation )
						
						if (hitPos) then
							local trace = {}
							
							FillTraceData( trace, shape )
							
							trace.HitAngle = 0
							trace.StartPos = start
							trace.HitPos = hitPos
							
							table.insert( traces, trace )
						end
						
					end
					
				end
			end
			
		end
		
	end
	
	return traces
	
end


local function TsRayBoxIntersection( start, dir, self )
	
	local traces = {}
	
	for ply,plyGates in pairs(shapes) do
		
		for gate,gateShapes in pairs(plyGates) do
			
			local continue = false
			
			//If player is not same player who trace and e2's does not share with other players e2
			if (ply ~= self.player and (sharing[ply][gate] ~= 2 or sharing[self.player][self.entity] ~= 2)) then continue = true end
			
			//If e2 is not same as e2 that trace and e2 does not share at all
			if (gate ~= self.entity and (sharing[ply][gate] == 0 or sharing[self.player][self.entity] == 0)) then continue = true end
			
			if (!continue) then
				for k,shape in pairs(gateShapes) do
					
					if (shape.Model == "box") then
						
						local pos, ang, normal, rotation
						if (shape.Parent) then
							pos, ang, normal, rotation = GetWorldData(shape)
						else
							pos, ang, normal, rotation = shape.Pos, shape.Ang, shape.Normal, shape.Rotation
						end
						
						local hitPos, hitNormal = RayOBBoxIntersection( start, dir, pos, shape.Size, ang )
						
						if (hitPos) then
							local trace = {}
							
							FillTraceData( trace, shape )
							
							trace.HitAngle = 0
							trace.StartPos = start
							trace.HitPos = hitPos
							trace.HitNormal = hitNormal
							
							table.insert( traces, trace )
						end
						
					end
					
				end
			end
			
		end
		
	end
	
	return traces
	
end

local function TsRayCircleIntersection( start, dir, self )
	
	local traces = {}
	
		for ply,plyGates in pairs(shapes) do
		
		for gate,gateShapes in pairs(plyGates) do
			
			local continue = false
			
			//If player is not same player who trace and e2's does not share with other players e2
			if (ply ~= self.player and (sharing[ply][gate] ~= 2 or sharing[self.player][self.entity] ~= 2)) then continue = true end
			
			//If e2 is not same as e2 that trace and e2 does not share at all
			if (gate ~= self.entity and (sharing[ply][gate] == 0 or sharing[self.player][self.entity] == 0)) then continue = true end
			
			if (!continue) then
				for k,shape in pairs(gateShapes) do
					
					if (shape.Model == "circle") then
						
						local pos, ang, normal, rotation
						if (shape.Parent) then
							pos, ang, normal, rotation = GetWorldData(shape)
						else
							pos, ang, normal, rotation = shape.Pos, shape.Ang, shape.Normal, shape.Rotation
						end
						
						local hitPos = RayCircleIntersection( start, dir, pos, normal, shape.Radius )
						
						if (hitPos) then
							local trace = {}
							
							FillTraceData( trace, shape )
							
							trace.HitAngle = 0
							trace.StartPos = start
							trace.HitPos = hitPos
							
							table.insert( traces, trace )
						end
						
					end
					
				end
			end
			
		end
		
	end
	
	return traces
	
end

local function TsRaySphereIntersection( start, dir, self )
	
	local traces = {}
	
	for ply,plyGates in pairs(shapes) do
		
		for gate,gateShapes in pairs(plyGates) do
			
			local continue = false
			
			//If player is not same player who trace and e2's does not share with other players e2
			if (ply ~= self.player and (sharing[ply][gate] ~= 2 or sharing[self.player][self.entity] ~= 2)) then continue = true end
			
			//If e2 is not same as e2 that trace and e2 does not share at all
			if (gate ~= self.entity and (sharing[ply][gate] == 0 or sharing[self.player][self.entity] == 0)) then continue = true end
			
			if (!continue) then
				for k,shape in pairs(gateShapes) do
					
					if (shape.Model == "sphere") then
						
						local pos, ang, normal, rotation
						if (shape.Parent) then
							pos, ang, normal, rotation = GetWorldData(shape)
						else
							pos, ang, normal, rotation = shape.Pos, shape.Ang, shape.Normal, shape.Rotation
						end
						
						local hitPos = RaySphereIntersection( start, dir, pos, shape.Radius )
						
						if (hitPos) then
							local trace = {}
							
							FillTraceData( trace, shape )
							
							trace.HitAngle = 0
							trace.StartPos = start
							trace.HitPos = hitPos
							trace.HitNormal = Norm(hitPos - pos)
							
							table.insert( traces, trace )
						end
						
					end
					
				end
			end
			
		end
		
	end
	
	return traces
	
end


local function TsRayIntersection( start, dir, self )
	
	local traces = {}
	
	local rayPlane = TsRayPlaneIntersection( start, dir, self )
	local rayFace = TsRayFaceIntersection( start, dir, self )
	local rayBox = TsRayBoxIntersection( start, dir, self)
	local rayCircle = TsRayCircleIntersection( start, dir, self )
	local raySphere = TsRaySphereIntersection( start, dir, self )
	
	table.Add(traces,rayPlane)
	table.Add(traces,rayFace)
	table.Add(traces,rayBox)
	table.Add(traces,rayCircle)
	table.Add(traces,raySphere)
	
	return traces
	
end


local function TsConeSphereIntersection( start, dir, angle, self )
	
	local traces = {}
	
	for ply,plyGates in pairs(shapes) do
		
		for gate,gateShapes in pairs(plyGates) do
			
			local continue = false
			
			//If player is not same player who trace and e2's does not share with other players e2
			if (ply ~= self.player and (sharing[ply][gate] ~= 2 or sharing[self.player][self.entity] ~= 2)) then continue = true end
			
			//If e2 is not same as e2 that trace and e2 does not share at all
			if (gate ~= self.entity and (sharing[ply][gate] == 0 or sharing[self.player][self.entity] == 0)) then continue = true end
			
			if (!continue) then
				for k,shape in pairs(gateShapes) do
					
					if (shape.Model == "sphere") then
						
						local pos, ang, normal, rotation
						if (shape.Parent) then
							pos, ang, normal, rotation = GetWorldData(shape)
						else
							pos, ang, normal, rotation = shape.Pos, shape.Ang, shape.Normal, shape.Rotation
						end
						
						local hitPos, hitAngle = ConeSphereIntersection( start, dir, pos, shape.Radius, angle )
						
						if (hitPos) then
							local trace = {}
							
							FillTraceData( trace, shape )
							
							trace.HitAngle = hitAngle
							trace.StartPos = start
							trace.HitPos = hitPos
							trace.HitNormal = Norm(hitPos - pos)
							
							table.insert( traces, trace )
						end
						
					end
					
				end
			end
			
		end
		
	end
	
	return traces
	
end



/******************************
*****     Retrieval functions     *****
******************************/

local function SortByDistance( traces, pos )
	
	table.sort(traces, function(a, b)
		return Distance(pos, a.HitPos) < Distance(pos, b.HitPos)
	end)
	
	return #traces
	
end

local function Count( traces )
	
	return #traces
	
end


local function GetHit( traces, index )
	
	if (traces[index]) then
		return traces[index].Hit
	end
	
	return 0
end

local function GetHitAngle( traces, index )
	
	if (traces[index]) then
		return traces[index].HitAngle
	end
	
	return 0
end

local function GetHitIndex( traces, index )
	
	if (traces[index]) then
		return traces[index].Index
	end
	
	return 0
end

local function GetHitDistance( traces, index )
	
	if (traces[index]) then
		local trace = traces[index]
		
		return Distance(trace.StartPos, trace.HitPos)
	end
	
	return 0
end

local function GetHitRadius( traces, index )
	
	if (traces[index]) then
		return traces[index].Radius
	end
	
	return 0
end

local function GetHitRotation( traces, index )
	
	if (traces[index]) then
		return traces[index].Rotation
	end
	
	return 0
end

local function GetHitModel( traces, index )
	
	if (traces[index]) then
		return traces[index].Model
	end
	
	return ""
end

local function GetHitPos( traces, index )
	
	if (traces[index]) then
		return traces[index].HitPos
	end
	
end

local function GetHitOrigin( traces, index )
	
	if (traces[index]) then
		return traces[index].Pos
	end
	
end

local function GetHitAng( traces, index )
	
	if (traces[index]) then
		return traces[index].Ang
	end
	
end

local function GetHitNormal( traces, index )
	
	if (traces[index]) then
		return traces[index].HitNormal
	end
	
end

local function GetHitSize( traces, index )
	
	if (traces[index]) then
		return traces[index].Size
	end
	
end

local function GetHitParent( traces, index )
	
	if (traces[index]) then
		return traces[index].Parent
	end
	
end

local function GetHitEntity( traces, index )
	
	if (traces[index]) then
		return traces[index].HitEntity
	end
	
end

local function GetHitOwner( traces, index )
	
	if (traces[index]) then
		return traces[index].HitOwner
	end
	
end



/************************
*****     E2 Datatype     *****
*************************/

registerType("tracedata", "xtd", {},
	nil,
	nil,
	function(retval)
		if retval == nil then return end
		if type(retval) ~= "table" then error("Return value is not a table, but a "..type(retval).."!",0) end
	end,
	function(v)
		return type(v) ~= "table"
	end
)

e2function tracedata operator=(tracedata lhs, tracedata rhs)
	self.vars[lhs] = rhs
	self.vclk[lhs] = true
	return rhs
end

e2function number operator_is(tracedata walker)
	if walker then return 1 else return 0 end
end



/************************************
*****     E2 Intersection functions     *****
************************************/

e2function vector rayPlaneIntersection( vector start, vector dir, vector pos, vector normal )
	start = E2VecToLuaVec( start )
	dir = E2VecToLuaVec( dir )
	pos = E2VecToLuaVec( pos )
	normal = E2VecToLuaVec( normal )
	
	hitPos = RayPlaneIntersection( start, dir, pos, normal )
	
	return LuaVecToE2Vec( hitPos )
end

e2function vector rayFaceIntersection( vector start, vector dir, vector pos, vector normal, vector size, number ang )
	start = E2VecToLuaVec( start )
	dir = E2VecToLuaVec( dir )
	pos = E2VecToLuaVec( pos )
	normal = E2VecToLuaVec( normal )
	size = E2VecToLuaVec( size )
	
	hitPos = RayFaceIntersection( start, dir, pos, normal, size, ang )
	
	return LuaVecToE2Vec( hitPos )
end

e2function vector rayAABBoxIntersection( vector start, vector dir, vector pos, vector size )
	start = E2VecToLuaVec( start )
	dir = E2VecToLuaVec( dir )
	pos = E2VecToLuaVec( pos )
	size = E2VecToLuaVec( size )
	
	hitPos = RayAABBoxIntersection( start, dir, pos, size )
	
	return LuaVecToE2Vec( hitPos )
end

e2function vector rayOBBoxIntersection( vector start, vector dir, vector pos, vector size, angle ang )
	start = E2VecToLuaVec( start )
	dir = E2VecToLuaVec( dir )
	pos = E2VecToLuaVec( pos )
	size = E2VecToLuaVec( size )
	ang = E2AngToLuaAng( ang )
	
	hitPos = RayOBBoxIntersection( start, dir, pos, size, ang )
	
	return LuaVecToE2Vec( hitPos )
end

e2function vector rayCircleIntersection( vector start, vector dir, vector pos, vector normal, number radius )
	start = E2VecToLuaVec( start )
	dir = E2VecToLuaVec( dir )
	pos = E2VecToLuaVec( pos )
	normal = E2VecToLuaVec( normal )
	
	hitPos = RayCircleIntersection( start, dir, pos, normal, radius )
	
	return LuaVecToE2Vec( hitPos )
end

e2function vector raySphereIntersection( vector start, vector dir, vector pos, number radius )
	start = E2VecToLuaVec( start )
	dir = E2VecToLuaVec( dir )
	pos = E2VecToLuaVec( pos )
	
	hitPos = RaySphereIntersection( start, dir, pos, radius )
	
	return LuaVecToE2Vec( hitPos )
end

e2function vector coneSphereIntersection( vector start, vector dir, vector pos, number radius, number ang )
	start = E2VecToLuaVec( start )
	dir = E2VecToLuaVec( dir )
	pos = E2VecToLuaVec( pos )
	
	hitPos = ConeSphereIntersection( start, dir, pos, radius, ang )
	
	return LuaVecToE2Vec( hitPos )
end



/**************************
*****     E2 * functions     *****
**************************/

e2function number tsShapeCanCreate( )
	return GetConVar("wire_shapes_max"):GetInt() - playerAmount[self.player]
end

e2function void tsShapeShare( number share )
	return ShapeShare( share, self )
end

e2function string tsShapeCreate( number index, string model, number radius, rotation, vector pos, vector normal, vector size, angle ang )
	if (!ShapeCanCreate( self.player )) then return "Limit reached" end
	
	pos = E2VecToLuaVec( pos )
	normal = E2VecToLuaVec( normal )
	size = E2VecToLuaVec( size )
	ang = E2AngToLuaAng( ang )
	
	return ShapeCreate( index, model, radius, rotation, pos, normal, size, ang, self )
end

e2function string tsShapeCreate( number index )
	if (!ShapeCanCreate( self.player )) then return "Limit reached" end
	
	return ShapeCreate( index, "", 0, 0, Vector(0,0,0), Vector(0,0,0), Vector(0,0,0), Angle(0,0,0), self )
end

e2function string tsShapeModel( number index, string model )
	return ShapeModel( index, model, self )
end

e2function string tsShapeRadius( number index, number radius )
	return ShapeRadius( index, radius, self )
end

e2function string tsShapeRotation( number index, number rotation )
	return ShapeRotation( index, rotation, self )
end

e2function string tsShapePos( number index, vector pos )
	pos = E2VecToLuaVec( pos )
	
	return ShapePos( index, pos, self )
end

e2function string tsShapeAng( number index, angle ang )
	ang = E2AngToLuaAng( ang )
	
	return ShapeAng( index, ang, self )
end

e2function string tsShapeNormal( number index, vector normal )
	normal = E2VecToLuaVec( normal )
	
	return ShapeNormal( index, normal, self )
end

e2function string tsShapeSize( number index, vector size )
	size = E2VecToLuaVec( size )
	
	return ShapeSize( index, size, self )
end

e2function string tsShapeParent( number index, entity parent )
	return ShapeParent( index, parent, self )
end

e2function string tsShapeRemove( number index )
	return ShapeRemove( index, self )
end

e2function void tsShapeClear( )
	return ShapeClear( self )
end



/**************************************
*****     E2 ts intersection functions     *****
**************************************/

e2function tracedata tsRayPlaneIntersection( vector start, vector dir )
	start = E2VecToLuaVec( start )
	dir = E2VecToLuaVec( dir )
	
	local traces = TsRayPlaneIntersection( start, dir, self )
	
	SortByDistance( traces, start )
	
	return traces
end

e2function tracedata tsRayFaceIntersection( vector start, vector dir )
	start = E2VecToLuaVec( start )
	dir = E2VecToLuaVec( dir )
	
	local traces = TsRayFaceIntersection( start, dir, self )
	
	SortByDistance( traces, start )
	
	return traces
end

e2function tracedata tsRayBoxIntersection( vector start, vector dir )
	start = E2VecToLuaVec( start )
	dir = E2VecToLuaVec( dir )
	
	local traces =  TsRayBoxIntersection( start, dir, self )
	
	SortByDistance( traces, start )
	
	return traces
end

e2function tracedata tsRayCircleIntersection( vector start, vector dir )
	start = E2VecToLuaVec( start )
	dir = E2VecToLuaVec( dir )
	
	local traces =  TsRayCircleIntersection( start, dir, self )
	
	SortByDistance( traces, start )
	
	return traces
end

e2function tracedata tsRaySphereIntersection( vector start, vector dir )
	start = E2VecToLuaVec( start )
	dir = E2VecToLuaVec( dir )
	
	local traces =  TsRaySphereIntersection( start, dir, self )
	
	SortByDistance( traces, start )
	
	return traces
end

e2function tracedata tsRayIntersection( vector start, vector dir )
	start = E2VecToLuaVec( start )
	dir = E2VecToLuaVec( dir )
	
	local traces =  TsRayIntersection( start, dir, self )
	
	SortByDistance( traces, start )
	
	return traces
end

e2function tracedata tsConeSphereIntersection( vector start, vector dir, number angle )
	start = E2VecToLuaVec( start )
	dir = E2VecToLuaVec( dir )
	
	local traces =  TsConeSphereIntersection( start, dir, angle, self )
	
	SortByDistance( traces, start )
	
	return traces
end



/*********************************
*****     E2 Retrieval functions     *****
*********************************/

e2function number tracedata:sortByDistance( vector pos )
	pos = E2VecToLuaVec( pos )
	
	return SortByDistance( this, pos )
end

e2function number tracedata:count( )
	return Count( this )
end


e2function number tracedata:hit( )
	return GetHit( this, 1 )
end

e2function number tracedata:hit( number index )
	return GetHit( this, index )
end

e2function number tracedata:hitAngle( )
	return GetHitAngle( this, 1 )
end

e2function number tracedata:hitAngle( number index )
	return GetHitAngle( this, index )
end

e2function number tracedata:index( )
	return GetHitIndex( this, 1 )
end

e2function number tracedata:index( number index )
	return GetHitIndex( this, index )
end

e2function number tracedata:distance( )
	return GetHitDistance( this, 1 )
end

e2function number tracedata:distance( number index )
	return GetHitDistance( this, index )
end

e2function number tracedata:radius( )
	return GetHitRadius( this, 1 )
end

e2function number tracedata:radius( number index )
	return GetHitRadius( this, index )
end

e2function number tracedata:rotation( )
	return GetHitRotation( this, 1 )
end

e2function number tracedata:rotation( number index )
	return GetHitRotation( this, index )
end

e2function string tracedata:model( )
	return GetHitModel( this, 1 )
end

e2function string tracedata:model( number index )
	return GetHitModel( this, index )
end

e2function vector tracedata:hitPos( )
	local hitPos = GetHitPos( this, 1 )
	
	return LuaVecToE2Vec(hitPos)
end

e2function vector tracedata:hitPos( number index )
	local hitPos = GetHitPos( this, index )
	
	return LuaVecToE2Vec(hitPos)
end

e2function vector tracedata:pos( )
	local pos = GetHitOrigin( this, 1 )
	
	return LuaVecToE2Vec(pos)
end

e2function vector tracedata:pos( number index )
	local pos = GetHitOrigin( this, index )
	
	return LuaVecToE2Vec(pos)
end

e2function angle tracedata:ang( )
	local ang = GetHitAng( this, 1 )
	
	return LuaAngToE2Ang(ang)
end

e2function angle tracedata:ang( number index )
	local ang = GetHitAng( this, index )
	
	return LuaAngToE2Ang(ang)
end

e2function vector tracedata:hitNormal( )
	local hitNormal = GetHitNormal( this, 1 )
	
	return LuaVecToE2Vec(hitNormal)
end

e2function vector tracedata:hitNormal( number index )
	local hitNormal = GetHitNormal( this, index )
	
	return LuaVecToE2Vec(hitNormal)
end

e2function vector tracedata:size( )
	local size = GetHitSize( this, 1 )
	
	return LuaVecToE2Vec(size)
end

e2function vector tracedata:size( number index )
	local size = GetHitSize( this, index )
	
	return LuaVecToE2Vec(size)
end

e2function entity tracedata:parent( )
	return GetHitParent( this, 1 )
end

e2function entity tracedata:parent( number index )
	return GetHitParent( this, index )
end

e2function entity tracedata:entity( )
	return GetHitEntity( this, 1 )
end

e2function entity tracedata:entity( number index )
	return GetHitEntity( this, index )
end

e2function entity tracedata:owner( )
	return GetHitOwner( this, 1 )
end

e2function entity tracedata:owner( number index )
	return GetHitOwner( this, index )
end



/*******************
*****     Hooks     *****
*******************/

//When an e2 is spawned
registerCallback("construct",function(self)
	if (!sharing[self.player]) then
		shapes[self.player] = {}
		sharing[self.player] = {}
		playerAmount[self.player] = 0
	end
	shapes[self.player][self.entity] = {}
	sharing[self.player][self.entity] = 0
end)

//When an e2 is removed
registerCallback("destruct",function(self)
	if (sharing[self.player][self.entity]) then
		ShapeClear( self )
		
		shapes[self.player][self.entity] = nil
		sharing[self.player][self.entity] = nil
	end
end)


//When player leaves, remove his shapes.
hook.Add("PlayerDisconnected","playerdisconnected",function(ply)
	if (ply:IsValid() and ply:IsPlayer()) then
		shapes[ply] = nil
		sharing[ply] = nil
		playerAmount[ply] = nil
	end
end)
