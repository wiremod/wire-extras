local Obj = EGP:NewObject( "BoxOutline" )
Obj.Draw = function( self )
	if (self.a>0 and self.w > 0 and self.h > 0) then
		surface.SetDrawColor( self.r, self.g, self.b, self.a )
		surface.DrawOutlinedRect( self.x, self.y, self.w, self.h )
	end
end
Obj.Transmit = function( self )
	self.BaseClass.Transmit( self )
end
Obj.Receive = function( self, um )
	return self.BaseClass.Receive( self, um )
end
Obj.DataStreamInfo = function( self )
	return self.BaseClass.DataStreamInfo( self )
end