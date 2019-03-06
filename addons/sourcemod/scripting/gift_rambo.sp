#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <gift>
#include <csgocolors>

#define AMMUNITION 			200
#define CS_SLOT_PRIMARY		0

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

public void Gift_OnGiftStart() {
	g_iGift = Gift_RegisterNewGift("Rambo", "RAMBO", false, true, 100.0, -1, ADMFLAG_CUSTOM1|ADMFLAG_ROOT);
}
public void OnPluginStart() {
	HookEvent("round_start", 		OnRoundStart, 			EventHookMode_Post);
}

public Action Gift_OnRandomGift(int client, int gift) {
	if(gift != g_iGift)
		return Plugin_Handled;
	
	g_iRamboCount[client] = 3;
	CPrintToChat(client, "{lightgreen}%s {green} Vous êtes RAMBO!", PREFIX);
	
	SDKHook(client, SDKHook_PostThinkPost, OnPlayerThink);
	OnReload(client);
	
	return Plugin_Handled;
}
public void OnPlayerThink(int client) {
	static bool previous[65];
	
	if( g_iRamboCount[client] == 0 ) {
		SDKUnhook(client, SDKHook_PostThinkPost, OnPlayerThink);
		return;
	}
	
	int wpnid = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	bool reloading = view_as<bool>(GetEntProp(wpnid, Prop_Data, "m_bInReload"));
	
	if( !reloading && previous[client] ) {
		OnReload(client);
	}
	
	previous[client] = reloading;
}
public void OnReload(int client) {	
	int wpnid = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	if( wpnid != GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) )
		return;
	
	SetEntProp(wpnid, Prop_Send, "m_iClip1", AMMUNITION);
	g_iRamboCount[client]--;
	
	CPrintToChat(client, "{lightgreen}%s {green} [RAMBO] Il vous reste %d super-chargeur%s {lightgreen}!", PREFIX, g_iRamboCount[client], (g_iRamboCount[client] > 1 ? "s" : ""));
}

public Action OnRoundStart(Handle ev, const char[] name, bool dontBroadcast) {
	for (int i = 0; i < MaxClients; i++)
		g_iRamboCount[i] = 0;
}
