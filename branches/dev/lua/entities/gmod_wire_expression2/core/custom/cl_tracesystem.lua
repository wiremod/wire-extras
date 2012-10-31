if E2Helper then

--Basic intersection functions
E2Helper.Descriptions["rayPlaneIntersection"] = "Return the position where a ray (start, dir) intersects with a plane (pos, normal)."
E2Helper.Descriptions["rayFaceIntersection"] = "Return the position where a ray (start, dir) intersects with a face (pos, normal, size, rotation)."
E2Helper.Descriptions["rayPolygonIntersection"] = "Return the position where a ray (start, dir) intersects with a Polygon (Three vertices)."
E2Helper.Descriptions["rayAABBoxIntersection"] = "Return the position where a ray (start, dir) intersects with a axis aligned bounding box (pos, size)."
E2Helper.Descriptions["rayOBBoxIntersection"] = "Return the position where a ray (start, dir) intersects with a oriented  bounding box (pos, size, angle)."
E2Helper.Descriptions["rayCircleIntersection"] = "Return the position where a ray (start, dir) intersects with a circle (pos, normal, radius)."
E2Helper.Descriptions["raySphereIntersection"] = "Return the position where a ray (start, dir) intersects with a sphere (pos, radius)."
E2Helper.Descriptions["coneSphereIntersection"] = "Return the position where a cone (start, dir, angle) intersects with a sphere (pos, radius)."

--Ts intersection functions
E2Helper.Descriptions["tsRayPlaneIntersection"] = "Like rayPlaneIntersection() except it returns tracedata from all intersections with tracing system's planes"
E2Helper.Descriptions["tsRayFaceIntersection"] = "Like rayFaceIntersection() except it returns tracedata from all intersections with tracing system's faces"
E2Helper.Descriptions["tsRayPolygonIntersection"] = "Like rayPolygonIntersection() except it returns tracedata from all intersections with tracing system's polygons"
E2Helper.Descriptions["tsRayBoxIntersection"] = "Like rayOBBoxIntersection() except it returns tracedata from all intersections with tracing system's boxes"
E2Helper.Descriptions["tsRayCircleIntersection"] = "Like rayOBBoxIntersection() except it returns tracedata from all intersections with tracing system's circles"
E2Helper.Descriptions["tsRaySphereIntersection"] = "Like raySphereIntersection() except it returns tracedata from all intersections with tracing system's spheres"
E2Helper.Descriptions["tsRayIntersection"] = "A ray trace that return tracedata from all intersections with tracing system's shapes"
E2Helper.Descriptions["tsConeSphereIntersection"] = "coneSphereIntersection() except it returns tracedata from all intersections with tracing system's spheres"

--Ts shape functions
E2Helper.Descriptions["tsShapeCanCreate"] = "Returns how many shapes the player still can create."
E2Helper.Descriptions["tsShapeShare"] = "Sets the scope of the e2. Setting the scope determines what shapes the e2 can hit (and vice versa). Check the wiki (data signals) for more info about scopes."
E2Helper.Descriptions["tsShapeCreate"] = "Creates a shape. Can take alot of arguments, or just the index."
E2Helper.Descriptions["tsShapePolygon"] = "Creates a polygon, you can use tsShapeCreate(), but this is simpler to use."
E2Helper.Descriptions["tsShapeModel"] = "Set the shape's model."
E2Helper.Descriptions["tsShapeRadius"] = "Set the shape's radius (spheres and circles)."
E2Helper.Descriptions["tsShapeRotation"] = "Set the shape's rotation (faces)."
E2Helper.Descriptions["tsShapePos"] = "Set the shape's position."
E2Helper.Descriptions["tsShapeVertices"] = "Set the shape's vertices (polygons)."
E2Helper.Descriptions["tsShapeAng"] = "Set the shape's angle."
E2Helper.Descriptions["tsShapeNormal"] = "Set the shape's normal (planes, faces and circles)."
E2Helper.Descriptions["tsShapeSize"] = "Set the shape's size (boxes)."
E2Helper.Descriptions["tsShapeParent"] = "Set the shape's parent."
E2Helper.Descriptions["tsShapeRemove"] = "Remove a shape."
E2Helper.Descriptions["tsShapeClear"] = "Remove all shapes this e2 created."

--Ts retrieval functions
E2Helper.Descriptions["sortByDistance"] = "Sort the tracedata so hitpos of index 1 is closest to to vector. Returns the number of shapes in tracedata."
E2Helper.Descriptions["count"] = "Return the number of shapes in tracedata."
E2Helper.Descriptions["hit"] = "Returns if index exist in tracedata (same as index <= xtd:count())."
E2Helper.Descriptions["hitAngle"] = "Returns the angle between cone direction and direction to hitpos."
E2Helper.Descriptions["index"] = "Returns the shape's index."
E2Helper.Descriptions["distance"] = "Returns distance between hitpos and start of ray."
E2Helper.Descriptions["radius"] = "Returns the shape's radius."
E2Helper.Descriptions["rotation"] = "Returns the shape's rotation."
E2Helper.Descriptions["model"] = "Returns the shape's model."
E2Helper.Descriptions["hitPos"] = "Returns the position of where the shape got hit."
E2Helper.Descriptions["pos"] = "Returns the shape's pos."
E2Helper.Descriptions["ang"] = "Returns the shape's ang."
E2Helper.Descriptions["hitNormal"] = "Returns the hit normal."
E2Helper.Descriptions["size"] = "Returns the shape's size."
E2Helper.Descriptions["parent"] = "Returns the shape's parent."
E2Helper.Descriptions["entity"] = "Returns the e2 that created the shape."
E2Helper.Descriptions["owner"] = "Returns the owner that created the shape."

end
