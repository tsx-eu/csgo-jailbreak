#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#include <cstrike>
#include <emitsoundany>

#pragma newdecls required

#include <jb_lastrequest>

int g_cLaser;
int g_iDeagleDATA[4];
Handle g_hMain = INVALID_HANDLE;

public void JB_OnPluginReady() {
	JB_CreateLastRequest("Roulette", 			JB_SHOULD_SELECT_CT | JB_RUN_UNTIL_END, 	DV_CAN_Always, DV_Roulette);
	JB_CreateLastRequest("Brochette", 			JB_DEFAULT, 								DV_CAN_Min3CT, DV_Brochette);
	
	JB_CreateLastRequest("Cut 100HP", 			JB_SHOULD_SELECT_CT | JB_RUN_UNTIL_END, 	DV_CAN_Always, DV_CUT100);
	JB_CreateLastRequest("Cut 1HP", 			JB_SHOULD_SELECT_CT | JB_RUN_UNTIL_END, 	DV_CAN_Always, DV_CUT1);
	JB_CreateLastRequest("Cut Slide 100HP", 	JB_SHOULD_SELECT_CT | JB_RUN_UNTIL_END, 	DV_CAN_Always, DV_CUTSLIDE100,  DV_CUTSLIDE_END);
	JB_CreateLastRequest("Cut Slide 1HP", 		JB_SHOULD_SELECT_CT | JB_RUN_UNTIL_END, 	DV_CAN_Always, DV_CUTSLIDE1,  	DV_CUTSLIDE_END);
	
	JB_CreateLastRequest("Deagle explosif", 	JB_SHOULD_SELECT_CT | JB_RUN_UNTIL_END,		DV_CAN_Always, DV_DEAGLE_EXPL);
	JB_CreateLastRequest("Lancé de deagle", 	JB_SHOULD_SELECT_CT | JB_RUN_UNTIL_END,		DV_CAN_Always, DV_DEAGLE_THROW);
	JB_CreateLastRequest("Bataille de grenade", JB_SHOULD_SELECT_CT | JB_RUN_UNTIL_END,		DV_CAN_Always, DV_FUMI,  		DV_FUMI_END);
}
public void OnMapStart() {
	g_cLaser = PrecacheModel("materials/sprites/laserbeam.vmt", true);
}
// ----------------------------------------------------------------------------
public void DV_Roulette(int client, int target) {
	DV_StripWeapon(client, false);
	DV_StripWeapon(target, false);

	Client_RemoveWeapon(client, "weapon_deagle");
	GivePlayerItem(client, "weapon_deagle");
	
	Client_RemoveWeapon(target, "weapon_deagle");
	GivePlayerItem(target, "weapon_deagle");
}
// ----------------------------------------------------------------------------
public void DV_Brochette(int client, int target) {
	Client_RemoveWeapon(client, "weapon_awp");
	GivePlayerItem(client, "weapon_awp");
}
// ----------------------------------------------------------------------------
public void DV_CUT100(int client, int target) {
	DV_StripWeapon(client, false);
	GivePlayerItem(client, "weapon_knife");
	SetEntityHealth(client, 100);
	
	DV_StripWeapon(target, false);
	GivePlayerItem(target, "weapon_knife");
	SetEntityHealth(target, 100);
}
public void DV_CUT1(int client, int target) {
	DV_StripWeapon(client, false);
	GivePlayerItem(client, "weapon_knife");
	SetEntityHealth(client, 1);
	
	DV_StripWeapon(target, false);
	GivePlayerItem(target, "weapon_knife");
	SetEntityHealth(target, 1);
}
public void DV_CUTSLIDE100(int client, int target) {
	DV_StripWeapon(client, false);
	GivePlayerItem(client, "weapon_knife");
	SetEntityHealth(client, 100);
	
	DV_StripWeapon(target, false);
	GivePlayerItem(target, "weapon_knife");
	SetEntityHealth(target, 100);
	
	ServerCommand("sv_airaccelerate 1000;sv_gravity 0"); // TODO: Reset ces valeurs
}
public void DV_CUTSLIDE1(int client, int target) {
	DV_StripWeapon(client, false);
	GivePlayerItem(client, "weapon_knife");
	SetEntityHealth(client, 1);
	
	DV_StripWeapon(target, false);
	GivePlayerItem(target, "weapon_knife");
	SetEntityHealth(target, 1);
	
	ServerCommand("sv_airaccelerate 1000;sv_gravity 0");							// TODO: Gérer ça de façon automatisée ?
}
public void DV_CUTSLIDE_END(int client, int target) {
	ServerCommand("sv_airaccelerate 155;sv_gravity 800");
}
// ----------------------------------------------------------------------------
public void DV_DEAGLE_EXPL(int client, int target) {
	DV_StripWeapon(client, false);
	DV_StripWeapon(target, false);
	int id = Client_GiveWeaponAndAmmo(client, "weapon_deagle", true, 0, 0, 0, 0);	
	float timeLeft = GetGameTime() + Math_GetRandomFloat(20.0, 30.0);
	
	g_iDeagleDATA[0] = client;
	g_iDeagleDATA[1] = target;
	g_iDeagleDATA[2] = id;
	g_iDeagleDATA[3] = client;
	
	CreateTimer(0.1, DV_DeagleExplosif_TASK, timeLeft);
	
	for (int i = 1; i <= MaxClients; i++) 
		if( IsClientInGame(i) )
			SDKHook(i, SDKHook_WeaponCanUse, cb_DVDEAGLEEXPLO);
	
}
public Action cb_DVDEAGLEEXPLO(int client, int wepID) {
	if( g_iDeagleDATA[2] == wepID && (client==g_iDeagleDATA[0] || client == g_iDeagleDATA[1]) )
		g_iDeagleDATA[3] = client;
	else if( client==g_iDeagleDATA[0] || client==g_iDeagleDATA[1] )
		return Plugin_Handled;
	else if( g_iDeagleDATA[2] == wepID )
		return Plugin_Handled;
	
	return Plugin_Continue;
}
public Action DV_DeagleExplosif_TASK(Handle timer, any dp) {
	
	float timeLeft = view_as<float>(dp);
	int client = Weapon_GetOwner(g_iDeagleDATA[2]);
	int target = g_iDeagleDATA[3];
	
	if( timeLeft < GetGameTime() ) {
		float vecPos[3];
		GetClientEyePosition(target, vecPos);
		TE_SetupExplosion(vecPos, g_cLaser, 5.0, 0, 0, 50, 50);
		TE_SendToAll();
		
		ForcePlayerSuicide(target);
	}
	else {
		float vecPos[3];
		if( client > 0 )
			GetClientEyePosition(client, vecPos);
		else
			Entity_GetAbsOrigin(g_iDeagleDATA[2], vecPos);
		
		TE_SetupBeamRingPoint(vecPos, 0.0, 32.0, g_cLaser, g_cLaser, 0, 30, 0.5, 1.0, 0.0, { 255, 0, 0, 200 }, 0, 20);
		TE_SendToAll();
		
		Entity_GetAbsOrigin(target, vecPos);
		TE_SetupBeamRingPoint(vecPos, 0.0, 32.0, g_cLaser, g_cLaser, 0, 30, 0.5, 1.0, 0.0, { 255, 0, 0, 200 }, 0, 20);
		TE_SendToAll();
		
		
		EmitSoundToAllAny("common/warning.wav", g_iDeagleDATA[2]);
		
		float time = Math_Min(Logarithm((timeLeft - GetGameTime()) + 1.0, 2.0) - 0.5, 0.1);
		CreateTimer( time, DV_DeagleExplosif_TASK, timeLeft);
	}
}
// ----------------------------------------------------------------------------
public void DV_DEAGLE_THROW(int client, int target) {
	for (int i = 1; i <= MaxClients; i++) {
		if( !IsClientInGame(i) )
			continue;
		
		int id = Client_GiveWeaponAndAmmo(i, "weapon_deagle", true, 0, 0, 0, 0);
		int color[4];
		for (int j = 0; j < 3; j++)
			color[j] = Math_GetRandomInt(0, 255);
		color[3] = 255;
		
		SetEntityRenderMode(id, RENDER_TRANSCOLOR);
		SetEntityRenderColor(id, color[0], color[1], color[2], color[3]);
		
		CreateTimer(0.01, DV_DeagleThrow_Task, EntIndexToEntRef(id) );
	}
}
public Action DV_DeagleThrow_Task(Handle timer, any entity) {
	static float lastPos[2049][3];
	
	entity = EntRefToEntIndex(entity);
	if( entity < 0 )
		return Plugin_Handled;
		
	int color[4];
	Entity_GetRenderColor(entity, color);
	TE_SetupBeamFollow(entity, g_cLaser, g_cLaser, 0.5, 0.5, 0.5, 1, color);
	TE_SendToAll();
	
	if( Weapon_GetOwner(entity) == -1 ) {
		float vecStart[3], vecEnd[3];
		
		Entity_GetAbsOrigin(entity, vecStart);
		if( GetVectorDistance(vecStart, lastPos[entity]) <= 0.0) {
			Entity_GetAbsOrigin(entity, vecEnd);
			vecEnd[2] += 64.0;
		
			
			
			color[3] = 255;
		
			TE_SetupBeamPoints(vecStart, vecEnd, g_cLaser, g_cLaser, 0, 30, 60.0, 0.5, 0.5, 1, 0.0, color, 0);
			TE_SendToAll();
			TE_SetupBeamRingPoint(vecStart, 1.0, 32.0, g_cLaser, g_cLaser, 0, 30, 1.0, 0.5, 0.0, color, 0, 0);
			TE_SendToAll();
		
			AcceptEntityInput(entity, "Kill");
			return Plugin_Handled;
		}
		
		Entity_GetAbsOrigin(entity, lastPos[entity]);
	}
	
	CreateTimer(0.01, DV_DeagleThrow_Task, EntIndexToEntRef(entity) );
	return Plugin_Handled;
}
// ----------------------------------------------------------------------------
public void DV_FUMI(int client, int target) {
	
	DV_StripWeapon(client, false);
	GivePlayerItem(client, "weapon_flashbang");
	SetEntityHealth(client, 1);
	
	DV_StripWeapon(target, false);
	GivePlayerItem(target, "weapon_flashbang");
	SetEntityHealth(target, 1);
	
	Handle dp;
	g_hMain = CreateDataTimer(3.0, DV_Fumi_TASK, dp, TIMER_REPEAT);
	WritePackCell(dp, client);
	WritePackCell(dp, target);
}
public Action DV_Fumi_TASK(Handle timer, Handle dp) {
	ResetPack(dp);
	int client = ReadPackCell(dp);
	int target = ReadPackCell(dp);
	
	if( Client_GetWeapon(client, "weapon_flashbang") == -1 )
		GivePlayerItem(client, "weapon_flashbang");
	if( Client_GetWeapon(target, "weapon_flashbang") == -1 )
		GivePlayerItem(target, "weapon_flashbang");
}
public void DV_FUMI_END(int client, int target) {
	KillTimer(g_hMain);																// TODO: Gérer ça de façon automatisée ?
	g_hMain = null;
}
// ----------------------------------------------------------------------------