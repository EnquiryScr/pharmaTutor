# GitHub Repository File Organization Best Practices for 2025 (Flutter/Dart Focus)

## Executive Summary

Engineering teams succeed or struggle based on the predictability of their repositories. In 2025, this is truer than ever: repository layout is not merely a cosmetic concern, it directly shapes onboarding speed, code review quality, continuous integration stability, and security posture. For Flutter and Dart projects, aligning repository structure to the language’s package conventions and Flutter’s architectural guidance creates a single source of truth that accelerates delivery while reducing risk.

This report consolidates official guidance and pragmatic patterns into nine focus areas: Flutter/Dart structure, root-level organization, documentation, configuration, code versus non-code separation, assets, .github usage, GitHub Actions, and security. The recommendations center on a few high‑leverage decisions. First, treat the Dart package layout as the backbone of the repository, particularly for lib, test, tool, doc, example, and web directories, and their explicit expectations for public versus private code and generated artifacts[^1]. Second, adopt a feature‑first Flutter application structure over a layer‑first approach to improve scalability and maintainability as features grow[^4][^2]. Third, formalize the .github directory as the single location for repository governance and automation, and keep GitHub Actions workflows in .github/workflows at the repository root, using consistent naming conventions to manage scale[^7][^8][^9]. Finally, apply security controls—branch protection, pinned dependencies, secrets scanning, and signed releases—within CI to reduce supply chain risk and prevent leaks[^10].

To make adoption straightforward, Table 1 summarizes the top recommendations, their rationale, and the primary sources that underpin them.

Table 1: Top recommendations summary

| Recommendation | Rationale | Primary Sources |
|---|---|---|
| Adopt Dart package layout conventions (lib/, lib/src/, test/, tool/, doc/, example/, web/, bin/) | Aligns to official conventions; clarifies public vs private code and generated artifacts; reduces ambiguity in reviews | [^1] |
| Use feature‑first structure for Flutter apps (layers inside features) | Improves scalability and maintainability; co‑locates feature code and tests; avoids dispersion across layers | [^4][^2] |
| Keep GitHub Actions workflows in .github/workflows at root | Required by GitHub; predictable discovery and execution; enables consistent governance | [^7][^8][^9] |
| Centralize repository governance in .github (templates, CODEOWNERS, contributing, security) | Standardizes issues/PRs, review ownership, and security policy; improves contributor experience | [^6][^5] |
| Separate config and secrets; store .env in .gitignore and commit .env.sample | Prevents accidental leaks; clarifies environment variables; supports local development safely | [^17] |
| Enforce branch protection, pinned dependencies, SAST/SCA, secrets scanning, signed releases | Hardens repository and CI against supply chain threats and leakage; raises change quality | [^10] |
| Organize assets under a top‑level assets/ and declare them in pubspec.yaml | Keeps binary/resources out of lib/; ensures predictable bundling and access patterns | [^12][^13] |
| Mirror test/ structure to lib/ for Flutter | Preserves discoverability and alignment between production and test code | [^4] |
| Keep generated docs out of source control (doc/api/, .dart_tool) | Maintains clean diffs; avoids merge noise; respects tool‑generated directories | [^1] |
| Use reusable workflows and organization‑level templates | Scales automation across teams/repos with consistent security and performance | [^18][^19][^20] |

Together, these practices form a coherent blueprint that teams can implement incrementally. The remainder of this report explains the foundations and translates them into practical steps and tables that teams can adopt as‑is or adapt to their context.

## Methodology and Source Reliability

The analysis synthesizes three classes of sources: official documentation from GitHub and Flutter/Dart; reputable technical articles and Q&A threads; and security advisories. Official documentation anchors conventions that affect repository structure and workflow behavior, while recent articles provide pragmatic scaling patterns for feature‑first organization and assets management. Security advisories and industry guidance from 2025 underscore supply chain risks and mandate concrete controls.

Two criteria guided inclusion. First, recency: guidance published or updated in 2023–2025 carries greater weight, especially for security. Second, authority: GitHub Docs and Flutter/Dart official docs provide the baseline for enforceable conventions; vendor and community sources are incorporated where they provide actionable patterns that complement official guidance[^14][^10].

