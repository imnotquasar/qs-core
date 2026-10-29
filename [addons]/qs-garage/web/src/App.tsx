import { useEffect, useState } from 'react';
import { FaWarehouse, FaTimes, FaCarSide, FaGasPump, FaCogs, FaCarCrash, FaSignOutAlt } from 'react-icons/fa';
import useNuiEvent from './hooks/useNuiEvent';
import { fetchNui } from './utils/fetchNui';
import type { Colors, GarageData, Vehicle, Locale } from './types';
import './index.css';

const isBrowser = !(window as any).invokeNative;

function applyTheme(c: Colors) {
  if (!c) return;
  const map: Record<string, string | undefined> = {
    '--hud-text': c.text,
    '--hud-muted': c.muted,
    '--hud-primary': c.primary,
    '--hud-accent': c.accent,
    '--hud-glow': c.glow,
    '--hud-border': c.border,
  };
  const style = document.documentElement.style;
  for (const key in map) {
    const val = map[key];
    if (val) style.setProperty(key, val);
  }
  const rgb = (hex?: string): string | null => {
    if (!hex || hex[0] !== '#' || hex.length < 7) return null;
    const n = parseInt(hex.slice(1, 7), 16);
    return `${(n >> 16) & 255}, ${(n >> 8) & 255}, ${n & 255}`;
  };
  const a = rgb(c.accent);
  if (a) {
    style.setProperty('--hud-accent-soft', `rgba(${a}, 0.16)`);
    style.setProperty('--hud-accent-mid', `rgba(${a}, 0.3)`);
  }
  const p = rgb(c.primary);
  if (p) style.setProperty('--hud-primary-soft', `rgba(${p}, 0.22)`);
}

const prettyModel = (m: string) => (m || '').replace(/_/g, ' ').toUpperCase();
const pct = (n: number, max: number) => Math.max(0, Math.min(100, Math.round((n / max) * 100)));

const DEMO: GarageData = {
  label: 'Legion Square Garage',
  vehicles: [
    { plate: 'QS12ABC', model: 'sultan', state: 1, fuel: 82, engine: 940, body: 1000 },
    { plate: 'QS9XY7Z', model: 'kuruma', state: 0, fuel: 40, engine: 600, body: 720 },
    { plate: 'QSK4M9P', model: 'baller', state: 1, fuel: 100, engine: 1000, body: 1000 },
  ],
};

function Bar({ value, tone }: { value: number; tone: string }) {
  return (
    <div className="bar">
      <span className="bar-fill" style={{ width: `${value}%`, background: tone }} />
    </div>
  );
}

export default function App() {
  const [open, setOpen] = useState(isBrowser);
  const [data, setData] = useState<GarageData>(DEMO);
  const [plate, setPlate] = useState<string>(DEMO.vehicles[0]?.plate || '');
  const [locale, setLocale] = useState<Locale>({});

  const L = (k: string, fb: string) => locale[k] || fb;

  useNuiEvent<Colors>('theme', applyTheme);
  useNuiEvent<Locale>('locale', (l) => l && setLocale(l));
  useNuiEvent<GarageData>('open', (d) => {
    if (!d) return;
    setData(d);
    setPlate(d.vehicles[0]?.plate || '');
    setOpen(true);
  });
  useNuiEvent('close', () => setOpen(false));

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') close();
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, []);

  const close = () => {
    setOpen(false);
    fetchNui('close');
  };

  const pick = (p: string) => {
    if (p === plate) return;
    setPlate(p);
    fetchNui('select', { plate: p });
  };

  const selected: Vehicle | undefined = data.vehicles.find((v) => v.plate === plate);

  const takeout = () => {
    if (selected) fetchNui('takeout', { plate: selected.plate });
  };

  if (!open) return null;

  return (
    <div className="wrap">
      <aside className="panel">
        <header className="phead">
          <div className="brand">
            <FaWarehouse className="brand-ic" />
            <span>{data.label || L('ui_title', 'Garage')}</span>
          </div>
          <button className="xbtn" onClick={close} title={L('ui_close', 'Close')}>
            <FaTimes />
          </button>
        </header>

        {data.vehicles.length === 0 ? (
          <div className="empty">
            <FaCarSide />
            <span>{L('ui_empty', 'No vehicles in this garage.')}</span>
          </div>
        ) : (
          <>
            <div className="list">
              {data.vehicles.map((v) => (
                <button
                  key={v.plate}
                  className={`row ${v.plate === plate ? 'active' : ''}`}
                  onClick={() => pick(v.plate)}
                >
                  <div className="rmain">
                    <span className="rname">{prettyModel(v.model)}</span>
                    <span className="rplate">{v.plate}</span>
                  </div>
                  <span className={`badge ${v.state === 1 ? 'in' : 'out'}`}>
                    {v.state === 1 ? L('ui_stored', 'Stored') : L('ui_out', 'Out')}
                  </span>
                </button>
              ))}
            </div>

            {selected && (
              <footer className="foot">
                <div className="fname">{prettyModel(selected.model)}</div>
                <div className="fplate">{L('ui_plate', 'Plate')}: {selected.plate}</div>

                <div className="stat">
                  <FaGasPump /> <span className="slabel">{L('ui_fuel', 'Fuel')}</span>
                  <Bar value={pct(selected.fuel, 100)} tone="linear-gradient(90deg,#f0a04b,#f5c96b)" />
                </div>
                <div className="stat">
                  <FaCogs /> <span className="slabel">{L('ui_engine', 'Engine')}</span>
                  <Bar value={pct(selected.engine, 1000)} tone="linear-gradient(90deg,var(--hud-primary),var(--hud-accent))" />
                </div>
                <div className="stat">
                  <FaCarCrash /> <span className="slabel">{L('ui_body', 'Body')}</span>
                  <Bar value={pct(selected.body, 1000)} tone="linear-gradient(90deg,#5ad19b,#8ee7bd)" />
                </div>

                <button className="buy" onClick={takeout}>
                  <FaSignOutAlt /> {L('ui_takeout', 'Take out')}
                </button>
              </footer>
            )}
          </>
        )}
      </aside>
    </div>
  );
}
