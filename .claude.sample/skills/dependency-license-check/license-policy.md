# License Policy

All new dependencies must comply with Blacklane's [Open Source Software Policy](https://blacklane.atlassian.net/wiki/spaces/PT/pages/5525078029).

## Allowed Licenses (no approval needed)

| License | Production runtime | Dev / test / CI tooling |
|---|---|---|
| MIT, Apache-2.0, BSD, ISC | Yes | Yes |
| MPL-2.0 | Yes (don't modify MPL files) | Yes |

## Restricted Licenses

| License | Production runtime | Dev / test / CI tooling |
|---|---|---|
| LGPL-2.1 / LGPL-3.0 | **No** for compiled backends (Go, Rust, Java, Kotlin), mobile (Swift), bundled JS. Legacy only. | Yes (standalone binary/CLI only) |
| GPL-2.0 / GPL-3.0 | **No** — do not introduce new GPL runtime deps | Yes (standalone binary/CLI only) |
| AGPL-3.0 | **Hard no** | Yes (standalone internal CLI only) |
| Unknown / no license / custom | **Hard no** | **Hard no** |

## Key Rules

- **Production vs dev/test distinction matters.** GPL/LGPL/AGPL tools used as standalone executables in dev, CI, or tests (linters, compilers, CLIs) are fine. The same licenses are prohibited as linked runtime dependencies in shipped code.
- **No license = no permission.** Treat code with no LICENSE file as proprietary.
- If you need a restricted-license dependency, a waiver is required via the [Legal service desk](https://blacklane.atlassian.net/servicedesk/customer/portal/26). Inform your EM or Staff Engineer.
- Keep all LICENSE / NOTICE files when vendoring dependencies.
- When in doubt, ask before adding the dependency.

## How to Check a License

### Ruby
```bash
# Check via RubyGems
gem specification <gem_name> license
# Or check the gem's page on rubygems.org
# Or inspect the LICENSE file in the gem's GitHub repo
```

## Wiz License Verification (MANDATORY for new dependencies)

When adding any new dependency (direct or indirect), you **must** verify its license and the licenses of its transitive dependencies using the Wiz MCP SBOM tool before proceeding. CI/CD will block PRs that introduce restrictive-licensed production dependencies.

### Process for every new dependency

1. **Before installing**, query `mcp__wiz__list_sbom` with the package name to check its license and Wiz category.
2. **Check transitive dependencies too.** After adding the dependency, check the dependency lock file for any new transitive deps and query those as well. Restrictive-licensed transitive deps will also be flagged by CI/CD.
3. **Evaluate the Wiz license category:**
   - **Permissive** — safe to use, proceed.
   - **Semi-Permissive** (e.g., MPL-2.0) — allowed for production if MPL files are not modified. Proceed with caution.
   - **Restrictive** (e.g., GPL, AGPL, LGPL) — **block the install** unless the dependency is a standalone dev/CI tool (not compiled into the production binary). Inform the user that CI/CD will reject the PR.
   - **Unknown** — **block the install**. No license = no permission.
4. **If a restrictive-licensed dependency is detected:**
   - Stop the installation and revert the dependency change.
   - Inform the user which packages have restrictive licenses and why they are blocked.
   - Suggest permissive-licensed alternatives if known.
   - If a waiver is needed, direct the user to the [Legal service desk](https://blacklane.atlassian.net/servicedesk/customer/portal/26).

### Example Wiz SBOM check

```
mcp__wiz__list_sbom(name_filter: ["github.com/example/package"], limit: 10)
```
Look at the `licenses` array in the response — each license has an `id` (e.g., "MIT", "GPL-3.0-only") and `categories` with a category `id` ("permissive", "semi-permissive", or "restrictive").

**Note:** If the Wiz MCP server is unavailable, fall back to checking the license on the package's GitHub/source repository and apply the Allowed/Restricted license tables above manually.

## Wiz CI/CD Scanning

Wiz scans detect restrictive licenses in CI/CD. Two scan types exist:
- **PR scans** - Only scan changed files (diff-based). Will NOT catch pre-existing license issues.
- **Full repository scans** - Scan everything. Run via Wiz portal ("User Initiated").

If Wiz flags a dependency with a restrictive license (e.g., GPL-3.0-only), verify whether it's a production or dev/test dependency before taking action.
