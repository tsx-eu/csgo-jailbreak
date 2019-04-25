#pragma semicolon 1
#pragma tabsize 0

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <csgocolors>
#include <smlib>
#include <timer-stocks>
#include <timer-worldrecord>

#define PREFIX "{purple}[ {white}MG {purple}]"

public Plugin myinfo = {
	name = "[Server] Autorespawn & Other",
	author = "NeoX^",
	version = "1.5",
	description = "Autorespawn (with command & config file), Give knife on race&fight maps, Anti late spawn, Delete AFK Killer on Harero, 10k$, Change cvars values differs maps, Unlimited time to choose team, HUD Server Record",
};

File g_fileAutoRespawnConfig;
char g_szActualMapName[64], g_szSRRecord[64], g_szSRRecordName[64];
Handle g_hTimeForRespawn, g_hHudSyncSR, g_hTimerSyncHUD;
float g_fRespawnTime, g_fServerRecordTime;

ConVar g_cvRoundTime;
ConVar g_cvRoundTime_defuse;
ConVar g_cvRoundTime_hostage;
ConVar g_cvGravity;
ConVar g_cvAutoBhop;
ConVar g_cvTimeLimit;

public void OnPluginStart() {
	RegAdminCmd("sm_addrestime", Cmd_AddAutorespawnTime, ADMFLAG_ROOT);
	RegAdminCmd("sm_addknife", Cmd_AddKnife, ADMFLAG_ROOT);
	RegAdminCmd("sm_statauto", Cmd_StatAuto, ADMFLAG_VOTE);
	RegAdminCmd("sm_getrestime", Cmd_GetResTime, ADMFLAG_VOTE);
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_connect_full", Event_PlayerFullConnect);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post);

	HookConVarChange(FindConVar("mp_roundtime"), OnRoundTimeChanged);
	HookConVarChange(FindConVar("mp_roundtime_defuse"), OnRoundTimeChanged);
	HookConVarChange(FindConVar("mp_roundtime_hostage"), OnRoundTimeChanged);
	HookConVarChange(FindConVar("mp_maxrounds"), OnMaxRoundsChanged);
	HookConVarChange(FindConVar("mp_freezetime"), OnFreezeTimeChanged);
	HookConVarChange(FindConVar("sv_airaccelerate"), OnSvAirAccelerateChanged);
	HookConVarChange(FindConVar("bot_quota"), OnBotQuotaChanged);
	HookConVarChange(FindConVar("sv_full_alltalk"), OnFullAlltalkChanged);
	g_cvRoundTime = FindConVar("mp_roundtime");
	g_cvRoundTime_defuse = FindConVar("mp_roundtime_defuse");
	g_cvRoundTime_hostage = FindConVar("mp_roundtime_hostage");
	g_cvTimeLimit = FindConVar("mp_timelimit");
	g_cvGravity = FindConVar("sv_gravity");
	g_cvAutoBhop = FindConVar("sv_autobunnyhopping");

	g_hHudSyncSR = CreateHudSynchronizer();
}

public void OnMapStart() {
	GetCurrentMap(g_szActualMapName, sizeof(g_szActualMapName));

	g_fileAutoRespawnConfig = OpenFile("addons/sourcemod/configs/autorespawn.ini", "a+");
	if(g_fileAutoRespawnConfig == null) {
		SetFailState("Impossible d'ouvrir le fichier \"addons/sourcemod/configs/autorespawn.ini\" !");
		return;
	}

	char fileLine[128], mapName[64], timeRespawn;
	while(!IsEndOfFile(g_fileAutoRespawnConfig) && ReadFileLine(g_fileAutoRespawnConfig, fileLine, sizeof(fileLine))) {
		timeRespawn = BreakString(fileLine, mapName, sizeof(mapName));
		if(StrEqual(mapName, g_szActualMapName)) {
			g_fRespawnTime = StringToFloat(fileLine[timeRespawn]);
			break;
		}
		else
			g_fRespawnTime = -2.0;
	}

	if(g_fRespawnTime < 0.0)
		ServerCommand("sm plugins unload timer/timer-hud_csgo.smx");

	if(g_fRespawnTime >= 0.0)
		g_hTimerSyncHUD = CreateTimer(1.0, Timer_SyncHUDSR, _, TIMER_REPEAT);
}

public void OnMapEnd() {
	delete g_fileAutoRespawnConfig;
	FlashTimer(g_hTimerSyncHUD);
}

public void OnConfigsExecuted() {
	if(Valid_RunMap() && GetRoundTimesValue() != 60)
		SetRoundTimesValue(60);
	else if(!Valid_RunMap() && GetRoundTimesValue() != 20)
		SetRoundTimesValue(20);
}

