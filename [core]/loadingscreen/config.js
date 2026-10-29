// loading screen branding. no build step, just restart the resource.
window.LOADING_CONFIG = {
  name: 'QSCORE',
  subtitle: 'Roleplay Framework',

  about: 'Open-source roleplay framework · runs ESX & QBCore scripts',

  keys: [
    { key: 'F1', label: 'Inventory' },
    { key: 'TAB', label: 'Item wheel' },
    { key: '1-5', label: 'Quick slots' },
    { key: 'E', label: 'Interact' },
    { key: 'U', label: 'Lock vehicle' },
    { key: 'B', label: 'Seatbelt' },
    { key: 'G', label: 'Hotwire' },
    { key: 'T', label: 'Chat' },
  ],

  // rotating lines at the bottom
  tips: [
    'Every character is a story waiting to be lived.',
    'Drive like you mean it. Roleplay like it matters.',
    'Hold TAB to use the items in your first five slots.',
    'Your reputation is the only currency that lasts.',
    'Use /me and /do in the chat to roleplay your actions.',
  ],

  tipInterval: 5.2, // seconds
};
