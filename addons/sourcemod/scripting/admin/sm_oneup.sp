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

public void OnPluginStart() {
	RegAdminCmd("sm_oneup", Cmd_Respawn, ADMFLAG_KICK);
	RegAdminCmd("sm_hrespawn", Cmd_Respawn, ADMFLAG_KICK);
}
public Action Cmd_Respawn(int client, int args) {
	char arg[MAX_TARGET_LENGTH];
	GetCmdArg(1, arg, sizeof(arg));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count; bool tn_is_ml;
	if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED|COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	float vec[3];
	
	for (int i = 0; i < target_count; i++) {
		int target = target_list[i];
		int ragdoll = GetEntPropEnt(target, Prop_Send, "m_hRagdoll");
		if( ragdoll > 0 && IsValidEdict(ragdoll)) {
			Entity_GetAbsOrigin(ragdoll, vec);
			CS_RespawnPlayer(target);
			TeleportEntity(target, vec, NULL_VECTOR, NULL_VECTOR);
			ReplyToCommand(client, "%N a été respawn", target);
		}
	}
	
	return Plugin_Handled;
}