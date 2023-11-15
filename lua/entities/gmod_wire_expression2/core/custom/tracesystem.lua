--[[***********************************************************************************************************************
Credits


Feha - I am coding the stuff

gmod lua wiki - they got a list of functions you can use.

Inspired by the e2 extensions: holo, datasignals, gvars, entity and ranger.
***********************************************************************************************************************]]

E2Lib.RegisterExtension("tracesystem", false)

--[[****************************
*****     Helper functions     *****
****************************]]

--[
local v = debug.getregistry().Vector
local Length = v.Length
local Dot = v.Dot
local Cross = v.Cross
local Distance = v.Distance
local sqrt = math.sqrt
--]]

-- Default function make 1,0,0 have a length below 1, use this instead.
local function Norm( Vec )

	return Vec / Length(Vec)

end



--[[*********************************
*****     Intersection functions     *****
*********************************]]

local function RayPlaneIntersection( Start, Dir, Pos, Normal )

	local A = Dot(Normal, Dir)

	-- Check if the ray is aiming towards the plane (fail if it origin behind the plane, but that is checked later)
	if (A < 0) then

		local B = Dot(Normal, Pos-Start)

		-- Check if the ray origin in front of plane
		if (B < 0) then
			return (Start + Dir * (B/A))
		end

	-- Check if the ray is parallel to the plane
	elseif (A == 0) then

		-- Check if the ray origin inside the plane
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

		-- Because using Normal:Angle() for WorldToLocal() makes it think that axis is x, we need to use the local hitpos z as x.
		if (localHitPos.z >= min.x and localHitPos.z <= max.x) then
			if (localHitPos.y >= min.y and localHitPos.y <= max.y) then

				return hitPos

			end
		end

	end

	return false

end

local function RayPolygonIntersection( Start, Dir, Vertices )

	local Vertex1 = Vertices[1]
	local Vertex2 = Vertices[2]
	local Vertex3 = Vertices[3]

	local V1V2 = Norm(Vertex2 - Vertex1)
	local V1V3 = Norm(Vertex3 - Vertex1)

	local normal = Cross(V1V2, V1V3)
	if Dot( Dir, normal ) > 0 then normal:Mul(-1) end

	local hitPos = RayPlaneIntersection( Start, Dir, Vertex1, normal )

	if (hitPos) then

		local V1Hit = Norm(hitPos - Vertex1)

		if	Dot( V1V2, V1V3 ) < Dot( V1V2, V1Hit ) and
			Dot( V1V3, V1V2 ) < Dot( V1V3, V1Hit ) and
			Dot( V1V2, Norm(Vertex3 - Vertex2) ) > Dot( V1V2, Norm(hitPos - Vertex2) ) then

			return hitPos

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

	-- Getting the sizes for the faces let us scale the box a lil.
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

	-- To use an oriented-bounding-box we make the ray local (so we can use the AABB code)
	local localRayStart = WorldToLocal( Start, Angle(0,0,0), Pos, Ang )

	-- The direction need to be local to 0,0,0 though
	local localRayDir = WorldToLocal( Dir, Angle(0,0,0), Vector(0,0,0), Ang )

	-- Use AABB code as that is easyer than calculating the normals of the faces and their angle aroudn that axis
	local localHitPos, localHitNormal = RayAABBoxIntersection( localRayStart, localRayDir, Vector(0,0,0), Size )

	-- But we want the returned hitpos to be a world coord
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
  local A = Dir:LengthSqr(); if(A < 0) then return nil end
  local R = Vector(Start) R:Sub(Pos) -- Margin less than distance
  local B, C = 2 * Dir:Dot(R), (R:LengthSqr() - Radius^2)
  local D = (B^2 - 4*A*C); if(D < 0) then return nil end -- Img roots
  local K = 1 / (2*A); D, B = K*math.sqrt(D), -B*K
  local P = Vector(Dir); P:Mul(B + D); P:Add(Start)
  local M = Vector(Dir); M:Mul(B - D); M:Add(Start)
  return P, M -- Return the intersected +/- root point
end