public Action Cmd_AddAutorespawnTime(int client, int args) {
	if(args != 1) {
		ReplyToCommand(client, "Usage : sm_addrestime <time> (0 = infinite respawn, white = -2)");
		return Plugin_Handled;
	}

	if(g_fRespawnTime >= 0.0) {
		CPrintToChat(client, "%s Impossible de rajouter un temps de respawn, il en existe déjà un ! ({white}%f {purple}secondes)", PREFIX, g_fRespawnTime);
		return Plugin_Handled;
	}

	char buffer[16];
	GetCmdArgString(buffer, sizeof(buffer));
	int timeRespawn = StringToInt(buffer);

	if(timeRespawn >= 0) {
		WriteFileLine(g_fileAutoRespawnConfig, "\"%s\" %i", g_szActualMapName, timeRespawn);
		CPrintToChat(client, "%s Vous avez rajouté {white}%i {purple}seconde(s) de respawn pour la map {white}%s {purple}!", PREFIX, timeRespawn, g_szActualMapName);
		g_fRespawnTime = float(timeRespawn);
	}
	else 
		CPrintToChat(client, "%s Le temps de respawn doit être supérieur ou égal à 0 ! (0 = temps infini)", PREFIX);
	return Plugin_Handled;
}

public Action Cmd_AddKnife(int client, int args) {
	if(g_fRespawnTime != -1.0) {
		WriteFileLine(g_fileAutoRespawnConfig, "\"%s\" -1", g_szActualMapName);
		g_fRespawnTime = -1.0;
	}
	else
		CPrintToChat(client, "%s Les couteaux sont déjà autorisés sur cette map !", PREFIX);
	return Plugin_Handled;
}

public Action Cmd_StatAuto(int client, int args) {
	if(GetConVarInt(g_cvAutoBhop) == 1)
		SetConVarInt(g_cvAutoBhop, 0, false, false);
	else
		SetConVarInt(g_cvAutoBhop, 1, false, false);
}

public Action Cmd_GetResTime(int client, int args) {
	CPrintToChat(client, "%s Le temps d'autorespawn sur cette map est de : {white}%.0f {purple}secondes.", PREFIX, g_fRespawnTime);
	return Plugin_Handled;
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast) {
	if(g_fRespawnTime > 0.0) {
		g_hTimeForRespawn = CreateTimer(g_fRespawnTime, Timer_RespawnPlayerByTime);
		CPrintToChatAll("%s Le temps d'autorespawn est de {white}%.0f {purple}secondes !", PREFIX, g_fRespawnTime);
	}
	else if(Valid_RunMap())
		CPrintToChatAll("%s Vous serez respawn jusqu'à la fin de la partie en cas de mort.", PREFIX);

	if(StrEqual(g_szActualMapName, "mg_harero_v2")) {
		int afkTrigger = Entity_FindByName("afk", "trigger_multiple");
		AcceptEntityInput(afkTrigger, "Kill");
	}

	if(StrEqual(g_szActualMapName, "mg_100traps_v4_1")) {
		int buttonHelpGravity = Entity_FindByName("helpbutts2", "func_button");
		AcceptEntityInput(buttonHelpGravity, "Kill");
	}

	if(GetConVarInt(g_cvGravity) != 800)
		SetConVarInt(g_cvGravity, 800);
}

public Action Timer_RespawnPlayerByTime(Handle timer) {
	CPrintToChatAll("%s Vous n'êtes plus autorisé à respawn !", PREFIX);
	g_hTimeForRespawn = null;
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) {
	FlashTimer(g_hTimeForRespawn);
	if(GetConVarInt(g_cvAutoBhop) == 0)
		SetConVarInt(g_cvAutoBhop, 1, false, false);
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(Valid_Client(client) && GetClientTeam(client) > 1 && (Valid_RunMap() || g_hTimeForRespawn != null))
		CreateTimer(0.2, Timer_RespawnClient, client);
}

public Action Timer_RespawnClient(Handle timer, int client) {
	if(!Valid_Client(client))
		return Plugin_Handled;

	if(!(GetClientTeam(client) == CS_TEAM_T || GetClientTeam(client) == CS_TEAM_CT))
		return Plugin_Handled;

	if(IsPlayerAlive(client))
		return Plugin_Handled;

	if(Valid_RunMap()) {
		CS_RespawnPlayer(client);
		return Plugin_Handled;
	}
	else if(g_hTimeForRespawn != null) {
		CS_RespawnPlayer(client);
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(Valid_Client(client) && !IsFakeClient(client) && GetClientTeam(client) > 1 && GetPlayerWeaponSlot(client, CS_SLOT_KNIFE) == -1 && g_fRespawnTime >= -1.0) {
		GivePlayerItem(client, "weapon_knife");
		if(GetEntProp(client, Prop_Send, "m_iAccount") != 10000)
			SetEntProp(client, Prop_Send, "m_iAccount", 10000);
	}

	if(Valid_Client(client) && GetClientTeam(client) > 1) {
		if(g_fRespawnTime > 0.0 && g_hTimeForRespawn == null)
			CreateTimer(0.2, Timer_KillPlayer, client);
		else if(g_fRespawnTime == -2.0)
			DisarmClient(client);
	}
}

public Action Event_PlayerFullConnect(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(Valid_Client(client))
		SetEntPropFloat(client, Prop_Send, "m_fForceTeam", 3600.0);
}

public Action Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!Valid_Client(client))
		return Plugin_Handled;

	int team = GetEventInt(event, "team");
	int oldTeam = GetEventInt(event, "oldteam");
	if(team > 1 && oldTeam <= 1) {
		if(Valid_RunMap() || g_hTimeForRespawn != null)
			CreateTimer(0.2, Timer_RespawnClient, client);
	}
	return Plugin_Continue;
}

