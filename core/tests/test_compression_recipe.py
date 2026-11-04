"""Keep unavailable RAR extras from preventing Debian OEM finalization."""
import os
from pathlib import Path
import subprocess
import unittest

CORE = Path(__file__).resolve().parents[1]


class CompressionRecipeTests(unittest.TestCase):
    def test_core_failures_remain_fatal_and_optional_codecs_do_not_block(self):
        name = 'recipe:_ADM:_Compression_Tools () {'
        function = name + (CORE / '_rtd_recipies.info').read_text().split(
            name, 1
        )[1].split('\n}', 1)[0] + '\n}\n'
        script = """
hash() { [[ "$1" == apt ]]; }
write_information() { :; }
write_warning() { echo "warning:$*"; }
write_error() { echo "$*" >&2; }
software::from_flathub.org() { return "$FLATPAK_RESULT"; }
software::check_native_package_dependency() { echo "required:$*"; return "$CORE_RESULT"; }
software::add_native_package() { echo "optional:$*"; return 0; }
dependency::command_exists() { return "$COMMAND_RESULT"; }
""" + function + '\nrecipe:_ADM:_Compression_Tools'
        for core, flatpak, command in ((0, 0, 0), (1, 0, 0), (0, 1, 0), (0, 0, 1)):
            with self.subTest(core=core, flatpak=flatpak, command=command):
                result = subprocess.run(
                    ['bash', '-c', script], capture_output=True, text=True, timeout=5,
                    env={**os.environ, 'CORE_RESULT': str(core), 'FLATPAK_RESULT': str(flatpak),
                         'COMMAND_RESULT': str(command)},
                )
                self.assertEqual(result.returncode == 0, not (core or flatpak or command),
                                 result.stderr)
                self.assertIn('required:7zip\n', result.stdout)
                self.assertNotIn('required:7zip zip', result.stdout)
                self.assertIn('optional:zip rar 7zip-rar', result.stdout)

    def test_fedora_accepts_existing_7z_without_obsolete_package_names(self):
        name = 'recipe:_ADM:_Compression_Tools () {'
        function = name + (CORE / '_rtd_recipies.info').read_text().split(
            name, 1
        )[1].split('\n}', 1)[0] + '\n}\n'
        script = """
hash() { [[ "$1" == dnf ]]; }
write_information() { :; }
software::from_flathub.org() { return 0; }
software::add_native_package() { return 0; }
software::check_native_package_dependency() { echo "obsolete dependency:$*"; return 19; }
dependency::command_exists() { [[ "$*" == "--silent 7z" ]]; }
""" + function + '\nrecipe:_ADM:_Compression_Tools'
        result = subprocess.run(['bash', '-c', script], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertNotIn('obsolete dependency:', result.stdout)


if __name__ == '__main__':
    unittest.main()
