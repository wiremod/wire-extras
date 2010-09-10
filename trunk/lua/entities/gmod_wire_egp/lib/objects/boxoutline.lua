local Obj = EGP:NewObject( "BoxOutline" )
Obj.size = 1
Obj.Draw = function( self )
	if (self.a>0 and self.w > 0 and self.h > 0) then
		surface.SetDrawColor( self.r, self.g, self.b, self.a )
		local s = self.size / 2
		EGP:DrawLine( self.x				, self.y + s			, self.x + self.w	  , self.y + s			, self.size )
		EGP:DrawLine( self.x + self.w - s	, self.y				, self.x + self.w - s , self.y + self.h		, self.size )
		EGP:DrawLine( self.x + self.w		, self.y + self.h - s	, self.x			  , self.y + self.h - s	, self.size )
		EGP:DrawLine( self.x + s			, self.y + self.h		, self.x + s 		  , self.y				, self.size )
	end
end
Obj.Transmit = function( self )
	EGP.umsg.Short( self.size )
	self.BaseClass.Transmit( self )
end
Obj.Receive = function( self, um )
	local tbl = {}
	tbl.size = um:ReadShort()
	table.Merge( tbl, self.BaseClass.Receive( self, um ) )
	return tbl
end
Obj.DataStreamInfo = function( self )
	local tbl = {}
	tbl.size = self.size
	table.Merge( tbl, self.BaseClass.DataStreamInfo( self ) )
	return tbl
end