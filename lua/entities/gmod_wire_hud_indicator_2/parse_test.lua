dofile( "fakelib/system.lua" )


include( "parser/HMLParser.lua" )
include( "renderer/HMLRenderer.lua" )




code = ""
code = code .. "<hml context=\"screen\" >\n"
code = code .. "\t<rect start={10,10} end={200,200}>\n"
code = code .. "\t\t<text position={30, 50}>Meep\nWibble</text>\n"
code = code .. "\t\t<line start={30,30} end={50,50} color=WHITE50 />\n"
code = code .. "\t</rect>\n"
code = code .. "</hml>\n"

--print( "Parsing: ", code )

parser = HMLParser:new( code )
renderer = HMLRenderer:new()

--PrintTitledTable( "Parser", debug.getmetatable( parser ) )
--PrintTitledTable( "Renderer", debug.getmetatable( renderer ) )

t = parser:exec()

PrintTable(t)

renderer:Draw( t )

