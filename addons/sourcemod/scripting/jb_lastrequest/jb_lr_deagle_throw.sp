#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <smart-menu>

#pragma newdecls required

#include <jb_lastrequest>
int g_cLaser, g_wpnClient, g_wpnTarget;
public void JB_OnPluginReady() {
	JB_CreateLastRequest("Lancé de deagle", 	JB_SELECT_CT_UNTIL_DEAD|JB_BEACON, DV_CAN_Always, DV_Start, DV_Stop);
}
public void OnMapStart() {
	g_cLaser = PrecacheModel("materials/sprites/laserbeam.vmt", true);
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
}

public Action DV_DeagleThrow_Task(Handle timer, any entity) {
	static float lastPos[2049][3];
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
		float vecStart[3], vecEnd[3];
		
		Entity_GetAbsOrigin(entity, vecStart);
		if( GetVectorDistance(vecStart, lastPos[entity]) <= 0.0) {
			Entity_GetAbsOrigin(entity, vecEnd);
			vecEnd[2] += 64.0;
		
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


public void DV_Stop(int client, int target) {
	AcceptEntityInput(g_wpnClient, "Kill");
	AcceptEntityInput(g_wpnTarget, "Kill");
}