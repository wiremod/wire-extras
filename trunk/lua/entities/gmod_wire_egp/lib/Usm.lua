--Usermessage Layouts

EGP.USM.Default = {
		{ "Short", "X" },
		{ "Short", "Y" },
		{ "Short", "W" },
		{ "Short", "H" },
		{ "Byte", "R" },
		{ "Byte", "G" },
		{ "Byte", "B" },
		{ "Byte", "A" },
}

EGP.USM.E = {}

EGP.USM.box = {
		{ "Short", "X" },
		{ "Short", "Y" },
		{ "Short", "W" },
		{ "Short", "H" },
		{ "Short", "Ang" },
		{ "Byte", "R" },
		{ "Byte", "G" },
		{ "Byte", "B" },
		{ "Byte", "A" },
		{ "String", "material" },
}

EGP.USM.boxoutline = {
		{ "Short", "X" },
		{ "Short", "Y" },
		{ "Short", "W" },
		{ "Short", "H" },
		{ "Byte", "R" },
		{ "Byte", "G" },
		{ "Byte", "B" },
		{ "Byte", "A" },
		{ "String", "material" },
}

EGP.USM.text = {
		{ "Short", "X" },
		{ "Short", "Y" },
		{ "Byte", "R" },
		{ "Byte", "G" },
		{ "Byte", "B" },
		{ "Byte", "A" },
		{ "String", "text" },
		{ "Char", "falign" },
		{ "Short", "fsize" },
		{ "Char", "fid" }
}

EGP.USM.textl = {
		{ "Short", "X" },
		{ "Short", "Y" },
		{ "Short", "W" },
		{ "Short", "H" },
		{ "Byte", "R" },
		{ "Byte", "G" },
		{ "Byte", "B" },
		{ "Byte", "A" },
		{ "String", "text" },
		{ "Char", "falign" },
		{ "Short", "fsize" },
		{ "Char", "fid" }
}

EGP.USM.line = {
		{ "Short", "X" },
		{ "Short", "Y" },
		{ "Short", "X1" },
		{ "Short", "Y1" },
		{ "Byte", "R" },
		{ "Byte", "G" },
		{ "Byte", "B" },
		{ "Byte", "A" },
}

EGP.USM.circle = {
		{ "Short", "X" },
		{ "Short", "Y" },
		{ "Short", "W" },
		{ "Short", "H" },
		{ "Byte", "R" },
		{ "Byte", "G" },
		{ "Byte", "B" },
		{ "Byte", "A" }
}

EGP.USM.triangle = {
		{ "Short", "X1" },
		{ "Short", "Y1" },
		{ "Short", "X2" },
		{ "Short", "Y2" },
		{ "Short", "X3" },
		{ "Short", "Y3" },
		{ "Byte", "R" },
		{ "Byte", "G" },
		{ "Byte", "B" },
		{ "Byte", "A" }
}
EGP.USM.poly = {
		{ "Byte", "R" },
		{ "Byte", "G" },
		{ "Byte", "B" },
		{ "Byte", "A" },
		{ "String", "material" },
		{ "VertexList", "vertices" }
}
