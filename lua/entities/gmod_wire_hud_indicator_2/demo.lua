-- --------------------------------- --
-- Set up a fake GMod environment... --
-- --------------------------------- --
dofile( "fakelib/system.lua" )

-- Set up alias paths for non-direct loading of includes... damn you Garry...
mapInclude( "Constants.lua", "parser/Constants.lua" )
mapInclude( "entities/gmod_wire_hud_indicator_2/util/tables.lua", "util/tables.lua" )
mapInclude( "valid_fonts.lua", "renderer/valid_fonts.lua" )
mapInclude( "tags/core.lua", "renderer/tags/core.lua" )
mapInclude( "tags/presets.lua", "renderer/tags/presets.lua" )

-- Now the stuff we -actually- need.
include( "util/errors.lua" )
include( "util/tables.lua" )

include( "expressions/expr_tokenizer.lua" )
include( "expressions/expr_stack.lua" )

include( "parser/HMLParser.lua" )

include( "renderer/HMLRenderer.lua" )
include( "expression_parser.lua" )

-- ------------------------------------------------------------------- --
-- The actual demo code, all of the above is just environment setup... --
-- ------------------------------------------------------------------- --

local	input = "<hml>\n"
	input = input .. "\t<rect start={10,10}; end={100,100}; >\n"
	input = input .. "\t\t<line start={50%,0%}; end={50%,100%}; />\n"
	input = input .. "\t\t<text position={(10*2)%,(10+5)%}; value={5,5}; />\n"
	input = input .. "\t</rect>\n"
	input = input .. "</hml>"
local parser = HMLParser:new( input )

local preParsedTable = parser:exec()
local requiredInputs = parser:getInputTable()

PrintTitledTable( "Pre-Parsed Table", preParsedTable )
PrintTitledTable( "Required Inputs", requiredInputs )

local renderer = HMLRenderer:new()
renderer:SetRenderTable( preParsedTable )
renderer:Draw()
