#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <csgocolors>
#include <emitsoundany>
#include <cstrike>
#include <smlib>
#include <smart-menu>
#include <CustomPlayerSkins>

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
int g_iStackFlag[MAX_LR], g_iStackTeam[MAX_LR][4], g_iSorted[MAX_LR]; // CS_TEAM_T == 2 CS_TEAM_CT == 3 
Handle g_hPluginReady = INVALID_HANDLE, g_hOnStartLR = INVALID_HANDLE, g_hOnStopLR = INVALID_HANDLE;
int g_iOpenMenu = -1;
Handle g_hCvarEnable = INVALID_HANDLE;
Handle g_hCvarStripWeapon = INVALID_HANDLE;
bool g_bPluginEnabled;

int g_iDoingDV = -1;
int g_iCurrentTeam[4][MAX_PLAYERS], g_iCurrentTeamCount[4], g_iInitialTeam[4][MAX_PLAYERS], g_iInitialTeamCount[4];


int g_cLaser, g_cArrow;

public void OnPluginStart() {
	g_hCvarEnable = CreateConVar("sm_hosties_lr", "1");
	g_hCvarStripWeapon = CreateConVar("sm_hosties_strip_weapons", "1");
	
	g_bPluginEnabled = GetConVarInt(g_hCvarEnable) == 1;
	HookConVarChange(g_hCvarEnable, OnConVarChange);
	
	RegConsoleCmd("sm_dv", 			cmd_DV);
	RegConsoleCmd("sm_lr", 			cmd_DV);
	RegConsoleCmd("sm_lastrequest", cmd_DV);
	
	RegAdminCmd("sm_cancellr", 		cmd_AdminCancel,	ADMFLAG_KICK);
	
	HookEvent("player_death", 		EventDeath, 		EventHookMode_Pre);
	HookEvent("player_spawn", 		EventSpawn, 		EventHookMode_Post);
	HookEvent("round_start",		EventRoundStart,	EventHookMode_Post);
	HookEvent("round_end",			EventRoundEnd,		EventHookMode_Post);
	
	CreateTimer(1.0, EventSecondElapsed, _, TIMER_REPEAT);
}
public void OnConVarChange(Handle cvar, const char[] oldVal, const char[] newVal) {
	if( cvar == g_hCvarEnable ) {
		g_bPluginEnabled = StringToInt(newVal) == 1;
	}
}
public void OnMapStart() {
	if( g_iDoingDV >= 0 )
		DV_Stop(g_iDoingDV);
		
	g_iStackCount = 0;
	g_iStackCount = g_iCurrentTeamCount[CS_TEAM_T] = g_iCurrentTeamCount[CS_TEAM_CT] = g_iInitialTeamCount[CS_TEAM_T] = g_iInitialTeamCount[CS_TEAM_CT] = 0;
	g_iDoingDV = -1;
	
	g_cLaser = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	g_cArrow = PrecacheModel("materials/vgui/hud/icon_arrow_up.vmt", true);
	PrecacheSoundAny("buttons/blip1.wav", true);
	PrecacheSoundAny("rsc/jailbreak/lr1.mp3", true);
	
	AddFileToDownloadsTable("sound/rsc/jailbreak/lr1.mp3");
	
	Call_StartForward(g_hPluginReady);
	Call_Finish();
}
public void OnClientPutInServer(int client) {
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
public Action EventSpawn(Handle ev, const char[] name, bool broadcast) {
	int client = GetClientOfUserId(GetEventInt(ev, "userid"));
	int team = GetClientTeam(client);
	
	if( GetConVarBool(g_hCvarStripWeapon) ) {
		DV_CleanClient(client);
		
		if( team == CS_TEAM_CT )
			Client_SetArmor(client, 100);
		if( team == CS_TEAM_T && DV_CAN_VIP(client) )
			Client_SetArmor(client, 100);
	}
	
	if( g_iOpenMenu > 0 && IsClientInGame(g_iOpenMenu) )
		CloseMenu(g_iOpenMenu);
}
public Action EventDeath(Handle ev, const char[] name, bool broadcast) {
	int client = GetClientOfUserId(GetEventInt(ev, "userid"));
	if( g_iOpenMenu == client && client > 0 )
		CloseMenu(client);
	
	if( g_iDoingDV == -1 )
		return;
	
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
	
	if( g_iOpenMenu > 0 && IsClientInGame(g_iOpenMenu) )
		CloseMenu(g_iOpenMenu);
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
	
	if( attacker > MaxClients && HasEntProp(attacker, Prop_Data, "m_hOwnerEntity") )
		attacker = GetEntProp(attacker, Prop_Data, "m_hOwnerEntity");
	
	bool victimInDV = DV_IsClientInsideTeam(victim);	
	bool attackerInDV = (attacker > 0 && attacker <= MaxClients) ? DV_IsClientInsideTeam(attacker) : false;
	
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
	static bool lastWasAvailable = false;
	
	bool now = (DV_CanBeStarted() != -1);
	
	if( g_iDoingDV == -1 && now && !lastWasAvailable )
		EmitSoundToAllAny("rsc/jailbreak/lr1.mp3");
	lastWasAvailable = now;
	
	
	if( g_iDoingDV >= 0 && g_iStackFlag[g_iDoingDV] & JB_BEACON ) {
		float src[3], dst[3];
		int client, target;
		
		for (int i = 0; i < g_iCurrentTeamCount[CS_TEAM_T]; i++) {
			client = g_iCurrentTeam[CS_TEAM_T][i];
			GetClientAbsOrigin(client, src);
			src[2] += 16.0;
			
			
			
			for (int j = 0; j < g_iCurrentTeamCount[CS_TEAM_CT]; j++) {
				target = g_iCurrentTeam[CS_TEAM_CT][j];
				GetClientAbsOrigin(target, dst);
				dst[2] += 16.0;
				
				if( GetVectorDistance(src, dst, true) > MAX_DISTANCE*MAX_DISTANCE ) {
					DV_BeamEffect(src, dst, {255, 0, 0, 100});
					DV_BeamEffect(dst, src, { 0, 0, 255, 100});
					
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
void initTeam(int team) {
	g_iCurrentTeamCount[team] = 0;
	for (int i = 1; i < MaxClients; i++) {
		if( !IsClientInGame(i) || !IsPlayerAlive(i) )
			continue;
		if( GetClientTeam(i) != team )
			continue;
		
		g_iCurrentTeam[team][g_iCurrentTeamCount[team]++] = i;
	}
}
void displayDV(int client) {
	static char tmp[8];
	
	int t = DV_CanBeStarted();
	int dv = 0;
	
	Menu menu = new Menu(menuDV);
	menu.SetTitle("Choisissez votre dernière volonté\n");
	
	initTeam(CS_TEAM_T);
	g_iCurrentTeamCount[CS_TEAM_CT] = 0;
	
	int targetCount = DV_CountTeam(CS_TEAM_CT);
	
	for (int i = 0; i < g_iStackCount; i++) {
		int id = g_iSorted[i];
		
		if( g_iStackTeam[id][CS_TEAM_T] == t ) {
			Format(tmp, sizeof(tmp), "%d", id);
			
			bool can = DV_CanBePlayed(id, targetCount);		
			menu.AddItem(tmp, g_cStackName[id], can ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
			if( can )
				dv++;
		}
	}
	
	menu.ExitButton = false;
	
	if( dv >  0) {
		menu.Display(client, MENU_TIME_FOREVER);
		g_iOpenMenu = client;
		PrintHintTextToAll("%N\nchoisis sa dernière volonté", client);
		EmitSoundToAllAny("ui/bonus_alert_start.wav");
	}
	else {
		CPrintToChat(client, MOD_TAG ... "Vous n'avez {red}pas{default} le droit d'utiliser le " ... MOD_TAG_START ... "!dv" ... MOD_TAG_END ... " maintenant.");
		delete menu;
	}
}
void displayDV_SelectCT(int client, int id) {
	static char tmp[2][64];
	
	SmartMenu menu = new SmartMenu(menuDVchooseCT);
	menu.SetTitle("Choisissez un CT\n");
	menu.SetCell("id", id);
	
	for (int i = 1; i <= MaxClients; i++) {
		if( !IsClientInGame(i) )
			continue;
		if( !IsPlayerAlive(i) )
			continue;
		if( GetClientTeam(i) != CS_TEAM_CT)
			continue;
			
		int skip = false;
		for (int j = 0; j < g_iCurrentTeamCount[CS_TEAM_CT]; j++) {
			if( g_iCurrentTeam[CS_TEAM_CT][j] == i ) {
				skip = true;
				break;
			}
		}
		
		if( skip )
			continue;
		
		Format(tmp[0], sizeof(tmp[]), "%d", i);
		Format(tmp[1], sizeof(tmp[]), "%N", i);
		
		menu.AddItem(tmp[0], tmp[1]);
	}
	
	menu.ExitButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
	g_iOpenMenu = client;
}
public int menuDV(Menu menu, MenuAction action, int client, int params) {
	static char options[64];
	if( action == MenuAction_Select ) {
		GetMenuItem(menu, params, options, sizeof(options));
		int id = StringToInt(options);
		
		if( g_iStackFlag[id] & JB_SHOULD_SELECT_CT ) {
			displayDV_SelectCT(client, id);
		}
		else {
			DV_Start(id);
		}
	}
	else if( action == MenuAction_Cancel && params == MenuCancel_Interrupted ) {
		JB_DisplayMenu(displayDV, client);
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
	return;
}
public int menuDVchooseCT(SmartMenu menu, MenuAction action, int client, int params) {
	static char options[64];
	if( action == MenuAction_Select ) {
		GetMenuItem(menu, params, options, sizeof(options));
		int id = menu.GetCell("id");
		int teamCount = StringToInt(options);
		
		g_iCurrentTeam[CS_TEAM_CT][g_iCurrentTeamCount[CS_TEAM_CT]] = teamCount;
		g_iCurrentTeamCount[CS_TEAM_CT]++;
		
		if( g_iCurrentTeamCount[CS_TEAM_CT] >= g_iStackTeam[id][CS_TEAM_CT] )
			DV_Start(id);
		else
			displayDV_SelectCT(client, id);
		
	}
	else if( action == MenuAction_Cancel && params == MenuCancel_Interrupted ) {
		JB_DisplayMenu(displayDV_SelectCT, client, menu.GetCell("id"));
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
		DV_RemoveFromStack(client, g_iCurrentTeam[CS_TEAM_CT], g_iCurrentTeamCount[CS_TEAM_CT]);
		if( disconnect )
			DV_RemoveFromStack(client, g_iInitialTeam[CS_TEAM_CT], g_iInitialTeamCount[CS_TEAM_CT]);
		
		if( g_iCurrentTeamCount[CS_TEAM_CT] <= 0 )
			endOfDV = true;
	}
	if( team == CS_TEAM_T ) {
		DV_RemoveFromStack(client, g_iCurrentTeam[CS_TEAM_T], g_iCurrentTeamCount[CS_TEAM_T]);
		if( disconnect )
			DV_RemoveFromStack(client, g_iInitialTeam[CS_TEAM_T], g_iInitialTeamCount[CS_TEAM_T]);
		
		if( g_iCurrentTeamCount[CS_TEAM_T] <= 0 )
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
bool DV_IsClientInsideTeam(int client, int team = -1) {
	if( team == -1 )
		team = GetClientTeam(client);
	
	for (int i = 0; i < g_iCurrentTeamCount[team]; i++)
		if( g_iCurrentTeam[team][i] == client )
			return true;
	
	return false;
}
int DV_CanBeStarted() {
	if( !g_bPluginEnabled )
		return -1;
	if( g_iDoingDV >= 0 )
		return -1;
	
	int ct, t;
	for (int i = 1; i <= MaxClients; i++) {
		if( !IsClientInGame(i) || !IsPlayerAlive(i) )
			continue;
		if( GetClientTeam(i) == CS_TEAM_CT )
			ct++;
		else if( GetClientTeam(i) == CS_TEAM_T )
			t++;
	}
	
	if( ct == 0 ) {
		return -1;
	}
	if( t > 1 ) {
		initTeam(CS_TEAM_T);
		for (int id = 0; id < g_iStackCount; id++) {
			if( g_iStackTeam[id][CS_TEAM_T] == t ) {
				if( DV_CanBePlayed(id, ct) )
					return t;
			}
		}
		return -1;
	}
	
	return t;
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
	if( team > 0 ) {
		for (int i = 0; i < g_iCurrentTeamCount[team]; i++)
			DV_CleanClient(g_iCurrentTeam[team][i]);
	}
	else {
		for (int i = 0; i < g_iCurrentTeamCount[CS_TEAM_T]; i++)
			DV_CleanClient(g_iCurrentTeam[CS_TEAM_T][i]);
		for (int i = 0; i < g_iCurrentTeamCount[CS_TEAM_CT]; i++)
			DV_CleanClient(g_iCurrentTeam[CS_TEAM_CT][i]);
	}
}
void DV_CleanClient(int client) {
	if( g_iDoingDV == -1 || !(g_iStackFlag[g_iDoingDV] & JB_DONT_STRIP) ) {
		DV_StripWeapon(client);
		GivePlayerItem(client, "weapon_knife");
	}
	if( g_iDoingDV == -1 || !(g_iStackFlag[g_iDoingDV] & JB_DONT_HEAL) ) {
		SetEntityHealth(client, 100);
		Client_SetArmor(client, 0);
	}
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
		
		TE_SetupBeamPoints(dir, vel, g_cLaser, g_cLaser, 0, 12, 1.0, 2.0, 2.0, 0, 0.0, color, 10);
		TE_SendToAll();
		TE_SetupBeamPoints(vel, ang, g_cLaser, g_cLaser, 0, 12, 1.0, 2.0, 2.0, 0, 0.0, color, 10);
		TE_SendToAll();
	}
	else {
		TE_SetupBeamPoints(dir, ang, g_cLaser, g_cLaser, 0, 12, 1.0, 2.0, 2.0, 0, 0.0, color, 10);
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
bool DV_CanBePlayed(int id, int targetCount=1) {
	bool can;
	
	if( g_iStackFlag[id] & JB_SHOULD_SELECT_CT && g_iStackTeam[id][CS_TEAM_CT] > targetCount ) {
		can = false;
	}
	else if( g_fStackCondition[id] == INVALID_FUNCTION ) {
		can = true;
	}
	else {
		Call_StartFunction(g_hStackPlugin[id], g_fStackCondition[id]);
		if( g_iStackTeam[id][CS_TEAM_T] > 1 ) {
			Call_PushArray(g_iCurrentTeam[CS_TEAM_T], g_iCurrentTeamCount[CS_TEAM_T]);
			Call_PushCell(g_iCurrentTeamCount[CS_TEAM_T]);
		}
		else
			Call_PushCell(g_iCurrentTeam[CS_TEAM_T][0]);
		Call_Finish(can);
	}
	return can;
}
bool DV_Start(int id) {
	if( !DV_CanBeStarted() ) {
		CPrintToChatAll("%s La {blue}DV{default} n'est plus disponible.", MOD_TAG);
		return false;
	}
	if( !DV_CanBePlayed(id, g_iCurrentTeamCount[CS_TEAM_CT]) ) {
		CPrintToChatAll("%s La {blue}DV{default} n'est plus disponible.", MOD_TAG);
		displayDV(g_iCurrentTeam[CS_TEAM_T][0]);
		return false;
	}
	
	g_iOpenMenu = -1;
	PrintHintTextToAll("Dernière volonté:\n%s", g_cStackName[id]);
		
	if( g_iCurrentTeamCount[CS_TEAM_CT] > 0 )
		CPrintToChatAll(MOD_TAG ... "{teamcolor}%N{default} a choisis de faire sa DV " ... MOD_TAG_START ... "%s" ... MOD_TAG_END ... " contre " ... MOD_TAG_START ... "%N" ... MOD_TAG_END ... ".", g_iCurrentTeam[CS_TEAM_T][0], g_cStackName[id], g_iCurrentTeam[CS_TEAM_CT][0]);
	else
		CPrintToChatAll(MOD_TAG ... "{blue}%N{default} a choisis sa dernière volontée: " ... MOD_TAG_START ... "%s" ... MOD_TAG_END ... ".", g_iCurrentTeam[CS_TEAM_T][0],  g_cStackName[id]);
	
	g_iDoingDV = id;
	g_iInitialTeam[CS_TEAM_T] = g_iCurrentTeam[CS_TEAM_T];
	g_iInitialTeamCount[CS_TEAM_T] = g_iCurrentTeamCount[CS_TEAM_T];
	g_iInitialTeam[CS_TEAM_CT] = g_iCurrentTeam[CS_TEAM_CT];
	g_iInitialTeamCount[CS_TEAM_CT] = g_iCurrentTeamCount[CS_TEAM_CT];
	
	DV_CleanTeams();
	
	if( g_fStackStart[id] != INVALID_FUNCTION )
		DV_Call(id, g_fStackStart[id]);
	
	Call_StartForward(g_hOnStartLR);
	Call_PushCell(g_iInitialTeam[CS_TEAM_T][0]);
	Call_PushCell(g_iInitialTeam[CS_TEAM_CT][0]);	
	Call_Finish();
	
	if( g_iStackFlag[g_iDoingDV] & JB_BEACON ) {
		for (int i = 0; i < g_iInitialTeamCount[CS_TEAM_T]; i++)
			Effect_Glow(g_iInitialTeam[CS_TEAM_T][i], 255, 0, 0, 200);
		for (int i = 0; i < g_iInitialTeamCount[CS_TEAM_CT]; i++)
			Effect_Glow(g_iInitialTeam[CS_TEAM_CT][i], 0, 0, 255, 200);
	}
	
	return false;
}
void DV_Stop(int id) {
	CPrintToChatAll("%s La {blue}DV{default} est terminée.", MOD_TAG);
	
	if( g_fStackEnd[id] != INVALID_FUNCTION )
		DV_Call(id, g_fStackEnd[id]);
	
	Call_StartForward(g_hOnStopLR);
	Call_PushCell(g_iInitialTeam[CS_TEAM_T][0]);
	Call_PushCell(g_iInitialTeam[CS_TEAM_CT][0]);	
	Call_Finish();
	
	if( g_iStackFlag[g_iDoingDV] & JB_BEACON ) {
		for (int i = 0; i < g_iInitialTeamCount[CS_TEAM_T]; i++)
			Effect_GlowStop(g_iInitialTeam[CS_TEAM_T][i]);
		for (int i = 0; i < g_iInitialTeamCount[CS_TEAM_CT]; i++)
			Effect_GlowStop(g_iInitialTeam[CS_TEAM_CT][i]);
	}
	
	DV_CleanTeams();
	g_iInitialTeamCount[CS_TEAM_CT] = g_iInitialTeamCount[CS_TEAM_T] = g_iCurrentTeamCount[CS_TEAM_T] = g_iCurrentTeamCount[CS_TEAM_CT] = 0;
	g_iDoingDV = -1;
}
void DV_Call(int id, Function func) {
	Call_StartFunction(g_hStackPlugin[id], func);
	if( g_iStackTeam[id][CS_TEAM_T] > 1 ) {
		Call_PushArray(g_iInitialTeam[CS_TEAM_T], g_iInitialTeamCount[CS_TEAM_T]);
		Call_PushCell(g_iInitialTeamCount[CS_TEAM_T]);
	}
	else if( g_iStackTeam[id][CS_TEAM_T] == 1 )
		Call_PushCell(g_iInitialTeamCount[CS_TEAM_T] > 0 ? g_iInitialTeam[CS_TEAM_T][0] : 0 );
	
	if( g_iStackTeam[id][CS_TEAM_CT] > 1 ) {
		Call_PushArray(g_iInitialTeam[CS_TEAM_CT], g_iInitialTeamCount[CS_TEAM_CT]);
		Call_PushCell(g_iInitialTeamCount[CS_TEAM_CT]);
	}
	else if( g_iStackTeam[id][CS_TEAM_CT] == 1 )
		Call_PushCell(g_iInitialTeamCount[CS_TEAM_CT] > 0 ? g_iInitialTeam[CS_TEAM_CT][0] : 0);
	Call_Finish();
}
// -------------------------------------------------------------------------------------------------------------------------------
public APLRes AskPluginLoad2(Handle hPlugin, bool isAfterMapLoaded, char[] error, int err_max) {
	RegPluginLibrary("JB_LastRequest");
	
	CreateNative("JB_CreateLastRequest", Native_JB_CreateLastRequest);
	CreateNative("JB_SetTeamCount", Native_JB_SetTeamCount);
	CreateNative("JB_AddClientInDV", Native_JB_AddClientInDV);
	CreateNative("JB_CeanTeam", Native_DV_CleanTeam);
	CreateNative("JB_End", Native_JB_End);
	CreateNative("JB_IsDvActive", Native_JB_IsDvActive);
	
	g_hPluginReady = CreateGlobalForward("JB_OnPluginReady", ET_Ignore);
	g_hOnStartLR = CreateGlobalForward("OnStartLR", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_hOnStopLR = CreateGlobalForward("OnStopLR", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
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
	g_iSorted[g_iStackCount] = g_iStackCount;
	
	SortCustom1D(g_iSorted, g_iStackCount+1, SortAscending);
	
	return g_iStackCount++;
}
public int SortAscending(int a, int b, const int[] array, Handle hdl) {
	return strcmp(g_cStackName[a], g_cStackName[b]);
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
public int Native_JB_AddClientInDV(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	int team = GetClientTeam(client);
	
	for (int i = 0; i < g_iInitialTeamCount[team]; i++)
		if( g_iInitialTeam[team][i] == client )
			return;
	
	g_iInitialTeam[team][g_iInitialTeamCount[team]] = client;
	g_iInitialTeamCount[team]++;
	
	if( IsPlayerAlive(client) ) {
		for (int i = 0; i < g_iCurrentTeamCount[team]; i++)
			if( g_iCurrentTeam[team][i] == client )
				return;
		g_iCurrentTeam[team][g_iCurrentTeamCount[team]] = client;
		g_iCurrentTeamCount[team]++;
	}

}
public int Native_JB_IsDvActive(Handle plugin, int numParams) {
	Handle pl = GetNativeCell(1);
	if( pl == INVALID_HANDLE ) {
		if( g_iDoingDV >= 0 )
			return view_as<int>(true);
	}
	else {
		if( g_iDoingDV >= 0 && g_hStackPlugin[g_iDoingDV] == pl )
			return view_as<int>(true);
	}
	return view_as<int>(false);
}


void Effect_Glow(int client, int r, int g, int b, int a) {
	static char model[PLATFORM_MAX_PATH];
	
	Entity_GetModel(client, model, sizeof(model));
	CPS_RemoveSkin(client);
	CPS_SetSkin(client, model, CPS_RENDER);
	
	int entity = CPS_GetSkin(client);
	SetEntProp(entity, Prop_Send, "m_bShouldGlow", true, true);
	SetEntProp(entity, Prop_Send, "m_nGlowStyle", 0);
	SetEntPropFloat(entity, Prop_Send, "m_flGlowMaxDist", 100000.0);
	
	int offset = GetEntSendPropOffs(entity, "m_clrGlow");
	SetEntData(entity, offset + 0, r, _, true);
	SetEntData(entity, offset + 1, g, _, true);
	SetEntData(entity, offset + 2, b, _, true);
	SetEntData(entity, offset + 3, a, _, true);
}

void Effect_GlowStop(int client) {
	int entity = CPS_GetSkin(client);
	if( entity > 0 )
		CPS_RemoveSkin(client);
}