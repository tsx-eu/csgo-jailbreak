#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#include <emitsoundany>

#pragma newdecls required

#include <jb_lastrequest>

int g_cLaser;
int g_iDeagleDATA[4];


public void OnPluginStart() {
	g_iDeagleDATA[0] = g_iDeagleDATA[1] = g_iDeagleDATA[2] = g_iDeagleDATA[3] = -1;
	for (int i = 1; i <= MaxClients; i++) 
		if( IsClientInGame(i) )
			SDKHook(i, SDKHook_WeaponCanUse, cb_DVDEAGLEEXPLO);
}
public void JB_OnPluginReady() {
	JB_CreateLastRequest("Deagle explosif", 	JB_SELECT_CT_UNTIL_DEAD|JB_BEACON|JB_NODAMAGE, DV_CAN_Always, DV_Start, DV_Stop);
}
public void OnMapStart() {
	g_cLaser = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	PrecacheSoundAny("common/beep.wav", true);
}
public void OnClientPostAdminCheck(int client) {
	SDKHook(client, SDKHook_WeaponCanUse, cb_DVDEAGLEEXPLO);
}

public void DV_Start(int client, int target) {
	DV_StripWeapon(client, false);
	DV_StripWeapon(target, false);
	
	GivePlayerItem(client, "weapon_knife");
	GivePlayerItem(target, "weapon_knife");
	
	int victim = GetRandomInt(0, 1) ? client : target;
	
	int id = GivePlayerItem(victim, "weapon_deagle");	
	SetEntProp(id, Prop_Send, "m_iClip1", 0);
	SetEntProp(id, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
	float timeLeft = GetGameTime() + Math_GetRandomFloat(20.0, 30.0);
	
	g_iDeagleDATA[0] = client;
	g_iDeagleDATA[1] = target;
	g_iDeagleDATA[2] = id;
	g_iDeagleDATA[3] = victim;
	
	CreateTimer(0.1, DV_DeagleExplosif_TASK, timeLeft);
	
	JB_ShowHUDMessage("Vous avez un deagle qui explosera au bout d'un certain temps, vous devez le jeter à l'adversaire avant qu'il n'explose.");
}
public void DV_Stop(int client, int target) {
	g_iDeagleDATA[0] = g_iDeagleDATA[1] = g_iDeagleDATA[2] = g_iDeagleDATA[3] = -1;
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
	float vecPos[3];
	float timeLeft = view_as<float>(dp);
	int client = Weapon_GetOwner(g_iDeagleDATA[2]);
	int target = g_iDeagleDATA[3];
	
	float clientSpeed = g_iDeagleDATA[0] == g_iDeagleDATA[3] ? 1.1 : 1.0;
	float targetSpeed = g_iDeagleDATA[1] == g_iDeagleDATA[3] ? 1.1 : 1.0;
	
	SetEntPropFloat(g_iDeagleDATA[0], Prop_Send, "m_flLaggedMovementValue", clientSpeed);
	SetEntPropFloat(g_iDeagleDATA[1], Prop_Send, "m_flLaggedMovementValue", targetSpeed);
	
	if( timeLeft < GetGameTime() ) {
		GetClientEyePosition(target, vecPos);
		TE_SetupExplosion(vecPos, g_cLaser, 5.0, 0, 0, 50, 50);
		TE_SendToAll();
		
		ForcePlayerSuicide(target);
	}
	else {
		if( client > 0 )
			GetClientEyePosition(client, vecPos);
		else
			Entity_GetAbsOrigin(g_iDeagleDATA[2], vecPos);
		
		TE_SetupBeamRingPoint(vecPos, 0.0, 32.0, g_cLaser, g_cLaser, 0, 30, 0.5, 1.0, 0.0, { 255, 0, 0, 200 }, 0, 20);
		TE_SendToAll();
		
		Entity_GetAbsOrigin(target, vecPos);
		TE_SetupBeamRingPoint(vecPos, 0.0, 32.0, g_cLaser, g_cLaser, 0, 30, 0.5, 1.0, 0.0, { 255, 0, 0, 200 }, 0, 20);
		TE_SendToAll();
		
		EmitSoundToAllAny("common/beep.wav", g_iDeagleDATA[2]);
		
		float time = Math_Min(Logarithm((timeLeft - GetGameTime()) + 1.0, 2.0) - 0.5, 0.1);
		CreateTimer( time, DV_DeagleExplosif_TASK, timeLeft);
	}
}