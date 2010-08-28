include('shared.lua')

function ENT:Initialize()
	self.RenderTable = table.Copy(EGP.HomeScreen)
end

--[[ THIS FUNCTION DOESN'T WORK AS INTENDED. Which is why I added the convar to block EGP screens/HUDs/emitters.
function ENT:FixPositions()
	for k,v in ipairs( self.RenderTable ) do
		if (v.vertices) then
			print("object ahs vertices")
			for k2, v2 in ipairs( v.vertices ) do
				if (v2.x < 0) then
					print("vertices x changed to 0")
					self.RenderTable[k].vertices[k2].x = 0
				elseif (v2.x > 512) then
					print("vertices x changed to 512")
					self.RenderTable[k].vertices[k2].x = 512
				end
				if (v2.y < 0) then
					print("vertices y changed to 0")
					self.RenderTable[k].vertices[k2].y = 0
				elseif (v2.y > 512) then
					print("vertices y changed to 512")
					self.RenderTable[k].vertices[k2].y = 512
				end
			end
		elseif (v.x and v.y and v.h and v.w) then
			print("object has x,y,w,h")
			if (v.x - v.w / 2 < 0) then
				print("vertices xw changed to 0")
				self.RenderTable[k].x = v.x + v.w / 4
				self.RenderTable[k].w = v.w - v.w / 2
			elseif (v.x + v.w / 2 > 512) then
				print("vertices xw changed to 512")
				self.RenderTable[k].x = v.x - v.w / 4
				self.RenderTable[k].w = v.w - v.w / 2
			end
			if (v.y - v.h / 2 < 0) then
				print("vertices yh changed to 0")
				self.RenderTable[k].y = v.y + v.h / 4
				self.RenderTable[k].h = v.h - v.h / 2
			elseif (v.y + v.h / 2 > 512) then
				print("vertices yh changed to 512")
				self.RenderTable[k].y = v.y - v.h / 4
				self.RenderTable[k].h = v.h - v.h / 2
			end
		elseif (v.x and v.y) then
			print("object has x,y")
			if (v.x < 0) then
				print("vertices x changed to 0")
				self.RenderTable[k].x = 0
			elseif (v.x > 512) then
				print("vertices x changed to 512")
				self.RenderTable[k].x = 512
			end
			if (v.y < 0) then
				print("vertices y changed to 0")
				self.RenderTable[k].y = 0
			elseif (v.y > 512) then
				print("vertices y changed to 512")
				self.RenderTable[k].y = 512
			end
		end
	end
end
]]

function ENT:EGP_Update() 
	for k,v in ipairs( self.RenderTable ) do
		if (v.parent and v.parent != 0) then
			local x, y, angle = EGP:GetGlobalPos( self, v.index )
			EGP:EditObject( v, { x = x, y = y, angle = angle } )
		end
	end
	--self:FixPositions()
end

function ENT:Draw()
	self.Entity.DrawEntityOutline = function() end
	self.Entity:DrawModel()
	Wire_Render(self.Entity)
	if (self.RenderTable and #self.RenderTable > 0) then
		local pos = self:LocalToWorld( Vector( -64, 0, 135 ) )
		local ang = self:LocalToWorldAngles( Angle(0,0,90) )

		cam.Start3D2D( pos , ang , 0.25 )
			for k,v in ipairs( self.RenderTable ) do 
				local oldtex = EGP:SetMaterial( v.material )
				v:Draw() 
				EGP:FixMaterial( oldtex )
			end
		cam.End3D2D()
		
	end
end