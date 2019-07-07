#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#include <emitsoundany>

#pragma newdecls required

#include <jb_lastrequest>

#define TIME_TO_TICK(%1)	(RoundToNearest((%1) / GetTickInterval()))
#define TICK_TO_TIME(%1)	((%1) * GetTickInterval())

int g_iClient = -1, g_iTarget = -1, g_iPrevTickCount[65], g_iTickCount, g_iWeapons[65];
float g_vAbsCentre[65][3], g_vEyePos[65][3], g_vMins[65][3], g_vMaxs[65][3], g_vAbsBottom[65][3];
int g_iState;
Handle g_hMain = INVALID_HANDLE;

public void JB_OnPluginReady() {
	JB_CreateLastRequest("Roulette CowBoy", 	JB_SELECT_CT_UNTIL_DEAD|JB_BEACON, DV_CAN_Always, DV_Start, DV_Stop);
}
public void OnMapStart() {
	PrecacheSoundAny("rsc/jailbreak/taunt_bell.wav");
	PrecacheSoundAny("rsc/jailbreak/heavy_niceshot02.wav");
	
	AddFileToDownloadsTable("sound/rsc/jailbreak/taunt_bell.wav");
	AddFileToDownloadsTable("sound/rsc/jailbreak/heavy_niceshot02.wav");
}
public void DV_Start(int client, int target) {
	g_iClient = client;
	g_iTarget = target;
	g_iState = 1;
	CreateTimer(1.0, CheckDistance);
	SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
	SDKHook(target, SDKHook_TraceAttack, OnTraceAttack);
	
	JB_ShowHUDMessage("Éloig﻿nez vous pour que la dv se lance, vous devez être à la même hauteur et aucun obstacle ne doit vous séparer. Quand vous entendrez le fameux \"Ding\" retournez vous et tirez.﻿﻿﻿﻿﻿﻿﻿﻿﻿﻿");
}

