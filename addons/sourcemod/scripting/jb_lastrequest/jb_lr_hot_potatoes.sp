#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#include <emitsoundany>
#include <smart-menu>

#pragma newdecls required

#include <jb_lastrequest>

int g_cLaser;
int g_iDeagleDATA[4];

public void JB_OnPluginReady() {
	JB_CreateLastRequest("Deagle explosif", 	JB_SELECT_CT_UNTIL_DEAD|JB_BEACON|JB_NODAMAGE, DV_CAN_Always, DV_Start);
}
public void OnMapStart() {
	g_cLaser = PrecacheModel("materials/sprites/laserbeam.vmt", true);
}

public void DV_Start(int client, int target) {
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