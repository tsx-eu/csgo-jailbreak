#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <csgocolors>
#include <emitsoundany>
#include <cstrike>

#pragma newdecls required

#include <jb_lastrequest>


public Plugin myinfo = {
	name = "Last Request",
	author = "KoSSoLaX",
	description = "Système de DV",
	version = "1.0.0",
	url = "zaretti.be"
};

#define MAX_PLAYERS 65
int g_iStackCount = 0;

char g_cStackName[MAX_LR][128];
Function g_fStackCondition[MAX_LR], g_fStackStart[MAX_LR], g_fStackEnd[MAX_LR];
int g_bStackFlag[MAX_LR];
Handle g_hPluginReady = INVALID_HANDLE;
bool g_bDoingDV, g_bDoingUntilRoundEnd;


public void OnPluginStart() {
	RegConsoleCmd("sm_dv", 			cmd_DV);
	RegConsoleCmd("sm_lr", 			cmd_DV);
	RegConsoleCmd("sm_lastrequest", cmd_DV);
	
	
	Call_StartForward(g_hPluginReady);
	Call_Finish();
}
// -------------------------------------------------------------------------------------------------------------------------------
public Action cmd_DV(int client, int args) {
	if( GetClientTeam(client) != CS_TEAM_T || !IsPlayerAlive(client) || DV_CAN() == -1 ) {
		CPrintToChat(client, MOD_TAG ... "Vous n'avez {red}pas{default} le droit d'utiliser le " ... MOD_TAG_START ... "!dv" ... MOD_TAG_END ... " maintenant.");
		return Plugin_Handled;
	}
	
	displayDV(client);
	return Plugin_Handled;
}
void displayDV(int client) {
	static char tmp[8];
	
	Menu menu = new Menu(menuDV);
	menu.SetTitle("Choisissez votre dernière volonté");
	
	for (int i = 0; i < g_iStackCount; i++) {
		Format(tmp, sizeof(tmp), "%d", i);
		
		bool can;
		if( g_fStackCondition[i] == INVALID_FUNCTION ) {
			can = true;
		}
		else {
			Call_StartFunction(INVALID_HANDLE, g_fStackCondition[i]);
			Call_PushCell(client);
			Call_Finish(can);
		}
		
		menu.AddItem(tmp, g_cStackName[i], can ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	}
	
	menu.ExitButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
	
	PrintHintTextToAll("%N\nchoisis sa dernière volonté", client);
	EmitSoundToAllAny("ui/bonus_alert_start.wav");
}
public int menuDV(Handle menu, MenuAction action, int client, int params) {
	if( action == MenuAction_Select ) {
		char options[64], tmp[2][64];
		GetMenuItem(menu, params, options, sizeof(options));
		int id = StringToInt(options);
		
		if( g_bStackFlag[id] & JB_SHOULD_SELECT_CT ) {
			Handle menu2 = CreateMenu(menuDVchoose);
			SetMenuTitle(menu2, "Choisissez un CT");
			
			for (int i = 1; i <= MaxClients; i++) {
				if( IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_CT ) {
					
					Format(tmp[0], sizeof(tmp[]), "%d %d", id, i);
					Format(tmp[1], sizeof(tmp[]), "%N", i);
					
					AddMenuItem(menu2, tmp[0], tmp[1]);
				}
			}
			
			SetMenuExitButton(menu2, false);
			DisplayMenu(menu2, client, MENU_TIME_FOREVER);
		}
		else {			
			DV_Start(id, client);
		}
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
	return;
}
public int menuDVchoose(Handle menu, MenuAction action, int client, int params) {
	if( action == MenuAction_Select ) {
		char options[64], data[2][16];
		GetMenuItem(menu, params, options, sizeof(options));
		ExplodeString(options, " ", data, sizeof(data), sizeof(data[]));
		
		int targets[MAX_PLAYERS];
		targets[0] = StringToInt(data[1]);
		
		DV_Start(StringToInt(data[0]), client, targets, 1);		
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
}
// -------------------------------------------------------------------------------------------------------------------------------
int DV_CAN() {
	if( g_bDoingDV )
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
int DV_Start(int id, int client, int targets[MAX_PLAYERS] = {0, ...}, int targetCount = 0) {
	PrintHintTextToAll("Dernière volonté:\n%s", g_cStackName[id]);
		
	if( targetCount > 0 )
		CPrintToChatAllEx(client, MOD_TAG ... "{teamcolor}%N{default} a choisis de faire sa DV " ... MOD_TAG_START ... "%s" ... MOD_TAG_END ... " contre " ... MOD_TAG_START ... "%N" ... MOD_TAG_END ... ".", client, g_cStackName[id], targets[0]);
	else
		CPrintToChat(client, MOD_TAG ... "{blue}%N{default} a choisis sa dernière volontée: " ... MOD_TAG_START ... "%s" ... MOD_TAG_END ... ".", client,  g_cStackName[id]);
	
	g_bDoingDV = true;
	g_bDoingUntilRoundEnd = view_as<bool>(g_bStackFlag[id] & JB_RUN_UNTIL_END);
	
	if( g_fStackStart[id] != INVALID_FUNCTION ) {
		Call_StartFunction(INVALID_HANDLE, g_fStackStart[id]);
		Call_PushCell(client);
		Call_PushArray(targets, targetCount);
		Call_PushCell(targetCount);
		Call_Finish();
		
		Call_StartFunction(INVALID_HANDLE, g_fStackStart[id]);
		Call_PushCell(client);
		Call_PushCell(targets[0]);
		Call_Finish();
	}
}
int DV_Stop(int id, int client, int targets[MAX_PLAYERS] = {0, ...}, int targetCount = 0) {
	
	CPrintToChatAll("%s La {blue}DV{default} est terminée.", MOD_TAG);
	
	g_bDoingDV = false;
	g_bDoingUntilRoundEnd = false;
	
	if( g_fStackStop[id] != INVALID_FUNCTION ) {
		Call_StartFunction(INVALID_HANDLE, g_fStackStop[id]);
		Call_PushCell(client);
		Call_PushArray(targets, targetCount);
		Call_PushCell(targetCount);
		Call_Finish();
		
		Call_StartFunction(INVALID_HANDLE, g_fStackStop[id]);
		Call_PushCell(client);
		Call_PushCell(targets[0]);
		Call_Finish();
	}
}

// -------------------------------------------------------------------------------------------------------------------------------
public APLRes AskPluginLoad2(Handle hPlugin, bool isAfterMapLoaded, char[] error, int err_max) {
	RegPluginLibrary("JB_LastRequest");
	
	CreateNative("JB_CreateLastRequest", Native_JB_CreateLastRequest);
	g_hPluginReady = CreateGlobalForward("JB_OnPluginReady", ET_Ignore);
}
public int Native_JB_CreateLastRequest(Handle plugin, int numParams) {

	GetNativeString(1, g_cStackName[g_iStackCount], sizeof(g_cStackName[]));
	g_bStackFlag[g_iStackCount] = GetNativeCell(2);
	g_fStackCondition[g_iStackCount] = GetNativeFunction(3);
	g_fStackStart[g_iStackCount] = GetNativeFunction(4);
	g_fStackEnd[g_iStackCount] = GetNativeFunction(5);
	
	return g_iStackCount++;
}