"""End-to-end tests for swf-branch using local bare repositories (no network)."""
import importlib.machinery
import importlib.util
import sys
import subprocess
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent.parent
loader = importlib.machinery.SourceFileLoader("swf_branch", str(HERE / "swf-branch"))
spec = importlib.util.spec_from_loader("swf_branch", loader)
sb = importlib.util.module_from_spec(spec)
sys.modules["swf_branch"] = sb
loader.exec_module(sb)

CONFIG = """
default_repos = ["depmgt", "lib"]
depmgt_repos = ["depmgt"]
[orgs]
exo = "acme"
[repos]
exo = ["depmgt", "lib"]
[properties]
prefixes = ["io.meeds.", "addon.exo."]
depmgt_marker = "depmgt"
exclude = ["addon.exo.skipme.version"]
"""
LIB_POM = """<project>
<parent><artifactId>maven-parent-pom</artifactId><groupId>io.meeds</groupId><version>22-SNAPSHOT</version></parent>
<version>7.3.x-SNAPSHOT</version>
<properties><addon.exo.lib.version>7.3.x-SNAPSHOT</addon.exo.lib.version>
<io.meeds.depmgt.version>26.x-SNAPSHOT</io.meeds.depmgt.version>
<other.version>7.3.x-SNAPSHOT</other.version>
<addon.exo.brandnew.version>7.3.x-SNAPSHOT</addon.exo.brandnew.version>
<addon.exo.skipme.version>7.3.x-SNAPSHOT</addon.exo.skipme.version>
<io.meeds.pinned.version>6.0.0</io.meeds.pinned.version></properties>
<dependencies><dependency><artifactId>not-a-parent</artifactId><version>22-SNAPSHOT</version></dependency></dependencies></project>"""
MOD_POM = """<project><parent><groupId>io.meeds.addons</groupId><artifactId>addons-parent-pom</artifactId>
<version>22-SNAPSHOT</version></parent></project>"""
DEPMGT_POM = "<project><version>26.x-SNAPSHOT</version></project>"


def run(*cmd, cwd=None):
    return subprocess.run(cmd, cwd=cwd, check=True, text=True, capture_output=True).stdout


class SwfBranchTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.TemporaryDirectory().name)
        self.addCleanup(lambda: subprocess.run(["rm", "-rf", str(self.tmp)]))
        self.remotes, self.work = self.tmp / "remotes" / "acme", self.tmp / "work"
        self.remotes.mkdir(parents=True)
        (self.tmp / "repos.toml").write_text(CONFIG)
        for name, pom in (("depmgt", DEPMGT_POM), ("lib", LIB_POM)):
            seed = self.tmp / "seed" / name
            seed.mkdir(parents=True)
            run("git", "init", "-q", "-b", "develop", cwd=seed)
            (seed / "pom.xml").write_text(pom)
            if name == "lib":
                (seed / "mod").mkdir()
                (seed / "mod" / "pom.xml").write_text(MOD_POM)
            run("git", "-c", "user.name=t", "-c", "user.email=t@t", "add", ".", cwd=seed)
            run("git", "-c", "user.name=t", "-c", "user.email=t@t", "commit", "-qm", "init", cwd=seed)
            run("git", "clone", "-q", "--bare", str(seed), str(self.remotes / f"{name}.git"))

    def sb(self, *args):
        base = ["--config", str(self.tmp / "repos.toml"), "--workdir", str(self.work), "--non-interactive",
                "--url-template", str(self.tmp / "remotes" / "{org}" / "{repo}.git")]
        return sb.main([args[0], *base, *args[1:]])

    def remote_pom(self, repo, branch):
        return run("git", "show", f"{branch}:pom.xml", cwd=self.remotes / f"{repo}.git")

    def remote_has(self, repo, branch):
        return branch in run("git", "branch", cwd=self.remotes / f"{repo}.git")

    CREATE = ("create", "myfb", "7.3.x", "26.x", "TASK-1")

    def test_dry_run_pushes_nothing_but_rewrites_locally(self):
        self.assertEqual(self.sb(*self.CREATE), 0)
        self.assertFalse(self.remote_has("lib", "feature/myfb"))
        pom = (self.work / "lib" / "pom.xml").read_text()
        self.assertEqual(run("git", "branch", "--show-current", cwd=self.work / "lib").strip(), "develop")
        self.assertIn("7.3.x-SNAPSHOT", pom)  # develop checkout untouched
        self.assertIn("7.3.x-myfb-SNAPSHOT",
                      run("git", "show", "feature/myfb:pom.xml", cwd=self.work / "lib"))

    def test_push_rewrites_versions_correctly(self):
        self.assertEqual(self.sb(*self.CREATE, "--push"), 0)
        lib = self.remote_pom("lib", "feature/myfb")
        self.assertIn("<version>7.3.x-myfb-SNAPSHOT</version>", lib)
        self.assertIn("<addon.exo.lib.version>7.3.x-myfb-SNAPSHOT<", lib)
        self.assertIn("<io.meeds.depmgt.version>26.x-myfb-SNAPSHOT<", lib)
        self.assertIn("<other.version>7.3.x-SNAPSHOT<", lib)  # prefix not covered
        self.assertIn("<addon.exo.brandnew.version>7.3.x-myfb-SNAPSHOT<", lib)  # new add-on, no config edit
        self.assertIn("<addon.exo.skipme.version>7.3.x-SNAPSHOT<", lib)  # excluded
        self.assertIn("<io.meeds.pinned.version>6.0.0<", lib)  # value differs from old version: untouched
        self.assertIn("<version>26.x-myfb-SNAPSHOT</version>", self.remote_pom("depmgt", "feature/myfb"))
        log = run("git", "log", "-1", "--format=%s", "feature/myfb", cwd=self.work / "lib").strip()
        self.assertEqual(log, "TASK-1: Create FB myfb and update projects versions/dependencies")

    def test_existing_default_is_keep_not_destructive(self):
        self.sb(*self.CREATE, "--push")
        lib = self.work / "lib"
        run("git", "checkout", "-q", "feature/myfb", cwd=lib)
        (lib / "mine.txt").write_text("x")
        run("git", "add", ".", cwd=lib)
        run("git", "-c", "user.name=t", "-c", "user.email=t@t", "commit", "-qm", "mine", cwd=lib)
        run("git", "push", "-q", "origin", "feature/myfb", cwd=lib)
        self.assertEqual(self.sb(*self.CREATE, "--push"), 0)  # default existing=ask -> keep when non-interactive
        self.assertIn("mine.txt", run("git", "ls-tree", "--name-only", "feature/myfb", cwd=self.remotes / "lib.git"))

    def test_recreate_drops_custom_commits(self):
        self.sb(*self.CREATE, "--push")
        lib = self.work / "lib"
        run("git", "checkout", "-q", "feature/myfb", cwd=lib)
        (lib / "mine.txt").write_text("x")
        run("git", "add", ".", cwd=lib)
        run("git", "-c", "user.name=t", "-c", "user.email=t@t", "commit", "-qm", "mine", cwd=lib)
        run("git", "push", "-q", "origin", "feature/myfb", cwd=lib)
        self.assertEqual(self.sb(*self.CREATE, "--push", "--existing", "recreate"), 0)
        self.assertEqual(len(run("git", "branch", "--list", "backup/feature/myfb-*", cwd=lib).split()), 1)
        self.assertNotIn("mine.txt", run("git", "ls-tree", "--name-only", "feature/myfb", cwd=self.remotes / "lib.git"))

    def test_preserve_moves_7_3_to_8_0_bump_on_base_then_dev_commits(self):
        self.sb(*self.CREATE, "--push")
        lib = self.work / "lib"
        run("git", "checkout", "-q", "feature/myfb", cwd=lib)
        (lib / "mine.txt").write_text("x")
        run("git", "add", ".", cwd=lib)
        run("git", "commit", "-qm", "dev work", cwd=lib)
        old_dev = run("git", "rev-parse", "HEAD", cwd=lib).strip()
        run("git", "push", "-q", "origin", "feature/myfb", cwd=lib)
        # develop moves 7.3.x -> 8.0.x on the remote
        run("git", "checkout", "-q", "develop", cwd=lib)
        pom = (lib / "pom.xml").read_text().replace("7.3.x", "8.0.x")
        (lib / "pom.xml").write_text(pom)
        run("git", "commit", "-qam", "move develop to 8.0.x", cwd=lib)
        run("git", "push", "-q", "origin", "develop", cwd=lib)
        self.assertEqual(self.sb("create", "myfb", "8.0.x", "26.x", "TASK-1", "--push", "--existing", "preserve"), 0)
        r = self.remotes / "lib.git"
        # oldest first, after develop: bump commit, then the dev commit
        subjects = run("git", "log", "--reverse", "--format=%s", "develop..feature/myfb", cwd=r).splitlines()
        self.assertEqual(subjects, ["TASK-1: Create FB myfb and update projects versions/dependencies", "dev work"])
        self.assertEqual(run("git", "rev-parse", "feature/myfb~2", cwd=r).strip(),
                         run("git", "rev-parse", "develop", cwd=r).strip())  # bump sits right on develop
        final = self.remote_pom("lib", "feature/myfb")
        self.assertIn("<version>8.0.x-myfb-SNAPSHOT</version>", final)
        self.assertNotIn("7.3.x", final)
        self.assertIn("mine.txt", run("git", "ls-tree", "--name-only", "feature/myfb", cwd=r))
        new_dev = run("git", "rev-parse", "feature/myfb", cwd=r).strip()
        self.assertNotEqual(new_dev, old_dev)  # hash changed, content kept
        backups = run("git", "branch", "--list", "backup/feature/myfb-*", cwd=lib).split()
        self.assertEqual(len(backups), 1)  # old tip kept locally, never pushed
        self.assertEqual(run("git", "rev-parse", backups[0], cwd=lib).strip(), old_dev)
        self.assertNotIn("backup/", run("git", "branch", "-a", cwd=r))

    def test_preserve_conflict_leaves_branch_untouched(self):
        self.sb(*self.CREATE, "--push")
        lib = self.work / "lib"
        run("git", "checkout", "-q", "feature/myfb", cwd=lib)
        (lib / "f.txt").write_text("dev")
        run("git", "add", ".", cwd=lib)
        run("git", "commit", "-qm", "dev f", cwd=lib)
        run("git", "push", "-q", "origin", "feature/myfb", cwd=lib)
        tip = run("git", "rev-parse", "HEAD", cwd=lib).strip()
        run("git", "checkout", "-q", "develop", cwd=lib)
        (lib / "f.txt").write_text("conflicting")
        run("git", "add", ".", cwd=lib)
        run("git", "commit", "-qm", "develop f", cwd=lib)
        run("git", "push", "-q", "origin", "develop", cwd=lib)
        self.assertEqual(self.sb(*self.CREATE, "--push", "--existing", "preserve"), 1)
        self.assertEqual(run("git", "branch", "--list", "backup/*", cwd=lib).strip(), "")  # untouched: no backup left
        self.assertEqual(run("git", "rev-parse", "feature/myfb", cwd=self.remotes / "lib.git").strip(), tip)

    def test_keep_with_stale_local_branch_pulls_remote_first(self):
        self.sb(*self.CREATE, "--push")  # operator clone now has local feature/myfb
        other = self.tmp / "dev"
        run("git", "clone", "-q", str(self.remotes / "lib.git"), str(other))
        run("git", "checkout", "-q", "feature/myfb", cwd=other)
        (other / "dev.txt").write_text("d")
        run("git", "add", ".", cwd=other)
        run("git", "commit", "-qm", "dev pushed meanwhile", cwd=other)
        run("git", "push", "-q", "origin", "feature/myfb", cwd=other)
        self.assertEqual(self.sb(*self.CREATE, "--push", "--existing", "keep"), 0)  # would be rejected if stale
        self.assertIn("dev.txt", run("git", "ls-tree", "--name-only", "feature/myfb", cwd=self.remotes / "lib.git"))

    def test_preserve_warns_on_non_base_merge_and_linearizes(self):
        self.sb(*self.CREATE, "--push")
        lib = self.work / "lib"
        run("git", "checkout", "-q", "feature/myfb", cwd=lib)
        run("git", "checkout", "-q", "-b", "side", cwd=lib)
        (lib / "side.txt").write_text("s")
        run("git", "add", ".", cwd=lib)
        run("git", "commit", "-qm", "side work", cwd=lib)
        run("git", "checkout", "-q", "feature/myfb", cwd=lib)
        run("git", "merge", "-q", "--no-ff", "-m", "merge side", "side", cwd=lib)
        run("git", "push", "-q", "origin", "feature/myfb", cwd=lib)
        import contextlib, io
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            self.assertEqual(self.sb(*self.CREATE, "--push", "--existing", "preserve"), 0)
        self.assertIn("merges something other than develop", buf.getvalue())
        r = self.remotes / "lib.git"
        self.assertIn("side.txt", run("git", "ls-tree", "--name-only", "feature/myfb", cwd=r))
        self.assertEqual(run("git", "rev-list", "--merges", "develop..feature/myfb", cwd=r).strip(), "")

    def mod_and_root(self, branch="feature/myfb"):
        g = self.remotes / "lib.git"
        return run("git", "show", f"{branch}:pom.xml", cwd=g), run("git", "show", f"{branch}:mod/pom.xml", cwd=g)

    def test_parent_unchanged_by_default(self):
        self.sb(*self.CREATE, "--push")
        root, mod = self.mod_and_root()
        self.assertIn("<version>22-SNAPSHOT</version></parent>", root)
        self.assertIn("22-SNAPSHOT", mod)

    def test_parent_all_artifacts_and_only_inside_parent_blocks(self):
        self.assertEqual(self.sb(*self.CREATE, "--push", "--parent", "22-SNAPSHOT=22-maintenance-SNAPSHOT"), 0)
        root, mod = self.mod_and_root()
        self.assertIn("<version>22-maintenance-SNAPSHOT</version></parent>", root)
        self.assertIn("22-maintenance-SNAPSHOT", mod)
        self.assertIn("<artifactId>not-a-parent</artifactId><version>22-SNAPSHOT</version>", root)  # dependency untouched

    def test_parent_restricted_to_one_artifact(self):
        self.sb(*self.CREATE, "--push", "--parent", "maven-parent-pom:22-SNAPSHOT=22-maintenance-SNAPSHOT")
        root, mod = self.mod_and_root()
        self.assertIn("22-maintenance-SNAPSHOT", root)
        self.assertNotIn("maintenance", mod)

    def test_parent_value_must_match_old_version(self):
        self.sb(*self.CREATE, "--push", "--parent", "23-SNAPSHOT=23-maintenance-SNAPSHOT")
        root, _ = self.mod_and_root()
        self.assertNotIn("maintenance", root)

    def test_parent_invalid_spec_rejected(self):
        for bad in ("22-SNAPSHOT", "a=b=c", "x=x"):
            with self.assertRaises(SystemExit, msg=bad):
                self.sb(*self.CREATE, "--parent", bad)

    def test_preserve_includes_parent_change_in_the_bump_commit(self):
        self.sb(*self.CREATE, "--push")
        self.assertEqual(self.sb(*self.CREATE, "--push", "--existing", "preserve",
                                 "--parent", "22-SNAPSHOT=22-maintenance-SNAPSHOT"), 0)
        root, mod = self.mod_and_root()
        self.assertIn("22-maintenance-SNAPSHOT", root + mod)
        g = self.remotes / "lib.git"
        self.assertEqual(run("git", "rev-list", "--count", "develop..feature/myfb", cwd=g).strip(), "1")

    def test_base_branch_precedence(self):
        r = sb.resolve_base
        self.assertEqual(r(None, {}, {}), "develop")
        self.assertEqual(r(None, {}, {"base_branch": "main"}), "main")
        self.assertEqual(r(None, {"SWF_BASE_BRANCH": "trunk"}, {"base_branch": "main"}), "trunk")
        self.assertEqual(r("cli", {"SWF_BASE_BRANCH": "trunk"}, {"base_branch": "main"}), "cli")
        for bad in ("-x", "/abs", "a b", "a;b"):
            with self.assertRaises(SystemExit, msg=bad):
                r(bad, {}, {})

    def test_custom_base_branch_from_config_end_to_end(self):
        for name in ("depmgt", "lib"):  # the remotes' integration branch is called 'trunk'
            run("git", "branch", "-m", "develop", "trunk", cwd=self.remotes / f"{name}.git")
        (self.tmp / "repos.toml").write_text('base_branch = "trunk"\n' + CONFIG)
        self.assertEqual(self.sb(*self.CREATE, "--push"), 0)  # no --base given
        r = self.remotes / "lib.git"
        self.assertEqual(run("git", "rev-list", "--count", "trunk..feature/myfb", cwd=r).strip(), "1")
        self.assertEqual(run("git", "branch", "--show-current", cwd=self.work / "lib").strip(), "trunk")
        self.assertEqual(self.sb("remove", "feature/myfb", "--push", "--yes"), 0)
        with self.assertRaises(SystemExit):  # the configured base is protected too
            self.sb("remove", "trunk", "--push", "--yes")

    def test_parse_selection(self):
        cfg = {"repos": {"g": ["b", "c"]}}
        o = ["a", "b", "c", "d"]
        self.assertEqual(sb.parse_selection("all", cfg, o), o)
        self.assertEqual(sb.parse_selection("g d", cfg, o), ["b", "c", "d"])
        self.assertEqual(sb.parse_selection("1,3-4", cfg, o), ["a", "c", "d"])
        with self.assertRaises(SystemExit):
            sb.parse_selection("9", cfg, o)

    def test_skip_existing(self):
        self.sb(*self.CREATE, "--push")
        self.assertEqual(self.sb(*self.CREATE, "--push", "--existing", "skip"), 0)

    def test_missing_args_non_interactive_fails_instead_of_hanging(self):
        with self.assertRaises(SystemExit) as cm:
            self.sb("create", "myfb")
        self.assertIn("missing argument", str(cm.exception))

    def test_remove_local_then_remote(self):
        self.sb(*self.CREATE, "--push")
        self.assertEqual(self.sb("remove", "feature/myfb"), 0)
        self.assertTrue(self.remote_has("lib", "feature/myfb"))  # no --push: remote kept
        self.assertFalse(sb.has_local(self.work / "lib", "feature/myfb"))
        with self.assertRaises(SystemExit):  # remote delete needs --yes non-interactively
            self.sb("remove", "feature/myfb", "--push")
        self.assertEqual(self.sb("remove", "feature/myfb", "--push", "--yes"), 0)
        self.assertFalse(self.remote_has("lib", "feature/myfb"))

    def test_remove_refuses_protected_branches(self):
        for b in ("develop", "develop-exo", "master", "stable/1.x", "release/2.0"):
            with self.assertRaises(SystemExit, msg=b):
                self.sb("remove", b, "--push", "--yes")

    def test_dirty_clone_is_refused_not_wiped(self):
        self.sb(*self.CREATE)
        (self.work / "lib" / "pom.xml").write_text("dirty")
        self.assertEqual(self.sb(*self.CREATE, "--existing", "skip"), 1)
        self.assertEqual((self.work / "lib" / "pom.xml").read_text(), "dirty")


if __name__ == "__main__":
    unittest.main()