public Action Timer_KillPlayer(Handle timer, int client) {
	if(Valid_Client(client) && IsPlayerAlive(client) && g_fRespawnTime > 0.0 && g_hTimeForRespawn == null) {
		ForcePlayerSuicide(client);
		CPrintToChat(client, "%s Vous n'êtes pas autorisé à respawn !", PREFIX);
	}
}

public Action Timer_SyncHUDSR(Handle timer) {
	int iRecordID, iTotalRanks;
	Timer_GetStyleRecordWRStats(0, 0, iRecordID, g_fServerRecordTime, iTotalRanks);
	Timer_SecondsToTime(g_fServerRecordTime, g_szSRRecord, sizeof(g_szSRRecord), 2);
	Timer_GetRecordHolderName(0, 0, 1, g_szSRRecordName, sizeof(g_szSRRecordName));

	for(int i = 1; i <= MaxClients; i++) {
		if(Valid_Client(i)) {
			SetHudTextParams(0.01, 0.01, 1.0, 255, 255, 255, 255, 0, 0.0, 0.0, 0.0);
			if(g_fServerRecordTime > 0.0)
				ShowSyncHudText(i, g_hHudSyncSR, "SR: %s (%s)", g_szSRRecord, g_szSRRecordName);
			else
				ShowSyncHudText(i, g_hHudSyncSR, "SR: En cours ...");
		}
	}
}

public int OnTimerRecord(int client, int track, int style, float newTime, float bestTime, int currentRank, int newRank) {
	int iRecordID, iTotalRanks;
	Timer_GetStyleRecordWRStats(0, 0, iRecordID, g_fServerRecordTime, iTotalRanks);
	Timer_GetRecordHolderName(0, 0, 1, g_szSRRecordName, sizeof(g_szSRRecordName));

	if(newTime == g_fServerRecordTime)
		Timer_SecondsToTime(g_fServerRecordTime, g_szSRRecord, sizeof(g_szSRRecord), 2);
}

public void OnRoundTimeChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	if(Valid_RunMap() && StringToInt(newValue) < 60)
		SetConVarInt(convar, 60, false, false);
	else if(!Valid_RunMap() && StringToInt(newValue) < 20)
		SetConVarInt(convar, 20, false, false);
}

public void OnMaxRoundsChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	if(StringToInt(newValue) != 0)
		SetConVarInt(convar, 0, false, false);
}

public void OnFreezeTimeChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	if(StringToInt(newValue) != 2)
		SetConVarInt(convar, 2, false, false); 
}

public void OnSvAirAccelerateChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	if(StringToInt(newValue) != 2000)
		SetConVarInt(convar, 2000, false, false);
}

public void OnBotQuotaChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	if(StringToInt(newValue) != 0)
		SetConVarInt(convar, 0, false, false);
}

public void OnFullAlltalkChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	if(StringToInt(newValue) != 1)
		SetConVarInt(convar, 1, false, false);
}

int GetRoundTimesValue() {
	int value = GetConVarInt(g_cvRoundTime) + GetConVarInt(g_cvRoundTime_hostage) + GetConVarInt(g_cvRoundTime_defuse);
	return value/3;
}

void SetRoundTimesValue(int value) {
	if(GetConVarInt(g_cvRoundTime) != value)
		SetConVarInt(g_cvRoundTime, value, false, false);

	if(GetConVarInt(g_cvRoundTime_hostage) != value)
		SetConVarInt(g_cvRoundTime_hostage, value, false, false);

	if(GetConVarInt(g_cvRoundTime_defuse) != value)
		SetConVarInt(g_cvRoundTime_defuse, value, false, false);

	if(GetConVarInt(g_cvTimeLimit) != value)
		SetConVarInt(g_cvTimeLimit, value, false, false);
}

void FlashTimer(Handle &timer) {
	if(timer != null)
		delete timer;
	timer = null;
}

void DisarmClient(int id) {
	int index;
	for(int i = 0; i <= 6; i++) {
		if(i < 6 && (index = GetPlayerWeaponSlot(id, i)) != -1)
			RemovePlayerItem(id, index);
	}
}

bool Valid_RunMap() {
	if(RoundFloat(g_fRespawnTime) == 0)
		return true;
	return false;
}

bool Valid_Client(int id) {
	return (id > 0 && id <= MaxClients && IsClientInGame(id) && IsClientConnected(id) && !IsClientInKickQueue(id));
}