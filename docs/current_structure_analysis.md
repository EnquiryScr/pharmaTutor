# pharmaTutor Project Structure vs Flutter Standards: Diagnostic and Alignment Blueprint

## Executive Summary

The pharmaTutor mobile application is implemented as a Flutter app under the app/ directory with an MVVM (Model–View–ViewModel) and repository-oriented architecture. The top-level project is a multi-folder workspace that also includes a backend/, deployment/, docs/, and a full flutter/ SDK copy. The mobile app presents many strong architectural elements—clear layering (core, data, domain, presentation), a defined asset structure, and early-stage unit tests—yet it diverges from Flutter project norms in ways that introduce friction in tooling, consistency checks, and CI readiness.

The most consequential gaps are: absence of project-level code quality configuration (no analysis_options.yaml and related static analysis), missing platform folders (ios, web, linux, macos, windows) that constrain cross-platform builds and CI coverage, incomplete integration test scaffolding (no integration_test/ at the app root), and duplicate/unstandardized configuration material in the app/ directory. Assets are well-placed under app/assets, but font handling is inconsistent relative to Material 3 guidance and the declared pubspec.yaml assets.

Primary risks include: degraded developer experience (no shared lint rules, unclear analyzer exclusions), limited test coverage visibility (no coverage setup), restricted portability across platforms (no ios/web/linux/macos/windows trees), and tooling drift (embedded Flutter SDK copy increasing maintenance burden and causing path inconsistencies). Priority fixes should establish the project’s static analysis baseline and project files (analysis_options.yaml, dart_test.yaml), complete platform folders and shell app targets, create the integration_test/ scaffold with a basic smoke test, formalize a monorepo layout that cleanly separates the Flutter app from the backend and SDK copy, and document environment/secrets practices.

Immediate next steps:
- Introduce analysis_options.yaml and dart_test.yaml aligned with Flutter team conventions; enable tests and coverage in CI.
- Create missing platform directories with shell apps (flutter create) to unlock multi-platform builds and testing.
- Add integration_test/ with a trivial smoke test and wire it into CI for baseline regression checks.
- Separate concerns at the workspace root: keep the Flutter app under app/, move backend/ and documentation under separate roots, and remove or isolate the embedded SDK.
- Document asset conventions (fonts vs images vs icons) and update pubspec.yaml to reflect authoritative paths.

Addressing these gaps will materially improve build reliability, code consistency, test coverage, and long-term maintainability.

## Scope and Method

This assessment reviews the workspace structure with emphasis on the Flutter app under app/, aligning observations against standard Flutter project layout and configuration conventions. The focus is on:

- Project layout: presence and organization of lib/, test/, integration_test/, platform folders (android, ios, web, linux, macos, windows), and configuration artifacts.
- Code quality and configuration: analysis_options.yaml, dart_test.yaml, lints, analyzer exclusions, and test coverage enablement.
- Asset management: assets/images, assets/icons, assets/fonts and declared assets in pubspec.yaml.
- Test coverage: unit, widget, and integration tests; mocks and coverage tooling.
- Monorepo hygiene: separation of Flutter app, backend, docs, and the embedded Flutter SDK copy.
- Documentation completeness: app-level docs and gaps relative to the codebase and testing approach.

Limitations include the absence of workspace-level code quality configuration and environment documentation. The analysis relies on the observed project structure and file contents; recommendations are grounded in standard Flutter practices and the needs of a maintainable monorepo.

## Current Directory Layout (What exists today)

The workspace root aggregates multiple concerns. It contains the app/ directory (the Flutter application), backend/ (Node.js backend), deployment/ (CI/CD and environment scaffolding), docs/ (guides and analyses), scripts/ (utility scripts), and a full flutter/ directory that mirrors the Flutter SDK.

