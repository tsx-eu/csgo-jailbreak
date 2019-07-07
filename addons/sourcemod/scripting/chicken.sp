#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <smlib>
#include <emitsoundany>

#pragma newdecls required

Handle g_hCvarEnabled;
Handle g_hCvarChickenHP;
Handle g_hCvarChickenGravity;
Handle g_hCvarChickenSpeed;
Handle g_hCvarChickenAreAlive;
Handle g_hCvarChickenThird;
Handle g_hCvarRespawnHP;
Handle g_hCvarRespawnTime;
Handle g_hCvarRespawnCount;

int g_iRespawnCount[65];
float g_flRespawnTime[65], g_flNextSound[65];
bool g_bIsChicken[65];
char g_szOldPlayerSkin[65][PLATFORM_MAX_PATH];

#define CHICKEN_MODEL_CT	"models/npc/killzonegaming/chickenblue/chickenblue.mdl"
#define CHICKEN_MODEL_T		"models/npc/killzonegaming/chickenorange/chickenorange.mdl"


public void OnPluginStart() {
	g_hCvarEnabled = 			CreateConVar("sm_chicken", 				"1");
	g_hCvarChickenHP = 			CreateConVar("sm_chicken_hp", 			"10");
	g_hCvarChickenGravity = 	CreateConVar("sm_chicken_gravity", 		"0.8");
	g_hCvarChickenSpeed = 		CreateConVar("sm_chicken_speed", 		"1.1");
	g_hCvarChickenAreAlive = 	CreateConVar("sm_chicken_alive", 		"1");
	g_hCvarChickenThird = 		CreateConVar("sm_chicken_thirdperson",	"1");
	g_hCvarRespawnHP = 			CreateConVar("sm_chicken_respawn_hp", 	"25");
	g_hCvarRespawnTime = 		CreateConVar("sm_chicken_time",			"30");
	g_hCvarRespawnCount = 		CreateConVar("sm_chicken_respawn", 		"3");
	
	for (int i = 1; i <= MaxClients; i++)
		if( IsClientInGame(i) )
			OnClientPostAdminCheck(i);
	
	HookEvent("player_death", 		EventDeath, 			EventHookMode_Pre);
	HookEvent("round_start", 		OnRoundStart, 			EventHookMode_Post);
	ServerCommand("sv_allow_thirdperson 1");
	AutoExecConfig();
}
public void OnMapStart() {
	PrecacheModel(CHICKEN_MODEL_CT);
	PrecacheModel(CHICKEN_MODEL_T);
	
	PrecacheSoundAny("ambient/creatures/chicken_death_01.wav");
	PrecacheSoundAny("ambient/creatures/chicken_death_02.wav");
	PrecacheSoundAny("ambient/creatures/chicken_death_03.wav");
	
	PrecacheSoundAny("ambient/creatures/chicken_idle_01.wav");
	PrecacheSoundAny("ambient/creatures/chicken_idle_02.wav");
	PrecacheSoundAny("ambient/creatures/chicken_idle_03.wav");
	PrecacheSoundAny("ambient/creatures/chicken_idle_04.wav");
	PrecacheSoundAny("ambient/creatures/chicken_idle_05.wav");
	
	PrecacheSoundAny("ambient/creatures/chicken_panic_03.wav");
	PrecacheSoundAny("ambient/creatures/chicken_panic_04.wav");
	
	
	AddFileToDownloadsTable("materials/ex/feather.vmt");
	AddFileToDownloadsTable("materials/ex/feather.vtf");
	AddFileToDownloadsTable("materials/ex/feather2.vmt");
	AddFileToDownloadsTable("materials/ex/feather2.vtf");
	AddFileToDownloadsTable("materials/ex/glow1.vmt");
	AddFileToDownloadsTable("materials/ex/glow1.vtf");
	

	AddFileToDownloadsTable("particles/sky_chick.pcf");
	PrecacheGeneric("particles/sky_chick.pcf", true);
	
	PrecacheParticleEffect("Sky_Chick_Blue");
	PrecacheParticleEffect("Sky_Chick_Red");
	PrecacheParticleEffect("Sky_Chick_Spawn_Blue");
	PrecacheParticleEffect("Sky_Chick_Spawn_Red");
}
public void OnClientPostAdminCheck(int client) {
	if( !GetConVarBool(g_hCvarEnabled) )
		return;
	
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
	SDKHook(client, SDKHook_WeaponCanSwitchTo, OnWeaponSwitch);
	
	g_iRespawnCount[client] = GetConVarInt(g_hCvarRespawnCount);
}

