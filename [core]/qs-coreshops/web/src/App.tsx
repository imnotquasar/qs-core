import { useEffect, useState } from 'react';
import { FaStore, FaTimes } from 'react-icons/fa';
import useNuiEvent from './hooks/useNuiEvent';
import { fetchNui } from './utils/fetchNui';
import type { Colors, ShopData, ShopItem } from './types';
import './index.css';

const isBrowser = !(window as any).invokeNative;
const IMG_BASE = 'https://cfx-nui-qs-coreinventory/web/images/';

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

const money = (n: number) => '$' + (n || 0).toLocaleString('en-US');

function ItemThumb({ item }: { item: ShopItem }) {
  const [failed, setFailed] = useState(false);
  useEffect(() => setFailed(false), [item.name, item.image]);
  if (failed) return <span className="thumb-fallback">📦</span>;
  return (
    <img
      className="thumb-img"
      src={item.image || `${IMG_BASE}${item.name}.png`}
      onError={() => setFailed(true)}
      alt=""
      draggable={false}
    />
  );
}

function Card({ item, cash, onBuy, buyLabel }: { item: ShopItem; cash: number; onBuy: (name: string, count: number) => void; buyLabel: string }) {
  const [qty, setQty] = useState(1);
  const total = item.price * qty;
  const afford = cash >= total;
  return (
    <div className="card">
      <div className="thumb">
        <ItemThumb item={item} />
      </div>
      <div className="iname">{item.label}</div>
      <div className="iprice">{money(item.price)}</div>
      <div className="buyrow">
        <div className="qty">
          <button onClick={() => setQty((q) => Math.max(1, q - 1))}>−</button>
          <span className="n">{qty}</span>
          <button onClick={() => setQty((q) => Math.min(100, q + 1))}>+</button>
        </div>
        <button className={`buy ${afford ? '' : 'poor'}`} onClick={() => onBuy(item.name, qty)}>{buyLabel}</button>
      </div>
    </div>
  );
}

const DEMO: ShopData = {
  name: 'grocery',
  label: '24/7 Store',
  cash: 1250,
  items: [
    { name: 'water', label: 'Water', price: 5 },
    { name: 'bread', label: 'Bread', price: 8 },
    { name: 'sandwich', label: 'Sandwich', price: 12 },
    { name: 'cola', label: 'Cola', price: 6 },
  ],
};

export default function App() {
  const [open, setOpen] = useState(isBrowser);
  const [shop, setShop] = useState<ShopData>(DEMO);
  const [cash, setCash] = useState(DEMO.cash);

  const [loc, setLoc] = useState<Record<string, string>>({});
  const L = (k: string, fb: string) => loc[k] || fb;

  useNuiEvent<Colors>('theme', applyTheme);
  useNuiEvent<Record<string, string>>('locale', (d) => d && setLoc(d));
  useNuiEvent<ShopData>('open', (d) => {
    if (!d) return;
    setShop(d);
    setCash(d.cash || 0);
    setOpen(true);
  });
  useNuiEvent<{ cash: number }>('cash', (d) => d && setCash(d.cash || 0));
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

  const buy = (name: string, count: number) => fetchNui('buy', { name, count });

  return (
    <div className="wrap">
      <div className="shop">
        <div className="head">
          <FaStore className="head-ico" />
          <div className="titles">
            <div className="sub">{L('ui_shop', 'Shop')}</div>
            <div className="ttl">{shop.label}</div>
          </div>
          <div className="cash">
            <span className="lbl">{L('ui_cash', 'Cash')}</span>
            <span className="amt">{money(cash)}</span>
          </div>
          <button className="close" onClick={close}>
            <FaTimes />
          </button>
        </div>

        <div className="grid">
          {(shop.items || []).map((it) => (
            <Card key={it.name} item={it} cash={cash} onBuy={buy} buyLabel={L('ui_buy', 'Buy')} />
          ))}
        </div>
      </div>
    </div>
  );
}
