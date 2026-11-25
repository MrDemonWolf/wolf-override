# Security policy

WOLF OVERRIDE has a Godot project and a static website. Report issues with
project code, the website build or the repository's GitHub Actions workflows
here. Report problems in Godot and other third-party services to those projects.

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
privately through a direct message on the
[Discord server](https://mrdwolf.net/discord), or the contact options on
[mrdemonwolf.com](https://www.mrdemonwolf.com). Say in the first line that
it is a security report and keep the details for the private reply. If
private vulnerability reporting is switched on later, the **Security** tab
on GitHub becomes the preferred route and this file will say so.

Include what you can of:

- the affected file or page and the commit you looked at;
- steps to observe the issue and any relevant logs;
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

There is no bug bounty.

## Scope notes

- The current Godot entry scene has no scripts.
- The website stores only the guide's theme choice in your browser and
  loads no third-party scripts. See the
  [privacy page](https://wolfoverride.mrdemonwolf.dev/docs/privacy/).
- Dependency advisories for the docs site are handled by updating the
  pinned packages on `main`; a report that names a specific reachable
  problem is more useful than a bare advisory link.
