import defaultMdxComponents from 'fumadocs-ui/mdx';
import type { MDXComponents } from 'mdx/types';
import { LinkCards, Screenshot } from '@/app/docs/guide-components';

export function getMDXComponents(components?: MDXComponents): MDXComponents {
  return { ...defaultMdxComponents, LinkCards, Screenshot, ...components };
}
