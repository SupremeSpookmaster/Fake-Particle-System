#if defined _fps_included_
  #endinput
#endif
#define _fps_included_

enum FPS_ParticleType
{
	FPS_ParticleType_None = -1,
	FPS_ParticleType_Normal,
	FPS_ParticleType_Billboard
};

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
		if (IsValidClient(target))
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
		//TODO: Call FPS_OnFakeParticleRemoved
	}
}

//TODO: Rename this to just FPE_Transmit and block fake particles from being transmitted if they are parented to the client and the client is in first person
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

/**
 * Spawns a model at the given coordinates. Intended to be used to spawn fake particle effects.
 *
 * @param pos		The position at which to spawn the fake particle effect.
 * @param ang		The angles with which the fake particle effect should be spawned.
 * @param particle	The model name of the fake particle effect.
 * @param skin		Model skin to use for the fake particle effect.
 * @param sequence	Optional sequence for the fake particle effect to use.
 * @param rate		Optional playback rate for the fake particle effect's sequence to use, if a sequence is assigned.
 * @param duration	Optional duration of the fake particle effect. 0.0 or below: infinite.
 * @param r			Optional render color parameter for the fake particle effect to use, R value, 0-255.
 * @param g			Optional render color parameter for the fake particle effect to use, G value, 0-255.
 * @param b			Optional render color parameter for the fake particle effect to use, B value, 0-255.
 * @param alpha		Optional render color parameter for the fake particle effect to use, alpha value, 0-255.
 * @param scale		Optional model scale for the fake particle effect.
 *
 * @return The entity index of the fake particle effect which was spawned.
 * @error  The model passed to the ''particle'' parameter does not exist.
 */
native int FPS_SpawnFakeParticle(float pos[3], float ang[3], char particle[255], int skin, char sequence[255] = "ref", float rate = 1.0, float duration = 0.0, int r = 255, int g = 255, int b = 255, int alpha = 255, float scale = 1.0);

/**
 * Attaches a model to a given entity. Intended to be used to attach fake particle effects to entities.
 *
 * @param entity	The entity to attach the fake particle effect to.
 * @param point		The attachment point to attach the fake particle effect to.
 * @param particle	The model name of the fake particle effect.
 * @param skin		Model skin to use for the fake particle effect.
 * @param sequence	Optional sequence for the fake particle effect to use.
 * @param rate		Optional playback rate for the fake particle effect's sequence to use, if a sequence is assigned.
 * @param duration	Optional duration of the fake particle effect. 0.0 or below: infinite.
 * @param r			Optional render color parameter for the fake particle effect to use, R value, 0-255.
 * @param g			Optional render color parameter for the fake particle effect to use, G value, 0-255.
 * @param b			Optional render color parameter for the fake particle effect to use, B value, 0-255.
 * @param alpha		Optional render color parameter for the fake particle effect to use, alpha value, 0-255.
 * @param scale		Optional model scale for the fake particle effect.
 * @param posOffset	Optional positional offset.
 * @param angOffset Optional angle offset.
 *
 * @return The entity index of the fake particle effect which was attached.
 * @error  Invalid entity index passed to the ''entity'' parameter, or the model passed to the ''particle'' parameter does not exist. 
 */
native int FPS_AttachFakeParticleToEntity(int entity, char point[255], char particle[255], int skin, char sequence[255] = "ref", float rate = 1.0, float duration = 0.0, int r = 255, int g = 255, int b = 255, int alpha = 255, float scale = 1.0, float posOffset[3] = NULL_VECTOR, float angOffset[3] = NULL_VECTOR);

/**
 * Spawns a unique model at the given coordinates for every client, which faces its target client at all times. 
 * Example: if you've ever played Super Mario 64, this does what the trees in the starting area do, for *every* client.
 * As such, billboard particles are VERY expensive on the entity limit and should be used sparingly.
 *
 * @param pos		The position at which to spawn the fake particle effect.
 * @param particle	The model name of the fake particle effect.
 * @param skin		Model skin to use for the fake particle effect.
 * @param sequence	Optional sequence for the fake particle effect to use.
 * @param rate		Optional playback rate for the fake particle effect's sequence to use, if a sequence is assigned.
 * @param duration	Optional duration of the fake particle effect. 0.0 or below: infinite.
 * @param r			Optional render color parameter for the fake particle effect to use, R value, 0-255.
 * @param g			Optional render color parameter for the fake particle effect to use, G value, 0-255.
 * @param b			Optional render color parameter for the fake particle effect to use, B value, 0-255.
 * @param alpha		Optional render color parameter for the fake particle effect to use, alpha value, 0-255.
 * @param scale		Optional model scale for the fake particle effect.
 *
 * @return An array handle containing the entity references of every model spawned by this method. DELETE THIS HANDLE WHEN YOU ARE DONE WITH IT, EVEN IF YOU DO NOT USE IT AT ALL!
 * @error  The model passed to the ''particle'' parameter does not exist.
 */
native Handle FPS_SpawnBillboardParticle(float pos[3], char particle[255], int skin, char sequence[255] = "ref", float rate = 1.0, float duration = 0.0, int r = 255, int g = 255, int b = 255, int alpha = 255, float scale = 1.0);

/**
 * Functions the same as FPS_SpawnBillboardParticle, but with the added functionality of allowing you to attach the model to a given entity.
 *
 * @param entity	The entity to attach the fake particle effect to.
 * @param point		The attachment point to attach the fake particle effect to.
 * @param particle	The model name of the fake particle effect.
 * @param skin		Model skin to use for the fake particle effect.
 * @param sequence	Optional sequence for the fake particle effect to use.
 * @param rate		Optional playback rate for the fake particle effect's sequence to use, if a sequence is assigned.
 * @param duration	Optional duration of the fake particle effect. 0.0 or below: infinite.
 * @param r			Optional render color parameter for the fake particle effect to use, R value, 0-255.
 * @param g			Optional render color parameter for the fake particle effect to use, G value, 0-255.
 * @param b			Optional render color parameter for the fake particle effect to use, B value, 0-255.
 * @param alpha		Optional render color parameter for the fake particle effect to use, alpha value, 0-255.
 * @param scale		Optional model scale for the fake particle effect.
 * @param posOffset	Optional positional offset.
 *
 * @return An array handle containing the entity references of every model spawned by this method. DELETE THIS HANDLE WHEN YOU ARE DONE WITH IT, EVEN IF YOU DO NOT USE IT AT ALL!
 * @error  Invalid entity index passed to the ''entity'' parameter, or the model passed to the ''particle'' parameter does not exist. 
 */
native Handle FPS_AttachBillboardParticleToEntity(int entity, char point[255], char particle[255], int skin, char sequence[255] = "ref", float rate = 1.0, float duration = 0.0, int r = 255, int g = 255, int b = 255, int alpha = 255, float scale = 1.0, float posOffset[3] = NULL_VECTOR);