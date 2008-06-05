TOOL.Category		= "Construction"
TOOL.Name			= "Keypad - Advanced"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.ClientConVar["secure"] = "0"
TOOL.ClientConVar["weld"] = "1"
TOOL.ClientConVar["freeze"] = "1"

TOOL.ClientConVar["password"] = ""
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


if ( CLIENT ) then

	language.Add( "Tool_keypad_adv_name", "Keypad - Advanced" )
	language.Add( "Tool_keypad_adv_desc", "Made by: Killer HAHA (Robbis_1)" )
	language.Add( "Tool_keypad_adv_0", "Left Click: Spawn a Keypad   Right Click: Update Keypad with settings" )

end

function TOOL:SetupKeypad(Ent, Password)
	Ent:AddPassword(Password)

	Ent:SetNetworkedEntity("keypad_owner", self:GetOwner())
	Ent:SetNetworkedInt("keypad_length1", self:GetClientNumber("length1"))
	Ent:SetNetworkedInt("keypad_length2", self:GetClientNumber("length2"))

	Ent:SetNetworkedInt("keypad_keygroup1", self:GetClientNumber("keygroup1"))
	Ent:SetNetworkedInt("keypad_keygroup2", self:GetClientNumber("keygroup2"))

	Ent:SetNetworkedInt("keypad_delay1", self:GetClientNumber("delay1"))
	Ent:SetNetworkedInt("keypad_delay2", self:GetClientNumber("delay2"))

	Ent:SetNetworkedInt("keypad_initdelay1", self:GetClientNumber("initdelay1"))
	Ent:SetNetworkedInt("keypad_initdelay2", self:GetClientNumber("initdelay2"))

	Ent:SetNetworkedInt("keypad_repeats1", self:GetClientNumber("repeat1"))
	Ent:SetNetworkedInt("keypad_repeats2", self:GetClientNumber("repeats2"))

	Ent:SetNetworkedBool("keypad_showaccess", false)
	Ent:SetNetworkedBool("keypad_secure", util.tobool(self:GetClientNumber("secure")))
	Ent:SetNetworkedBool("keypad_simple", false)
end

function TOOL:RightClick(tr)
	if (tr.Entity:GetClass() == "player") then return false end
	if (CLIENT) then return true end

	local Ply = self:GetOwner()
	local Password = tonumber(Ply:GetInfo("keypad_adv_password"))

	local SpawnPos = tr.HitPos + tr.HitNormal
	local TraceEnt = tr.Entity

	if (Password == nil) or (string.len(tostring(Password)) > 4) or (string.find(tostring(Password), "0")) then
		Ply:PrintMessage(3, "Invalid password!")
		return false
	end

	if (TraceEnt:IsValid() and TraceEnt:GetClass() == "sent_keypad" and TraceEnt:GetNetworkedEntity("keypad_owner") == Ply ) then
		self:SetupKeypad(TraceEnt, Password)
		return true
	end
end

function TOOL:LeftClick(tr)
	if (tr.Entity:GetClass() == "player") then return false end
	if (CLIENT) then return true end

	local Ply = self:GetOwner()
	local Password = self:GetClientNumber("password")

	local SpawnPos = tr.HitPos + tr.HitNormal
	local TraceEnt = tr.Entity

	if (Password == nil) or (string.len(tostring(Password)) > 4) or (string.find(tostring(Password), "0")) then
		Ply:PrintMessage(3, "Invalid password!")
		return false
	end

	local Keypad = ents.Create("sent_keypad")
	Keypad:SetPos(SpawnPos)
	Keypad:SetAngles(tr.HitNormal:Angle())
	Keypad:Spawn()
	Keypad:SetAngles(tr.HitNormal:Angle())
	Keypad:Activate()

	self:SetupKeypad(Keypad, Password)

	undo.Create("Keypad")

	if (util.tobool(self:GetClientNumber("freeze"))) then
		Keypad:GetPhysicsObject():EnableMotion(false)
	end

	if (util.tobool(self:GetClientNumber("weld"))) and not (TraceEnt:GetClass() == "player") and not (TraceEnt:GetClass() == "sent_keypad") and not (TraceEnt:GetClass() == "sent_keypad_wire") then
		local weld = constraint.Weld(Keypad, TraceEnt, 0, tr.PhysicsBone, 0)
		TraceEnt:DeleteOnRemove(Keypad)
		TraceEnt:DeleteOnRemove(weld)
		Keypad:DeleteOnRemove(weld)

		Keypad:GetPhysicsObject():EnableCollisions(false)

		undo.AddEntity(weld)
	end

	undo.AddEntity(Keypad)
	undo.SetPlayer(Ply)
	undo.Finish()

	--Ply:AddCount( "keypads", Keypad )
	Ply:AddCleanup( "keypads", Keypad )

	return true
