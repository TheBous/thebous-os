// thebous-os — OpenCode plugin.
//
// Discovers and registers commands from commands/*.md — the single unified
// command directory for the whole thebous-os plugin (git/Jira/Slack/Confluence
// workflow, morning briefing, end-of-day recap). Self-locates via
// import.meta.url so paths work across hosts without symlinks.
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

export default async ({ client } = {}) => {
  return {
    config: async (config) => {
      if (!config.command) config.command = {};
      const commandDir = path.join(__dirname, '..', '..', 'commands');
      try {
        for (const file of fs.readdirSync(commandDir).filter((f) => f.endsWith('.md'))) {
          const name = path.basename(file, '.md');
          const parsed = parseCommandFile(path.join(commandDir, file));
          if (parsed) config.command[name] = parsed;
        }
      } catch (e) {}
    },
  };
};