Limitations and information gaps are acknowledged explicitly. GitHub does not natively support subdirectories under .github/workflows, and community requests for this capability remain open; teams must therefore rely on consistent file naming and organization‑level reusable workflows to manage scale[^21][^22]. The official Flutter documentation provides a high‑level guide to app architecture without prescribing a single directory layout; community articles fill this gap with feature‑first guidance that remains a recommended pattern rather than an official standard[^2][^4]. Some security risks referenced predate 2025 but are still relevant as part of the supply chain context; this report focuses on recent guidance where possible[^23][^24]. Finally, GitHub’s general repository best practices are broad and not Flutter‑specific; applying them to Flutter projects requires interpretation through the lens of Dart package conventions and Flutter assets handling[^14][^1][^12].

## Flutter/Dart Project Structure Standards (2025)

A Flutter/Dart repository should start from the official Dart package layout conventions. These conventions define the purpose of top‑level directories, the boundaries of public versus private code, and the treatment of generated artifacts. They are the reference point that reduces ambiguity in code reviews and CI configuration.

At the root, pubspec.yaml is mandatory. The lib/ directory contains public library code, with lib/src/ reserved for internal implementation that must not be imported by other packages. test/ holds unit tests; integration_test/ is reserved for Flutter integration tests. tool/ is intended for development scripts, not end‑user executables; bin/ is used for public command‑line tools. doc/ contains authored documentation, with doc/api/ reserved for generated API documentation, which should not be committed. example/ provides standalone programs demonstrating package usage, and web/ contains entrypoint code and supporting files for web packages. .dart_tool/ is a tool‑generated cache directory and must not be committed; pubspec.lock should be committed only for application packages, not for libraries[^1].

Beyond directory roles, import discipline is critical. Within a package, prefer relative imports for intra‑lib movement and avoid reaching into lib/src from other packages. Effective Dart guidance discourages import paths that cross the lib boundary inappropriately, which helps maintain encapsulation and prevents accidental coupling[^16][^1]. In practice, this means placing shared application logic in lib/ and lib/src/ with clear boundaries, while keeping non‑code assets out of lib/ to avoid cluttering the public API surface[^1].

Table 2 maps the standard directories to their purposes and commit expectations.

Table 2: Dart package directory map

| Directory | Purpose | Commit? | Notes |
|---|---|---|---|
| lib/ | Public libraries | Yes | Public API surface; organize with package‑name parity[^1] |
| lib/src/ | Internal implementation | Yes | Not for external import; encapsulates private details[^1] |
| test/ | Unit tests | Yes | Mirror lib/ structure for discoverability[^1][^4] |
| integration_test/ | Flutter integration tests | Yes | Separate from unit tests; Flutter‑specific[^1] |
| benchmark/ | Performance benchmarks | Yes | Optional; for performance testing[^1] |
| bin/ | Public executables | Yes | CLI tools accessible via dart run/pub global[^1] |
| tool/ | Development scripts | Yes | Internal tooling; not for end users[^1] |
| doc/ | Authored docs | Yes | Generated docs belong in doc/api/ and should not be committed[^1] |
| example/ | Example programs | Yes | Demonstrates usage; can display on pub.dev[^1] |
| web/ | Web entrypoints | Yes | For web packages; contains HTML/CSS/Dart entrypoint[^1] |
| .dart_tool/ | Tool cache | No | Generated by tools; do not commit[^1] |
| pubspec.yaml | Package metadata | Yes | Required at root[^1] |
| pubspec.lock | Lockfile | App only | Commit for application packages; do not commit for libraries[^1] |

The second structural decision is application organization. Flutter’s official guide describes a layered architecture—UI, Data, and an optional Domain layer—with well‑defined responsibilities and boundaries[^2]. However, how those layers are foldered has a major impact on maintainability. A layer‑first approach places all presentation code together, all data code together, and so on, with features dispersed across layers. As features accumulate, this dispersion makes it harder to modify or remove a feature cohesively. In contrast, a feature‑first approach places the feature’s presentation, application services, domain models, and data sources inside the feature’s directory, with layers as subfolders. This co‑location keeps feature work focused, simplifies testing, and scales more naturally as the app grows[^4].