The app/ directory includes:
- A standard pubspec.yaml and a lock file, declaring dependencies such as provider, Riverpod, Dio, Supabase, SQLite, Hive, GoRouter, and testing tools. Material design is enabled and assets are declared for images, icons, and fonts.
- A lib/ directory with a clean layered structure:
  - core/: base classes, configuration (Supabase), constants, DI, navigation (GoRouter), network, security, services, theme, and utilities.
  - data/: models, datasources (local/remote scaffolds), repositories, and services.
  - domain/: entities (scaffold), repository interfaces, and use cases (base and auth scaffold).
  - presentation/: pages (login, home, splash, placeholders), providers (Riverpod/Provider), viewmodels (scaffold), widgets (scaffold).
- assets/: images/, icons/, fonts/, with a placeholder SVG under icons/.
- test/: unit and provider tests for repository and provider logic, including mocks generated via build_runner.

Platform directories under app/ are incomplete: an android/ tree exists with app/src/main/ and a local.properties stub; the ios/ path appears as android/ios/test, which is non-standard. No web/, linux/, macos/, or windows/ directories are present. No integration_test/ exists at the app root. Configuration files for code quality (analysis_options.yaml, dart_test.yaml) are not present at the app root; .dart_tool and a package config file exist.

Backend and deployment assets exist at the workspace level but outside the mobile app scope.

To orient stakeholders, Table 1 summarizes the observed app-level directories and their intended role, contrasted with standard expectations.

### Table 1. Observed App Directories vs Intended Purpose vs Flutter Standard Expectation

| Directory/File                               | Observed Presence | Intended Purpose (from content)                  | Flutter Standard Expectation                                        | Notes                                                                                  |
|----------------------------------------------|-------------------|--------------------------------------------------|-----------------------------------------------------------------------|----------------------------------------------------------------------------------------|
| lib/                                         | Present           | App code: core, data, domain, presentation       | Required                                                              | Well-organized layered structure; consistent with scalable Flutter architecture.       |
| lib/main.dart                                | Present           | Entry point, DI, routing, theming                | Required                                                              | Initializes Supabase, Hive, DI, and ScreenUtil; uses GoRouter and ProviderScope.      |
| pubspec.yaml                                 | Present           | Dependencies, assets declarations                 | Required                                                              | Declares assets paths; fonts path presence needs verification.                         |
| assets/images/                               | Present           | Image assets                                      | Optional but common                                                   | Good location; ensure declared in pubspec.yaml.                                        |
| assets/icons/                                | Present           | Icon assets, includes placeholder SVG            | Optional but common                                                   | Confirm icon usage and packaging approach.                                             |
| assets/fonts/                                | Present           | Font assets                                       | Optional; aligns with Material if used                                | Verify fonts are declared; avoid mixing non-font files here.                           |
| test/                                        | Present           | Unit and provider tests                           | Strongly recommended                                                  | Coverage setup not evident; ensure CI runs tests with coverage.                        |
| integration_test/                            | Missing           | End-to-end/UI integration tests                   | Recommended for regression and CI                                     | Should be created at app root.                                                         |
| android/                                     | Present           | Android platform build files                      | Required for Android builds                                           | Appears partial; ensure Gradle files, app/ module, and manifest are consistent.        |
| ios/                                         | Non-standard path | iOS platform build files                          | Required for iOS builds                                               | Path android/ios/test is incorrect; must be ios/ at app root with Xcode project.       |
| web/                                         | Missing           | Web build artifacts                               | Optional if targeting Web                                             | Create only if web support is planned.                                                 |
| linux/                                       | Missing           | Linux build artifacts                             | Optional if targeting Linux                                           | Create only if Linux support is planned.                                               |
| macos/                                       | Missing           | macOS build artifacts                             | Optional if targeting macOS                                           | Create only if macOS support is planned.                                               |
| windows/                                     | Missing           | Windows build artifacts                           | Optional if targeting Windows                                         | Create only if Windows support is planned.                                             |
| analysis_options.yaml                        | Missing           | Static analysis rules                             | Strongly recommended                                                  | Establish project-level lint/analysis baseline.                                        |
| dart_test.yaml                               | Missing           | Test configuration                                | Optional but recommended                                              | Define tags, timeouts, and CI test behavior.                                           |
| .dart_tool/                                  | Present           | Tooling metadata                                  | Generated/ephemeral                                                   | Ensure reproducible builds; do not commit build outputs.                               |

