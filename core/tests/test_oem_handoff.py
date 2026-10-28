#!/usr/bin/env python3
"""Regression tests for the Ubuntu OEM temporary-account handoff."""

from __future__ import annotations

import os
import subprocess
import tempfile
import unittest
from pathlib import Path


HELPER = Path(__file__).resolve().parents[1] / 'rtd-prepare-oem-temporary-user.sh'


class UbuntuOemHandoffTests(unittest.TestCase):
    def command(self, directory: Path, name: str, body: str) -> None:
        path = directory / name
        path.write_text('#!/bin/bash\nset -eu\n' + body)
        path.chmod(0o755)

    def test_renames_user_group_and_home(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            commands = root / 'bin'
            commands.mkdir()
            state = root / 'oem-temporary-user'
            state.write_text('tangarora\n')
            log = root / 'commands.log'
            group_renamed = root / 'group-renamed'

            self.command(commands, 'getent', f'''
case "$1:$2" in
  passwd:tangarora) printf '%s\n' 'tangarora:x:1000:1000:RTD User:/home/tangarora:/bin/bash' ;;
  passwd:oem) exit 2 ;;
  passwd:29999) exit 2 ;;
  group:tangarora) printf '%s\n' 'tangarora:x:1000:' ;;
  group:oem) [[ -e '{group_renamed}' ]] || exit 2; printf '%s\n' 'oem:x:29999:' ;;
  group:29999) exit 2 ;;
  *) exit 2 ;;
esac
''')
            self.command(commands, 'id', '''
case "$1:$2" in
  -gn:tangarora) printf '%s\n' tangarora ;;
  -u:tangarora) printf '%s\n' 1000 ;;
  -g:tangarora) printf '%s\n' 1000 ;;
  *) exit 2 ;;
esac
''')
            self.command(commands, 'groupmod', f'''
printf 'groupmod:%s\n' "$*" >>'{log}'
touch '{group_renamed}'
''')
            self.command(commands, 'usermod', f'''printf 'usermod:%s\n' "$*" >>'{log}'\n''')
            self.command(commands, 'chown', f'''printf 'chown:%s\n' "$*" >>'{log}'\n''')

            environment = os.environ.copy()
            environment['PATH'] = f'{commands}:/usr/bin:/bin'
            environment['RTD_OEM_USER_STATE_FILE'] = str(state)
            completed = subprocess.run(
                ['bash', str(HELPER)], env=environment, text=True,
                stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)

            self.assertEqual(completed.returncode, 0, completed.stderr)
            self.assertEqual(state.read_text(), 'oem\n')
            calls = log.read_text().splitlines()
            self.assertEqual(calls, [
                'groupmod:--new-name oem tangarora',
                'groupmod:--gid 29999 oem',
                'usermod:--login oem tangarora',
                'usermod:--uid 29999 oem',
                'usermod:--home /home/oem --move-home oem',
                'usermod:--gid oem oem',
                'chown:-R oem:oem /home/oem',
            ])

    def test_refuses_root(self):
        with tempfile.TemporaryDirectory() as temporary:
            state = Path(temporary) / 'oem-temporary-user'
            state.write_text('root\n')
            environment = os.environ.copy()
            environment['RTD_OEM_USER_STATE_FILE'] = str(state)
            completed = subprocess.run(
                ['bash', str(HELPER)], env=environment, text=True,
                stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
            self.assertNotEqual(completed.returncode, 0)
            self.assertIn('Refusing to rename root', completed.stderr)


if __name__ == '__main__':
    unittest.main()
