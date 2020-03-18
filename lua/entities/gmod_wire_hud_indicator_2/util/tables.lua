function PrintTitledTable( title, t )
	print( title )
	PrintTable( t, 8 )
end

function PrintTable (t, indent, done)
  if( type(t) == "table" ) then
    done = done or {}
    indent = indent or 0
    for key, value in pairs (t) do
      indentStr = string.rep (" ", indent) -- indent it
      if type (value) == "table" and not done [value] then
        done [value] = true
        print( indentStr..tostring(key).."{")
        PrintTable (value, indent+3, done)
      else
        print(indentStr..tostring (key), " = ", tostring(value))
      end
    end

    indentStr = string.rep (" ", indent-3) -- indent it
    print( indentStr.."}" )
  else
    print( "Not a table!" )
  end
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