### App-Level Code Organization

The codebase demonstrates strong intent: core utilities and base classes (BaseViewModel, BaseView, BaseModel), clear separation of concerns across domain entities, repository interfaces and implementations, and a presentation layer using both Provider and Riverpod. The main.dart properly initializes Supabase (with PKCE), Hive, and dependency injection, then runs the app within a ProviderScope. Navigation is configured via GoRouter, and theming is declared in core/theme. This organization supports testability and future growth.

### Workspace-Level Aggregation

The presence of backend/, deployment/, docs/, scripts/, and the embedded flutter/ SDK at the root creates a monorepo-like aggregation. While there is value in housing documentation and deployment assets adjacent to code, mixing a complete Flutter SDK copy with application code increases maintenance burden, complicates tooling paths, and risks version drift. It is preferable to externalize the SDK or use a managed Flutter installation, thereby reducing duplication and ensuring consistency across developer machines and CI.

## Comparison with Flutter Project Standards (How it should be structured)

A standard Flutter project expects:
- A lib/ directory with the application code and a main.dart entry point.
- A test/ directory for unit and widget tests.
- Platform-specific directories: android/ and ios/ for mobile builds; optionally web/, linux/, macos/, windows/ for additional targets.
- An integration_test/ directory at the project root for end-to-end testing.
- A pubspec.yaml declaring dependencies and assets.
- Project-level configuration for analysis and tests (analysis_options.yaml and dart_test.yaml), enabling consistent linting and CI coverage.
- Clear asset declarations that match the physical structure under assets/.

From this perspective, pharmaTutor’s app/ is partially aligned: lib/ and test/ are present and organized; android/ exists; however, ios/ is mislocated (appearing under android/ios/test), and web/, linux/, macos/, windows/ are missing. The lack of integration_test/ is a notable gap. There is no project-level analysis_options.yaml or dart_test.yaml. Assets are structured well but the mapping to pubspec.yaml requires validation, particularly for fonts.

### Table 2. Required Flutter Files/Directories vs Observed Status

| Standard Item                   | Expected Location | Status        | Notes                                                                                 |
|---------------------------------|-------------------|---------------|---------------------------------------------------------------------------------------|
| lib/                            | Project root      | Present       | Strong layering and organization.                                                     |
| main.dart                       | lib/              | Present       | Properly initializes app services and routing.                                        |
| test/                           | Project root      | Present       | Unit and provider tests exist; coverage instrumentation not evident.                  |
| integration_test/               | Project root      | Missing       | Should be created with baseline smoke test and CI wiring.                             |
| android/                        | Project root      | Present       | Appears partial; ensure Gradle and manifest completeness.                             |
| ios/                            | Project root      | Misplaced     | Exists as android/ios/test (non-standard). Must be ios/ at root with Xcode project.   |
| web/                            | Project root      | Missing       | Optional; add only if Web support is planned.                                         |
| linux/                          | Project root      | Missing       | Optional; add only if Linux support is planned.                                       |
| macos/                          | Project root      | Missing       | Optional; add only if macOS support is planned.                                       |
| windows/                        | Project root      | Missing       | Optional; add only if Windows support is planned.                                     |
| pubspec.yaml                    | Project root      | Present       | Declares assets; fonts handling needs validation.                                     |
| analysis_options.yaml           | Project root      | Missing       | Establish static analysis baseline and exclude generation outputs.                    |
| dart_test.yaml                  | Project root      | Missing       | Define test tags/timeouts; integrate with CI.                                         |
| .dart_tool/                     | Project root      | Present       | Generated metadata; do not commit build outputs.                                      |

### Platform-Specific Gaps

The ios/ directory is incorrectly placed at android/ios/test, which will prevent Flutter from detecting the iOS project. This breaks iOS builds and removes iOS from CI matrices. Missing web/, linux/, macos/, and windows/ folders constrain cross-platform ambitions and CI options.

