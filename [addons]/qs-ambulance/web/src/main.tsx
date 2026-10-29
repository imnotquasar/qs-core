import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import '@fontsource/poppins/500.css';
import '@fontsource/poppins/600.css';
import '@fontsource/poppins/700.css';
import '@fontsource/poppins/800.css';
import '@fontsource/poppins/900.css';
import './index.css';
import { FaAmbulance, FaStethoscope, FaHeartbeat, FaProcedures, FaBed } from 'react-icons/fa';
import App from './App';
import JobMenu, { type MenuAction } from './JobMenu';

const EMS_ACTIONS: MenuAction[] = [
  { id: 'diagnose', icon: FaStethoscope, label: ['ui_diagnose', 'Diagnose'] },
  { id: 'self', icon: FaHeartbeat, label: ['ui_mystatus', 'My status'] },
  { id: 'stretcher', icon: FaProcedures, label: ['ui_stretcher', 'Stretcher'] },
  { id: 'patient', icon: FaBed, label: ['ui_patient', 'Patient to stretcher'] },
];

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
    <JobMenu icon={FaAmbulance} title={['ui_ems', 'EMS']} actions={EMS_ACTIONS} />
  </StrictMode>,
);
