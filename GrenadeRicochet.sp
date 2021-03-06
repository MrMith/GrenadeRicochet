#include <sourcemod>
#include <sdktools>

#pragma semicolon 1


public Plugin:myinfo =
{
	name =  "Grenade Ricochet",
	author = "Mith",
	description = "When someone shoots a grenade instead of tanking through it, it rebounds depending on the player's weapon damage.",
	version = "1.1",
	url = ""
};

//weapon name -> weapon damage ex. _WeaponNames[0][0] = "weapon_deagle", _WeaponDamage[0][0] = 63.
char _WeaponNames[][] 		= {"weapon_deagle","weapon_revolver","weapon_glock","weapon_elite","weapon_tec9","weapon_mp9","weapon_mp7","weapon_bizon","weapon_mp5sd","weapon_cz75a","weapon_xm1014","weapon_mag7","weapon_sawedoff","weapon_nova","weapon_aug","weapon_m249","weapon_negev","weapon_galilar","weapon_sg556","weapon_m4a1_silencer","weapon_m4a1","weapon_famas","weapon_ak47","weapon_ssg08","weapon_g3sg1","weapon_scar20","weapon_awp","weapon_mac10","weapon_ump45","weapon_hkp2000","weapon_usp_silencer","weapon_p250","weapon_fiveseven","weapon_p90"};
//int _WeaponDamage[][] 		= {63,86,30,38,33,26,29,27,27,31,17,30,32,26,28,32,35,30,30,33,33,30,36,88,80,80,115,29,35,35,35,38,32,26};
//int _WeaponBulletEnergy[][] = {1650,1965,481,481,481,481,447,481,481,490,484,423,423,376,1755,1755,1755,1755,1755,1755,1755,1755,3304,3304,3304,3304,6734,483,483,686,483,686,400,400};
new Float:_WeaponNormalized[][] = {1.136,1.221,1.019,1.024,1.021,1.016,1.017,1.017,1.017,1.020,1.011,1.017,1.018,1.013,1.064,1.073,1.080,1.069,1.069,1.076,1.076,1.069,1.155,1.380,1.345,1.345,2.012,1.018,1.022,1.031,1.022,1.034,1.017,1.014};
// grenade is 0.4 kg so calulated its velocity based off of v = (2*energy)/mass then Normalized the data™ but I didnt want the lowest to be 0 so i did ((velocity * weaponDamage)[this where i removed min velocity]) / (Max velocity - Min velocity)+1)
// idk thats prob not the way to do it at ALL but i stayed up all night and got a idea in the middle of mowing the lawn.
new Float:_WeaponPushScale = 1.0;
char strName[128];
new String:weaponName[256];
new String:argGrenade[128];
new Float:ang[3];
new Float:entityloc[3];
new Float:bulletloc[3];
new Float:vector[3];
new Float:speed;
char NameTest[64];
int clientPlayer;
new maxentities;
int x = MAXPLAYERS+1;

public OnPluginStart()
{
	RegAdminCmd("sm_SetWeaponScale", SetWeaponScale, ADMFLAG_ROOT, "Sets how far grenades will fly based on weapon damage ( def. 1 )");
	HookEvent("bullet_impact", Event_BulletImpact, EventHookMode_Post);
}

public Action SetWeaponScale(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_SetWeaponScale <number>");
		return Plugin_Handled;
	}else if(args == 1)
	{
		GetCmdArg(1, argGrenade, sizeof(argGrenade));
		_WeaponPushScale = StringToFloat(argGrenade);
		return Plugin_Handled;
	}
	ReplyToCommand(client, "Usage: sm_SetWeaponScale <number>");
	ReplyToCommand(client, "You enter too many arguments!");
	return Plugin_Handled;
}

public Action Event_BulletImpact(Event event, const char[] name, bool dontBroadcast)
{
	clientPlayer = GetClientOfUserId(event.GetInt("userid"));
	
	GetClientName(clientPlayer,NameTest,sizeof(NameTest));
	
	bulletloc[0] = event.GetFloat("x");
	bulletloc[1] = event.GetFloat("y");
	bulletloc[2] = event.GetFloat("z");
	
	maxentities = GetMaxEntities();
	
	for ( x = MAXPLAYERS + 1; x <= maxentities; x++)
	{
		if (!IsValidEdict(x))
		{
			continue;
		}
	
		GetEntPropVector(x, Prop_Data, "m_vecOrigin", entityloc);
	
		if (GetVectorDistance(bulletloc, entityloc) <= 15.0)
		{
			GetEdictClassname(x, strName, 128); 
			
			if(StrContains(strName,"projectile",false) != -1){
				GetClientWeapon(clientPlayer,weaponName,sizeof(weaponName));
				
				GetEntPropVector(x, Prop_Data, "m_vecVelocity", vector);
				ScaleVector(vector, _WeaponPushScale * (caliberScale(weaponName)));
				speed = GetVectorLength(vector);
				GetClientEyeAngles(clientPlayer, ang);
				ang[0] *= -1.0;
				ang[0] = DegToRad(ang[0]);
				ang[1] = DegToRad(ang[1]);
				
				vector[0] = vector[0] + (speed * Cosine(ang[0]) * Cosine(ang[1]));
				vector[1] = vector[0] + (speed * Cosine(ang[0]) * Sine(ang[1]));
				vector[2] = vector[0] + (speed * Sine(ang[0]));
				TeleportEntity(x, NULL_VECTOR, NULL_VECTOR, vector);
			}
		}
	}  
}

public int caliberScale(char[] weaponNameCal)
{
	for(int I;I <= sizeof(_WeaponNames);I++)
	{
		if(StrEqual(weaponNameCal, _WeaponNames[I][0] ,false))
		{
			return view_as<int>(_WeaponNormalized[I][0]);
		}
	}
	return 0;
}

//All of this isn't mine.
