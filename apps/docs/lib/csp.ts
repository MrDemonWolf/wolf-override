/**
 * The site's Content-Security-Policy, written into every page as `<meta http-equiv>` by
 * app/layout.tsx. GitHub Pages cannot send response headers, so the meta tag is the only way to
 * set one (Codex review, next.config.mjs:4). A meta policy cannot carry frame-ancestors,
 * report-uri or sandbox; browsers ignore those there, so they are left out.
 *
 * Every resource the export loads comes from the site itself: scripts and styles under /_next,
 * the WOFF2 fonts, images, the search index (/api/search.json) and the Markdown copies the page's
 * "Copy Markdown" button fetches. Outside links (GitHub, the publisher's profiles, ChatGPT and
 * Claude in the page menu) are plain navigations, which CSP does not limit.
 *
 * Two allowances are needed:
 * - script-src 'unsafe-inline': the static export writes inline scripts on every page (Next's
 *   `self.__next_f` page data and next-themes' theme script). A static site cannot hand out a
 *   per-request nonce, and the inline scripts change with every build and page, so hashes would
 *   need a post-build rewrite of every file.
 * - style-src 'unsafe-inline': React writes `style` attributes (such as Fumadocs' callout
 *   colour) into the HTML, which a policy without it blocks.
 *
 * `next dev` also needs eval for React's debugging and a WebSocket for hot reload, so
 * {@link contentSecurityPolicy} adds those only when `dev` is true.
 */
const directives: Record<string, string[]> = {
  'default-src': ["'self'"],
  'script-src': ["'self'", "'unsafe-inline'"],
  'style-src': ["'self'", "'unsafe-inline'"],
  'img-src': ["'self'"],
  'font-src': ["'self'"],
  'connect-src': ["'self'"],
  'object-src': ["'none'"],
  'base-uri': ["'self'"],
  'form-action': ["'self'"],
};

/**
 * The policy as one `content` string, such as `default-src 'self'; script-src ...`.
 * `dev` (true under `next dev`) adds 'unsafe-eval' to script-src and ws: to connect-src.
 */
export function contentSecurityPolicy(dev = false): string {
  return Object.entries(directives)
    .map(([name, sources]) => {
      const extra = !dev ? [] : name === 'script-src' ? ["'unsafe-eval'"] : name === 'connect-src' ? ['ws:'] : [];
      return [name, ...sources, ...extra].join(' ');
    })
    .join('; ');
}
