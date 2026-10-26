import type { StorybookConfig } from '@storybook/react-vite';

const config: StorybookConfig = {
  framework: '@storybook/react-vite',
  stories: ['../src/**/*.mdx', '../src/**/*.stories.@(ts|tsx)'],
  addons: ['@storybook/addon-docs'],
  // Stickers, photos and fonts live with the Flutter app, so both use the same files
  staticDirs: [{ from: '../../app/assets', to: '/assets' }],
  // A clean shell for reviewers: no setup checklist in the sidebar or menu, no "what's new" popups, no telemetry
  features: { sidebarOnboardingChecklist: false, menuOnboardingChecklist: false },
  core: { disableWhatsNewNotifications: true, disableTelemetry: true },
};
export default config;
