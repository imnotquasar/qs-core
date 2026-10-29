import { useEffect, useState } from 'react';
import { FaHeartbeat, FaBandAid, FaSnowflake, FaFireAlt, FaPlus, FaCheck, FaUserInjured, FaBoxOpen } from 'react-icons/fa';
import type { IconType } from 'react-icons';
import useNuiEvent from './hooks/useNuiEvent';
import { fetchNui } from './utils/fetchNui';
import type { Colors, OpenData, Positions, TreatItem } from './types';
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
}

const ITEM_ICONS: Record<string, IconType> = {
  bandage: FaBandAid,
  icepack: FaSnowflake,
  burn_cream: FaFireAlt,
};

const TYPE_COLORS: Record<string, string> = {
  bleeding: '#ff5d6c',
  bruising: '#f0a83a',
  burning: '#b07cff',
  none: 'rgba(150, 180, 220, 0.7)',
};

const REGION_ORDER = ['head', 'body', 'left_arm', 'right_arm', 'left_leg', 'right_leg'];

const DEMO: OpenData = {
  name: 'John Doe',
  downed: true,
  regions: {
    head: { type: 'bleeding', level: 2, pct: 50 },
    body: { type: 'bruising', level: 1, pct: 75 },
    left_arm: { type: 'none', level: 0, pct: 100 },
    right_arm: { type: 'burning', level: 3, pct: 25 },
    left_leg: { type: 'none', level: 0, pct: 100 },
    right_leg: { type: 'none', level: 0, pct: 100 },
  },
  items: [
    { name: 'bandage', injury: 'bleeding', count: 3 },
    { name: 'burn_cream', injury: 'burning', count: 1 },
    { name: 'icepack', injury: 'bruising', count: 2 },
  ],
};

const DEMO_POS: Positions = {
  head: { x: 52, y: 22, on: true },
  body: { x: 55, y: 42, on: true },
  left_arm: { x: 45, y: 46, on: true },
  right_arm: { x: 64, y: 40, on: true },
  left_leg: { x: 47, y: 68, on: true },
  right_leg: { x: 60, y: 70, on: true },
};

function ItemImg({ name }: { name: string }) {
  const [failed, setFailed] = useState(false);
  useEffect(() => setFailed(false), [name]);
  const Icon = ITEM_ICONS[name] || FaBandAid;
  if (failed) return <Icon className="i-ico" />;
  return <img className="i-img" src={`${IMG_BASE}${name}.png`} onError={() => setFailed(true)} alt="" draggable={false} />;
}