Table 3 contrasts these patterns.

Table 3: Layer‑first vs feature‑first comparison

| Aspect | Layer‑first | Feature‑first |
|---|---|---|
| Structure | Layers contain multiple features | Features contain layers |
| Scalability | Degrades as features grow | Scales well with growing features |
| Deletion ease | Hard; files spread across layers | Easy; remove feature directory |
| Team focus | Requires cross‑layer coordination | Localized ownership and reviews |
| Testing alignment | Tests dispersed | Tests mirror feature folders[^4] |

A pragmatic hybrid is often warranted: use feature‑first for business features (authentication, checkout, orders), and centralize truly shared utilities and UI components (constants, exceptions, localization, routing, common widgets, utils). Avoid creating an oversized “common” dumping ground; use the hybrid to keep shared concerns tidy and bounded[^4].

Finally, mirror test/ to lib/ so that a feature’s tests sit alongside its code. This practice preserves discoverability, reduces friction in test‑driven development, and simplifies mapping production code to its test coverage[^4].

## Root Directory Organization

The repository root should be minimal and purposeful. Its primary role is to host configuration, documentation, and high‑level materials that govern the repository, while keeping code and assets in their conventional subdirectories. The root should contain at minimum pubspec.yaml and README.md; for published packages, include LICENSE and CHANGELOG.md. A top‑level assets/ folder—outside lib/—keeps binary resources and data files co-located but separate from public libraries[^1][^12]. Avoid committing generated caches (.dart_tool/) and lockfiles for libraries (pubspec.lock is for application packages only)[^1].

Organizing by concern helps maintain clarity: source code lives under lib/, tests under test/, documentation under doc/, tooling under tool/, and examples under example/. The root then serves as a clean entry point with essential docs and configuration, signaling the project’s conventions to contributors immediately[^15][^1].

Table 4 outlines a recommended root layout with commit guidance.

Table 4: Recommended root layout

| Item | Location | Commit? | Rationale |
|---|---|---|---|
| pubspec.yaml | Root | Yes | Defines package metadata and dependencies[^1] |
| README.md | Root | Yes | Project overview; GitHub displays it automatically[^14][^15] |
| LICENSE | Root | Yes (packages) | Required for published packages; legal clarity[^1] |
| CHANGELOG.md | Root | Yes | Versioned history; displayed on pub.dev for packages[^1] |
| assets/ | Root | Yes | Non‑code resources (images, fonts, data); declared in pubspec[^12] |
| lib/ | Root | Yes | Public libraries and internal implementation[^1] |
| test/ | Root | Yes | Unit tests; mirror lib/ for Flutter[^1][^4] |
| doc/ | Root | Yes | Authored docs; keep generated docs out of VCS[^1] |
| example/ | Root | Yes | Example programs; helps users and pub.dev[^1] |
| tool/ | Root | Yes | Development scripts; internal tooling[^1] |
| web/ | Root (web packages) | Yes | Web entrypoints and support files[^1] |
| .github/ | Root | Yes | Repository governance (templates, CODEOWNERS), workflows[^6][^7] |
| .dart_tool/ | Root | No | Tool cache; not committed[^1] |
| pubspec.lock | Root | App only | Commit for applications; not for libraries[^1] |

This structure makes navigation predictable. Engineers quickly learn where to find code, tests, docs, and assets, and reviewers can assess whether the right artifacts are committed or generated.

## Documentation Placement

Good documentation reduces friction at every stage of the software lifecycle. At the repository level, GitHub recommends a README in the root for every repository so that visitors can quickly understand the project, how to build and test it, and how to contribute[^14]. For published Dart packages, README.md and CHANGELOG.md serve dual roles: they appear on pub.dev and anchor user expectations for versioning and changes[^1]. Generated API documentation should live under doc/api/ and must not be committed; keeping it out of version control avoids diff noise and storage bloat[^1]. The .github directory is the canonical home for contributor documentation such as CONTRIBUTING.md, CODE_OF_CONDUCT.md, SECURITY.md, and funding configuration (FUNDING.yml). GitHub surfaces these files in relevant UI contexts (e.g., issues and pull requests), increasing their visibility and impact[^6][^5].

