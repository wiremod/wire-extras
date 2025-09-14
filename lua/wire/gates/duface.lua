//-----------------------------------------------------------------------------
// DuFace's Wire Gates
// -------------------
//
// Adds vector and entity based gates. Common to all gate sections are the
// following:
//
//   * Multiplexer/Demultiplexer
//   * Latch/D-latch
//   * Equal/Inequal/Less-than/Greater-than (where appropriate)
//
//
// Vector Gates
// ------------
//
//   * Add -- removed
//   * Subtract -- removed
//   * Negate -- removed
//   * Multiply/Divide by constant -- removed
//   * Dot/Cross Product -- removed
//   * Yaw/Pitch -- removed
//   * Yaw/Pitch (Radian) -- removed
//   * Magnitude -- removed
//   * Conversion To/From -- removed
//   * Normalise -- removed
//   * Identity -- removed
//   * Random (really needed?) -- removed
//   * Component Derivative -- removed
//   * Component Integral -- removed
//
//
// Entity Gates
// ------------
//
//   * Activator
//   * Owner -- removed
//   * Identity
//   * Name -- removed
//   * Position -- removed
//   * Colour -- removed
//   * EntId -- removed
//   * Class -- removed
//   * Parent
//   * Null
//   * Velocity -- removed
//   * Forward/Right/Up vectors -- removed
//   * Max Health/Health
//   * Model -- removed
//   * Skin/Skin Count
//   * IsPlayer -- removed
//   * IsConstrained
//   * IsInWorld -- removed
//   * IsNPC -- removed
//   * IsOnFire -- removed
//   * IsOnGround -- removed
//   * IsPlayerHolding -- removed
//   * IsVehicle -- removed
//   * IsWeapon -- removed
//   * Can See
//
//
// Player Gates
// ------------
//
// Still strictly entity gates, but will output nil or zero (whichever is more
// appropriate) if the input entity is not a player.
//
//   * Alive
//   * Armour
//   * Chat Print
//   * Crouching
//   * Death/Kill Count
//   * Aim Vector -- removed
//   * InVehicle -- removed
//   * SteamID -- removed
//   * Team ID/Name
//   * Seconds Connected -- removed
//   * IsLockedOnto
//
//
// Thats all I can think of for the time being. If you can think of anything
// you'd like added then either PM me or start a thread on the Wiremod forums.
// You could leave a message on the FP forums if you wanted but I probably wont
// read it. I tend to lurk moar at Wiremod.com ;-)
//-----------------------------------------------------------------------------



//-----------------------------------------------------------------------------
// Controlling convars
//-----------------------------------------------------------------------------

// Behaviour of chatprint gate is to be controlled to prevent exploitation
// by mingebags:
//   0 - Gate completely disabled (still spawns, just won't do anything)
//   1 - Can only act on owning player (entity input ignored)
//   2 - Full operation allowed
//CreateConVar ("sv_wiregates_chatprint_act", "1", FCVAR_ARCHIVE)


//-----------------------------------------------------------------------------
// Entity Gates
//-----------------------------------------------------------------------------

GateActions("Entity")

// Activator (TODO... maybe)
// Identity
GateActions["entity_ident"] = {
	name = "Identity",
	inputs = { "A" },
	inputtypes = { "ENTITY" },
	outputtypes = { "ENTITY" },
	output = function (gate, A)
		if (A and IsEntity (A) and A:IsValid ()) then return A end
		return nil
	end,
	label = function (Out, A)
		return string.format ("%s = %s", A, tostring(Out))
	end
}
// Parent
GateActions["entity_parent"] = {
	name = "Parent",
	inputs = { "A" },
	inputtypes = { "ENTITY" },
	outputtypes = { "ENTITY" },
	output = function (gate, A)
		if (A and IsEntity (A) and A:IsValid ()) then return A:GetParent () end
		return NULL
	end,
	label = function (Out, A)
		local strParent = "(none)"
		if (Out != NULL and IsEntity (Out)) then strParent = Out:GetName () end
		return string.format ("A: %s  Parent  %s", A, strParent)
	end
}

// IsConstrained
GateActions["entity_isconstrained"] = {
	name = "Is Constrained",
	inputs = { "A" },
	inputtypes = { "ENTITY" },
	timed = true,
	output = function (gate, A)
		if (A and IsEntity (A) and A:IsValid () and A:IsConstrained ()) then
			return 1
		end
		return 0
	end,
	label = function (Out, A)
		local strNot = "no"
		if (Out == 1) then strNot = "yes" end
		return string.format ("A: %s  Is Constrained: %s", A, strNot)
	end
}
// Can See
GateActions["entity_cansee"] = {
	name = "Can See",
	inputs = { "A", "B" },
	inputtypes = { "ENTITY", "ENTITY" },
	timed = true,
	output = function (gate, A, B)
		if (A and IsEntity (A) and A:IsValid () and B and IsEntity (B) and B:IsValid ()) then
			if (A:Visible (B)) then
				return 1
			end
		end
		return 0
	end,
	label = function (Out, A, B)
		local strNot = "not"
		if (Out == 1) then strNot = "" end
		return string.format ("Entity(%s) can%s see Entity(%s)", A, strNot, B)
	end
}


//-----------------------------------------------------------------------------
// Player Gates
//-----------------------------------------------------------------------------

GateActions("Player")

--[[// Chat Print
GateActions["player_printf"] = {
	name = "Chat Print",
	inputs = { "Player", "Message" },
	inputtypes = { "ENTITY", "STRING" },
	outputs = {  },
	output = function (gate, ply, msg)
		local act = GetConVarNumber ("sv_wiregates_chatprint_act")
		// Completely disabled
		if (Act == 0) then return end
		// May only work on spawning player
		if (Act == 1 and gate:GetOwner ():IsPlayer ()) then
			gate:GetOwner ():ChatPrint (msg)
			return
		end
		// Unrestricted usage
		if (Act == 2 and ply and ply:IsPlayer () and msg != "") then 
			ply:ChatPrint (msg)
		end
	end,
	label = function (Out, ply, msg)
		local act = GetConVarNumber ("sv_wiregates_chatprint_act")
		// Completely disabled
		if (act == 0) then
			return "Function Disabled!"
		end
		// Function enabled
		local _ply = nil
		if (act == 1 and gate:GetOwner ():IsPlayer ()) then
			_ply = gate:GetOwner ()
		elseif (act == 2 and ply and ply:IsPlayer ()) then 
			_ply = ply
		end
		// Include target in tooltip
		if (_ply) then
			return "Target: ".._ply:GetName ()
		else
			return "No Target"
		end
	end
}
]]

// Is Locked Onto by [at least one] Target Finder
GateActions["player_istarget"] = {
	name = "Is Locked Onto",
	inputs = { "A" },
	inputtypes = { "ENTITY" },
	timed = true,
	output = function (gate, A)
		if (IsEntity (A) and A:IsValid () and A:IsPlayer ()) then
			if (A.IsLockedOnto and A:IsLockedOnto ()) then
				return 1
			end
		end
		return 0
	end,
	label = function (Out, A)
		local strNot = "no"
		if (Out == 1) then strNot = "yes" end
		return string.format ("A: %s  In Target: %s", A, strNot)
	end
}

GateActions()
