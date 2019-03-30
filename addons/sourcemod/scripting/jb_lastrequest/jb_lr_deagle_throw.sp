#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <smart-menu>

#pragma newdecls required

#include <jb_lastrequest>
int g_cLaser;

public void JB_OnPluginReady() {
	JB_CreateLastRequest("Lancé de deagle", 	JB_SELECT_CT_UNTIL_DEAD|JB_BEACON, DV_CAN_Always, DV_Start);
}
public void OnMapStart() {
	g_cLaser = PrecacheModel("materials/sprites/laserbeam.vmt", true);
}

public void DV_Start(int client, int target) {
	int wpnClient = Client_GiveWeaponAndAmmo(client, "weapon_deagle", true, 0, 0, 0, 0);
	int wpnTarget = Client_GiveWeaponAndAmmo(target, "weapon_deagle", true, 0, 0, 0, 0);
	
	SetEntityRenderMode(wpnClient, RENDER_TRANSCOLOR);
	SetEntityRenderMode(wpnTarget, RENDER_TRANSCOLOR);
	
	SetEntityRenderColor(wpnClient, 255, 0, 0, 200);
	SetEntityRenderColor(wpnTarget, 0, 0, 255, 200);
	
	CreateTimer(0.01, DV_DeagleThrow_Task, EntIndexToEntRef(wpnClient) );
	CreateTimer(0.01, DV_DeagleThrow_Task, EntIndexToEntRef(wpnTarget) );
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
		
			return Plugin_Handled;
		}
		
		Entity_GetAbsOrigin(entity, lastPos[entity]);
	}
	
	CreateTimer(0.01, DV_DeagleThrow_Task, EntIndexToEntRef(entity) );
	return Plugin_Handled;
}