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
#include <tf2_stocks>
#include <queue>
#include <cfgmap>
#include <sdkhooks>

float OFF_THE_MAP[3] = {1182792704.0, 1182792704.0, -964690944.0};

#define MODEL_DEFAULT	"models/props_c17/cashregister01a.mdl"

#include "fake_particles/particle_simulation.sp"
#include "fake_particles/particle_body.sp"

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
	
	CreateNative("FPS_SpawnFakeParticle", Native_FPS_SpawnFakeParticle);
	CreateNative("FPS_AttachFakeParticleToEntity", Native_FPS_AttachFakeParticleToEntity);
	CreateNative("FPS_SpawnBillboardParticle", Native_FPS_SpawnBillboardParticle);
	CreateNative("FPS_AttachBillboardParticleToEntity", Native_FPS_AttachBillboardParticleToEntity);
	
	PSim_MakeNatives();
	PBod_MakeNatives();
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
	
	PrecacheModel(MODEL_DEFAULT);
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
		ActiveEffects[entity].Delete();
		
		ParticleSimulation PSim = view_as<ParticleSimulation>(entity);
		if (PSim.Exists)
		{
			PSim.Destroy();
			PSim.Exists = false;
		}
		
		ParticleBody PBod = view_as<ParticleBody>(entity);
		if (PBod.Exists)
		{
			PBod.Destroy();
			PBod.Exists = false;
		}
	}
}

public Native_FPS_SpawnFakeParticle(Handle plugin, int numParams)
{
	float pos[3], ang[3];
	char particle[255], sequence[255];
	GetNativeArray(1, pos, sizeof(pos));
	GetNativeArray(2, ang, sizeof(ang));
	
	GetNativeString(3, particle, sizeof(particle));
	int skin = GetNativeCell(4);
	GetNativeString(5, sequence, sizeof(sequence));
	float rate = GetNativeCell(6);
	float duration = GetNativeCell(7);
	int r = GetNativeCell(8);
	int g = GetNativeCell(9);
	int b = GetNativeCell(10);
	int alpha = GetNativeCell(11);
	float scale = GetNativeCell(12);
	
	int FakeParticle = CreateEntityByName("prop_dynamic_override");
	if (IsValidEntity(FakeParticle))
	{
		TeleportEntity(FakeParticle, pos, ang, NULL_VECTOR);
	
		char skinChar[16];
		Format(skinChar, sizeof(skinChar), "%i", skin);
	
		DispatchKeyValue(FakeParticle, "skin", skinChar);
		DispatchKeyValue(FakeParticle, "model", particle);	
		
		DispatchKeyValueVector(FakeParticle, "angles", ang);
		
		DispatchSpawn(FakeParticle);
		ActivateEntity(FakeParticle);
		
		SetVariantString(sequence);
		AcceptEntityInput(FakeParticle, "SetAnimation");
		DispatchKeyValueFloat(FakeParticle, "playbackrate", rate);
		
		SetEntityRenderMode(FakeParticle, RENDER_TRANSALPHA);
		SetEntityRenderColor(FakeParticle, r, g, b, alpha);
		SetEntPropFloat(FakeParticle, Prop_Send, "m_flModelScale", scale); 
		
		//AcceptEntityInput(FakeParticle, "DisableShadow");
		DispatchKeyValue(FakeParticle, "shadowcastdist", "0");
		DispatchKeyValue(FakeParticle, "disablereceiveshadows", "1");
		DispatchKeyValue(FakeParticle, "disableshadows", "1");
		DispatchKeyValue(FakeParticle, "disableshadowdepth", "1");
		DispatchKeyValue(FakeParticle, "disableselfshadowing", "1"); 
		
		if (duration > 0.0)
		{
			CreateTimer(duration, Timer_RemoveEntity, EntIndexToEntRef(FakeParticle), TIMER_FLAG_NO_MAPCHANGE);
		}
		
		//TODO: Use RequestFrame to call FPS_OnFakeParticleCreated on the next frame.
		
		ActiveEffects[FakeParticle].Create(FakeParticle, FPS_ParticleType_Normal);
		
		return FakeParticle;
	}
	
	return -1;
}

