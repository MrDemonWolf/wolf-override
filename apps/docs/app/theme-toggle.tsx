'use client';

import { useEffect, useState } from 'react';
import { useTheme } from 'next-themes';

export default function ThemeToggle() {
  const { resolvedTheme, setTheme } = useTheme();
  const [mounted, setMounted] = useState(false);

  useEffect(() => setMounted(true), []);

  return (
    <button
      type="button"
      className="theme-toggle"
      aria-label={mounted ? (resolvedTheme === 'dark' ? 'Switch to light mode' : 'Switch to dark mode') : 'Switch color theme'}
      onClick={() => setTheme(resolvedTheme === 'dark' ? 'light' : 'dark')}
    >
      {mounted ? (resolvedTheme === 'dark' ? 'Light mode' : 'Dark mode') : 'Theme'}
    </button>
  );
}
