if E2Helper then
--EGP Max Elements Return Func
E2Helper.Descriptions["egpElements()"] = "Returns the servers limit of EGP elements."

--EGP Clear Function's
E2Helper.Descriptions["egpClear(xwl:)"] = "Emptys all memory on the egp."
E2Helper.Descriptions["egpClear(xwl:a)"] = "Emptys all memory inside cells on egp effecting elements indexed inside array."
E2Helper.Descriptions["egpRemove(xwl:n)"] = "Emptys the memory of the element indexed at n."

--EGP Draw functions
E2Helper.Descriptions["egpCanDraw(xwl:)"] = "Returns 1 if the EGP can draw at that time, Retuns 0 if not."
E2Helper.Descriptions["egpDraw(xwl:)"] = "Process the EGP's cache to its draw memory, Retuns 1 if it has drawn , Retuns 0 if it has not draw."

--Material Functions
E2Helper.Descriptions["egpMaterial(xwl:ns)"] = "Sets the material of element at n to s."
E2Helper.Descriptions["egpMaterialFromScreen(xwl:ne)"] = "Sets the material of element at index n to the wiredisplay of e."
E2Helper.Descriptions["egpMaterialFromScreen(xwl:nxwl)"] = "Sets the material of element at index n to the wiredisplay of enity of xwl."

--Misc Functions
E2Helper.Descriptions["egpAngle(xwl:nn)"] = "Set the angle of element at index n1 to n2. (Only works on egpBox.)"

--Set Position functions
E2Helper.Descriptions["egpPos(xwl:nv2)"] = "Set position of element at index n to v2."
E2Helper.Descriptions["egpPos(xwl:nnn)"] = "Set position of element at index n1 to vector2( n2 , n3 )."
E2Helper.Descriptions["egpPosX(xwl:nn)"] = "Set the X position of element at index n1 to n2."
E2Helper.Descriptions["egpPosY(xwl:nn)"] = "Set the Y position of element at index n1 to n2."

E2Helper.Descriptions["egpPos1(xwl:nv2)"] = "Set position1 of element at index n to v2."
E2Helper.Descriptions["egpPos1(xwl:nnn)"] = "Set position1 of element at index n1 to vector2( n2 , n3 )."
E2Helper.Descriptions["egpPosX1(xwl:nn)"] = "Set the X position1 of element at index n1 to n2."
E2Helper.Descriptions["egpPosY1(xwl:nn)"] = "Set the Y position1 of element at index n1 to n2."

E2Helper.Descriptions["egpPos2(xwl:nv2)"] = "Set position2 of element at index n to v2."
E2Helper.Descriptions["egpPos2(xwl:nnn)"] = "Set position2 of element at index n1 to vector2( n2 , n3 )."
E2Helper.Descriptions["egpPosX2(xwl:nn)"] = "Set the X position2 of element at index n1 to n2."
E2Helper.Descriptions["egpPosY2(xwl:nn)"] = "Set the Y position2 of element at index n1 to n2."

--Set Size functions
E2Helper.Descriptions["egpSize(xwl:nv2)"] = "Set the size of element at index n to v2."
E2Helper.Descriptions["egpSize(xwl:nnn)"] = "Set the size of element at index n1 to vec2( n2 , n3 )."

--Set TextElement functions
E2Helper.Descriptions["egpSetText(xwl:ns)"] = "Sets the text of a text element at index n to s."
E2Helper.Descriptions["egpFont(xwl:nsn)"] = "Sets the font/size of text of a text element at index n1 to Font:s Size:n2."
E2Helper.Descriptions["egpSetFont(xwl:nsn)"] = "Sets the font/size of text of a text element at index n1 to Font:s Size:n2."
E2Helper.Descriptions["egpTextAlign(xwl:nnn)"] = "Sets the horizontal and veritcal alignment of text of a text element at index n1 to Horizontal:n2 Vertical:n3."

--Set Color functions
E2Helper.Descriptions["egpColor(xwl:nv3)"] = "Sets the color of element at index n as vec4( Red , Blue , Green )."
E2Helper.Descriptions["egpColor(xwl:nv4)"] = "Sets the color of element at index n as vec4( Red , Blue , Green , Alpha )."
E2Helper.Descriptions["egpColor(xwl:nnnn)"] = "Sets the color of element at index n1 to vec( n2 , n3 , n4 )."
E2Helper.Descriptions["egpColor(xwl:nnnnn)"] = "Sets the color of element at index n1 to vec4( n2 , n3 , n4 , n5)."

