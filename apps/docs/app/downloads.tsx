'use client';
import { useEffect, useState } from 'react';

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
  return (
    <section id="downloads" className="marketing-downloads" aria-labelledby="downloads-title">
      <div className="marketing-width">
        <p className="marketing-kicker">Choose your way into THE DEN</p>
        <div className="marketing-download-heading"><h2 id="downloads-title">Your platform.<br /><em>When it&apos;s ready.</em></h2><p id="download-note">Downloads are coming soon. These are planned channels, not available releases. There is no announced release date.</p></div>
        <div className="marketing-platform-picker"><label htmlFor="platform">Your platform</label><select id="platform" value={platform} onChange={event => setPlatform(event.target.value as Platform | '')}><option value="">Choose a platform</option>{Object.entries(platforms).map(([value, label]) => <option key={value} value={value}>{label}</option>)}</select><p>Suggested from your browser. You can choose any platform.</p></div>
        <div className="marketing-download-grid">
          {channels.map(channel => <button key={channel.name} type="button" aria-disabled="true" aria-describedby="download-note" title="Coming soon — no download is available yet" className={`marketing-download${platform === channel.platform ? ' is-suggested' : ''}`}>
            <span className="marketing-download-platform">{platforms[channel.platform]}{platform === channel.platform && <span className="marketing-match">Your platform</span>}</span>
            <strong>{channel.name} <span aria-hidden="true">↗</span></strong><span className="marketing-download-detail">{channel.detail}</span><span className="marketing-coming-soon">Coming soon</span>
          </button>)}
        </div>
        <p className="marketing-download-note">No installer, purchase or update will start from these buttons. Store availability and platform testing are still ahead.</p>
      </div>
    </section>
  );
}
