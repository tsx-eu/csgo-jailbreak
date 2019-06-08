#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <emitsoundany>

#pragma newdecls required

#include <jb_lastrequest>

int g_iClient, g_iTarget;
bool g_bClient, g_bTarget;
float g_vecClient[3], g_vecTarget[3];
int g_cSpray;

public void JB_OnPluginReady() {
	JB_CreateLastRequest("Spray le plus haut", 	JB_SELECT_CT_UNTIL_DEAD|JB_BEACON|JB_NODAMAGE, DV_CAN_Always, DV_Start, DV_Stop);
}
public void OnMapStart() {
	AddFileToDownloadsTable("materials/rc/dv_spray2.vmt");
	AddFileToDownloadsTable("materials/rc/dv_spray.vtf");
	g_cSpray = PrecacheDecal("rc/dv_spray2.vmt", true);
}

public void DV_Start(int client, int target) {
	g_iClient = client;
	g_iTarget = target;
	g_bClient = g_bTarget = false;
	
	JB_ShowHUDMessage("F﻿aites E (ou utiliser) sur une surface pour tagger le plus haut possible.﻿﻿");	
}
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon) {
	static lastButtons[65];
	
	if( (client == g_iTarget || client == g_iClient) ) {
		
		if(( client == g_iClient && g_bClient ) || ( client == g_iTarget && g_bTarget ) )
			return Plugin_Continue;
		
		if( buttons & IN_USE && !(lastButtons[client] & IN_USE) ) {
			float src[3], ang[3], dst[3];
			GetClientEyePosition(client, src);
			GetClientEyeAngles(client, ang);
			
			Handle tr = TR_TraceRayFilterEx(src, ang, MASK_SHOT, RayType_Infinite, TR_FilterSelf, client);
			if( TR_DidHit(tr) ) {
				TR_GetEndPosition(dst, tr);
				int target = TR_GetEntityIndex(tr);
				
				if(target == 0 && GetVectorDistance(src, dst) <= 128.0) {
					TE_Start("World Decal");
					TE_WriteVector("m_vecOrigin", dst);
					TE_WriteNum("m_nIndex", g_cSpray);
					TE_SendToAll();
					
					if( client == g_iClient ) {
						g_bClient = true;
						g_vecClient = dst;
					}
					else if( client == g_iTarget ) {
						g_bTarget = true;
						g_vecTarget = dst;
					}
					
					if( g_bClient && g_bTarget ) {
						if( g_vecClient[2] > g_vecTarget[2] )
							ForcePlayerSuicide(g_iTarget);
						else
							ForcePlayerSuicide(g_iClient);
					}
				}
			}
			
			CloseHandle(tr);
		}
		
		lastButtons[client] = buttons;
	}
	return Plugin_Continue;
}
public bool TR_FilterSelf(int entity, int mask, any client) {
	if (entity == client)
		return false;
	return true;
}
public void DV_Stop(int client, int target) {
	g_iClient = g_iTarget = -1;
}
