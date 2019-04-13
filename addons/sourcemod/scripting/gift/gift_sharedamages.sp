#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#include <csgocolors>
#include <gift>
#include <gang>

#pragma newdecls required
#define MAX_ENTITIES 2048

bool g_bHasGift[65];
int g_iOwner[MAX_ENTITIES+1];
int g_iGift = -1;

public Plugin myinfo = {
	name = "Share damages",
	author = "KoSSoLaX",
	description = "Share damages with teamates",
	version = "1.0.0",
	url = "zaretti.be"
};

public void OnPluginStart() {
	HookEvent("round_start", 		OnRoundStart, 			EventHookMode_Post);
	for (int i = 1; i <= MaxClients; i++)
		if( IsClientInGame(i) )
			OnClientPostAdminCheck(i);
}
public Action OnRoundStart(Handle ev, const char[] name, bool dontBroadcast) {
	for (int i = 0; i < MaxClients; i++)
		g_bHasGift[i] = false;
}

public void Gift_OnGiftStart() {
	g_iGift = Gift_RegisterNewGift("ShareDamages", "ShareDamages", true, true, 100.0, -1, ADMFLAG_CUSTOM1|ADMFLAG_ROOT);
}
public Action Gift_OnRandomGift(int client, int gift) {
	if(gift != g_iGift)
		return Plugin_Handled;
	
	if( Gang_GetClientGang(client) == GangNothing ) {
		Gift_RemoveClientGift(client);
		Gift_ForceRandomGift(client);
		return Plugin_Stop;
	}
	
	
	g_bHasGift[client] = true;
	CPrintToChat(client, "{lightgreen}%s {green}Vous partagez vos dégats avec vos mates!", PREFIX);

	return Plugin_Handled;
}
public void OnClientPostAdminCheck(int client) {
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}
public void OnEntityCreated(int entity, const char[] classname) {
	if( entity >= 0 && entity < MAX_ENTITIES )
		g_iOwner[entity] = 0;
}
public void OnEntityDestroyed(int entity) {
	if( entity >= 0 && entity < MAX_ENTITIES )
		g_iOwner[entity] = 0;
}
public Action OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3]) {
	
	if( attacker > 0 && attacker < MaxClients && g_bHasGift[victim] && damage > 0.0 ) {
		GangList gang = Gang_GetClientGang(victim);
		if( gang == GangNothing )
			return Plugin_Continue;
		if( damage > 500.0 )
			return Plugin_Continue;
		
		int cpt = 0;
		for (int i = 1; i < MaxClients; i++) {
			if( !IsClientInGame(i) || !IsPlayerAlive(i) )
				continue;
			if( Gang_GetClientGang(i) == gang )
				i++;
		}
		
		damage /= float(cpt);
		
		for (int i = 1; i < MaxClients; i++) {
			if( !IsClientInGame(i) || !IsPlayerAlive(i) )
				continue;
			if( Gang_GetClientGang(i) == gang )
				i++;
			
			SDKHooks_TakeDamage(i, inflictor, attacker, damage, damagetype, weapon, damageForce, damagePosition);
		}
		
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