end

if (CLIENT) then
	local function ResetSettings(Ply, Com, Args)
		Ply:ConCommand("keypad_adv_length"..Args[1].." 0.1\n")
		Ply:ConCommand("keypad_adv_initdelay"..Args[1].." 0\n")
		Ply:ConCommand("keypad_adv_repeats"..Args[1].." 0\n")
		Ply:ConCommand("keypad_adv_delay"..Args[1].." 0\n")
	end
	concommand.Add("keypad_adv_reset", ResetSettings)
end

function TOOL.BuildCPanel( CPanel )
	CPanel:AddControl( "Header", {	Text = "#Tool_keypad_adv_name", Description	= "#Tool_keypad_adv_desc" }  )

	CPanel:AddControl( "TextBox", {	Label		= "Password",
									MaxLength	= "4",
									Command		= "keypad_adv_password" })

	CPanel:AddControl( "CheckBox", {Label 		= "Secure Mode",
									Description	= "The password on the display will be hidden.",
									Command		= "keypad_adv_secure" } )

	CPanel:AddControl( "CheckBox", {Label 		= "Weld Keypad",
									Description	= "The Keypad will be welded onto any surface.",
									Command		= "keypad_adv_weld" } )

	CPanel:AddControl( "CheckBox", {Label 		= "Freeze Keypad",
									Description	= "The Keypad will be frozen but not welded.",
									Command		= "keypad_adv_freeze" } )

	CPanel:AddControl( "Numpad", {	Label	= "Access -Granted-", Command  = "keypad_adv_keygroup1",
									Label2	= "Access -Denied-", Command2 = "keypad_adv_keygroup2", ButtonSize = 22 } )

	CPanel:AddControl( "Header", {	Text = "Settings when Granted", Description = "Settings to be used when access is granted." }  )

	CPanel:AddControl( "Button", {	Label 		= "Reset Settings",
									Text		= "Reset",
									Command		= "keypad_adv_reset 1" } )

	CPanel:AddControl( "Slider", {	Label 	= "Keypad Hold Length",
									Type	= "Float",
									Min		= "0.1",
									Max		= "10",
									Command	= "keypad_adv_length1" } )

	CPanel:AddControl( "Slider", {	Label 	= "Keypad Initial Press Delay",
									Type	= "Float",
									Min		= "0",
									Max		= "10",
									Command	= "keypad_adv_initdelay1" } )

	CPanel:AddControl( "Slider", {	Label 	= "Keypad Press Delay",
									Type	= "Float",
									Min		= "0",
									Max		= "10",
									Command	= "keypad_adv_delay1" } )

	CPanel:AddControl( "Slider", {	Label 	= "Keypad Add Repeats",
									Type	= "Integer",
									Min		= "0",
									Max		= "5",
									Command	= "keypad_adv_repeats1" } )

	CPanel:AddControl( "Header", {	Text = "Settings when Denied", Description = "Settings to be used when access is denied." }  )

	CPanel:AddControl( "Button", {	Label 		= "Reset Settings",
									Text		= "Reset",
									Command		= "keypad_adv_reset 2" } )

	CPanel:AddControl( "Slider", {	Label 	= "Keypad Hold Length",
									Type	= "Float",
									Min		= "0.1",
									Max		= "10",
									Command	= "keypad_adv_length2" } )

	CPanel:AddControl( "Slider", {	Label 	= "Keypad Initial Press Delay",
									Type	= "Float",
									Min		= "0",
									Max		= "10",
									Command	= "keypad_adv_initdelay2" } )

	CPanel:AddControl( "Slider", {	Label 	= "Keypad Press Delay",
									Type	= "Float",
									Min		= "0",
									Max		= "10",
									Command	= "keypad_adv_delay2" } )

	CPanel:AddControl( "Slider", {	Label 	= "Keypad Add Repeats",
									Type	= "Integer",
									Min		= "0",
									Max		= "5",
									Command	= "keypad_adv_repeats2" } )
end