public Action CheckDistance(Handle timer, any none) {
	float src[3], dst[3];
	GetClientAbsOrigin(g_iClient, src);
	GetClientAbsOrigin(g_iTarget, dst);
	
	float dist = GetVectorDistance(src, dst);
	
	
	if( dist < 256.0 ) {
		PrintHintTextToAll("Reculez-vous");
	}
	else if( dist <= 512.0 ) {
		PrintHintTextToAll("Rapprochez-vous");
	}
	else if ( FloatAbs(src[2] - dst[2]) > 128.0 ) {
		PrintHintTextToAll("Rapprochez-vous");
	}
	else {
		UpdateClientData(g_iClient);
		UpdateClientData(g_iTarget);
		
		if( Entity_GetGroundEntity(g_iClient) == 0 && Entity_GetGroundEntity(g_iTarget) == 0 ) {
			if( IsAbleToSee(g_iClient, g_iTarget) && IsAbleToSee(g_iTarget, g_iClient) ) {
				
				DV_StripWeapon(g_iClient);
				DV_StripWeapon(g_iTarget);
				
				g_iWeapons[g_iClient] = GivePlayerItem(g_iClient, "weapon_deagle");
				g_iWeapons[g_iTarget] = GivePlayerItem(g_iTarget, "weapon_deagle");
				
				SetEntProp(g_iWeapons[g_iClient], Prop_Send, "m_iClip1", 0);
				SetEntProp(g_iWeapons[g_iClient], Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
				
				SetEntProp(g_iWeapons[g_iTarget], Prop_Send, "m_iClip1", 0);
				SetEntProp(g_iWeapons[g_iTarget], Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
				
				g_iState = 2;
				g_hMain = CreateTimer(5.0, Start);
				return Plugin_Handled;
			}
			else {
				PrintHintTextToAll("Quelque chose se trouve entre vous deux");
			}
		}
		else {
			PrintHintTextToAll("Ne sautez pas");
		}
	}
	
	g_hMain = CreateTimer(1.0, CheckDistance);
	return Plugin_Handled;
}

public Action Start(Handle timer, any none) {
	g_iState = 3;
	
	EmitSoundToAllAny("rsc/jailbreak/taunt_bell.wav", g_iWeapons[g_iClient]);
	EmitSoundToAllAny("rsc/jailbreak/taunt_bell.wav", g_iWeapons[g_iTarget]);	
	
	SetEntProp(g_iWeapons[g_iClient], Prop_Send, "m_iClip1", 1);
	SetEntProp(g_iWeapons[g_iTarget], Prop_Send, "m_iClip1", 1);
	
	g_hMain = CreateTimer(5.0, Late);
}
public Action Late(Handle timer, any none) {	
	g_iState = 2;
	g_hMain = CreateTimer(5.0, Start);
}
public Action OnTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup) {
	if( g_iState == 3 ) {
		if( victim == g_iClient || victim == g_iTarget ) {
			if( attacker == g_iClient || attacker == g_iTarget ) {
		
				g_iState = 4;
				EmitSoundToAllAny("rsc/jailbreak/heavy_niceshot02.wav", g_iWeapons[attacker]);
				return Plugin_Continue;
			}
		}
	}
	return Plugin_Handled;
}
public void DV_Stop(int client, int target) {
	g_iState = 0;
	g_iClient = g_iTarget = -1;
	
	if(client)
		SDKUnhook(client, SDKHook_TraceAttack, OnTraceAttack);
	if(target)
		SDKUnhook(target, SDKHook_TraceAttack, OnTraceAttack);
	
	if( IsValidHandle(g_hMain) )
		KillTimer(g_hMain);
	g_hMain = null;
}
public void OnGameFrame() {	
	g_iTickCount = GetGameTickCount();
}
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2]) {
	static float vecNull[3], angle[3];
	
	g_iPrevTickCount[client] = tickcount;
	
	if( g_iState >= 2 ) {
		if( client == g_iClient || client == g_iTarget ) {
			int target = client == g_iClient ? g_iTarget : g_iClient;
			
			LookAtTarget(client, target, angle);
			Blind(client,  g_iState == 2);
			TeleportEntity(client, g_vAbsBottom[client], g_iState == 2 ? angle : NULL_VECTOR, vecNull);
			vel = vecNull;
			
			if( g_iState == 3 && buttons & IN_ATTACK )
				buttons = IN_ATTACK;
			else
				buttons = 0;
			
			return Plugin_Changed;				
		}
	}
	
	return Plugin_Continue;
}

