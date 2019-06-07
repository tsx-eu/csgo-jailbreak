#include <sourcemod>
#include <sdktools>
#include <shop>
#include <smlib>

public void SC_OnPluginReady() {
	SC_Item item = SC_Item("Healing Potion", OnItemUse);
	item.Money = 500;
	item.Stack = 3;
	item.SetModel("models/dh/powerup/potion_1.mdl", 0.5);
}

public Action OnItemUse(SC_Item itemId, int client) {
	int health = GetClientHealth(client);
	
	if( health >= Entity_GetMaxHealth(client) )
		return Plugin_Handled;
	
	health += 25;
	if( health > Entity_GetMaxHealth(client) )
		health = Entity_GetMaxHealth(client);
	
	SetEntityHealth(client, health);
	return Plugin_Continue;
}
