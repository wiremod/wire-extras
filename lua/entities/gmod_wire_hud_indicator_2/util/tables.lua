function PrintTitledTable( title, t )
	print( title )
	PrintTable( t, 8 )
end

function CatTables( tables )
	local result = {}
	
	for index,t in pairs( tables ) do
		for key, value in pairs( t ) do
			result[key] = value
		end
	end
	
	return result
end

function PrintStack( stack )
	print( "[STACK]" )
	for key,value in pairs( stack ) do
		print( "", "[" ..key.. "]", value.type, value.value )
	end
	print( "[/STACK]" )
end