#### Table 3. Platform Directory Status and Fix Strategy

| Platform | Current State                | Correct Location             | Action                                      | Priority |
|----------|------------------------------|------------------------------|---------------------------------------------|----------|
| iOS      | Misplaced at android/ios/test| app/ios/                     | Create ios/ via flutter create; migrate assets| High     |
| Android  | Present but partial          | app/android/                 | Validate Gradle files and manifests          | Medium   |
| Web      | Missing                      | app/web/                     | Add if Web support is planned                | Low      |
| Linux    | Missing                      | app/linux/                   | Add if Linux support is planned              | Low      |
| macOS    | Missing                      | app/macos/                   | Add if macOS support is planned              | Low      |
| Windows  | Missing                      | app/windows/                 | Add if Windows support is planned            | Low      |

## Missing Standard Flutter Directories

The current structure lacks integration_test/ for end-to-end and UI flow validation, correct ios/ for iOS builds, and optional platform targets (web/, linux/, macos/, windows/) depending on product strategy. It also lacks analysis_options.yaml and dart_test.yaml at the project root.

### Table 4. Missing Directories and Configurations

| Item                 | Why Needed                                | Impact if Missing                           | Proposed Location | Owner           | Priority |
|----------------------|-------------------------------------------|---------------------------------------------|-------------------|-----------------|----------|
| integration_test/    | E2E/UI flow validation and CI regression  | No E2E coverage; limited QA automation      | app/integration_test/ | Mobile leads     | High     |
| ios/                 | iOS builds and device testing             | iOS builds fail; no iOS CI coverage         | app/ios/          | Mobile leads     | High     |
| web/                 | Web target (optional)                     | No Web builds; limited audience reach       | app/web/          | Product/Flutter  | Low      |
| linux/               | Linux target (optional)                   | No Linux builds                              | app/linux/        | Product/Flutter  | Low      |
| macos/               | macOS target (optional)                   | No macOS builds                              | app/macos/        | Product/Flutter  | Low      |
| windows/             | Windows target (optional)                 | No Windows builds                             | app/windows/      | Product/Flutter  | Low      |
| analysis_options.yaml| Static analysis baseline                   | Inconsistent linting; dev tooling variance  | app/analysis_options.yaml | Flutter lead | High     |
| dart_test.yaml       | Test configuration                         | Unclear test tags/timeouts; brittle CI      | app/dart_test.yaml      | Flutter lead | Medium   |

## Misplaced Files and Inconsistencies

The most visible misplacement is ios/ under android/ios/test, which prevents Flutter from recognizing an iOS project. Duplicated setup scripts and environment reports appear both at the workspace root and within app/, which can confuse onboarding and lead to version skew. Assets are correctly under app/assets, yet icons/app-placeholder.svg should ideally be in assets/images/ if it is not a font icon. The embedded Flutter SDK under the workspace root is non-standard and should be externalized or removed.

### Table 5. Misplaced/Duplicated Artifacts and Recommended Actions

| Current Path                               | Correct Path                         | Rationale                                        | Action                                              | Priority |
|--------------------------------------------|--------------------------------------|--------------------------------------------------|-----------------------------------------------------|----------|
| app/android/ios/test                       | app/ios/                             | Flutter expects ios/ at root for iOS builds      | Create ios/ with flutter create; migrate any assets | High     |
| Root-level setup/status docs duplicates    | Consolidated under docs/             | Reduce confusion; single source of truth         | Deduplicate and version control in docs             | Medium   |
| icons/app-placeholder.svg                  | assets/images/app-placeholder.svg    | Separate images from fonts/icons                 | Move to images; update references                   | Medium   |
| Embedded flutter/ SDK at root              | Externalized Flutter installation    | Avoid duplication and path conflicts             | Remove; use system-managed Flutter                  | High     |

## Documentation Gaps

