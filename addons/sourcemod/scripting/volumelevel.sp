#include <sourcemod>
#include <volumelevel>
#include <clientprefs>

Handle cookie_Volume;
float g_fVolume[MAXPLAYERS + 1];

public Plugin myinfo =
{
    name = "Volume Level",
    author = "Kriax",
    version = "1.0",
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_volume", Command_Volume);
	
	cookie_Volume = RegClientCookie("volume_level", "Niveau des snd", CookieAccess_Private);
}

public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int err_max) {
	RegPluginLibrary("VolumeLevel");
	
	CreateNative("Volume_GetLevel", Native_GetLevel);
}

public void OnClientCookiesCached(int client) {
	char szCookie[8];
	GetClientCookie(client, cookie_Volume, szCookie, sizeof(szCookie));
	
	g_fVolume[client] = StringToFloat(szCookie);
	
	if(g_fVolume[client] <= 0.0) {
		g_fVolume[client] = 0.10;
	}
}

public Action Command_Volume(int client, int args) {
	if(!IsClientInGame(client)) {
		return Plugin_Handled;
	}
	
	MenuVolume(client);
	
	return Plugin_Handled;
}

public void MenuVolume(int client) {
	Menu menu = new Menu(MenuHandler_Volume);
	menu.SetTitle("Volume Disco: %.1f", g_fVolume[client]);
	
	menu.AddItem("a", "Augmenter le volume", g_fVolume[client] >= 0.7 ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	menu.AddItem("s", "Diminuer le volume", g_fVolume[client] <= 0.2 ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	
	menu.ExitButton = true;
	menu.Display(client, 10);
}

public int MenuHandler_Volume(Menu menu, MenuAction action, int client, int param) {
	if(action == MenuAction_Select) {
		char szParam[2];
		GetMenuItem(menu, param, szParam, sizeof(szParam));
		
		if(szParam[0] == 'a') {
			g_fVolume[client] += 0.10;
		}
		if(szParam[0] == 's') {
			g_fVolume[client] -= 0.10;
		}
		
		char szCookie[8];
		FloatToString(g_fVolume[client], szCookie, sizeof(szCookie));
		SetClientCookie(client, cookie_Volume, szCookie);
		
		MenuVolume(client);
	}
	if(action == MenuAction_End) {
		delete menu;
	}
}

public int Native_GetLevel(Handle plugin, int numbParams) {
	return view_as<int>(g_fVolume[GetNativeCell(1)]);
}
