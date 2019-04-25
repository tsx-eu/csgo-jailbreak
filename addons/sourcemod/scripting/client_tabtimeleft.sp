#include <sourcemod>
#include <sdktools>

Handle g_hHudSync;

public void OnPluginStart() {
	g_hHudSync = CreateHudSynchronizer();
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2]) {
	static char szNextMap[32], buffer[128];
	static int lastTime = -1;
	
	if( IsFakeClient(client) )
		return Plugin_Continue;
	
	
	
	if(buttons & IN_SCORE) {
		int iTimeleft;
		GetMapTimeLeft(iTimeleft);
		
		if( lastTime != iTimeleft ) {
			lastTime = iTimeleft;
			
			GetNextMap(szNextMap, sizeof(szNextMap));
			if(iTimeleft <= 0)
				FormatEx(buffer, sizeof(buffer), "**** Timeleft ****\n* Dernière manche !\n\n**** Nextmap ****\n* %s", szNextMap);
			else if(iTimeleft < 60)
				FormatEx(buffer, sizeof(buffer), "**** Timeleft ****\n* %i seconde%s\n\n**** Nextmap ****\n* %s", iTimeleft, iTimeleft <= 1 ? "":"s", szNextMap);
			else if(iTimeleft <= 480)
				FormatEx(buffer, sizeof(buffer), "**** Timeleft ****\n* %i minute%s\n\n**** Nextmap ****\n* %s", iTimeleft/60, iTimeleft < 120 ? "":"s", szNextMap);
			else
				FormatEx(buffer, sizeof(buffer), "**** Timeleft ****\n* %i minutes", iTimeleft/60);		
		}

		SetHudTextParams(0.01, 0.4, 0.1, 255, 255, 255, 255, 0, 0.0, 0.0, 0.0);
		ShowSyncHudText(client, g_hHudSync, buffer);
		return Plugin_Continue;
	}
	return Plugin_Continue;
}
