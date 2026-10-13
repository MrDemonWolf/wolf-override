# Full review, presentation research and Blowback build records (October 6 to 9, 2026)

Machine-readable records of three pieces of review work. They are the evidence behind several merged pull requests and are kept as JSON exactly as the agents wrote them, with personal paths rewritten as repository-relative paths or "[session scratch, not kept]".

## The work

- **Full review, October 6 and 7.** A full review of the repository with the installed review skills (UI and UX, frontend design, accessibility, code review, security, legal, web performance, mobile UI) plus rendered evidence: site captures, Godot stills at four resolutions and an Android emulator touch run. Result: 125 issues, 17 P0 and 17 P1 (game 52, site 49, platform 24). They were fixed in PR #31 (phase 0 and 1), PRs #38 and #39 (phase 2), PR #40 (site phase 3) and later passes. Decisions Nathanial made while it was fixed (recorded in [`../notion/`](../notion/)): the relay rework (after disclosing, WOLF walks to the contact himself; the manual bypass stays), the N and L/F9 hotkeys removed and I kept, a dark-only landing page, labels in Montserrat, and the docs site mostly on Tailwind (October 7).
- **Presentation research, October 8.** Research into 2.5D presentation (Godot's 2D rendering and parallax, how shipped games build depth and menus, and the project's own assets), followed by two implementation passes on `codex/game-presentation` with an independent verification of each: the UI theme pass (097e4db, verdict "fix-needed", then fixed) and the depth pass (98106cb, "pass"). The picks shown to Nathanial are on [`../review-pages/2026-10-08-look-picks.md`](../review-pages/2026-10-08-look-picks.md); they shipped in PR #42.
- **Blowback implement and verify, October 9.** The build record of the Service Junction "Blowback" action slice (design in `../../data/blowback-spec.md` and `../../data/action-design.json`): each step (follow-ups, foundation, Blowback beats, fixes, beats 4 to 6, zoom, art, docs) was implemented by one agent and checked by another from rendered stills, with commit, summary, checks, stills, open issues, verdict and defects for each. Run 1 stopped after the first Blowback step needed fixes; run 2 continued from there. It landed in PR #42 (Service Junction action room, impact kit, procedural sound, knockdown, zoom 1.35, layered room art).

These records judge from code, tests and still renders. Hands-on play of the routes was not done at the time, as the records themselves state.

## Files

- `2026-10-06-full-review-issues.json`: the 125 issues by area, each with priority, severity, status, sources, files, problem, fix, reuse, effort and dependencies, plus strengths, items not verified and dropped findings.
- `2026-10-06-full-review-dimensions.json`: per-dimension findings, strengths and what could not be verified (game correctness, in-game copy and story rules, assets and legal, site code, site CSS and design, site SEO and performance).
- `2026-10-08-presentation-research.json`: the three research briefs (Godot, shipped-game references, project assets) with findings, techniques and sources, and the two implement-and-verify results.
- `2026-10-09-blowback-implement-verify-run1.json`, `2026-10-09-blowback-implement-verify-run2.json`: the Blowback build records.

## Credits

- Game, story, characters and every decision: Nathanial Henniges.
- Reviews, research, implementation and verification: Claude (Claude Code) and Codex agents working for him, using Godot 4.7.2 for the stills, Playwright for the site captures and an Android emulator for the touch run.
- The games named in the presentation research are studied and cited only; no material from them is used.

### Sources cited in these records

URLs as recorded in the JSON (the file that cites each is in brackets). Accessed October 6 to 9, 2026. Titles are given where the record or the URL names them.

