#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <csgocolors>
#include <smlib>

#pragma newdecls required

#include <jb_lastrequest>
int g_cLaser;

int g_iPlaying, g_iState;
int g_iLastOwner[2049];
int g_iClient;
int g_iWeaponToThrow = 0;
int g_iWeapons[MAX_PLAYERS];
bool g_bThrowed[MAX_PLAYERS], g_bTossed[MAX_PLAYERS];
float g_flPositions[MAX_PLAYERS][3], g_flTarget[3];
Handle g_hMain = INVALID_HANDLE;

public void OnPluginStart() {
	HookEvent("weapon_fire",		EventShoot,			EventHookMode_Post);
	for (int i = 1; i <= MaxClients; i++) 
		if( IsClientInGame(i) )
			SDKHook(i, SDKHook_WeaponCanUse, OnWeaponCanUse);
}
public void JB_OnPluginReady() {
	JB_CreateLastRequest("Lancé de deagle de précision", 	JB_SELECT_CT_UNTIL_DEAD|JB_BEACON|JB_NODAMAGE, DV_CAN_Always, DV_Start, DV_Stop);
	
	int id = JB_CreateLastRequest("Lancé de deagle de précision", 	JB_SELECT_CT_UNTIL_DEAD|JB_BEACON|JB_NODAMAGE, DV_CAN_Cupidon, DV_StartMulti, DV_StopMulti);
	JB_SetTeamCount(id, CS_TEAM_T, 2);
	JB_SetTeamCount(id, CS_TEAM_CT, 2);
}
public void OnMapStart() {
	g_cLaser = PrecacheModel("materials/sprites/laserbeam.vmt", true);
}
public void OnEntityCreated(int entity, const char[] classname) {
	if( entity > 0 )
		g_iLastOwner[entity] = 0;
}
public void OnClientPostAdminCheck(int client) {
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
}
public Action OnWeaponCanUse(int client, int wepID) {
	if( g_iPlaying > 0 && g_iLastOwner[wepID] != 0 )
		return Plugin_Handled;
	return Plugin_Continue;
}
public void DV_StartMulti(int[] clients, int clientCount, int[] targets, int targetCount) {
	g_iState = 1;
	g_iClient = clients[0];
	g_flTarget[2] = 9999999.9;
	
	g_iWeaponToThrow = 0;
	
	JB_ShowHUDMessage("Cutez le sol pour choisir un endroit, une cible. Vous devrez lancer votre deagle le plus près du centre de la cible verte.", CS_TEAM_T);
	JB_ShowHUDMessage("Le terro choisis une cible, vous devrez lan﻿cer votre deagle le plus près du centre de la cible verte. Bonne chance !", CS_TEAM_CT);
	
	
	for (int i = 0; i < clientCount; i++) {
		int client = clients[i];
		
		DV_StripWeapon(client);
		GivePlayerItem(client, "weapon_knife");
		
		SDKHook(client, SDKHook_WeaponDrop, OnWeaponDrop);
		int wpnId = GivePlayerItem(client, "weapon_deagle");
		SetEntProp(wpnId, Prop_Send, "m_iClip1", 0);
		SetEntProp(wpnId, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
		g_iWeapons[client] = EntIndexToEntRef(wpnId);
		SetEntityRenderMode(g_iWeapons[client], RENDER_TRANSCOLOR);
		CreateTimer(0.01, DV_DeagleThrow_Task,g_iWeapons[client] );
		
		g_iWeaponToThrow++;
	}
	for (int i = 0; i < targetCount; i++) {
		int client = targets[i];
		
		DV_StripWeapon(client);
		GivePlayerItem(client, "weapon_knife");
		
		SDKHook(client, SDKHook_WeaponDrop, OnWeaponDrop);
		int wpnId = GivePlayerItem(client, "weapon_deagle");
		SetEntProp(wpnId, Prop_Send, "m_iClip1", 0);
		SetEntProp(wpnId, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
		g_iWeapons[client] = EntIndexToEntRef(wpnId);
		SetEntityRenderMode(g_iWeapons[client], RENDER_TRANSCOLOR);
		CreateTimer(0.01, DV_DeagleThrow_Task,g_iWeapons[client] );
		
		g_iWeaponToThrow++;
	}	
	
	g_hMain = CreateTimer(0.1, DV_TASK, _, TIMER_REPEAT);
}
public void DV_Start(int client, int target) {
	 int clients[1], targets[1];
	 clients[0] = client;
	 targets[0] = target;
	 DV_StartMulti(clients, 1, targets, 1);
}
public Action DV_TASK(Handle timer, Handle dp) {
	float vecEnd[3];
	vecEnd = g_flTarget;
	vecEnd[2] += 64.0;
	
	TE_SetupBeamPoints(g_flTarget, vecEnd, g_cLaser, g_cLaser, 0, 30, 1.0, 1.0, 1.0, 1, 0.0, {0, 255, 0, 200}, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(g_flTarget, 1.0, 64.0, g_cLaser, g_cLaser, 0, 30, 1.0, 1.0, 0.0, {0, 255, 0, 200}, 0, 0);
	TE_SendToAll();
}

public Action EventShoot(Handle ev, const char[] name, bool broadcast) {
	int client = GetClientOfUserId(GetEventInt(ev, "userid"));
	
	if( client == g_iClient ) {
		char wepname[32];
		GetEventString(ev, "weapon", wepname, sizeof(wepname));
		
		if( StrContains(wepname, "knife") >= 0 && g_iState == 1 ) {
			GetClientAbsOrigin(client, g_flTarget);
			g_iState = 2;
			
			for (int i = 1; i < MaxClients; i++) {
				g_bThrowed[i] = g_bTossed[i] = false;
			}
			
			g_iPlaying = 2;
		}
	}
}
public Action OnWeaponDrop(int client, int wpnid) {
	if( g_iWeapons[client] == EntIndexToEntRef(wpnid) ) {
		if(g_iState !=2) {
			return Plugin_Handled;
		}
		
		g_bThrowed[client] = true;
		g_iLastOwner[wpnid] = client;
	}
	return Plugin_Continue;
}
public Action DV_DeagleThrow_Task(Handle timer, any entity) {
	static int offset = -1;	
	entity = EntRefToEntIndex(entity);
	
	if( entity < 0 )
		return Plugin_Handled;
	
	if( offset <= 0 )
		offset = GetEntSendPropOffs(entity, "m_clrRender", true);
	
	int color[4];
	for(int i=0; i<=3; i++)
		color[i] = GetEntData(entity, offset+i, 1);
	
	TE_SetupBeamFollow(entity, g_cLaser, g_cLaser, 0.5, 0.5, 0.5, 1, color);
	TE_SendToAll();
	
	if( Weapon_GetOwner(entity) == -1 ) {
		int client = g_iLastOwner[entity];
		float vecStart[3], vecEnd[3];
		
		Entity_GetAbsOrigin(entity, vecStart);
		
		if( GetVectorDistance(vecStart, g_flPositions[ client ]) <= 0.0) {
			Entity_GetAbsOrigin(entity, vecEnd);
			vecEnd[2] += 64.0;
		
			TE_SetupBeamPoints(vecStart, vecEnd, g_cLaser, g_cLaser, 0, 30, 60.0, 0.5, 0.5, 1, 0.0, color, 0);
			TE_SendToAll();
			TE_SetupBeamRingPoint(vecStart, 1.0, 32.0, g_cLaser, g_cLaser, 0, 30, 1.0, 0.5, 0.0, color, 0, 0);
			TE_SendToAll();
			
			g_bTossed[client] = true;
			g_iWeaponToThrow--;
			if( g_iWeaponToThrow == 0 )
				DV_CheckWinner();
			
			return Plugin_Handled;
		}
		
		Entity_GetAbsOrigin(entity, g_flPositions[ client ]);
	}
	
	CreateTimer(0.01, DV_DeagleThrow_Task, EntIndexToEntRef(entity) );
	return Plugin_Handled;
}
void DV_CheckWinner() {
	float distance = 999999.9;
	int winner = -1;
	
	for (int i = 1; i < MaxClients; i++) {
		if( !g_bTossed[i] )
			continue;
		
		float tmp = GetVectorDistance(g_flPositions[i], g_flTarget);
		if( tmp < distance ) {
			winner = i;
			distance = tmp;
		}
	}
	
	for (int i = 1; i < MaxClients; i++) {
		if( !g_bTossed[i] )
			continue;
		if( i == winner )
			continue;
		ForcePlayerSuicide(i);
	}
}
public void DV_Stop(int client, int target) {
	int clients[1], targets[1];
	clients[0] = client;
	targets[0] = target;
	DV_StopMulti(clients, 1, targets, 1);
}
public void DV_StopMulti(int[] clients, int clientCount, int[] targets, int targetCount) {
	g_iPlaying = 0;
	g_iState = 0;
	
	for (int i = 0; i < MaxClients; i++) {		
		int idx = EntRefToEntIndex(g_iWeapons[i]);
		if( idx > 0 )
			AcceptEntityInput(idx, "Kill");
		
		g_iWeapons[i] = 0;
	}
	
	KillTimer(g_hMain);
	g_hMain = null;
	
	for (int i = 0; i < clientCount; i++)
		SDKUnhook(clients[i], SDKHook_WeaponDrop, OnWeaponDrop);
	for (int i = 0; i < targetCount; i++)
		SDKUnhook(targets[i], SDKHook_WeaponDrop, OnWeaponDrop);
}