local function RayAAEllipsoidIntersection( Start, Dir, Pos, Size )

	local RayPos = Start - Pos
	local RayDir = Norm(Dir)

	--This boosts my performance by only having to do ^2 once per variable, instead of 3.
	local ElipsoidRadiusX2 = Size.x^2
	local ElipsoidRadiusY2 = Size.y^2
	local ElipsoidRadiusZ2 = Size.z^2

	local A = RayDir.x^2 / ElipsoidRadiusX2
		+ RayDir.y^2 / ElipsoidRadiusY2
		+ RayDir.z^2 / ElipsoidRadiusZ2

	local B = (2 * RayPos.x * RayDir.x) / ElipsoidRadiusX2
		+ (2 * RayPos.y * RayDir.y) / ElipsoidRadiusY2
		+ (2 * RayPos.z * RayDir.z) / ElipsoidRadiusZ2

	local C = RayPos.x^2 / ElipsoidRadiusX2
		+ RayPos.y^2 / ElipsoidRadiusY2
		+ RayPos.z^2 / ElipsoidRadiusZ2
		- 1

	local D = (B^2) - (4 * A * C)

	if (D >= 0) then
		D = sqrt(D)

		local Hit1 = (-B + D) / (2 * A)
		local Hit2 = (-B - D) / (2 * A)

		if (Hit1 < Hit2) then
			return Start + RayDir * Hit1
		else
			return Start + RayDir * Hit2
		end
	end

	return false

end

local function RayOEllipsoidIntersection( Start, Dir, Pos, Size, Ang )

	-- To use an oriented-bounding-box we make the ray local (so we can use the AABB code)
	local localRayStart = WorldToLocal( Start, Angle(0,0,0), Pos, Ang )

	-- The direction need to be local to 0,0,0 though
	local localRayDir = WorldToLocal( Dir, Angle(0,0,0), Vector(0,0,0), Ang )

	-- Use AABB code as that is easyer than calculating the normals of the faces and their angle aroudn that axis
	local localHitPos = RayAAEllipsoidIntersection( localRayStart, localRayDir, Vector(0,0,0), Size )

	-- But we want the returned hitpos to be a world coord
	if (localHitPos) then
		local hitPos = LocalToWorld( localHitPos, Angle(0,0,0), Pos, Ang )

		return hitPos
	end

	return false

end


local function ConeSphereIntersection( Start, Dir, Pos, Radius, Ang )

	local HitPos = RaySphereIntersection( Start, Dir, Pos, Radius )

	-- If we hit with a normal trace we dont need to calculate for a cone
	if (HitPos) then return HitPos, 0 end
	if (Ang == 0) then return false end

	-- Normal of the plane is -Dir because that makes the face perfectly perpendicular to the trace, and facing towards the origin
	HitPos = RayPlaneIntersection( Start, Dir, Pos, Dir * -1 )

	if (!HitPos) then return false end

	-- Calculate where on a circle would be closest to the plane hitpos
	HitPos = Pos + Norm(HitPos-Pos) * Radius

	-- Get angle between the vector we aim and vector to the circle "hitpos"
	VecAng = math.deg( math.acos( Dot( Norm(Dir), Norm(HitPos-Start) ) ) )

	if (VecAng <= Ang) then return HitPos, VecAng end

	return false

end



--[[***********************
*****     * functions     *****
************************]]


local playerAmount = {}
local shapes = {}
local sharing = {}

CreateConVar("wire_shapes_max","50")
local function ShapeCanCreate( ply )
	if (playerAmount[ply] < GetConVarNumber("wire_shapes_max")) then return true end
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
	"sphere",
	"ellipsoid",
	"polygon"
}

local function ShapeCreate( index, model, radius, rotation, pos, normal, size, ang, vertices, self )

	if (!table.HasValue( models, model )) then return "Invalid model." end

	if (model == "polygon") then return ShapeCreatePolygon( index, vertices, self ) end

	if (!shapes[self.player][self.entity][index]) then
		playerAmount[self.player] = playerAmount[self.player]+1
	end

	local shape = {}

	-- Unmodifiable
	shape.Index = index
	shape.Entity = self.entity
	shape.Owner = self.player

	-- Modifiable
	shape.Model = model
	shape.Radius = radius
	shape.Rotation = rotation
	shape.Pos = pos
	shape.Normal = normal
	shape.Size = size
	shape.Ang = ang

	shape.Vertices = nil

	shapes[self.player][self.entity][index] = shape

	return ""

end

