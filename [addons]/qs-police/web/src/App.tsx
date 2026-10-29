import { useEffect, useState } from 'react';
import {
  FaShieldAlt,
  FaTimes,
  FaBoxOpen,
  FaSearch,
  FaFlask,
  FaCar,
  FaCrosshairs,
  FaTint,
  FaCheck,
} from 'react-icons/fa';
import useNuiEvent from './hooks/useNuiEvent';
import { fetchNui } from './utils/fetchNui';
import type { ArmoryItem, Colors, GarageVehicle, LabItem, SearchItem, UIData } from './types';
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

function Thumb({ name }: { name: string }) {
  const [failed, setFailed] = useState(false);
  useEffect(() => setFailed(false), [name]);
  if (failed) return <span className="thumb-fallback">📦</span>;
  return <img className="thumb-img" src={`${IMG_BASE}${name}.png`} onError={() => setFailed(true)} alt="" draggable={false} />;
}

const DEMO: UIData = {
  mode: 'lab',
  items: [
    { slot: 3, info: { etype: 'casing', weapon: 'Pistol', time: '14:22', location: '105, -1941' } },
    { slot: 5, info: { etype: 'blood', dna: 'QS123ABC', time: '14:30', location: '210, -1600' } },
    { slot: 6, info: { etype: 'blood', dna: 'QS777XYZ', time: '15:01', location: '-654, -1230', analyzed: 'John Doe' } },
  ],
};

export default function App() {
  const [open, setOpen] = useState(isBrowser);
  const [data, setData] = useState<UIData>(DEMO);
  const [paused, setPaused] = useState(false);
  const [loc, setLoc] = useState<Record<string, string>>({});
  const t = (k: string, fb: string) => loc[k] || fb;

  useNuiEvent<Colors>('theme', applyTheme);
  useNuiEvent<Record<string, string>>('locale', (d) => d && setLoc(d));
  useNuiEvent<UIData>('open', (d) => {
    if (!d) return;
    setData(d);
    setOpen(true);
  });
  useNuiEvent<UIData>('update', (d) => d && setData((cur) => ({ ...cur, ...d })));
  useNuiEvent('close', () => setOpen(false));
  useNuiEvent<{ on: boolean }>('paused', (d) => setPaused(!!(d && d.on)));

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

  if (!open || paused) return null;

  const MODE_META: Record<string, { icon: any; title: string }> = {
    armory: { icon: FaBoxOpen, title: t('ui_armory', 'Armory') },
    search: { icon: FaSearch, title: t('ui_search', 'Search') },
    lab: { icon: FaFlask, title: t('ui_lab', 'Forensics Lab') },
    garage: { icon: FaCar, title: t('ui_garage', 'Garage') },
  };
  const meta = MODE_META[data.mode] || MODE_META.armory;
  const HeadIcon = meta.icon;

  return (
    <div className="wrap">
      <div className="panel">
        <div className="head">
          <FaShieldAlt className="head-ico" />
          <div className="titles">
            <div className="sub">{t('ui_police', 'Police')}</div>
            <div className="ttl">
              <HeadIcon className="ttl-ico" /> {meta.title}
              {data.mode === 'search' && data.name ? ` — ${data.name}` : ''}
            </div>
          </div>
          <button className="close" onClick={close}>
            <FaTimes />
          </button>
        </div>

        {data.mode === 'armory' && (
          <div className="grid g3">
            {((data.items as ArmoryItem[]) || []).map((it) => (
              <div key={it.name} className="card">
                <div className="thumb"><Thumb name={it.name} /></div>
                <div className="iname">{it.label}</div>
                <div className="imeta">x{it.count}</div>
                <button className="btn" onClick={() => fetchNui('take', { name: it.name })}>
                  {t('ui_take', 'Take')}
                </button>
              </div>
            ))}
          </div>
        )}

        {data.mode === 'search' && (
          <div className="grid g3">
            {((data.items as SearchItem[]) || []).length === 0 && <div className="none">{t('ui_empty', 'Nothing here.')}</div>}
            {((data.items as SearchItem[]) || []).map((it) => (
              <div key={it.slot} className="card">
                <div className="thumb"><Thumb name={it.name} /></div>
                <div className="iname">{it.label}</div>
                <div className="imeta">x{it.count}{it.info && it.info.etype ? ` · ${it.info.etype}` : ''}</div>
                <button className="btn danger" onClick={() => fetchNui('confiscate', { slot: it.slot })}>
                  {t('ui_confiscate', 'Confiscate')}
                </button>
              </div>
            ))}
          </div>
        )}

        {data.mode === 'lab' && (
          <div className="list">
            {((data.items as LabItem[]) || []).length === 0 && <div className="none">{t('ui_empty', 'Nothing here.')}</div>}
            {((data.items as LabItem[]) || []).map((it) => {
              const isBlood = it.info.etype === 'blood';
              return (
                <div key={it.slot} className="row" style={{ ['--c' as any]: isBlood ? '#ff5d6c' : '#f0a83a' }}>
                  <div className="ico">{isBlood ? <FaTint /> : <FaCrosshairs />}</div>
                  <div className="info">
                    <div className="name">{isBlood ? t('ui_blood', 'Blood Sample') : t('ui_casing', 'Bullet Casing')}</div>
                    <div className="meta">
                      {it.info.weapon && <span>{t('ui_weapon', 'Weapon')}: <b>{it.info.weapon}</b></span>}
                      {it.info.time && <span>{t('ui_time', 'Time')}: <b>{it.info.time}</b></span>}
                      {it.info.location && <span>{t('ui_location', 'Location')}: <b>{it.info.location}</b></span>}
                    </div>
                    {isBlood && (
                      <div className="meta">
                        {it.info.analyzed ? (
                          <span className="match"><FaCheck /> {t('ui_match', 'Match')}: <b>{it.info.analyzed}</b></span>
                        ) : (
                          <span className="pending">{t('ui_unanalyzed', 'Not analyzed')} · {t('ui_dna', 'DNA')}: <b>?</b></span>
                        )}
                      </div>
                    )}
                  </div>
                  {isBlood && !it.info.analyzed && (
                    <button className="btn" onClick={() => fetchNui('analyze', { slot: it.slot })}>
                      {t('ui_analyze', 'Analyze')}
                    </button>
                  )}
                </div>
              );
            })}
          </div>
        )}

        {data.mode === 'garage' && (
          <div className="grid g2">
            {((data.vehicles as GarageVehicle[]) || []).map((v) => (
              <div key={v.model} className="card veh">
                <FaCar className="veh-ico" />
                <div className="iname">{v.label}</div>
                <button className="btn" onClick={() => fetchNui('spawn', { model: v.model })}>
                  {t('ui_spawn', 'Spawn')}
                </button>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
