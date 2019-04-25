#include <sourcemod>
#include <sdktools>

Handle g_hHudSync;

public void OnPluginStart() {
	g_hHudSync = CreateHudSynchronizer();
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2]) {
	if(!Valid_Client(client))
		return Plugin_Handled;

	if(buttons & IN_SCORE) {
		int iTimeleft;
		char szNextMap[32], buffer[128];
		GetMapTimeLeft(iTimeleft);
		GetNextMap(szNextMap, sizeof(szNextMap));
		if(iTimeleft <= 0)
			FormatEx(buffer, sizeof(buffer), "Dernière manche !\nNextmap : %s", szNextMap);
		else if(iTimeleft < 60)
			FormatEx(buffer, sizeof(buffer), "Timeleft: %is\nNextmap : %s", iTimeleft, szNextMap);
		else if(iTimeleft <= 480)
			FormatEx(buffer, sizeof(buffer), "Timeleft: %im\nNextmap : %s", iTimeleft/60, szNextMap);
		else if(iTimeleft > 540)
			FormatEx(buffer, sizeof(buffer), "Timeleft: %im", iTimeleft/60);

		SetHudTextParams(0.01, 0.4, 0.1, 255, 255, 255, 255, 0, 0.0, 0.0, 0.0);
		ShowSyncHudText(client, g_hHudSync, buffer);
		return Plugin_Continue;
	}
	return Plugin_Continue;
}

bool Valid_Client(int id) {
	return (id > 0 && id <= MaxClients && IsClientInGame(id) && IsClientConnected(id) && !IsClientInKickQueue(id));
}