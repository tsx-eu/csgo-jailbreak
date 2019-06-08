#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#include <smart-menu>

#pragma newdecls required

#include <jb_lastrequest>

int g_iWeaponId = -1, g_iClient = -1, g_iTarget = -1;

public void OnPluginStart() {
	HookEvent("weapon_fire",		EventPlayerShot,			EventHookMode_Post);
}
public void JB_OnPluginReady() {
	JB_CreateLastRequest("Roulette", 	JB_SELECT_CT_UNTIL_DEAD|JB_BEACON, DV_CAN_Always, DV_Start, DV_Stop);	
}
public void DV_Start(int client, int target) {
	SmartMenu menu = new SmartMenu(selectWeapon);
	menu.SetTitle("Avec quelle arme voulez-vous faire la roulette?\n");
	menu.SetCell("target", target);
	
	menu.AddItem("weapon_deagle", "Desert Eagle");
	menu.AddItem("weapon_revolver", "Revolver");
	
	menu.ExitButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
	
	JB_ShowHUDMessage("Placez vous face à face le long d'une surface et celui qui n'a pas﻿ la balle devra l'éviter en faisait des droites gauches.");
}
public int selectWeapon(SmartMenu menu, MenuAction action, int client, int params) {
	static char options[64];
	if( action == MenuAction_Select ) {
		menu.GetItem(params, options, sizeof(options));
		int target = menu.GetCell("target");
		
		DV_StripWeapon(client);
		DV_StripWeapon(target);
		
		GivePlayerItem(client, "weapon_knife");
		GivePlayerItem(target, "weapon_knife");
		
		g_iWeaponId = GivePlayerItem( GetRandomInt(0, 1) ? client : target, options);
		g_iClient = client;
		g_iTarget = target;
		SetEntProp(g_iWeaponId, Prop_Send, "m_iClip1", 1);
		SetEntProp(g_iWeaponId, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
	}
	else if( action == MenuAction_Cancel && params == MenuCancel_Interrupted ) {
		JB_DisplayMenu(DV_Start, client, menu.GetCell("target"));
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
	return;
}
public Action EventPlayerShot(Handle ev, const char[] name, bool  bd) {
	int client = GetClientOfUserId(GetEventInt(ev, "userid"));
	if( client == g_iClient || client == g_iTarget ) {
		int wpnid = Client_GetActiveWeapon(client);
		
		if( wpnid == g_iWeaponId )
			CreateTimer(0.1, SwitchDeagleTeam, client);
	}
}

public Action SwitchDeagleTeam(Handle timer, any client) {
	int target = client == g_iClient ? g_iTarget : g_iClient;
	RemovePlayerItem(client, g_iWeaponId);
	EquipPlayerWeapon(target, g_iWeaponId);
	SetEntProp(g_iWeaponId, Prop_Send, "m_iClip1", 1);
	SetEntProp(g_iWeaponId, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
}
public void DV_Stop(int client, int target) {
	CloseMenu(client);
	g_iWeaponId = g_iClient = g_iTarget = -1;
}
