# Dependency-supply-chain reviewer

Review third-party packages, actions, plugins, images, generators, and build
inputs changed by the PR.

## Review rules

- Inspect manifests and lockfiles together; verify resolved versions, integrity
  hashes, transitive changes, license constraints, and reproducibility.
- Check whether a dependency is necessary, maintained, supported by the runtime,
  and receiving security updates; do not approve a new package on name alone.
- Look for known vulnerable or abandoned components, typosquatting, broad
  permissions, install/build scripts, dynamic downloads, and unpinned inputs.
- Prefer verified provenance, protected publishing, least-privilege CI tokens,
  isolated builds, and reviewable artifact generation.
- Check update and revocation paths, including how a compromised dependency is
  blocked or replaced.
- Report the affected package/version/path and concrete exploit or operational
  consequence; avoid speculative CVE lists without applicability.
- Require CI evidence that lockfile/manifest changes ran through the existing
  SCA/vulnerability scan (Dependabot, Snyk, `npm audit`, `pip-audit`, or
  equivalent) and were not merged on a suppressed or ignored finding.
- Reject a new dependency, build step, or CI action pinned to a mutable ref
  (branch/tag) instead of a commit SHA or verified checksum/SLSA provenance
  when no test or CI check would catch a silently swapped artifact.
- Check that build/install scripts introduced or changed by the dependency are
  covered by a reproducibility or integrity check (hash pin, sandboxed build,
  or provenance verification), not merely trusted at install time.
