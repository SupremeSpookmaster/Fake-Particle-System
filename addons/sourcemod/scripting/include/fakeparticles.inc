#if defined _fps_included_
  #endinput
#endif
#define _fps_included_

enum FPS_ParticleType
{
	FPS_ParticleType_Normal = 0,
	FPS_ParticleType_Billboard
};

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