local function ShapeCreatePolygon( index, vertices, self )

	if (!shapes[self.player][self.entity][index]) then
		playerAmount[self.player] = playerAmount[self.player]+1
	end

	local shape = {}

	-- Unmodifiable
	shape.Index = index
	shape.Entity = self.entity
	shape.Owner = self.player

	-- Modifiable
	shape.Model = "polygon"
	shape.Vertices = vertices
	shape.Pos = (vertices[1] + vertices[2] + vertices[3]) / 3

	shape.Radius = 0
	shape.Rotation = 0
	shape.Normal = Vector(0,0,0)
	shape.Size = Vector(0,0,0)
	shape.Ang = Angle(0,0,0)

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
		shape.Pos = shape.Parent:WorldToLocal(pos)
	else
		shape.Pos = pos
	end

	return ""

end

local function ShapeVertices( index, vertices, self )

	local shape = shapes[self.player][self.entity][index]
	if (!shape) then return "Invalid index." end

	if (shape.Parent) then
		vertices[1] = shape.Parent:WorldToLocal(vertices[1])
		vertices[2] = shape.Parent:WorldToLocal(vertices[2])
		vertices[3] = shape.Parent:WorldToLocal(vertices[3])
		shape.Vertices = vertices
	else
		shape.Vertices = vertices
	end

	return ""

end

local function ShapeAng( index, ang, self )

	local shape = shapes[self.player][self.entity][index]
	if (!shape) then return "Invalid index." end

	if (shape.Parent) then
		shape.Ang = shape.Parent:WorldToLocal(ang)
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

		local pos, ang, normal, rotation, vertices
		if (shape.Parent) then
			pos, ang, normal, rotation, vertices = GetWorldData(shape)
		else
			pos, ang, normal, rotation = shape.Pos, shape.Ang, shape.Normal, shape.Rotation
			local vertices = shape.Vertices
		end

		shape.Pos = parent:WorldToLocal(pos)
		shape.Ang = parent:WorldToLocalAngles(ang)
		shape.Normal = WorldToLocal( normal, Angle(0,0,0), Vector(0,0,0), parent:GetAngles() )
		shape.Rotation = rotation -- Work on

		if vertices then
			shape.Vertices[1] = parent:WorldToLocal(vertices[1])
			shape.Vertices[2] = parent:WorldToLocal(vertices[2])
			shape.Vertices[3] = parent:WorldToLocal(vertices[3])
		else
			shape.Vertices = nil
		end

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



--[[***********************************
*****     Ts intersection functions     *****
***********************************]]

local function GetWorldData(shape)

	local parent = shape.Parent

	local pos = parent:LocalToWorld(shape.Pos)
	local ang = parent:LocalToWorldAngles(shape.Ang)

	local normal = LocalToWorld( shape.Normal, Angle(0,0,0), Vector(0,0,0), shape.Parent:GetAngles() )
	local rotation = shape.Rotation -- Work On

	local vertices = shape.Vertices
	if vertices then
		vertices[1] = parent:LocalToWorld(vertices[1])
		vertices[2] = parent:LocalToWorld(vertices[2])
		vertices[3] = parent:LocalToWorld(vertices[3])
	end

	return pos, ang, normal, rotation, vertices

end

local function FillTraceData( trace, shape )

	local pos, ang, normal, rotation, vertices
	if (shape.Parent) then
		pos, ang, normal, rotation, vertices = GetWorldData(shape)
	else
		pos, ang, normal, rotation = shape.Pos, shape.Ang, shape.Normal, shape.Rotation
		vertices = shape.Vertices
	end

	trace.Hit = 1
	trace.Index = shape.Index
	trace.Radius = shape.Radius
	trace.Rotation = rotation
	trace.Model = shape.Model
	trace.HitNormal = normal
	trace.Size = shape.Size
	trace.Pos = pos
	trace.Vertices = vertices
	trace.Ang = ang
	trace.Parent = shape.Parent
	trace.HitEntity = shape.Entity
	trace.HitOwner = shape.Owner

end