public Native_FPS_AttachFakeParticleToEntity(Handle plugin, int numParams)
{
	int entity = GetNativeCell(1);
	
	float posOffset[3], angOffset[3];
	char particle[255], sequence[255], point[255];
	GetNativeString(2, point, sizeof(point));
	
	GetNativeString(3, particle, sizeof(particle));
	int skin = GetNativeCell(4);
	GetNativeString(5, sequence, sizeof(sequence));
	float rate = GetNativeCell(6);
	float duration = GetNativeCell(7);
	int r = GetNativeCell(8);
	int g = GetNativeCell(9);
	int b = GetNativeCell(10);
	int alpha = GetNativeCell(11);
	float scale = GetNativeCell(12);
	
	GetNativeArray(13, posOffset, sizeof(posOffset));
	GetNativeArray(14, angOffset, sizeof(angOffset));
	
	float pos[3], ang[3];
	if (HasEntProp(entity, Prop_Data, "m_vecAbsOrigin"))
	{
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", pos);
	}
	else if (HasEntProp(entity, Prop_Send, "m_vecOrigin"))
	{
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
	}
	
	if (IsValidClient(entity))
	{
		GetClientAbsOrigin(entity, pos);
		GetClientAbsAngles(entity, ang);
	}
	else
	{
		GetEntPropVector(entity, Prop_Data, "m_angRotation", ang); 
	}
		
	int FakeParticle = FPS_SpawnFakeParticle(pos, ang, particle, skin, sequence, rate, duration, r, g, b, alpha, scale);
	if (IsValidEntity(FakeParticle))
	{
		int info = ParentInfoTarget(entity, point);
		
		SetVariantString("!activator");
		AcceptEntityInput(FakeParticle, "SetParent", info, FakeParticle);
		DispatchKeyValue(FakeParticle, "targetname", "present");
		SetEntPropEnt(FakeParticle, Prop_Send, "m_hOwnerEntity", entity);
			
		GetEntPropVector(FakeParticle, Prop_Send, "m_vecOrigin", pos);
		GetEntPropVector(FakeParticle, Prop_Send, "m_angRotation", ang);
			
		//TODO: This breaks them in Chaos Fortress for some reason????????????????????
		//Need to find a fix and publish the fixed version to GitHub, then add the FPS to prerequisites.
		/*for (int i = 0; i < 3; i++)
		{
			pos[i] += posOffset[i];
			ang[i] += angOffset[i];
		}
			
		TeleportEntity(FakeParticle, pos, ang, NULL_VECTOR);*/
			
		DispatchSpawn(FakeParticle);
		ActivateEntity(FakeParticle);
		
		SetVariantString(sequence);
		AcceptEntityInput(FakeParticle, "SetAnimation");
		DispatchKeyValueFloat(FakeParticle, "playbackrate", rate);
		
		return FakeParticle;
	}
	
	return -1;
}

int ParentInfoTarget(int entity, char point[255])
{
	int info = CreateEntityByName("info_target");
	if (IsValidEntity(info))
	{
		float pos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
		TeleportEntity(info, pos, NULL_VECTOR, NULL_VECTOR);
		
		SetVariantString("!activator");
		AcceptEntityInput(info, "SetParent", entity, info);
		SetVariantString(point);
		AcceptEntityInput(info, "SetParentAttachmentMaintainOffset", info, info);
		DispatchKeyValue(info, "targetname", "dummycam"); 
		DispatchSpawn(info);
		ActivateEntity(info);
		AcceptEntityInput(info, "Start");
		
		return info;
	}
	
	return -1;
}

