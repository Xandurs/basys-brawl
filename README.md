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

Connect a keyboard directly to the Basys 3 USB-A (J2) socket. The programming
USB cable does not carry laptop keyboard events into this receiver.

| Input | Action |
|-------|--------|
| A / D | hold to walk left / right |
| W | jump / menu up |
| S | menu down |
| J | hold to block |
| I | punch (temporary default) |
| K | fireball |
| L | shield |
| N / M | dash backwards / forwards relative to facing |
| Enter | menu select / continue to P2 / return to menu |
| U | ultimate (temporary default; full meter + code still required) |
| 0–9 (top row) | toggle virtual ultimate-code switches 0–9 |
| Backspace | clear virtual code switches |
| SW14 | pause |
| SW15 | reset |

Letters work without Shift or Caps Lock. Actions fire once per press; release
before pressing again. A/D/J remain held until their release is received.
The physical push buttons and SW0–SW13 no longer control the main game.
The original standalone Part*_Test_Top modules still use their original controls.

Ultimate codes and LED hints retain their existing rules. For code 103, tap
Backspace, then 1, 0, 3 in order, then U once the meter is full. Number keys
stay toggled after release, matching switches. Codes clear at each new turn;
Backspace also clears them before entering a new code after using an ultimate.

The keyboard source and PS/2 constraints are already included in Basys_Brawl.xpr.
Gameplay remains at the existing 30 Hz; the OLED clock is unchanged.

See [KEYBOARD_TESTING.md](KEYBOARD_TESTING.md) for testing before committing.

## Characters and combined actions

After CPU personality selection, choose **Dr Chua**, **Prof Massimo** or
**Karthi** separately for P1, P2 and the CPU. Use W/S and Enter. The menu
shows names only; the selected 12 × 16 pixel sprites appear in the fight.

Both fighters can walk while punching/blocking, and punch or block in the air.
Hitstun, KO and punch recovery retain priority. All characters use identical
body boxes, punch reach and damage. See [CHARACTER_UPDATE.md](CHARACTER_UPDATE.md)
for exact rules and validation limits, and [the sprite preview](docs/character_preview.png).

## Workflow

- Pull before you start working, and commit and push when you finish.
- Only edit your own modules. If you need a change in someone else's file, tell them.
- Don't commit the `.runs` / `.cache` folders. The `.gitignore` already handles this.
