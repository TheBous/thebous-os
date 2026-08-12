// thebous-os — OpenCode plugin.
//
// Discovers canonical skills and compatibility commands from this package.
// Skills are the source of truth; commands are thin prompt adapters.
// Self-locates via import.meta.url so paths work across hosts without symlinks.
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
      const skillsDir = path.resolve(__dirname, '..', '..', 'skills');
      try {
        for (const file of fs.readdirSync(commandDir).filter((f) => f.endsWith('.md'))) {
          const name = path.basename(file, '.md');
          const parsed = parseCommandFile(path.join(commandDir, file));
          if (parsed) config.command[name] = parsed;
        }
      } catch (e) {}

      config.skills = config.skills || {};
      config.skills.paths = config.skills.paths || [];
      if (!config.skills.paths.includes(skillsDir)) config.skills.paths.push(skillsDir);
    },
  };
};