Table 5 summarizes where each documentation artifact should live and why.

Table 5: Documentation artifacts placement

| File | Location | Why |
|---|---|---|
| README.md | Root | GitHub renders it on the repository landing page; standard entry point[^14] |
| CHANGELOG.md | Root | Version history for packages and apps; aids users and maintainers[^1] |
| CONTRIBUTING.md | Root or .github/ | GitHub links it on PRs/issues; standardizes contributions[^6][^5] |
| CODE_OF_CONDUCT.md | Root or .github/ | GitHub surfaces it; clarifies community standards[^6][^5] |
| SECURITY.md | Root or .github/ | GitHub links it for vulnerability reporting; sets policy expectations[^6] |
| FUNDING.yml | .github/ | Enables sponsor button and funding links[^6] |
| ISSUE_TEMPLATE | .github/ISSUE_TEMPLATE/ | Standardizes issue intake; improves triage[^5] |
| PULL_REQUEST_TEMPLATE | .github/PULL_REQUEST_TEMPLATE.md or .github/pull_request_template.md | Standardizes PR description; improves review quality[^6] |
| doc/api/ (generated) | doc/api/ | Generated API docs; do not commit[^1] |

Adopting this placement ensures contributors and users encounter the right information at the right time, reducing onboarding time and miscommunication.

## Configuration File Organization

Configuration should be explicit and safe. Store non‑secret configuration in version control; keep secrets out. A practical pattern is to commit .env.sample (or similar) that enumerates expected variables with safe defaults, while instructing developers to create local .env files that remain uncommitted via .gitignore. This approach allows teams to collaborate on configuration structure without risking exposure of credentials or environment‑specific values[^17]. The repository’s README and CONTRIBUTING guidance should describe how to obtain and configure local environment variables.

In CI/CD, use GitHub Environments to manage per‑environment secrets and protection rules. Environments isolate production credentials, enforce approvals, and allow targeted deployment controls. Admin access is required to configure environment protections, and deleting an environment also removes its associated secrets and rules, which is useful for hygiene when projects wind down[^11]. On the security front, distinguish between safe‑to‑share configuration and sensitive secrets; mixing them in a single .env file increases leak risk and complicates rotation[^25]. 

Table 6 provides a blueprint for common configuration artifacts.

Table 6: Configuration artifact blueprint

| Artifact | Location | Commit? | Risk Level | Rationale |
|---|---|---|---|---|
| .env.sample | Root | Yes | Low | Documents expected variables and defaults[^17] |
| .env | Root | No | High | Contains sensitive values; never commit[^17] |
| .gitignore | Root | Yes | Low | Excludes local .env and generated caches[^17][^1] |
| CI env config | GitHub Environments | N/A | Medium | Centralizes per‑env secrets and rules[^11] |
| App config files | Root or config/ | Yes | Low | Safe‑to‑share settings; not secrets[^25] |

This separation keeps the repository safe while enabling smooth local development and consistent CI behavior.

## Code vs Non-Code Files Separation

Clear boundaries between code and non‑code reduce cognitive load and avoid accidental commits of sensitive or build‑generated content. Dart’s conventions provide that lib/ and test/ are for code, while doc/ is for authored documentation, example/ for demos, and assets/ for binary resources. Generated caches (.dart_tool/) and build outputs should never be committed[^1]. The same principle applies to non‑code artifacts such as large datasets or binaries: keeping them out of version control reduces clone size, avoids opaque risks, and ensures that review focus remains on source code. When datasets are integral to the project, consider storing them in a database and managing schema changes via migrations rather than placing raw data files under version control[^1][^26]. If a repository contains multiple applications or packages, a mono‑repo can simplify shared dependency management; if separation of ownership and lifecycle is paramount, a multi‑repo approach may be preferable[^27].

Table 7 offers practical guidance on whether to commit non‑code artifacts.

Table 7: Code vs non‑code classification

