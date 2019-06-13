#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <emitsoundany>
#include <dhooks>

#pragma newdecls required

#include <jb_lastrequest>

int g_cLaser;
int g_iEnabledBunny, g_iAutoBunny;
int g_iClient, g_iTarget;
float g_flJumpStart[65][3], g_flJumpEnd[65][3], g_flDistance[65];

Handle g_hTeleport;

public void OnPluginInit() {
	Handle hGameData = LoadGameConfigFile("sdktools.games");
	if(hGameData == INVALID_HANDLE)
		return;
	
	int iOffset = GameConfGetOffset(hGameData, "Teleport");
	if(iOffset != -1) {
		g_hTeleport = DHookCreate(iOffset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, DHooks_OnTeleport);
		if(g_hTeleport != INVALID_HANDLE) {
			DHookAddParam(g_hTeleport, HookParamType_VectorPtr);
			DHookAddParam(g_hTeleport, HookParamType_ObjectPtr);
			DHookAddParam(g_hTeleport, HookParamType_VectorPtr);
			DHookAddParam(g_hTeleport, HookParamType_Bool);
		}
	}
}

public MRESReturn DHooks_OnTeleport(int client, Handle hParams) {
	bool bOriginNull = DHookIsNullParam(hParams, 1);
	
	if( client == g_iClient || client == g_iTarget ) {
		if( !bOriginNull ) {
			DHookGetParamVector(hParams, 1, g_flJumpStart[client]);
			g_flDistance[client] = 0.0;
			PrintToChatAll("%N a triché pendant sa DV :(((((((", client);
		}
	}
 
 	return MRES_Ignored;
 }
 
public void JB_OnPluginReady() {
	JB_CreateLastRequest("Le bunny le plus long", 	JB_SELECT_CT_UNTIL_DEAD|JB_BEACON|JB_NODAMAGE, DV_CAN_Always, DV_Start, DV_Stop);
}
public void OnMapStart() {
	g_cLaser = PrecacheModel("materials/sprites/laserbeam.vmt", true);
}
public void OnClientPostAdminCheck(int client) {
	DHookEntity(g_hTeleport, false, client);
}

public void DV_Start(int client, int target) {
	g_iEnabledBunny = GetConVarInt(FindConVar("sv_enablebunnyhopping"));
	g_iAutoBunny = GetConVarInt(FindConVar("sv_autobunnyhopping"));
	ServerCommand("sv_enablebunnyhopping 1;sv_autobunnyhopping 1");
	
	g_iClient = client;
	g_iTarget = target;
	
	Entity_SetCollisionGroup(client, COLLISION_GROUP_DEBRIS_TRIGGER);
	Entity_SetCollisionGroup(target, COLLISION_GROUP_DEBRIS_TRIGGER);
	
	SetEntityMoveType(client, MOVETYPE_NONE);
	SetEntityMoveType(target, MOVETYPE_NONE);
	
	CreateTimer(5.0, TIMER_DisableGodmod, client);
	CreateTimer(5.0, TIMER_DisableGodmod, target);
	
	PrintHintTextToAll("Début de la course dans 5 secondes");
			
	GetClientAbsOrigin(client, g_flJumpStart[client]);
	GetClientAbsOrigin(client, g_flJumpEnd[client]);
	
	GetClientAbsOrigin(target, g_flJumpStart[target]);
	GetClientAbsOrigin(target, g_flJumpEnd[target]);
	
	g_flDistance[client] = 0.0;
	g_flDistance[target] = 0.0;	
	
	CreateTimer(20.0, TIMER_Check);
	
	JB_ShowHUDMessage("Vous devez effectuer le plus long saut. Pour cela, l'auto-bunnyhop est activé: Vous n'avez qu'à rester appuyé sur espace.");
}
public Action TIMER_Check(Handle timer, any none) {
	if( g_flDistance[g_iClient] > g_flDistance[g_iTarget] )
		ForcePlayerSuicide(g_iTarget);
	else
		ForcePlayerSuicide(g_iClient);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &wep) {
	static int oldGround[65];
	
	if( client == g_iClient || client == g_iTarget ) {
		int groundEnd = Entity_GetGroundEntity(client);
		
		if( groundEnd >= 0 && oldGround[client] == -1 ) {
			GetClientAbsOrigin(client, g_flJumpEnd[client]);
			float dist = GetVectorDistance(g_flJumpStart[client], g_flJumpEnd[client]);
			if( dist > g_flDistance[client] )
				g_flDistance[client] = dist;
			
			TE_SetupBeamRingPoint(g_flJumpStart[client], 1.0, 64.0, g_cLaser, g_cLaser, 0, 30, 1.0, 1.0, 0.0, {0, 255, 0, 200}, 0, 0);
			TE_SendToAll();
			TE_SetupBeamRingPoint(g_flJumpEnd[client], 1.0, 64.0, g_cLaser, g_cLaser, 0, 30, 1.0, 1.0, 0.0, {255, 0, 0, 200}, 0, 0);
			TE_SendToAll();
			
			float src[3], dst[3];
			src = g_flJumpStart[client];
			dst = g_flJumpEnd[client];
			
			src[2] += 64.0;
			dst[2] += 64.0;
			
			TE_SetupBeamPoints(src, g_flJumpStart[client], g_cLaser, g_cLaser, 0, 30, 1.0, 1.0, 1.0, 1, 0.0, {0, 255, 0, 200}, 0);
			TE_SetupBeamPoints(g_flJumpEnd[client], dst, g_cLaser, g_cLaser, 0, 30, 1.0, 1.0, 1.0, 1, 0.0, {255, 0, 0, 200}, 0);
			TE_SetupBeamPoints(src, dst, g_cLaser, g_cLaser, 0, 30, 1.0, 1.0, 1.0, 1, 0.0, {255, 255, 255, 200}, 0);
			
			PrintHintTextToAll("%N: %.2f\n%N: %.2f", g_iClient, g_flDistance[g_iClient], g_iTarget, g_flDistance[g_iTarget]);
		}
		if( groundEnd == -1 && oldGround[client] >= 0 ) {
			GetClientAbsOrigin(client, g_flJumpStart[client]);
			
			TE_SetupBeamRingPoint(g_flJumpStart[client], 1.0, 64.0, g_cLaser, g_cLaser, 0, 30, 1.0, 1.0, 0.0, {0, 255, 0, 200}, 0, 0);
			TE_SendToAll();
		}
		
		oldGround[client] = groundEnd;		
	}
}

public void DV_Stop(int client, int target) {
	ServerCommand("sv_enablebunnyhopping %d;sv_autobunnyhopping %d", g_iEnabledBunny, g_iAutoBunny);
	
	if( client )
		Entity_SetCollisionGroup(client, COLLISION_GROUP_PLAYER);
	if( target )
		Entity_SetCollisionGroup(target, COLLISION_GROUP_PLAYER);
	
	
	g_iClient = g_iTarget = -1;
}
public Action TIMER_DisableGodmod(Handle timer, any client) {
	SetEntityMoveType(client, MOVETYPE_WALK);
	EmitSoundToAllAny("rsc/jailbreak/taunt_bell.wav", client);
}
