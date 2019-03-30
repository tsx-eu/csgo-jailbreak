#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#include <cstrike>
#include <emitsoundany>
#include <smart-menu>

#pragma newdecls required

#include <jb_lastrequest>

int g_iWeaponId = -1;

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
}
public int selectWeapon(SmartMenu menu, MenuAction action, int client, int params) {
	static char options[64];
	if( action == MenuAction_Select ) {
		menu.GetItem(params, options, sizeof(options));
		int target = menu.GetCell("target");
		
		if( GetClientHealth(client) < 100 )
			SetEntityHealth(client, 100);
		if( GetClientHealth(target) < 100 )
			SetEntityHealth(target, 100);
		
		DV_StripWeapon(client);
		DV_StripWeapon(target);
		
		g_iWeaponId = GivePlayerItem(client, options);
		SetEntProp(g_iWeaponId, Prop_Send, "m_iClip1", 1);
		
		SDKHook(client, SDKHook_TraceAttackPost, OnTraceAttack);
		SDKHook(target, SDKHook_TraceAttackPost, OnTraceAttack);
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
	return;
}
public void OnTraceAttack(int victim, int attacker, int inflictor, float damage, int damagetype, int ammotype, int hitbox, int hitgroup) {
	if( inflictor == g_iWeaponId ) {
		RemovePlayerItem(attacker, g_iWeaponId);
		EquipPlayerWeapon(victim, g_iWeaponId);
		SetEntProp(g_iWeaponId, Prop_Send, "m_iClip1", 1);
	}
}

public void DV_Stop(int client, int target) {
	if( client > 0 )
		SDKUnhook(client, SDKHook_TraceAttackPost, OnTraceAttack);
	if( target > 0 )
		SDKUnhook(target, SDKHook_TraceAttackPost, OnTraceAttack);
}
