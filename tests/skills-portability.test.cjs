const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const test = require('node:test');
const { parseCommandFile } = require('../.opencode/plugins/thebous-os-frontmatter.cjs');

const root = path.resolve(__dirname, '..');
const commandsDir = path.join(root, 'commands');
const skillsDir = path.join(root, 'skills');
const cursorPluginDir = path.join(root, '.cursor-plugin');

function readBody(file) {
  const source = fs.readFileSync(file, 'utf8');
  const match = source.match(/^---\r?\n[\s\S]*?\r?\n---\r?\n([\s\S]*)$/);
  assert.ok(match, `${file} must have YAML frontmatter`);
  return match[1].trim();
}

function readFrontmatter(file) {
  const source = fs.readFileSync(file, 'utf8');
  const match = source.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n/);
  assert.ok(match, `${file} must have YAML frontmatter`);
  return {
    name: match[1].match(/^name:\s*(.+)$/m)?.[1]?.trim(),
    description: match[1].match(/^description:\s*(.+)$/m)?.[1]?.trim(),
  };
}

const workflowNames = fs.readdirSync(commandsDir)
  .filter((file) => file.endsWith('.md'))
  .map((file) => file.slice(0, -'.md'.length))
  .sort();

const skillNames = fs.readdirSync(skillsDir)
  .filter((name) => fs.existsSync(path.join(skillsDir, name, 'SKILL.md')))
  .sort();

for (const name of skillNames) {
  test(`${name} has portable Agent Skills frontmatter`, () => {
    const metadata = readFrontmatter(path.join(skillsDir, name, 'SKILL.md'));
    assert.equal(metadata.name, name);
    assert.ok(metadata.description, 'description must be non-empty');
  });
}

for (const name of workflowNames) {
  test(`${name} has a canonical skill and a thin command adapter`, () => {
    const skillFile = path.join(skillsDir, name, 'SKILL.md');
    const commandFile = path.join(commandsDir, `${name}.md`);
    assert.ok(fs.existsSync(skillFile), `missing ${skillFile}`);

    const skillBody = readBody(skillFile);
    const commandBody = readBody(commandFile);

    assert.ok(skillBody.length >= 500, `${skillFile} must contain the workflow instructions`);
    assert.doesNotMatch(skillBody, /CLAUDE_PLUGIN_ROOT|commands\/[a-z0-9-]+\.md/);
    assert.match(commandBody, new RegExp(`skills/${name}/SKILL\\.md`));
    assert.ok(commandBody.length < 400, `${commandFile} must remain a thin adapter`);
  });
}

test('OpenCode registers canonical skills in addition to commands', () => {
  const source = fs.readFileSync(
    path.join(root, '.opencode/plugins/thebous-os.mjs'),
    'utf8',
  );
  assert.match(source, /config\.skills/);
  assert.match(source, /skillsDir/);
});

test('OpenCode can parse every command adapter', () => {
  for (const name of workflowNames) {
    const parsed = parseCommandFile(path.join(commandsDir, `${name}.md`));
    assert.ok(parsed?.description, `${name} is missing a command description`);
    assert.match(parsed.template, new RegExp(`skills/${name}/SKILL\\.md`));
  }
});