public any Native_FPS_SpawnBillboardParticle(Handle plugin, int numParams)
{
	float pos[3], ang[3];
	char particle[255], sequence[255];
	GetNativeArray(1, pos, sizeof(pos));
	
	GetNativeString(2, particle, sizeof(particle));
	int skin = GetNativeCell(3);
	GetNativeString(4, sequence, sizeof(sequence));
	float rate = GetNativeCell(5);
	float duration = GetNativeCell(6);
	int r = GetNativeCell(7);
	int g = GetNativeCell(8);
	int b = GetNativeCell(9);
	int alpha = GetNativeCell(10);
	float scale = GetNativeCell(11);
	bool xRot = GetNativeCell(12);
	bool yRot = GetNativeCell(13);
	bool zRot = GetNativeCell(14);
	
	Handle ReturnValue = CreateArray(16);
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			int FakeParticle = CreateEntityByName("prop_dynamic_override");
			if (IsValidEntity(FakeParticle))
			{
				TeleportEntity(FakeParticle, pos, ang, NULL_VECTOR);
			
				char skinChar[16];
				Format(skinChar, sizeof(skinChar), "%i", skin);
			
				DispatchKeyValue(FakeParticle, "skin", skinChar);
				DispatchKeyValue(FakeParticle, "model", particle);	
				
				DispatchKeyValueVector(FakeParticle, "angles", ang);
				
				DispatchSpawn(FakeParticle);
				ActivateEntity(FakeParticle);
				
				SetVariantString(sequence);
				AcceptEntityInput(FakeParticle, "SetAnimation");
				DispatchKeyValueFloat(FakeParticle, "playbackrate", rate);
				
				SetEntityRenderColor(FakeParticle, r, g, b, alpha);
				SetEntPropFloat(FakeParticle, Prop_Send, "m_flModelScale", scale); 
				
				AcceptEntityInput(FakeParticle, "DisableShadow");
				
				if (duration > 0.0)
				{
					CreateTimer(duration, Timer_RemoveEntity, EntIndexToEntRef(FakeParticle), TIMER_FLAG_NO_MAPCHANGE);
				}
				
				//TODO: Use RequestFrame to call FPS_OnFakeParticleCreated on the next frame.
				
				ActiveEffects[FakeParticle].Create(FakeParticle, FPS_ParticleType_Billboard, client, xRot, yRot, zRot);
				
				PushArrayCell(ReturnValue, EntIndexToEntRef(FakeParticle));
			}
		}
	}
	
	return ReturnValue;
}

public any Native_FPS_AttachBillboardParticleToEntity(Handle plugin, int numParams)
{
	int entity = GetNativeCell(1);
	
	float posOffset[3];
	char particle[255], sequence[255], point[255];
	GetNativeString(2, point, sizeof(point));
	
	GetNativeString(3, particle, sizeof(particle));
	int skin = GetNativeCell(4);
	GetNativeString(5, sequence, sizeof(sequence));
	float rate = GetNativeCell(6);
	float duration = GetNativeCell(7);
	int r = GetNativeCell(8);
	int g = GetNativeCell(9);
	int b = GetNativeCell(10);
	int alpha = GetNativeCell(11);
	float scale = GetNativeCell(12);
	bool xRot = GetNativeCell(13);
	bool yRot = GetNativeCell(14);
	bool zRot = GetNativeCell(15);
	
	GetNativeArray(13, posOffset, sizeof(posOffset));
	
	Handle FakeParticles = FPS_SpawnBillboardParticle(OFF_THE_MAP, particle, skin, sequence, rate, duration, r, g, b, alpha, scale, xRot, yRot, zRot);
	for (int i = 0; i < GetArraySize(FakeParticles); i++)
	{
		int FakeParticle = EntRefToEntIndex(GetArrayCell(FakeParticles, i));
		if (IsValidEntity(FakeParticle))
		{
			float pos[3];
			if (HasEntProp(entity, Prop_Data, "m_vecAbsOrigin"))
			{
				GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", pos);
			}
			else if (HasEntProp(entity, Prop_Send, "m_vecOrigin"))
			{
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
			}
			
			TeleportEntity(FakeParticle, pos, NULL_VECTOR, NULL_VECTOR);
		
			int info = ParentInfoTarget(entity, point);
		
			SetVariantString("!activator");
			AcceptEntityInput(FakeParticle, "SetParent", info, FakeParticle);
			DispatchKeyValue(FakeParticle, "targetname", "present");
			SetEntPropEnt(FakeParticle, Prop_Send, "m_hOwnerEntity", entity);
			
			GetEntPropVector(FakeParticle, Prop_Send, "m_vecOrigin", pos);
			
			for (int j = 0; j < 3; j++)
			{
				pos[j] += posOffset[j];
			}
			
			TeleportEntity(FakeParticle, pos, NULL_VECTOR, NULL_VECTOR);
			
			SetVariantString(sequence);
			AcceptEntityInput(FakeParticle, "SetAnimation");
			DispatchKeyValueFloat(FakeParticle, "playbackrate", rate);
		}
	}
	
	return FakeParticles;
}

