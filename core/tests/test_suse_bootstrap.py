"""AutoYaST must install RTD even when its second stage is disabled."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
import xml.etree.ElementTree as ET

from test_oem_themes import library_function


class SuseBootstrapTests(unittest.TestCase):
    def test_bootstrap_runs_in_installed_system_before_installer_reboot(self):
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / 'autoyast.xml'
            result = subprocess.run(
                ['bash', '-c', library_function('template::AutoYast_xml') +
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
            self.assertIn('git clone --depth=1 https://example.invalid/RTD.git /opt/rtd', code)
            self.assertIn('bash /opt/rtd/core/rtd-oem-enable-config.sh', code)
            self.assertIn('test -f /opt/rtd/core/rtd-oem-enable-config.sh', code)
            self.assertNotIn('\nreboot\n', code)
            self.assertNotIn('zypper in', code)
            self.assertEqual(subprocess.run(['bash', '-n'], input=code, text=True).returncode, 0)
            packages = [item.text for item in doc.findall('y:software/y:packages/y:package', ns)]
            self.assertIn('openssh-server', packages)
            self.assertIn('yad', packages)
            self.assertIn('sudo', packages)
            self.assertIn('gzip', packages)
            self.assertIn('yast2-firstboot', packages)

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
