#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <smart-menu>

#pragma newdecls required

#include <jb_lastrequest>

int g_iAirAccelerate, g_iGravity;
float g_flStart[3];

public void JB_OnPluginReady() {
	JB_CreateLastRequest("Combat de cut-slide", 	JB_SELECT_CT_UNTIL_DEAD|JB_BEACON, DV_CAN_Always, DV_Start, DV_Stop);
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
		
		g_iAirAccelerate = GetConVarInt(FindConVar("sv_airaccelerate"));
		g_iGravity = GetConVarInt(FindConVar("sv_gravity"));
		ServerCommand("sv_airaccelerate 1000;sv_gravity 0");	
		
		int target = menu.GetCell("target");
		int hp = StringToInt(options);
		
		Entity_SetCollisionGroup(client, COLLISION_GROUP_DEBRIS_TRIGGER);
		Entity_SetCollisionGroup(target, COLLISION_GROUP_DEBRIS_TRIGGER);
		
		SetEntityHealth(client, hp);
		SetEntityHealth(target, hp);
		
		DV_StripWeapon(client);
		DV_StripWeapon(target);
		
		GivePlayerItem(client, "weapon_knife");
		GivePlayerItem(target, "weapon_knife");
		
		SetEntProp(client, Prop_Data, "m_takedamage", 0);
		SetEntProp(target, Prop_Data, "m_takedamage", 0);
		
		CreateTimer(5.0, TIMER_DisableGodmod, client);
		CreateTimer(5.0, TIMER_DisableGodmod, target);
		
		float vel[3];
		GetClientAbsOrigin(client, g_flStart);
		vel[2] = 800.0;
		
		if( GetEntityFlags(client) & FL_ONGROUND )
			SetEntityFlags(client, GetEntityFlags(client) & ~FL_ONGROUND);
		if( GetEntityFlags(target) & FL_ONGROUND )
			SetEntityFlags(target, GetEntityFlags(target) & ~FL_ONGROUND);
		
		TeleportEntity(client, g_flStart, NULL_VECTOR, vel);
		TeleportEntity(target, g_flStart, NULL_VECTOR, vel);
		
		PrintHintTextToAll("Début du combat dans 5 secondes");
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
	return;
}
public Action TIMER_DisableGodmod(Handle timer, any client) {
	SetEntProp(client, Prop_Data, "m_takedamage", 2);
	PrintHintTextToAll("FIGHT!");
}
public void DV_Stop(int client, int target) {
	ServerCommand("sv_airaccelerate %d;sv_gravity %d", g_iAirAccelerate, g_iGravity);
	
	if( client > 0 ) {
		Entity_SetCollisionGroup(client, COLLISION_GROUP_PLAYER);
		TeleportEntity(client, g_flStart, NULL_VECTOR, NULL_VECTOR);
	}
	if( target > 0 ) {
		Entity_SetCollisionGroup(target, COLLISION_GROUP_PLAYER);
		TeleportEntity(target, g_flStart, NULL_VECTOR, NULL_VECTOR);
	}
}
