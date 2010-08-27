EGP = {}

--------------------------------------------------------
-- Include all other files
--------------------------------------------------------

function EGP:Initialize()	
	local Folder = "entities/gmod_wire_egp/lib/EGPLib/"
	local entries = file.FindInLua( Folder .. "*.lua" )
	for _, entry in ipairs( entries ) do
		if (SERVER) then
			AddCSLuaFile( Folder .. entry )
		end
		include( Folder .. entry )			
	end

end

EGP:Initialize()

local EGP = EGP

EGP.ConVars = {}
EGP.ConVars.MaxObjects = CreateConVar( "wire_egp_max_objects", 300, { FCVAR_NOTIFY, FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE } )
EGP.ConVars.MaxPerSec = CreateConVar( "wire_egp_max_umsg_per_sec", 10, { FCVAR_NOTIFY, FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE }  )

EGP.ConVars.AllowEmitter = CreateConVar( "wire_egp_allow_emitter", 1, { FCVAR_NOTIFY, FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE  }  )
EGP.ConVars.AllowHUD = CreateConVar( "wire_egp_allow_hud", 1, { FCVAR_NOTIFY, FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE  }  )
EGP.ConVars.AllowScreen = CreateConVar( "wire_egp_allow_screen", 1, { FCVAR_NOTIFY, FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE  }  )

-- If other addons want to do something with EGP, this makes sure everything has loaded first.
-- It needs to be inside an Initialize hook because if it isn't, the other addon's hook.Add may not have been run yet.
hook.Add("Initialize","EGP_Initialize",function() hook.Call("WireEGP_Initialize", {}) end)