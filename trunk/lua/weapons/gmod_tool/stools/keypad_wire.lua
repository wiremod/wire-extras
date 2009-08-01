if not WireVersion then return end

TOOL.Category		= "Wire - I/O"
TOOL.Name			= "#Keypad"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.ClientConVar["secure"] = "0"
TOOL.ClientConVar["weld"] = "1"
TOOL.ClientConVar["freeze"] = "1"

TOOL.ClientConVar["keygroup1"] = "-1"
TOOL.ClientConVar["keygroup2"] = "-1"
TOOL.ClientConVar["length1"] = "0.1"
TOOL.ClientConVar["length2"] = "0.1"
TOOL.ClientConVar["delay1"] = "0"
TOOL.ClientConVar["delay2"] = "0"
TOOL.ClientConVar["initdelay1"] = "0"
TOOL.ClientConVar["initdelay2"] = "0"
TOOL.ClientConVar["repeats1"] = "0"
TOOL.ClientConVar["repeats2"] = "0"
TOOL.ClientConVar["toggle1"] = "0"
TOOL.ClientConVar["toggle2"] = "0"
TOOL.ClientConVar["valueon1"] = "1"
TOOL.ClientConVar["valueon2"] = "1"
TOOL.ClientConVar["valueoff1"] = "0"
TOOL.ClientConVar["valueoff2"] = "0"

if ( CLIENT ) then

	language.Add( "Tool_keypad_wire_name", "Keypad (Wire)" )
	language.Add( "Tool_keypad_wire_desc", "Made by: Killer HAHA (Robbis_1)" )
	language.Add( "Tool_keypad_wire_0", "Left Click: Spawn a Keypad, Right Click: Update Keypad with settings" )


end

function TOOL:SetupKeypad(Ent, Password)
	Ent:AddPassword(Password)

	Ent:SetPlayer(self:GetOwner())
	Ent.length1 = self:GetClientNumber("length1")
	Ent.length2 = self:GetClientNumber("length2")

	Ent.keygroup1 = self:GetClientNumber("keygroup1")
	Ent.keygroup2 = self:GetClientNumber("keygroup2")

	Ent.delay1 = self:GetClientNumber("delay1")
	Ent.delay2 = self:GetClientNumber("delay2")

	Ent.initdelay1 = self:GetClientNumber("initdelay1")
	Ent.initdelay2 = self:GetClientNumber("initdelay2")

	Ent.repeats1 = self:GetClientNumber("repeat1")
	Ent.repeats2 = self:GetClientNumber("repeats2")

	Ent.toggle1 = util.tobool(self:GetClientNumber("toggle1"))
	Ent.toggle2 = util.tobool(self:GetClientNumber("toggle2"))
	
	Ent.valueon1 = self:GetClientNumber("valueon1")
	Ent.valueon2 = self:GetClientNumber("valueon2")
	Ent.valueoff1 = self:GetClientNumber("valueoff1")
	Ent.valueoff2 = self:GetClientNumber("valueoff2")

	Ent:SetNetworkedBool("keypad_showaccess", false)
	Ent.secure = util.tobool(self:GetClientNumber("secure")) -- feed duplicator
	Ent:SetNetworkedBool("keypad_secure", Ent.secure) -- feed client
end

function TOOL:RightClick(trace)
	if (trace.Entity:GetClass() == "player") then return false end
	if (CLIENT) then return true end

	local Ply = self:GetOwner()
	local Password = tonumber(Ply:GetInfo("keypad_adv_password"))

	local SpawnPos = trace.HitPos
	local TraceEnt = trace.Entity

	if (Password == nil) or (string.len(tostring(Password)) > 4) or (string.find(tostring(Password), "0")) then
		Ply:PrintMessage(3, "Invalid password!")
		return false
	end

	if (TraceEnt:IsValid() and TraceEnt:GetClass() == "sent_keypad" and TraceEnt:GetPlayer() == Ply ) then
		self:SetupKeypad(TraceEnt, Password)
		return true
	end
end

function TOOL:LeftClick(trace)
	if (trace.Entity:GetClass() == "player") then return false end
	if (CLIENT) then return true end

	local Ply = self:GetOwner()
	local Password = tonumber(Ply:GetInfo("keypad_adv_password"))

	local SpawnPos = trace.HitPos + trace.HitNormal
	local TraceEnt = trace.Entity

	if (Password == nil) or (string.len(tostring(Password)) > 4) or (string.find(tostring(Password), "0")) then
		Ply:PrintMessage(3, "Invalid password!")
		return false
	end

	local Keypad = ents.Create("sent_keypad")
	Keypad.AddOutputs = true
	Keypad:SetPos(SpawnPos)
	Keypad:SetAngles(trace.HitNormal:Angle())
	Keypad:Spawn()
	Keypad:SetAngles(trace.HitNormal:Angle())
	Keypad:Activate()

	Wire_TriggerOutput(Keypad, "Valid", self:GetClientNumber("valueoff1"))
	Wire_TriggerOutput(Keypad, "Invalid", self:GetClientNumber("valueoff2"))

	self:SetupKeypad(Keypad, Password)

	undo.Create("Wire Keypad")

	if (util.tobool(self:GetClientNumber("freeze"))) then
		Keypad:GetPhysicsObject():EnableMotion(false)
	end

	if (util.tobool(self:GetClientNumber("weld"))) and not (TraceEnt:GetClass() == "player") and not (TraceEnt:GetClass() == "sent_keypad") then
		local weld = constraint.Weld(Keypad, TraceEnt, 0, trace.PhysicsBone, 0)
		TraceEnt:DeleteOnRemove(Keypad)
		TraceEnt:DeleteOnRemove(weld)
		Keypad:DeleteOnRemove(weld)

		Keypad:GetPhysicsObject():EnableCollisions(false)

		undo.AddEntity(weld)
	end

	undo.AddEntity(Keypad)
	undo.SetPlayer(Ply)
	undo.Finish()

	Ply:AddCount( "keypads", Keypad )
	Ply:AddCleanup( "keypads", Keypad )

	return true
