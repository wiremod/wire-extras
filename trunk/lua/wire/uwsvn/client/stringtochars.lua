//-----------------------------------------------------------------------------
// Name: CC_StringToChars
// Desc: Converts a string or a single character into the appropriate character
//       codes, can output as a list of codes or a packet for the E-Gate.
//-----------------------------------------------------------------------------
local function CC_StringToChars (player, command, args)
    local adj = 0
    local out = "%s"
    
    // Output usage
    if (table.getn (args) == 0) then
        Msg ("USAGE: stringtochars [PACKET] \"string\"\n  Use PACKET to output in expression gate packet form.\n")
        return
    end
    
    // Select output mode
    if (string.upper (args[1]) == "PACKET") then
        adj = 1
        out = "send(%s)"
    end
    
    // Loop through the arguments
    for i = 1 + adj, table.getn (args) do
        local fmt   = ""
        local chars = { string.byte (args[i], 1, string.len (args[i])) }
        for j = 1, table.getn (chars) do
            if (string.len (fmt) > 0) then
                fmt = fmt .. ", "
            end
            fmt = fmt .. tostring (chars[j])
        end
        Msg (string.format ("'%s' = %s\n", args[i], string.format (out, fmt)))
    end
end
concommand.Add ('stringtochars', CC_StringToChars)