| Artifact | Commit? | Rationale | Source |
|---|---|---|---|
| lib/ | Yes | Source code and public APIs | [^1] |
| test/ | Yes | Unit/integration tests | [^1] |
| doc/ (authored) | Yes | Project documentation | [^1] |
| doc/api/ (generated) | No | Generated docs; keep out of VCS | [^1] |
| assets/ | Yes | Images, fonts, JSON; declare in pubspec | [^12][^13] |
| .dart_tool/ | No | Tool cache; generated | [^1] |
| Large binaries | No | Increases clone size; opaque risk | [^10][^26] |
| Data files (raw) | No (prefer DB) | Manage via migrations; reduces bloat | [^26] |

Maintaining these boundaries improves build reproducibility, security, and review quality.

## Assets and Resources Organization (Flutter)

Assets should be organized under a top‑level assets/ directory with logical subfolders—images/, fonts/, data/—and declared under the flutter section in pubspec.yaml. This approach keeps assets out of lib/ and preserves the public API surface for Dart libraries. Images are accessed via Image.asset; JSON data via rootBundle; fonts either statically through TextStyle or dynamically via font loading routines. SVGs require flutter_svg and are accessed using SvgPicture.asset[^12][^13].

Table 8 maps asset types to folder locations, declarations, and access methods.

Table 8: Asset type map

| Type | Location | Declaration (pubspec) | Access Method |
|---|---|---|---|
| Images (PNG, JPG, WebP, GIF, etc.) | assets/images/ | flutter: assets: - assets/images/ | Image.asset('assets/images/...')[^12][^13] |
| Fonts | assets/fonts/ | flutter: fonts: (per font) | TextStyle(fontFamily: ...) or dynamic load[^12][^13] |
| JSON data | assets/data/ | flutter: assets: - assets/data/ | rootBundle.loadString('assets/data/...')[^12][^13] |
| SVG | assets/images/ | dependency: flutter_svg | SvgPicture.asset('assets/images/...')[^13] |

Declare assets explicitly, run flutter pub get after changes, and keep the assets hierarchy tidy to support consistent access patterns across features[^12][^13].

## .github Folder Usage

The .github directory centralizes repository governance, contributor experience, and automation. Its common contents include ISSUE_TEMPLATE, PULL_REQUEST_TEMPLATE, CONTRIBUTING.md, CODE_OF_CONDUCT.md, SECURITY.md, FUNDING.yml, and CODEOWNERS. GitHub links these artifacts in relevant UI contexts (e.g., when opening an issue or pull request), which increases the likelihood that contributors follow established patterns[^6][^5]. Repository and organization templates allow teams to bootstrap new repositories with the same directory structure, branches, and files, standardizing layouts and governance across projects[^20]. Organizations can also provide workflow templates and share actions and reusable workflows internally, enabling consistent CI/CD patterns without duplicating files[^18][^19].

Table 9 inventories key .github artifacts.

Table 9: .github artifacts inventory

| Item | Purpose | Location | GitHub UI Behavior |
|---|---|---|---|
| ISSUE_TEMPLATE | Standardize issue intake | .github/ISSUE_TEMPLATE/ | Appears in New Issue form[^5] |
| PULL_REQUEST_TEMPLATE | Standardize PR description | .github/PULL_REQUEST_TEMPLATE.md | Pre‑fills PR body[^6] |
| CONTRIBUTING.md | Guide contributions | Root or .github/ | Linked on issues/PRs[^6] |
| CODE_OF_CONDUCT.md | Community standards | Root or .github/ | Linked in repository UI[^6] |
| SECURITY.md | Vulnerability reporting | Root or .github/ | Linked on security advisories[^6] |
| FUNDING.yml | Funding links | .github/ | Enables sponsor button[^6] |
| CODEOWNERS | Review ownership | .github/ or Root | Requests reviews from owners[^6] |
| Workflows | CI/CD automation | .github/workflows/ | Runs on events per workflow[^7][^8] |

Using .github as a single source of truth simplifies governance and onboarding while scaling automation across repositories.

## GitHub Actions and CI/CD Organization

