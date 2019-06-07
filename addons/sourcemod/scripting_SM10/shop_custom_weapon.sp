#include <sourcemod>
#include <sdktools>
#include <shop>
#include <smlib>
#include <custom_weapon_mod>

char g_szWeapons[MAX_ITEMS][PLATFORM_MAX_PATH];

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
	float pos[3], vel[3];
	int wpn = CWM_GetId(g_szWeapons[view_as<int>(item)]);
	if( wpn >= 0 )
		CWM_Spawn(wpn, client, pos, vel);
	return Plugin_Continue;
}
public void OnItemDrop(SC_Item item, int client) {
	float pos[3], vel[3];
	GetClientEyePosition(client, pos);
	
	vel[0] = Math_GetRandomFloat(-128.0, 128.0);
	vel[1] = Math_GetRandomFloat(-128.0, 128.0);
	vel[2] = Math_GetRandomFloat(0.0, 32.0);
	
	int wpn = CWM_GetId(g_szWeapons[view_as<int>(item)]);
	if( wpn >= 0 )
		CWM_Spawn(wpn, 0, pos, vel);
}
