"""Run from a Vivado command prompt or a shell with Icarus Verilog installed."""
from pathlib import Path
import shutil
import subprocess
import sys
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / 'keyboard_test_build'
BUILD.mkdir(exist_ok=True)
fileset = ET.parse(ROOT / 'Basys_Brawl.xpr').find(".//FileSet[@Name='sources_1']")
sources = []
for entry in fileset.findall('File'):
    name = entry.get('Path').replace('$PSRCDIR', str(ROOT / 'Basys_Brawl.srcs'))
    path = Path(name)
    if path.suffix == '.v' and not path.name.startswith('Part') and path.name != 'fighter_demo_core.v':
        if not path.is_file():
            raise SystemExit(f'Missing project source: {path}')
        sources.append(str(path))
tests = ['keyboard_controls_tb', 'keyboard_system_tb', 'fighter_actions_tb', 'sprite_bounds_tb', 'collision_tb', 'cpu_actions_tb']
benches = [str(ROOT / 'tests' / (test + '.sv')) for test in tests]

def run(args):
    result = subprocess.run(args, cwd=BUILD, capture_output=True, text=True)
    print(result.stdout)
    if result.stderr:
        print(result.stderr, file=sys.stderr)
    if result.returncode:
        raise SystemExit(result.returncode)
    return result.stdout

if shutil.which('iverilog') and shutil.which('vvp'):
    for test in tests:
        executable = str(BUILD / test)
        run(['iverilog', '-g2012', '-s', test, '-o', executable, *sources, *benches])
        output = run(['vvp', executable])
        if f'PASS: {test}' not in output:
            raise SystemExit(f'{test}: no PASS marker')
elif all(shutil.which(tool) for tool in ['xvlog', 'xelab', 'xsim']):
    run(['xvlog', '--sv', *sources, *benches])
    for test in tests:
        snapshot = test + '_snapshot'
        run(['xelab', '-s', snapshot, test])
        output = run(['xsim', snapshot, '-runall'])
        if f'PASS: {test}' not in output:
            raise SystemExit(f'{test}: no PASS marker')
else:
    raise SystemExit('No simulator found. Run in the Vivado command prompt (xvlog/xelab/xsim), or install Icarus Verilog.')
print('PASS: all game tests')