- **Godot Engine documentation (Godot Engine contributors)**
  - <https://docs.godotengine.org/en/4.7/tutorials/rendering/renderers.html> (`2026-10-08-presentation-research.json`)
  - <https://docs.godotengine.org/en/4.7/tutorials/rendering/compositor.html> (`2026-10-08-presentation-research.json`)
  - <https://docs.godotengine.org/en/4.7/classes/class_environment.html> (`2026-10-08-presentation-research.json`)
  - <https://docs.godotengine.org/en/4.7/classes/class_viewport.html> (`2026-10-08-presentation-research.json`)
  - <https://docs.godotengine.org/en/4.7/tutorials/2d/2d_lights_and_shadows.html> (`2026-10-08-presentation-research.json`)
  - <https://docs.godotengine.org/en/4.7/classes/class_projectsettings.html> (`2026-10-08-presentation-research.json`)
  - <https://docs.godotengine.org/en/4.7/classes/class_gpuparticles2d.html> (`2026-10-08-presentation-research.json`)
  - <https://docs.godotengine.org/en/4.7/classes/class_cpuparticles2d.html> (`2026-10-08-presentation-research.json`)
  - <https://docs.godotengine.org/en/4.7/tutorials/shaders/screen-reading_shaders.html> (`2026-10-08-presentation-research.json`)
  - <https://docs.godotengine.org/en/4.7/tutorials/performance/gpu_optimization.html> (`2026-10-08-presentation-research.json`)
  - <https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_images.html> (`2026-10-08-presentation-research.json`)
  - <https://docs.godotengine.org/en/4.7/classes/class_parallax2d.html> (`2026-10-08-presentation-research.json`)
  - <https://docs.godotengine.org/en/4.7/tutorials/2d/2d_parallax.html> (`2026-10-08-presentation-research.json`)
  - <https://docs.godotengine.org/en/4.7/classes/class_parallaxbackground.html> (`2026-10-08-presentation-research.json`)
  - <https://docs.godotengine.org/en/4.7/classes/class_pointlight2d.html> (`2026-10-08-presentation-research.json`)
  - <https://docs.godotengine.org/en/4.7/classes/class_light2d.html> (`2026-10-08-presentation-research.json`)
  - <https://docs.godotengine.org/en/4.7/classes/class_canvasmodulate.html> (`2026-10-08-presentation-research.json`)
  - <https://docs.godotengine.org/en/4.7/classes/class_tween.html> (`2026-10-08-presentation-research.json`)
  - <https://docs.godotengine.org/en/4.7/classes/class_camera2d.html> (`2026-10-08-presentation-research.json`)
  - <https://docs.godotengine.org/en/4.7/tutorials/shaders/custom_postprocessing.html> (`2026-10-08-presentation-research.json`)
  - <https://docs.godotengine.org/en/4.7/classes/class_lightoccluder2d.html> (`2026-10-08-presentation-research.json`)
  - <https://docs.godotengine.org/en/4.7/classes/class_canvastexture.html> (`2026-10-08-presentation-research.json`)
  - <https://docs.godotengine.org/en/4.7/classes/class_backbuffercopy.html> (`2026-10-08-presentation-research.json`)
  - <https://docs.godotengine.org/en/4.7/classes/class_canvaslayer.html> (`2026-10-08-presentation-research.json`)
  - <https://docs.godotengine.org/en/4.7/classes/class_canvasitem.html> (`2026-10-08-presentation-research.json`)
  - <https://docs.godotengine.org/en/4.7/tutorials/shaders/shader_reference/canvas_item_shader.html> (`2026-10-08-presentation-research.json`)
  - <https://docs.godotengine.org/en/4.7/classes/class_directionallight2d.html> (`2026-10-08-presentation-research.json`)
  - <https://docs.godotengine.org/en/4.7/tutorials/shaders/advanced_postprocessing.html> (`2026-10-08-presentation-research.json`)
  - <https://docs.godotengine.org/en/4.7/tutorials/shaders/shader_reference/shading_language.html> (`2026-10-08-presentation-research.json`)
  - <https://docs.godotengine.org/en/4.7/engine_details/architecture/internal_rendering_architecture.html> (`2026-10-08-presentation-research.json`)
  - <https://docs.godotengine.org/en/4.3/classes/class_styleboxflat.html> (`2026-10-08-presentation-research.json`)
  - <https://docs.godotengine.org/en/4.3/classes/class_styleboxtexture.html> (`2026-10-08-presentation-research.json`)
  - <https://docs.godotengine.org/en/4.3/classes/class_gradienttexture2d.html> (`2026-10-08-presentation-research.json`)
  - <https://docs.godotengine.org/en/4.3/classes/class_parallax2d.html> (`2026-10-08-presentation-research.json`)
  - <https://docs.godotengine.org/en/4.3/tutorials/2d/2d_lights_and_shadows.html> (`2026-10-08-presentation-research.json`)
  - <https://docs.godotengine.org/en/4.3/tutorials/shaders/screen-reading_shaders.html> (`2026-10-08-presentation-research.json`)
  - <https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html> (`2026-10-08-presentation-research.json`)
  - <https://docs.godotengine.org/en/4.3/classes/class_tween.html> (`2026-10-08-presentation-research.json`)
  - <https://docs.godotengine.org/en/stable/about/complying_with_licenses.html> (`README.md`)
  - <https://docs.godotengine.org/en/stable/tutorials/export/exporting_projects.html> (`README.md`)
