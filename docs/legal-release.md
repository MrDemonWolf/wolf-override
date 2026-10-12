# Legal and installation copy — private working draft

Drafted September 26, 2026. **Do not publish or present this as approved terms.** Review against the actual release binary, website build, stores, assets, target regions and an owner-approved contact. This is a product checklist and draft copy, not legal advice.

## Observed M0 behavior and limits

- The current Godot source stores checkpoint state in `user://m0-save.json`: selected roster name index, actor and positions, puzzle route, checkpoint flag, and one authored dialogue choice. `New Game` clears memory in the running game; it does **not** currently delete the previous save file. The current source contains no account, networking, analytics, ads, payment or cloud-save code. Recheck the exported binary and any future SDKs before a public privacy claim.
- The proposed public `apps/docs` site has no first-party forms, analytics or tracking code in the inspected source. Its dependencies/build are not verified yet and GitHub Pages is not deployed. GitHub says Pages logs every visitor's IP address for security, regardless of sign-in. Avoid saying the website collects no data or sets no cookies without verifying the actual deployed page and host behavior.
- No downloadable game, installer, App Store/Google Play record, or store privacy declaration exists yet. There are no acquired art/audio assets in the current asset register.

## Draft privacy policy text — edit after release inventory

> **WOLF//OVERRIDE Privacy Policy**  
> Effective [date]; applies to [exact game versions/platforms] and [public website URL]. Publisher: MrDemonWolf, Inc. Contact: [owner-approved privacy/support contact].
>
> **Game saves.** The current game stores your progress and a selected response to one story choice in a file on your device. It also stores the chosen display name from the built-in roster, character positions, and corridor puzzle state. The current game does not send this save to us. `New Game` starts fresh play but does not currently erase the old checkpoint file. [Before release, provide a clear delete-save instruction or control for each platform and confirm how platform backups behave.]
>
> **Website.** If the public site uses GitHub Pages, GitHub hosts it and logs visitor IP addresses for security. [Confirm any cookies, fonts, embeds, analytics, forms, CDN, and links in the deployed output.] See [GitHub's privacy statement](https://docs.github.com/en/site-policy/privacy-policies/github-general-privacy-statement) for GitHub's practices.
>
> **Accounts and communications.** [Confirm that the shipped game has no account, telemetry, advertising, crash reporting, newsletter or cloud service. If added, describe the data, purpose, recipients, retention, choices and deletion process here.]
>
> **Retention and choices.** Local checkpoint data remains on your device until you remove it through [verified platform steps/control]. [Describe how to contact us about any data the publisher actually holds, and distinguish store/hosting data controlled by Apple, Google or GitHub.]
>
> **Changes.** We will update this notice when the game or website's data practices change and show the effective date. Contact [owner-approved contact] with privacy questions.

The bracketed items block publication. Do not represent a source-code scan as proof that a future export or third-party SDK sends no data.

## Draft terms and license notice — edit before distribution

> **WOLF//OVERRIDE Terms and Licenses**  
> Effective [date]. WOLF//OVERRIDE source code and public documentation are offered under **GPL-3.0-or-later**. The [license text](../LICENSE) and corresponding source for the exact distributed version must be available with each distributed binary. Payment for a copy does not remove the GPL rights to use, modify and redistribute its covered code. [List the distinct licenses/permissions for shipped art, music, voice, fonts, marks and other assets from the final asset register.] Godot Engine is MIT licensed; include its copyright and license notice in the game credits or distribution documentation. [Publisher contact and consumer terms that apply in the actual selling regions.] Nothing in these terms limits rights granted by the GPL.

Do not add a mandatory “accept restrictions on copying/modification” installer checkbox for GPL-covered code. A direct download page can present a clear **License and source** link before download, with the same information available in an in-game Credits/Legal menu. For Apple distribution, the standard EULA may conflict with GPL rights; a custom EULA option exists but does not resolve compatibility by itself. Obtain qualified legal review of the exact GPL/assets/store combination before submitting a paid Mac App Store build.

## Draft before-install disclosure

Show on the download/store page before installation; keep accessible from in-game Credits/Legal after installation. For a Homebrew cask, put the disclosure on the linked release page because the command-line install has no custom consent screen.

> **WOLF//OVERRIDE [version] — [platform]**  
> Publisher: MrDemonWolf, Inc. Price: [channel-specific confirmed price]. The game saves progress and an authored story choice locally on your device. [Confirmed network/analytics statement for this exact binary.] [Verified way to remove saves.] Read the [Privacy Policy URL], [Terms and Licenses URL], and [version-matched source URL] before installing. Credits: **Game idea by Nathanial Henniges. Made with help from AI tools.** [Age/content rating, system requirements, refund and support links as applicable to this channel.]

The tentative Mac App Store price is **US $4.99** and Windows is intended to be free; neither is a live offer. Decide direct Mac/Homebrew pricing and mobile pricing separately. Do not claim a Homebrew cask, App Store listing or downloadable build exists until it does.

## Release checks

| Check | Current status | Required before release |
| --- | --- | --- |
| Data inventory and privacy policy | Draft based on M0 source | Inspect final binary/dependencies/site output; confirm support contact, hosting, SDKs, retention, deletion and target regions. |
| Local save removal | Missing in-game delete control | Provide truthful per-platform deletion steps or a control; verify `New Game` semantics. |
| Apple privacy | Not configured | Publish accessible policy URL in metadata and in app; complete accurate app privacy responses, including partner SDKs. |
| Google Play privacy | Not configured | Publish policy URL in listing and app; complete Data safety form even if no data collected. Account-deletion rules apply if accounts are later added. |
| GPL distribution | Source-only prototype | Include GPL notice/text and exact-version corresponding source with every binary; preserve GPL rights in any terms/EULA. |
| Engine and asset notices | No exports/assets | Include Godot MIT notice; audit each shipped asset's rights and notice requirements. |
| Mac App Store legal route | Unresolved | Review GPL compatibility, Apple EULA/custom terms, asset rights, proposed price and Paid Apps Agreement before submission. |
| Install surface | No packages/listings | Show version, price, data behavior, privacy, license/source, support and content information before download where channel allows; avoid a fictitious installer acceptance gate. |
| Provenance credit | Requested | Keep “Game idea by Nathanial Henniges. Made with help from AI tools.” in public credits; it is a credit, not license text. |

## Primary references checked September 26, 2026

- [Apple App Review Guidelines §5.1.1](https://developer.apple.com/app-store/review/guidelines/) require a privacy-policy link in store metadata and in the app and describe data/retention/deletion disclosures.
- [Apple App Store Connect privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy) requires a privacy-policy URL and accurate data-practice responses.
- [Apple custom EULA instructions](https://developer.apple.com/help/app-store-connect/manage-app-information/provide-a-custom-license-agreement) explain the default EULA and custom option; they do not certify GPL compatibility.
- [Apple's standard EULA](https://www.apple.com/legal/internet-services/itunes/dev/stdeula/) restricts transfer, redistribution and modification, with an open-source-components exception whose fit to this full GPL game has not been determined.
- [Google Play Data safety](https://support.google.com/googleplay/android-developer/answer/10787469) requires a form and policy link even for apps reporting no collected user data; [Google Play User Data policy](https://support.google.com/googleplay/android-developer/answer/10144311) covers policy placement in listing and app.
- [GitHub Pages documentation](https://docs.github.com/en/pages/getting-started-with-github-pages/what-is-github-pages) says visitor IP addresses are logged for security; see [GitHub privacy statement](https://docs.github.com/en/site-policy/privacy-policies/github-general-privacy-statement).
- [GPLv3 text](https://www.gnu.org/licenses/gpl-3.0.en.html) and [GNU FAQ on corresponding source](https://www.gnu.org/licenses/gpl-faq.en.html#AnonFTPAndSendSources) govern binaries/source and downstream rights; [GNU licensing guidance](https://www.gnu.org/licenses/gpl-howto.en.html) recommends clear notices.
- [Godot license](https://godotengine.org/license/) requires the engine's MIT copyright/license notice when the engine binary is distributed.
