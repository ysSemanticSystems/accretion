---
id: vision
title: Game Vision
status: active
layer: game-design
depends_on: []
last_reviewed: 2026-06-21
---

# Game vision

**Fly a ship through the universe, collect and refine materials, upgrade your
vessel, and eventually grow powerful enough to traverse a black hole** — with
every physical number honest and cited.

## Pillars

1. **Explore first** — 3rd person flight, navigation, and sector discovery are
   the core loop in the current slice.
2. **Collect and refine** — tractor beams, mining lasers, onboard refinery;
   no combat until collection is fully established.
3. **Scientific honesty** — physics in `accretion-core`; presentation shows, never computes.
4. **Prestige through traversal** — black-hole crossing as a future one-way reset
   (deferred); wormholes as in-universe shortcuts (deferred).
5. **Solo only** — no multiplayer; local sector state.

## Long-term arc (deferred)

The existing black-hole survival sim (Eddington limit, disk integrity, mass
milestones) remains in the codebase as a capstone layer to integrate after
explore + collection are complete.

## Visual identity

HDR lensing black hole (Tyler Kennedy shader), procedural starfield, ship that
grows from escape-pod scale toward endgame hull — prestige fantasy where universe
N's starter ship resembles universe N+4's lifeboat.

See [locked-decisions.md](locked-decisions.md) for current scope locks.
