import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import '@fontsource/poppins/500.css';
import '@fontsource/poppins/600.css';
import '@fontsource/poppins/700.css';
import '@fontsource/poppins/800.css';
import '@fontsource/poppins/900.css';
import './index.css';
import { FaShieldAlt, FaWalking, FaCarSide, FaSignOutAlt, FaSearch, FaTruckPickup } from 'react-icons/fa';
import { FaHandcuffs } from 'react-icons/fa6';
import App from './App';
import JobMenu, { type MenuAction } from './JobMenu';

const POLICE_ACTIONS: MenuAction[] = [
  { id: 'cuff', icon: FaHandcuffs, label: ['ui_cuff', 'Cuff'], needsTarget: true },
  { id: 'escort', icon: FaWalking, label: ['ui_escort', 'Escort'], needsTarget: true },
  { id: 'putincar', icon: FaCarSide, label: ['ui_putincar', 'Put in vehicle'], needsTarget: true },
  { id: 'outcar', icon: FaSignOutAlt, label: ['ui_outcar', 'Take out'], needsTarget: true },
  { id: 'search', icon: FaSearch, label: ['ui_search', 'Search'], needsTarget: true },
  { id: 'impound', icon: FaTruckPickup, label: ['ui_impound', 'Impound'], danger: true },
];

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
    <JobMenu icon={FaShieldAlt} title={['ui_police', 'Police']} actions={POLICE_ACTIONS} fine />
  </StrictMode>,
);
