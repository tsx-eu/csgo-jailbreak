#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#pragma newdecls required

public Plugin myinfo = {
	name = "Entity Manager",
	author = "KoSSoLaX`",
	description = "Help to remove useless props on the map",
	version = "1.0",
	url = "zaretti.be"
};

#define MAX_ENTITY 2048
Handle g_hBDD;

public void OnPluginStart() {
	HookEvent("round_start", 		EventRoundStart, EventHookMode_Post);
	
	RegAdminCmd("sm_entity_delete", Cmd_AdminDelete, ADMFLAG_ROOT);
	RegAdminCmd("sm_entity_remove", Cmd_AdminDelete, ADMFLAG_ROOT);
}

public void OnMapStart() {
	Handle KV = CreateKeyValues("sql");
	
	KvSetString(KV, "driver",	"mysql");
	KvSetString(KV, "host",		"localhost");
	KvSetString(KV, "database",	"serverother");
	KvSetString(KV,	"user",		"serverother");
	KvSetString(KV,	"pass",		"iBEpewupbB");
	KvSetString(KV,	"port",		"3306");
	
	char error[1024];
	g_hBDD = SQL_ConnectCustom(KV, error, sizeof(error), true);
	
	if (g_hBDD == INVALID_HANDLE)
		SetFailState("Connexion impossible: %s", error);
	delete KV;
}
public void LoadMapData(Handle owner, Handle hQuery, const char[] error, any none) {
	int entity[MAX_ENTITY], count = 0;
	
	while (SQL_FetchRow(hQuery)) {		
		entity[count++] = SQL_FetchInt(hQuery, 0);
	}
	
	for (int j = MaxClients; j < MAX_ENTITY; j++) {
		int uniqId = GetEntProp(j, Prop_Data, "m_iHammerID");
		
		for (int i = count-1; i < 0; i--) {
			if( entity[i] == uniqId ) {
				count--;
				AcceptEntityInput(j, "KillHierarchy");
				break;
			}
		}
	}
}
public void OnMapEnd() {
	delete g_hBDD;
}
public Action EventRoundStart(Handle ev, const char[] name, bool bd) {
	char sql[1024], map[128];
	GetCurrentMap(map, sizeof(map));
	
	Format(sql, sizeof(sql), "SELECT `entity` FROM `map_entity` WHERE `map`='%s';", map);
	SQL_TQuery(g_hBDD, LoadMapData, sql);
}

// ------------------------------------------------------------------------------------------

public Action Cmd_AdminDelete(int client, int args) {
	int entity = GetClientAimTarget(client, false);
	
	if( !IsValidProp(entity) ) {
		ReplyToCommand(client, "Veuillez viser un props valide");
		return Plugin_Handled;
	}
	
	int uniqId = GetEntProp(entity, Prop_Data, "m_iHammerID");
	AcceptEntityInput(entity, "Kill");
	
	char sql[1024], map[128];
	GetCurrentMap(map, sizeof(map));
	Format(sql, sizeof(sql), "INSERT INTO `map_entity` (`id`, `map`, `entity`) VALUES (NULL, '%s', '%d');", map, uniqId);
	
	SQL_TQuery(g_hBDD, SQL_QueryCallBack, sql);
	return Plugin_Handled;
}

// ------------------------------------------------------------------------------------------

public bool IsValidProp(int entity) {
	if( entity < MaxClients )
		return false;
	
	if( HasEntProp(entity, Prop_Data, "m_iHammerID") )
		return false;
	
	// TODO: Ajouter d'autres restriction ?
	
	return true;
}

public void SQL_QueryCallBack(Handle owner, Handle handle, const char[] error, any data) {
	if( handle == INVALID_HANDLE ) {
		LogError("[SQL] [ERROR] %s", error);
	}
}