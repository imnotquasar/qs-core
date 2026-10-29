import { useEffect, useState } from 'react';
import { FaSkullCrossbones, FaTimes, FaCannabis, FaPills, FaFlask } from 'react-icons/fa';
import type { IconType } from 'react-icons';
import useNuiEvent from './hooks/useNuiEvent';
import { fetchNui } from './utils/fetchNui';
import type { Colors, DealerData, DrugItem } from './types';
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
    style.setProperty('--hud-accent-soft', `rgba(${a}, 0.14)`);
    style.setProperty('--hud-accent-mid', `rgba(${a}, 0.24)`);
  }
  const p = rgb(c.primary);
  if (p) style.setProperty('--hud-primary-soft', `rgba(${p}, 0.2)`);
}

const ICONS: Record<string, IconType> = {
  weed: FaCannabis,
  cocaine: FaPills,
  meth: FaFlask,
};

const money = (n: number) => '$' + (n || 0).toLocaleString('en-US');

function Row({
  item,
  onSell,
  t,
}: {
  item: DrugItem;
  onSell: (name: string, count: number) => void;
  t: (k: string, fb: string) => string;
}) {
  const [qty, setQty] = useState(1);
  useEffect(() => {
    setQty((q) => Math.min(Math.max(1, q), Math.max(1, item.count)));
  }, [item.count]);

  const Icon = ICONS[item.key] || FaSkullCrossbones;
  const has = item.count > 0;
  const clamp = (n: number) => Math.min(Math.max(1, n), Math.max(1, item.count));

  return (
    <div className={`row ${has ? '' : 'empty'}`}>
      <div className="ico">
        <Icon />
      </div>
      <div className="info">
        <div className="name">{item.label}</div>
        <div className="meta">
          <span className="price">{money(item.price)}</span> <span className="per">{t('ui_price', 'each')}</span>
          <span className="dot">•</span>
          <span className="have">
            {t('ui_have', 'You have')} {item.count}
          </span>
        </div>
      </div>

      <div className="qty">
        <button onClick={() => setQty((q) => clamp(q - 1))} disabled={!has}>−</button>
        <span className="n">{qty}</span>
        <button onClick={() => setQty((q) => clamp(q + 1))} disabled={!has}>+</button>
      </div>

      <div className="acts">
        <button className="sell" disabled={!has} onClick={() => onSell(item.name, qty)}>
          {t('ui_sell', 'Sell')} · {money(item.price * qty)}
        </button>
        <button className="sellall" disabled={!has} onClick={() => onSell(item.name, item.count)}>
          {t('ui_sellall', 'Sell all')}
        </button>
      </div>
    </div>
  );
}

const DEMO: DealerData = {
  black: 4200,
  limit: 25,
  sold: 0,
  items: [
    { key: 'weed', name: 'weed_baggie', label: 'Bag of Weed', price: 72, count: 8 },
    { key: 'cocaine', name: 'cocaine_baggie', label: 'Bag of Cocaine', price: 155, count: 3 },
    { key: 'meth', name: 'meth_baggie', label: 'Bag of Meth', price: 190, count: 0 },
  ],
};

export default function App() {
  const [open, setOpen] = useState(isBrowser);
  const [data, setData] = useState<DealerData>(DEMO);
  const [loc, setLoc] = useState<Record<string, string>>({});
  const t = (k: string, fb: string) => loc[k] || fb;

  useNuiEvent<Colors>('theme', applyTheme);
  useNuiEvent<Record<string, string>>('locale', (d) => d && setLoc(d));
  useNuiEvent<DealerData>('open', (d) => {
    if (!d) return;
    setData(d);
    setOpen(true);
  });
  useNuiEvent<DealerData>('update', (d) => d && setData((cur) => ({ ...cur, ...d })));
  useNuiEvent('close', () => setOpen(false));

  const close = () => {
    setOpen(false);
    fetchNui('close');
  };

  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') close();
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [open]);

  if (!open) return null;

  const sell = (name: string, count: number) => {
    if (count > 0) fetchNui('sell', { name, count });
  };

  const items = data.items || [];
  const anything = items.some((i) => i.count > 0);

  return (
    <div className="wrap">
      <div className="panel">
        <div className="head">
          <FaSkullCrossbones className="head-ico" />
          <div className="titles">
            <div className="sub">{t('ui_sub', 'Black Market')}</div>
            <div className="ttl">{t('ui_dealer', 'Dealer')}</div>
          </div>
          <div className="black">
            <span className="lbl">{t('ui_black', 'Dirty Cash')}</span>
            <span className="amt">{money(data.black)}</span>
          </div>
          <button className="close" onClick={close}>
            <FaTimes />
          </button>
        </div>

        <div className="list">
          {anything ? (
            items.map((it) => <Row key={it.name} item={it} onSell={sell} t={t} />)
          ) : (
            <div className="none">{t('ui_empty', 'You have nothing the dealer wants.')}</div>
          )}
        </div>
      </div>
    </div>
  );
}
