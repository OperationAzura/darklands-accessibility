"""Check dependency detection without installing system packages."""

from pathlib import Path
import subprocess
import unittest


class TestDependencyDetection(unittest.TestCase):
    def check_packages(self, missing):
        script = (Path(__file__).resolve().parents[1] / "scripts/install.sh").read_text()
        function = script.split("missing_debian_dependencies()", 1)[1].split(
            "\nif ((install_system_deps))", 1)[0]
        mock = '''dpkg-query() {
    if [[ "$3" == "$MISSING_PACKAGE" ]]; then
        return 1
    fi
    printf 'install ok installed'
}
'''
        result = subprocess.run(
            ["bash", "-eu", "-c", mock + "missing_debian_dependencies()" + function + '''
mapfile -t missing < <(missing_debian_dependencies)
printf '%s\\n' "${#missing[@]}"
if ((${#missing[@]})); then printf '%s\\n' "${missing[@]}"; fi
'''], env={"PATH": "/usr/bin:/bin", "MISSING_PACKAGE": missing},
            text=True, capture_output=True, check=True,
        )
        return result.stdout.splitlines()

    def test_no_missing_packages(self):
        self.assertEqual(self.check_packages(""), ["0"])

    def test_one_missing_package(self):
        self.assertEqual(self.check_packages("meson"), ["1", "meson"])
