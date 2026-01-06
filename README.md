--[[ 
ESP MODULE – INITIAL IMPLEMENTATION

Goal:
Add a lightweight, client-side ESP system integrated with LinoriaLib UI.

Requirements:
- Toggleable via UI
- Supports Player ESP only (for now)
- Displays:
    • Name
    • 2D bounding box
- Color customizable via ColorPicker
- Automatically:
    • Adds ESP when players join
    • Removes ESP when players leave
    • Updates on character respawn
- Uses Drawing API (no BillboardGui)
- Minimal performance impact
- Clean separation between UI logic and ESP logic

Future Expansion (not required now):
- Distance text
- Team check
- Health bar
- Tracers
- NPC support
]]