--BOX
E2Helper.Descriptions["egpBox(xwl:nv2v2)"] = "Index Position Size\nCreate a box element at index."
E2Helper.Descriptions["egpBox(xwl:nv2v2v)"] = "Index Position Size Color\nCreate a box element at index."
E2Helper.Descriptions["egpBox(xwl:nv2v2v4)"] = "Index Position Size Color\nCreate a box element at index."

E2Helper.Descriptions["egpBox(xwl:nnnnn)"] = "Index X Y Width Height\nCreate a box element at index."
E2Helper.Descriptions["egpBox(xwl:nnnnnv)"] = "Index X Y Width Height Color\nCreate a box element at index."
E2Helper.Descriptions["egpBox(xwl:nnnnnv4)"] = "Index X Y Width Height Color\nCreate a box element at index."

--BOXOutline
E2Helper.Descriptions["egpBoxOutline(xwl:nv2v2)"] = "Index Position Size\nCreate a boxoutline element at index."
E2Helper.Descriptions["egpBoxOutline(xwl:nv2v2v)"] = "Index Position Size Color\nCreate a boxoutline element at index."
E2Helper.Descriptions["egpBoxOutline(xwl:nv2v2v4)"] = "Index Position Size Color\nCreate a boxoutline element at index."

E2Helper.Descriptions["egpBoxOutline(xwl:nnnnn)"] = "Index X Y Width Height\nCreate a boxoutline element at index."
E2Helper.Descriptions["egpBoxOutline(xwl:nnnnnv)"] = "Index X Y Width Height Color\nCreate a boxoutline element at index."
E2Helper.Descriptions["egpBoxOutline(xwl:nnnnnv4)"] = "Index X Y Width Height Color\nCreate a boxoutline element at index."

--Line
E2Helper.Descriptions["egpLine(xwl:nv2v2)"] = "Index Position1 Position2\nCreate a line element at index."
E2Helper.Descriptions["egpLine(xwl:nv2v2v)"] = "Index Position1 Position2 Color\nCreate a line element at index."
E2Helper.Descriptions["egpLine(xwl:nv2v2v4)"] = "Index Position1 Position2 Color\nCreate a line element at index."

E2Helper.Descriptions["egpLine(xwl:nnnnn)"] = "Index X1 Y1 X2 Y2\nCreate a line element at index."
E2Helper.Descriptions["egpLine(xwl:nnnnnv)"] = "Index X1 Y1 X2 Y2 Color\nCreate a line element at index."
E2Helper.Descriptions["egpLine(xwl:nnnnnv4)"] = "Index X1 Y1 X2 Y2 Color\nCreate a line element at index."

--Circle
E2Helper.Descriptions["egpCircle(xwl:nv2v2)"] = "Index Position Size\nCreate a circle element at index."
E2Helper.Descriptions["egpCircle(xwl:nv2v2v)"] = "Index Position Size Color\nCreate a circle element at index."
E2Helper.Descriptions["egpCircle(xwl:nv2v2v4)"] = "Index Position Size Color\nCreate a circle element at index."

E2Helper.Descriptions["egpCircle(xwl:nnnnn)"] = "Index X Y Width Height\nCreate a circle element at index."
E2Helper.Descriptions["egpCircle(xwl:nnnnnv)"] = "Index X Y Width Height Color\nCreate a circle element at index."
E2Helper.Descriptions["egpCircle(xwl:nnnnnv4)"] = "Index X Y Width Height Color\nCreate a circle element at index."

--Triangle
E2Helper.Descriptions["egpTriangle(xwl:nv2v2v2)"] = "Index Position1 Position2 Position3\nCreate a triangle element at index."
E2Helper.Descriptions["egpTriangle(xwl:nv2v2v2v)"] = "Index Position1 Position2 Position3 Color\nCreate a triangle element at index."
E2Helper.Descriptions["egpTriangle(xwl:nv2v2v2v4)"] = "Index Position1 Position2 Position3 Color\nCreate a triangle element at index."

E2Helper.Descriptions["egpTriangle(xwl:nnnnn)"] = "Index X1 Y1 X2 Y2 X3 Y3\nCreate a triangle element at index."
E2Helper.Descriptions["egpTriangle(xwl:nnnnnv)"] = "Index X1 Y1 X2 Y2 X3 Y3 Color\nCreate a triangle element at index."
E2Helper.Descriptions["egpTriangle(xwl:nnnnnv4)"] = "Index X1 Y1 X2 Y2 X3 Y3 Color\nCreate a triangle element at index."

