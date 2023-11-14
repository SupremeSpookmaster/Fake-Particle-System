#define DEBUG_FAKE_PARTICLES

#define PLUGIN_NAME           		  "[Any] Fake Particle System"

#define PLUGIN_AUTHOR         "Spookmaster"
#define PLUGIN_DESCRIPTION    "Makes it easier for devs to create fake particle effects by using models."
#define PLUGIN_VERSION        "0.2.0"
#define PLUGIN_URL            "https://github.com/SupremeSpookmaster/Fake-Particle-System"

#pragma semicolon 1

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

#include <fakeparticles>
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <entity>
#include <cfgmap>
#include <dhooks>
#include <collisionhook>

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	FPS_MakeNatives();
	return APLRes_Success;
}

public void OnPluginStart()
{
	//RegAdminCmd("pnpc_reload", PNPC_ReloadNPCs, ADMFLAG_KICK, "Portable NPC System: Reloads the list of enabled PNPCs.");
	
	FPS_MakeForwards();
}

public void FPS_MakeNatives()
{
	RegPluginLibrary("fake_particle_system");
}

public void FPS_MakeForwards()
{
	
}

#define SND_ADMINCOMMAND			"ui/cyoa_ping_in_progress.wav"
#define SND_ADMINCOMMAND_ERROR		"ui/cyoa_ping_in_progress.wav"

#define MAXIMUM_PNPCS				255

public const char s_ModelFileExtensions[][] =
{
	".dx80.vtx",
	".dx90.vtx",
	".mdl",
	".phy",
	".sw.vtx",
	".vvd"
};

public OnMapStart()
{
	FPS_LoadFakes();
	
	PrecacheSound(SND_ADMINCOMMAND);
	PrecacheSound(SND_ADMINCOMMAND_ERROR);
}

public void FPS_LoadFakes()
{
	ConfigMap FakeParticles = new ConfigMap("data/fake_particle_system/fakeparticles.cfg");
	if (FakeParticles == null)
	{
		LogError("data/fake_particle_system/fakeparticles.cfg does not exist!");
		return;
	}
	
	#if defined DEBUG_FAKE_PARTICLES
	PrintToServer("\n\n----------- FAKE PARTICLE SYSTEM DOWNLOADS BEGIN -----------\n\n");
	#endif
	
	int i = 1;
	ConfigMap CurrentSection = FakeParticles.GetSection("particles.1");
	while (CurrentSection != null)
	{
		
		#if defined DEBUG_FAKE_PARTICLES
		PrintToServer("DOWNLOADING ENTRY #%i:\n", i);
		#endif
		
		FPS_ManageFiles(CurrentSection);
		
		#if defined DEBUG_FAKE_PARTICLES
		PrintToServer("\n\n");
		#endif
		
		i++;
		char CurrentSlot[16];
		Format(CurrentSlot, sizeof(CurrentSlot), "particles.%i", i);
		CurrentSection = FakeParticles.GetSection(CurrentSlot);
	}
	
	DeleteCfg(FakeParticles);
	
	#if defined DEBUG_FAKE_PARTICLES
	PrintToServer("----------- FAKE PARTICLE SYSTEM DOWNLOADS END -----------\n\n");
	#endif
}

public void FPS_ManageFiles(ConfigMap FakeParticle)
{
	char modelName[255];
	FakeParticle.Get("model", modelName, sizeof(modelName));
	FPS_DownloadModel(modelName);
	
 	ConfigMap section = FakeParticle.GetSection("materials");
 	if (section != null)
 	{
 		FPS_DownloadMaterials(section);
 	}
}

