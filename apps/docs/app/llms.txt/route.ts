import { docsLlms } from '@/lib/source';
import { siteDescription, siteUrl } from '@/lib/seo';

// A static export only prerenders route handlers marked force-static (Next static-exports guide).
export const dynamic = 'force-static';

/**
 * /llms.txt in the llmstxt.org layout: the project name as H1, a `>` summary, a short note, then
 * the guide tree as an H2 link list and an `## Optional` section. Fumadocs' index() starts with the
 * page-tree root ("# Game guide") and links relative paths without the trailing slash the site
 * uses, so its first line is replaced and its links made absolute.
 */
export async function GET() {
  const tree = (await docsLlms.index())
    .split('\n')
    .slice(1)
    .join('\n')
    .replace(/\]\(\/docs([^)]*)\)/g, (_, path: string) => `](${siteUrl}/docs${path}/)`);
  const body =
    `# WOLF//OVERRIDE\n\n> ${siteDescription}\n\n` +
    `Spoiler-light player guide; walkthrough pages label their spoilers. Every page in full, as Markdown: ${siteUrl}/llms-full.txt\n\n` +
    `## Game guide\n${tree}\n\n` +
    `## Optional\n\n- [Source code](https://github.com/MrDemonWolf/wolf-override): the Godot project and this website (GPL-3.0-or-later code; art and branding have their own terms)\n`;
  return new Response(body, { headers: { 'Content-Type': 'text/plain; charset=utf-8' } });
}
