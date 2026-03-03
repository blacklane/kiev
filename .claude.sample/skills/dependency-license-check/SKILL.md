---
name: dependency-license-check
description: Validates dependency licenses against Blacklane's Open Source Software Policy before adding any new library. Use when installing, adding, or upgrading dependencies in any language.
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
  - WebFetch
---

# Dependency & License Compliance

Ensure every dependency in the project complies with Blacklane's [Open Source Software Policy](https://blacklane.atlassian.net/wiki/spaces/PT/pages/5525078029). Write original code where possible; when a library is needed, verify it carries a permissive license before adding it.

## When to Use

**MANDATORY** — Always invoke this skill before:
- Adding any new dependency
- Upgrading an existing dependency to a new major version
- Any task that results in a new entry in a dependency file


**Language-specific install commands this covers:**
- `bundle add`, `gem install` — adds to `Gemfile`

**Always run this check first — then add the library.**

Also invoke this skill when:
- User asks to "check licenses", "audit dependencies", or "verify compliance" of existing libraries
- User asks to evaluate whether a specific library is allowed
- Reviewing a PR that introduces new dependencies

## Validation Workflow

1. **Identify the dependency** — Name, version, and language ecosystem
2. **Verify the license** — Confirm it is on the approved list (see `license-policy.md`)
3. **Determine usage context** — Production runtime vs dev/test/CI only (see `usage-detection.md`)
4. **Confirm compliance** — Match license + usage context against the policy matrix
5. **Report** — Tell the user the license, context, and compliance status

## Approved Licenses (use these freely)

**Any context:** MIT, Apache-2.0, BSD, ISC, MPL-2.0
**Dev/test/CI tooling only:** LGPL, GPL, AGPL (standalone binary/CLI only)

Libraries with unknown, missing, or custom licenses require a waiver — see `license-policy.md` for the full matrix and waiver process.

## Output

Report to the user:
- Dependency name and version
- Detected license
- Whether it's production or dev/test usage
- Compliant / Not compliant / Needs waiver
- If not compliant: suggest permissive-licensed alternatives or the waiver process

## Examples

```
User: "Add github.com/some/library to handle CSV parsing"

1. Verify license -> MIT (permissive)
2. Determine usage -> Production (imported in non-test Go files)
3. MIT + Production -> Compliant

github.com/some/library (MIT) is approved for production use.
```

```
User: "Add a GPL-licensed linter tool"

1. Verify license -> GPL-3.0
2. Determine usage -> Dev/CI only (standalone CLI binary)
3. GPL-3.0 + standalone dev tool -> Compliant

Approved as a standalone dev/CI tool (not compiled into the production binary).
```

```
User: "I need a library for X" (and it has a restrictive license)

1. Verify license -> AGPL-3.0
2. Determine usage -> Production (imported in Go service)
3. AGPL-3.0 + Production -> Not compliant

-> Suggest permissive alternatives for X, or write an original implementation.
-> If no alternative exists, direct user to the Legal service desk for a waiver.
```

## Code Originality

For complex logic (SQL queries, regex patterns, algorithms), prefer writing original implementations tailored to our domain. When referencing external patterns, ensure they come from permissive-licensed sources and adapt them to our codebase rather than copying verbatim.

## Supporting Files

- `license-policy.md` — Full license compatibility matrix, Wiz SBOM verification, and rules
- `usage-detection.md` — How to determine production vs dev/test usage per language
