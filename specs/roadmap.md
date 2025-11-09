# Cassette Refactoring & Modernization Roadmap

This roadmap provides a comprehensive checklist for refactoring the Cassette codebase according to:
- **`specs/instr-ref.md`** — GTK4/Vala refactoring guidelines
- **`instructions/instr-architect.md`** — Residuality-based development workflow
- **`instructions/istr-implement.md`** — Incremental development workflow

---

## Implementation Workflow (NON-NEGOTIABLE)

### Core Principles
1. **DO NOT LEAVE TODOs, PLACEHOLDERS, "For now", "In real impl"** — PREFER TO IMPLEMENT
2. **DO NOT EVER SIMPLIFY UNLESS USER ASKED** — ALWAYS PROMPT IF YOU WANT TO SIMPLIFY SOMETHING
3. **DO NOT EVER LEAVE CODE UNBUILDABLE**
4. **NEVER LEAVE SYSTEM with `make test` and `make build` failed**

### Incremental Development Loop

For **every single change**, follow this strict loop:

#### 1. Plan
- State the tiniest behavior slice to add or change in one sentence
- Keep scope under 15 modified lines total
- One new widget property OR one method per loop

#### 2. Build-RED
- Make exactly one change that causes a build error or missing behavior
- Show code diff, expected error/behavior, and rationale

#### 3. Code-GREEN
- Change minimal production code to satisfy that requirement only
- Show code diff and rationale for each line
- If GREEN needs more than 5 edited lines, split into smaller steps first

#### 4. Reflect
- Self-critique: error/behavior matched intention? Smaller step possible? Any accidental behavior? Complexity delta?

#### 5. Refactor (Optional)
- Tiny refactor with safety proof (rebuild and verify behavior-preserving)

#### 6. Verify
- Run `make build` — must succeed with zero warnings
- Run `make test` — must pass
- Run `make lint` — must pass (if configured)
- Print summary: build status, errors/warnings, runtime verification

#### 7. Commit
- Propose conventional commit message:
  - `type: feat|fix|refactor`
  - `scope: <module>`
  - `subject: imperative, 72 chars max`
  - `body: 'why', not 'what'`

#### 8. Repeat
- Stop only if: stated goal capability is satisfied OR next step is ambiguous
- If ambiguous, list 2-3 candidate next micro-steps and ask to choose

### Quality Gates Per Loop
- ✅ Build succeeds (`make build`) with zero warnings
- ✅ Tests pass (`make test`)
- ✅ No lint errors (`make lint`)
- ✅ Fast feedback: 2-5 minutes per loop
- ✅ Behavior-preserving: UI behavior unchanged (unless fixing bugs)
- ✅ Contract thinking: name preconditions, postconditions, invariants touched

### Heuristics for "Small Enough"
- One new widget property OR one method per loop
- If you touched two files outside the widget file, it is probably too big
- If you had to name a new concept, first make it concrete with a single widget/method, then extract
- Keep steps under 15 modified lines total across code+refactor

### Project-Specific Patterns
- Replace `Cassette.application.root` → `Cassette.Application.tape_client`
- Replace `Cassette.settings` → `Cassette.Application.app_settings`
- Replace `yam_helper` access → `Application.tape_client.yam_helper`
- Replace `storager` access → `Application.tape_client.cachier.storager`
- Replace `player` access → Check if available in `Application.tape_client`
- Add Vala source files to `src/meson.build`
- Add Blueprint templates to `data/meson.build`
- Add UI files to `data/space.rirusha.Cassette.gresource.xml.in`

### Self-Reflection Rubric
- Did the change cause the intended error/behavior before GREEN?
- Did GREEN add exactly one behavior and nothing else?
- Did refactor reduce duplication or clarify intent without new branches?
- Is there a simpler change that would still achieve the same goal?

---

## Phase 1: Code Analysis & Baseline Establishment

