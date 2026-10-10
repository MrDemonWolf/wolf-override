import { createMDX } from 'fumadocs-mdx/next';

/** @type {import('next').NextConfig} */
const config = {
  output: 'export',
  reactStrictMode: true,
  trailingSlash: true,
  // GitHub Pages has no image optimiser; images render from their static URLs, never /_next/image.
  images: { unoptimized: true },
};

export default createMDX()(config);
