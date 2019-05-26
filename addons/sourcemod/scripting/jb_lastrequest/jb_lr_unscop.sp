#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#include <smart-menu>

#pragma newdecls required

#include <jb_lastrequest>

int g_iClient, g_iTarget, g_iWpnClient, g_iWpnTarget;


public void JB_OnPluginReady() {
	JB_CreateLastRequest("Unscope", 	JB_SELECT_CT_UNTIL_DEAD|JB_BEACON, DV_CAN_Always, DV_Start, DV_Stop);	
}
public void DV_Start(int client, int target) {
	SmartMenu menu = new SmartMenu(selectWeapon);
	menu.SetTitle("Avec quelle arme voulez-vous faire la DV?\n");
	menu.SetCell("target", target);
	
	menu.AddItem("weapon_awp", 		"AWP");
	menu.AddItem("weapon_ssg08", 	"Scout");
	menu.AddItem("weapon_g3sg1", 	"Autonoob");	
	
	menu.ExitButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
}
public int selectWeapon(SmartMenu menu, MenuAction action, int client, int params) {
	static char options[64];
	if( action == MenuAction_Select ) {
		menu.GetItem(params, options, sizeof(options));
		int target = menu.GetCell("target");
		
		DV_StripWeapon(client);
		DV_StripWeapon(target);
		
		g_iWpnClient = GivePlayerItem(client, options);
		g_iWpnTarget = GivePlayerItem(target, options);
		
		g_iClient = client;
		g_iTarget = target;
	}
	else if( action == MenuAction_Cancel && params == MenuCancel_Interrupted ) {
		JB_DisplayMenu(DV_Start, client, menu.GetCell("target"));
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
	return;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &wep) {
	if( (client == g_iTarget || client == g_iClient) ) {
		float time = GetGameTime();
		
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		
		if( (weapon == g_iWpnClient || weapon == g_iWpnTarget) ) {
			
			int zoom = GetEntProp(weapon, Prop_Send, "m_zoomLevel");
			if( zoom > 0 )
				SetEntProp(weapon, Prop_Send, "m_zoomLevel", 0);
			
			SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", time + 1.0);
			
			if( buttons & IN_ATTACK2 ) {
				buttons = buttons & ~IN_ATTACK2;
				return Plugin_Changed;
			}
		}
	}
	
	return Plugin_Continue;
}

public void DV_Stop(int client, int target) {
	CloseMenu(client);
	g_iClient = g_iTarget = -1;
}