### 1.1 Static Analysis Baseline
- [ ] Run `valac --fatal-warnings --target-glib=2.76 --pkg gtk4` on all sources, document warnings
- [ ] Run `vala-lint` with zero-tolerance config, generate baseline report
- [ ] Run `cppcheck` on generated C code, document issues
- [ ] Run `clang-tidy` with `bugprone-*`, `modernize-*`, `readability-*` checks
- [ ] Generate initial code coverage report (gcov/lcov)
- [ ] Document current LOC, complexity metrics, and test coverage percentage
- [ ] Run `G_DEBUG=gc-friendly valgrind` to identify memory leaks
- [ ] Check for thread-safety issues using TSAN/helgrind

### 1.2 Architecture Documentation
- [ ] Create `specs/SPEC.md` — purpose, inputs/outputs, constraints, complexity, non-goals
- [ ] Create `specs/DESIGN.md` — current architecture, dependency graph, failure modes
- [ ] Document all singletons and their usage patterns
- [ ] Map all signal connections and identify manual `connect()` calls
- [ ] Document all async operations and error handling patterns
- [ ] Create dependency graph visualization (tools, services, widgets, models)

### 1.3 Stressor Identification
- [ ] List 10+ potential stressors (requirement shifts, dependency rot, scaling, edge cases)
- [ ] Document assumptions about GTK4/GLib versions, system dependencies
- [ ] Identify external API dependencies and their failure modes
- [ ] Document thread-safety assumptions and potential race conditions

---

## Phase 2: Idiomatic Vala & GObject Modernization

### 2.1 Ownership Semantics
- [ ] Audit all `unowned` annotations — ensure correct usage (UI template children only)
- [ ] Replace incorrect `unowned` with `owned` where ownership transfer occurs
- [ ] Add `weak` references where circular references exist
- [ ] Document ownership decisions in code comments

### 2.2 Signal Connections
- [ ] Replace manual `.connect()` calls with `[GtkCallback]` attributes where applicable
- [ ] Use `on_*` naming pattern for callback methods
- [ ] Ensure all UI template callbacks use `[GtkCallback]`
- [ ] Document signal connections that must remain manual

**Files to review (apply incremental loop per file):**
- [ ] `src/widgets/player-bar.vala` (lines 75-95 have manual connects)
  - [ ] Loop: Replace ONE signal connection with `[GtkCallback]`
  - [ ] Verify: `make build`, `make test`, `make lint` pass
  - [ ] Repeat for each connection
- [ ] `src/widgets/track-carousel.vala` (check signal connections)
  - [ ] Apply incremental loop per connection
- [ ] `src/widgets/abstract-reactable.vala` (construct block signal connections)
  - [ ] Apply incremental loop per connection
- [ ] `src/window.vala` (lines 81, 93-98 have manual connects)
  - [ ] Apply incremental loop per connection
- [ ] All widget files in `src/widgets/`
  - [ ] Audit each file, apply incremental loop per change

### 2.3 Object Initialization
- [ ] Replace manual property setting with `construct` properties where possible
- [ ] Use object initialization lists `Object (prop: value)`
- [ ] Ensure all widgets use `[GtkTemplate]` for UI hierarchy
- [ ] Verify all `.ui` and `.blp` files are properly referenced

### 2.4 Disposal & Cleanup
- [ ] Add `dispose()` override where resources are held (files, streams, timers)
- [ ] Add `finalize()` override only if native resources need cleanup
- [ ] Ensure all signal connections are disconnected in `dispose()`
- [ ] Verify no double-free or use-after-free in cleanup paths

**Files to audit:**
- [ ] `src/widgets/save-stack.vala` (has dispose, verify completeness)
- [ ] `src/widgets/shrinkable/bin.vala` (has dispose, verify completeness)
- [ ] All widgets with timeouts, async operations, or signal connections

### 2.5 Async/Await Patterns
- [ ] Audit all async operations — ensure proper `async`/`yield` usage
- [ ] Replace blocking I/O with async equivalents
- [ ] Ensure error propagation in async chains
- [ ] Document async operations that cannot be made async (if any)

**Files to review:**
- [ ] `src/widgets/views/main.vala` (async operations present)
- [ ] `src/widgets/views/playlist.vala` (async operations present)
- [ ] All view classes and data loading code

---

## Phase 3: Modern C-Level Best Practices

