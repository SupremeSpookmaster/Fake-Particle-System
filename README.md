# Overview
Multiplayer Source games (specifically ***Team Fortress 2***, the game for which this mod was written) are a fantastic place for budding game developers to hone their skills and express their creativity without the need for years of prior experience. A game dev who is just beginning to learn isn't going to know how to make a 3D model, make animations, or design sounds, and they certainly aren't going to have the capital to hire a team to do all of that for them; borrowing from the game's own files allows you to sidestep these limitations and not only practice game design, but even share your work with a community who may come to love what you've made. However, this approach is not without its limitations; when your work is so dependent on an existing engine, you must play by that engine's rules, and one of the biggest limitations of the Source engine is that **you cannot force players to download custom particle effects.**

## Get to the point already! What does the ***Fake Particle System*** actually do?
The most effective way to sidestep the Source engine's inability to download custom particles is to instead make clever use of models and materials, which *can* be downloaded, to mimic particle effects. The ***Fake Particle System*** is a simple plugin which eases the implementation of these "fake particles" by [automatically adding the files for your fake particles to the downloads table](https://github.com/SupremeSpookmaster/Fake-Particle-System/blob/main/addons/sourcemod/data/fake_particle_system/fakeparticles.cfg), while also providing [several helpful natives for programmers to use]() alongside these fake particles.

TODO: Post gifs of the fake particle system in action.