export default function App() {
  const [open, setOpen] = useState(isBrowser);
  const [data, setData] = useState<OpenData>(DEMO);
  const [pos, setPos] = useState<Positions>(DEMO_POS);
  const [drag, setDrag] = useState<TreatItem | null>(null);
  const [ghost, setGhost] = useState({ x: 0, y: 0 });
  const [shake, setShake] = useState<string | null>(null);
  const [loc, setLoc] = useState<Record<string, string>>({});
  const t = (k: string, fb: string) => loc[k] || fb;

  useNuiEvent<Colors>('theme', applyTheme);
  useNuiEvent<Record<string, string>>('locale', (d) => d && setLoc(d));
  useNuiEvent<OpenData>('open', (d) => {
    if (!d) return;
    setData(d);
    setOpen(true);
  });
  useNuiEvent<Partial<OpenData>>('update', (d) => d && setData((cur) => ({ ...cur, ...d })));
  useNuiEvent<Positions>('positions', (d) => d && setPos(d));
  useNuiEvent('close', () => {
    setOpen(false);
    setDrag(null);
  });

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

  useEffect(() => {
    if (!drag) return;
    const move = (e: MouseEvent) => setGhost({ x: e.clientX, y: e.clientY });
    const up = (e: MouseEvent) => {
      const el = document.elementFromPoint(e.clientX, e.clientY) as HTMLElement | null;
      const target = el?.closest('[data-region]') as HTMLElement | null;
      if (target) {
        const region = target.getAttribute('data-region')!;
        const state = data.regions[region];
        if (state && state.level > 0) {
          if (state.type === drag.injury) {
            fetchNui('treat', { item: drag.name, region });
          } else {
            setShake(region);
            window.setTimeout(() => setShake(null), 450);
          }
        }
      }
      setDrag(null);
    };
    window.addEventListener('mousemove', move);
    window.addEventListener('mouseup', up);
    return () => {
      window.removeEventListener('mousemove', move);
      window.removeEventListener('mouseup', up);
    };
  }, [drag, data]);

  if (!open) return null;

  const injuries = REGION_ORDER.filter((r) => (data.regions[r]?.level || 0) > 0);
  const GhostIcon = drag ? ITEM_ICONS[drag.name] || FaBandAid : null;
  const sevLabel = (level: number) => t('sev_' + level, ['', 'Light', 'Moderate', 'Severe', 'Critical'][level] || '');

  return (
    <div className="wrap">
      <div className="side">
        <div className="panel head-panel">
          <div className="hp-ico"><FaHeartbeat /></div>
          <div className="hp-txt">
            <div className="hp-title">{t('ui_treat_title', 'Treat Patient')}</div>
            <div className="hp-sub">{t('ui_treat_hint', "To treat the patient's injuries, drag the items to the appropriate body parts.")}</div>
            <div className="hp-name"><FaUserInjured /> {data.name}</div>
          </div>
        </div>

        <div className="panel">
          <div className="p-head">
            <FaBoxOpen className="p-ico" />
            <div>
              <div className="p-title">{t('ui_items', 'Inventory Items')}</div>
              <div className="p-sub">{t('ui_items_hint', 'Use the items to heal the injuries')}</div>
            </div>
          </div>
          <div className="items">
            {(data.items || []).map((it) => (
              <div
                key={it.name}
                className={`item ${it.count > 0 ? '' : 'empty'} ${drag?.name === it.name ? 'lift' : ''}`}
                onMouseDown={(e) => {
                  if (it.count > 0 && e.button === 0) {
                    e.preventDefault();
                    setGhost({ x: e.clientX, y: e.clientY });
                    setDrag(it);
                  }
                }}
              >
                <div className="i-thumb"><ItemImg name={it.name} /></div>
                <div className="i-body">
                  <div className="i-name">{t('item_' + it.name, it.name)}</div>
                  <div className="i-desc">{t('use_for_' + it.injury, 'Use for ' + it.injury)}</div>
                </div>
                <span className="i-count">{it.count}x</span>
              </div>
            ))}
          </div>
        </div>

        <div className="panel">
          <div className="p-head">
            <FaUserInjured className="p-ico" />
            <div>
              <div className="p-title">{t('ui_injuries', 'Injuries')}</div>
              <div className="p-sub">{t('ui_injuries_hint', 'Patient injury report')}</div>
            </div>
          </div>
          <div className="inj-list">
            {injuries.length === 0 && <div className="inj-none">{t('ui_no_injuries', 'No injuries detected.')}</div>}
            {injuries.map((r) => {
              const s = data.regions[r];
              const color = TYPE_COLORS[s.type] || TYPE_COLORS.none;
              return (
                <div key={r} className="inj" style={{ ['--c' as any]: color }}>
                  <div className="inj-row">
                    <span className="inj-region">{t('region_' + r, r)}</span>
                    <span className="inj-sev">{sevLabel(s.level)}</span>
                    <span className="inj-pct">%{100 - s.pct}</span>
                  </div>
                  <div className="inj-type">{t('ui_injury_type', 'Injury Type')}: {t('injury_' + s.type, s.type)}</div>
                  <div className="inj-bar"><div className="inj-fill" style={{ width: `${100 - s.pct}%` }} /></div>
                </div>
              );
            })}
          </div>
        </div>
      </div>

      {REGION_ORDER.map((r) => {
        const p = pos[r];
        const s = data.regions[r];
        if (!p || !p.on || !s) return null;
        const injured = s.level > 0;
        const color = injured ? TYPE_COLORS[s.type] || '#ff5d6c' : '#37e0a0';
        const RING = 2 * Math.PI * 15.5;
        return (
          <div
            key={r}
            data-region={injured ? r : undefined}
            className={`marker ${injured ? 'injured' : 'healthy'} ${drag && injured && s.type === drag.injury ? 'want' : ''} ${shake === r ? 'shake' : ''}`}
            style={{ left: `${p.x}%`, top: `${p.y}%`, ['--c' as any]: color }}
          >
            <div className="m-tag">
              <span className="m-label">{t('region_' + r, r)}</span>
              <span className="m-status">{injured ? t('injury_' + s.type, s.type) : t('m_stable', 'Stable')}</span>
            </div>
            <div className="m-node">
              <svg className="m-ring" viewBox="0 0 36 36">
                <circle className="m-ring-bg" cx="18" cy="18" r="15.5" />
                <circle
                  className="m-ring-fg"
                  cx="18"
                  cy="18"
                  r="15.5"
                  style={{ strokeDasharray: RING, strokeDashoffset: RING * (1 - s.pct / 100) }}
                />
              </svg>
              <span className="m-icon">{injured ? <FaPlus /> : <FaCheck />}</span>
            </div>
            <span className="m-pct">{s.pct}%</span>
          </div>
        );
      })}

      {drag && GhostIcon && (
        <div className="ghost" style={{ left: ghost.x, top: ghost.y }}>
          <GhostIcon />
        </div>
      )}
    </div>
  );
}