### 3.1 Compiler Warning Flags
- [ ] Add `-Wall -Wextra -Wpedantic -Werror` to Meson build configuration
  - [ ] Plan: Add one warning flag at a time
  - [ ] Build-RED: Add flag, observe warnings
  - [ ] Code-GREEN: Fix warnings incrementally (one warning per loop)
  - [ ] Verify: `make build` succeeds, `make test` passes
- [ ] Fix all implicit casts in generated C
  - [ ] Apply incremental loop: fix one cast per iteration
- [ ] Fix all uninitialized variable warnings
  - [ ] Apply incremental loop: fix one variable per iteration
- [ ] Eliminate undefined behavior (UB) patterns
  - [ ] Apply incremental loop: fix one UB pattern per iteration
- [ ] Ensure `-Werror` does not break builds
  - [ ] Final verification: `make build` succeeds with `-Werror`

### 3.2 Const-Correctness
- [ ] Add `const` to all non-modifying parameters in function signatures
- [ ] Use `const` pointers in C code blocks
- [ ] Ensure generated C has proper const-correctness

### 3.3 Memory Management
- [ ] Eliminate redundant `g_strdup()` calls
- [ ] Ensure every `malloc()`/`g_new()` has matching free path
- [ ] Optimize memory access patterns (avoid heap churn in hot loops)
- [ ] Use `g_malloc0()` where zero-initialization is needed
- [ ] Replace manual `free()` with `g_free()` where appropriate

### 3.4 C Code Blocks (`[CCode]` and inline C)
- [ ] Review all `[CCode (cname="...")]` annotations
- [ ] Audit `src/widgets/vibe-canvas-helper.c` for modern C patterns
- [ ] Replace macros with static inline helpers where possible
- [ ] Use designated initializers (`Foo bar = { .field = value }`)
- [ ] Replace `#define` constants with `static const`
- [ ] Use `bool` from `<stdbool.h>` instead of `gboolean` where not bound by GLib
- [ ] Remove magic numbers, use named constants
- [ ] Ensure explicit casts, no hidden side effects
- [ ] Document C-level assumptions and safety guarantees

**Files to modernize:**
- [ ] `src/widgets/test-shader.vala` (CCode blocks)
- [ ] `src/widgets/vibe-canvas.vala` (CCode blocks)
- [ ] `src/widgets/vibe-canvas-helper.c` (manual C code)

### 3.5 Thread Safety
- [ ] Document thread-safety assumptions explicitly
- [ ] Add mutex/atomic operations where shared state is accessed
- [ ] Ensure GTK operations occur on main thread only
- [ ] Document async operations that touch UI state

---

## Phase 4: Architectural Modernization

### 4.1 Code Organization
- [ ] Ensure one class per file (verify all files comply)
- [ ] Ensure namespace matches directory structure
- [ ] Organize by domain: Models, Views, Controllers, Services, Utils
- [ ] Remove dead code and unused signals
- [ ] Remove redundant callbacks

### 4.2 Dependency Injection
- [ ] Replace static singletons with application services
- [ ] Refactor `Application.app_settings`, `Application.client_settings`, `Application.tape_client` to dependency injection
- [ ] Remove `[SingleInstance]` attributes, replace with service registration
- [ ] Ensure UI components depend on interfaces, not concrete types

**Files to refactor (apply incremental loop per file):**
- [ ] `src/application.vala` (static singletons at lines 50-81)
  - [ ] Loop: Extract ONE static singleton to service registration
  - [ ] Update ONE consumer file to use new service
  - [ ] Verify: `make build`, `make test` pass
  - [ ] Repeat for each singleton
- [ ] `subprojects/libtape/lib/client.vala` ([SingleInstance] at line 22)
  - [ ] Apply incremental loop: replace `[SingleInstance]` with service registration
- [ ] `subprojects/libtape/lib/cachier/cachier.vala` ([SingleInstance] at line 22)
  - [ ] Apply incremental loop: replace `[SingleInstance]` with service registration
- [ ] All files accessing `Application.tape_client`, `Application.app_settings`
  - [ ] Apply incremental loop: update one file at a time, verify build/test after each

### 4.3 GObject Properties
- [ ] Ensure all properties are GObject-compliant and introspectable
- [ ] Add `@since` tags to public APIs
- [ ] Add GNOME-style docblocks (`/** ... */`) to public APIs
- [ ] Verify properties work with Builder/UI templates

