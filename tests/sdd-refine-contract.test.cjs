const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');

const root = path.resolve(__dirname, '..');
const skillPath = path.join(root, 'skills', 'sdd-refine', 'SKILL.md');
const commandPath = path.join(root, 'commands', 'sdd-refine.md');

function read(file) {
  return fs.readFileSync(file, 'utf8');
}

function body(file) {
  const source = read(file);
  const match = source.match(/^---\r?\n[\s\S]*?\r?\n---\r?\n([\s\S]*)$/);
  assert.ok(match, `${file} must have YAML frontmatter`);
  return match[1].trim();
}

test('sdd-refine has discovery-safe frontmatter', () => {
  const source = read(skillPath);
  const frontmatter = source.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n/);

  assert.ok(frontmatter, 'skill must have YAML frontmatter');
  assert.match(frontmatter[1], /^name:\s*sdd-refine$/m);
  assert.match(frontmatter[1], /^description:\s*Use when\b/m);
  assert.doesNotMatch(frontmatter[1], /creates|writes|asks|interviews|workflow/i);
});

test('sdd-refine defines the interview contract and approval gate', () => {
  const source = body(skillPath);

  for (const phrase of [
    'Fact',
    'Decision',
    'Assumption',
    'Unknown',
    '3-5',
    'mutually exclusive',
    'explicitly marked recommendation',
    'Out of Scope',
    'build-spec.md',
    'approve-build-spec changes/{CHG_ID}/build-spec.md',
    'cook-specify',
  ]) {
    assert.match(source, new RegExp(phrase.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i'));
  }

  assert.match(source, /Do not (write|create).*(code|test|plan|spec)/is);
  assert.match(source, /stop|block/is);
  assert.match(source, /after each round|wait.*answer/is);
  assert.match(source, /at most three rounds/i);
  assert.match(source, /after the third.*blocker/is);
  assert.match(source, /status to `Approved`/i);
});

test('sdd-refine has a thin command adapter', () => {
  const source = body(commandPath);

  assert.match(source, /skills\/sdd-refine\/SKILL\.md/);
  assert.ok(source.length < 400, 'command adapter must remain thin');
});

test('cook requires refinement before creating SDD artifacts', () => {
  const source = read(path.join(root, 'skills', 'cook', 'SKILL.md'));
  const refine = source.indexOf('sdd-refine');
  const artifacts = source.indexOf('spec.md');

  assert.notEqual(refine, -1, 'cook must invoke sdd-refine');
  assert.notEqual(artifacts, -1, 'cook must document SDD artifacts');
  assert.ok(refine < artifacts, 'refinement must precede SDD artifact creation');
});

test('cook-specify requires the approved build spec', () => {
  const source = read(path.join(root, 'skills', 'cook-specify', 'SKILL.md'));

  assert.match(source, /build-spec\.md/i);
  assert.match(source, /approve-build-spec changes\/\{CHG_ID\}\/build-spec\.md/i);
  assert.match(source, /before.*delta-spec|delta-spec.*after/is);
});

test('evals cover feature, bug, and pressure refinement scenarios', () => {
  const source = read(path.join(root, 'evals', 'evals.json5'));

  assert.match(source, /sdd-refine/);
  assert.match(source, /ambiguous feature|CSV export/i);
  assert.match(source, /login bug|logged out/i);
  assert.match(source, /do not ask|don't ask|urgency|pressure/i);
});
