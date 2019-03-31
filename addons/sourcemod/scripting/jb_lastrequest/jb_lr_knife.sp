#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <smart-menu>

#pragma newdecls required

#include <jb_lastrequest>

public void JB_OnPluginReady() {
	JB_CreateLastRequest("Combat de cut", 	JB_SELECT_CT_UNTIL_DEAD|JB_BEACON, DV_CAN_Always, DV_Start);
}
public void DV_Start(int client, int target) {
	SmartMenu menu = new SmartMenu(selectWeapon);
	menu.SetTitle("Combien de HP?\n");
	menu.SetCell("target", target);

	menu.AddItem("1", 	"1");
	menu.AddItem("35", 	"35");
	menu.AddItem("50", 	"50");
	menu.AddItem("75", 	"75");
	menu.AddItem("100", "100");
	menu.AddItem("200", "200");
	
	menu.ExitButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
}
public int selectWeapon(SmartMenu menu, MenuAction action, int client, int params) {
	static char options[64];
	if( action == MenuAction_Select ) {
		menu.GetItem(params, options, sizeof(options));
		int target = menu.GetCell("target");
		int hp = StringToInt(options);
		
		SetEntityHealth(client, hp);
		SetEntityHealth(target, hp);
		
		DV_StripWeapon(client);
		DV_StripWeapon(target);
		
		GivePlayerItem(client, "weapon_knife");
		GivePlayerItem(target, "weapon_knife");
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
	return;
}
