#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <csgocolors>
#include <emitsoundany>
#include <cstrike>
#include <smlib>

#pragma newdecls required

#include <jb_lastrequest>

public Plugin myinfo = {
	name = "Last Request",
	author = "KoSSoLaX",
	description = "Système de DV",
	version = "1.0.0",
	url = "zaretti.be"
};

int g_iStackCount = 0;

char g_cStackName[MAX_LR][128];
Function g_fStackCondition[MAX_LR], g_fStackStart[MAX_LR], g_fStackEnd[MAX_LR];
Handle g_hStackPlugin[MAX_LR];
int g_iStackFlag[MAX_LR], g_iStackTeam[MAX_LR][4]; // CS_TEAM_T == 2 CS_TEAM_CT == 3 
Handle g_hPluginReady = INVALID_HANDLE, g_hOnStartLR = INVALID_HANDLE, g_hOnStopLR = INVALID_HANDLE;
Handle g_hCvar = INVALID_HANDLE;
bool g_bPluginEnabled;

int g_iDoingDV = -1;
int g_iCurrentClients[MAX_PLAYERS], g_iCurrentClientCount, g_iCurrentTargets[MAX_PLAYERS], g_iCurrentTargetCount;
int g_iInitialClients[MAX_PLAYERS], g_iInitialClientCount, g_iInitialTargets[MAX_PLAYERS], g_iInitialTargetCount;

int g_cLaser, g_cArrow;

