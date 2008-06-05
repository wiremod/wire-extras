TOOL.Category		= "Construction"
TOOL.Name			= "Keypad"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.ClientConVar["secure"] = "0"
TOOL.ClientConVar["weld"] = "1"
TOOL.ClientConVar["freeze"] = "1"

TOOL.ClientConVar["keygroup1"] = "-1"
TOOL.ClientConVar["keygroup2"] = "-1"
TOOL.ClientConVar["length1"] = "0.1"
TOOL.ClientConVar["length2"] = "0.1"

cleanup.Register("keypad")

if ( CLIENT ) then

	language.Add( "Tool_keypad_name", "Keypad" )
	language.Add( "Tool_keypad_desc", "Made by: Killer HAHA (Robbis_1)" )
	language.Add( "Tool_keypad_0", "Left Click: Spawn a Keypad   Right Click: Update Keypad with settings" )

	language.Add( "Undone_keypad", "Undone Keypad" )
	language.Add( "Cleanup_keypad", "Keypads" )
	language.Add( "Cleaned_keypad", "Cleaned up all Keypads" )

end

function TOOL:SetupKeypad(Ent, Password)
	Ent:AddPassword(Password)

	Ent:SetNetworkedEntity("keypad_owner", self:GetOwner())
	Ent:SetNetworkedInt("keypad_length1", self:GetClientNumber("length1"))
	Ent:SetNetworkedInt("keypad_length2", self:GetClientNumber("length2"))

	Ent:SetNetworkedInt("keypad_keygroup1", self:GetClientNumber("keygroup1"))
	Ent:SetNetworkedInt("keypad_keygroup2", self:GetClientNumber("keygroup2"))

	Ent:SetNetworkedBool("keypad_showaccess", false)
	Ent:SetNetworkedBool("keypad_secure", util.tobool(self:GetClientNumber("secure")))
	Ent:SetNetworkedBool("keypad_simple", true)
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
	local Password = tonumber(self:GetClientNumber("adv_password"))

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
		Ply:ConCommand("keypad_length1 0.1\n")
		Ply:ConCommand("keypad_length2 0.1\n")
	end
	concommand.Add("keypad_reset", ResetSettings)
end

function TOOL.BuildCPanel( CPanel )
	CPanel:AddControl( "Header", {	Text = "#Tool_keypad_name", Description	= "#Tool_keypad_desc" }  )

	CPanel:AddControl( "TextBox", {	Label		= "Password",
									MaxLength	= "4",
									Command		= "keypad_adv_password" })

	CPanel:AddControl( "CheckBox", {Label 		= "Secure Mode",
									Description	= "The password on the display will be hidden.",
									Command		= "keypad_secure" } )

	CPanel:AddControl( "CheckBox", {Label 		= "Weld Keypad",
									Description	= "The Keypad will be welded onto any surface.",
									Command		= "keypad_weld" } )

	CPanel:AddControl( "CheckBox", {Label 		= "Freeze Keypad",
									Description	= "The Keypad will be frozen but not welded.",
									Command		= "keypad_freeze" } )

	CPanel:AddControl( "Numpad", {	Label	= "Access -Granted-", Command  = "keypad_keygroup1",
									Label2	= "Access -Denied-", Command2 = "keypad_keygroup2", ButtonSize = 22 } )

	CPanel:AddControl( "Button", {	Label 		= "Reset Settings",
									Text		= "Reset",
									Command		= "keypad_reset" } )

	CPanel:AddControl( "Slider", {	Label 	= "Keypad -Granted- Hold Length",
									Type	= "Float",
									Min		= "0.1",
									Max		= "10",
									Command	= "keypad_length1" } )

	CPanel:AddControl( "Slider", {	Label 	= "Keypad -Denied- Hold Length",
									Type	= "Float",
									Min		= "0.1",
									Max		= "10",
									Command	= "keypad_length2" } )
end
