-- Constants.lua
--
-- Constants for the parser to replace in HML.
-- Place any additional replacements here.
--
-- Table keys should be in UPPERCASE always, otherwise they wont be replaced
-- when the parser sees the argument.
--
-- NOTE: Parser only currently replaces constants in arguments.
--
-- Moggie100.


function HMLConstants()
	constants = {}
	constants["BLACK"]		=	{ type="vector_3d", x=000, y=000, z=000 }
	constants["BLACK25"]	=	{ type="vector_4d", x=000, y=000, z=000, w=64 }
	constants["BLACK50"]	=	{ type="vector_4d", x=000, y=000, z=000, w=128 }
	constants["BLACK75"]	=	{ type="vector_4d", x=000, y=000, z=000, w=192 }

	constants["SILVER"]		=	{ type="vector_3d", x=192, y=192, z=192 }
	constants["SILVER25"]	=	{ type="vector_4d", x=192, y=192, z=192, w=64 }
	constants["SILVER50"]	=	{ type="vector_4d", x=192, y=192, z=192, w=128 }
	constants["SILVER75"]	=	{ type="vector_4d", x=192, y=192, z=192, w=192 }

	constants["GRAY"]		=	{ type="vector_3d", x=128, y=128, z=128 }
	constants["GRAY25"]		=	{ type="vector_4d", x=128, y=128, z=128, w=64 }
	constants["GRAY50"]		=	{ type="vector_4d", x=128, y=128, z=128, w=128 }
	constants["GRAY75"]		=	{ type="vector_4d", x=128, y=128, z=128, w=192 }

	constants["WHITE"]		=	{ type="vector_3d", x=255, y=255, z=255 }
	constants["WHITE25"]	=	{ type="vector_4d", x=255, y=255, z=255, w=64 }
	constants["WHITE50"]	=	{ type="vector_4d", x=255, y=255, z=255, w=128 }
	constants["WHITE75"]	=	{ type="vector_4d", x=255, y=255, z=255, w=192 }

	constants["MAROON"]		=	{ type="vector_3d", x=128, y=000, z=000 }
	constants["MAROON25"]	=	{ type="vector_4d", x=128, y=000, z=000, w=64 }
	constants["MAROON50"]	=	{ type="vector_4d", x=128, y=000, z=000, w=128 }
	constants["MAROON75"]	=	{ type="vector_4d", x=128, y=000, z=000, w=192 }

	constants["RED"]		=	{ type="vector_3d", x=255, y=000, z=000 }
	constants["RED25"]		=	{ type="vector_4d", x=255, y=000, z=000, w=64 }
	constants["RED50"]		=	{ type="vector_4d", x=255, y=000, z=000, w=128 }
	constants["RED75"]		=	{ type="vector_4d", x=255, y=000, z=000, w=192 }

	constants["PURPLE"]		=	{ type="vector_3d", x=128, y=000, z=128 }
	constants["PURPLE25"]	=	{ type="vector_4d", x=128, y=000, z=128, w=64 }
	constants["PURPLE50"]	=	{ type="vector_4d", x=128, y=000, z=128, w=128 }
	constants["PURPLE75"]	=	{ type="vector_4d", x=128, y=000, z=128, w=192 }

	constants["FUCHSIA"]	=	{ type="vector_3d", x=255, y=000, z=255 }
	constants["FUCHSIA25"]	=	{ type="vector_4d", x=255, y=000, z=255, w=64 }
	constants["FUCHSIA50"]	=	{ type="vector_4d", x=255, y=000, z=255, w=128 }
	constants["FUCHSIA75"]	=	{ type="vector_4d", x=255, y=000, z=255, w=192 }

	constants["GREEN"]		=	{ type="vector_3d", x=000, y=128, z=000 }
	constants["GREEN25"]	=	{ type="vector_4d", x=000, y=128, z=000, w=64 }
	constants["GREEN50"]	=	{ type="vector_4d", x=000, y=128, z=000, w=128 }
	constants["GREEN75"]	=	{ type="vector_4d", x=000, y=128, z=000, w=192 }

	constants["LIME"]		=	{ type="vector_3d", x=000, y=255, z=000 }
	constants["LIME25"]		=	{ type="vector_4d", x=000, y=255, z=000, w=64 }
	constants["LIME50"]		=	{ type="vector_4d", x=000, y=255, z=000, w=128 }
	constants["LIME75"]		=	{ type="vector_4d", x=000, y=255, z=000, w=192 }

	constants["OLIVE"]		=	{ type="vector_3d", x=128, y=128, z=000 }
	constants["OLIVE25"]	=	{ type="vector_4d", x=128, y=128, z=000, w=64 }
	constants["OLIVE50"]	=	{ type="vector_4d", x=128, y=128, z=000, w=128 }
	constants["OLIVE75"]	=	{ type="vector_4d", x=128, y=128, z=000, w=192 }

	constants["YELLOW"]		=	{ type="vector_3d", x=255, y=255, z=000 }
	constants["YELLOW25"]	=	{ type="vector_4d", x=255, y=255, z=000, w=64 }
	constants["YELLOW50"]	=	{ type="vector_4d", x=255, y=255, z=000, w=128 }
	constants["YELLOW75"]	=	{ type="vector_4d", x=255, y=255, z=000, w=192 }

	constants["NAVY"]		=	{ type="vector_3d", x=000, y=000, z=128 }
	constants["NAVY25"]		=	{ type="vector_4d", x=000, y=000, z=128, w=64 }
	constants["NAVY50"]		=	{ type="vector_4d", x=000, y=000, z=128, w=128 }
	constants["NAVY75"]		=	{ type="vector_4d", x=000, y=000, z=128, w=192 }

	constants["BLUE"]		=	{ type="vector_3d", x=000, y=000, z=255 }
	constants["BLUE25"]		=	{ type="vector_4d", x=000, y=000, z=255, w=64 }
	constants["BLUE50"]		=	{ type="vector_4d", x=000, y=000, z=255, w=128 }
	constants["BLUE75"]		=	{ type="vector_4d", x=000, y=000, z=255, w=192 }

	constants["TEAL"]		=	{ type="vector_3d", x=000, y=128, z=128 }
	constants["TEAL25"]		=	{ type="vector_4d", x=000, y=128, z=128, w=64 }
	constants["TEAL50"]		=	{ type="vector_4d", x=000, y=128, z=128, w=128 }
	constants["TEAL75"]		=	{ type="vector_4d", x=000, y=128, z=128, w=192 }

	constants["AQUA"]		=	{ type="vector_3d", x=000, y=255, z=255 }
	constants["AQUA25"]		=	{ type="vector_4d", x=000, y=255, z=255, w=64 }
	constants["AQUA50"]		=	{ type="vector_4d", x=000, y=255, z=255, w=128 }
	constants["AQUA75"]		=	{ type="vector_4d", x=000, y=255, z=255, w=192 }


	constants["DERMA"]		=	{ type="vector_4d", x=050, y=050, z=075, w=100 }
	constants["DERMA25"]	=	{ type="vector_4d", x=050, y=050, z=075, w=64 }
	constants["DERMA50"]	=	{ type="vector_4d", x=050, y=050, z=075, w=128 }
	constants["DERMA75"]	=	{ type="vector_4d", x=050, y=050, z=075, w=192 }
	constants["DERMA100"]	=	{ type="vector_4d", x=050, y=050, z=075, w=255 }

	return constants
end
