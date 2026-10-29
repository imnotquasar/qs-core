import { useState } from 'react';
import type { IconType } from 'react-icons';
import {
  FaHeart,
  FaShieldAlt,
  FaDrumstickBite,
  FaTint,
  FaBriefcase,
  FaDollarSign,
  FaPiggyBank,
  FaGasPump,
} from 'react-icons/fa';
import { PiSeatbeltFill } from 'react-icons/pi';
import useNuiEvent from './hooks/useNuiEvent';
import type { Colors, CountsData, ShowData, StatusData, VehData } from './types';
import './index.css';

const isBrowser = !(window as any).invokeNative;

function applyTheme(c: Colors) {
  if (!c) return;
  const map: Record<string, string | undefined> = {
    '--hud-text': c.text,
    '--hud-muted': c.muted,
    '--hud-primary': c.primary,
    '--hud-primary-dim': c.primaryDim,
    '--hud-accent': c.accent,
    '--hud-glow': c.glow,
    '--hud-border': c.border,
    '--hud-panel': c.panel,
    '--v-health': c.health,
    '--v-armor': c.armor,
    '--v-hunger': c.hunger,
    '--v-thirst': c.thirst,
  };
  const style = document.documentElement.style;
  for (const key in map) {
    const val = map[key];
    if (val) style.setProperty(key, val);
  }
}

const money = (n: number) => '$' + Math.round(n || 0).toLocaleString('en-US');
const clamp = (n: number) => Math.max(0, Math.min(100, Math.round(n || 0)));

function Card({ Icon, label }: { Icon: IconType; label: string }) {
  return (
    <div className="card">
      <Icon className="card-ico" />
      <span className="card-lbl">{label}</span>
    </div>
  );
}

function Pill({ tag, value }: { tag: string; value: string | number }) {
  return (
    <div className="pill">
      <span className="tag">{tag}</span>
      <span className="val">{value}</span>
    </div>
  );
}

const SEGMENTS = 16;

function gearLabel(gear: number, speed: number) {
  if (gear === 0) return speed > 2 ? 'R' : 'N';
  return String(gear);
}

function CarHud({ v }: { v: VehData }) {
  const lit = Math.round(clamp(v.rpm * 100) / 100 * SEGMENTS);
  const fuelLow = v.fuel <= 20;
  return (
    <div className="car">
      <svg className="car-rail" viewBox="0 0 300 44" preserveAspectRatio="none">
        <path className="rail-line" d="M12 38 L94 38 L150 10 L292 10" />
        {Array.from({ length: 8 }).map((_, i) => {
          const x = 162 + i * 17;
          return <line key={i} className="rail-tick" x1={x} y1={15} x2={x} y2={23} />;
        })}
      </svg>

      <div className="car-mid">
        <div className="car-left">
          <span className="gear">{gearLabel(v.gear, v.speed)}</span>
          <PiSeatbeltFill className={`c-ico belt ${v.belt ? 'on' : 'off'}`} />
          <FaGasPump className={`c-ico fuel ${fuelLow ? 'low' : ''}`} />
        </div>
        <div className="car-right">
          <span className="unit">{v.unit}</span>
          <span className="speed">{Math.round(v.speed)}</span>
        </div>
      </div>

      <div className="car-bar">
        {Array.from({ length: SEGMENTS }).map((_, i) => (
          <span key={i} className={`seg ${i < lit ? 'on' : ''} ${i >= SEGMENTS - 3 ? 'red' : ''}`} />
        ))}
      </div>

      <div className="car-street">{v.street || ''}</div>
    </div>
  );
}

function HBar({ value, color, Icon, low }: { value: number; color: string; Icon: IconType; low?: boolean }) {
  const pct = clamp(value);
  return (
    <div className={`hbar ${low && pct <= 20 ? 'low' : ''}`} style={{ ['--c' as any]: color }}>
      <div className="hbar-fill" style={{ width: `${pct}%` }} />
      <Icon className="hbar-ico" />
    </div>
  );
}

export default function App() {
  const [visible, setVisible] = useState(isBrowser);
  const [serverId, setServerId] = useState(8);
  const [job, setJob] = useState('Civilian');
  const [cash, setCash] = useState(500);
  const [bank, setBank] = useState(5210);
  const [online, setOnline] = useState(1);
  const [max, setMax] = useState(10);
  const [veh, setVeh] = useState<VehData | null>(null);
  const [minimap, setMinimap] = useState(false);
  const [s, setS] = useState<StatusData>({
    health: 85,
    armor: 40,
    hunger: 72,
    thirst: 61,
    stamina: 90,
    talking: false,
    voicemode: 2,
  });

  useNuiEvent<Colors>('theme', applyTheme);
  useNuiEvent<ShowData>('show', (d) => {
    setServerId(d.serverId);
    setJob(d.job);
    setCash(d.cash);
    setBank(d.bank);
    setOnline(d.online);
    setMax(d.max);
    setVisible(true);
  });
  useNuiEvent<{ job: string }>('job', (d) => setJob(d.job));
  useNuiEvent<{ cash: number; bank: number }>('money', (d) => {
    setCash(d.cash);
    setBank(d.bank);
  });
  useNuiEvent<CountsData>('counts', (d) => {
    setOnline(d.online);
    setMax(d.max);
  });
  useNuiEvent<StatusData>('status', (d) => setS(d));
  useNuiEvent<{ visible: boolean }>('minimap', (d) => setMinimap(!!d?.visible));
  useNuiEvent<VehData>('vehicle', (d) => setVeh(d));
  useNuiEvent('vehicle:hide', () => setVeh(null));
  useNuiEvent('hide', () => setVisible(false));

  if (!visible) return null;

  return (
    <>
      {}
      <div className="info">
        <div className="cards">
          <Card Icon={FaBriefcase} label={job} />
          <Card Icon={FaDollarSign} label={money(cash)} />
          <Card Icon={FaPiggyBank} label={money(bank)} />
        </div>
        <div className="pills">
          <Pill tag="ID" value={serverId} />
          <Pill tag="ONLINE" value={`${online}/${max}`} />
        </div>
      </div>

      {}
      <div className={`hrow top${minimap ? '' : ' nomap'}`}>
        <HBar value={s.hunger} color="var(--v-hunger)" Icon={FaDrumstickBite} low />
        <HBar value={s.thirst} color="var(--v-thirst)" Icon={FaTint} low />
      </div>

      {}
      <div className="hrow bot">
        <HBar value={s.health} color="var(--v-health)" Icon={FaHeart} low />
        <HBar value={s.armor} color="var(--v-armor)" Icon={FaShieldAlt} />
      </div>

      {}
      {veh && <CarHud v={veh} />}
    </>
  );
}