public void OnPluginStart() {
	g_hCvar = CreateConVar("sm_hosties_lr", "1");
	g_bPluginEnabled = GetConVarInt(g_hCvar) == 1;
	HookConVarChange(g_hCvar, OnConVarChange);
	
	RegConsoleCmd("sm_dv", 			cmd_DV);
	RegConsoleCmd("sm_lr", 			cmd_DV);
	RegConsoleCmd("sm_lastrequest", cmd_DV);
	
	RegAdminCmd("sm_cancellr", 		cmd_AdminCancel,	ADMFLAG_KICK);
	
	
	HookEvent("player_death", 		EventDeath, 		EventHookMode_Pre);
	HookEvent("round_start",		EventRoundStart,	EventHookMode_Post);
	HookEvent("round_end",			EventRoundEnd,		EventHookMode_Post);
	
	CreateTimer(1.0, EventSecondElapsed, _, TIMER_REPEAT);
}
public void OnConVarChange(Handle cvar, const char[] oldVal, const char[] newVal) {
	if( cvar == g_hCvar ) {
		g_bPluginEnabled = StringToInt(newVal) == 1;
	}
}
public void OnMapStart() {
	if( g_iDoingDV >= 0 )
		DV_Stop(g_iDoingDV);
		
	g_iStackCount = 0;
	g_iStackCount = g_iCurrentClientCount = g_iCurrentTargetCount = g_iInitialClientCount = g_iInitialTargetCount = 0;
	g_iDoingDV = -1;
	
	g_cLaser = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	g_cArrow = PrecacheModel("materials/vgui/hud/icon_arrow_up.vmt", true);
	PrecacheSoundAny("buttons/blip1.wav", true);
	
	Call_StartForward(g_hPluginReady);
	Call_Finish();
}
public void OnClientPostAdminCheck(int client) {
	SDKHook(client, SDKHook_OnTakeDamage, EventTakeDamage);
}
public void OnClientDisconnect(int client) {
	if( g_iDoingDV == -1 )
		return;
	
	bool endOfDV = DV_RemoveClientFromTeam(client, true);
	
	if( endOfDV )
		DV_Stop(g_iDoingDV);
}
// -------------------------------------------------------------------------------------------------------------------------------
public Action EventDeath(Handle ev, const char[] name, bool broadcast) {
	if( g_iDoingDV == -1 )
		return;
	
	int client = GetClientOfUserId(GetEventInt(ev, "userid"));
	bool endOfDV = DV_RemoveClientFromTeam(client, false);
	
	if( endOfDV )
		DV_Stop(g_iDoingDV);
}
public Action EventRoundStart(Handle ev, const char[] name, bool  bd) {
	if( g_iDoingDV >= 0 ) { // Comment c'est possible ?
		DV_Stop(g_iDoingDV);
		
		PrintToChatAll("WARNING - Please report the following issue:");
		PrintToChatAll(" -\t EventRoundStart @ g_iDoingDV >= 0");		
	}
}
public Action EventRoundEnd(Handle ev, const char[] name, bool  bd) {
	if( g_iDoingDV >= 0 )
		DV_Stop(g_iDoingDV);
}
public Action EventTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3]) {
	if( g_iDoingDV == -1 )
		return Plugin_Continue;
	if( !(g_iStackFlag[g_iDoingDV] & JB_SHOULD_SELECT_CT) )
		return Plugin_Continue;
	
	bool victimInDV = DV_IsClientInsideTeam(victim);
	bool attackerInDV = DV_IsClientInsideTeam(attacker);
	
	
	if( victimInDV && attackerInDV ) {
		if( g_iStackFlag[g_iDoingDV] & JB_NODAMAGE )
			return Plugin_Stop;
		
	}
	else {
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}
public Action EventSecondElapsed(Handle timer, any none) {
	
	if( g_iDoingDV >= 0 && g_iStackFlag[g_iDoingDV] & JB_BEACON ) {
		float src[3], dst[3];
		int client, target;
		
		for (int i = 0; i < g_iCurrentClientCount; i++) {
			client = g_iCurrentClients[i];
			GetClientAbsOrigin(client, src);
			src[2] += 16.0;
			
			
			
			for (int j = 0; j < g_iCurrentTargetCount; j++) {
				target = g_iCurrentTargets[j];
				GetClientAbsOrigin(target, dst);
				dst[2] += 16.0;
				
				if( GetVectorDistance(src, dst, true) > MAX_DISTANCE*MAX_DISTANCE ) {
					DV_BeamEffect(src, dst, {255, 0, 0, 200});
					DV_BeamEffect(dst, src, { 0, 0, 255, 200});
					
					EmitSoundToClientAny(client, "buttons/blip1.wav", target);
					EmitSoundToClientAny(target, "buttons/blip1.wav", client);
				}
			}
		}
		
	}
	
	return Plugin_Continue;
}

// -------------------------------------------------------------------------------------------------------------------------------
public Action cmd_AdminCancel(int client, int args) {
	if( g_iDoingDV >= 0 )
		DV_Stop(g_iDoingDV);
	
	return Plugin_Handled;
}
public Action cmd_DV(int client, int args) {
	if( GetClientTeam(client) != CS_TEAM_T || !IsPlayerAlive(client) || DV_CanBeStarted() == -1 ) {
		CPrintToChat(client, MOD_TAG ... "Vous n'avez {red}pas{default} le droit d'utiliser le " ... MOD_TAG_START ... "!dv" ... MOD_TAG_END ... " maintenant.");
		return Plugin_Handled;
	}
	
	displayDV(client);
	return Plugin_Handled;
}
void displayDV(int client) {
	static char tmp[8];
	
	Menu menu = new Menu(menuDV);
	menu.SetTitle("Choisissez votre dernière volonté\n");
	
	g_iCurrentClients[0] = client;
	g_iCurrentClientCount = 1;
	g_iCurrentTargetCount = 0;
	
	int targetCount = DV_CountTeam(CS_TEAM_CT);
	
	for (int i = 0; i < g_iStackCount; i++) {
		Format(tmp, sizeof(tmp), "%d", i);
		
		bool can;
		
		if( g_iStackTeam[i][CS_TEAM_CT] > targetCount ) {
			can = false;
		}
		else if( g_fStackCondition[i] == INVALID_FUNCTION ) {
			can = true;
		}
		else {
			
			Call_StartFunction(g_hStackPlugin[i], g_fStackCondition[i]);
			if( g_iStackTeam[i][CS_TEAM_T] > 1 ) {
				Call_PushArray(g_iCurrentClients, g_iCurrentClientCount);
				Call_PushCell(g_iCurrentClientCount);
			}
			else
				Call_PushCell(g_iCurrentClients[0]);
			Call_Finish(can);
			
		}
		
		menu.AddItem(tmp, g_cStackName[i], can ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	}
	
	menu.ExitButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
	
	PrintHintTextToAll("%N\nchoisis sa dernière volonté", client);
	EmitSoundToAllAny("ui/bonus_alert_start.wav");
}
void displayDV_SelectCT(int id, int client) {
	static char tmp[2][64];
	
	Menu menu = new Menu(menuDVchooseCT);
	menu.SetTitle("Choisissez un CT\n");
	
	for (int i = 1; i <= MaxClients; i++) {
		if( !IsClientInGame(i) )
			continue;
		if( !IsPlayerAlive(i) )
			continue;
		if( GetClientTeam(i) != CS_TEAM_CT)
			continue;
			
		int skip = false;
		for (int j = 0; j < g_iStackTeam[id][CS_TEAM_CT]; j++) {
			if( g_iCurrentTargets[j] == i ) {
				skip = true;
				break;
			}
		}
		
		if( skip )
			continue;
		
		Format(tmp[0], sizeof(tmp[]), "%d %d", id, i);
		Format(tmp[1], sizeof(tmp[]), "%N", i);
		
		menu.AddItem(tmp[0], tmp[1]);
	}
	
	menu.ExitButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
}
public int menuDV(Menu menu, MenuAction action, int client, int params) {
	static char options[64];
	if( action == MenuAction_Select ) {
		GetMenuItem(menu, params, options, sizeof(options));
		int id = StringToInt(options);
		
		if( g_iStackFlag[id] & JB_SHOULD_SELECT_CT ) {
			displayDV_SelectCT(id, client);
		}
		else {
			DV_Start(id);
		}
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
	return;
}
public int menuDVchooseCT(Menu menu, MenuAction action, int client, int params) {
	static char options[64], data[2][16];
	if( action == MenuAction_Select ) {
		GetMenuItem(menu, params, options, sizeof(options));
		ExplodeString(options, " ", data, sizeof(data), sizeof(data[]));
		
		int id = StringToInt(data[0]);
		g_iCurrentTargets[g_iCurrentTargetCount] = StringToInt(data[1]);
		g_iCurrentTargetCount++;
		
		if( g_iCurrentTargetCount >= g_iStackTeam[id][CS_TEAM_CT] )
			DV_Start(id);
		else
			displayDV_SelectCT(id, client);
		
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
}
// -------------------------------------------------------------------------------------------------------------------------------
bool DV_RemoveClientFromTeam(int client, bool disconnect) {
	bool endOfDV = false;
	int team = GetClientTeam(client);

	if( team == CS_TEAM_CT && g_iStackFlag[g_iDoingDV] & (JB_SHOULD_SELECT_CT|JB_RUN_UNTIL_DEAD) ) {
		DV_RemoveFromStack(client, g_iCurrentTargets, g_iCurrentTargetCount);
		if( disconnect )
			DV_RemoveFromStack(client, g_iInitialTargets, g_iInitialTargetCount);
		
		if( g_iCurrentTargetCount <= 0 )
			endOfDV = true;
	}
	if( team == CS_TEAM_T ) {
		DV_RemoveFromStack(client, g_iCurrentClients, g_iCurrentClientCount);
		if( disconnect )
			DV_RemoveFromStack(client, g_iInitialClients, g_iInitialClientCount);
		
		if( g_iCurrentClientCount <= 0 )
			endOfDV = true;
	}
	
	return endOfDV;
}
bool DV_RemoveFromStack(int client, int[] stack, int& count) {
	for (int i = 0; i < count; i++) {
		if( stack[i] == client ) {
			
			for (int j = i+1; j < count; j++)
				stack[j - 1] = stack[j];
			count--;
			
			break;
		}
	}
}
bool DV_IsClientInsideTeam(int client) {
	int team = GetClientTeam(client);
	if( team == CS_TEAM_CT ) {
		for (int i = 0; i < g_iCurrentTargetCount; i++)
			if( g_iCurrentTargets[i] == client )
				return true;
	}
	else if( team == CS_TEAM_T ) {
		for (int i = 0; i < g_iCurrentClientCount; i++)
			if( g_iCurrentClients[i] == client )
				return true;
	}
	
	return false;
}
int DV_CanBeStarted() {
	if( !g_bPluginEnabled )
		return -1;
	if( g_iDoingDV >= 0 )
		return -1;
			
	int ct, t, found;
	for (int i = 1; i <= MaxClients; i++) {
		if( !IsClientInGame(i) || !IsPlayerAlive(i) )
			continue;
		if( GetClientTeam(i) == CS_TEAM_CT )
			ct++;
		else if( GetClientTeam(i) == CS_TEAM_T ) {
			t++;
			found = i;
		}
	}
			
	if( t > 1 || ct == 0 ) 
		return -1;
	
	return found;
}
int DV_CountTeam(int team) {
	int t = 0;
	for (int i = 1; i <= MaxClients; i++) {
		if( !IsClientInGame(i) || !IsPlayerAlive(i) )
			continue;
		if( GetClientTeam(i) == team )
			t++;
	}
	return t;
}
stock void DV_CleanTeams(int team = 0) {
	if( team > 0 && team == CS_TEAM_T ) {
		for (int i = 0; i < g_iCurrentClientCount; i++) {
			DV_CleanClient(g_iCurrentClients[i]);
		}
	}
	
	if( team > 0 && team == CS_TEAM_CT ) {
		for (int j = 0; j < g_iCurrentTargetCount; j++) {
			DV_CleanClient(g_iCurrentTargets[j]);
		}
	}
}
void DV_CleanClient(int client) {
	DV_StripWeapon(client);
	GivePlayerItem(client, "weapon_knife");
}
void DV_BeamEffect(float src[3], float dst[3], int color[4]) {
	TE_SetupBeamRingPoint(src, 32.0, MAX_DISTANCE/2, g_cLaser, g_cLaser, 0, 12, 2.0, 16.0, 0.0, color, 0, 0);
	TE_SendToAll();
	
	float dir[3], ang[3], vel[3];
	SubtractVectors(src, dst, dir);
	GetVectorAngles(dir, ang);
	Math_RotateVector(view_as<float>({0.0, 16.0, 0.0}), ang, vel);
	AddVectors(src, vel, dir);
	AddVectors(dst, vel, ang);
	
	Handle trace = TR_TraceRayFilterEx(ang, dir, MASK_SHOT, RayType_EndPoint, TR_FilterClients);
	if (TR_DidHit(trace)) {
		TR_GetEndPosition(vel, trace);
		
		TE_SetupBeamPoints(dir, vel, g_cArrow, g_cArrow, 0, 12, 1.0, 16.0, 16.0, 0, 0.0, color, 10);
		TE_SendToAll();
		TE_SetupBeamPoints(vel, ang, g_cArrow, g_cArrow, 0, 12, 1.0, 16.0, 16.0, 0, 0.0, color, 10);
		TE_SendToAll();
	}
	else {
		TE_SetupBeamPoints(dir, ang, g_cArrow, g_cArrow, 0, 12, 1.0, 16.0, 16.0, 0, 0.0, color, 10);
		TE_SendToAll();
	}
	CloseHandle(trace);
	
	
}
public bool TR_FilterClients(int entity, int mask, any client) {
	if (entity > 0 && entity <= MaxClients)
		return false;
	return true;
}
// -------------------------------------------------------------------------------------------------------------------------------
int DV_Start(int id) {
	PrintHintTextToAll("Dernière volonté:\n%s", g_cStackName[id]);
		
	if( g_iCurrentTargetCount > 0 )
		CPrintToChatAll(MOD_TAG ... "{teamcolor}%N{default} a choisis de faire sa DV " ... MOD_TAG_START ... "%s" ... MOD_TAG_END ... " contre " ... MOD_TAG_START ... "%N" ... MOD_TAG_END ... ".", g_iCurrentClients[0], g_cStackName[id], g_iCurrentTargets[0]);
	else
		CPrintToChatAll(MOD_TAG ... "{blue}%N{default} a choisis sa dernière volontée: " ... MOD_TAG_START ... "%s" ... MOD_TAG_END ... ".", g_iCurrentClients[0],  g_cStackName[id]);
	
	g_iDoingDV = id;
	g_iInitialClients = g_iCurrentClients;
	g_iInitialClientCount = g_iCurrentClientCount;
	g_iInitialTargets = g_iCurrentTargets;
	g_iInitialTargetCount = g_iCurrentTargetCount;
	
	DV_CleanTeams();
	if( g_fStackStart[id] != INVALID_FUNCTION )
		DV_Call(id, g_fStackStart[id]);
	
	Call_StartForward(g_hOnStartLR);
	Call_PushCell(g_iInitialClients[0]);
	Call_PushCell(g_iInitialTargets[0]);	
	Call_Finish();
}
int DV_Stop(int id) {
	CPrintToChatAll("%s La {blue}DV{default} est terminée.", MOD_TAG);
	
	if( g_fStackEnd[id] != INVALID_FUNCTION )
		DV_Call(id, g_fStackEnd[id]);
	
	Call_StartForward(g_hOnStopLR);
	Call_PushCell(g_iInitialClients[0]);
	Call_PushCell(g_iInitialTargets[0]);	
	Call_Finish();
	
	DV_CleanTeams();
	g_iInitialTargetCount = g_iInitialClientCount = g_iCurrentClientCount = g_iCurrentTargetCount = 0;
	g_iDoingDV = -1;
}
void DV_Call(int id, Function func) {
	Call_StartFunction(g_hStackPlugin[id], func);
	if( g_iStackTeam[id][CS_TEAM_T] > 1 ) {
		Call_PushArray(g_iInitialClients, g_iInitialClientCount);
		Call_PushCell(g_iInitialClientCount);
	}
	else if( g_iStackTeam[id][CS_TEAM_T] == 1 )
		Call_PushCell(g_iInitialClientCount > 0 ? g_iInitialClients[0] : 0 );
	
	if( g_iStackTeam[id][CS_TEAM_CT] > 1 ) {
		Call_PushArray(g_iInitialTargets, g_iInitialTargetCount);
		Call_PushCell(g_iInitialTargetCount);
	}
	else if( g_iStackTeam[id][CS_TEAM_CT] == 1 )
		Call_PushCell(g_iInitialTargetCount > 0 ? g_iInitialTargets[0] : 0);
	Call_Finish();
}
// -------------------------------------------------------------------------------------------------------------------------------
public APLRes AskPluginLoad2(Handle hPlugin, bool isAfterMapLoaded, char[] error, int err_max) {
	RegPluginLibrary("JB_LastRequest");
	
	CreateNative("JB_CreateLastRequest", Native_JB_CreateLastRequest);
	CreateNative("JB_SetTeamCount", Native_JB_SetTeamCount);
	CreateNative("JB_CeanTeam", Native_DV_CleanTeam);
	CreateNative("JB_End", Native_JB_End);
	
	g_hPluginReady = CreateGlobalForward("JB_OnPluginReady", ET_Ignore);
	g_hOnStartLR = CreateGlobalForward("OnStartLR", ET_Ignore);
	g_hOnStopLR = CreateGlobalForward("OnStopLR", ET_Ignore);
}
public int Native_JB_CreateLastRequest(Handle plugin, int numParams) {

	g_hStackPlugin[g_iStackCount] = plugin;
	GetNativeString(1, g_cStackName[g_iStackCount], sizeof(g_cStackName[]));
	g_iStackFlag[g_iStackCount] = GetNativeCell(2);
	g_fStackCondition[g_iStackCount] = GetNativeFunction(3);
	g_fStackStart[g_iStackCount] = GetNativeFunction(4);
	g_fStackEnd[g_iStackCount] = GetNativeFunction(5);
	
	g_iStackTeam[g_iStackCount][CS_TEAM_T] = 1;
	g_iStackTeam[g_iStackCount][CS_TEAM_CT] = 1;
	
	return g_iStackCount++;
}
public int Native_JB_SetTeamCount(Handle plugin, int numParams) {	
	g_iStackTeam[GetNativeCell(1)][GetNativeCell(2)] = GetNativeCell(3);	
}
public int Native_JB_End(Handle plugin, int numParams) {
	DV_Stop(g_iDoingDV);
}
public int Native_DV_CleanTeam(Handle plugin, int numParams) {
	DV_CleanTeams(GetNativeCell(1));
}