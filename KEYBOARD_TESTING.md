# Keyboard integration — test before committing

This archive contains the edited repository with the original folder layout.
Copy its contents over your **local clone**, keeping your existing `.git` folder.
Review `git diff` or GitHub Desktop's Changes tab, test locally, then commit.
No commit or push was made while preparing this archive. Uploading files through
the GitHub website creates a commit, so use your local clone to test first.

## Build and board test

1. Use a short path such as `C:\EE2026\basys-brawl` because the existing imported
   source paths are long. Close Vivado before replacing the files.
2. Open **Basys_Brawl.xpr**. `Top_Basys_Brawl` remains the synthesis top; the new
   keyboard source is already registered. No manual wiring or Add Sources is needed.
3. Reset the existing synthesis/implementation runs if this is an existing clone,
   generate the bitstream, then program the board. Keep the OLED on **JB**.
4. Connect a keyboard directly to USB-A J2. Set SW14 and SW15 off; toggle SW15
   on then off to reset. Use Enter to open the menu, W/S to change options, and
   Enter to select them. After personality, confirm the P1, P2 and CPU character selections with W/S and Enter; the last selection starts the countdown.
5. Verify A/D walking, W jumping, J held blocking, I punching, K fireball and
   L shield. Hold an action key: it should activate once until released/repressed.
6. M dashes toward the facing direction; N dashes away. They share the original
   dash cooldown (240 game ticks, about eight seconds). Test with both facing
   directions and near both screen edges.
7. SW14 pauses/resumes. Action presses during pause are discarded. SW15 resets.
8. Number keys toggle the original code-switch bits; Backspace clears them.
   Follow LED0–9 hints in order. The starting code is 103. U still requires both
   the code and the original full meter; it does not grant meter or unlock cheats.
9. At the between-player screen and final result screen, Enter continues.
   I only punches. P1/P2 scoring, damage and match timing are unchanged. The
   CPU now supports walking combinations and can choose to jump.

If a keyboard is disconnected while a key is held, reset with SW15 after
reconnecting if that key remains stuck. No laptop software is needed.

## Automated tests

From a **Vivado command prompt**, at the repository root:

```text
vivado -mode batch -source tests/run_vivado_tests.tcl
```

Alternatively, if Python and either Icarus Verilog or Vivado's standalone
`xvlog`/`xelab`/`xsim` commands are on PATH:

```text
python tests/run_tests.py
```

Both routes require `PASS: all game tests`. Generated simulation files go
under ignored `keyboard_test_build/`; do not commit them.

`keyboard_controls_tb.sv` checks serial scan-code decoding, make/break, multiple
held keys, repeat suppression, parity rejection, partial-frame recovery, extended
Enter, reconnect startup, number toggles, Backspace and round reset behavior.

`keyboard_system_tb.sv` drives the actual integrated top through the serial
keyboard pins. It checks menu and P1/P2/CPU character selection, countdown, movement, block, jump, punch,
fireball, shield, both dashes, unlock-code/U routing, SW14 pause and Enter for P2.
It accelerates game ticks, holds the CPU AI busy, and forces meter full only for
the U-binding test. Those controls exist only in the testbench and never enter
the synthesised design. Additional fighter, sprite, collision and CPU-command
regressions are described in CHARACTER_UPDATE.md. This is not an OLED timing
or exhaustive full-combat regression.

## Scope and validation

Added a PS/2 receiver for the board's existing USB keyboard bridge; registered
it in the XPR; enabled the school's existing C17/B17 constraints; replaced main
top input bindings; connected dash positions into the fighter; added backward
dash selection; and fixed special-action presses that coincide with a game tick.
Pending special presses clear when play stops, preventing queued pause inputs.
The original dash distance, movement algorithm and cooldown remain intact.

The receiver remembers held keys across match resets, while virtual code bits
clear per turn. Only full-system reset clears all held-key state.

Source paths, instance ports, top-level pin coverage, structural token balances,
and Python test-runner syntax were checked during preparation. **No HDL simulator
or Vivado was available in that environment, so the testbenches, synthesis,
implementation, timing closure and board behavior still need to be run locally.**

The uploaded GitHub snapshot is the basis for these edits. No live GitHub branch
was accessed or modified.
