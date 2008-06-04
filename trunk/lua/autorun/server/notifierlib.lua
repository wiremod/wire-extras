NotifierDelay = 3 //3 second delay
NotifierSilent = 0 //Not silent
NotifierConsole = 0
function NotifierSetDelay(pl,cmd,args)
	if !(NotifierCheckAdmin(pl)) then return false end
	NotifierDelay =  tonumber(args[1]) or 3
end
concommand.Add("wire_notifier_delay",NotifierSetDelay)
function NotifierSetSilent(pl,cmd,args)
	if !(NotifierCheckAdmin(pl)) then return false end
	NotifierSilent =  tonumber(args[1]) or 0
end
concommand.Add("wire_notifier_silent",NotifierSetSilent)
function NotifierSetConsole(pl,cmd,args)
	if !(NotifierCheckAdmin(pl)) then return false end
	NotifierConsole = tonumber(args[1]) or 1
end
concommand.Add("wire_notifier_console",NotifierSetConsole)
function NotifierCheckAdmin(pl)
	if (pl:IsAdmin() || pl:IsSuperAdmin()) then return true end
	return false
end
