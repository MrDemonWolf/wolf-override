# Security policy

WOLF//OVERRIDE is a source-only game and a static website. Neither runs a
server, takes accounts or sends data, so most reports will concern the
game's handling of its own save and settings files, the website build, or
the GitHub Actions workflows. Problems in Godot, GitHub Pages or other
third-party services belong with those projects.

## Supported versions

| Version                     | Supported                                  |
| --------------------------- | ------------------------------------------ |
| `main` branch               | Yes; fixes land here first                 |
| Packaged releases           | None exist yet; there is nothing to patch |
| Forks and local builds      | No                                         |

There are no tagged releases or installers. Running the game means running
the current `main` branch from source in Godot 4.7.2.

## Reporting a vulnerability

Please do not open a public issue or pull request for a security problem.

GitHub private vulnerability reporting is not enabled for this repository
(checked October 10, 2026). Until it is, contact Nathanial Henniges
privately through the public channels listed in the
[README](README.md#contact): a direct message on the
[Discord server](https://mrdwolf.net/discord), or the contact options on
[mrdemonwolf.com](https://www.mrdemonwolf.com). Say in the first line that
it is a security report and keep the details for the private reply. If
private vulnerability reporting is switched on later, the **Security** tab
on GitHub becomes the preferred route and this file will say so.

Include what you can of:

- the affected file or page and the commit you looked at;
- steps or a small proof of concept (a crafted `m0-save.json` or
  `settings.cfg`, a request, a build log);
- what an attacker could do with it;
- how you would like to be credited, if at all.

## What to expect

This is a one-person, part-time project with AI-assisted development, so
timelines are aims rather than guarantees:

- an acknowledgement within seven days;
- a fix on `main` when one is ready, with a plain-language note in the
  [changelog](https://wolfoverride.mrdemonwolf.dev/docs/changelog/) that
  leaves out exploit details until the fix has landed;
- credit in the changelog entry if you want it.

There is no bug bounty. Reports about the save and settings files are
welcome even when the only way to trigger the problem is editing those
files by hand; the game already rejects some damaged saves, and more
checks are useful.

## Scope notes

- The game makes no network requests; its only outward action opens the
  online changelog in your browser.
- The website stores only the guide's theme choice in your browser and
  loads no third-party scripts. See the
  [privacy page](https://wolfoverride.mrdemonwolf.dev/docs/privacy/).
- Dependency advisories for the docs site are handled by updating the
  pinned packages on `main`; a report that names a specific reachable
  problem is more useful than a bare advisory link.
