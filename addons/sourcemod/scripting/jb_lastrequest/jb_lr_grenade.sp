#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <smart-menu>

#pragma newdecls required

#include <jb_lastrequest>

Handle g_hMain = INVALID_HANDLE;

public void JB_OnPluginReady() {
	JB_CreateLastRequest("Combat de grenade", 	JB_SELECT_CT_UNTIL_DEAD|JB_BEACON, DV_CAN_Always, DV_Start, DV_Stop);
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
		
		GivePlayerItem(client, "weapon_hegrenade");
		GivePlayerItem(target, "weapon_hegrenade");	
		
		Handle dp;
		g_hMain = CreateDataTimer(1.0, EventSecondElapsed, dp, TIMER_REPEAT);
		WritePackCell(dp, client);
		WritePackCell(dp, target);
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
	return;
}

public Action EventSecondElapsed(Handle timer, Handle dp) {
	ResetPack(dp);
	int client = ReadPackCell(dp);
	int target = ReadPackCell(dp);
	
	if( Client_GetWeapon(client, "weapon_hegrenade") == -1 )
		GivePlayerItem(client, "weapon_hegrenade");
	if( Client_GetWeapon(target, "weapon_hegrenade") == -1 )
		GivePlayerItem(target, "weapon_hegrenade");
}

public void DV_Stop(int client, int target) {
	KillTimer(g_hMain);
	g_hMain = null;
}