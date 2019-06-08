#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#include <smart-menu>

#pragma newdecls required

#include <jb_lastrequest>

bool g_bInit = false;
float g_flStart[3];
bool g_bOnce = false;
public void OnPluginStart() {
	HookEvent("player_spawn", 		EventSpawn, 		EventHookMode_Post);
}
public Action EventSpawn(Handle ev, const char[] name, bool broadcast) {
	int client = GetClientOfUserId(GetEventInt(ev, "userid"));
	int team = GetClientTeam(client);
	
	if( !g_bInit && team == CS_TEAM_CT ) {
		g_bInit = true;
		GetClientAbsOrigin(client, g_flStart);
	}
}
public void JB_OnPluginReady() {
	JB_CreateLastRequest("Rébellion", 	JB_RUN_UNTIL_ROUND_END|JB_ONLY_VIP, DV_CAN, DV_Start, DV_Stop);	
}
public void OnMapStart() {
	g_bOnce = false;
	g_bInit = false;
}
public bool DV_CAN(int client) {
	return !g_bOnce && g_bInit && DV_CAN_Min3CT(client);
}

public void DV_Start(int client) {
	g_bOnce = true;
	Client_SetArmor(client, 100);
	TeleportEntity(client, g_flStart, NULL_VECTOR, NULL_VECTOR);
	
	JB_ShowHUDMessage("Tuez tous le monde.", CS_TEAM_T);
	JB_ShowHUDMessage("Le dernier terro s'est rebellé, tuez le.﻿", CS_TEAM_CT);
}
public void DV_Stop(int client, int[] targets, int targetCount) {
	
}
