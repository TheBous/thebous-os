const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const test = require('node:test');
const { parseCommandFile } = require('../.opencode/plugins/thebous-os-frontmatter.cjs');

const root = path.resolve(__dirname, '..');
const commandsDir = path.join(root, 'commands');
const skillsDir = path.join(root, 'skills');

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

test('explain-change defines the visual fallback and ce-explain preference', () => {
  const skill = fs.readFileSync(path.join(skillsDir, 'explain-change', 'SKILL.md'), 'utf8');
  assert.match(skill, /ce-explain/);
  assert.match(skill, /compound-engineering:ce-explain/);
  assert.match(skill, /HTML/i);
  assert.match(skill, /SVG|diagram/i);
  assert.match(skill, /business/i);
  assert.match(skill, /tecnic/i);
  assert.match(skill, /non.*wall of text|wall of text/i);
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
});
