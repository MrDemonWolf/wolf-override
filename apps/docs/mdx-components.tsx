import defaultMdxComponents from 'fumadocs-ui/mdx';
import type { MDXComponents } from 'mdx/types';
import { Callout, Details, LinkCards, Screenshot, Summary } from '@/app/docs/guide-components';
import { CurrentVersion } from '@/app/docs/current-version';
import { AiDisclosure } from '@/app/docs/ai-disclosure';

const DefaultPre = defaultMdxComponents.pre;

export function getMDXComponents(components?: MDXComponents): MDXComponents {
  return {
    ...defaultMdxComponents,
    // Fumadocs 16.17 dropped shadow-sm from code blocks; keep the guide's code blocks as they were.
    pre: (props) => <DefaultPre {...props} className={['shadow-sm', props.className].filter(Boolean).join(' ')} />,
    AiDisclosure,
    // Fumadocs' Callout with a Markdown form for llms-full.txt and the .md copies (guide-components.tsx).
    Callout,
    CurrentVersion,
    Details,
    Summary,
    LinkCards,
    Screenshot,
    ...components,
  };
}
