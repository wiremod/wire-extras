-- Fakelib!
--
-- A small lib of dummy GMOD functions, useful for offline testing.
--
-- Moggie100.

fakesys = {}

function mapInclude( target, destination )
	fakesys[target] = destination
	print( "[FAKE]", tostring(target) .. " -> " .. tostring( destination ) )
end

function include( file )
	if( fakesys[file] ) then
		print("[FAKE]", "Requested " .. tostring(file) .. ", but was mapped to " .. tostring( fakesys[file] ) .. " - Overridden!" )
		dofile( fakesys[file] )
	else
		print("[FAKE]", "Hard-including " .. tostring(file) .. "! (non-mapped include path!)" )
		dofile( file )
	end
end

function Msg( message )
	print( "> " .. tostring(message) )
end

print("[FAKE]", "Loading FAKELib..." )

dofile( "fakelib/surface.lua" )
	print("", "\tLoaded surface emulation..." )

dofile( "fakelib/draw.lua" )
	print("", "\tLoading draw command emulation..." )
	
dofile( "fakelib/color.lua" )
	print("", "\tLoading color library emulation..." )

print("[FAKE]", "Loaded FAKELib" )
