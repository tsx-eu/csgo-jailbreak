#include <sourcemod>
#include <sdktools>
#include <autores_time>
#include <smlib>

public Plugin myinfo = {
	name = "[Server] Gestion autobhop",
	author = "NeoX^ - Rebel's Corporation",
	version = "1.0",
	description = "Changer les valeurs de l'autobhop selon les maps",
};

ConVar g_cvAutoBhop;
Database g_hTimerDatabase = null;

public void OnPluginStart() {
	HookEvent("round_start", Event_OnRoundStart);
	g_cvAutoBhop = FindConVar("sv_autobunnyhopping");

	Database.Connect(Timer_Database, "timer");
	RegAdminCmd("sm_addbutton", Cmd_AddButton, ADMFLAG_ROOT);
	RegAdminCmd("sm_deletebutton", Cmd_DeleteButton, ADMFLAG_ROOT);
}

public void OnMapStart() {
	SetAutoRespawnTime();
}

public void OnPluginEnd() {
	delete g_hTimerDatabase;
}

public void Timer_Database(Database db, const char[] error, any data) {
	if(db == null)
		LogError("Database failure: %s", error);
	else {
		g_hTimerDatabase = db;
		g_hTimerDatabase.Query(T_FailedQuery, "CREATE TABLE IF NOT EXISTS `timer`.`buttons` ( `map` VARCHAR(64) NOT NULL , `button_hid` INT NOT NULL);");
	}
}

public void T_FailedQuery(Database db, DBResultSet results, const char[] error, any data) {
	if(results == null) {
		LogError("T_FailedQuery failed ! Error : %s", error);
		return;
	}
}

public Action Cmd_AddButton(int client, int args) {
	int entity = GetClientAimTarget(client, false);
	if(entity != -1) {
		if(FindEntityByClassname(entity, "func_button") != -1) {
			int hammerID = GetEntProp(entity, Prop_Data, "m_iHammerID", 32);
			char buffer[128];
			FormatEx(buffer, sizeof(buffer), "INSERT INTO `buttons` (`map`, `button_hid`) VALUES ('%s', '%i')", g_szCurrentMap, hammerID);
			g_hTimerDatabase.Query(T_CheckInsertQuery, buffer, client);
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}

public void T_CheckInsertQuery(Database db, DBResultSet results, const char[] error, any client) {
	if(results == null) {
		LogError("T_CheckInsertQuery failed : %s", error);
		return;
	}
	PrintToChat(client, "Le bouton a été ajouté avec succès !");
}

public Action Cmd_DeleteButton(int client, int args) {
	int entity = GetClientAimTarget(client, false);
	if(entity != -1) {
		if(FindEntityByClassname(entity, "func_button") != -1) {
			int hammerID = GetEntProp(entity, Prop_Data, "m_iHammerID", 32);
			char buffer[128];
			FormatEx(buffer, sizeof(buffer), "DELETE FROM `buttons` WHERE `map` = '%s' AND `button_hid` = %i", g_szCurrentMap, hammerID);
			g_hTimerDatabase.Query(T_CheckDeleteQuery, buffer, client);
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}

public void T_CheckDeleteQuery(Database db, DBResultSet results, const char[] error, any client) {
	if(results == null) {
		LogError("T_CheckDeleteQuery failed : %s", error);
		return;
	}
	PrintToChat(client, "Le bouton a été supprimé avec succès !");
}

public Action Event_OnRoundStart(Event event, const char[] name, bool dontBroadcast) {
	if(!IsBlackListedMap()) {
		if(IsMultigameMap()) {
			if(GetConVarInt(g_cvAutoBhop) != 0)
				SetConVarInt(g_cvAutoBhop, 0, false, false);

			char buffer[128];
			FormatEx(buffer, sizeof(buffer), "SELECT `button_hid` FROM `buttons` WHERE `map` = '%s'", g_szCurrentMap);
			g_hTimerDatabase.Query(T_CheckButtonQuery, buffer);
		}

		if(IsFightMap()) {
			if(GetConVarInt(g_cvAutoBhop) != 0)
				SetConVarInt(g_cvAutoBhop, 0, false, false);
		}

		if(IsTimerMap()) {
			if(GetConVarInt(g_cvAutoBhop) != 1)
				SetConVarInt(g_cvAutoBhop, 1, false, false);
		}
	}
	else {
		if(GetConVarInt(g_cvAutoBhop) != 1)
			SetConVarInt(g_cvAutoBhop, 1, false, false);
	}
}

public void T_CheckButtonQuery(Database db, DBResultSet results, const char[] error, any data) {
	if(results == null) {
		LogError("T_CheckButtonQuery failed : %s", error);
		return;
	}

	while(results.FetchRow()) {
		int hammerID = results.FetchInt(0);
		int button = Entity_FindByHammerId(hammerID);
		HookSingleEntityOutput(button, "OnPressed", OnButtonPressed);
	}
}

public void OnButtonPressed(const char[] output, int caller, int activator, float delay) {
	if(GetConVarInt(g_cvAutoBhop) != 1)
		SetConVarInt(g_cvAutoBhop, 1, false, false);
}

bool IsBlackListedMap() {
	if(IsMapNameEqual("mg_ka_trains_detach") || 
		IsMapNameEqual("mg_oaks_cruiseship_v2_go") ||
		IsMapNameEqual("mg_jacks_bhop_battle_final_fix") ||
		IsMapNameEqual("mg_koga73_multigames_e") ||
		IsMapNameEqual("mg_lt_galaxy_csgo_v1"))
		return true;
	return false;
}