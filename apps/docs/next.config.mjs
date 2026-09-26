import { createMDX } from 'fumadocs-mdx/next';

/** @type {import('next').NextConfig} */
const config = {
  output: 'export',
  reactStrictMode: true,
  trailingSlash: true,
  basePath: process.env.GITHUB_PAGES === 'true' ? '/wolf-override' : undefined,
};

export default createMDX()(config);
