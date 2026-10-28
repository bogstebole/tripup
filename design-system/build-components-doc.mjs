// Builds design-system/COMPONENTS.md, the index of TripUp's Figma components, from design-system/components.json.
// Usage: node design-system/build-components-doc.mjs
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const d = JSON.parse(readFileSync(join(root, 'design-system/components.json'), 'utf8'));
const link = id => `${d.file}?node-id=${id.replace(':', '-')}`;
const count = d.categories.reduce((n, c) => n + c.components.length, 0);

const out = [
  '# TripUp components',
  '',
  `Generated from design-system/components.json by design-system/build-components-doc.mjs. Don't edit by hand.`,
  '',
  `Every component the Figma screens are built from: ${count} entries on the page Components (${link(d.page)}), one section each.`,
  'The Flutter app (app/lib) is the source of truth; each component is drawn 1:1 from its widget.',
  '',
  '## How to read it',
  '',
  '- Name: the component\'s name in Figma, also the name of its section and its docs card.',
  '- Figma: node id, component key, and the property API exactly as Figma has it (`Name=value|value` for variants; text, boolean and instance swap properties in brackets).',
  '- Props: how the Figma properties map to the code\'s parameters (`Kind → kind`).',
  '- Code: the widget and its file. Swift for the Live Activity and the notification.',
  '- Tokens: every colour, size and space is a variable made from design-system/tokens.json; in Figma its code syntax is the CSS variable (`var(--color-bg-muted)`), the same token as TokColors and TokSpace in Dart. Components use semantic tokens; a component token (TokDim) exists only when it is derived (concentric corners), shared by several components, or shared with the Live Activity. The tokens each component uses are listed in its Figma description.',
  '- Screens are instances of these components: change the component, never a copy on a screen.',
  '',
  '## Index',
  '',
];
for (const c of d.categories) out.push(`- ${c.name}: ${c.components.map(x => x.name).join(', ')}`);
for (const c of d.categories) {
  out.push('', `## ${c.name}`, '', c.about);
  for (const x of c.components) {
    out.push('', `### ${x.name}`, '', x.what, '');
    if (x.use) out.push(`- Use: ${x.use}`);
    if (x.avoid) out.push(`- Avoid: ${x.avoid}`);
    if (x.props) out.push(`- Props: ${x.props}`);
    if (x.code) out.push(`- Code: ${x.code}`);
    if (x.story) out.push(`- Storybook: ${x.story}`);
    const figma = [`node ${x.id}`, x.key && `key ${x.key}`, x.figmaProps && `properties: ${x.figmaProps}`].filter(Boolean).join(' · ');
    out.push(`- Figma: ${figma} (${link(x.section)})`);
  }
}
writeFileSync(join(root, 'design-system/COMPONENTS.md'), out.join('\n') + '\n');
console.log(`wrote design-system/COMPONENTS.md (${count} components)`);
