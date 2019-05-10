#if defined _autores_time_included
 #endinput
#endif
#define _autores_time_included

float g_fResTime = -10.0;
File g_fileAutoResConfig;
char g_szCurrentMap[64];

stock void SetAutoRespawnTime() {
	g_fileAutoResConfig = OpenFile("addons/sourcemod/configs/autorespawn.ini", "a+");
	if(g_fileAutoResConfig == null) {
		SetFailState("Impossible d'ouvrir le fichier \"addons/sourcemod/configs/autorespawn.ini\" !");
		return;
	}

	char fileLine[128], mapName[64], timeRespawn;
	GetCurrentMap(g_szCurrentMap, sizeof(g_szCurrentMap));
	while(!IsEndOfFile(g_fileAutoResConfig) && ReadFileLine(g_fileAutoResConfig, fileLine, sizeof(fileLine))) {
		timeRespawn = BreakString(fileLine, mapName, sizeof(mapName));
		if(StrEqual(mapName, g_szCurrentMap)) {
			g_fResTime = StringToFloat(fileLine[timeRespawn]);
			break;
		}
		else
			g_fResTime = -2.0;
	}
	delete g_fileAutoResConfig;
}

stock float GetAutoRespawnTime() {
	if(g_fResTime != -10.0)
		return g_fResTime;
	else {
		SetAutoRespawnTime();
		return GetAutoRespawnTime();
	}
}

stock bool IsMultigameMap() {
	if(GetAutoRespawnTime() == -2)
		return true;
	return false;
}

stock bool IsFightMap() {
	if(GetAutoRespawnTime() == -1)
		return true;
	return false;
}

stock bool IsRunMap() {
	if(GetAutoRespawnTime() == 0)
		return true;
	return false;
}

stock bool IsTimerMap() {
	if(GetAutoRespawnTime() >= 0)
		return true;
	return false;
}

stock bool IsMapNameEqual(const char[] mapName) {
	if(StrEqual(g_szCurrentMap, mapName))
		return true;
	return false;
}