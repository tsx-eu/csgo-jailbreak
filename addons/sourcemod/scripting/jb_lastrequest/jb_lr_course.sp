#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#include <cstrike>
#include <emitsoundany>
#include <csgocolors>
#include <smart-menu>

#pragma newdecls required

#include <jb_lastrequest>

int g_cLaser;
Handle g_hMain = INVALID_HANDLE;
float maxTime;
float g_flCourseStart[3], g_flCourseEnd[3];
int g_iState, g_iClient, g_iTarget;

int g_iAirAccelerate, g_iGravity, g_iEnabledBunny, g_iAutoBunny;

public void JB_OnPluginReady() {
	JB_CreateLastRequest("Course", 	JB_SELECT_CT_UNTIL_DEAD, 	DV_CAN_Always, DV_Start, DV_End);
	
	
	HookEvent("weapon_fire",		EventShoot,			EventHookMode_Post);
}
public void OnMapStart() {
	g_cLaser = PrecacheModel("materials/sprites/laserbeam.vmt", true);
}

public Action EventShoot(Handle ev, const char[] name, bool broadcast) {
	int client = GetClientOfUserId(GetEventInt(ev, "userid"));
	
	if( client == g_iClient ) {
		char wepname[32];
		GetEventString(ev, "weapon", wepname, sizeof(wepname));
		
		if( StrContains(wepname, "knife") >= 0 && g_iState == 1 ) {
			GetClientAbsOrigin(client, g_flCourseStart);
			g_iState = 2;
		}
		else if( StrContains(wepname, "knife") >= 0 && g_iState == 2 ) {
			float tmp[3];
			GetClientAbsOrigin(client, tmp);
			if( GetVectorDistance(g_flCourseStart, tmp) > 128.0 ) {
				g_flCourseEnd = tmp;
				g_iState = 3;
				maxTime = 0.0;
			}
		}
	}
}

public void DV_Start(int client, int target) {
	g_iClient = client;
	
	SmartMenu menu = new SmartMenu(selectStyle);
	menu.SetTitle("Quel style de course?\n");
	menu.SetCell("target", target);

	menu.AddItem("normal", 	"Normal");
	menu.AddItem("bunny", 	"Bunny");
	menu.AddItem("lowgrav",	"Lowgrav");
	
	menu.ExitButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
}
public int selectStyle(SmartMenu menu, MenuAction action, int client, int params) {
	static char options[64];
	if( action == MenuAction_Select ) {
		menu.GetItem(params, options, sizeof(options));
		int target = menu.GetCell("target");
		
		g_iEnabledBunny = GetConVarInt(FindConVar("sv_enablebunnyhopping"));
		g_iAutoBunny = GetConVarInt(FindConVar("sv_autobunnyhopping"));
		g_iAirAccelerate = GetConVarInt(FindConVar("sv_airaccelerate"));
		g_iGravity = GetConVarInt(FindConVar("sv_gravity"));
		
		if( StrEqual(options, "bunny") )
			ServerCommand("sv_enablebunnyhopping 1;sv_autobunnyhopping 1");	
		if( StrEqual(options, "lowgrav") )
			ServerCommand("sv_airaccelerate 1000;sv_gravity 200");
		
		
		maxTime = GetGameTime() + 30.0;
		CPrintToChat(client, "%s Faites un clique gauche pour selectionner le départ et l'arrivée.", MOD_TAG);
		CPrintToChat(client, "%s Vous avez 30 secondes pour définir le parcours.", MOD_TAG);
		
		if( Client_GetWeapon(client, "weapon_knife") == -1) {
			GivePlayerItem(client, "weapon_knife");
		}
		
		g_iState = 1;
		g_flCourseStart[2] = g_flCourseEnd[2] = 9999999.9;
		
		
		Handle dp;
		g_hMain = CreateDataTimer(0.1, DV_COURSE_TASK, dp, TIMER_REPEAT);
		WritePackCell(dp, client);
		WritePackCell(dp, target);
	}
	else if( action == MenuAction_Cancel && params == MenuCancel_Interrupted ) {
		JB_DisplayMenu(DV_Start, client, menu.GetCell("target"));
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
	return;
}

public Action DV_COURSE_TASK(Handle timer, Handle dp) {
	ResetPack(dp);
	int client = ReadPackCell(dp);
	int target = ReadPackCell(dp);
	
	bool start = false;
	static float vecEnd[3], vecEnd2[3];
	
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
			
			Entity_SetCollisionGroup(client, COLLISION_GROUP_DEBRIS_TRIGGER);
			Entity_SetCollisionGroup(target, COLLISION_GROUP_DEBRIS_TRIGGER);
			
			
			TeleportEntity(client, g_flCourseStart, vec2, vec3);
			TeleportEntity(target, g_flCourseStart, vec2, vec3);
			
			SetEntityMoveType(client, MOVETYPE_NONE);
			SetEntityMoveType(target, MOVETYPE_NONE);
			
			CreateTimer(5.0, TIMER_DisableGodmod, client);
			CreateTimer(5.0, TIMER_DisableGodmod, target);
			
			PrintHintTextToAll("Début de la course dans 5 secondes");
			
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


public void DV_End(int client, int target) {
	KillTimer(g_hMain);																// TODO: Gérer ça de façon automatisée ?
	g_hMain = null;
	
	CloseMenu(client);
	
	ServerCommand("sv_enablebunnyhopping %d;sv_autobunnyhopping %d", g_iEnabledBunny, g_iAutoBunny);
	ServerCommand("sv_airaccelerate %d;sv_gravity %d", g_iAirAccelerate, g_iGravity);
	
	if( client )
		Entity_SetCollisionGroup(client, COLLISION_GROUP_PLAYER);
	if( target )
		Entity_SetCollisionGroup(target, COLLISION_GROUP_PLAYER);
}

public Action TIMER_DisableGodmod(Handle timer, any client) {
	SetEntityMoveType(client, MOVETYPE_WALK);
	EmitSoundToAllAny("rsc/jailbreak/taunt_bell.wav", client);
}
