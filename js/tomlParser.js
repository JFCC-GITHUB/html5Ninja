// ==========================================
// LIGHTWEIGHT TOML PARSER FOR BROWSER
// ==========================================

export function parseTOML(tomlText) {
  const result = {};
  let currentSection = result;

  const lines = tomlText.split(/\r?\n/);
  for (let line of lines) {
    line = line.trim();
    if (!line || line.startsWith('#')) continue;

    // Check table section e.g. [player] or [difficulties.GOD]
    if (line.startsWith('[') && line.endsWith(']')) {
      const sectionPath = line.slice(1, -1).trim().split('.');
      currentSection = result;
      for (const key of sectionPath) {
        if (!currentSection[key]) {
          currentSection[key] = {};
        }
        currentSection = currentSection[key];
      }
      continue;
    }

    // Key-value pair
    const eqIdx = line.indexOf('=');
    if (eqIdx !== -1) {
      const rawKey = line.slice(0, eqIdx).trim();
      const rawVal = line.slice(eqIdx + 1).trim();

      let val = rawVal;
      if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) {
        val = val.slice(1, -1);
      } else if (val === 'true') {
        val = true;
      } else if (val === 'false') {
        val = false;
      } else if (!isNaN(Number(val))) {
        val = Number(val);
      }

      currentSection[rawKey] = val;
    }
  }

  return result;
}
