-- Just a list of valid fonts.
--
-- Comment out any you dont want to be usable, and
-- the default font will be used where the commented
-- out font is requested.
--
-- Moggie100

print("[II]", "Loading font list...")

H2Fonts = {}

H2Fonts["Default"]			= "Default"
H2Fonts["DebugFixed"]			= "DebugFixed"
H2Fonts["DebugFixedSmall"]		= "DebugFixedSmall"
H2Fonts["DefaultFixedOutline"]		= "DefaultFixedOutline"
H2Fonts["MenuItem"]			= "MenuItem"
H2Fonts["TabLarge"]			= "TabLarge"
H2Fonts["DefaultBold"]			= "DefaultBold"
H2Fonts["DefaultUnderline"]		= "DefaultUnderline"
H2Fonts["DefaultSmall"]			= "DefaultSmall"
H2Fonts["DefaultSmallDropShadow"]	= "DefaultSmallDropShadow"
H2Fonts["DefaultVerySmall"]		= "DefaultVerySmall"
H2Fonts["DefaultLarge"]			= "DefaultLarge"
H2Fonts["UiBold"]			= "UiBold"
H2Fonts["MenuLarge"]			= "MenuLarge"
H2Fonts["ConsoleText"]			= "ConsoleText"
H2Fonts["Marlett"]			= "Marlett"
H2Fonts["Trebuchet18"]			= "Trebuchet18"
H2Fonts["Trebuchet19"]			= "Trebuchet19"
H2Fonts["Trebuchet20"]			= "Trebuchet20"
H2Fonts["Trebuchet22"]			= "Trebuchet22"
H2Fonts["Trebuchet24"]			= "Trebuchet24"
H2Fonts["HUDNumber"]			= "HUDNumber"
H2Fonts["HUDNumber1"]			= "HUDNumber1"
H2Fonts["HUDNumber2"]			= "HUDNumber2"
H2Fonts["HUDNumber3"]			= "HUDNumber3"
H2Fonts["HUDNumber4"]			= "HUDNumber4"
H2Fonts["HUDNumber5"]			= "HUDNumber5"
H2Fonts["HudHintTextLarge"]		= "HudHintTextLarge"
H2Fonts["HudHintTextSmall"]		= "HudHintTextSmall"
H2Fonts["CenterPrintText"]		= "CenterPrintText"
H2Fonts["HudSelectionText"]		= "HudSelectionText"
H2Fonts["DefaultFixed"]			= "DefaultFixed"
H2Fonts["DefaultFixedDropShadow"]	= "DefaultFixedDropShadow"
H2Fonts["CloseCaption_Normal"]		= "CloseCaption_Normal"
H2Fonts["CloseCaption_Bold"]		= "CloseCaption_Bold"
H2Fonts["CloseCaption_BoldItalic"]	= "CloseCaption_BoldItalic"
H2Fonts["TitleFont"]			= "TitleFont"
H2Fonts["TitleFont2"]			= "TitleFont2"
H2Fonts["ChatFont"]			= "ChatFont"
H2Fonts["TargetID"]			= "TargetID"
H2Fonts["TargetIDSmall"]		= "TargetIDSmall"
H2Fonts["HL2MPTypeDeath"]		= "HL2MPTypeDeath"
H2Fonts["BudgetLabel"]			= "BugetLabel"
H2Fonts["ScoreboardText"]		= "ScoreboardText"

-- Aliases, for ease of use... subject to change.
--
-- Also, self-referential, so could cause issues if elements do not exist, hence the 'or Default' part.

H2Fonts["Bold"]				= H2Fonts["DefaultBold"]			or "Default"
H2Fonts["Underline"]		= H2Fonts["DefaultUnderline"]		or "Default"
H2Fonts["Small"]			= H2Fonts["DefaultSmall"]			or "Default"
H2Fonts["SmallShadowed"]	= H2Fonts["DefaultSmallDropShadow"]	or "Default"
H2Fonts["VerySmall"]		= H2Fonts["DefaultVerySmall"]		or "Default"
H2Fonts["Large"]			= H2Fonts["DefaultLarge"]			or "Default"
H2Fonts["Console"]			= H2Fonts["ConsoleText"]			or "Default"
H2Fonts["LargeHint"]		= H2Fonts["HudHintTextLarge"]		or "Default"
H2Fonts["SmallHint"]		= H2Fonts["HudHintTextSmall"]		or "Default"
H2Fonts["Selected"]			= H2Fonts["HudSelectionText"]		or "Default"
H2Fonts["Fixed"]			= H2Fonts["DefaultFixed"]			or "Default"
H2Fonts["FixedShadowed"]	= H2Fonts["DefaultFixedDropShadow"]	or "Default"
H2Fonts["Title"]			= H2Fonts["TitleFont"]				or "Default"
H2Fonts["Title2"]			= H2Fonts["TitleFont2"]				or "Default"
H2Fonts["Chat"]				= H2Fonts["ChatFont"]				or "Default"

print( "[II]", "Loaded fonts!" )
