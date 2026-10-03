'use client';

import { useEffect, useState } from 'react';
import { useTheme } from 'next-themes';

export default function ThemeToggle() {
  const { resolvedTheme, setTheme } = useTheme();
  const [mounted, setMounted] = useState(false);
  const isDark = mounted ? resolvedTheme === 'dark' : true;
  const nextMode = isDark ? 'light' : 'dark';

  useEffect(() => setMounted(true), []);

  return (
    <button
      type="button"
      className="theme-toggle"
      aria-label={mounted ? `Switch to ${nextMode} mode` : 'Toggle color theme'}
      title={mounted ? `Switch to ${nextMode} mode` : 'Toggle color theme'}
      onClick={() => setTheme(nextMode)}
    >
      <svg aria-hidden="true" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round">
        {isDark ? (
          <>
            <circle cx="12" cy="12" r="3.6" />
            <path d="M12 2.2v2M12 19.8v2M4.9 4.9l1.4 1.4m11.4 11.4 1.4 1.4M2.2 12h2m15.6 0h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4" />
          </>
        ) : (
          <path d="M20.2 15.1A8.4 8.4 0 0 1 8.9 3.8a8.5 8.5 0 1 0 11.3 11.3Z" />
        )}
      </svg>
      <span className="theme-toggle-label">{mounted ? `${nextMode[0].toUpperCase()}${nextMode.slice(1)} mode` : 'Theme'}</span>
    </button>
  );
}