//STOCKS BELOW, too lazy to make a separate .inc file:

stock Handle GetPluginHandle(char plugin[255])
{
	char buffer[PLATFORM_MAX_PATH];
	Handle iter = GetPluginIterator();
	while (MorePlugins(iter))
	{
		Handle plug = ReadPlugin(iter);
		GetPluginFilename(plug, buffer, sizeof(buffer));
		
		int highest = -1;
		for(int i = strlen(buffer)-1; i > 0; i--)
		{
			if(buffer[i] == '/' || buffer[i] == '\\')
			{
				highest = i;
				break;
			}
		}
		
		ReplaceString(buffer, sizeof(buffer), ".smx", "");
		
		if(StrEqual(buffer[highest+1], plugin))
		{
			delete iter;
			return plug;
		}
	}
	
	delete iter;
	return INVALID_HANDLE;
}

stock int SpawnParticle(float origin[3], char particle[255], float duration = 0.0)
{
	int Effect = CreateEntityByName("info_particle_system");
	if (IsValidEdict(Effect))
	{
		TeleportEntity(Effect, origin, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(Effect, "effect_name", particle);
		SetVariantString("!activator");
		DispatchKeyValue(Effect, "targetname", "present");
		DispatchSpawn(Effect);
		ActivateEntity(Effect);
		AcceptEntityInput(Effect, "Start");
		
		if (duration > 0.0)
		{
			CreateTimer(duration, Timer_RemoveEntity, EntIndexToEntRef(Effect), TIMER_FLAG_NO_MAPCHANGE);
		}
		
		return Effect;
	}
	
	return -1;
}

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

public Action Timer_RemoveEntity(Handle removeEnt, int entityId)
{
	int entity = EntRefToEntIndex(entityId);
	if (IsValidEntity(entity) && entity > MaxClients)
	{
		TeleportEntity(entity, OFF_THE_MAP, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(entity, "Kill");
		RemoveEntity(entity);
	}
	return Plugin_Continue;
}

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

stock void AddInFrontOf(float fVecOrigin[3], float fVecAngle[3], float fUnits, float fOutPut[3])
{
	float fVecView[3]; GetViewVector(fVecAngle, fVecView);
	
	fOutPut[0] = fVecView[0] * fUnits + fVecOrigin[0];
	fOutPut[1] = fVecView[1] * fUnits + fVecOrigin[1];
	fOutPut[2] = fVecView[2] * fUnits + fVecOrigin[2];
}

stock bool IsPlayerInvis(int client)
{
	if (!IsValidClient(client))
		return false;
		
	//Check for empty model:
	char model[255];
	GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
	
	if (StrContains(model, "empty.mdl") != -1)
		return true;
		
	//Check for zero alpha:
	int r, g, b, a;
	GetEntityRenderColor(client, r, g, b, a);
	if (a == 0)
		return true;
	
	//Check for RENDERFX_NONE and TF2's invisibility conditions:
	return GetEntityRenderMode(client) == RENDER_NONE || TF2_IsPlayerInCondition(client, TFCond_Cloaked) || TF2_IsPlayerInCondition(client, TFCond_Stealthed) || TF2_IsPlayerInCondition(client, TFCond_StealthedUserBuffFade);
}

stock void GetViewVector(float fVecAngle[3], float fOutPut[3])
{
	fOutPut[0] = Cosine(fVecAngle[1] / (180 / FLOAT_PI));
	fOutPut[1] = Sine(fVecAngle[1] / (180 / FLOAT_PI));
	fOutPut[2] = -Sine(fVecAngle[0] / (180 / FLOAT_PI));
}