- **Godot Engine website (Godot Foundation)**
  - <https://godotengine.org/releases/4.3/> (`2026-10-08-presentation-research.json`)
- **Godot Forum**
  - <https://forum.godotengine.org/t/i-think-i-found-a-godot-bug/125307> (`2026-10-08-presentation-research.json`)
- **OpenAI**
  - <https://openai.com/policies/terms-of-use/> (`2026-10-08-presentation-research.json`)
- **MrDemonWolf, Inc. (this project)**
  - <https://mrdwolf.net/discord> (`README.md`)
  - <https://mrdemonwolf.com> (`README.md`)
- **WOLF//OVERRIDE public site (this project)**
  - <https://mrdemonwolf.github.io/wolf-override/docs/changelog/> (`README.md`)
  - <https://mrdemonwolf.github.io/wolf-override/> (`README.md`)
  - <https://wolfoverride.mrdemonwolf.dev/docs/changelog/> (`README.md`)
  - <https://wolfoverride.mrdemonwolf.dev/> (`README.md`)
  - <https://wolfoverride.mrdemonwolf.dev/docs/walkthrough/> (`README.md`)
  - <https://wolfoverride.mrdemonwolf.dev/docs/> (`README.md`)
  - <https://wolfoverride.mrdemonwolf.dev/docs/credits/> (`README.md`)
  - <https://wolfoverride.mrdemonwolf.dev> (`README.md`)
  - <https://wolfoverride.mrdemonwolf.dev/this-page-does-not-exist/> (`README.md`)
  - <https://wolf-override.mrdemonwolf.dev/> (`README.md`)
- **Godot Engine source (Godot Engine contributors)**
  - <https://github.com/godotengine/godot/tree/4.7.2-stable> (`README.md`)
  - <https://github.com/godotengine/godot/blob/4.7.2-stable/scene/main/viewport.cpp> (`README.md`)
  - <https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/windows/dir_access_windows.cpp> (`README.md`)
- **Game Accessibility Guidelines**
  - <https://gameaccessibilityguidelines.com/allow-players-to-progress-through-text-prompts-at-their-own-pace/> (`README.md`)
  - <https://gameaccessibilityguidelines.com/give-a-clear-indication-that-interactive-elements-are-interactive/> (`README.md`)
  - <https://gameaccessibilityguidelines.com/if-any-subtitles-captions-are-used-present-them-in-a-clear-easy-to-read-way/> (`README.md`)
  - <https://gameaccessibilityguidelines.com/allow-controls-to-be-remapped-reconfigured/> (`README.md`)
- **IGDA**
  - <https://igda.org/resources-archive/igda-game-crediting-guidelines-10-1-march-2023-update/> (`README.md`)
- **SIL Open Font License site (SIL International)**
  - <https://openfontlicense.org/ofl-faq/> (`README.md`)
- **IPTC**
  - <https://cv.iptc.org/newscodes/digitalsourcetype/trainedAlgorithmicMedia> (`README.md`)
- **Apple Developer documentation (Apple)**
  - <https://developer.apple.com/app-store/review/guidelines/> (`README.md`)
- **Google Play Console Help (Google)**
  - <https://support.google.com/googleplay/android-developer/answer/10787469> (`README.md`)
- **U.S. Copyright Office**
  - <https://www.copyright.gov/ai/Copyright-and-Artificial-Intelligence-Part-2-Copyrightability-Report.pdf> (`README.md`)
- **Free Software Foundation**
  - <https://www.fsf.org/blogs/licensing/more-about-the-app-store-gpl-enforcement> (`README.md`)
- **W3C**
  - <https://www.w3.org/WAI/WCAG22/Understanding/focus-order.html> (`README.md`)
  - <https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/examples/disclosure-navigation/> (`README.md`)
  - <https://www.w3.org/WAI/WCAG22/Understanding/bypass-blocks.html> (`README.md`)
  - <https://www.w3.org/TR/selectors-4/#specificity-rules> (`README.md`)
  - <https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html> (`README.md`)
  - <https://www.w3.org/WAI/WCAG22/Techniques/failures/F73> (`README.md`)
- **WHATWG HTML Standard**
  - <https://html.spec.whatwg.org/multipage/browsing-the-web.html#scroll-to-the-fragment-identifier> (`README.md`)