### 4.4 Service Registration
- [ ] Register services via `GLib.Application` instead of singletons
- [ ] Ensure services are accessible via application instance
- [ ] Document service lifecycle and ownership

---

## Phase 5: Style & Readability

### 5.1 Code Style
- [ ] Verify 4-space indentation throughout (no tabs)
- [ ] Ensure UTF-8 encoding, Unix newlines
- [ ] Use compact brace style (`if (cond) {`)
- [ ] Consistent naming: Classes `PascalCase`, methods `snake_case`, constants `UPPER_CASE`
- [ ] Align function parameters and signal handlers neatly

### 5.2 Documentation
- [ ] Add GNOME-style docblocks (`/** ... */`) to all public APIs
- [ ] Add inline comments explaining *why*, not *what*
- [ ] Document ownership semantics in complex code
- [ ] Document async operation chains and error handling

### 5.3 Code Quality
- [ ] Remove all TODO/FIXME comments (address or create issues)
- [ ] Ensure consistent error message formatting
- [ ] Verify all public APIs have docblocks

---

## Phase 6: Test Infrastructure & Coverage

### 6.1 Test Infrastructure Setup
- [ ] Set up GLib.Test framework for unit tests
  - [ ] Loop: Create minimal test infrastructure (one test file, one test case)
  - [ ] Verify: `make build`, `make test` pass
- [ ] Create test directory structure (`tests/unit/`, `tests/integration/`, `tests/e2e/`)
  - [ ] Apply incremental loop: create one directory, add one test file
- [ ] Configure Meson build for test execution
  - [ ] Apply incremental loop: add one test executable to meson.build
- [ ] Set up coverage collection (gcov/lcov)
  - [ ] Apply incremental loop: configure coverage for one module
- [ ] Configure CI pipeline for test execution
  - [ ] Apply incremental loop: add one CI gate

### 6.2 Unit Tests
- [ ] Write unit tests for all non-UI business logic
  - [ ] Apply incremental loop: write ONE test per iteration
  - [ ] Verify: `make build`, `make test` pass after each test
- [ ] Achieve ≥95% line coverage for core logic
  - [ ] Measure coverage incrementally, add tests to cover gaps
- [ ] Achieve ≥85% branch coverage for core logic
  - [ ] Add tests incrementally to cover branches
- [ ] Test all error paths and edge cases
  - [ ] Apply incremental loop: add one error path test per iteration
- [ ] Use GLib.Test fixtures where appropriate
  - [ ] Apply incremental loop: extract one fixture per iteration

### 6.3 Integration Tests
- [ ] Write integration tests for service interactions
- [ ] Test async operation chains
- [ ] Test error propagation and recovery
- [ ] Test cache and storage operations

### 6.4 Property-Based & Fuzz Tests
- [ ] Write ≥3 property-based tests with custom shrinkers
- [ ] Set up fuzzing for parsers and data handlers
- [ ] Run fuzzing ≥60 seconds per target with fixed seeds
- [ ] Document invariants and test strategies

### 6.5 E2E Tests (GUI)
- [ ] Set up Dogtail (AT-SPI automation) for GUI tests
- [ ] Ensure all interactive widgets have `accessible-name`
- [ ] Write E2E tests for critical user journeys
- [ ] Configure headless CI execution (Xvfb/Wayland nested compositor)
- [ ] Set up installed tests via `gnome-desktop-testing-runner`

### 6.6 Mutation Testing
- [ ] Set up mutation testing framework
- [ ] Achieve ≥70% mutation score
- [ ] Fix weak tests identified by mutation testing

### 6.7 Performance & Stress Tests
- [ ] Write performance regression tests
- [ ] Ensure no regression >5% in hot paths
- [ ] Run race detector (TSAN/helgrind), achieve zero races
- [ ] Test fault injection scenarios (network failures, timeouts)

---

## Phase 7: Quality Gates & Validation

### 7.1 Build Quality
- [ ] Ensure `valac --fatal-warnings` compiles cleanly
- [ ] Ensure `gcc/clang` with `-Wall -Wextra -Werror` compiles cleanly
- [ ] Ensure `vala-lint` passes with zero issues
- [ ] Ensure `cppcheck` passes with zero critical issues
- [ ] Ensure `clang-tidy` passes with zero issues

