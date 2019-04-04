#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <csgocolors>
#include <smlib>
#include <smart-menu>

#pragma newdecls required

#include <jb_lastrequest>
int g_cLaser, g_wpnClient, g_wpnTarget;

int g_iClient, g_iTarget, g_iPlaying, g_iState;
int g_iLastOwner[2049];
bool g_bThrowed[MAX_PLAYERS], g_bTossed[MAX_PLAYERS];
float g_flPositions[MAX_PLAYERS][2][3], g_flTarget[3];
Handle g_hMain = INVALID_HANDLE;

public void OnPluginStart() {
	HookEvent("weapon_fire",		EventShoot,			EventHookMode_Post);
}
public void JB_OnPluginReady() {
	JB_CreateLastRequest("Lancé de deagle de précision", 	JB_SELECT_CT_UNTIL_DEAD|JB_BEACON|JB_NODAMAGE, DV_CAN_Always, DV_Start, DV_Stop);
	for (int i = 1; i <= MaxClients; i++) 
		if( IsClientInGame(i) )
			SDKHook(i, SDKHook_WeaponCanUse, OnWeaponCanUse);
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

public void DV_Start(int client, int target) {
	g_iState = 1;
	g_iClient = client;
	g_iTarget = target;
	g_flTarget[2] = 9999999.9;
	
	SDKHook(g_iClient, SDKHook_WeaponDropPost, OnWeaponDrop);
	SDKHook(g_iTarget, SDKHook_WeaponDropPost, OnWeaponDrop);
	
	g_hMain = CreateTimer(0.1, DV_TASK, _, TIMER_REPEAT);
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
			
			DV_StripWeapon(g_iClient);
			DV_StripWeapon(g_iTarget);

			g_wpnClient = EntIndexToEntRef(Client_GiveWeaponAndAmmo(g_iClient, "weapon_deagle", true, 0, 0, 0, 0));
			g_wpnTarget = EntIndexToEntRef(Client_GiveWeaponAndAmmo(g_iTarget, "weapon_deagle", true, 0, 0, 0, 0));
			
			SetEntityRenderMode(g_wpnClient, RENDER_TRANSCOLOR);
			SetEntityRenderMode(g_wpnTarget, RENDER_TRANSCOLOR);
			
			SetEntityRenderColor(g_wpnClient, 255, 0, 0, 200);
			SetEntityRenderColor(g_wpnTarget, 0, 0, 255, 200);
			
			CreateTimer(0.01, DV_DeagleThrow_Task, g_wpnClient );
			CreateTimer(0.01, DV_DeagleThrow_Task, g_wpnTarget );
			
			for (int i = 1; i < MaxClients; i++)
				g_bThrowed[i] = g_bTossed[i] = false;
			
			g_iPlaying = 2;
		}
	}
}
public Action OnWeaponDrop(int client, int wpnid) {
	if( wpnid == EntRefToEntIndex(g_wpnClient) || wpnid == EntRefToEntIndex(g_wpnTarget) ) {
		GetClientEyePosition(client, g_flPositions[client][0]);
		g_bThrowed[client] = true;
		g_iLastOwner[wpnid] = client;
	}
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
		
		if( GetVectorDistance(vecStart, g_flPositions[ client ][1]) <= 0.0) {
			Entity_GetAbsOrigin(entity, vecEnd);
			vecEnd[2] += 64.0;
		
			TE_SetupBeamPoints(vecStart, vecEnd, g_cLaser, g_cLaser, 0, 30, 60.0, 0.5, 0.5, 1, 0.0, color, 0);
			TE_SendToAll();
			TE_SetupBeamRingPoint(vecStart, 1.0, 32.0, g_cLaser, g_cLaser, 0, 30, 1.0, 0.5, 0.0, color, 0, 0);
			TE_SendToAll();
			
			g_bTossed[client] = true;
			DV_CheckWinner();
			
			return Plugin_Handled;
		}
		
		Entity_GetAbsOrigin(entity, g_flPositions[ client ][1]);
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
		
		float tmp = GetVectorDistance(g_flPositions[i][1], g_flTarget);
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
	g_iPlaying = 0;
	g_iState = 0;
	
	AcceptEntityInput(g_wpnClient, "Kill");
	AcceptEntityInput(g_wpnTarget, "Kill");
	
	KillTimer(g_hMain);
	g_hMain = null;
	
	if( client )
		SDKUnhook(client, SDKHook_WeaponDropPost, OnWeaponDrop);
	if( target )
		SDKUnhook(target, SDKHook_WeaponDropPost, OnWeaponDrop);
}