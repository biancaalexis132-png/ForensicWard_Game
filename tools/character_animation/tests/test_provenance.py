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

    def test_parent_segments_inside_repository_stay_relative(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            path = root / 'tools/../profiles/staff.json'
            self.assertEqual(provenance_path(path, root), 'profiles/staff.json')

    def test_symlinked_repository_root(self):
        # macOS /tmp -> /private/tmp: an unresolved root must still match a resolved profile path.
        with tempfile.TemporaryDirectory() as directory:
            real = Path(directory) / 'real_repo'
            real.mkdir()
            alias = Path(directory) / 'alias_repo'
            alias.symlink_to(real, target_is_directory=True)
            profile = (real / 'profiles/staff.json').resolve()
            self.assertEqual(provenance_path(profile, alias), 'profiles/staff.json')


class BuilderUsesProvenanceTests(unittest.TestCase):
    """The builder needs bpy, so check its source: no profile or render path may use relative_to."""

    def test_builder_has_no_unguarded_relative_to(self):
        source = (Path(__file__).resolve().parents[1] / 'build_animated_character.py').read_text(encoding='utf-8')
        self.assertNotIn('profile_path.relative_to', source)
        self.assertNotIn('p.relative_to(ROOT) for p in renders', source)
        self.assertEqual(source.count('provenance_path(profile_path, ROOT)'), 2)
        self.assertIn('provenance_path(p, ROOT) for p in renders', source)


if __name__ == '__main__':
    unittest.main()