### 7.2 Static Analysis
- [ ] Fix all `cppcheck` warnings
- [ ] Fix all `clang-tidy` warnings
- [ ] Address all `vala-lint` issues
- [ ] Document justified waivers for any remaining warnings

### 7.3 Memory Safety
- [ ] Run `G_DEBUG=gc-friendly valgrind`, fix all leaks
- [ ] Run AddressSanitizer (ASan), fix all issues
- [ ] Run UndefinedBehaviorSanitizer (UBSan), fix all issues
- [ ] Verify deterministic cleanup on app shutdown

### 7.4 Thread Safety
- [ ] Run ThreadSanitizer (TSAN), fix all races
- [ ] Verify explicit thread-safety assumptions are documented
- [ ] Test concurrent access scenarios

### 7.5 Test Coverage Gates
- [ ] Achieve ≥95% line coverage
- [ ] Achieve ≥85% branch coverage
- [ ] Achieve ≥70% mutation score
- [ ] Document coverage gaps and justify if needed

---

## Phase 8: Documentation & Evolution

### 8.1 Core Documentation
- [ ] Create/update `specs/SPEC.md` — problem, invariants, constraints, non-goals
- [ ] Create/update `specs/DESIGN.md` — architecture, decisions, failure modes, residues
- [ ] Create `specs/REPRO.md` — exact steps to rebuild and retest anywhere
- [ ] Update `README.md` — usage, configuration, troubleshooting
- [ ] Create `docs/ARCHITECTURE.md` — system architecture overview

### 8.2 API Documentation
- [ ] Generate API documentation (valadoc/gtk-doc)
- [ ] Ensure all public APIs are documented
- [ ] Document ownership semantics and thread-safety guarantees
- [ ] Document async operation chains and error handling

### 8.3 Development Documentation
- [ ] Create `CONTRIBUTING.md` — development workflow, coding standards
- [ ] Document build system (Meson) configuration
- [ ] Document test execution and coverage collection
- [ ] Document CI/CD pipeline

### 8.4 ADRs (Architecture Decision Records)
- [ ] Document singleton → service refactoring decision
- [ ] Document async/await patterns decision
- [ ] Document error handling strategy
- [ ] Document thread-safety assumptions

---

## Phase 9: CI/CD & Reproducibility

### 9.1 CI Pipeline
- [ ] Configure CI pipeline (GitLab CI / GitHub Actions)
- [ ] Add lint/typecheck gate (0 warnings)
- [ ] Add test execution gate
- [ ] Add coverage collection and reporting
- [ ] Add static analysis gates (cppcheck, clang-tidy)
- [ ] Add memory safety gates (valgrind, sanitizers)
- [ ] Add performance regression detection

### 9.2 Reproducible Builds
- [ ] Ensure builds are reproducible (deterministic)
- [ ] Create `specs/REPRO.md` with exact rebuild steps
- [ ] Test build on clean environment
- [ ] Document all dependencies and versions

### 9.3 Hermetic Builds (Optional)
- [ ] Create `Dockerfile` for hermetic builds
- [ ] Create `flake.nix` for Nix-based builds
- [ ] Document build environment requirements

---

## Phase 10: Validation Against Stressors

### 10.1 Stress Testing
- [ ] Test requirement changes (modify APIs, verify graceful degradation)
- [ ] Test dependency failures (simulate network failures, API errors)
- [ ] Test invalid inputs (malformed data, null pointers, edge cases)
- [ ] Test timeouts and partial failures (async operations)
- [ ] Test rollback scenarios (configuration changes, state recovery)

### 10.2 Failure Mode Testing
- [ ] Test network failure scenarios
- [ ] Test API rate limiting and errors
- [ ] Test disk space exhaustion
- [ ] Test memory pressure scenarios
- [ ] Test UI state corruption recovery

### 10.3 End-to-End Validation
- [ ] Verify all tests pass after refactoring
- [ ] Verify UI behavior unchanged
- [ ] Verify performance not degraded
- [ ] Verify memory usage acceptable
- [ ] Verify thread-safety maintained