public void FPS_DownloadModel(char value[255])
{
	char fileCheck[255], actualFile[255];
				
	for (int j = 0; j < sizeof(s_ModelFileExtensions); j++)
	{
		Format(fileCheck, sizeof(fileCheck), "models/%s%s", value, s_ModelFileExtensions[j]);
		Format(actualFile, sizeof(actualFile), "%s%s", value, s_ModelFileExtensions[j]);
		if (CheckFile(fileCheck))
		{
			if (StrEqual(s_ModelFileExtensions[j], ".mdl"))
			{
				#if defined DEBUG_FAKE_PARTICLES
				int check = PrecacheModel(fileCheck);
					
				if (check != 0)
				{
					PrintToServer("Successfully precached file ''%s''.", fileCheck);
				}
				else
				{
					PrintToServer("Failed to precache file ''%s''.", fileCheck);
				}
				#else
				PrecacheModel(fileCheck);
				#endif
			}

			AddFileToDownloadsTable(fileCheck);
						
			#if defined DEBUG_FAKE_PARTICLES
			PrintToServer("Successfully added model file ''%s'' to the downloads table.", fileCheck);
			#endif
		}
		else
		{
			#if defined DEBUG_FAKE_PARTICLES
			PrintToServer("ERROR: Failed to find model file ''%s''.", fileCheck);
			#endif
		}
	}
}

public void FPS_DownloadMaterials(ConfigMap subsection)
{
 	char value[255];
 	
 	for (int i = 1; i <= subsection.Size; i++)
 	{
 		subsection.GetIntKey(i, value, sizeof(value));
 		Format(value, sizeof(value), "materials/%s", value);
 		
 		if (CheckFile(value))
		{
			AddFileToDownloadsTable(value);
			
			#if defined DEBUG_FAKE_PARTICLES
			PrintToServer("Successfully added material ''%s'' to the downloads table.", value);
			#endif
		}
		else
		{
			#if defined DEBUG_FAKE_PARTICLES
			PrintToServer("ERROR: Failed to find material ''%s''.", value);
			#endif
		}
	}
}

public void OnEntityDestroyed(int entity)
{
	if (entity >= 0 && entity < 2049)
	{
		//TODO: This plugin is inevitably going to end up having some global variables tied to fake particles, clean them up here.
	}
}

//Stocks and such, move these to a file like fps_stocks or something before publishing:

/**
 * Checks if a client is valid.
 *
 * @param client			The client to check.
 *
 * @return					True if the client is valid, false otherwise.
 */
stock bool IsValidClient(int client)
{
	if(client <= 0 || client > MaxClients)
	{
		return false;
	}
	
	if(!IsClientInGame(client))
	{
		return false;
	}

	return true;
}

stock Handle getAimTrace(int client, TraceEntityFilter filter)
{
	float eyePos[3];
	float eyeAng[3];
	GetClientEyePosition(client, eyePos);
	GetClientEyeAngles(client, eyeAng);
	
	Handle trace;
	
	trace = TR_TraceRayFilterEx(eyePos, eyeAng, MASK_SHOT, RayType_Infinite, filter);
	
	return trace;
}

public bool Trace_OnlyHitWorld(entity, contentsMask)
{
	return entity == 0;
}

stock int GetIntFromConfigMap(ConfigMap map, char[] path, int defaultValue)
{
	char value[255];
	map.Get(path, value, sizeof(value));
	
	if (StrEqual(value, ""))
	{
		return defaultValue;
	}
	
	return StringToInt(value);
}

stock float GetFloatFromConfigMap(ConfigMap map, char[] path, float defaultValue)
{
	char value[255];
	map.Get(path, value, sizeof(value));
	
	if (StrEqual(value, ""))
	{
		return defaultValue;
	}
	
	return StringToFloat(value);
}

stock bool GetBoolFromConfigMap(ConfigMap map, char[] path, bool defaultValue)
{
	char value[255];
	map.Get(path, value, sizeof(value));
	
	if (StrEqual(value, ""))
	{
		return defaultValue;
	}
	
	return (StringToInt(value) != 0);
}

/**
 * Checks if a file exists.
 *
 * @param path			The file to check.
 *
 * @return					True if it exists, false otherwise.
 */
stock bool CheckFile(char path[255])
{
	bool exists = false;
	
	if (FileExists(path))
	{
		exists = true;
	}
	else
	{
		if (FileExists(path, true))
		{
			exists = true;
		}
	}
	
	return exists;
}