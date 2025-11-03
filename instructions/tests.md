Here’s a pragmatic, GNOME-native testing playbook for Vala apps—unit through end-to-end—so your tests survive GTK/GLib quirks and CI reality.

# 1) Principles (architecture that makes tests easy)

* **Separate UI from logic.** Keep business logic in plain `GObject` classes (no widgets), tested with GLib’s test framework; keep thin GTK layers that can be smoke-tested. GLib’s testing API (`g_test_*`) is the standard base. ([https://docs.gtk.org][1])
* **Prefer “installed tests” for system-level checks.** GNOME’s `gnome-desktop-testing` runner executes *as-installed* tests against your packaged app (great for CI and distro integration). Use it in addition to build-time tests. ([gitlab.gnome.org][2])
* **For GUI E2E, use a11y automation.** Dogtail (Python) drives the app via AT-SPI accessibility—robust, toolkit-agnostic, works with GTK. ([about.gitlab.com][3])
* **Mind GTK test APIs.** Old `gtk_test_*` helpers are not the path forward in GTK 4; design around accessibility and events instead. ([https://docs.gtk.org][4])

---

# 2) Unit tests (GLib.Test + Vala)

Use GLib’s testing framework from Vala. Minimal example (no UI):

```vala
using GLib;

public class Calculator : Object {
    public int add(int a, int b) { return a + b; }
}

void add_calculator_tests () {
    Test.add_func("/calc/add", () => {
        var c = new Calculator();
        assert_true(c.add(2, 3) == 5);
    });
}

public static int main (string[] args) {
    Test.init(ref args);
    add_calculator_tests();
    return Test.run();
}
```

For GTK-touching tests, initialize GTK and run the test suite from the main loop exactly once (avoid re-creating `Gtk.Application` multiple times in one process):

```vala
using GLib;
using Gtk;

void add_widget_tests () {
    Test.add_func("/ui/button-instantiation", () => {
        var b = new Button.with_label("hi");
        assert_true(b is Button);
    });
}

int main (string[] args) {
    Gtk.init(ref args);
    Test.init(ref args);

    add_widget_tests();

    Idle.add(() => { Test.run(); Gtk.main_quit(); return false; });
    Gtk.main();
    return 0;
}
```

This pattern mirrors GNOME’s own sample for Vala tests with GTK. ([wiki.gnome.org][5])

**Unit-test tactics (GLib/GIO idioms):**

* **Fixtures:** use GLib fixtures (`g_test_add` in C; in Vala, structure setup/teardown inside your added functions) to isolate temp dirs, state, or D-Bus sessions. ([https://docs.gtk.org][1])
* **Async code:** drive async with a `MainLoop`; in a test, start the async op, quit the loop in the callback, assert results after.
* **Subprocess tests:** for things that must run in a fresh process (e.g., single-instance `Gtk.Application`), use GLib’s *trap subprocess* pattern (in C it’s `g_test_trap_subprocess`; mirror with small helper binaries from Vala). ([https://docs.gtk.org][1])
* **Assertions:** avoid `g_assert()` in unit tests (becomes no-op with `G_DISABLE_ASSERT`); use `g_assert_true`, etc. Vala’s `assert_true` maps to those. ([https://docs.gtk.org][1])

**Build & run:** Integrate with Meson’s `test()` targets; for packaging/CI, also register installed tests and run them with the GNOME runner. ([gitlab.gnome.org][2])

---

# 3) End-to-End (GUI) tests that actually work

**Tooling: Dogtail (Python) over AT-SPI**

* Script flows like “launch app → click menu → type → assert label”.
* Locates widgets by a11y **role/name/description**; so give your key widgets stable, human-readable labels/`accessible-name`s.
* Works across GTK versions and Wayland/X11 via the accessibility stack. ([about.gitlab.com][3])

**Skeleton Dogtail test (Python):**

```python
# python3 -m pip install dogtail
from dogtail.tree import root
from dogtail.rawinput import click, typeText, keyCombo
from dogtail.utils import run
app = run('your-app-id-or-exec')

win = root.application('Your App Name')
win.child('Open').click()
typeText('hello world')
keyCombo('<Alt>F4')
```

**Best practices for GUI E2E:**

* **Define stable a11y semantics:** every interactive widget with a deterministic `accessible-name`. Your tests will be 10× less flaky. ([Fedora Magazine][6])
* **Lifecycle & isolation:** launch a fresh instance per test file; clean config dirs between tests.
* **Timing:** prefer waiting on state (e.g., “label text becomes X”) over sleeps.
* **Headless CI:** use a virtual display/session (e.g., `dbus-run-session` + Xvfb for X11; for Wayland, run inside a nested compositor used by CI images), then call Dogtail. Fedora and GNOME docs show this pattern for a11y automation. ([Fedora Magazine][6])
* **System-level assertions:** complement with **installed tests** to verify the packaged app launches, schemas are present, D-Bus activations work, etc. Run via `gnome-desktop-testing-runner`. ([gitlab.gnome.org][2])

---

# 4) Coverage, quality, and CI knobs

* **Coverage:** collect with `gcov/lcov` or `llvm-cov` on the generated C—works because Vala emits C.
* **Sanitizers:** enable Address/UBSan in your CI build flags; they’ll catch the C-level footguns Vala can’t fully prevent.
* **Deprecations budget:** fail the build on newly introduced GTK deprecations only if you target a specific migration window; the GTK team’s stance is “don’t panic—clean up when porting majors.” Keep this sane to avoid churn. ([GNOME Blogs][7])

---

# 5) When you need more than unit tests but less than full E2E

* **Component tests:** spin a minimal `Gtk.Application`, present a single widget tree, interact via Dogtail against just that widget. Faster than full app E2E, still exercises rendering/events.
* **CLI/daemon parts:** test those as pure GLib/GIO programs with subprocess traps and temporary runtime dirs.

---

# 6) References you can lean on

* GLib’s official testing guide (fixtures, assertions, subprocesses). ([https://docs.gtk.org][1])
* GNOME Vala unit-test samples, including GTK loop integration. ([wiki.gnome.org][5])
* Dogtail: project docs and usage via AT-SPI. ([about.gitlab.com][3])
* GNOME installed tests & runner (`gnome-desktop-testing`). ([gitlab.gnome.org][2])
* GTK deprecations/migration context (why not to lean on old `gtk_test_*`). ([https://docs.gtk.org][4])

---

## A compact blueprint to adopt

1. **Unit tests**: GLib.Test for all non-UI code; one GTK-aware test binary that runs inside `Gtk.main()` once.
2. **Installed tests**: package a smoke test that launches the app and verifies basic environment with `gnome-desktop-testing-runner`.
3. **E2E**: Dogtail scripts for top user journeys, run in a virtual desktop in CI.
4. **Quality gates**: coverage + sanitizers + “no new deprecations” rule.

If you share your build system layout (Meson options, Flatpak manifests, how you launch the app), I can sketch exact `meson.build` snippets for unit/installed tests and a ready-to-copy CI job that spins up a Wayland/Xvfb session and runs Dogtail.

[1]: https://docs.gtk.org/glib/testing.html?utm_source=chatgpt.com "Testing Framework - GLib – 2.0"
[2]: https://gitlab.gnome.org/GNOME/gnome-desktop-testing?utm_source=chatgpt.com "gnome-desktop-testing - GitLab"
[3]: https://gitlab.com/dogtail/dogtail?utm_source=chatgpt.com "Dogtail"
[4]: https://docs.gtk.org/gtk4/?utm_source=chatgpt.com "Gtk – 4.0"
[5]: https://wiki.gnome.org/Projects%282f%29Vala%282f%29TestSample.html?utm_source=chatgpt.com "Projects/Vala/TestSample"
[6]: https://fedoramagazine.org/automation-through-accessibility/?utm_source=chatgpt.com "Automation through Accessibility"
[7]: https://blogs.gnome.org/gtk/2022/10/30/on-deprecations/?utm_source=chatgpt.com "On deprecations – GTK Development Blog"