GitHub Actions workflows must be stored in .github/workflows at the repository root. Although the community has requested subdirectory support under .github/workflows to better organize large numbers of workflows, this is not supported; workflows cannot reside in subdirectories within .github/workflows, so teams rely on consistent naming to group and manage them[^8][^9][^21][^22]. Good naming conventions—e.g., app.frontend.yml, app.backend.yml, lib.core.yml, deploy.prod.yml—make intent and scope obvious. Keep workflow permissions minimal, use reusable workflows to avoid duplication, and reference organization‑level templates for consistency. When working in multi‑directory repositories, use working-directory settings carefully to target specific jobs and components without scattering configuration[^28][^7][^30][^18][^19].

Security hardening is essential. Vet third‑party actions, pin dependencies to exact versions, and handle secrets safely. In March 2025, a supply chain compromise of a widely used action (tj‑actions/changed‑files) highlighted the risk of unvetted dependencies; organizations were advised to audit usage and update to safe versions promptly[^23]. Earlier Git vulnerabilities also demonstrate the need to keep tooling updated and to validate repository behavior across the supply chain[^24].

Table 10 provides a naming taxonomy, and Table 11 lists the default trigger events that determine when workflows run.

Table 10: Workflow file naming taxonomy

| Pattern | Example | Purpose |
|---|---|---|
| app.component.yml | app.frontend.yml | Focus on specific application component |
| lib.package.yml | lib.core.yml | Target a library package in the repo |
| deploy.env.yml | deploy.prod.yml | Environment‑specific deployments |
| ci.event.yml | ci.pr.yml | Event‑driven CI (pull requests, pushes) |

Table 11: Common workflow triggers

| Event | Typical Use | Notes |
|---|---|---|
| push | CI on commits | Validate builds/tests on push[^7] |
| pull_request | Pre‑merge validation | Required checks before merge[^7][^30] |
| release | Publishing | Tag‑based release workflows[^7] |
| schedule | Maintenance tasks | Nightly builds, dependency scans[^7] |

Use environments to gate deployments and manage production secrets, and enforce checks via branch protection to prevent unreviewed changes from reaching critical branches[^11].

## Security Considerations for Sensitive Files

Security is a discipline, not a checklist. For repositories and CI, several controls have outsized impact. Enforce branch protection to require reviews, status checks, and prevent history rewrites on main/master. Run security tests in CI pipelines: Static Application Security Testing (SAST), Software Composition Analysis (SCA), malicious package detection, secrets detection, and container scanning where applicable. Pin dependencies to exact versions to ensure reproducibility and avoid confusion attacks. Minimize binary artifacts in the repository because they are opaque and can conceal malware. Establish a clear security policy and require fuzzing tests where relevant to catch input‑related vulnerabilities early[^10].

Separate secrets from configuration. Never commit .env to version control; use .env.sample to document expected variables and keep local .env in .gitignore. In CI, use GitHub Environments to store secrets and enforce protection rules. Differentiate safe‑to‑share config (e.g., feature flags, endpoints) from sensitive secrets (e.g., credentials, tokens), and avoid mixing them in the same file, which complicates rotation and increases leak risk[^17][^11][^25]. Keep third‑party actions updated and audit usage after supply chain advisories; in March 2025, CISA warned of a compromise affecting tj‑actions/changed‑files, underscoring the need for vigilance[^23]. Maintain Git client and server tooling to mitigate known vulnerabilities, and practice secure packaging and signed releases to assure integrity across distribution[^24][^10].

Table 12 provides a control matrix to operationalize these practices.

Table 12: Security control matrix

| Control | Risk Addressed | Implementation Location | Source |
|---|---|---|---|
| Branch protection | Unreviewed merges | Repository settings | [^10] |
| Required reviews/status checks | Low‑quality or malicious changes | Branch protection rules | [^10] |
| SAST/SCA in CI | Vulnerable code and dependencies | Workflows | [^10] |
| Secrets scanning | Credential leaks | Workflows; pre‑commit hooks | [^10] |
| Pinned dependencies | Supply chain attacks | Dependency manifests | [^10] |
| Signed releases | Tampering in distribution | Release workflows | [^10] |
| Minimize binaries | Opaque malware risk | Repo policy | [^10] |
| Fuzzing tests | Input‑based vulnerabilities | Workflows; test suites | [^10] |
| Environment protections | Production credential leaks | GitHub Environments | [^11] |
| .env hygiene | Accidental secret exposure | .gitignore, .env.sample | [^17][^25] |
| Third‑party action vetting | Action compromise | Workflows; governance | [^23] |
| Git tooling updates | Client/server vulnerabilities | Tooling and CI images | [^24] |

