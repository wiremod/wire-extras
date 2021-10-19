//**********************************************
// Arithmetic Gates
//**********************************************

GateActions("Arithmetic")

GateActions["PHI"] = {
	name = "Phi",
	inputs = { },
	outputs = { "Algebra", "Trig", "666" },
	output = function(gate)
		return
			(1 + math.sqrt(5)) / 2,
			2*math.cos(math.rad(36)),
			-(math.sin(math.rad(666)) + math.cos(math.rad(6*6*6)))
	end	
}
//Q: What is Phi?
//A: Phi is a irrational decimal value of approx. 1.6180339887...
//   Phi resembles the ratio of the sides of an ordinay A4 paper sheet. -- that is bullshit, A4 is 1.414:1, very far from phi
//   Phi resembles the screen ratio of widescreens (16:9 or 16:10 is roughly the same as Phi:1).
//   Phi is the approximate ratio between two sucsessing fibbonachi numbers (1,1,2,3,5,8,13,21,35...).
//   Phi resembles the expansion coefficient of snail shells.
//   Phi resembles the expansion acceleration of the universe. -- wtf?
--   Phi is a/b = (a+b)/a

GateActions()
