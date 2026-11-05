"""AutoYaST must install RTD even when its second stage is disabled."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
import xml.etree.ElementTree as ET

from test_oem_themes import library_function


class SuseBootstrapTests(unittest.TestCase):
    def test_installer_stages_bootstrap_for_installed_system_networking(self):
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / 'autoyast.xml'
            result = subprocess.run(
                ['bash', '-c', library_function('template::suse_bootstrap_stage') +
                 library_function('template::AutoYast_xml') +
                 '\ntemplate::AutoYast_xml "$_autoyast_filename"'],
                capture_output=True, text=True,
                env={**os.environ, '_autoyast_filename': str(target),
                     '_UserProductSelection': 'Tumbleweed',
                     'GIT_RTD_SRC_URL': 'https://example.invalid/RTD.git'},
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            doc = ET.parse(target)
            ns = {'y': 'http://www.suse.com/1.0/yast2ns'}
            self.assertEqual(doc.findtext('y:general/y:mode/y:second_stage', namespaces=ns), 'false')
            self.assertIsNone(doc.find('y:scripts/y:init-scripts', ns))
            script = doc.find('y:scripts/y:chroot-scripts/y:script', ns)
            self.assertIsNotNone(script)
            self.assertEqual(script.findtext('y:chrooted', namespaces=ns), 'true')
            code = script.findtext('y:source', namespaces=ns)
            self.assertIn('RTD_BOOTSTRAP_GIT_URL=https://example.invalid/RTD.git', code)
            self.assertIn('After=network-online.target nss-lookup.target', code)
            self.assertIn('Requires=rtd-firstboot-bootstrap.service', code)
            self.assertNotIn('\nreboot\n', code)
            self.assertNotIn('zypper in', code)
            self.assertEqual(subprocess.run(['bash', '-n'], input=code, text=True).returncode, 0)
            packages = [item.text for item in doc.findall('y:software/y:packages/y:package', ns)]
            self.assertIn('openssh-server', packages)
            self.assertNotIn('yad', packages)
            self.assertIn('sudo', packages)
            self.assertIn('gzip', packages)
            self.assertIn('yast2-firstboot', packages)

    def test_offline_staging_then_clone_failure_retry_and_registration(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for path in ('etc/systemd/system', 'bin'):
                (root / path).mkdir(parents=True)
            env = {**os.environ, 'PATH': f'{root}/bin:{os.environ["PATH"]}',
                   'GIT_RTD_SRC_URL': 'https://example.invalid/RTD.git',
                   'MOCK_ROOT': directory, 'CLONE_FAIL': '1'}
            # No installer command may access the network. Record any clone;
            # the mock registration has its own failure mode after cloning.
            mocks = {
                'systemctl': '#!/bin/bash\nprintf "%s\\n" "$*" >>"$MOCK_ROOT/systemctl.log"\n',
                'firewall-offline-cmd': '#!/bin/bash\nexit 0\n',
                'sleep': '#!/bin/bash\nexit 0\n',
                'git': '''#!/bin/bash
echo clone >>"$MOCK_ROOT/git.log"
[[ "$CLONE_FAIL" == 0 ]] || exit 1
target="${@: -1}"
mkdir -p "$target/core"
cat >"$target/core/rtd-oem-enable-config.sh" <<'REGISTER'
[[ "$REGISTER_FAIL" == 0 ]] || exit 1
touch "$MOCK_ROOT/var/lib/rtd/template-autofinalize"
REGISTER
''',
            }
            for name, contents in mocks.items():
                command = root / 'bin' / name
                command.write_text(contents)
                command.chmod(0o755)
            code = subprocess.check_output(
                ['bash', '-c', library_function('template::suse_bootstrap_stage') +
                 '\ntemplate::suse_bootstrap_stage'], env=env, text=True)
            for path in ('/usr/local/sbin', '/etc/', '/var/log/rtd', '/var/lib/rtd', '/opt/rtd'):
                code = code.replace(path, directory + path)
            staged = subprocess.run(['bash'], input=code, text=True, env=env)
            self.assertEqual(staged.returncode, 0)
            self.assertFalse((root / 'git.log').exists(), 'staging must work without network')
            bootstrap = root / 'usr/local/sbin/rtd-firstboot-bootstrap'
            complete = root / 'var/lib/rtd/bootstrap-complete'
            failed = subprocess.run(['bash', str(bootstrap)], env=env)
            self.assertNotEqual(failed.returncode, 0)
            self.assertFalse(complete.exists())
            self.assertEqual((root / 'git.log').read_text().count('clone'), 5)
            self.assertFalse(list((root / 'opt').glob('.rtd-bootstrap.*')))
            env.update(CLONE_FAIL='0', REGISTER_FAIL='1')
            self.assertNotEqual(subprocess.run(['bash', str(bootstrap)], env=env).returncode, 0)
            self.assertFalse(complete.exists(), 'clone alone must not count as success')
            env['REGISTER_FAIL'] = '0'
            self.assertEqual(subprocess.run(['bash', str(bootstrap)], env=env).returncode, 0)
            self.assertTrue(complete.exists())
            self.assertEqual((root / 'git.log').read_text().count('clone'), 6,
                             'registration retry must reuse the successful clone')

    def test_reseal_arms_native_unit_and_rejects_missing_prerequisites(self):
        for packages, unit in ((0, 'YaST2-Firstboot.service'), (1, 'YaST2-Firstboot.service'), (0, 'missing')):
            with self.subTest(packages=packages, unit=unit), tempfile.TemporaryDirectory() as directory:
                marker = Path(directory) / 'YaST2/reconfig_system'
                function = library_function('system::rtd_oem_reseal::_prepare_suse').replace(
                    '/var/lib/YaST2', str(marker.parent)
                )
                result = subprocess.run(['bash', '-c', """
write_status() { :; }
write_error() { echo "$*" >&2; }
software::check_native_package_dependency() { return "$PACKAGE_RESULT"; }
systemctl() {
    if [[ "$1" == cat ]]; then [[ "$2" == "$UNIT" ]];
    else echo "$*"; fi
}
""" + function + '\nsystem::rtd_oem_reseal::_prepare_suse physical'],
                                        capture_output=True, text=True,
                                        env={**os.environ, 'PACKAGE_RESULT': str(packages),
                                             'UNIT': unit, '_LOGFILE': str(Path(directory) / 'log')})
                success = packages == 0 and unit != 'missing'
                self.assertEqual(result.returncode == 0, success, result.stderr)
                self.assertEqual(marker.exists(), success)
                if success:
                    self.assertIn('enable YaST2-Firstboot.service', (Path(directory) / 'log').read_text())


if __name__ == '__main__':
    unittest.main()