- **Next.js documentation (Vercel)**
  - <https://nextjs.org/docs/app/getting-started/fonts> (`README.md`)
  - <https://nextjs.org/docs/app/guides/static-exports> (`README.md`)
  - <https://nextjs.org/docs/app/api-reference/components/font> (`README.md`)
  - <https://nextjs.org/docs/app/api-reference/file-conventions/metadata/robots> (`README.md`)
  - <https://nextjs.org/docs/app/guides/json-ld> (`README.md`)
- **web.dev (Google)**
  - <https://web.dev/articles/optimize-lcp> (`README.md`)
  - <https://web.dev/articles/font-best-practices> (`README.md`)
  - <https://web.dev/articles/lcp> (`README.md`)
- **React documentation (Meta)**
  - <https://react.dev/reference/rsc/use-client> (`README.md`)
- **next-themes (Paco Coursey)**
  - <https://github.com/pacocoursey/next-themes#avoid-hydration-mismatch> (`README.md`)
- **Microsoft DevBlogs (Microsoft)**
  - <https://devblogs.microsoft.com/typescript/announcing-typescript-6-0/> (`README.md`)
- **MDN Web Docs (Mozilla)**
  - <https://developer.mozilla.org/en-US/docs/Web/CSS/@layer> (`README.md`)
  - <https://developer.mozilla.org/en-US/docs/Web/CSS/overflow> (`README.md`)
- **Lighthouse (Google Chrome)**
  - <https://github.com/GoogleChrome/lighthouse/blob/main/docs/throttling.md> (`README.md`)
- **Meta for Developers**
  - <https://developers.facebook.com/docs/sharing/webmasters/images/> (`README.md`)
- **Branch Help Center**
  - <https://help.branch.io/faq/docs/why-are-some-quick-link-thumbnails-not-shown-in-whatsapp> (`README.md`)
- **Google Search Central (Google)**
  - <https://developers.google.com/search/docs/crawling-indexing/robots/robots_txt> (`README.md`)
  - <https://developers.google.com/search/docs/appearance/site-names> (`README.md`)
- **GitHub Docs (GitHub)**
  - <https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/verifying-your-custom-domain-for-github-pages> (`README.md`)
- **Content Authenticity Initiative**
  - <https://verify.contentauthenticity.org/> (`README.md`)
  - <https://opensource.contentauthenticity.org/docs/c2patool/> (`README.md`)