// -------------------------------------------------------------------------------------
void Blind(int client, bool toggle) {
	Handle hFadeClient = StartMessageOne("Fade", client);
	PbSetInt(hFadeClient, "duration", 1536);
	PbSetInt(hFadeClient, "hold_time", 1536);
	
	if( toggle ) {
		PbSetInt(hFadeClient, "flags", (0x0001 | 0x0010));
		PbSetColor(hFadeClient, "clr", {0, 0, 0, 255});
	}
	else {
		PbSetInt(hFadeClient, "flags", (0x0001 | 0x0010));
		PbSetColor(hFadeClient, "clr", {0, 0, 0, 0});
	}
	
	EndMessage();
}
void LookAtTarget(int client, int target, float angles[3]) {  
	float clientEyes[3], targetEyes[3], resultant[3];  
	GetClientEyePosition(client, clientEyes); 
	GetClientEyePosition(target, targetEyes); 
	MakeVectorFromPoints(targetEyes, clientEyes, resultant);  
	GetVectorAngles(resultant, angles);

	if(angles[0] >= 270) {  
		angles[0] -= 270;
		angles[0] = (90-angles[0]);  
	}
	else if(angles[0] <= 90) {
		angles[0] *= -1;  
	}
	angles[2] = 0.0;
}  
void UpdateClientData(int client) {
	
	GetClientMins(client, g_vMins[client]);
	GetClientMaxs(client, g_vMaxs[client]);
	GetClientAbsOrigin(client, g_vAbsBottom[client]);
	GetClientAbsOrigin(client, g_vAbsCentre[client]);
	GetClientEyePosition(client, g_vEyePos[client]);
	
	// Adjust vectors relative to the model's absolute centre.
	g_vMaxs[client][2] /= 2.0;
	g_vMins[client][2] -= g_vMaxs[client][2];
	g_vAbsCentre[client][2] += g_vMaxs[client][2];

	// Adjust vectors based on the clients velocity.
	float vVelocity[3];
	Entity_GetAbsVelocity(client, vVelocity);
	
	if (!IsVectorZero(vVelocity)) {
		// Lag compensation.
		int iTargetTick;
		
		// Based on CLagCompensationManager::StartLagCompensation.
		float fCorrect = GetClientLatency(client, NetFlow_Outgoing);
		int iLerpTicks = TIME_TO_TICK(GetEntPropFloat(client, Prop_Data, "m_fLerpTime"));
		
		// Assume sv_maxunlag == 1.0f seconds.
		fCorrect += TICK_TO_TIME(iLerpTicks);
		fCorrect = Math_Clamp(fCorrect, 0.0, 1.0);
		iTargetTick = g_iPrevTickCount[client] - iLerpTicks;
			
		if (FloatAbs(fCorrect - TICK_TO_TIME(g_iTickCount - iTargetTick)) > 0.2) {
			// Difference between cmd time and latency is too big > 200ms.
			// Use time correction based on latency.
			iTargetTick = g_iTickCount - TIME_TO_TICK(fCorrect);
		}
		
		// Use velocity before it's modified.
		float vTemp[3];
		vTemp[0] = FloatAbs(vVelocity[0]) * 0.01;
		vTemp[1] = FloatAbs(vVelocity[1]) * 0.01;
		vTemp[2] = FloatAbs(vVelocity[2]) * 0.01;
		
		// Calculate predicted positions for the next frame.
		float vPredicted[3];
		ScaleVector(vVelocity, TICK_TO_TIME((g_iTickCount - iTargetTick) * 1));
		AddVectors(g_vAbsCentre[client], vVelocity, vPredicted);
		
		// Make sure the predicted position is still inside the world.
		TR_TraceHullFilter(vPredicted, vPredicted, view_as<float>({-5.0, -5.0, -5.0}), view_as<float>({5.0, 5.0, 5.0}), MASK_PLAYERSOLID_BRUSHONLY, Filter_WorldOnly);
		
		if (!TR_DidHit()) {
			g_vAbsCentre[client] = vPredicted;
			AddVectors(g_vEyePos[client], vVelocity, g_vEyePos[client]);
		}
		
		// Expand the mins/maxs to help smooth during fast movement.
		if (vTemp[0] > 1.0) {
			g_vMins[client][0] *= vTemp[0];
			g_vMaxs[client][0] *= vTemp[0];
		}
		if (vTemp[1] > 1.0) {
			g_vMins[client][1] *= vTemp[1];
			g_vMaxs[client][1] *= vTemp[1];
		}
		if (vTemp[2] > 1.0) {
			g_vMins[client][2] *= vTemp[2];
			g_vMaxs[client][2] *= vTemp[2];
		}
	}
}
bool IsVectorZero(float vec[3]) {
	return vec[0] == 0.0 && vec[1] == 0.0 && vec[2] == 0.0;
}
bool IsAbleToSee(int entity, int client) {
	
	// Check if centre is visible.
	if (IsPointVisible(g_vEyePos[client], g_vAbsCentre[entity]))
		return true;
		
	// Check outer 4 corners of player.
	if (IsRectangleVisible(g_vEyePos[client], g_vAbsCentre[entity], g_vMins[entity], g_vMaxs[entity], 0.75))
		return true;
	
	return false;
}
bool IsRectangleVisible(const float start[3], const float end[3], const float mins[3], const float maxs[3], float scale=1.0) {
	static float angles[3], fwd[3], right[3];
	static float vRectangle[4][3], vTemp[3];
	static float ZpozOffset, ZnegOffset, WideOffset;
	
	ZnegOffset = mins[2];
	ZpozOffset = maxs[2];
	WideOffset = ((maxs[0] - mins[0]) + (maxs[1] - mins[1])) / 4.0;
	
	// This rectangle is just a point!
	if (ZpozOffset == 0.0 && ZnegOffset == 0.0 && WideOffset == 0.0) {
		return IsPointVisible(start, end);
	}

	// Adjust to scale.
	ZpozOffset *= scale;
	ZnegOffset *= scale;
	WideOffset *= scale;
	
	// Prepare rotation matrix.
	SubtractVectors(start, end, fwd);
	NormalizeVector(fwd, fwd);

	GetVectorAngles(fwd, angles);
	GetAngleVectors(angles, fwd, right, NULL_VECTOR);
	
	// If the player is on the same level as us, we can optimize by only rotating on the z-axis.
	if (FloatAbs(fwd[2]) <= 0.7071) {
		ScaleVector(right, WideOffset);
		
		// Corner 1, 2
		vTemp = end;
		vTemp[2] += ZpozOffset;
		AddVectors(vTemp, right, vRectangle[0]);
		SubtractVectors(vTemp, right, vRectangle[1]);
		
		// Corner 3, 4
		vTemp = end;
		vTemp[2] += ZnegOffset;
		AddVectors(vTemp, right, vRectangle[2]);
		SubtractVectors(vTemp, right, vRectangle[3]);
	}
	else if (fwd[2] > 0.0) {
		fwd[2] = 0.0;
		NormalizeVector(fwd, fwd);
		
		ScaleVector(fwd, scale);
		ScaleVector(fwd, WideOffset);
		ScaleVector(right, WideOffset);
		
		// Corner 1
		vTemp = end;
		vTemp[2] += ZpozOffset;
		AddVectors(vTemp, right, vTemp);
		SubtractVectors(vTemp, fwd, vRectangle[0]);
		
		// Corner 2
		vTemp = end;
		vTemp[2] += ZpozOffset;
		SubtractVectors(vTemp, right, vTemp);
		SubtractVectors(vTemp, fwd, vRectangle[1]);
		
		// Corner 3
		vTemp = end;
		vTemp[2] += ZnegOffset;
		AddVectors(vTemp, right, vTemp);
		AddVectors(vTemp, fwd, vRectangle[2]);
		
		// Corner 4
		vTemp = end;
		vTemp[2] += ZnegOffset;
		SubtractVectors(vTemp, right, vTemp);
		AddVectors(vTemp, fwd, vRectangle[3]);
	}
	else {
		fwd[2] = 0.0;
		NormalizeVector(fwd, fwd);
		
		ScaleVector(fwd, scale);
		ScaleVector(fwd, WideOffset);
		ScaleVector(right, WideOffset);

		// Corner 1
		vTemp = end;
		vTemp[2] += ZpozOffset;
		AddVectors(vTemp, right, vTemp);
		AddVectors(vTemp, fwd, vRectangle[0]);
		
		// Corner 2
		vTemp = end;
		vTemp[2] += ZpozOffset;
		SubtractVectors(vTemp, right, vTemp);
		AddVectors(vTemp, fwd, vRectangle[1]);
		
		// Corner 3
		vTemp = end;
		vTemp[2] += ZnegOffset;
		AddVectors(vTemp, right, vTemp);
		SubtractVectors(vTemp, fwd, vRectangle[2]);
		
		// Corner 4
		vTemp = end;
		vTemp[2] += ZnegOffset;
		SubtractVectors(vTemp, right, vTemp);
		SubtractVectors(vTemp, fwd, vRectangle[3]);
	}

	// Run traces on all corners.
	for (int i = 0; i < 4; i++) {
		if (IsPointVisible(start, vRectangle[i])) {
			return true;
		}
	}

	return false;
}
bool IsPointVisible(const float start[3], const float end[3]) {
	TR_TraceRayFilter(start, end, MASK_VISIBLE, RayType_EndPoint, Filter_NoPlayers);
	
	return (TR_GetFraction() == 1.0);
}
public bool Filter_NoPlayers(int entity, int mask) {
	return entity > MaxClients;
}
public bool Filter_WorldOnly(int entity, int mask) {
	return false;
}