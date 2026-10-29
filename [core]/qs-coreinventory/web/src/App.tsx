import { useEffect, useState } from 'react';
import { FaBox } from 'react-icons/fa';
import useNuiEvent from './hooks/useNuiEvent';
import { fetchNui } from './utils/fetchNui';
import ItemImg from './ItemImg';
import Radial from './Radial';
import type { Colors, Container, InvData, InvItem, Section, Slot } from './types';
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
    '--hud-panel': c.panel,
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
    style.setProperty('--hud-accent-strong', `rgba(${a}, 0.4)`);
  }
  const p = rgb(c.primary);
  if (p) style.setProperty('--hud-primary-soft', `rgba(${p}, 0.2)`);
}

interface Menu {
  container: Container;
  slot: number;
  item: InvItem;
  x: number;
  y: number;
}

const DEMO: InvData = {
  slots: 30,
  columns: 5,
  weight: 3200,
  maxWeight: 50000,
  items: [
    { name: 'bandage', label: 'Bandage', count: 1, weight: 100, useable: true, max: 64 },
    { name: 'phone', label: 'Phone', count: 1, weight: 190, useable: true, max: 1 },
    { name: 'water', label: 'Water', count: 5, weight: 500, useable: true, max: 64 },
    { name: 'weapon_pistol', label: 'Pistol', count: 1, weight: 1000, useable: true, max: 1 },
    false,
    { name: 'bread', label: 'Bread', count: 3, weight: 150, useable: true, max: 64 },
  ],
  secondary: {
    slots: 10,
    columns: 5,
    weight: 1000,
    maxWeight: 100000,
    label: 'Trunk',
    kind: 'trunk',
    items: [{ name: 'burger', label: 'Burger', count: 2, weight: 400, useable: true, max: 64 }],
  },
};

const EMPTY: InvData = { slots: 30, columns: 5, weight: 0, maxWeight: 50000, items: [] };

interface ItemBox {
  id: number;
  name: string;
  label: string;
  image?: string;
  count: number;
  type: 'add' | 'remove';
}
let boxSeq = 0;