end

if (CLIENT) then
	local function ResetSettings(Ply, Com, Args)
		Ply:ConCommand("keypad_wire_length"..Args[1].." 0.1\n")
		Ply:ConCommand("keypad_wire_initdelay"..Args[1].." 0\n")
		Ply:ConCommand("keypad_wire_repeats"..Args[1].." 0\n")
		Ply:ConCommand("keypad_wire_delay"..Args[1].." 0\n")
		Ply:ConCommand("keypad_wire_toggle"..Args[1].." 0\n")
		Ply:ConCommand("keypad_wire_valueon"..Args[1].." 1\n")
		Ply:ConCommand("keypad_wire_valueoff"..Args[1].." 0\n")
	end
	concommand.Add("keypad_wire_reset", ResetSettings)
end

function TOOL.BuildCPanel( CPanel )
	CPanel:AddControl( "Header", {	Text = "#Tool_keypad_wire_name", Description	= "#Tool_keypad_wire_desc" }  )

	CPanel:AddControl( "TextBox", {	Label		= "Password",
									MaxLength	= "4",
									Command		= "keypad_adv_password" })

	CPanel:AddControl( "CheckBox", {Label 		= "Secure Mode",
									Description	= "The password on the display will be hidden.",
									Command		= "keypad_wire_secure" } )

	CPanel:AddControl( "CheckBox", {Label 		= "Weld Keypad",
									Description	= "The Keypad will be welded onto any surface.",
									Command		= "keypad_wire_weld" } )

	CPanel:AddControl( "CheckBox", {Label 		= "Freeze Keypad",
									Description	= "The Keypad will be frozen but not welded.",
									Command		= "keypad_wire_freeze" } )

	CPanel:AddControl( "Header", {	Text = "Settings when Granted", Description = "Settings to be used when access is granted." }  )

	CPanel:AddControl( "Button", {	Label 		= "Reset Settings",
									Text		= "Reset",
									Command		= "keypad_wire_reset 1" } )

	CPanel:AddControl( "CheckBox", {Label 		= "Toggle Value",
									Description	= "Hold length will be ignored if this is used.",
									Command		= "keypad_wire_toggle1" } )

	CPanel:AddControl( "Slider", {	Label 	= "Value On",
									Type	= "Integer",
									Min		= "-10",
									Max		= "10",
									Command	= "keypad_wire_valueon1" } )

	CPanel:AddControl( "Slider", {	Label 	= "Value Off",
									Type	= "Integer",
									Min		= "-10",
									Max		= "10",
									Command	= "keypad_wire_valueoff1" } )

	CPanel:AddControl( "Slider", {	Label 	= "Value Hold Length",
									Type	= "Float",
									Min		= "0.1",
									Max		= "10",
									Command	= "keypad_wire_length1" } )

	CPanel:AddControl( "Slider", {	Label 	= "Value Initial Press Delay",
									Type	= "Float",
									Min		= "0",
									Max		= "10",
									Command	= "keypad_wire_initdelay1" } )

	CPanel:AddControl( "Slider", {	Label 	= "Value Press Delay",
									Type	= "Float",
									Min		= "0",
									Max		= "10",
									Command	= "keypad_wire_delay1" } )

	CPanel:AddControl( "Slider", {	Label 	= "Value Add Repeats",
									Type	= "Integer",
									Min		= "0",
									Max		= "5",
									Command	= "keypad_wire_repeats1" } )

	CPanel:AddControl( "Header", {	Text = "Settings when Denied", Description = "Settings to be used when access is denied." }  )

	CPanel:AddControl( "Button", {	Label 		= "Reset Settings",
									Text		= "Reset",
									Command		= "keypad_wire_reset 2" } )

	CPanel:AddControl( "CheckBox", {Label 		= "Toggle Value",
									Description	= "Hold length will be ignored if this is used.",
									Command		= "keypad_wire_toggle2" } )

	CPanel:AddControl( "Slider", {	Label 	= "Value On",
									Type	= "Integer",
									Min		= "-10",
									Max		= "10",
									Command	= "keypad_wire_valueon2" } )

	CPanel:AddControl( "Slider", {	Label 	= "Value Off",
									Type	= "Integer",
									Min		= "-10",
									Max		= "10",
									Command	= "keypad_wire_valueoff2" } )

	CPanel:AddControl( "Slider", {	Label 	= "Value Hold Length",
									Type	= "Float",
									Min		= "0.1",
									Max		= "10",
									Command	= "keypad_wire_length2" } )

	CPanel:AddControl( "Slider", {	Label 	= "Value Initial Press Delay",
									Type	= "Float",
									Min		= "0",
									Max		= "10",
									Command	= "keypad_wire_initdelay2" } )

	CPanel:AddControl( "Slider", {	Label 	= "Value Press Delay",
									Type	= "Float",
									Min		= "0",
									Max		= "10",
									Command	= "keypad_wire_delay2" } )

	CPanel:AddControl( "Slider", {	Label 	= "Value Add Repeats",
									Type	= "Integer",
									Min		= "0",
									Max		= "5",
									Command	= "keypad_wire_repeats2" } )
end
