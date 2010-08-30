local Obj = EGP:NewObject( "Line" )
Obj.w = nil
Obj.h = nil
Obj.x2 = 0
Obj.y2 = 0
Obj.size = 1
Obj.verticesindex = { { "x", "y" }, { "x2", "y2" } }
Obj.Draw = function( self )
	if (self.a>0) then
		surface.SetDrawColor( self.r, self.g, self.b, self.a )
		if (self.size == 1) then
			surface.DrawLine( self.x, self.y, self.x2, self.y2 )
		else
			if (self.size < 1) then self.size = 1 end
			
			-- Calculate position
			local x = (self.x + self.x2) / 2
			local y = (self.y + self.y2) / 2
			
			-- calculate height
			local w = math.sqrt( (self.x2-self.x) ^ 2 + (self.y2-self.y) ^ 2 )
			
			-- Calculate angle (Thanks to Fizyk)
			local angle = math.deg(math.atan2(self.y-self.y2,self.x2-self.x))
			
			surface.DrawTexturedRectRotated( x, y, w, self.size, angle )
		end
	end
end
Obj.Transmit = function( self )
	EGP.umsg.Short(self.x)
	EGP.umsg.Short(self.y)
	EGP.umsg.Short(self.x2)
	EGP.umsg.Short(self.y2)
	EGP.umsg.Short(self.size)
	EGP:SendMaterial( self )
	EGP:SendColor( self )
end
Obj.Receive = function( self, um )
	local tbl = {}
	tbl.x = um:ReadShort()
	tbl.y = um:ReadShort()
	tbl.x2 = um:ReadShort()
	tbl.y2 = um:ReadShort()
	tbl.size = um:ReadShort()
	EGP:ReceiveMaterial( tbl, um )
	EGP:ReceiveColor( tbl, self, um )
	return tbl
end
Obj.DataStreamInfo = function( self )
	return { x = self.x, y = self.y, x2 = self.x2, y2 = self.y2, r = self.r, g = self.g, b = self.b, a = self.a }
end