local function TsRayPlaneIntersection( start, dir, self )

	local traces = {}

	for ply,plyGates in pairs(shapes) do

		for gate,gateShapes in pairs(plyGates) do

			local cont = false

			-- If player is not same player who trace and e2's does not share with other players e2
			if (ply ~= self.player and (sharing[ply][gate] ~= 2 or sharing[self.player][self.entity] ~= 2)) then cont = true end

			-- If e2 is not same as e2 that trace and e2 does not share at all
			if (gate ~= self.entity and (sharing[ply][gate] == 0 or sharing[self.player][self.entity] == 0)) then cont = true end

			if (!cont) then
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

			local cont = false

			-- If player is not same player who trace and e2's does not share with other players e2
			if (ply ~= self.player and (sharing[ply][gate] ~= 2 or sharing[self.player][self.entity] ~= 2)) then cont = true end

			-- If e2 is not same as e2 that trace and e2 does not share at all
			if (gate ~= self.entity and (sharing[ply][gate] == 0 or sharing[self.player][self.entity] == 0)) then cont = true end

			if (!cont) then
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

local function TsRayPolygonIntersection( start, dir, self )

	local traces = {}

	for ply,plyGates in pairs(shapes) do

		for gate,gateShapes in pairs(plyGates) do

			local cont = false

			-- If player is not same player who trace and e2's does not share with other players e2
			if (ply ~= self.player and (sharing[ply][gate] ~= 2 or sharing[self.player][self.entity] ~= 2)) then cont = true end

			-- If e2 is not same as e2 that trace and e2 does not share at all
			if (gate ~= self.entity and (sharing[ply][gate] == 0 or sharing[self.player][self.entity] == 0)) then cont = true end

			if (!cont) then
				for k,shape in pairs(gateShapes) do

					if (shape.Model == "polygon") then

						local pos, ang, normal, rotation, vertices
						if (shape.Parent) then
							pos, ang, normal, rotation, vertices = GetWorldData(shape)
						else
							pos, ang, normal, rotation, vertices = shape.Pos, shape.Ang, shape.Normal, shape.Rotation, shape.Vertices
						end

						local hitPos = RayPolygonIntersection( start, dir, vertices )

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

			local cont = false

			-- If player is not same player who trace and e2's does not share with other players e2
			if (ply ~= self.player and (sharing[ply][gate] ~= 2 or sharing[self.player][self.entity] ~= 2)) then cont = true end

			-- If e2 is not same as e2 that trace and e2 does not share at all
			if (gate ~= self.entity and (sharing[ply][gate] == 0 or sharing[self.player][self.entity] == 0)) then cont = true end

			if (!cont) then
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

			local cont = false

			-- If player is not same player who trace and e2's does not share with other players e2
			if (ply ~= self.player and (sharing[ply][gate] ~= 2 or sharing[self.player][self.entity] ~= 2)) then cont = true end

			-- If e2 is not same as e2 that trace and e2 does not share at all
			if (gate ~= self.entity and (sharing[ply][gate] == 0 or sharing[self.player][self.entity] == 0)) then cont = true end

			if (!cont) then
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

			local cont = false

			-- If player is not same player who trace and e2's does not share with other players e2
			if (ply ~= self.player and (sharing[ply][gate] ~= 2 or sharing[self.player][self.entity] ~= 2)) then cont = true end

			-- If e2 is not same as e2 that trace and e2 does not share at all
			if (gate ~= self.entity and (sharing[ply][gate] == 0 or sharing[self.player][self.entity] == 0)) then cont = true end

			if (!cont) then
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

local function TsRayEllipsoidIntersection( start, dir, self )

	local traces = {}

	for ply, plyGates in pairs(shapes) do

		for gate, gateShapes in pairs(plyGates) do

			local cont = false

			-- If player is not same player who trace and e2's does not share with other players e2
			if (ply ~= self.player and (sharing[ply][gate] ~= 2 or sharing[self.player][self.entity] ~= 2)) then cont = true end

			-- If e2 is not same as e2 that trace and e2 does not share at all
			if (gate ~= self.entity and (sharing[ply][gate] == 0 or sharing[self.player][self.entity] == 0)) then cont = true end

			if (!cont) then
				for k,shape in pairs(gateShapes) do

					if (shape.Model == "ellipsoid") then

						local pos, ang, normal, rotation
						if (shape.Parent) then
							pos, ang, normal, rotation = GetWorldData(shape)
						else
							pos, ang, normal, rotation = shape.Pos, shape.Ang, shape.Normal, shape.Rotation
						end

						local hitPos = RayOEllipsoidIntersection( start, dir, pos, shape.Size, ang )

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
	local rayPolygon = TsRayPolygonIntersection( start, dir, self )
	local rayBox = TsRayBoxIntersection( start, dir, self)
	local rayCircle = TsRayCircleIntersection( start, dir, self )
	local raySphere = TsRaySphereIntersection( start, dir, self )
	local rayEllipsoid = TsRayEllipsoidIntersection( start, dir, self )

	table.Add(traces,rayPlane)
	table.Add(traces,rayFace)
	table.Add(traces,rayPolygon)
	table.Add(traces,rayBox)
	table.Add(traces,rayCircle)
	table.Add(traces,raySphere)
	table.Add(traces,rayEllipsoid)

	return traces

