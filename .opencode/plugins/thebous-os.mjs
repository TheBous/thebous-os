// thebous-os — OpenCode plugin.
//
// Dynamically discovers and registers commands from all three skill subdirectories:
// - commands/ (thebous-jira-git-sync)
// - morning-briefing/commands/
// - end-of-day/commands/
//
// Self-locating via import.meta.url so paths work across hosts without symlinks.
//
// Add to opencode.json:
//   { "plugin": ["./thebous-os/.opencode/plugins/thebous-os.mjs"] }

import { createRequire } from 'module';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const require = createRequire(import.meta.url);
const { parseCommandFile } = require('./thebous-os-frontmatter.cjs');

function registerCommandsFromDir(config, dirPath, prefix = '') {
  try {
    for (const file of fs.readdirSync(dirPath).filter((f) => f.endsWith('.md'))) {
      const name = prefix ? `${prefix}-${path.basename(file, '.md')}` : path.basename(file, '.md');
      const parsed = parseCommandFile(path.join(dirPath, file));
      if (parsed) config.command[name] = parsed;
    }
  } catch (e) {
    // Silently skip missing directories
  }
}

export default async ({ client } = {}) => {
  return {
    config: async (config) => {
      if (!config.command) config.command = {};
      const repoRoot = path.join(__dirname, '..', '..');

      // thebous-jira-git-sync commands (main commands/ directory)
      registerCommandsFromDir(config, path.join(repoRoot, 'commands'));

      // morning-briefing commands
      registerCommandsFromDir(config, path.join(repoRoot, 'morning-briefing', 'commands'), 'morning-briefing');

      // end-of-day commands
      registerCommandsFromDir(config, path.join(repoRoot, 'end-of-day', 'commands'), 'end-of-day');
    },
  };
};