public Action OnRoundStart(Handle ev, const char[] name, bool dontBroadcast) {
	int count = GetConVarInt(g_hCvarRespawnCount);
	
	for (int i = 1; i < MaxClients; i++) {
		if( IsClientInGame(i) ) {
			if( g_bIsChicken[i] ) {
				if( GetConVarBool(g_hCvarChickenThird) )
					ClientCommand(i, "firstperson");
			}
			g_bIsChicken[i] = false;
			g_iRespawnCount[i] = count;
		}
	}
}

public Action OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3]) {
	if( attacker > 0 ) {
		
		int health = GetClientHealth(victim) - RoundFloat(damage);
		if( health <= 1 ) {
			
			if( !g_bIsChicken[victim] && g_iRespawnCount[victim] > 0 ) {
				ClientTransformIntoChicken(victim);
				return Plugin_Handled;
			}
			
		}
	}
	
	return Plugin_Continue;
}
public Action OnWeaponSwitch(int client, int weapon) {
	static char tmp[64];
	GetEntityClassname(weapon, tmp, sizeof(tmp));
	
	if( g_bIsChicken[client] ) {
		if( StrContains(tmp, "knife") == -1 )
			return Plugin_Handled;
	}
	return Plugin_Continue;
}
public void OnPostThinkPost(int client) {
	static char tmp[PLATFORM_MAX_PATH];
	
	if( g_bIsChicken[client] ) {
		SetEntProp(client, Prop_Send, "m_iAddonBits", 0);
		SetEntProp(client, Prop_Send, "m_iPrimaryAddon", 0);
		SetEntProp(client, Prop_Send, "m_iSecondaryAddon", 0);
		
		float time = GetGameTime();
		int wpnid = Client_GetActiveWeapon(client);
		if( wpnid > 0 ) {
			SetEntPropFloat(wpnid, Prop_Send, "m_flNextPrimaryAttack", 	time + 1.0);
			SetEntPropFloat(wpnid, Prop_Send, "m_flNextSecondaryAttack", 	time + 1.0);
			
			int world = GetEntPropEnt(wpnid, Prop_Send, "m_hWeaponWorldModel");
			SetEntProp(world, Prop_Send, "m_nModelIndex", 0);
		}
		
		float respawn = g_flRespawnTime[client] - GetGameTime();
		PrintHintText(client, "Respawn in: %.1f", respawn);
		if( respawn <= 0 ) {
			ChickenTransformIntoClient(client);
		}
		
		if( g_flNextSound[client] < time ) {
			if( GetRandomFloat() > 0.5 ) {
				Format(tmp, sizeof(tmp), "ambient/creatures/chicken_panic_0%d.wav", GetRandomInt(3, 4));
			}
			else {
				Format(tmp, sizeof(tmp), "ambient/creatures/chicken_idle_0%d.wav", GetRandomInt(1, 5));
			}
			EmitSoundToAllAny(tmp, client);
			g_flNextSound[client] = time + GetRandomFloat(2.0, 3.0);
		}
	}
}

public Action EventDeath(Handle ev, const char[] name, bool broadcast) {
	int client = GetClientOfUserId(GetEventInt(ev, "userid"));
	if( g_bIsChicken[client] ) {
		g_bIsChicken[client] = false;
		float pos[3];
		GetClientAbsOrigin(client, pos);
		CreateParticule(GetClientTeam(client) == CS_TEAM_CT ? "Sky_Chick_Blue" : "Sky_Chick_Red", 0, pos);	
		 
		char tmp[PLATFORM_MAX_PATH];
		Format(tmp, sizeof(tmp), "ambient/creatures/chicken_death_0%d.wav", GetRandomInt(1, 3));
		
		EmitSoundToAllAny(tmp, client);
		if( GetConVarBool(g_hCvarChickenThird) )
			ClientCommand(client, "firstperson");
	}
}

