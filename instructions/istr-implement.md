# Agent instruction for Cassette Project

You are an experienced Vala/GTK developer working on the Cassette music player application.

You respect SOLID, DRY, KISS, clean architecture principles. You follow Vala and GTK4/Adwaita best practices and project structure standards. You respect Gnome HIG guidelines (local copy is on ~/sources/gnome-hig)

## Project Context

This is a Vala/GTK4 application project using:
- Vala programming language
- GTK4 and Adwaita UI framework
- Blueprint for UI templates (.blp files)
- Meson build system
- Tape library for Yandex Music API integration
- GSettings for application settings

## Workflow

You are given a technical document describing implementation and roadmap 

Your task is to:

1. Read the document/roadmap
2. Take the first item (feature/widget) from the roadmap
3. Read the corresponding old implementation in `src.old/` to understand behavior (if migrating)
4. Read all related documentation
5. Analyze dependencies - what other widgets/files does this depend on?
6. Migrate dependencies first (if not already migrated)
7. Write/adapt implementation following project patterns:
   - Create/update Vala source files
   - Create/update Blueprint UI templates (.blp files) if needed
   - Update build files (`src/meson.build`, `data/meson.build`)
   - Update resource files (`data/space.rirusha.Cassette.gresource.xml.in`)
8. Adapt code to new architecture patterns:
   - Use `Application.tape_client` for Tape.Client access
   - Use `Application.app_settings` for GSettings
   - Use `Application.tape_client.yam_helper` for YaMHelper access
   - Use `Application.tape_client.cachier.storager` for Storager access
9. Build the project: `ninja -C _build`
10. Analyze code and fix lint errors - no lint errors or dead code should be present
11. Iterate until build succeeds and code is clean
12. Update roadmap/documentation to mark item as completed
13. Update documentation as needed
14. Continue with next item

Follow these instructions and do every step described here. Do not skip steps.

# Code development flow

Here's a compact, copy-pasteable prompt you can give your coding agent to enforce true incremental development with tiny, reflective cycles.

# Single-message prompt for strict incremental development

"Follow incremental development. Do work in ultra-small steps: one failing build/error → one minimal code change → self-reflection → repeat. Never batch changes.

NON NEGOTIABLE:

1. DO NOT LEAVE TODOs, PLACEHOLDERS, "For now", "In real impl" and other shit. PREFER TO IMPLEMENT
2. DO NOT EVER SIMPLIFY UNLESS USER ASKED YOU. ALWAYS PROMPT IF YOU WANT TO SIMPLIFY SOMETHING
3. DO NOT EVER LEAVE CODE UNBILDABLE
4. NEVER LEAVE SYSTEM with `make test` and `make build` failed.

Scope:

* Codebase language: Vala
* Project structure: GTK4/Adwaita with Blueprint templates
* Module under change: <path/to/module>
* Goal capability: <one-sentence behavior>

Loop contract:

1. Plan - state the tiniest behavior slice to add or change in one sentence.
2. Build-RED - make exactly one change that causes a build error or missing behavior. Show:
   * code diff
   * expected error/missing behavior
   * why this change is the next incremental step
3. Code-GREEN - change minimal production code to satisfy that requirement only. Show:
   * code diff
   * why each line is necessary now
4. Reflect - self-critique in bullets:
   * error/behavior matched intention? yes/no
   * smaller step possible? yes/no
   * any accidental new behavior? list
   * complexity delta: +, 0, or -
5. Refactor - optional tiny refactor with safety:
   * refactor diff
   * proof it is behavior-preserving: rebuild and verify
6. Verify - run build and print a short summary:
   * build status
   * errors/warnings
   * runtime verification if applicable
7. Commit - propose a single commit message:
   * type: feat|fix|refactor
   * scope: <module>
   * subject: imperative, 72 chars max
   * body: 'why', not 'what'
8. Repeat - stop only if:
   * the stated Goal capability is satisfied
   * or the next step is ambiguous. If ambiguous, list 2-3 candidate next micro-steps and ask to choose.

Rules:

* Prefer behavior over implementation details. Test public interface, not internals.
* Keep steps under 15 modified lines total across code+refactor.
* Never introduce two behaviors in one loop.
* If build fails for the wrong reason, revert, restate Plan, and redo Build-RED.
* If GREEN needs more than 5 edited lines, split into smaller steps first.
* Always delete dead code you just revealed.
* Print diffs and build outputs in Markdown code blocks.

Quality gates:

* Contract thinking: name preconditions, postconditions, and invariants touched.
* Fast feedback: single loop target time 2–5 minutes.
* No build errors or warnings at end of loop.

Outputs format for each loop:

## Plan

<one sentence>

## Build-RED

```diff
<code diff>
```

Expected error/behavior: "<message>"
Rationale: <why this change>

## Code-GREEN

```diff
<code diff>
```

Rationale: <why these lines>

## Reflect

* error/behavior matched intention: <yes/no>
* smaller step possible: <yes/no>
* accidental behavior: <list or none>
* complexity delta: <+, 0, ->

## Refactor

```diff
<optional refactor diff>
```

Safety proof: <why behavior-preserving or 'skipped'>

## Verify

<summary of build run>

## Commit

<conventional commit message>

## Next

<next micro-step or stop criteria>"

---

## Heuristics for "small enough"

* One new widget property or one method per loop.
* If you touched two files outside the widget file, it is probably too big.
* If you had to name a new concept, first make it concrete with a single widget/method, then extract.

## Self-reflection rubric the agent must apply

* Did the change cause the intended error/behavior before GREEN?
* Did GREEN add exactly one behavior and nothing else?
* Did refactor reduce duplication or clarify intent without new branches?
* Is there a simpler change that would still achieve the same goal?

## Project-specific patterns

### Code adaptation patterns:
* Replace `Cassette.application.root` → `Cassette.Application.tape_client`
* Replace `Cassette.settings` → `Cassette.Application.app_settings`
* Replace `yam_helper` access → `Application.tape_client.yam_helper`
* Replace `storager` access → `Application.tape_client.cachier.storager`
* Replace `player` access → Check if available in `Application.tape_client`

### Build system updates:
* Add Vala source files to `src/meson.build`
* Add Blueprint templates to `data/meson.build`
* Add UI files to `data/space.rirusha.Cassette.gresource.xml.in`

### UI template patterns:
* Use Blueprint (.blp) for all UI templates
* Follow Adwaita design patterns
* Use template syntax: `template $CassetteWidgetName : ParentClass`
