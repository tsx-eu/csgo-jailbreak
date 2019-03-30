#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#include <cstrike>
#include <emitsoundany>
#include <csgocolors>

#pragma newdecls required

#include <jb_lastrequest>

int g_cLaser;
Handle g_hMain = INVALID_HANDLE;
float maxTime;
float g_flCourseStart[3], g_flCourseEnd[3];
int g_iState;

public void JB_OnPluginReady() {
	JB_CreateLastRequest("Course - VIP", 	JB_SHOULD_SELECT_CT | JB_RUN_UNTIL_END, 	DV_CAN_VIP, DV_COURSE, DV_COURSE_END);
	
}
public void OnMapStart() {
	g_cLaser = PrecacheModel("materials/sprites/laserbeam.vmt", true);
}


public void DV_COURSE(int client, int target) {
	maxTime = GetGameTime() + 30.0;
	CPrintToChat(client, "%s Faites un clique gauche pour selectionner le départ et l'arrivée.", MOD_TAG);
	CPrintToChat(client, "%s Vous avez 30 secondes pour définir le parcours.", MOD_TAG);
	
	if( Client_GetWeapon(client, "weapon_knife") == -1) {
		GivePlayerItem(client, "weapon_knife");
	}
	
	g_iState = 1;
	
	Handle dp;
	g_hMain = CreateDataTimer(0.1, DV_COURSE_TASK, dp, TIMER_REPEAT);
	WritePackCell(dp, client);
	WritePackCell(dp, target);
}
public Action DV_COURSE_TASK(Handle timer, Handle dp) {
	ResetPack(dp);
	int client = ReadPackCell(dp);
	int target = ReadPackCell(dp);
	
	bool start = false;
	float vecEnd[3], vecEnd2[3];
	
	if( maxTime < GetGameTime() ) {
		if( g_iState == 1 || g_iState == 2 ) {
			ForcePlayerSuicide(client);
		}
		else if( g_iState == 3 ) {
			start = true;
			CPrintToChatAll("%s Début de la course.", MOD_TAG);
			g_iState = 0;
		}
		
		if( start ) {
			float vec1[3], vec2[3], vec3[3];
			MakeVectorFromPoints(g_flCourseStart, g_flCourseEnd, vec1);
			GetVectorAngles(vec1, vec2);
			
			SetEntProp(client, Prop_Data, "m_CollisionGroup", 2);
			SetEntProp(target, Prop_Data, "m_CollisionGroup", 2);
			TeleportEntity(client, g_flCourseStart, vec2, vec3);
			TeleportEntity(target, g_flCourseStart, vec2, vec3);
			
			maxTime = -1.0;
		}
		
		if( maxTime < 0.0 ) {
			
			GetClientAbsOrigin(client, vecEnd);
			GetClientAbsOrigin(target, vecEnd2);
			
			float dist1 = GetVectorDistance(g_flCourseEnd, vecEnd);
			float dist2 = GetVectorDistance(g_flCourseEnd, vecEnd2);
			if( dist1 < 32.0 || dist2 < 32.0 ) {
				int winner;
				if( dist1 > dist2 )
					winner = target;
				else
					winner = client;
				
				CPrintToChatAllEx(target, "%s {teamcolor}%N{default} a {green}gagné{default} la course!", MOD_TAG, winner);
				ForcePlayerSuicide(winner==target?client:target);
				return;
			}
		}
	}
	
	vecEnd = g_flCourseStart;
	vecEnd[2] += 64.0;
	
	TE_SetupBeamPoints(g_flCourseStart, vecEnd, g_cLaser, g_cLaser, 0, 30, 1.0, 1.0, 1.0, 1, 0.0, {0, 255, 0, 200}, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(g_flCourseStart, 1.0, 64.0, g_cLaser, g_cLaser, 0, 30, 1.0, 1.0, 0.0, {0, 255, 0, 200}, 0, 0);
	TE_SendToAll();
	
	vecEnd2 = g_flCourseEnd;
	vecEnd2[2] += 64.0;
	
	TE_SetupBeamPoints(g_flCourseEnd, vecEnd2, g_cLaser, g_cLaser, 0, 30, 1.0, 1.0, 1.0, 1, 0.0, {255, 0, 0, 200}, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(g_flCourseEnd, 1.0, 64.0, g_cLaser, g_cLaser, 0, 30, 1.0, 1.0, 0.0, {255, 0, 0, 200}, 0, 0);
	TE_SendToAll();
	
	TE_SetupBeamPoints(vecEnd, vecEnd2, g_cLaser, g_cLaser, 0, 30, 0.1, 0.5, 0.5, 1, 0.0, { 200, 200, 200, 50 }, 0);
	TE_SendToAll();
}


public void DV_COURSE_END(int client, int target) {
	KillTimer(g_hMain);																// TODO: Gérer ça de façon automatisée ?
	g_hMain = null;
}

