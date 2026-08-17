#!/usr/bin/env node

const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(__dirname, '..');
const manifestPaths = [
  'package.json',
  '.claude-plugin/plugin.json',
  '.claude-plugin/marketplace.json',
  '.codex-plugin/plugin.json',
  '.cursor-plugin/plugin.json',
];

function readJson(relativePath) {
  const file = path.join(root, relativePath);
  return {
    file,
    data: JSON.parse(fs.readFileSync(file, 'utf8')),
  };
}

function getVersions(manifest) {
  const versions = [];
  if (manifest.data.version) versions.push(manifest.data.version);
  for (const plugin of manifest.data.plugins || []) {
    if (plugin.version) versions.push(plugin.version);
  }
  return versions;
}

const manifests = manifestPaths.map(readJson);
const versions = manifests.flatMap(getVersions);
const distinctVersions = [...new Set(versions)];

if (distinctVersions.length !== 1) {
  throw new Error(`Manifest versions are inconsistent: ${distinctVersions.join(', ')}`);
}

const currentVersion = distinctVersions[0];
const match = currentVersion.match(/^(\d+)\.(\d+)\.(\d+)$/);
if (!match) throw new Error(`Unsupported version: ${currentVersion}`);

const nextVersion = `${match[1]}.${match[2]}.${Number(match[3]) + 1}`;

for (const manifest of manifests) {
  manifest.data.version = nextVersion;
  for (const plugin of manifest.data.plugins || []) plugin.version = nextVersion;
  fs.writeFileSync(manifest.file, `${JSON.stringify(manifest.data, null, 2)}\n`);
}

console.log(`${currentVersion} -> ${nextVersion}`);