export default function App() {
  const [open, setOpen] = useState(isBrowser);
  const [data, setData] = useState<InvData>(isBrowser ? DEMO : EMPTY);
  const [menu, setMenu] = useState<Menu | null>(null);
  const [menuAmt, setMenuAmt] = useState(1);
  const [drag, setDrag] = useState<{ container: Container; from: number; item: InvItem } | null>(null);
  const [ghost, setGhost] = useState<{ x: number; y: number }>({ x: 0, y: 0 });
  const [over, setOver] = useState<{ c: Container; s: number } | null>(null);
  const [secondary, setSecondary] = useState<Section | null>(null);
  const [secClosing, setSecClosing] = useState(false);
  const [boxes, setBoxes] = useState<ItemBox[]>([]);
  const [loc, setLoc] = useState<Record<string, string>>({});
  const [paused, setPaused] = useState(false);
  const L = (k: string, fb: string) => loc[k] || fb;

  useNuiEvent<Colors>('theme', applyTheme);
  useNuiEvent<Record<string, string>>('locale', (d) => d && setLoc(d));
  useNuiEvent<{ on: boolean }>('paused', (d) => setPaused(!!(d && d.on)));
  useNuiEvent<InvData>('open', (d) => {
    if (d) setData(d);
    setOpen(true);
  });
  useNuiEvent<InvData>('set', (d) => d && setData(d));
  useNuiEvent('close', () => {
    setOpen(false);
    setMenu(null);
    setDrag(null);
  });

  useNuiEvent<Omit<ItemBox, 'id'>>('itembox', (d) => {
    if (!d || !d.name) return;
    const id = ++boxSeq;
    setBoxes((b) => [...b, { id, ...d }].slice(-5));
    window.setTimeout(() => setBoxes((b) => b.filter((x) => x.id !== id)), 3500);
  });

  useEffect(() => {
    if (!menu) return;
    const off = () => setMenu(null);
    window.addEventListener('click', off);
    return () => window.removeEventListener('click', off);
  }, [menu]);

  useEffect(() => {
    if (!drag) return;
    const slotUnder = (e: MouseEvent) => {
      const el = document.elementFromPoint(e.clientX, e.clientY) as HTMLElement | null;
      return el?.closest('[data-slot]') as HTMLElement | null;
    };
    const move = (e: MouseEvent) => {
      setGhost({ x: e.clientX, y: e.clientY });
      const t = slotUnder(e);
      if (t) {
        setOver({
          c: (t.getAttribute('data-container') || 'player') as Container,
          s: parseInt(t.getAttribute('data-slot') || '0', 10),
        });
      } else {
        setOver(null);
      }
    };
    const up = (e: MouseEvent) => {
      const target = slotUnder(e);
      if (target) {
        const to = parseInt(target.getAttribute('data-slot') || '0', 10);
        const toC = (target.getAttribute('data-container') || 'player') as Container;
        if (to && !(toC === drag.container && to === drag.from)) {
          fetchNui('move', { fromContainer: drag.container, from: drag.from, toContainer: toC, to });
        }
      }
      setDrag(null);
      setOver(null);
    };
    window.addEventListener('mousemove', move);
    window.addEventListener('mouseup', up);
    return () => {
      window.removeEventListener('mousemove', move);
      window.removeEventListener('mouseup', up);
    };
  }, [drag]);

  useEffect(() => {
    if (data.secondary) {
      setSecondary(data.secondary);
      setSecClosing(false);
    } else {
      setSecondary((cur) => {
        if (cur) setSecClosing(true);
        return cur;
      });
    }
  }, [data]);

  useEffect(() => {
    if (!secClosing) return;
    const id = window.setTimeout(() => {
      setSecondary(null);
      setSecClosing(false);
    }, 300);
    return () => window.clearTimeout(id);
  }, [secClosing]);

  const startDrag = (container: Container, slot: number, item: InvItem, e: React.MouseEvent) => {
    if (e.button !== 0) return;
    e.preventDefault();
    setMenu(null);
    setGhost({ x: e.clientX, y: e.clientY });
    setDrag({ container, from: slot, item });
  };

  const openMenu = (container: Container, slot: number, item: InvItem, e: React.MouseEvent) => {
    e.preventDefault();
    const MW = 150;
    const buttons = container === 'player' ? (item.useable ? 1 : 0) + 2 : 2;
    const MH = 34 + buttons * 38 + (item.count > 1 ? 42 + 38 : 0) + 12;
    let x = e.clientX;
    let y = e.clientY;
    if (x + MW > window.innerWidth) x = x - MW;
    if (y + MH > window.innerHeight) y = window.innerHeight - MH - 8;
    setMenuAmt(item.count);
    setMenu({ container, slot, item, x: Math.max(8, x), y: Math.max(8, y) });
  };

  const act = (type: 'use' | 'give' | 'drop' | 'take' | 'split', m: Menu) => {
    const amt = Math.max(1, Math.min(m.item.count, menuAmt || m.item.count));
    if (type === 'use') fetchNui('use', { slot: m.slot });
    else if (type === 'give') fetchNui('give', { slot: m.slot, count: amt });
    else if (type === 'take') fetchNui('take', { slot: m.slot, count: amt });
    else if (type === 'split') fetchNui('split', { container: m.container, slot: m.slot, count: amt });
    else fetchNui('drop', { container: m.container, slot: m.slot, count: amt });
    setMenu(null);
  };

  const renderGrid = (container: Container, sec: Section) => (
    <div
      className={`grid ${container === 'secondary' ? 'grid-scroll' : ''}`}
      style={{ ['--cols' as any]: sec.columns || 5 }}
    >
      {Array.from({ length: sec.slots || sec.items.length }).map((_, i) => {
        const slot = i + 1;
        const raw: Slot = sec.items[i];
        const item = raw && typeof raw === 'object' ? (raw as InvItem) : null;
        return (
          <div
            key={slot}
            data-container={container}
            data-slot={slot}
            className={`slot ${item ? 'filled' : ''} ${
              drag?.container === container && drag?.from === slot ? 'dragging' : ''
            } ${over?.c === container && over?.s === slot ? 'over' : ''}`}
            onMouseDown={(e) => item && startDrag(container, slot, item, e)}
            onContextMenu={(e) => item && openMenu(container, slot, item, e)}
            onDoubleClick={() => {
              if (!item) return;
              if (container === 'secondary') fetchNui('take', { slot });
              else if (item.useable) fetchNui('use', { slot });
            }}
          >
            {item && (
              <>
                <span className="slot-num">{slot}</span>
                <ItemImg item={item} />
                <span className="slot-count">{item.count}</span>
                <span className="slot-label">{item.label}</span>
              </>
            )}
          </div>
        );
      })}
    </div>
  );

  const used = (data.items || []).filter((i) => i && typeof i === 'object').length;
  const pct = Math.min(100, (data.weight / (data.maxWeight || 1)) * 100);

  if (paused) return null;

  return (
    <>
      <Radial L={L} />

      {!open && boxes.length > 0 && (
        <div className="ibox-stack">
          {boxes.map((b) => (
            <div key={b.id} className={`ibox ${b.type}`}>
              <span className="ib-dot" />
              <div className="ib-thumb">
                <ItemImg item={{ name: b.name, image: b.image } as InvItem} />
              </div>
              <div className="ib-body">
                <span className="ib-label">{b.label}</span>
                <span className="ib-act">{b.type === 'add' ? L('ui_added', 'Added') : L('ui_removed', 'Removed')}</span>
              </div>
              <span className="ib-count">
                {b.type === 'add' ? '+' : '−'}
                {b.count}
              </span>
            </div>
          ))}
        </div>
      )}

      {open && (
        <div className={`wrap ${drag ? 'dragging' : ''}`}>
          <div className={`panel ${secondary ? 'has-trunk' : ''}`}>
        <div className="head">
          <div className="title">
            <FaBox className="title-ico" />
            <span>{L('ui_title', 'Inventory')}</span>
          </div>
          <button className="closebtn" onClick={() => fetchNui('close')}>
            ✕
          </button>
        </div>

        <div className="meta">
          <span className="used">
            {used}/{data.slots} {L('ui_slots', 'slots')}
          </span>
          <span className="wt">
            {(data.weight / 1000).toFixed(1)} / {(data.maxWeight / 1000).toFixed(0)} kg
          </span>
        </div>
        <div className="wbar">
          <div className="wfill" style={{ width: `${pct}%` }} />
        </div>

        {renderGrid('player', data)}

        {secondary && (
          <div className={`section ${secClosing ? 'closing' : ''}`}>
            <div className="sec-head">
              <span>{secondary.label || L('ui_storage', 'Storage')}</span>
              <span className="sec-wt">
                {(secondary.weight / 1000).toFixed(1)} / {(secondary.maxWeight / 1000).toFixed(0)} kg
              </span>
            </div>
            {renderGrid('secondary', secondary)}
          </div>
        )}
      </div>

      {drag && (
        <div className="ghost" style={{ left: ghost.x, top: ghost.y }}>
          <ItemImg item={drag.item} />
        </div>
      )}

      {menu && (
        <div className="menu" style={{ left: menu.x, top: menu.y }} onClick={(e) => e.stopPropagation()}>
          <div className="menu-head">{menu.item.label}</div>
          {menu.item.count > 1 && (
            <div className="menu-amt">
              <button onClick={() => setMenuAmt((a) => Math.max(1, a - 1))}>−</button>
              <input
                type="number"
                min={1}
                max={menu.item.count}
                value={menuAmt}
                onChange={(e) => setMenuAmt(Math.max(1, Math.min(menu.item.count, Number(e.target.value) || 1)))}
              />
              <button onClick={() => setMenuAmt((a) => Math.min(menu.item.count, a + 1))}>+</button>
              <span className="menu-max" onClick={() => setMenuAmt(menu.item.count)}>/{menu.item.count}</span>
            </div>
          )}
          {menu.item.count > 1 && (
            <button className="menu-item" onClick={() => act('split', menu)}>{L('ui_split', 'Split')}</button>
          )}
          {menu.container === 'player' ? (
            <>
              {menu.item.useable && (
                <button className="menu-item" onClick={() => act('use', menu)}>{L('ui_use', 'Use')}</button>
              )}
              <button className="menu-item" onClick={() => act('give', menu)}>{L('ui_give', 'Give')}</button>
              <button className="menu-item danger" onClick={() => act('drop', menu)}>{L('ui_drop', 'Drop')}</button>
            </>
          ) : (
            <>
              <button className="menu-item" onClick={() => act('take', menu)}>{L('ui_take', 'Take')}</button>
              <button className="menu-item danger" onClick={() => act('drop', menu)}>{L('ui_drop', 'Drop')}</button>
            </>
          )}
        </div>
      )}
        </div>
      )}
    </>
  );
}