end


local function TsConeSphereIntersection( start, dir, angle, self )

	local traces = {}

	for ply,plyGates in pairs(shapes) do

		for gate,gateShapes in pairs(plyGates) do

			local cont = false

			-- If player is not same player who trace and e2's does not share with other players e2
			if (ply ~= self.player and (sharing[ply][gate] ~= 2 or sharing[self.player][self.entity] ~= 2)) then cont = true end

			-- If e2 is not same as e2 that trace and e2 does not share at all
			if (gate ~= self.entity and (sharing[ply][gate] == 0 or sharing[self.player][self.entity] == 0)) then cont = true end

			if (!cont) then
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



--[[******************************
*****     Retrieval functions     *****
******************************]]

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

local function GetHitVertices( traces, index )

	if (traces[index]) then
		return traces[index].Vertices
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



--[[***********************
*****     E2 Datatype     *****
************************]]

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

e2function number operator_is(tracedata walker)
	if walker then return 1 else return 0 end
end



--[[***********************************
*****     E2 Intersection functions     *****
***********************************]]

e2function vector rayPlaneIntersection( vector start, vector dir, vector pos, vector normal )
	return RayPlaneIntersection( start, dir, pos, normal )
end

e2function vector rayFaceIntersection( vector start, vector dir, vector pos, vector normal, vector size, number ang )
	return RayFaceIntersection( start, dir, pos, normal, size, ang )
end

e2function vector rayPolygonIntersection( vector start, vector dir, vector vertex1, vector vertex2, vector vertex3 )
	return RayPolygonIntersection( start, dir, {vertex1, vertex2, vertex3} )
end

e2function vector rayAABBoxIntersection( vector start, vector dir, vector pos, vector size )
	return RayAABBoxIntersection( start, dir, pos, size )
end

e2function vector rayOBBoxIntersection( vector start, vector dir, vector pos, vector size, angle ang )
	return RayOBBoxIntersection( start, dir, pos, size, ang )
end

e2function vector rayCircleIntersection( vector start, vector dir, vector pos, vector normal, number radius )
	return RayCircleIntersection( start, dir, pos, normal, radius )
end

e2function vector raySphereIntersection( vector start, vector dir, vector pos, number radius )
	local P = RaySphereIntersection( start, dir, pos, radius )
  return (P ~= nil) and P or Vector()
end

e2function vector rayAAEllipsoidIntersection( vector start, vector dir, vector pos, vector size )
	return RayAAEllipsoidIntersection( start, dir, pos, size )
end

e2function vector rayOEllipsoidIntersection( vector start, vector dir, vector pos, vector size, angle ang )
	return RayOEllipsoidIntersection( start, dir, pos, size, ang )
end

e2function vector coneSphereIntersection( vector start, vector dir, vector pos, number radius, number ang )
	return ConeSphereIntersection( start, dir, pos, radius, ang )
end



--[[*************************
*****     E2 * functions     *****
*************************]]

e2function number tsShapeCanCreate( )
	return GetConVarNumber("wire_shapes_max") - playerAmount[self.player]
end

e2function void tsShapeShare( number share )
	return ShapeShare( share, self )
end

e2function string tsShapeCreate( number index, string model, number radius, rotation, vector pos, vector normal, vector size, angle ang, vector vertex1, vector vertex2, vector vertex3 )
	if (!ShapeCanCreate( self.player )) then return "Limit reached" end
	return ShapeCreate( index, model, radius, rotation, pos, normal, size, ang, vertices, self )
end

e2function string tsShapeCreate( number index )
	if (!ShapeCanCreate( self.player )) then return "Limit reached" end
	return ShapeCreate( index, "", 0, 0, Vector(0,0,0), Vector(0,0,0), Vector(0,0,0), Angle(0,0,0), {}, self )
end

