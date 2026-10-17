import { repoUrl } from '@/lib/seo';

/**
 * The commit this build came from. The docs workflow (.github/workflows/docs.yml) passes
 * `NEXT_PUBLIC_COMMIT_SHA`; the bare `GITHUB_SHA` that every Actions job has is the fallback for a
 * workflow that forgets to. Undefined in a local build, which has no pushed commit to point at, so
 * the "built from" link is left out there.
 */
const commitSha = process.env.NEXT_PUBLIC_COMMIT_SHA ?? process.env.GITHUB_SHA;

// Footer links inherit the line's muted colour and stay underlined, so they read as links in both
// the landing page's dark palette and the guide's light and dark themes without a colour of their own.
const footerLink = 'underline underline-offset-[3px]';

/**
 * The site's copyright line, shared by the landing page footer and every guide page footer:
 * "© <year> WOLF OVERRIDE by MrDemonWolf, Inc.", plus " · built from <short commit>" when the
 * build knows its commit. Follows the footer of MrDemonWolf's WolfWave site. A server component:
 * the year and commit are read when the static export is built, not in the visitor's browser.
 * `className` styles the wrapping <p> (size and colour come from the page that places it).
 */
export default function SiteCopyright({ className }: { className?: string }) {
  const currentYear = new Date().getFullYear();
  return (
    <p className={className}>
      © {currentYear} WOLF OVERRIDE by{' '}
      <a href="https://www.mrdemonwolf.com" target="_blank" rel="noopener noreferrer" className={footerLink}>
        MrDemonWolf, Inc.
      </a>
      {commitSha ? (
        <>
          {' · built from '}
          <a href={`${repoUrl}/commit/${commitSha}`} target="_blank" rel="noopener noreferrer" className={`${footerLink} font-mono`}>
            {commitSha.slice(0, 7)}
          </a>
        </>
      ) : null}
    </p>
  );
}
