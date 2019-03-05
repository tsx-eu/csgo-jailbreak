#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
//#include <gift>

#pragma newdecls required

int g_iGift = -1;
int g_iRamboCount[65];

public Plugin myinfo = {
	name = "Gift: RAMBO",
	author = "KoSSoLaX",
	description = "Ajoute beaucoup de munitions",
	version = "1.0.0",
	url = "zaretti.be"
};
public void OnPluginStart() {
	HookEvent("player_spawn", 		OnPlayerSpawn, 			EventHookMode_Pre);
	HookEvent("player_death", 		OnPlayerDeath, 			EventHookMode_Pre);
	HookEvent("round_start", 		OnRoundStart, 			EventHookMode_Post);
}


public void OnThink(int client) {
	static bool previous[65];
	
	if( g_iRamboCount[client] == 0 ) {
		SDKUnhook(client, SDKHook_Think, OnThink);
		return;
	}
	
	int wpnid = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	bool reloading = view_as<bool>(GetEntProp(wpnid, Prop_Data, "m_bInReload"));
	
	if( !reloading && previous[client] ) {
		SetEntProp(wpnid, Prop_Send, "m_iClip1", 200);
		g_iRamboCount[client]--;
	}
	
	previous[client] = reloading;
}
public void OnReload(int client) {
	int wpnid = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	SetEntProp(wpnid, Prop_Send, "m_iClip1", 200);
	g_iRamboCount[client]--;
}

public Action OnPlayerSpawn(Handle ev, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(ev, "userid"));
	g_iRamboCount[client] = 2;
	
	SDKHook(client, SDKHook_Think, OnThink);
	OnReload(client);
}
public Action OnRoundStart(Handle ev, const char[] name, bool dontBroadcast) {
	for (int i = 0; i < MaxClients; i++)
		g_iRamboCount[i] = 0;
}
public Action OnPlayerDeath(Handle ev, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(ev, "userid"));
	g_iRamboCount[client] = 0;
}