---

## Phase 11: Final Quality Assurance

### 11.1 Self-Red Team Loop (×2)
- [ ] List 10 failure modes (correctness, perf, security, concurrency)
- [ ] Create 3 tests that reproduce them
- [ ] Fix code and document in `specs/DESIGN.md`
- [ ] Remove any untestable code
- [ ] Repeat cycle once more

### 11.2 Integration Validation
- [ ] Run full test suite (unit, integration, E2E)
- [ ] Verify all quality gates pass
- [ ] Verify documentation is complete
- [ ] Verify CI pipeline passes

### 11.3 Final Review
- [ ] Code review by skeptical engineer
- [ ] Verify `git clone`, one command, all gates pass
- [ ] Document any justified waivers
- [ ] Ensure system withstands stressors without collapsing
- [ ] Ensure future changes can be made confidently and reversibly

---

## Priority Order

1. **Critical Path** (must complete first):
   - Phase 1: Analysis & Baseline
   - Phase 2: Idiomatic Vala (ownership, signals, async)
   - Phase 3: C-Level Best Practices (warnings, memory safety)
   - Phase 6: Test Infrastructure (foundation for validation)

2. **High Priority** (enables quality gates):
   - Phase 4: Architectural Modernization
   - Phase 7: Quality Gates
   - Phase 9: CI/CD

3. **Medium Priority** (improves maintainability):
   - Phase 5: Style & Readability
   - Phase 8: Documentation
   - Phase 10: Stressor Validation

4. **Final Validation**:
   - Phase 11: Final QA

---

## Success Criteria

The refactoring is complete when:

- ✅ `valac --fatal-warnings` compiles cleanly
- ✅ `gcc/clang -Wall -Wextra -Werror` compiles cleanly
- ✅ `vala-lint` passes with zero issues
- ✅ Static analyzers pass (cppcheck, clang-tidy)
- ✅ Test coverage ≥95% line, ≥85% branch
- ✅ Mutation score ≥70%
- ✅ Zero memory leaks (valgrind)
- ✅ Zero thread-safety issues (TSAN)
- ✅ All tests pass
- ✅ Documentation complete (SPEC.md, DESIGN.md, REPRO.md)
- ✅ CI pipeline passes all gates
- ✅ System withstands stressors without collapsing

---

## Notes

- This roadmap is **iterative** — phases may overlap and inform each other
- Some items may be **justified waivers** — document them in DESIGN.md
- **Test-driven refactoring** — write tests before refactoring where possible
- **Incremental changes** — small, reviewable PRs preferred over large rewrites
- **Preserve semantics** — refactoring must not change behavior (unless fixing bugs)
- **Strict adherence to incremental loop** — every change must follow Plan → Build-RED → Code-GREEN → Reflect → Refactor → Verify → Commit
- **Never leave code unbuildable** — every loop must end with `make build` and `make test` passing
- **No TODOs or placeholders** — implement fully or skip the item
- **Micro-steps only** — if a change touches >15 lines or >2 files, split into smaller steps

---

**Last Updated:** 2025-01-XX  
**Status:** In Progress  
**Next Review:** After Phase 1 completion

---

## Quick Reference: Incremental Loop Template

When working on any roadmap item, use this template:

```markdown
## Plan
[One sentence describing the tiniest behavior slice]

## Build-RED
```diff
[code diff showing the change that causes build error]
```
Expected error/behavior: "[specific error message or missing behavior]"
Rationale: [why this change is the next incremental step]

## Code-GREEN
```diff
[code diff showing minimal fix]
```
Rationale: [why each line is necessary now]

## Reflect
* error/behavior matched intention: [yes/no]
* smaller step possible: [yes/no]
* accidental behavior: [list or none]
* complexity delta: [+, 0, or -]

## Refactor
```diff
[optional refactor diff]
```
Safety proof: [why behavior-preserving or 'skipped']

## Verify
* Build: [success/failure, warnings count]
* Test: [pass/fail, test count]
* Lint: [pass/fail, issues count]
* Runtime: [behavior verified]

## Commit
[conventional commit message]

## Next
[next micro-step or stop criteria]
```