- **Games and design writing (presentation research)**
  - 80 Level, interview with the developers of *Dead Cells* (Motion Twin): <https://80.lv/articles/interview-with-the-developers-of-dead-cells> (`2026-10-08-presentation-research.json`)
  - GoNintendo, *Dead Cells* dev blog: art design deep dive: <https://gonintendo.com/archives/280488-dead-cells-dev-blog-art-design-deep-dive-giving-back-colors-to-cryptic-worlds> (`2026-10-08-presentation-research.json`)
  - Xbox Wire (Microsoft), article on *Ori* art: <https://news.xbox.com/en-us/?p=4339> (`2026-10-08-presentation-research.json`)
  - Airborn Studios, *Ori* project page: <https://airborn-studios.com/projects/ori> (`2026-10-08-presentation-research.json`)
  - GDC Vault, "The Art of Ori and the Will of the Wisps" (Moon Studios): <https://gdcvault.com/play/1027035/The-Art-of-Ori-and> (`2026-10-08-presentation-research.json`)
  - Unity, *Hollow Knight* case study (Team Cherry): <https://unity.com/case-study/hollow-knight> (`2026-10-08-presentation-research.json`)
  - 80 Level, "How game devs trick players using simple layers": <https://80.lv/articles/check-out-how-game-devs-trick-players-using-simple-layers> (`2026-10-08-presentation-research.json`)
  - 80 Level, breakdown of *Hollow Knight*'s art style: <https://80.lv/articles/breakdown-hollow-knights-art-style> (`2026-10-08-presentation-research.json`)
  - GDC Vault, "Low Complexity, High Fidelity: INSIDE Rendering" (Playdead, 2016): <https://gdcvault.com/play/1023783/Low-Complexity-High-Fidelity-INSIDE> (`2026-10-08-presentation-research.json`)
  - Gameranx, Playdead on the techniques used to render *Inside*: <https://gameranx.com/updates/id/86066/article/playdead-provides-details-on-the-techniques-used-to-render-inside/> (`2026-10-08-presentation-research.json`)
  - PC Games Hardware, *Trine 2* technology interview with Frozenbyte (German): <https://www.pcgameshardware.de/Trine-2-Spiel-39851/Specials/Trine-2-Exklusives-Technik-Interview-mit-Frozenbyte-Grandioses-Art-Design-trifft-auf-detailverliebte-Engine-866092/> (`2026-10-08-presentation-research.json`)
  - GDC Vault, "Rayman Legends: The Design Process" (Ubisoft Montpellier): <https://gdcvault.com/play/1021191/Rayman-Legends-The-Design-Process> (`2026-10-08-presentation-research.json`)
  - Unreal Engine, "How Little Nightmares II plumbs the depths of adolescent angst" (Tarsier Studios): <https://www.unrealengine.com/en-US/developer-interviews/how-little-nightmares-ii-plumbs-the-depths-of-adolescent-angst> (`2026-10-08-presentation-research.json`)
  - Thumbsticks, *Little Nightmares* review: <https://www.thumbsticks.com/little-nightmares-review/> (`2026-10-08-presentation-research.json`)
  - Wikipedia, *Katana Zero*: <https://en.wikipedia.org/wiki/Katana_Zero> (`2026-10-08-presentation-research.json`)
  - Deutscher Computerspielpreis, *Signalis* entry: <https://deutscher-computerspielpreis.de/chronik/signalis/?lang=en> (`2026-10-08-presentation-research.json`)
  - PC Zone (article id 12693): <https://pczone.co.uk/?p=12693> (`2026-10-08-presentation-research.json`)
  - Game Developer, video: designing *Dead Space*'s immersive user interface: <https://gamedeveloper.com/design/video-designing-i-dead-space-i-s-immersive-user-interface> (`2026-10-08-presentation-research.json`)
  - Quest for UX, *Dead Space* remake game UX case study: <https://questforux.beehiiv.com/p/game-ux-case-study-dead-space-remake-422b> (`2026-10-08-presentation-research.json`)
  - Gfinity Esports, why *Dead Space*'s diegetic HUD matters: <https://www.gfinityesports.com/article/the-unsung-hero-of-dead-space-why-diegetic-hud-design-is-crucial-for-ultimate-immersion> (`2026-10-08-presentation-research.json`)
  - PlayStation Blog (post 348960): <https://blog.playstation.com/?p=348960> (`2026-10-08-presentation-research.json`)
  - Game Developer, "What to steal from Destiny's UI": <https://www.gamedeveloper.com/design/what-to-steal-from-destiny-s-ui> (`2026-10-08-presentation-research.json`)
  - HUDS+GUIS, *Destiny* UI: <https://hudsandguis.com/home/2015/5/25/destiny-ui> (`2026-10-08-presentation-research.json`)
  - GDC Vault, talk 1023460: <https://www.gdcvault.com/play/1023460/> (`2026-10-08-presentation-research.json`)
  - HUDS+GUIS, *Alien: Isolation*: <https://hudsandguis.com/home/2014/06/04/alien-isolation> (`2026-10-08-presentation-research.json`)
  - Kotaku, "The fonts in Control make its world feel way creepier" (2019): <https://kotaku.com/the-fonts-in-control-make-its-world-feel-way-creepier-1837714580> (`2026-10-08-presentation-research.json`)
  - Fonts In Use, *Control* (Remedy): <https://fontsinuse.com/uses/48689/control-video-game> (`2026-10-08-presentation-research.json`)
  - Work With Indies, Supergiant Games UI animator listing (*Hades II*): <https://www.workwithindies.com/careers/supergiant-games-ui-animator-hades-ii> (`2026-10-08-presentation-research.json`)
  - Supergiant Games, UI illustrator job post (*Hades II*): <https://www.supergiantgames.com/blog/job-opportunity-ui-illustrator-for-hades-ii> (`2026-10-08-presentation-research.json`)
  - Den of Geek, *Mass Effect Legendary Edition* changes: <https://www.denofgeek.com/games/mass-effect-legendary-edition-changes-problems-details-controversies> (`2026-10-08-presentation-research.json`)
  - Nielsen Norman Group, "Executing UX Animations: Duration and Motion Characteristics": <https://www.nngroup.com/articles/animation-duration/> (`2026-10-08-presentation-research.json`)
  - Nielsen Norman Group, "Glassmorphism": <https://www.nngroup.com/articles/glassmorphism/> (`2026-10-08-presentation-research.json`)
  - Josh W. Comeau, "Designing Beautiful Shadows in CSS": <https://www.joshwcomeau.com/css/designing-shadows/> (`2026-10-08-presentation-research.json`)
  - WebAIM, "Contrast and Color Accessibility": <https://webaim.org/articles/contrast/> (`2026-10-08-presentation-research.json`)
