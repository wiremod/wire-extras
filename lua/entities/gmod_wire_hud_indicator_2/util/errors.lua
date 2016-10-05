
function HMLError( s, displayTime )
	displayTime = displayTime or 7
	if( CLIENT ) then
		GAMEMODE:AddNotify("[EE] " .. s, NOTIFY_ERROR, displayTime)
		if( HUD_System.NextCheckTime ) then HUD_System.NextCheckTime = HUD_System.NextCheckTime + 3 end
	end
	Msg("[EE] " .. s .. "\n")
end

function HMLWarning( s )
	displayTime = displayTime or 7
	if( CLIENT ) then
		GAMEMODE:AddNotify("[WW] " .. s, NOTIFY_HINT, displayTime)
		if( HUD_System.NextCheckTime ) then HUD_System.NextCheckTime = HUD_System.NextCheckTime + 3 end
	end
	Msg("[WW] " .. s .. "\n")
end

function HMLMessage( s )
	displayTime = displayTime or 7
	if( CLIENT ) then
		GAMEMODE:AddNotify("[II] " .. s, NOTIFY_GENERIC, displayTime)
	end
	Msg("[II] " .. s .. "\n")
end
