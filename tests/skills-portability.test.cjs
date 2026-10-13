const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const test = require('node:test');

const root = path.resolve(__dirname, '..');
const skillsDir = path.join(root, 'skills');
const cursorPluginDir = path.join(root, '.cursor-plugin');

function readFrontmatter(file) {
  const source = fs.readFileSync(file, 'utf8');
  const match = source.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n/);
  assert.ok(match, `${file} must have YAML frontmatter`);
  return {
    name: match[1].match(/^name:\s*(.+)$/m)?.[1]?.trim(),
    description: match[1].match(/^description:\s*(.+)$/m)?.[1]?.trim(),
  };
}

const skillNames = fs.readdirSync(skillsDir)
  .filter((name) => fs.existsSync(path.join(skillsDir, name, 'SKILL.md')))
  .sort();

for (const name of skillNames) {
  test(`${name} has portable Agent Skills frontmatter`, () => {
    const file = path.join(skillsDir, name, 'SKILL.md');
    const metadata = readFrontmatter(file);
    assert.equal(metadata.name, name);
    assert.ok(metadata.description, 'description must be non-empty');
    assert.doesNotMatch(
      fs.readFileSync(file, 'utf8'),
      /CLAUDE_PLUGIN_ROOT|commands\/[a-z0-9-]+\.md/,
    );
  });
}

test('workflow entry points are skills', () => {
  assert.equal(fs.existsSync(path.join(root, 'commands')), false);
});

test('OpenCode registers canonical skills', () => {
  const source = fs.readFileSync(
    path.join(root, '.opencode/plugins/thebous-os.mjs'),
    'utf8',
  );
  assert.match(source, /config\.skills/);
  assert.match(source, /skillsDir/);
  assert.doesNotMatch(source, /commands/);
});

test('Cursor manifest exposes the canonical skills', () => {
  const manifest = JSON.parse(fs.readFileSync(path.join(cursorPluginDir, 'plugin.json'), 'utf8'));
  assert.equal(manifest.name, 'thebous-os');
  assert.equal(manifest.skills, './skills/');
  assert.equal(manifest.commands, undefined);
  assert.ok(fs.existsSync(path.join(root, manifest.skills, 'new-branch', 'SKILL.md')));
});

test('Cursor marketplace points at the repository plugin', () => {
  const marketplace = JSON.parse(
    fs.readFileSync(path.join(cursorPluginDir, 'marketplace.json'), 'utf8'),
  );
  assert.equal(marketplace.plugins.length, 1);
  assert.equal(marketplace.plugins[0].name, 'thebous-os');
  assert.equal(marketplace.plugins[0].source, '.');
});

test('Cursor README documents the UI GitHub import flow', () => {
  const readme = fs.readFileSync(path.join(root, 'README.md'), 'utf8');
  assert.match(readme, /\/add-plugin/);
  assert.match(readme, /Paste Link/);
  assert.doesNotMatch(readme, /\/add-plugin https:\/\/github\.com\/TheBous\/thebous-os/);
});

test('OpenCode setup uses the native skill invocation', () => {
  const readme = fs.readFileSync(path.join(root, '.opencode/README.md'), 'utf8');
  assert.match(readme, /@setup/);
  assert.doesNotMatch(readme, /^\/setup$/m);
});

