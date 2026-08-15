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
