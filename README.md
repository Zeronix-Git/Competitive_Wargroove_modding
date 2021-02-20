# Analysis Mod
This mod allows players to undo moves, and save a load states, letting them explore different options. 

### Features
HQ actions
- **Undo**: undo your last move
- **Undo Turn**: undo all moves from this turn
- **Save**: save the current state to one of 9 slots
- **Load**: load a previously saved state from a slot

Unit actions
- **Reposition**: moves a unit to any empty position

### Notes
- At the moment is possible to kill units by repositioning them on walls, or other terrains on which they can't stand
- The undo action can revert a repositioning
- Undoing a move that would take you back to turn of the previous player will result in all units switching owner, to allow the player to move them
- The current turn and player portrait displayed in the UI cannot be updated by the mod. So they might be wrong after you undo moves or load states.

### Installation
1. Download the zip from Github and extract the contents
2. Drag the mod folder onto your wargroove-mod-packer.exe to install the mod

### Feature Wishlist
- Add a means of setting the damage for the next attack. A simple option could be "min / avg / max"; a more advanced option would be setting the exact RNG roll or exact damage value
- Allow "free recruit" in case we forgot to  build certain units

### Contributors
- kingoftheconnors (Kanor on Discord)
-- Added undo action
- gp27 -- Added save, load, reposition actions.