While app/README.md is comprehensive on architecture, key developer-onboarding documentation is missing or incomplete. There is no explicit CHANGELOG.md, CONTRIBUTING.md tailored to the app, or ISSUE_TEMPLATE. Testing guidance is not centralized, and environment/secrets handling lacks a documented standard. Asset usage conventions and the relationship between declared assets in pubspec.yaml and physical paths require an official note.

### Table 6. Documentation Artifacts: Current vs Desired State

| Artifact                      | Current Status     | Gaps                                             | Proposed Location     | Owner             | Priority |
|------------------------------|--------------------|--------------------------------------------------|-----------------------|-------------------|----------|
| Architecture README          | Present (app/)     | None                                             | app/README.md         | Mobile leads      | Low      |
| CHANGELOG.md                 | Missing            | Version history and notable changes              | app/CHANGELOG.md      | Release manager   | Medium   |
| CONTRIBUTING.md              | Missing            | Contribution standards and process               | app/CONTRIBUTING.md   | Maintainers       | Medium   |
| Testing guide                | Missing            | Unit/widget/integration strategy and commands    | app/TESTING.md        | QA/Flutter lead   | High     |
| Environment/secrets guide    | Missing            | Local env, CI secrets, rotation                  | docs/ENV_SETUP.md     | DevOps            | High     |
| Asset conventions            | Partial (implicit) | Fonts vs images vs icons policy                  | app/ASSETS.md         | Design/Flutter    | Medium   |

## Configuration Organization Issues

The absence of analysis_options.yaml leaves static analysis unmanaged, increasing the risk of inconsistent style and undetected issues. Without dart_test.yaml, test tags, timeouts, and CI behavior are implicit rather than explicit. The pubspec.yaml asset declarations should be cross-checked against physical paths; the presence of assets/fonts/ suggests custom fonts, but validation is required. The main.dart initializes multiple systems (Supabase, Hive, DI); documenting the bootstrapping order and dependencies is advisable. Finally, a monorepo strategy should be formalized: keep the app under app/, relocate backend and docs to separate roots, and remove the embedded SDK.

### Table 7. Configuration Baseline to Establish

| Config File              | Purpose                                | Key Rules/Exclusions                                           | Example Location | Owner         | Priority |
|--------------------------|----------------------------------------|----------------------------------------------------------------|------------------|---------------|----------|
| analysis_options.yaml    | Static analysis and style consistency  | Exclude .dart_tool, generated, build outputs; enable lints     | app/             | Flutter lead  | High     |
| dart_test.yaml           | Test configuration                     | Define tags (unit, widget, integration), timeouts              | app/             | Flutter lead  | Medium   |
| pubspec.yaml validation  | Ensure asset declarations match paths  | Confirm images/, icons/, fonts/ mappings; remove mismatches    | app/             | Flutter lead  | Medium   |
| Monorepo layout          | Separate app, backend, docs            | Place backend/ and docs/ outside app/; remove SDK copy         | Root             | Maintainers   | High     |
| CI workflow updates      | Run tests with coverage and lint       | Enforce analysis and tests on PRs; gate on coverage thresholds | deployment/cicd  | DevOps        | High     |

## Risks and Impact

The current gaps expose tangible risks:
- iOS build breakage due to misplacement of ios/.
- Limited cross-platform reach with missing optional platform folders.
- Degraded code quality and developer experience in the absence of analysis_options.yaml.
- Incomplete testing coverage and lack of integration tests constraining regression detection.
- Asset management inconsistencies leading to runtime or build-time issues.

### Table 8. Risk Register

