# Introducing the Fake Particle System!
One major limitation of the Source engine is that you cannot force clients to download custom particles. The FPS exists to help devs most effective way to sidestep this limitation by making clever use of models and materials, which *can* be downloaded, to mimic particle effects. It eases the implementation of these "fake particles" by [automatically adding the files for your fake particles to the downloads table](https://github.com/SupremeSpookmaster/Fake-Particle-System/blob/main/addons/sourcemod/data/fake_particle_system/fakeparticles.cfg), while also providing [several helpful natives for programmers to use](https://github.com/SupremeSpookmaster/Fake-Particle-System/wiki/Forwards-and-Natives) alongside these fake particles.

# *Preview the Fake Particle System in action!*
TODO: Post gifs of the fake particle system in action.

# *KNOWN LIMITATIONS/BUGS*
Be forewarned that this plugin is not perfect; I did what I could to get it as close to perfect as possible, but there are certain kinks with TF2's version of the Source engine which cannot be worked around.
- If an FPE is parented to a player, that FPE rotates automatically when that player moves their mouse. This rotation is only visible to the client the FPE is parented to, and the FPE will appear completely normal to all other players.
- Fake Particle Simulations can be extremely expensive on the entity limit, so they should be used with caution.
