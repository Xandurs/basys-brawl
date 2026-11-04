# Basys Brawl

EE2026 (NUS) design project: a 2D fighting game on the Basys 3 FPGA with a PMOD OLED (96x64).

P1 fights the CPU, then P2 fights the CPU. Whoever KOs the CPU fastest wins.
If only one player gets a KO, that player wins. If neither does, the player who
left the CPU with less health wins.

## Team

| Member  | Parts |
|---------|-------|
| Oliver  | `fighter`, `fighter_draw`, `game_tick`, `button_input` |
| Karthi  | `special_top`, `special_fireball`, `special_def`, `special_dash`, `special_ult`, `ult_unlocker` |
| Yuhan   | `c_cpu`, `ai_decision`, `cpu_control`, `lfsr`, `control_menu`, `menu_render`, `font_render` |
| Xander  | `Top_Basys_Brawl`, `game_flow`, `combat`, `hud`, `font5x7`, `digit_pixel`, `flow_seg`, `num_to_seg` |

## Building

1. Clone the repo to a short path (e.g. `C:\EE2026\basys-brawl`). Long paths can break Vivado on Windows.
2. Open `Basys_Brawl.xpr` in Vivado. All sources and the constraints file are already in the project, and `Top_Basys_Brawl` is set as top.
3. Run Generate Bitstream, then Hardware Manager → Program Device.

The first synthesis after cloning may warn that the incremental checkpoint is missing. That's expected (it's a build file we don't commit), and Vivado just runs a full synthesis.

Source files live in `Basys_Brawl.srcs/sources_1/`. Teammates' modules are under `imports/`, keeping the paths Vivado gave them when they were added.

Device: `xc7a35tcpg236-1` (Basys 3). The OLED goes on JB.

## Controls

| Input | Action |
|-------|--------|
| BTNL / BTNR | walk |
| BTNU | jump / menu up |
| BTND | block / menu down |
| BTNC | punch / menu select / continue |
| SW10 | fireball |
| SW11 | dash (not wired yet) |
| SW12 | shield |
| SW13 | ult (needs full meter + code on SW0-9) |
| SW14 | pause |
| SW15 | reset |

## Workflow

- Pull before you start working, and commit and push when you finish.
- Only edit your own modules. If you need a change in someone else's file, tell them.
- Don't commit the `.runs` / `.cache` folders. The `.gitignore` already handles this.
