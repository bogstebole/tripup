import type { StorybookConfig } from '@storybook/react-vite';

const config: StorybookConfig = {
  framework: '@storybook/react-vite',
  stories: ['../src/**/*.mdx', '../src/**/*.stories.@(ts|tsx)'],
  addons: ['@storybook/addon-docs'],
  // Stickers, photos and fonts live with the Flutter app, so both use the same files
  staticDirs: [{ from: '../../app/assets', to: '/assets' }],
};
export default config;