--Text
E2Helper.Descriptions["egpText(xwl:nsv2)"] = "Index Text Position\nCreate a text element at index."
E2Helper.Descriptions["egpText(xwl:nsv2v)"] = "Index Text Position Color\nCreate a text element at index."
E2Helper.Descriptions["egpText(xwl:nsv2v4)"] = "Index Text Position Color\nCreate a text element at index."

E2Helper.Descriptions["egpText(xwl:nsnn)"] = "Index Text X Y\nCreate a text element at index."
E2Helper.Descriptions["egpText(xwl:nsnnv)"] = "Index Text X Y Color\nCreate a text element at index."
E2Helper.Descriptions["egpText(xwl:nsnnv4)"] = "Index Text X Y Color\nCreate a text element at index."

--TextLayout
E2Helper.Descriptions["egpTextLayout(xwl:nsv2v2)"] = "Index Text Position Size\nCreate a TextLayout element at index."
E2Helper.Descriptions["egpTextLayout(xwl:nsv2v2v)"] = "Index Text Position Size Color\nCreate a TextLayout element at index."
E2Helper.Descriptions["egpTextLayout(xwl:nsv2v2v4)"] = "Index Text Position Size Color\nCreate a TextLayout element at index."

E2Helper.Descriptions["egpTextLayout(xwl:nsnnnn)"] = "Index Text X Y Width Height\nCreate a TextLayout element at index."
E2Helper.Descriptions["egpTextLayout(xwl:nsnnnnv)"] = "Index Text X Y X Y Color\nCreate a TextLayout element at index."
E2Helper.Descriptions["egpTextLayout(xwl:nsnnnnv4)"] = "Index Text X Y X Y Color\nCreate a TextLayout element at index."

--PolyGons 
E2Helper.Descriptions["egpPoly(xwl:na)"] = "Index Vertex-Array\nCreate a polygon element at index."
E2Helper.Descriptions["egpPoly(xwl:n...)"] = "Index (...)\nCreate a polygon element at index using all vector's and vector2's as a Vertex-Array."

E2Helper.Descriptions["egpPolyColor(xwl:nv4...)"] = "Index Color (...)\nCreate a polygon element at index using all vector's and vector2's as a Vertex-Array."
E2Helper.Descriptions["egpPolyColor(xwl:nv4a)"] = "Index Color Vertex-Array\nCreate a polygon element at index."

E2Helper.Descriptions["egpPolyColor(xwl:nv...)"] = "Index Color (...)\nCreate a polygon element at index using all vector's and vector2's as a Vertex-Array."
E2Helper.Descriptions["egpPolyColor(xwl:nva)"] = "Index Color Vertex-Array\nCreate a polygon element at index."

--Element Return Functions
E2Helper.Descriptions["egpGetElement(xwl:nn)"] = "Returns element at index n as a tabel\nwill use drawn memory if n2 is 0 or cache memory if n2 is 1."
E2Helper.Descriptions["egpGetElements(xwl:n)"] = "Returns an arry of all element index's being used\nwill use drawn memory if n is 0 or cache memory if n is 1."

--GetPos
E2Helper.Descriptions["egpGetPos(xwl:nn)"] = "Returns psoition of element at index n1 as vector2\nwill use drawn memory if n2 is 0 or cache memory if n2 is 1."
E2Helper.Descriptions["egpGetPos1(xwl:nn)"] = "Returns psoition1 of element at index n1 as vector2\nwill use drawn memory if n2 is 0 or cache memory if n2 is 1."
E2Helper.Descriptions["egpGetPos2(xwl:nn)"] = "Returns psoition2 of element at index n1 as vector2\nwill use drawn memory if n2 is 0 or cache memory if n2 is 1."

--Get Size
E2Helper.Descriptions["egpGetSize(xwl:nn)"] = "Returns size of element at index n1 as vector2\nwill use drawn memory if n2 is 0 or cache memory if n2 is 1."

--Get Text
E2Helper.Descriptions["egpGetText(xwl:nn)"] = "Returns text of text element at index n1 as string\nwill use drawn memory if n2 is 0 or cache memory if n2 is 1."

--Get Color
E2Helper.Descriptions["egpGetColor(xwl:nn)"] = "Returns color of text element at index n1 as vector4\nwill use drawn memory if n2 is 0 or cache memory if n2 is 1."

--To Mouse Co-Ords
E2Helper.Descriptions["egpToMouse(xwl:e)"] = "When e is a player who is aiming at the egp it will return thier aim position relative to the screen as vector2, OOtherwise it will return vec2(-1,-1)"

end