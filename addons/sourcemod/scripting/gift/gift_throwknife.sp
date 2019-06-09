#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#include <gift>
#include <csgocolors>
#include <cstrike>

#pragma newdecls required

#define MODEL "models/weapons/w_knife_flip_dropped.mdl"

int g_iClient[MAXPLAYERS];
int g_cLaser;
int g_iGift;

int g_iMaxThrow;
int g_iHealth;

public void OnPluginStart() {
	HookEvent("round_start", EventRoundStart);
}

public void Gift_OnGiftStart() {
	g_iGift = Gift_RegisterNewGift("Lancé de couteau", "knifethrow", Gift_GetConfigBool("throw.ini", "active t"), Gift_GetConfigBool("throw.ini", "active ct"), Gift_GetConfigFloat("throw.ini", "chance"), Gift_GetConfigInt("throw.ini", "numb"), ADMFLAG_CUSTOM1|ADMFLAG_ROOT);
	
	g_iMaxThrow = Gift_GetConfigInt("throw.ini", "max_throw");
	g_iHealth = Gift_GetConfigInt("throw.ini", "health");
}

public void OnMapStart() {
	g_cLaser = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	PrecacheModel(MODEL);
}

public Action Gift_OnRandomGift(int client, int gift) {
	if(gift != g_iGift)
		return Plugin_Handled;
	
	CPrintToChat(client, "{lightgreen}%s {green} Vous pouvez lancer %i couteau%s avec un double clic!", PREFIX, g_iMaxThrow, g_iMaxThrow > 1 ? "x":"");
	g_iClient[client] = g_iMaxThrow;
	return Plugin_Continue;
}

public Action EventRoundStart(Event event, const char[] name, bool dontbroadcast) {
	for (int i = i; i <= MaxClients; i++) {
		if(IsClientValid(i)) {
			g_iClient[i] = 0;
		}
	}
}

public Action OnPlayerRunCmd(int client, int& button, int& impulse, float vel[3], float angle[3], int& weapon, int& subtype, int& command, int& tick, int& seed, int mouse[2]) {
	static int lastButton[65];
	static float lastDouble[65], src[3], ang[3];
	static char wepname[64];
	
	if( g_iClient[client] > 0 ) {
		if( !(lastButton[client] & IN_ATTACK) && button & IN_ATTACK ) {
			int wep = Client_GetActiveWeapon(client);
			if( wep > 0 ) {
				GetEdictClassname(wep, wepname, sizeof(wepname));
				
				if( StrContains(wepname, "knife") >= 0 ) {
					if( lastDouble[client]+0.5 >= GetGameTime() && lastDouble[client]+0.5 <= GetGameTime() + 0.5 ) {
						g_iClient[client]--;
			
						
						GetClientEyePosition(client, src);
						GetClientEyeAngles(client, ang);
						
						Effect(client, src, ang, view_as<float>({ 0.0, 24.0, -8.0 }), GetClientTeam(client) == CS_TEAM_T ? {255, 0, 0, 150} : {0, 0, 255, 150});
					}
					else {
						lastDouble[client] = GetGameTime();
					}
				}
			}
		}
		
		lastButton[client] = button;
	}
}

public bool TR_FilterSelf(int entity, int mask, any client) {
	if (entity == client)
		return false;
	return true;
}

int Effect(int client, float origin[3], float angle[3], float offset[3], int color[4]) {
	float src[3], dst[3], fVel[3], fPVel[3];
	dst[0] = angle[0];
	dst[1] = 0.0;
	dst[2] = 0.0;
	 
	Math_RotateVector(offset, angle, src);
	AddVectors(src, origin, src);
	
	GetAngleVectors(angle, fVel, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(fVel, 2000.0);
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fPVel);
	AddVectors(fVel, fPVel, fVel);
	
	int ent = CreateEntityByName("prop_physics_override");
	DispatchKeyValue(ent, "model", MODEL);
	DispatchKeyValue(ent, "OnUser1", "!self,Kill,,10.0,-1");
	DispatchSpawn( ent );
	
	AcceptEntityInput(ent, "FireUser1");	
	TeleportEntity(ent, origin, angle, fVel);
	Entity_SetCollisionGroup(ent, COLLISION_GROUP_PLAYER);
	Entity_SetSolidFlags(ent, FSOLID_TRIGGER);
	Entity_SetSolidType(ent, SOLID_VPHYSICS);
	Entity_SetOwner(ent, client);
	
	SDKHook(ent, SDKHook_Touch, OnTouch);	
	
	SetEntPropFloat(ent, Prop_Send, "m_flElasticity", 0.01);
	SetEntPropVector(ent, Prop_Data, "m_vecAngVelocity", view_as<float>({20000.0, 0.0, 0.0}));
	
	TE_SetupBeamFollow(ent, g_cLaser, 0, 0.5, 2.0, 0.1, 1, color);
	TE_SendToAll();
}

public void OnTouch(int entity, int client) {
	int owner = Entity_GetOwner(entity);
	if( owner == client || owner == 0  )
		return;
	
	if( client > 0 && client < MaxClients ) {
		AcceptEntityInput(entity, "Kill");
		
		Entity_Hurt(client, g_iHealth, owner);
		SlapPlayer(client, 0);
	}
	else {
		Entity_SetOwner(entity, 0);
	}
	
}