| Risk                                           | Evidence                                    | Impact                                  | Likelihood | Mitigation                                               | Priority |
|------------------------------------------------|---------------------------------------------|-----------------------------------------|------------|----------------------------------------------------------|----------|
| iOS builds fail                                | ios/ misplaced at android/ios/test          | No iOS binaries; blocked releases       | High       | Create ios/ via flutter create; validate build           | High     |
| Inconsistent code quality                      | No analysis_options.yaml                    | Lint drift; hidden issues               | High       | Add analysis_options.yaml; enforce in CI                | High     |
| Missing integration tests                      | No integration_test/                        | No E2E coverage; slower QA cycles       | High       | Create integration_test/ scaffold; add CI step           | High     |
| Asset path mismatches                          | fonts/images/icons mapping unclear          | Missing assets at runtime               | Medium     | Audit pubspec.yaml; fix paths; document conventions      | Medium   |
| SDK duplication                                | flutter/ copy at root                       | Version skew; maintenance burden        | Medium     | Externalize SDK; update tooling paths                    | Medium   |
| Incomplete platform coverage                   | Missing web/linux/macos/windows             | Limited audience and deployment options | Medium     | Add platform folders selectively per product strategy     | Medium   |
| Test coverage absent                           | No coverage config visible                  | Unknown quality gate                    | Medium     | Enable coverage; set thresholds in CI                    | Medium   |

## Prioritized Remediation Plan (So what to do)

A staged plan will resolve immediate blockers, establish configuration baselines, and then mature the testing and project layout discipline.

Short-term (1–2 weeks): 
- Create integration_test/ and add a basic smoke test for app launch.
- Introduce analysis_options.yaml and dart_test.yaml with standard rules, excluding generated outputs.
- Fix ios/ misplacement: run flutter create to generate the ios/ folder and migrate any existing assets.
- Audit pubspec.yaml assets and correct mappings (fonts vs images vs icons).
- Document environment/secrets handling and basic onboarding steps.

Medium-term (1–2 months):
- Establish a monorepo layout that cleanly separates app/, backend/, and docs/, removing the embedded SDK copy.
- Grow integration tests to cover login and navigation flows; wire tests into CI with coverage.
- Expand unit test coverage for domain use cases and repository logic; instrument coverage and enforce thresholds.
- Decide on optional platform targets (web/linux/macos/windows) based on product strategy; add corresponding folders.

Long-term (quarterly cadence):
- Formalize documentation pipelines, including CHANGELOG and CONTRIBUTING guidelines.
- Integrate linting, coverage, and test execution into pre-commit and PR gates.
- Periodically revisit asset and configuration policies to adapt to evolving dependencies and tooling.

### Table 9. Remediation Roadmap

| Task                                         | Impact                                | Effort | Owner           | Target Timeline | Dependencies                         |
|----------------------------------------------|---------------------------------------|--------|-----------------|-----------------|--------------------------------------|
| Add integration_test/ scaffold               | Enable E2E testing                    | Low    | Mobile/Flutter  | Week 1          | None                                 |
| Introduce analysis_options.yaml              | Improve code quality and DX           | Low    | Flutter lead    | Week 1          | None                                 |
| Add dart_test.yaml                           | Configure tests for CI                | Low    | Flutter lead    | Week 2          | None                                 |
| Create ios/ and fix iOS build                | Restore iOS builds                    | Medium | Mobile lead     | Week 2          | flutter create                       |
| Audit and correct pubspec assets             | Prevent runtime asset issues          | Low    | Flutter lead    | Week 2          | None                                 |
| Document env/secrets handling                | Ensure secure and consistent setup    | Low    | DevOps          | Week 2          | None                                 |
| Formalize monorepo layout                    | Reduce duplication, improve clarity   | Medium | Maintainers     | Month 2         | Team agreement                       |
| Remove embedded SDK                          | Eliminate version drift               | Medium | Maintainers     | Month 2         | Monorepo layout                      |
| Expand integration tests                     | Increase QA coverage                  | Medium | Mobile/QA       | Month 2         | integration_test scaffold            |
| Enable coverage in CI                        | Establish quality gate                | Low    | DevOps          | Month 2         | Test suite readiness                 |
| Decide and add optional platforms            | Enable target platforms               | Medium | Product/Flutter | Month 3         | Product strategy                     |
| Establish docs pipeline (CHANGELOG, etc.)    | Improve project governance            | Low    | Release manager | Quarter         | Team processes                       |

## Appendix A — Mapping to Flutter Standard Layout