e2function string tsShapePolygon( number index, vector vertex1, vector vertex2, vector vertex3 )
	if (!ShapeCanCreate( self.player )) then return "Limit reached" end

	return ShapeCreatePolygon( index, {vertex1, vertex2, vertex3}, self )
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
	return ShapePos( index, pos, self )
end

e2function string tsShapeVertices( number index, vector vertex1, vector vertex2, vector vertex3 )
	return ShapeVertices( index, {vertex1, vertex2, vertex3}, self )
end

e2function string tsShapeAng( number index, angle ang )
	return ShapeAng( index, ang, self )
end

e2function string tsShapeNormal( number index, vector normal )
	return ShapeNormal( index, normal, self )
end

e2function string tsShapeSize( number index, vector size )
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



--[[*************************************
*****     E2 ts intersection functions     *****
*************************************]]

e2function tracedata tsRayPlaneIntersection( vector start, vector dir )
	local traces = TsRayPlaneIntersection( start, dir, self )
	SortByDistance( traces, start )
	return traces
end

e2function tracedata tsRayFaceIntersection( vector start, vector dir )
	local traces = TsRayFaceIntersection( start, dir, self )
	SortByDistance( traces, start )
	return traces
end

e2function tracedata tsRayPolygonIntersection( vector start, vector dir )
	local traces = TsRayPolygonIntersection( start, dir, self )
	SortByDistance( traces, start )
	return traces
end

e2function tracedata tsRayBoxIntersection( vector start, vector dir )
	local traces =  TsRayBoxIntersection( start, dir, self )
	SortByDistance( traces, start )
	return traces
end

e2function tracedata tsRayCircleIntersection( vector start, vector dir )
	local traces =  TsRayCircleIntersection( start, dir, self )
	SortByDistance( traces, start )
	return traces
end

e2function tracedata tsRaySphereIntersection( vector start, vector dir )
	local traces =  TsRaySphereIntersection( start, dir, self )
	SortByDistance( traces, start )
	return traces
end

e2function tracedata tsRayEllipsoidIntersection( vector start, vector dir )
	local traces =  TsRayEllipsoidIntersection( start, dir, self )
	SortByDistance( traces, start )
	return traces
end

e2function tracedata tsRayIntersection( vector start, vector dir )
	local traces =  TsRayIntersection( start, dir, self )
	SortByDistance( traces, start )
	return traces
end

e2function tracedata tsConeSphereIntersection( vector start, vector dir, number angle )
	local traces =  TsConeSphereIntersection( start, dir, angle, self )
	SortByDistance( traces, start )
	return traces
end



--[[********************************
*****     E2 Retrieval functions     *****
********************************]]

e2function number tracedata:sortByDistance( vector pos )
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

e2function vector tracedata:vertices( )
	return GetHitVertices( this, 1 )
end

e2function vector tracedata:vertices( number index )
	return GetHitVertices( this, index )
end

e2function angle tracedata:ang( )
	return GetHitAng( this, 1 )
end

e2function angle tracedata:ang( number index )
	return GetHitAng( this, index )
end

e2function vector tracedata:hitNormal( )
	return GetHitNormal( this, 1 )
end

e2function vector tracedata:hitNormal( number index )
	return GetHitNormal( this, index )
end

e2function vector tracedata:size( )
	return GetHitSize( this, 1 )
end

e2function vector tracedata:size( number index )
	return GetHitSize( this, index )
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



--[[******************
*****     Hooks     *****
******************]]

-- When an e2 is spawned
registerCallback("construct",function(self)
	if (!sharing[self.player]) then
		shapes[self.player] = {}
		sharing[self.player] = {}
		playerAmount[self.player] = 0
	end
	shapes[self.player][self.entity] = {}
	sharing[self.player][self.entity] = 0
end)

-- When an e2 is removed
registerCallback("destruct",function(self)
	if sharing[self.player] and sharing[self.player][self.entity] then
		ShapeClear( self )

		shapes[self.player][self.entity] = nil
		sharing[self.player][self.entity] = nil
	end
end)


-- When player leaves, remove his shapes.
hook.Add("PlayerDisconnected","playerdisconnected",function(ply)
	if (ply:IsValid() and ply:IsPlayer()) then
		shapes[ply] = nil
		sharing[ply] = nil
		playerAmount[ply] = nil
	end
end)
