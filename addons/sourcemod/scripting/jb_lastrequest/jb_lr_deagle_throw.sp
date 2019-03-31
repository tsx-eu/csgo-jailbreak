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

int g_iClient, g_iTarget, g_iPlaying;
int g_iLastOwner[2049];
bool g_bThrowed[MAX_PLAYERS], g_bTossed[MAX_PLAYERS];
float g_flPositions[MAX_PLAYERS][5][3];

public void JB_OnPluginReady() {
	JB_CreateLastRequest("Lancé de deagle", 	JB_SELECT_CT_UNTIL_DEAD|JB_BEACON, DV_CAN_Always, DV_Start, DV_Stop);
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
	g_wpnClient = EntIndexToEntRef(Client_GiveWeaponAndAmmo(client, "weapon_deagle", true, 0, 0, 0, 0));
	g_wpnTarget = EntIndexToEntRef(Client_GiveWeaponAndAmmo(target, "weapon_deagle", true, 0, 0, 0, 0));
	
	SetEntityRenderMode(g_wpnClient, RENDER_TRANSCOLOR);
	SetEntityRenderMode(g_wpnTarget, RENDER_TRANSCOLOR);
	
	SetEntityRenderColor(g_wpnClient, 255, 0, 0, 200);
	SetEntityRenderColor(g_wpnTarget, 0, 0, 255, 200);
	
	CreateTimer(0.01, DV_DeagleThrow_Task, g_wpnClient );
	CreateTimer(0.01, DV_DeagleThrow_Task, g_wpnTarget );
	
	SDKHook(client, SDKHook_WeaponDropPost, OnWeaponDrop);
	SDKHook(target, SDKHook_WeaponDropPost, OnWeaponDrop);
	
	for (int i = 1; i < MaxClients; i++)
		g_bThrowed[i] = g_bTossed[i] = false;
	
	g_iClient = client;
	g_iTarget = target;
	g_iPlaying = 2;
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
	int cpt;
	for (int i = 1; i < MaxClients; i++)
		if( g_bTossed[i] )
			cpt++;
	
	if( cpt < g_iPlaying )
		return;
	
	float avgAngleCOS = 0.0, avgAngleSIN = 0.0;
	float avgStart[3];
	float delta = 45.0 / 2.0;
	float maxDistance = 0.0;
	int winner = 0;
	
	for (int i = 1; i < MaxClients; i++) {
		if( !g_bTossed[i] )
			continue;  
		
		SubtractVectors(g_flPositions[i][1], g_flPositions[i][0], g_flPositions[i][2]);
		GetVectorAngles(g_flPositions[i][2], g_flPositions[i][3]);
		
		avgAngleCOS += Cosine(g_flPositions[i][3][1]);
		avgAngleSIN += Sine(g_flPositions[i][3][1]);				
		
		avgStart[0] += g_flPositions[i][0][0];
		avgStart[1] += g_flPositions[i][0][1];
		avgStart[2] += g_flPositions[i][0][2];		
	}
	
	float avgAngle = NormalizeAngle(ArcTangent2(avgAngleSIN / float(cpt), avgAngleCOS / float(cpt)));
	ScaleVector(avgStart, 1.0 / float(cpt));
	float end[3];
	end = avgStart;
	end[2] += 64.0;
	
	avgStart[2] = 0.0;
	
	TE_SetupBeamPoints(avgStart, end, g_cLaser, g_cLaser, 0, 30, 60.0, 0.5, 0.5, 1, 0.0, {0, 255, 0, 200}, 0);
	TE_SendToAll();	
	
	for (int i = 1; i < MaxClients; i++) {
		if( !g_bTossed[i] )
			continue;
		
		float diff = getAngleDiff(avgAngle, g_flPositions[i][3][1]);
		
		if( diff > delta ) {
			winner = g_iClient;
			CPrintToChatAll(MOD_TAG..."les joueurs n'ont pas lancé dans la même direction. La priorité est donné au T, soit %N.", winner);
			return;
		}
		
		TE_SetupBeamPoints(avgStart, g_flPositions[i][1], g_cLaser, g_cLaser, 0, 30, 60.0, 0.5, 0.5, 1, 0.0, {0, 255, 0, 200}, 0);
		TE_SendToAll();
		
		g_flPositions[i][4] = g_flPositions[i][1];
		g_flPositions[i][4][2] = 0.0;
		
		float dist = GetVectorDistance(avgStart, g_flPositions[i][4]);
		if( dist > maxDistance ) {
			maxDistance = dist;
			winner = i;
		}
	}
	
	CPrintToChatAll(MOD_TAG..."%N semble avoir gagné.", winner);
}
float NormalizeAngle(float a) {
	if( a > 360.0 )
		a -= 360.0;
	if( a < 0.0 )
		a += 360.0;	
	return a;
}
float getAngleDiff(float a, float b) {
	float n = NormalizeAngle(FloatAbs(a - b));
	return NormalizeAngle(n > 180.0 ? 360.0 - n : n);
}

public void DV_Stop(int client, int target) {
	g_iPlaying = 0;
	
	AcceptEntityInput(g_wpnClient, "Kill");
	AcceptEntityInput(g_wpnTarget, "Kill");
	
	if( client )
		SDKUnhook(client, SDKHook_WeaponDropPost, OnWeaponDrop);
	if( target )
		SDKUnhook(target, SDKHook_WeaponDropPost, OnWeaponDrop);
}