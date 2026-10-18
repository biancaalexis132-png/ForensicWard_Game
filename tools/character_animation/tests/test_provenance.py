import sys
from pathlib import Path
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from provenance import provenance_path


class ProvenanceTests(unittest.TestCase):
    def test_in_repository_profile(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.assertEqual(provenance_path(root / 'profiles/staff.json', root),
                             'profiles/staff.json')

    def test_external_profile_and_renders(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory) / 'repo'
            for name in ('profile.json', 'renders/face.png'):
                path = Path(directory) / 'external' / name
                self.assertEqual(provenance_path(path, root), str(path.resolve()))

    def test_symlink_outside_repository_records_actual_source(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory) / 'repo'
            root.mkdir()
            external = Path(directory) / 'external.json'
            external.write_text('{}')
            link = root / 'profile.json'
            link.symlink_to(external)
            self.assertEqual(provenance_path(link, root), str(external.resolve()))


if __name__ == '__main__':
    unittest.main()
