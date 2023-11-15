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
#include <fps_stocks>

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	FPS_MakeNatives();
	return APLRes_Success;
}

////////////////////////////////////////////////////////////////////////
//		TODO: Various ideas for features:
//
//		FPS_ParticleType: Comes with FPS_ParticleType_Normal, which is just a normal model, and FPS_ParticleType_Billboard, which displays a unique model to each player which is always facing that player. Billboard is WAY more expensive and should be used sparingly.
//				- Billboard will use its own spawning native which will return a list of all entity indexes which were spawned.
//
//		FPS_OnFakeParticleCreated(char particle[255], float pos[3], float ang[3], float scale, int r, int g, int b, int alpha, int skin): 
//				- Called when a FPE is created.
//		FPS_OnFakeParticleRemoved(char particle[255], float pos[3], float ang[3], float scale, int r, int g, int b, int alpha, int skin):
//				- Called when a FPE is removed.
////////////////////////////////////////////////////////////////////////

FakeParticleEffect ActiveEffects[2049];

enum struct FakeParticleEffect
{
	int EntIndex;
	int BillboardTarget;
	
	FPS_ParticleType Type;
	
	void Create(int newIndex, FPS_ParticleType newType, int target = 0)
	{
		this.EntIndex = newIndex;
		this.Type = newType;
		this.BillboardTarget = GetClientUserId(target);
		
		if (this.Type == FPS_ParticleType_Billboard)
		{
			SetEdictFlags(this.EntIndex, GetEdictFlags(this.EntIndex)&(~FL_EDICT_ALWAYS));
			SDKHook(this.EntIndex, SDKHook_SetTransmit, FPE_BillboardTransmit);
		}
	}
	
	void Remove()
	{
		if (IsValidEntity(this.EntIndex))
		{
			RemoveEntity(this.EntIndex);
		}
		
		this.Delete();
	}
	
	void Delete()
	{
		this.EntIndex = -1;
		this.BillboardTarget = -1;
		this.Type = FPS_ParticleType_None;
	}
}

public Action FPE_BillboardTransmit(int entity, int client)
{
 	SetEdictFlags(entity, GetEdictFlags(entity)&(~FL_EDICT_ALWAYS));
 	
 	int target = GetClientOfUserId(ActiveEffects[entity].BillboardTarget);
 	if (client != target)
 	{
 		return Plugin_Handled;
 	}
 	
 	//Orient the entity to always face directly at the target's eyes:
	float ang[3], pos[3], eyePos[3], DummyAngles[3], fVecFinal[3], fFinalPos[3];
	GetClientEyePosition(target, eyePos);
	GetClientEyeAngles(target, DummyAngles);
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
	GetEntPropVector(entity, Prop_Send, "m_angRotation", ang);	
	
	AddInFrontOf(eyePos, DummyAngles, 7.0, fVecFinal);
	MakeVectorFromPoints(pos, fVecFinal, fFinalPos);

	GetVectorAngles(fFinalPos, ang);
 	
 	TeleportEntity(entity, NULL_VECTOR, ang, NULL_VECTOR);
 	
 	return Plugin_Continue;
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
		ActiveEffects[entity].Delete();
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
		
		SetEntityRenderColor(FakeParticle, r, g, b, alpha);
		SetEntPropFloat(FakeParticle, Prop_Send, "m_flModelScale", scale); 
		
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
	
	int FakeParticle = FPS_SpawnFakeParticle(OFF_THE_MAP, NULL_VECTOR, particle, skin, sequence, rate, duration, r, g, b, alpha, scale);
	if (IsValidEntity(FakeParticle))
	{
		float pos[3], ang[3];
		if (HasEntProp(entity, Prop_Data, "m_vecAbsOrigin"))
		{
			GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", pos);
		}
		else if (HasEntProp(entity, Prop_Send, "m_vecOrigin"))
		{
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
		}
		
		TeleportEntity(FakeParticle, pos, NULL_VECTOR, NULL_VECTOR);
	
		SetVariantString("!activator");
		AcceptEntityInput(FakeParticle, "SetParent", entity, FakeParticle);
		SetVariantString(point);
		AcceptEntityInput(FakeParticle, "SetParentAttachmentMaintainOffset", FakeParticle, FakeParticle);
		DispatchKeyValue(FakeParticle, "targetname", "present");
		
		GetEntPropVector(FakeParticle, Prop_Send, "m_vecOrigin", pos);
		GetEntPropVector(FakeParticle, Prop_Send, "m_angRotation", ang);
		
		for (int i = 0; i < 3; i++)
		{
			pos[i] += posOffset[i];
			ang[i] += angOffset[i];
		}
		
		TeleportEntity(FakeParticle, pos, ang, NULL_VECTOR);
		
		return FakeParticle;
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
				
				if (duration > 0.0)
				{
					CreateTimer(duration, Timer_RemoveEntity, EntIndexToEntRef(FakeParticle), TIMER_FLAG_NO_MAPCHANGE);
				}
				
				//TODO: Use RequestFrame to call FPS_OnFakeParticleCreated on the next frame.
				
				ActiveEffects[FakeParticle].Create(FakeParticle, FPS_ParticleType_Billboard, client);
				
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
	
	GetNativeArray(13, posOffset, sizeof(posOffset));
	
	Handle FakeParticles = FPS_SpawnBillboardParticle(OFF_THE_MAP, particle, skin, sequence, rate, duration, r, g, b, alpha, scale);
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
		
			SetVariantString("!activator");
			AcceptEntityInput(FakeParticle, "SetParent", entity, FakeParticle);
			SetVariantString(point);
			AcceptEntityInput(FakeParticle, "SetParentAttachmentMaintainOffset", FakeParticle, FakeParticle);
			DispatchKeyValue(FakeParticle, "targetname", "present");
			
			GetEntPropVector(FakeParticle, Prop_Send, "m_vecOrigin", pos);
			
			for (int j = 0; j < 3; j++)
			{
				pos[j] += posOffset[j];
			}
			
			TeleportEntity(FakeParticle, pos, NULL_VECTOR, NULL_VECTOR);
		}
	}
	
	return FakeParticles;
}