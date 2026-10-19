import { aiDisclosure } from '@/lib/press-kit';

/**
 * The approved AI disclosure as one paragraph, for MDX pages (`<AiDisclosure />`, registered in
 * mdx-components.tsx). The words come from lib/press-kit.ts `aiDisclosure`, their one home on the site,
 * so a page never carries its own copy. A server component: no client JavaScript.
 */
export function AiDisclosure() {
  return <p>{aiDisclosure}</p>;
}
