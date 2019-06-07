#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <smlib>

#pragma newdecls required

public Plugin myinfo = {
	name = "One UP",
	author = "KoSSoLaX",
	description = "ReSpawn sur le cadavre",
	version = "1.1",
	url = "zaretti.be"
};

float g_flLastPosition[65][3];
bool g_bLastPosition[65];

public void OnPluginStart() {
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_oneup", Cmd_Respawn, ADMFLAG_KICK);
	RegAdminCmd("sm_hrespawn", Cmd_Respawn, ADMFLAG_KICK);
	
	HookEvent("player_death", 		EventDeath, 		EventHookMode_Pre);
}
public void OnClientPostAdminCheck(int client) {
	g_bLastPosition[client] = false;
}
public Action EventDeath(Handle ev, const char[] name, bool broadcast) {
	int client = GetClientOfUserId(GetEventInt(ev, "userid"));
	Entity_GetAbsOrigin(client, g_flLastPosition[client]);
	g_bLastPosition[client] = true;
}
public Action Cmd_Respawn(int client, int args) {
	char arg[MAX_TARGET_LENGTH];
	GetCmdArg(1, arg, sizeof(arg));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count; bool tn_is_ml;
	if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED|COMMAND_FILTER_DEAD, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (int i = 0; i < target_count; i++) {
		int target = target_list[i];
		CS_RespawnPlayer(target);
		if( g_bLastPosition[client] )
			TeleportEntity(target, g_flLastPosition[client], NULL_VECTOR, NULL_VECTOR);
		ReplyToCommand(client, "%N a été respawn", target);
	}
	
	return Plugin_Handled;
}