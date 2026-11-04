# Basys Brawl

EE2026 (NUS) design project: a 2D fighting game on the Basys 3 FPGA with a PMOD OLED (96x64).

P1 fights the CPU, then P2 fights the CPU. Whoever KOs the CPU fastest wins.
If only one player gets a KO, that player wins. If neither does, the player who
left the CPU with less health wins.

## Team

| Member  | Parts |
|---------|-------|
| Oliver  | `fighter`, `fighter_draw`, `game_tick`, `button_input` |
| Karthi  | `special_top`, `special_fireball`, `special_def`, `special_dash`, `special_ult`, `ult_manager` |
| Yuhan   | `c_cpu`, `ai_decision`, `cpu_control`, `lfsr`, `control_menu`, `menu_render`, `font_render` |
| Xander  | `Top_Basys_Brawl`, `game_flow`, `combat`, `hud`, `font5x7`, `digit_pixel`, `flow_seg`, `num_to_seg` |

## Building

1. Open the `.xpr` in Vivado. Extract the folder to a short path first; don't open it from inside a zip.
2. Set `Top_Basys_Brawl` as top.
3. Run Generate Bitstream, then Hardware Manager → Program Device.

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
