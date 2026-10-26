#!/usr/bin/env python3
"""Opt-in network/build smoke test. Installs only into disposable temporary homes."""
import argparse
import json
import os
from pathlib import Path
import sys
import tempfile
import time

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from studio import Studio, catalog

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--family', action='append', help='Family ID; repeat to select several, omit for all')
parser.add_argument('--profile', default='default')
parser.add_argument('--output', type=Path, help='Optional JSON results file')
args = parser.parse_args()
entries = [e for e in catalog() if not args.family or e['id'] in args.family]
if args.family and set(args.family) - {e['id'] for e in entries}:
    parser.error('Unknown family ID')
# Sequential by design: large icon trees can exhaust tmpfs inodes when built concurrently.
for key in ('XDG_DATA_HOME', 'XDG_CONFIG_HOME', 'XDG_STATE_HOME'):
    os.environ.pop(key, None)
results = []
for entry in entries:
    start = time.monotonic()
    with tempfile.TemporaryDirectory(prefix='rtd-studio-catalog-') as home:
        studio = Studio(home)
        try:
            message = studio.install(entry['id'], args.profile)
            record = studio.registry()[entry['id']]
            result = dict(id=entry['id'], ok=True, count=len(record['paths']), message=message,
                          variants=[Path(p).name for p in record['paths']])
            for path in record['paths']:
                for child in Path(path).rglob('*'):
                    if child.is_symlink():
                        assert child.exists(), f'Installed dangling link: {child}'
                        assert child.resolve().is_relative_to(Path(home)), f'Installed external link: {child}'
        except Exception as error:
            result = dict(id=entry['id'], ok=False, error=str(error))
        result['seconds'] = round(time.monotonic() - start, 1)
        print(json.dumps(result), flush=True)
        results.append(result)
if args.output:
    args.output.write_text(json.dumps(results, indent=2) + '\n')
sys.exit(0 if all(result['ok'] for result in results) else 1)
