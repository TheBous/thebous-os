// thebous-os — OpenCode plugin.
//
// Registers the canonical skills/ directory with OpenCode.
// Self-locates via import.meta.url so paths work across hosts without symlinks.
//
// Add to opencode.json:
//   { "plugin": ["./thebous-os/.opencode/plugins/thebous-os.mjs"] }

import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

export default async () => {
  return {
    config: async (config) => {
      const skillsDir = path.resolve(__dirname, '..', '..', 'skills');
      config.skills = config.skills || {};
      config.skills.paths = config.skills.paths || [];
      if (!config.skills.paths.includes(skillsDir)) config.skills.paths.push(skillsDir);
    },
  };
};