void ChickenTransformIntoClient(int client) {
	g_bIsChicken[client] = false;
	
	SetEntityHealth(client, GetConVarInt(g_hCvarRespawnHP));
	SetEntityGravity(client, 1.0);
	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);
	
	SetEntityModel(client, g_szOldPlayerSkin[client]);
	
	if( GetConVarBool(g_hCvarChickenThird) )
		ClientCommand(client, "firstperson");
//	if( !GetConVarBool(g_hCvarChickenAreAlive) )
//		SetEntProp(client, Prop_Send, "m_lifeState", 0);
	
	char tmp[PLATFORM_MAX_PATH];
	Format(tmp, sizeof(tmp), "ambient/creatures/chicken_death_0%d.wav", GetRandomInt(1, 3));
	EmitSoundToAllAny(tmp, client);
	
	CreateParticule(GetClientTeam(client) == CS_TEAM_CT ? "Sky_Chick_Spawn_Blue" : "Sky_Chick_Spawn_Red", client);
}
void ClientTransformIntoChicken(int client) {
	g_iRespawnCount[client]--;
	g_bIsChicken[client] = true;
	g_flRespawnTime[client] = GetGameTime() + GetConVarFloat(g_hCvarRespawnTime);
	
	Entity_GetModel(client, g_szOldPlayerSkin[client], sizeof(g_szOldPlayerSkin[]));
	
	SetEntityHealth(client, GetConVarInt(g_hCvarChickenHP));
	SetEntityGravity(client, GetConVarFloat(g_hCvarChickenGravity));
	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", GetConVarFloat(g_hCvarChickenSpeed));
	
	FakeClientCommand(client, "use weapon_knife");
	
	if( GetConVarBool(g_hCvarChickenThird) )
		ClientCommand(client, "thirdperson");
//	if( !GetConVarBool(g_hCvarChickenAreAlive) )
//		SetEntProp(client, Prop_Send, "m_lifeState", 1);

	if( GetClientTeam(client) == CS_TEAM_CT )
		SetEntityModel(client, CHICKEN_MODEL_CT);
	else
		SetEntityModel(client, CHICKEN_MODEL_T);
	
	char tmp[PLATFORM_MAX_PATH];
	Format(tmp, sizeof(tmp), "ambient/creatures/chicken_death_0%d.wav", GetRandomInt(1, 3));
	
	EmitSoundToAllAny(tmp, client);
	
	CreateParticule(GetClientTeam(client) == CS_TEAM_CT ? "Sky_Chick_Spawn_Blue" : "Sky_Chick_Spawn_Red", client);
}


void PrecacheParticleEffect(const char[] sEffectName) {
	static int table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
		table = FindStringTable("ParticleEffectNames");
	
	bool save = LockStringTables(false);
	AddToStringTable(table, sEffectName);
	LockStringTables(save);
}
int CreateParticule(const char[] effet, int parent = 0, float pos[3] = {0.0, 0.0, 0.0}, float time = 0.0) {
	static char tmp[128];
	
	int Entity = CreateEntityByName("info_particle_system");
	DispatchKeyValue(Entity, "effect_name", effet);

	if( time > 0.0 ) {
		Format(tmp, sizeof(tmp), "!self,Kill,,%f,-1", time);
		DispatchKeyValue(Entity, "OnUser1", tmp);
	}
	
	DispatchSpawn(Entity);
	ActivateEntity(Entity);
	
	if( parent >  0 ) {
		SetVariantString("!activator");
		AcceptEntityInput(Entity, "SetParent", parent);
	}
	TeleportEntity(Entity, pos, NULL_VECTOR, NULL_VECTOR);
	
	AcceptEntityInput(Entity, "start");
	if( time > 0.0 )
		AcceptEntityInput(Entity, "FireUser1");
	
	return Entity;
}
void SendDeathMessage(int attacker, int victim, const char[] weapon, bool headshot) {
	Event event = CreateEvent("player_death");
	event.SetInt("userid", GetClientUserId(victim));
	event.SetInt("attacker", GetClientUserId(attacker));
	event.SetString("weapon", weapon);
	event.SetBool("headshot", headshot);
	event.Fire();
}