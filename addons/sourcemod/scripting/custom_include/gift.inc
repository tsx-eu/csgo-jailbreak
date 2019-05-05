#if defined _gitft_included
#endinput
#endif
#define _gitft_included

#include <sourcemod>
#include <sdktools>
#include <rsc_utils>

#define MAX_GIFT 128
#define PREFIX "{lightgreen}[ {default}GIFT {lightgreen}]"

/*
 * Appeller quand le gift se lance 
 *
*/
forward void Gift_OnGiftStart();

/* 
 * Appeller quand quelqu'un tape !gift
 *
 * @param client 		Index du client
 *
*/
forward Action Gift_OnClientSendCommand(int client);

/* 
 * Appeller quand quelqu'un optien un gift
 *
 * @param client 		Index du client
 * @param gift			Index du gift
 * @param force			Forcer -> Gift_ForceClientGift
 *
*/
forward Action Gift_OnRandomGift(int client, int gift, bool force);

/* 
 * Appeller quand quelqu'un se voie retirer un gift
 *
 * @param client 		Index du client
 *
*/
forward Action Gift_OnRemoveGift(int client);

/* 
 * Appeller quand quelqu'un utilise un gift
 *
 * @param client 		Index du client
 *
*/
forward Action Gift_OnUseGift(int client, int gift);

/* ------------------------------------------------------------------------------------------------------------- */

/* 
 * Fonction qui reprend une valeur integer d'une configuration 
 *
 * @param config		Config
 * @param file			Fichier 
 * 
 * @return value
*/
native int Gift_GetConfigInt(char[] file, char[] config);

/* 
 * Fonction qui reprend une valeur float d'une configuration 
 *
 * @param config		Config
 * @param file			Fichier 
 * 
 * @return value
*/
native float Gift_GetConfigFloat(char[] file, char[] config);

/* 
 * Fonction qui reprend une valeur string d'une configuration 
 *
 * @param config		Config
 * @param file			Fichier 
 * @param buffer		String qui reprend la valeur
 * @param maxlen		Taille 
 * 
 * @noreturn
*/
native void Gift_GetConfigString(char[] file, char[] config, char[] buffer, int maxlen);

/* 
 * Fonction qui reprend une valeur bool d'une configuration 
 *
 * @param config		Config
 * @param file			Fichier 
 * 
 * @return true/false
*/
native bool Gift_GetConfigBool(char[] file, char[] config);

/* ------------------------------------------------------------------------------------------------------------- */

/*
 * Fonction qui reprend le nombre de gift
 *
 * @return Nombre de gift 
*/
native int Gift_GetNumberGift();

/*
 * Fonction qui reprend le nom d'un gift 
 *
 * @param gift		ID du gift
 * @param buffer	char contenant le gift 
 * @param maxlen	Taille du tableau
 *
*/
native void Gift_GetName(int gift, char[] buffer, maxlen);

/*
 * Fonction qui reprend le unique id d'un gift 
 *
 * @param gift		ID du gift
 * @param buffer	char contenant le unique id 
 * @param maxlen	Taille du tableau
 *
*/
native void Gift_GetUniqueId(int gift, char[] buffer, maxlen);

/* 
 * Fonction qui retourne l'accessibilité du gift pour une team 
 *
 * @param gift		ID du gift 
 * @param team 		ID de la team 
 *
 * @retur  			true/false
*/
native bool Gift_IsTeamAccess(int gift, int team);

/* 
 * Fonction qui reprend le pourcentage de chance du gift 
 * 
 * @param gift		ID du gift 
 *
 * @return pourcentage
*/
native float Gift_GetPercent(int gift);

/* 
 * Fonction qui reprend les flags permettant l'accessibilité du gift 
 *
 * @param gift		ID du gift 
 *
 * @return bitflags
*/
//native int Native_GetFlags(int gift);

/* ------------------------------------------------------------------------------------------------------------- */

/* 
 * Fonction qui enregistre un nouveau gift
 *
 * @param name			Nom du gift
 * @param uniqueid		ID unique du gift
 * @param accessT		Activer le gift pour les terro
 * @param accessCT		Activer le gift pour les CT
 * @param percent		Pourcentage de chance
 * @param access		Nombre d'accès au gift par round avant sa désactivation
 *
*/
native int Gift_RegisterNewGift(char[] name, char[] uniqueid, bool accessT, bool accessCT, float percent, int access, int flags = ADMFLAG_CUSTOM1);

/*
 * Fonction qui vérifie si le client à accès au gift 
 * 
 * @param client		Index du client 
 * 
 * @return				true/false
 *
*/
native bool Gift_ClientCanGift(int client);

/*
 * Fonction qui supprime le gift
 * 
 * @param client		Index du client 
 *
*/
native int Gift_RemoveClientGift(int client);

/* 
 * Fonction qui change l'acces au client 
 *
 * @param client		Index du client 
 * @param access		true/false
 *
*/
native int Gift_ClientGift(int client, bool access);

/* 
 * Fonction qui force le gift à un client 
 *
 * @param client		Index du client 
 * @param gift			Index du gift 
 *
*/
native void Gift_ForceGift(int client, int gift);

/* 
 * Fonction qui force le random gift à un client 
 *
 * @param client		Index du client 
 *
*/
native void Gift_ForceRandomGift(int client);

/* 
 * Fonction qui créé l'utilisation du gift
 *
 * @param client		Index du client 
 * @param gift			Idex du gift
 *
*/
native int Gift_ClientUseGift(int client, int gift);
