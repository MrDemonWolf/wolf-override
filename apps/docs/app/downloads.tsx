'use client';
import { useEffect, useState } from 'react';
import Link from 'next/link';

type Platform = 'windows' | 'macos' | 'ios' | 'android';
const platforms: Record<Platform, string> = { windows: 'Windows', macos: 'macOS', ios: 'iPhone / iPad', android: 'Android' };
const channels: { platform: Platform; name: string; detail: string }[] = [
  { platform: 'windows', name: 'Windows download', detail: 'Direct desktop download' },
  { platform: 'macos', name: 'macOS download', detail: 'Direct desktop download' },
  { platform: 'macos', name: 'Mac App Store', detail: 'Store distribution' },
  { platform: 'macos', name: 'Homebrew', detail: 'Install from your terminal' },
  { platform: 'ios', name: 'iOS / iPadOS App Store', detail: 'iPhone and iPad' },
  { platform: 'android', name: 'Google Play', detail: 'Android phones and tablets' },
];

export function detectPlatform(ua: string, platform: string, touchPoints: number): Platform | '' {
  if (/Android/i.test(ua)) return 'android';
  if (/iPhone|iPad|iPod/i.test(ua) || (platform === 'MacIntel' && touchPoints > 1)) return 'ios';
  if (/Mac/i.test(ua)) return 'macos';
  if (/Windows/i.test(ua)) return 'windows';
  return '';
}

export default function Downloads() {
  const [platform, setPlatform] = useState<Platform | ''>('');
  useEffect(() => {
    setPlatform(detectPlatform(navigator.userAgent, navigator.platform, navigator.maxTouchPoints));
  }, []);
  const preferred = channels.filter(channel => channel.platform === platform);
  const other = channels.filter(channel => channel.platform !== platform);
  const card = (channel: typeof channels[number]) => (
    <div key={channel.name} className="marketing-download" title="Coming soon — no download is available yet">
      <span className="marketing-download-platform">{platforms[channel.platform]}</span>
      <button type="button" disabled aria-describedby="download-note">{channel.name}</button>
      <span className="marketing-download-detail">{channel.detail}</span>
      <span className="marketing-coming-soon">Coming soon</span>
    </div>
  );
  return (
    <section id="downloads" className="marketing-downloads" aria-labelledby="downloads-title">
      <div className="marketing-width">
        <p className="marketing-kicker">Choose your way into THE DEN</p>
        <div className="marketing-download-heading"><h2 id="downloads-title">Join them.<br /><em>When it&apos;s ready.</em></h2><p id="download-note">No packaged game download yet. These are planned channels, with no announced release date. You can still try the current source build with Godot.</p></div>
        <div className="marketing-source-note"><div><strong>Want to try it now?</strong><p>Download the source snapshot and follow the Godot setup guide. It is a development build, not an installer.</p></div><Link href="/docs/get-game/">Get the source build <span aria-hidden="true">→</span></Link></div>
        <div className="marketing-platform-picker"><label htmlFor="platform">Your platform</label><span className="marketing-platform-select"><select id="platform" value={platform} onChange={event => setPlatform(event.target.value as Platform | '')}><option value="">Choose a platform</option>{Object.entries(platforms).map(([value, label]) => <option key={value} value={value}>{label}</option>)}</select></span><p>Suggested from your browser. You can choose any platform.</p></div>
        {platform && <div className="marketing-preferred"><h3>Planned for {platforms[platform]}</h3><div className="marketing-download-grid">{preferred.map(card)}</div></div>}
        <details className="marketing-other-platforms"><summary>{platform ? 'Other platforms & planned channels' : 'View all planned channels'}</summary><div className="marketing-download-grid">{other.map(card)}</div></details>
        <div className="marketing-download-links"><Link className="marketing-inline" href="/docs/get-game/">Get the game: source build guide →</Link><Link className="marketing-inline" href="/docs/changelog/">Follow the changelog →</Link></div>
      </div>
    </section>
  );
}
