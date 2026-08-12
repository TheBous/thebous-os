const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
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
