#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <shop>
#include <smlib>

enum struct SC_Data {
	char name[PLATFORM_MAX_PATH];
	int price;
	int stack;
	int weight;
	int flags;
	float modelScale;
	char model[PLATFORM_MAX_PATH];
	Handle plugin;
	SC_OnItemUse OnUse;
	SC_OnItemUse OnDrop;
}

int g_iItemsCount;
SC_Data g_dItems[MAX_ITEMS];


enum struct SC_ItemData {
	int itemId;
	int itemAmount;
}


int g_cItemsCount[65], g_cItemsWeight[65];
SC_ItemData g_cItems[65][MAX_ITEMS];

Handle g_hPluginReady;

public void OnPluginStart() {
	RegConsoleCmd("sm_shop", CmdShop);
	
	HookEvent("player_death", 		EventDeath, 		EventHookMode_Pre);
	HookEvent("player_spawn", 		EventSpawn, 		EventHookMode_Post);
	
	RegAdminCmd("sm_give_item",		CmdItem,			ADMFLAG_BAN);
}
public void OnMapStart() {
	g_iItemsCount = 0;
	Call_StartForward(g_hPluginReady);
	Call_Finish();
}
public Action CmdItem(int client, int args) {
	char buffer[12];
	GetCmdArg(1, buffer, sizeof(buffer));
	SC_GivePlayerItem(client, StringToInt(buffer));
	return Plugin_Handled;
}
public Action CmdShop(int client, int args) {
	displayItem(client);
	return Plugin_Handled;
}
void displayItem(int client) {
	static char tmp1[32], tmp2[64];
	
	if( g_cItemsCount[client] <= 0 )
		return;
	
	Menu menu = new Menu(menuItem);
	menu.SetTitle("Your items\n");
	
	for (int i = 0; i < g_cItemsCount[client]; i++) {
		
		int itemId = g_cItems[client][i].itemId;
		int tokken = i + (itemId<<16);
		
		Format(tmp1, sizeof(tmp1), "%d", tokken);
		Format(tmp2, sizeof(tmp2), "%dx %s", g_cItems[client][i].itemAmount, g_dItems[itemId].name);
		
		menu.AddItem(tmp1, tmp2);
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
}
public int menuItem(Menu menu, MenuAction action, int client, int params) {
	static char options[64];
	if( action == MenuAction_Select ) {
		GetMenuItem(menu, params, options, sizeof(options));
		int tokken = StringToInt(options);
		int i = tokken & 0xFF;
		int itemId = (tokken >> 16);
		
		if( g_cItems[client][i].itemId != itemId ) {
			displayItem(client);
			return;
		}
		
		Action can;
		
		Call_StartFunction(g_dItems[itemId].plugin, g_dItems[itemId].OnUse);
		Call_PushCell(itemId);
		Call_PushCell(client);
		Call_Finish(can);
		
		if( can != Plugin_Continue ) {
			displayItem(client);
			return;
		}
		
		g_cItemsWeight[client] -= g_dItems[itemId].weight;
		g_cItems[client][i].itemAmount--;
		if( g_cItems[client][i].itemAmount <= 0 ) {
			for (int j = i+1; j < g_cItemsCount[client]; j++)
				g_cItems[client][j - 1] = g_cItems[client][j];
			g_cItemsCount[client]--;
		}
		
		displayItem(client);
	}
	else if( action == MenuAction_Cancel && params == MenuCancel_Interrupted ) {
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
	return;
}
// -------------------------------------------------------------------------------------------------------------------------------
public Action EventSpawn(Handle ev, const char[] name, bool broadcast) {
	int client = GetClientOfUserId(GetEventInt(ev, "userid"));
	
	g_cItemsWeight[client] = 0;
	g_cItemsCount[client] = 0;
}
public Action EventDeath(Handle ev, const char[] name, bool broadcast) {
	int client = GetClientOfUserId(GetEventInt(ev, "userid"));
	
	float src[3], vel[3];
	GetClientEyePosition(client, src);
	
	for (int i = 0; i < g_cItemsCount[client]; i++) {
		int itemId = g_cItems[client][i].itemId;
		
		for (int j = 0; j < g_cItems[client][i].itemAmount; j++) {
			
			if( g_dItems[itemId].model[0] == 0 ) {
				Call_StartFunction(g_dItems[itemId].plugin, g_dItems[itemId].OnDrop);
				Call_PushCell(itemId);
				Call_PushCell(client);
				Call_Finish();
			}
			else {
				vel[0] = Math_GetRandomFloat(-128.0, 128.0);
				vel[1] = Math_GetRandomFloat(-128.0, 128.0);
				vel[2] = Math_GetRandomFloat(0.0, 64.0);
				SC_SpawnItem(itemId, src, vel);
			}
		}
	}
	g_cItemsWeight[client] = 0;
	g_cItemsCount[client] = 0;
}
public Action OnTouch(int entity, int client) {
	static char classname[64];

	if( client > 0 && client <= MaxClients ) {
		GetEdictClassname(entity, classname, sizeof(classname));
		ReplaceString(classname, sizeof(classname), WORLDNAME, "");
		int id = StringToInt(classname);
		
		if( SC_GivePlayerItem(client, id) )
			AcceptEntityInput(entity, "Kill");
	}
	
	return Plugin_Handled;
}
// -------------------------------------------------------------------------------------------------------------------------------
public APLRes AskPluginLoad2(Handle hPlugin, bool isAfterMapLoaded, char[] error, int err_max) {
	RegPluginLibrary("SC_Shop");
	
	CreateNative("SC_Create",			Native_SC_Create);
	CreateNative("SC_SetItemPrice",		Native_SC_SetItemPrice);
	CreateNative("SC_GetItemPrice",		Native_SC_GetItemPrice);
	CreateNative("SC_SetItemMaxStack",	Native_SC_SetItemMaxStack);
	CreateNative("SC_GetItemMaxStack",	Native_SC_GetItemMaxStack);
	CreateNative("SC_SetItemWeight",	Native_SC_SetItemWeight);
	CreateNative("SC_GetItemWeight",	Native_SC_GetItemWeight);
	CreateNative("SC_SetItemFlags",		Native_SC_SetItemFlags);
	CreateNative("SC_GetItemFlags",		Native_SC_GetItemFlags);
	CreateNative("SC_SetItemModel",		Native_SC_SetItemModel);
	CreateNative("SC_GetItemModel",		Native_SC_GetItemModel);
	
	CreateNative("SC_GivePlayerItem",	Native_SC_GivePlayerItem);
	CreateNative("SC_SpawnItem",		Native_SC_SpawnItem);
	
	g_hPluginReady = CreateGlobalForward("SC_OnPluginReady", ET_Ignore);
}
public int Native_SC_Create(Handle plugin, int numParams) {
	GetNativeString(1, g_dItems[g_iItemsCount].name, sizeof(g_dItems[].name));
	
	g_dItems[g_iItemsCount].price = 0;
	g_dItems[g_iItemsCount].stack = 1;
	g_dItems[g_iItemsCount].weight = 0;
	g_dItems[g_iItemsCount].flags = 0;
	g_dItems[g_iItemsCount].model[0] = 0;
	g_dItems[g_iItemsCount].modelScale = 1.0;
	g_dItems[g_iItemsCount].plugin = plugin;
	g_dItems[g_iItemsCount].OnUse = view_as<SC_OnItemUse>(GetNativeFunction(2));
	g_dItems[g_iItemsCount].OnDrop = view_as<SC_OnItemUse>(GetNativeFunction(3));
	
	return g_iItemsCount++;
}
public int Native_SC_SetItemPrice(Handle plugin, int numParams) {
	g_dItems[GetNativeCell(1)].price = GetNativeCell(2);
}
public int Native_SC_GetItemPrice(Handle plugin, int numParams) {
	return g_dItems[GetNativeCell(1)].price;
}
public int Native_SC_SetItemMaxStack(Handle plugin, int numParams) {
	g_dItems[GetNativeCell(1)].stack = GetNativeCell(2);
}
public int Native_SC_GetItemMaxStack(Handle plugin, int numParams) {
	return g_dItems[GetNativeCell(1)].stack;
}
public int Native_SC_SetItemWeight(Handle plugin, int numParams) {
	g_dItems[GetNativeCell(1)].weight = GetNativeCell(2);
}
public int Native_SC_GetItemWeight(Handle plugin, int numParams) {
	return g_dItems[GetNativeCell(1)].weight;
}
public int Native_SC_SetItemFlags(Handle plugin, int numParams) {
	g_dItems[GetNativeCell(1)].flags = GetNativeCell(2);
}
public int Native_SC_GetItemFlags(Handle plugin, int numParams) {
	return g_dItems[GetNativeCell(1)].flags;
}
public int Native_SC_SetItemModel(Handle plugin, int numParams) {
	GetNativeString(2, g_dItems[GetNativeCell(1)].model, sizeof(g_dItems[].model));
	g_dItems[GetNativeCell(1)].modelScale = GetNativeCell(3);
}
public int Native_SC_GetItemModel(Handle plugin, int numParams) {
	SetNativeString(2, g_dItems[GetNativeCell(1)].model, sizeof(g_dItems[].model), GetNativeCell(3));
	return view_as<int>(g_dItems[GetNativeCell(1)].modelScale);
}
// -------------------------------------------------------------------------------------------------------------------------------
public int Native_SC_GivePlayerItem(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	int itemId = GetNativeCell(2);
	
	if( g_cItemsWeight[client]+g_dItems[itemId].weight > MAX_WEIGHT ) {
		return view_as<int>(false);
	}
	
	int c = g_cItemsCount[client];
	
	for (int i = 0; i < c; i++) {
		if( g_cItems[client][i].itemId == itemId ) {
			
			if( g_cItems[client][i].itemAmount >= g_dItems[itemId].stack )
				return view_as<int>(false);
			
			g_cItems[client][i].itemAmount++;
			g_cItemsWeight[client] += g_dItems[itemId].weight;
			return view_as<int>(true);
		}
	}
	
	if( 0 >= g_dItems[itemId].stack )
		return view_as<int>(false);
	
	g_cItems[client][c].itemId = itemId;
	g_cItems[client][c].itemAmount = 1;
	g_cItemsCount[client]++;
	g_cItemsWeight[client] += g_dItems[itemId].weight;

	return view_as<int>(true);
}
public int Native_SC_SpawnItem(Handle plugin, int numParams) {
	static char classname[64];
	static float src[3], vel[3];
	
	int id = GetNativeCell(1);
	GetNativeArray(2, src, sizeof(src));
	GetNativeArray(3, vel, sizeof(vel));	
	
	Format(classname, sizeof(classname), "%s%d", WORLDNAME, id);
	int ent = CreateEntityByName("hegrenade_projectile");
	DispatchKeyValue(ent, "classname", classname);
	DispatchSpawn(ent);
	
	SetEntityModel(ent, g_dItems[id].model);
	Entity_SetSolidType(ent, SOLID_VPHYSICS);
	Entity_SetSolidFlags(ent, FSOLID_TRIGGER );
	Entity_SetCollisionGroup(ent, COLLISION_GROUP_PLAYER | COLLISION_GROUP_PLAYER_MOVEMENT);	
	SetEntPropFloat(ent, Prop_Data, "m_flModelScale", g_dItems[id].modelScale);
	SetEntPropFloat(ent, Prop_Send, "m_flElasticity", 0.4);
	
	TeleportEntity(ent, src, NULL_VECTOR, vel);
	SDKHook(ent, SDKHook_StartTouch, OnTouch);
}