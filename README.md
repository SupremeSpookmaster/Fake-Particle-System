# *Overview*
Multiplayer Source games (specifically ***Team Fortress 2***, the game for which this mod was written) are a fantastic place for budding game developers to hone their skills and express their creativity without the need for years of prior experience. A game dev who is just beginning to learn isn't going to know how to make a 3D model, make animations, or design sounds, and they certainly aren't going to have the capital to hire a team to do all of that for them; borrowing from the game's own files allows you to sidestep these limitations and not only practice game design, but even share your work with a community who may come to love what you've made. However, this approach is not without its limitations; when your work is so dependent on an existing engine, you must play by that engine's rules, and one of the biggest limitations of the Source engine is that **you cannot force players to download custom particle effects.**

## Get to the point already! What does the ***Fake Particle System*** actually do?
The most effective way to sidestep the Source engine's inability to download custom particles is to instead make clever use of models and materials, which *can* be downloaded, to mimic particle effects. The ***Fake Particle System*** is a simple plugin which eases the implementation of these "fake particles" by [automatically adding the files for your fake particles to the downloads table](https://github.com/SupremeSpookmaster/Fake-Particle-System/blob/main/addons/sourcemod/data/fake_particle_system/fakeparticles.cfg), while also providing [several helpful natives for programmers to use](https://github.com/SupremeSpookmaster/Fake-Particle-System/wiki/Forwards-and-Natives) alongside these fake particles.

# *Preview the Fake Particle System in action!*
TODO: Post gifs of the fake particle system in action.

# *KNOWN LIMITATIONS/BUGS*
Be forewarned that this plugin is not perfect; I did what I could to get it as close to perfect as possible, but there are certain kinks with TF2's version of the Source engine which cannot be worked around.
- FPEs (Fake Particle Effects) which have been parented to an object cannot play their own sequences.
- If an FPE is parented to a player, that FPE rotates automatically when that player moves their mouse. This rotation is only visible to the client the FPE is parented to, and appears completely normal to all other players.
