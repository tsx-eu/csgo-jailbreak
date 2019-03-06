#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <gift>
#include <smlib>

#pragma newdecls required

char g_szCache[MAX_GIFT + 1][128];

public void OnPluginStart() {
	int client = 1;
	Menu menu = CreateMenu(MenuHandler_Gift);
	menu.SetTitle("Liste des gifts");
    
	char tmp[8];
	int sorted[MAX_GIFT+1];
	int gifts = Gift_GetNumberGift();
	
	for( int i = 1; i <= gifts; i++ ) {
		Gift_GetName(i, g_szCache[i], sizeof(g_szCache[]));
		sorted[i-1] = i;
	}
	
	SortCustom1D(sorted, gifts, SortAscending);
	
	for (int i = 0; i < gifts; i++ ) {
		Format(tmp, sizeof(tmp), "%d", sorted[i]);
		menu.AddItem(tmp, g_szCache[sorted[i]]);
	}

	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}
public int SortAscending(int a, int b, const int[] array, Handle hdl) {
	return strcmp(g_szCache[a], g_szCache[b]);
}
public int MenuHandler_Gift(Handle menu, MenuAction action, int clients, int param) {
}