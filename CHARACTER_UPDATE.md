# Character selection and combined actions

Open `Basys_Brawl.xpr` from a short path such as `C:\EE2026\Brawl`. The existing
keyboard source and school-format constraints are already included. The stale
`special_top.dcp` checkpoint reference is removed and incremental synthesis is
disabled. No source files need to be added manually.

## New menu flow

Title → difficulty → CPU personality → P1 character → P2 character → CPU
character → countdown → match.

On each character screen, **W/S** changes the highlighted name and **Enter**
confirms. Each screen displays names only: **DR CHUA**, **PROF MASSIMO**, **KARTHI**.
P1 and P2 keep their own selections during their respective turns; the CPU keeps
its selected character for both turns. Duplicate selections are allowed.

Characters have identical gameplay statistics:

| ID | Character | Pixel design |
|---|---|---|
| 0 | Dr Chua | Female, long hair, teal tunic, gold trim |
| 1 | Prof Massimo | Male, light hair and beard, burgundy robe, gold trim |
| 2 | Karthi | Male, dark hair, gold headband, orange adventurer tunic |

The artwork uses the provided fantasy reference as a loose design cue and a
retro platform-game pixel style. It is authored directly as 12 × 16 palette ROM
rows in `fighter_draw.v`; there are no external image/ROM files to locate at
build time. `docs/character_preview.png` shows the exact idle sprite data enlarged.
The small team-colour band remains blue for P1, purple for P2 and red for the CPU.

## Combined actions

- Hold A/D to move during a jump, punch or block.
- Press I while airborne to punch; the normal startup/active/recovery timing runs
  while jump physics continues.
- Hold J while airborne to block. You can also jump while holding block.
- Press W while punching to jump without cancelling the punch timer.
- A held I or W still triggers only once per press; release before triggering again.
- Punch recovery finishes before blocking or another punch begins. If block and
  punch are requested together from neutral, block takes priority as before.
- Accepted hits, hitstun, KO, pause, cooldowns and screen bounds retain priority.

The same `fighter` module is used for both human and CPU fighters. The CPU
controller now preserves held motion when it requests punch, block or jump.
The AI has a small jump branch using its existing random generator; difficulty
reaction times and the existing aggressive/defensive/zoner branches are retained.

## Collision geometry

All characters share the original geometry and damage. The combat module and
projectile collision logic are unchanged.

| Region | Bounds (right/bottom exclusive) |
|---|---|
| Body | `[x, x + 12)` × `[feet_y - 16, feet_y)` |
| Right punch | `[x + 12, min(x + 20, 96))` × `[feet_y - 12, feet_y - 5)` |
| Left punch | `[max(x - 8, 0), x)` × `[feet_y - 12, feet_y - 5)` |

Sprites mirror inside that same 12-pixel body width. Their transparent corner
pixels are still part of the rectangular body hitbox; collision is rectangular,
not pixel-perfect. Clothing, hair, guard poses and the walk step stay inside the
body rectangle. The visible active fist fills the existing punch rectangle.
Airborne punches and blocks use the fighter's current height, so an attack only
connects if its vertical and horizontal rectangles overlap.

## Test before committing

1. Close Vivado, copy the archive contents into a separate local test copy or your
   local repository, then open its `Basys_Brawl.xpr`.
2. Reset synthesis and regenerate/program the bitstream. Keep OLED on JB.
3. Make different selections for P1, P2 and CPU. Verify that each appears during
   its correct turn. Test the menu wrapping in both directions.
4. Test A/D+I, A/D+J, W then I, W then J, and J held while pressing W.
5. Test both facing directions, both screen edges, hitstun, KO and SW14 pause.
6. Play against the CPU and check its jumping and moving attacks/blocks.
7. Review the changes and commit only after testing; no commit or push was made.

From a Vivado command prompt at the repository root, run the included regressions:

```text
vivado -mode batch -source tests/run_vivado_tests.tcl
```

Or, with Python and Icarus Verilog (or Vivado's standalone simulator commands)
on PATH:

```text
python tests/run_tests.py
```

Six testbenches cover serial keyboard decoding, the integrated menu/selection
flow, paired player/CPU fighter actions, exhaustive sprite clipping, real combat
rectangle boundaries/chip damage, and CPU movement/jump commands. They are not
an exhaustive verification of every gameplay interaction.

During preparation, source registration, module port names, structural syntax,
sprite ROM data and unchanged collision equations were checked. The sprite
preview was visually inspected. **Vivado and an HDL simulator were unavailable,
so these testbenches have not been executed here. Synthesis, timing closure and
board behavior still require local validation.**
