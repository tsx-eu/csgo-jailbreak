#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#include <smart-menu>
#include <emitsoundany>

#pragma newdecls required

#include <jb_lastrequest>

public void JB_OnPluginReady() {
	JB_CreateLastRequest("Duel d'armes", 	JB_SELECT_CT_UNTIL_DEAD|JB_BEACON, DV_CAN_Always, DV_Start, DV_Stop);	
}
public void DV_Start(int client, int target) {
	SmartMenu menu = new SmartMenu(selectWeapon);
	menu.SetTitle("Avec quelle arme voulez-vous faire la DV?\n");
	menu.SetCell("target", target);
	
	menu.AddItem("weapon_awp", 		"AWP");
	menu.AddItem("weapon_ak47", 	"AK47");
	menu.AddItem("weapon_m4a1", 	"M4A1");	
	menu.AddItem("weapon_deagle", 	"Deagle");	
	
	menu.ExitButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
	
	JB_ShowHUDMessage("Vous devez vous affronter en duel avec une arme.﻿﻿");
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
		
		GivePlayerItem(client, options);
		GivePlayerItem(target, options);
		
		SetEntProp(client, Prop_Data, "m_takedamage", 0);
		SetEntProp(target, Prop_Data, "m_takedamage", 0);
		
		CreateTimer(5.0, TIMER_DisableGodmod, client);
		CreateTimer(5.0, TIMER_DisableGodmod, target);
		
		PrintHintTextToAll("Début du combat dans 5 secondes");
	}
	else if( action == MenuAction_Cancel && params == MenuCancel_Interrupted ) {
		JB_DisplayMenu(DV_Start, client, menu.GetCell("target"));
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
	return;
}

public void DV_Stop(int client, int target) {
	CloseMenu(client);
}
public Action TIMER_DisableGodmod(Handle timer, any client) {
	SetEntProp(client, Prop_Data, "m_takedamage", 2);
	EmitSoundToAllAny("rsc/jailbreak/taunt_bell.wav", client);
}