test('manual install keeps repository support files', () => {
  const agents = fs.readFileSync(path.join(root, 'AGENTS.md'), 'utf8');
  assert.match(agents, /references\//);
  assert.match(agents, /scripts\//);
  assert.match(agents, /sibling skills/);
});

test('canonical skills and references do not depend on provider-specific paths', () => {
  const canonicalFiles = [
    ...fs.readdirSync(skillsDir)
      .map((name) => path.join(skillsDir, name, 'SKILL.md'))
      .filter((file) => fs.existsSync(file)),
    ...fs.readdirSync(path.join(root, 'references'))
      .map((name) => path.join(root, 'references', name))
      .filter((file) => file.endsWith('.md')),
  ];

  for (const file of canonicalFiles) {
    assert.doesNotMatch(
      fs.readFileSync(file, 'utf8'),
      /CLAUDE_PLUGIN_(DATA|ROOT)/,
      `${file} must use the provider-neutral data resolver`,
    );
  }
});

test('shared helper exposes a provider-neutral data directory override', () => {
  const helper = fs.readFileSync(path.join(root, 'scripts/helpers.sh'), 'utf8');
  assert.match(helper, /THEBOUS_OS_DATA_DIR=/);
  assert.match(helper, /ENV_FILE="\$THEBOUS_OS_DATA_DIR\/\.env"/);
});

test('version bump workflow keeps all manifests aligned', () => {
  const script = path.join(root, 'scripts/bump-version.cjs');
  const workflow = fs.readFileSync(path.join(root, '.github/workflows/bump-version.yml'), 'utf8');
  const check = spawnSync(process.execPath, ['--check', script], { encoding: 'utf8' });

  assert.equal(check.status, 0, check.stderr);
  assert.match(workflow, /branches:\s*[\r\n]+\s+- main/);
  assert.match(workflow, /node scripts\/bump-version\.cjs/);
  assert.match(workflow, /npm test/);
  assert.match(workflow, /contents: write/);

  const versions = [
    JSON.parse(fs.readFileSync(path.join(root, 'package.json'), 'utf8')).version,
    JSON.parse(fs.readFileSync(path.join(root, '.claude-plugin/plugin.json'), 'utf8')).version,
    JSON.parse(fs.readFileSync(path.join(root, '.claude-plugin/marketplace.json'), 'utf8')).version,
    JSON.parse(fs.readFileSync(path.join(root, '.claude-plugin/marketplace.json'), 'utf8')).plugins[0].version,
    JSON.parse(fs.readFileSync(path.join(root, '.codex-plugin/plugin.json'), 'utf8')).version,
    JSON.parse(fs.readFileSync(path.join(root, '.cursor-plugin/plugin.json'), 'utf8')).version,
  ];
  assert.equal(new Set(versions).size, 1);
});

test('create-jira-task always uses Markdown H2 description sections', () => {
  const skill = fs.readFileSync(path.join(skillsDir, 'create-jira-task', 'SKILL.md'), 'utf8');
  assert.match(skill, /## Descrizione/);
  assert.match(skill, /## Acceptance Criteria/);
  assert.doesNotMatch(skill, /^Descrizione\s*$/m);
  assert.doesNotMatch(skill, /^Acceptance Criteria\s*$/m);
});

test('core workflow skills declare their automatic trigger conditions', () => {
  const triggers = {
    'new-branch': /Use when.*(create|start|open).*branch/is,
    'create-pr': /Use when.*(create|open).*(PR|pull request).*merge|Use when.*merge.*branch/is,
  };

  for (const [name, pattern] of Object.entries(triggers)) {
    const metadata = readFrontmatter(path.join(skillsDir, name, 'SKILL.md'));
    assert.match(metadata.description, pattern, `${name} must describe its automatic trigger`);
  }

  const createPr = fs.readFileSync(path.join(skillsDir, 'create-pr', 'SKILL.md'), 'utf8');
  assert.match(createPr, /merge.*branch|existing pull request/i);
  assert.match(createPr, /skills\/merge-pr\/SKILL\.md/);
  assert.match(createPr, /PULL_REQUEST_TEMPLATE/);
  assert.match(createPr, /type>.*scope>.*concrete action and outcome/is);
  assert.match(createPr, /## Evidence/);
  assert.match(createPr, /Mermaid.*do not add Mermaid by default/is);
  assert.match(createPr, /<REQUIRED>` = `optional/);
  assert.doesNotMatch(createPr, /<REQUIRED>` = `required/);
});

test('this repository pre-fills PRs with the standard review template', () => {
  const template = fs.readFileSync(path.join(root, '.github', 'PULL_REQUEST_TEMPLATE.md'), 'utf8');
  assert.match(template, /^## Summary$/m);
  assert.match(template, /^## Why$/m);
  assert.match(template, /^## How to test$/m);
  assert.match(template, /^## Review focus$/m);
  assert.match(template, /^## Evidence$/m);
  assert.doesNotMatch(template, /Type of Change/);
});

test('address-review offers to request a new review after fixes', () => {
  const skill = fs.readFileSync(path.join(skillsDir, 'address-review', 'SKILL.md'), 'utf8');
  assert.match(skill, /Offer to request a new review/);
  assert.match(skill, /Do you want me to request a new review from <REVIEWER>/);
  assert.match(skill, /gh pr edit <NUMBER> --add-reviewer/);
  assert.match(skill, /already requested/i);
});

test('verify-resolved revalidates own review threads one by one', () => {
  const skill = fs.readFileSync(path.join(skillsDir, 'verify-resolved', 'SKILL.md'), 'utf8');
  assert.match(skill, /someone else's PR/i);
  assert.match(skill, /get-viewer-threads/);
  assert.match(skill, /Process one thread at a time/i);
  assert.match(skill, /Reply to every thread regardless of verdict/i);
  assert.match(skill, /Still needs attention:/);
  assert.match(skill, /## Verification report/);
  assert.match(skill, /### Coverage/);
  assert.match(skill, /### Verdict/);
  assert.match(skill, /### Residual risk/);
  assert.doesNotMatch(skill, /skills\/verify-resolved\/scripts/);
});

test('verify-resolved requires fresh evidence before assigning a verdict', () => {
  const skill = fs.readFileSync(path.join(skillsDir, 'verify-resolved', 'SKILL.md'), 'utf8');
  const contract = fs.readFileSync(
    path.join(root, 'references', 'review-evidence-contract.md'),
    'utf8',
  );

  assert.match(skill, /references\/review-evidence-contract\.md/);
  assert.match(skill, /fixed.*current-code evidence/is);
  assert.match(skill, /partial.*not-fixed.*concrete remaining gap/is);
  assert.match(skill, /needs-look.*not a defect/is);
  assert.match(contract, /current-code anchor/i);
  assert.match(contract, /author.*reply.*not.*evidence|reply alone.*evidence/is);
  assert.match(contract, /try to falsify|falsif/i);
  assert.match(contract, /missing.*evidence.*needs-look/is);
  assert.match(contract, /uncertainty.*defect|not.*proof/i);
});

test('review workflows share one evidence contract reference', () => {
  const referencePath = path.join(root, 'references', 'review-evidence-contract.md');
  assert.equal(fs.existsSync(referencePath), true);

  const reference = fs.readFileSync(referencePath, 'utf8');
  assert.match(reference, /current-code anchor/i);
  assert.match(reference, /preconditions/i);
  assert.match(reference, /execution[_ ]path/i);
  assert.match(reference, /absence of .*evidence.*not.*proof/is);
  assert.match(reference, /try to falsify|falsif/i);

  for (const name of ['review-pr-multiharness', 'verify-resolved']) {
    const skill = fs.readFileSync(path.join(skillsDir, name, 'SKILL.md'), 'utf8');
    assert.match(skill, /references\/review-evidence-contract\.md/);
  }

  const multiharness = fs.readFileSync(
    path.join(skillsDir, 'review-pr-multiharness', 'SKILL.md'),
    'utf8',
  );
  const verifyResolved = fs.readFileSync(
    path.join(skillsDir, 'verify-resolved', 'SKILL.md'),
    'utf8',
  );
  assert.doesNotMatch(multiharness, /Before a candidate becomes a finding/);
  assert.doesNotMatch(verifyResolved, /Record these fields for every thread/);
});

test('standard review workflow is removed while multiharness variants remain', () => {
  assert.equal(fs.existsSync(path.join(skillsDir, 'review-pr', 'SKILL.md')), false);
  assert.equal(fs.existsSync(path.join(skillsDir, 'review-pr-multiharness', 'SKILL.md')), true);
  assert.equal(fs.existsSync(path.join(skillsDir, 'review-pr-multiharness-ponytail', 'SKILL.md')), true);
});

test('multiharness review gates findings on evidence instead of uncertainty', () => {
  const skill = fs.readFileSync(
    path.join(skillsDir, 'review-pr-multiharness', 'SKILL.md'),
    'utf8',
  );
  const contract = fs.readFileSync(
    path.join(root, 'references', 'review-evidence-contract.md'),
    'utf8',
  );

  assert.match(skill, /references\/review-evidence-contract\.md/);
  assert.match(skill, /confirmed/i);
  assert.match(skill, /coverage-gap/i);
  assert.match(skill, /preconditions/i);
  assert.match(skill, /execution[_ ]path/i);
  assert.match(skill, /reproduc|failing[_ ]test/i);
  assert.match(contract, /exact changed-line anchor/i);
  assert.match(contract, /absence of .*evidence.*not.*proof|missing .*safeguard.*not.*evidence/is);
  assert.match(contract, /try to falsify|falsif/i);
});

test('review-pr-multiharness-ponytail follows the parent workflow and always runs ponytail', () => {
  const skill = fs.readFileSync(
    path.join(skillsDir, 'review-pr-multiharness-ponytail', 'SKILL.md'),
    'utf8',
  );
  const prompt = fs.readFileSync(
    path.join(skillsDir, 'review-pr-multiharness-ponytail', 'references', 'reviewer-prompts', 'ponytail.md'),
    'utf8',
  );

  assert.match(skill, /skills\/review-pr-multiharness\/SKILL\.md/);
  assert.doesNotMatch(skill, /danger_score = sum/);
  assert.match(skill, /always run `correctness` and `ponytail`/i);
  assert.match(skill, /never[\s\S]*coalesce[\s\S]*maintainability/i);
  assert.match(skill, /Minimum roster size is 2/);
  assert.match(skill, /occupies one of the parent/);
  assert.match(skill, /1→2|1->2/);
  assert.match(skill, /Lean already\. Ship\./);
  assert.match(skill, /net: -<N> lines possible/);
  for (const tag of ['delete:', 'stdlib:', 'native:', 'yagni:', 'shrink:']) {
    assert.match(skill, new RegExp(tag));
    assert.match(prompt, new RegExp(tag));
  }
  assert.doesNotMatch(skill, /haiku|sonnet|gpt-\d|claude/i);
  assert.match(prompt, /over-engineering|complexity only/i);
  assert.match(prompt, /out of scope/i);
  assert.match(prompt, /ponytail-core\.md/);
  assert.match(prompt, /platform-native\.md/);
  assert.match(prompt, /EmailValidator|Intl\.DateTimeFormat|AbstractRepository/);

  const core = fs.readFileSync(
    path.join(skillsDir, 'review-pr-multiharness-ponytail', 'references', 'ponytail-core.md'),
    'utf8',
  );
  const native = fs.readFileSync(
    path.join(skillsDir, 'review-pr-multiharness-ponytail', 'references', 'platform-native.md'),
    'utf8',
  );
  assert.match(skill, /ponytail-core\.md/);
  assert.match(skill, /platform-native\.md/);
  assert.match(core, /Does this need to exist at all/);
  assert.match(core, /When NOT to flag/);
  assert.match(core, /ponytail:/);
  assert.match(native, /structuredClone|Intl\.DateTimeFormat|fs\.mkdirSync/);
});