Adopting this control set materially reduces repository and CI risk.

## Implementation Roadmap and Checklists

A phased rollout balances adoption speed with stability. Start with structural alignment to the Dart package layout and feature‑first organization, then formalize documentation placement, followed by configuration hygiene and .github conventions. Introduce secure CI/CD workflows next, and finally enforce security controls across the repository.

Phase 1: Structure
- Align root and lib/ to Dart package conventions.
- Adopt feature‑first structure for Flutter applications.
- Mirror test/ to lib/ and ensure integration tests sit under integration_test/.
- Remove generated caches (.dart_tool/) and uncommit library lockfiles.

Phase 2: Documentation
- Create or update README.md at root; add CONTRIBUTING, CODE_OF_CONDUCT, SECURITY, FUNDING, and templates.
- Establish doc/ as the authored documentation location; exclude generated API docs.

Phase 3: Configuration and Assets
- Create .env.sample and .gitignore .env; document local setup in README/CONTRIBUTING.
- Organize assets under assets/ with logical subfolders; declare in pubspec.yaml.
- Ensure CI uses GitHub Environments for per‑environment secrets and protection rules.

Phase 4: CI/CD and Automation
- Store workflows under .github/workflows; apply naming conventions.
- Introduce reusable workflows and organization‑level templates; centralize common checks.

Phase 5: Security Hardening
- Enforce branch protection and required checks; pin dependencies.
- Add SAST, SCA, secrets detection; practice signed releases and secure packaging.
- Audit third‑party actions and update tooling regularly.

To support execution, Table 13 provides a consolidated checklist.

Table 13: Consolidated checklist

| Task | Owner | Phase | Verification |
|---|---|---|---|
| Align directories to Dart layout | Tech Lead | 1 | Repo structure review[^1] |
| Adopt feature‑first Flutter structure | App Architect | 1 | Folder structure audit[^4][^2] |
| Mirror test/ to lib/ | QA Lead | 1 | Test path mapping[^4] |
| Remove .dart_tool/ and uncommit lib lockfiles | Repo Maintainer | 1 | CI logs; git history check[^1] |
| Create root README, LICENSE, CHANGELOG | Maintainer | 2 | Files present and complete[^14][^1] |
| Add .github governance files | Maintainer | 2 | Templates appear in UI[^6][^5] |
| Establish doc/ authored docs | Docs Owner | 2 | Docs build cleanly; no generated content[^1] |
| Add .env.sample and .gitignore .env | Dev Lead | 3 | File scan; CI env completeness[^17] |
| Declare assets in pubspec.yaml | App Architect | 3 | Build includes assets[^12][^13] |
| Configure GitHub Environments | DevOps | 3 | Environment rules enforced[^11] |
| Implement workflows in .github/workflows | DevOps | 4 | Workflows run on events[^7][^8] |
| Use reusable workflows/templates | Org Owner | 4 | Cross‑repo consistency[^18][^19][^20] |
| Enforce branch protection | Security Lead | 5 | Merge checks required[^10] |
| Add SAST/SCA, secrets detection | Security Lead | 5 | CI reports integrated[^10] |
| Pin dependencies | Dependency Owner | 5 | Reproducible builds[^10] |
| Practice signed releases | Release Manager | 5 | Verifiable tags/releases[^10] |
| Audit third‑party actions | Security Lead | 5 | Advisory action review[^23] |
| Update Git tooling | DevOps | 5 | CI images/tooling current[^24] |

Review the repository quarterly to incorporate new security advisories and adjust for project growth.

## References