The following crosswalk compares current paths with their standard locations and recommended actions.

### Table 10. Directory Crosswalk

| Current Path                               | Standard Location             | Status        | Action                                               |
|--------------------------------------------|-------------------------------|---------------|------------------------------------------------------|
| app/lib/                                   | app/lib/                      | Correct       | Maintain                                             |
| app/lib/main.dart                          | app/lib/main.dart             | Correct       | Maintain                                             |
| app/test/                                  | app/test/                     | Correct       | Expand coverage; wire into CI                        |
| app/integration_test/                      | app/integration_test/         | Missing       | Create scaffold with smoke test                      |
| app/android/                               | app/android/                  | Partial       | Validate Gradle files, manifests                     |
| app/ios/                                   | app/ios/                      | Misplaced     | Create ios/ via flutter create; migrate assets       |
| app/web/                                   | app/web/                      | Missing       | Add only if Web support planned                      |
| app/linux/                                 | app/linux/                    | Missing       | Add only if Linux support planned                    |
| app/macos/                                 | app/macos/                    | Missing       | Add only if macOS support planned                    |
| app/windows/                               | app/windows/                  | Missing       | Add only if Windows support planned                  |
| app/pubspec.yaml                           | app/pubspec.yaml              | Correct       | Audit asset paths                                    |
| app/analysis_options.yaml                  | app/analysis_options.yaml     | Missing       | Create with standard rules                           |
| app/dart_test.yaml                         | app/dart_test.yaml            | Missing       | Create to configure tests                            |
| assets/images/, assets/icons/, assets/fonts/| app/assets/...               | Mostly correct| Confirm mapping and usage                            |

## Appendix B — Checklists

These checklists can be used to verify alignment with Flutter standards and project hygiene.

### Table 11. Compliance Checklist

| Criterion                                  | Evidence                                      | Status   | Remediation Owner | Due Date |
|--------------------------------------------|-----------------------------------------------|----------|-------------------|----------|
| Project-level analysis_options.yaml        | Review app/ root                               | Missing  | Flutter lead      | Week 1   |
| Project-level dart_test.yaml               | Review app/ root                               | Missing  | Flutter lead      | Week 2   |
| integration_test/ exists                   | Review app/ root                               | Missing  | Mobile/Flutter    | Week 1   |
| iOS project structure                      | Review app/ios/                                | Misplaced| Mobile lead       | Week 2   |
| Android project structure                  | Review app/android/                            | Partial  | Mobile lead       | Week 2   |
| Assets align with pubspec.yaml             | Review app/pubspec.yaml and assets/            | Unclear  | Flutter lead      | Week 2   |
| Monorepo layout separation                 | Review root, app/, backend/, docs/             | Partial  | Maintainers       | Month 2  |
| CI runs tests with coverage                | Review deployment/cicd workflows               | Unclear  | DevOps            | Month 2  |

---

### Information Gaps

- No top-level analysis_options.yaml or equivalent Flutter/dart lints configuration file was found in the app directory.
- No explicit integration_test/ directory under the app root for end-to-end tests.
- Platform folders ios/, web/, linux/, macos/, windows/ are missing; the ios/ path appears incorrectly under android/ios/test.
- No environment/secrets documentation was observed for local development and CI.
- A complete listing of unit/widget/integration test coverage metrics is not available; coverage configuration and reporting are unclear.
- The exact mapping between declared assets in pubspec.yaml (images, icons, fonts) and physical paths requires validation (fonts handling and icon usage).
- The relationship between the root-level flutter/ directory and the app build is unclear; it appears to be a full SDK copy rather than an external installation.
- The monorepo strategy across app/, backend/, and docs/ lacks a formal document defining boundaries and ownership.

By addressing the identified gaps with the prioritized plan, pharmaTutor will align closely with Flutter standards, strengthen test and CI maturity, and reduce friction for contributors and release engineering. The improvements are practical and staged to deliver quick wins while laying a durable foundation for multi-platform growth and long-term maintainability.