test('Cursor manifest exposes the canonical skills and command adapters', () => {
  const manifest = JSON.parse(fs.readFileSync(path.join(cursorPluginDir, 'plugin.json'), 'utf8'));
  assert.equal(manifest.name, 'thebous-os');
  assert.equal(manifest.skills, './skills/');
  assert.equal(manifest.commands, './commands/');
  assert.ok(fs.existsSync(path.join(root, manifest.skills, 'cook', 'SKILL.md')));
  assert.ok(fs.existsSync(path.join(root, manifest.commands, 'cook.md')));
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

test('explain-change defines a provider-neutral visual workflow', () => {
  const skill = fs.readFileSync(path.join(skillsDir, 'explain-change', 'SKILL.md'), 'utf8');
  assert.doesNotMatch(skill, /ce-explain|compound-engineering/i);
  assert.match(skill, /HTML/i);
  assert.match(skill, /SVG|diagram/i);
  assert.match(skill, /business/i);
  assert.match(skill, /technical/i);
  assert.match(skill, /non.*wall of text|wall of text/i);
  assert.match(skill, /OBSIDIAN_VAULT_PATH/);
  assert.match(skill, /obsidian_ticket_docs_dir|obsidian_copy_ticket_docs/);
  assert.match(skill, /docs\/explain-change/);
  assert.match(skill, /guiding question/i);
  assert.match(skill, /Evidence.*Inference.*Unverified/s);
  assert.match(skill, /output.*function.*transformation.*data source.*input/i);
  assert.match(skill, /counterexample/i);
  assert.match(skill, /Final check/i);
});

test('cook asks before pulling Granola and saves a selected meeting as a ticket page', () => {
  const cook = fs.readFileSync(path.join(skillsDir, 'cook', 'SKILL.md'), 'utf8');
  assert.match(cook, /prima di iniziare|before.*coding|before.*implement/i);
  assert.match(cook, /Granola/i);
  assert.match(cook, /explicit|esplicita|conferma|ask which meeting/i);
  assert.match(cook, /non.*auto|never.*auto|mai.*auto/i);
  assert.match(cook, /Dev\/Tickets|Tickets/);
  assert.match(cook, /include=transcript/);
  assert.match(cook, /granola-<GRANOLA_ID>\.md/);
  assert.match(cook, /granola_id.*title.*created_at.*updated_at.*granola_url.*imported_at/s);
  assert.match(cook, /\.md/);
  assert.match(cook, /300 lines of code|300 righe di codice/i);
  assert.match(cook, /PR stack/i);
  assert.match(cook, /git diff --numstat/);
  assert.match(cook, /Do not assume|non.*assum/i);
});

test('cook initializes provider-neutral SDD artifacts before development', () => {
  const cook = fs.readFileSync(path.join(skillsDir, 'cook', 'SKILL.md'), 'utf8');
  assert.match(cook, /direct Jira relationships|linked issues|parent story/i);
  assert.match(cook, /Do not show the user the ticket title or description/i);
  assert.match(cook, /Tickets\/DC-<TASK_ID>\/spec\.md/);
  assert.match(cook, /Tickets\/DC-<TASK_ID>\/plan\.md/);
  assert.match(cook, /Tickets\/DC-<TASK_ID>\/tasks\.md/);
  assert.match(cook, /implementation-direction\.html/);
  assert.match(cook, /Before changing source or test code/i);
  assert.match(cook, /each delegated action.*tasks\.md/is);
});

test('current-status covers the current-day multi-source snapshot', () => {
  const skill = fs.readFileSync(path.join(skillsDir, 'current-status', 'SKILL.md'), 'utf8');
  assert.match(skill, /current situation|situazione.*giornata/i);
  assert.match(skill, /GitHub/);
  assert.match(skill, /Jira/);
  assert.match(skill, /Confluence/);
  assert.match(skill, /Calendar|calendario/i);
  assert.match(skill, /Granola/);
  assert.match(skill, /non committati|uncommitted/i);
  assert.match(skill, /HTML/i);
  assert.match(skill, /read-only|read-only/i);
  assert.match(skill, /obsidian_copy_daily_artifact/);
  assert.match(skill, /30 - Current Status\.md/);
  assert.match(skill, /append_daily_note\.sh/);
});

test('core workflow skills declare their automatic trigger conditions', () => {
  const triggers = {
    cook: /Use when.*(develop|implement|plan).*(feature|fix)|Use when.*(feature|fix).*(develop|implement|plan)/is,
    'new-branch': /Use when.*(create|start|open).*branch/is,
    'create-pr': /Use when.*(create|open).*(PR|pull request).*merge|Use when.*merge.*branch/is,
    'review-pr': /Use when.*review.*(PR|pull request)/is,
  };

  for (const [name, pattern] of Object.entries(triggers)) {
    const metadata = readFrontmatter(path.join(skillsDir, name, 'SKILL.md'));
    assert.match(metadata.description, pattern, `${name} must describe its automatic trigger`);
  }

  const createPr = fs.readFileSync(path.join(skillsDir, 'create-pr', 'SKILL.md'), 'utf8');
  assert.match(createPr, /merge.*branch|existing pull request/i);
  assert.match(createPr, /skills\/merge-pr\/SKILL\.md/);
  assert.match(createPr, /PULL_REQUEST_TEMPLATE/);
  assert.match(createPr, /## Summary/);
  assert.match(createPr, /## Test plan/);
  assert.match(createPr, /<REQUIRED>` = `optional/);
  assert.doesNotMatch(createPr, /<REQUIRED>` = `required/);
});

test('this repository pre-fills PRs with GitHub Summary / Test plan', () => {
  const template = fs.readFileSync(path.join(root, '.github', 'PULL_REQUEST_TEMPLATE.md'), 'utf8');
  assert.match(template, /^## Summary$/m);
  assert.match(template, /^## Test plan$/m);
  assert.doesNotMatch(template, /Type of Change/);
});

test('review-pr runs a fast walkthrough subagent and saves its HTML in the ticket review folder', () => {
  const review = fs.readFileSync(path.join(skillsDir, 'review-pr', 'SKILL.md'), 'utf8');
  assert.match(review, /in parallel/i);
  assert.match(review, /fast subagent/i);
  assert.match(review, /fastest low-cost model/i);
  assert.doesNotMatch(review, /haiku|sonnet|gpt-\d|claude/i);
  assert.match(review, /Dev\/Review\/DC-<TASK_ID>/);
  assert.match(review, /index\.html/);
  assert.match(review, /self-contained/i);
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