[^1]: Package layout conventions - Dart. https://dart.dev/tools/pub/package-layout  
[^2]: Guide to app architecture - Flutter documentation. https://docs.flutter.dev/app-architecture/guide  
[^4]: Flutter Project Structure: Feature-first or Layer-first? https://codewithandrea.com/articles/flutter-project-structure/  
[^5]: Configuring issue templates for your repository - GitHub Docs. https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository  
[^6]: GitHub Repository Structure Best Practices. https://medium.com/code-factory-berlin/github-repository-structure-best-practices-248e6effc405  
[^7]: Workflows - GitHub Docs. https://docs.github.com/en/actions/concepts/workflows-and-actions/workflows  
[^8]: Workflow syntax for GitHub Actions. https://docs.github.com/actions/using-workflows/workflow-syntax-for-github-actions  
[^9]: Where should you put the GitHub workflow directory for Actions in a full-stack project? https://stackoverflow.com/questions/62288443/where-should-you-put-the-git-hub-workflow-directory-for-actions-in-a-full-stack  
[^10]: 12 Best Practices for Secure Code Repositories (2025 Guide). https://checkmarx.com/supply-chain-security/repository-health-monitoring-part-2-essential-practices-for-secure-repositories/  
[^11]: Using environments for deployment - GitHub Docs. https://docs.github.com/actions/deployment/targeting-different-environments/using-environments-for-deployment  
[^12]: Adding assets and images - Flutter documentation. https://docs.flutter.dev/ui/assets/assets-and-images  
[^13]: Managing Assets in Flutter: Images, Fonts, and Data. https://techdynasty.medium.com/managing-assets-in-flutter-images-fonts-and-data-2fa944fe4b40  
[^14]: Best practices for repositories - GitHub Docs. https://docs.github.com/en/repositories/creating-and-managing-repositories/best-practices-for-repositories  
[^15]: What's the best structure for a repository? https://softwareengineering.stackexchange.com/questions/86914/whats-the-best-structure-for-a-repository  
[^16]: Effective Dart: Don't allow an import path to reach into or out of lib. https://dart.dev/effective-dart/usage#dont-allow-an-import-path-to-reach-into-or-out-of-lib  
[^17]: Managing project config files in repository. https://stackoverflow.com/questions/40548141/managing-project-config-files-in-repository  
[^18]: Creating workflow templates for your organization - GitHub Docs. https://docs.github.com/actions/sharing-automations/creating-workflow-templates-for-your-organization  
[^19]: Sharing actions and workflows with your organization - GitHub Docs. https://docs.github.com/actions/creating-actions/sharing-actions-and-workflows-with-your-organization  
[^20]: Creating a template repository - GitHub Docs. https://docs.github.com/repositories/creating-and-managing-repositories/creating-a-template-repository  
[^21]: Support organizing workflows in directories #15935 - GitHub Community. https://github.com/orgs/community/discussions/15935  
[^22]: Feature request: allow workflow configuration in sub-folders #18055 - GitHub Community. https://github.com/orgs/community/discussions/18055  
[^23]: Supply Chain Compromise of third-party tj-actions/changed-files (CVE-2025-30066) - CISA. https://www.cisa.gov/news-events/alerts/2025/03/18/supply-chain-compromise-third-party-tj-actionschanged-files-cve-2025-30066-and-reviewdogaction  
[^24]: Git security vulnerabilities announced - The GitHub Blog. https://github.blog/open-source/git/git-security-vulnerabilities-announced-6/  
[^25]: Env config vs. secrets: What devs get wrong and why it's risky - Security Boulevard. https://securityboulevard.com/2025/10/env-config-vs-secrets-what-devs-get-wrong-and-why-its-risky/  
[^26]: Pros and cons for keeping code and data in separate repositories. https://stackoverflow.com/questions/13640292/pros-and-cons-for-keeping-code-and-data-in-separate-repositories  
[^27]: Monorepo vs Multi-Repo: Pros and Cons. https://kinsta.com/blog/monorepo-vs-multi-repo/  
[^28]: Configuring GitHub Actions in a multi-directory repository structure. https://medium.com/@owumifestus/configuring-github-actions-in-a-multi-directory-repository-structure-c4d2b04e6312  
[^29]: Building a CI/CD Workflow with GitHub Actions - GitHub Resources. https://resources.github.com/learn/pathways/automation/essentials/building-a-workflow-with-github-actions/  
[^30]: Understanding GitHub Actions - GitHub Docs. https://docs.github.com/articles/getting-started-with-github-actions