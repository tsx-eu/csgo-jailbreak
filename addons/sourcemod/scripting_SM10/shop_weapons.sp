#include <sourcemod>
#include <sdktools>
#include <shop>
#include <smlib>


char g_szWeapons[MAX_ITEMS][64];

void addWeapon(const char[] fullname, const char[] classname, int price) {
	SC_Item item = SC_Item(fullname, OnItemUse, OnItemDrop);
	item.Money = price;
	
	strcopy(g_szWeapons[view_as<int>(item)], sizeof(g_szWeapons[]), classname);
}

public void SC_OnPluginReady() {
	addWeapon("AK47", "weapon_ak47", 1200);
	addWeapon("M4A1", "weapon_m4a1", 1200);
}

public Action OnItemUse(SC_Item item, int client) {
	PrintToChatAll("%d", view_as<int>(item));
	int wpn = GivePlayerItem(client, g_szWeapons[view_as<int>(item)]);
	EquipPlayerWeapon(client, wpn);
	return Plugin_Continue;
}
public void OnItemDrop(SC_Item item, int client) {
	GivePlayerItem(client, g_szWeapons[view_as<int>(item)]);
}
