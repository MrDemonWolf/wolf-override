import { asMarkdown } from 'fumadocs-core/server';
import { aiDisclosure } from '@/lib/press-kit';

/**
 * The approved AI disclosure as one paragraph, for MDX pages (`<AiDisclosure />`, registered in
 * mdx-components.tsx). The words come from lib/press-kit.ts `aiDisclosure`, their one home on the site,
 * so a page never carries its own copy. A server component: no client JavaScript. In the Markdown
 * copies (llms.txt, llms-full.txt, each page's .md; see lib/source.ts) asMarkdown() is true and it
 * returns the plain paragraph, so those copies carry the text instead of a bare component tag.
 */
export function AiDisclosure() {
  if (asMarkdown()) return `${aiDisclosure}\n\n`;
  return <p>{aiDisclosure}</p>;
}
