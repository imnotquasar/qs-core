import { useEffect, useMemo, useState } from 'react';
import { FaCarSide, FaTimes, FaWallet, FaUniversity, FaCheck } from 'react-icons/fa';
import useNuiEvent from './hooks/useNuiEvent';
import { fetchNui } from './utils/fetchNui';
import type { Colors, ShopData, Vehicle, Locale } from './types';
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

const money = (n: number) => '$' + (n || 0).toLocaleString('en-US');

const DEMO: ShopData = {
  categories: [
    { id: 'sports', label: 'Sports' },
    { id: 'suvs', label: 'SUVs' },
    { id: 'sedans', label: 'Sedans' },
  ],
  vehicles: {
    sports: [
      { model: 'sultan', label: 'Karin Sultan', price: 45000 },
      { model: 'kuruma', label: 'Karin Kuruma', price: 52000 },
      { model: 'jester', label: 'Dinka Jester', price: 78000 },
    ],
    suvs: [{ model: 'baller', label: 'Gallivanter Baller', price: 55000 }],
    sedans: [{ model: 'asea', label: 'Declasse Asea', price: 12000 }],
  },
  cash: 25000,
  bank: 90000,
};

export default function App() {
  const [open, setOpen] = useState(isBrowser);
  const [data, setData] = useState<ShopData>(DEMO);
  const [cat, setCat] = useState<string>(DEMO.categories[0]?.id || '');
  const [model, setModel] = useState<string>(DEMO.vehicles[DEMO.categories[0]?.id]?.[0]?.model || '');
  const [locale, setLocale] = useState<Locale>({});

  const L = (k: string, fb: string) => locale[k] || fb;

  useNuiEvent<Colors>('theme', applyTheme);
  useNuiEvent<Locale>('locale', (l) => l && setLocale(l));
  useNuiEvent<ShopData>('open', (d) => {
    if (!d) return;
    setData(d);
    const firstCat = d.categories[0]?.id || '';
    setCat(firstCat);
    setModel(d.vehicles[firstCat]?.[0]?.model || '');
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

  const list = data.vehicles[cat] || [];
  const selected: Vehicle | undefined = useMemo(
    () => Object.values(data.vehicles).flat().find((v) => v.model === model),
    [data, model],
  );
  const afford = selected ? Math.max(data.cash, data.bank) >= selected.price : false;

  const pick = (m: string) => {
    if (m === model) return;
    setModel(m);
    fetchNui('preview', { model: m });
  };

  const buy = () => {
    if (selected && afford) fetchNui('buy', { model: selected.model });
  };

  if (!open) return null;

  return (
    <div className="wrap">
      <aside className="panel">
        <header className="phead">
          <div className="brand">
            <FaCarSide className="brand-ic" />
            <span>{L('ui_title', 'Dealership')}</span>
          </div>
          <button className="xbtn" onClick={close} title={L('ui_close', 'Close')}>
            <FaTimes />
          </button>
        </header>

        <div className="wallet">
          <div className="wchip">
            <FaWallet />
            <div>
              <span className="wlabel">{L('ui_cash', 'Cash')}</span>
              <span className="wval">{money(data.cash)}</span>
            </div>
          </div>
          <div className="wchip">
            <FaUniversity />
            <div>
              <span className="wlabel">{L('ui_bank', 'Bank')}</span>
              <span className="wval">{money(data.bank)}</span>
            </div>
          </div>
        </div>

        <nav className="tabs">
          {data.categories.map((c) => (
            <button
              key={c.id}
              className={`tab ${c.id === cat ? 'on' : ''}`}
              onClick={() => {
                setCat(c.id);
                const first = data.vehicles[c.id]?.[0]?.model;
                if (first) pick(first);
              }}
            >
              {c.label}
            </button>
          ))}
        </nav>

        <div className="list">
          {list.map((v) => (
            <button
              key={v.model}
              className={`row ${v.model === model ? 'active' : ''}`}
              onClick={() => pick(v.model)}
            >
              <span className="rname">{v.label}</span>
              <span className="rprice">{money(v.price)}</span>
            </button>
          ))}
        </div>

        {selected && (
          <footer className="foot">
            <div className="fdetail">
              <span className="fname">{selected.label}</span>
              <span className="fprice">{money(selected.price)}</span>
            </div>
            <button className={`buy ${afford ? '' : 'poor'}`} onClick={buy} disabled={!afford}>
              {afford ? (
                <>
                  <FaCheck /> {L('ui_buy', 'Buy')}
                </>
              ) : (
                L('no_money', 'Not enough money')
              )}
            </button>
          </footer>
        )}
      </aside>
    </div>
  );
}
