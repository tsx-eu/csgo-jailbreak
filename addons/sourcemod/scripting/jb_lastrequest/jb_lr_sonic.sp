#pragma semicolon 1
#pragma dynamic 1310720

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#include <navareautilities>

#pragma newdecls required

#include <jb_lastrequest>

bool g_bMapIsCompatible = false;
Handle g_hBDD;

#define MIN_COIN	64
#define MAX_COIN	128
#define ENTITY_SAFE	1950
#define SCORE		20

int g_iHidingPosition;
float g_flHidingPosition[256][3];
int g_iClient, g_iTarget;
int g_iScore[65];

public void JB_OnPluginReady() {
	JB_CreateLastRequest("Sonic - SOON", 	JB_SELECT_CT_UNTIL_DEAD|JB_ONLY_VIP, DV_CAN, DV_Start, DV_Stop);
}
stock bool DV_CAN(int client) {
	return false && g_bMapIsCompatible && g_iHidingPosition >= MIN_COIN && CountEntity() < ENTITY_SAFE-MAX_COIN;
}
public void DV_Start(int client, int target) {
	int entityCount = CountEntity();
	float pos[3];

	g_iClient = client;
	g_iTarget = target;
	
	g_iScore[client] = g_iScore[target] = 0;
	
	for (int i = 0; i < MAX_COIN; i++) {
		
		pos = g_flHidingPosition[i];
		
		int ent = CreateEntityByName("item_coop_coin");
		DispatchSpawn(ent);
		SDKHook(ent, SDKHook_Touch, OnTouch);
		
		pos[2] += 32.0;
		
		entityCount++;
		if( entityCount > ENTITY_SAFE ) {
			break;
		}
	}
}
public void OnTouch(int entity, int client) {
	if( client == g_iClient || client == g_iTarget ) {
		SDKUnhook(entity, SDKHook_Touch, OnTouch);
		
		g_iScore[client]++;
		PrintHintTextToAll("%N: %d/%d\n%N: %d/%d", g_iClient, g_iScore[g_iClient], SCORE, g_iTarget, g_iScore[g_iTarget], SCORE);
		
		if( g_iScore[client] >= SCORE ) {
			ForcePlayerSuicide(client==g_iClient?g_iTarget:g_iClient);
		}
	}
}
public void DV_Stop(int client, int target) {
	int ent = -1;
	while ((ent = FindEntityByClassname(ent, "item_coop_coin")) != -1) {
		if( IsValidEdict(ent) && IsValidEntity(ent) ) {
			AcceptEntityInput(ent, "Kill");
		}
	}
}

int CountEntity() {
	int cpt = 0;
	for (int i = 1; i <= 2048; i++) {
		if( !IsValidEdict(i) || !IsValidEntity(i) )
			continue;
		cpt++;
	}
	return cpt;
}

public void OnMapStart() {
	g_bMapIsCompatible = false;
	
	float min[3], max[3], pos[3], mid[3];
	char map[64];
	bool canSpawn;
	
	GetCurrentMap(map, sizeof(map));
	
	int cpt = 0;
	int count = NAU_GetNavAreaCount();
	if( !(count <= 512 || count == 1120) ) {
	
		float[] hiding = new float[count*3];
		
		for (int i = 0; i < count; i++) {
			CNavArea area = NAU_GetNavAreaAddressByIndex(i);
			area.GetNorthWestCorner(max);
			area.GetSouthEastCorner(min);
			
			if( FloatAbs( min[2] - max[2] ) > 1.0 )
				continue;
			
			float x = min[0] - max[0];
			float y = min[1] - max[1];
			float w = SquareRoot((x * x) + (y * y));
			
			if( w > 128.0 || w <= 16.0 )
				continue;
			
			mid[0] = (max[0] + min[0]) / 2.0;
			mid[1] = (max[1] + min[1]) / 2.0;
			mid[2] = (max[2] + min[2]) / 2.0;
			
			canSpawn = true;
			for (int j = 0; j < cpt; j++) {
				pos[0] = hiding[j * 3 + 0];
				pos[1] = hiding[j * 3 + 1];
				pos[2] = hiding[j * 3 + 2];
				
				if( GetVectorDistance(pos, mid, true) <= (256.0*256.0) ) {
					canSpawn = false;
					break;
				}
			}
			
			if( canSpawn ) {
				hiding[cpt*3 + 0] = mid[0];
				hiding[cpt*3 + 1] = mid[1];
				hiding[cpt*3 + 2] = mid[2];
				cpt++;
			}
		}
		
		if( cpt >= 128 ) {
			g_bMapIsCompatible = true;
			
		}
		
		for (int i = 0; i < cpt; i++) {
			g_flHidingPosition[cpt][0] = hiding[cpt * 3 + 0];
			g_flHidingPosition[cpt][1] = hiding[cpt * 3 + 1];
			g_flHidingPosition[cpt][2] = hiding[cpt * 3 + 2];
		}
		
		//for (int i = 0; i < cpt; i++) {
		for (int i = cpt-1; i > 0; i--) {
			int j = Math_GetRandomInt(0, i);
			mid = g_flHidingPosition[j];
			g_flHidingPosition[j] = g_flHidingPosition[i];
			g_flHidingPosition[i] = mid;
		}
		
		g_iHidingPosition = cpt;
	}
	
	Handle KV = CreateKeyValues("sql");
	KvSetString(KV, "driver",	"mysql");
	KvSetString(KV, "host",		"localhost");
	KvSetString(KV, "database",	"serverother");
	KvSetString(KV,	"user",		"serverother");
	KvSetString(KV,	"pass",		"iBEpewupbB");
	KvSetString(KV,	"port",		"3306");
	
	char error[1024];
	g_hBDD = SQL_ConnectCustom(KV, error, sizeof(error), true);
	Format(error, sizeof(error), "INSERT INTO `stats_nav` (`map`, `nav`, `hidding`) VALUES ('%s', '%d', '%d') ON DUPLICATE KEY UPDATE nav='%d', hidding='%d';", map, count, cpt, count, cpt);
	
	SQL_TQuery(g_hBDD, SQL_QueryCallBack, error);
}
public void OnMapEnd() {
	delete g_hBDD;
}
public void SQL_QueryCallBack(Handle owner, Handle handle, const char[] error, any data) {
	if( handle == INVALID_HANDLE ) {
		LogError("[SQL] [ERROR] %s", error);
	}
}