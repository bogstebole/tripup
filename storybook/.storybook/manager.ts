import { addons } from 'storybook/manager-api';
import { create } from 'storybook/theming';

// The canvas first: the addons panel (Controls, Actions) is one keypress away (A) but starts hidden, since most
// stories here are screens and states rather than knobs. The sidebar says whose system this is.
addons.setConfig({
  showPanel: false,
  theme: create({ base: 'light', brandTitle: 'TripUp · design system', brandTarget: '_self' }),
});
