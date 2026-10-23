import type { Preview } from '@storybook/react-vite';
import '@fontsource/geist/400.css';
import '@fontsource/geist/500.css';
import '@fontsource/geist/600.css';
import '@fontsource/geist/700.css';
import '@fontsource/ibm-plex-sans-condensed/700.css';
import '../src/tokens.css';
import '../src/global.css';

const preview: Preview = {
  parameters: {
    layout: 'centered',
    controls: { expanded: true },
    options: { storySort: { order: ['Introduction', 'Foundations', 'Components', 'Widget', 'Screens', 'Pop-ups'] } },
  },
  globalTypes: {
    theme: { description: 'Color mode', toolbar: { title: 'Theme', icon: 'mirror', items: ['light', 'dark'], dynamicTitle: true } },
  },
  initialGlobals: { theme: 'light' },
  decorators: [
    (Story, ctx) => {
      document.documentElement.dataset.theme = ctx.globals.theme;
      return <Story />;
    },
  ],
};
export default preview;
