--	gui Panel Test entity - greenarrow

ENT.Type 			= "anim"
ENT.Base 			= "base_gui_panel"
ENT.PrintName		= "gui Panel Test adv"
ENT.Author			= "greenarrow"
ENT.Purpose			= "Try out gui Panel"

ENT.Spawnable			= true
ENT.AdminSpawnable		= true

function ENT:BuildPanel()	--this function is not a library function, it is just created in this entity to create the interface both server and clientside
	
	--guiP_ClearWidgets(self.Entity)	--clears all existing widgets on panel.
	--guiP_AddWidget(self.Entity, "myname", "widgetType", X, Y, width, height, {widget specific parameters})
	--add parameters in the {} are optional, as defaults will be used if they are ommited, all are shown here.
	--The screen is a 200 by 200 grid.

	guiP_AddWidget(self.Entity, "title", "label", 4, 4, 184, 20, {fontSize = 1, text = "Example Sent"})
	guiP_AddWidget(self.Entity, "buttona", "button", 4, 30, 44, 30, {label = "Add", fontSize = 4})
	guiP_AddWidget(self.Entity, "buttonb", "button", 52, 30, 44, 30, {label = "Clr", fontSize = 4})
	guiP_AddWidget(self.Entity, "toggle_button", "buttonToggle", 100, 30, 44, 30, {label = "Tog", fontSize = 4})
	guiP_AddWidget(self.Entity, "slider1", "sliderV", 166, 64, 30, 124, {})
	guiP_AddWidget(self.Entity, "prog1", "progressV", 140, 64, 20, 124, {})
	guiP_AddWidget(self.Entity, "list1", "list", 4, 64, 130, 100, {fontSize = 4, list = "option 1|option 2|option 3"})
	guiP_AddWidget(self.Entity, "indicator1", "indicator", 160, 30, 30, 30, {label = "I", fontSize = 4})
	guiP_AddWidget(self.Entity, "textent1", "textentry", 4, 170, 130, 30, {fontSize = 3, maxLen = 15})
	
	
	--not all widgets are shown here, others are buggy or incomplete
	
end
