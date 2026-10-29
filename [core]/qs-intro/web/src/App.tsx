import { useEffect, useState } from 'react';
import useNuiEvent from './hooks/useNuiEvent';
import { fetchNui } from './utils/fetchNui';
import type { Palette } from './types';
import './index.css';

const isBrowser = !(window as any).invokeNative;

const PRESETS = [
  { name: 'ocean', primary: '#3b82f6', accent: '#5cbaf0' },
  { name: 'cyan', primary: '#06b6d4', accent: '#22d3ee' },
  { name: 'emerald', primary: '#10b981', accent: '#34d399' },
  { name: 'violet', primary: '#8b5cf6', accent: '#a78bfa' },
  { name: 'rose', primary: '#ec4899', accent: '#f472b6' },
  { name: 'crimson', primary: '#ef4444', accent: '#f87171' },
  { name: 'amber', primary: '#f59e0b', accent: '#fbbf24' },
  { name: 'slate', primary: '#64748b', accent: '#94a3b8' },
];

function hexToRgb(h: string): number[] {
  h = h.replace('#', '');
  return [parseInt(h.slice(0, 2), 16), parseInt(h.slice(2, 4), 16), parseInt(h.slice(4, 6), 16)];
}
function toHex(rgb: number[]): string {
  return '#' + rgb.map((x) => Math.max(0, Math.min(255, Math.round(x))).toString(16).padStart(2, '0')).join('');
}
function darken(rgb: number[], f: number): number[] {
  return rgb.map((x) => x * (1 - f));
}
function rgba(rgb: number[], a: number): string {
  return `rgba(${Math.round(rgb[0])}, ${Math.round(rgb[1])}, ${Math.round(rgb[2])}, ${a})`;
}

function buildPalette(primaryHex: string, accentHex: string): Palette {
  const p = hexToRgb(primaryHex);
  const a = hexToRgb(accentHex);
  const pd = darken(p, 0.2);
  return {
    name: 'custom',
    text: '#f2f6ff',
    muted: '#97a3ba',
    primary: primaryHex,
    primaryDim: toHex(pd),
    accent: accentHex,
    gradientFrom: rgba(p, 0.6),
    gradientTo: rgba(pd, 0.3),
    glow: rgba(p, 0.45),
    border: rgba(a, 0.5),
    panel: rgba(darken(p, 0.58), 0.32),
    health: '#5cf07c',
    armor: '#3b82f6',
    hunger: '#f0a83a',
    thirst: '#24c8d8',
  };
}

export default function App() {
  const [open, setOpen] = useState(isBrowser);
  const [primary, setPrimary] = useState('#3b82f6');
  const [accent, setAccent] = useState('#5cbaf0');
  const [loc, setLoc] = useState<Record<string, string>>({});
  const L = (k: string, fb: string) => loc[k] || fb;

  useNuiEvent<Palette>('theme', (d) => {
    if (d?.primary) setPrimary(d.primary);
    if (d?.accent) setAccent(d.accent);
  });
  useNuiEvent<Record<string, string>>('locale', (d) => d && setLoc(d));
  useNuiEvent('open', () => setOpen(true));
  useNuiEvent('close', () => setOpen(false));

  useEffect(() => {
    const pal = buildPalette(primary, accent);
    const r = document.documentElement.style;
    r.setProperty('--c-primary', pal.primary);
    r.setProperty('--c-accent', pal.accent);
    r.setProperty('--c-glow', pal.glow!);
    r.setProperty('--c-border', pal.border!);
    r.setProperty('--c-panel', pal.panel!);
  }, [primary, accent]);

  if (!open) return null;

  const confirm = () => {
    fetchNui('confirm', { palette: buildPalette(primary, accent) });
    setOpen(false);
  };

  return (
    <div className="wrap show">
      <div className="card">
        <div className="head">
          <div className="kicker">{L('cp_welcome', 'Welcome')}</div>
          <h1>{L('cp_title', 'Choose Your Colors')}</h1>
          <p>{L('cp_desc', 'Pick the palette your whole HUD, menus and notifications will use.')}</p>
        </div>

        <div className="label">{L('cp_presets', 'Presets')}</div>
        <div className="presets">
          {PRESETS.map((pr) => (
            <div
              key={pr.name}
              className={`sw${pr.primary === primary && pr.accent === accent ? ' on' : ''}`}
              style={{ background: `linear-gradient(135deg, ${pr.primary}, ${pr.accent})` }}
              title={pr.name}
              onClick={() => {
                setPrimary(pr.primary);
                setAccent(pr.accent);
              }}
            />
          ))}
        </div>

        <div className="label">{L('cp_custom', 'Custom')}</div>
        <div className="customs">
          <label className="pick">
            <input type="color" value={primary} onChange={(e) => setPrimary(e.target.value)} />
            <span className="pt">
              <small>{L('cp_primary', 'Primary')}</small>
              <b>{primary}</b>
            </span>
          </label>
          <label className="pick">
            <input type="color" value={accent} onChange={(e) => setAccent(e.target.value)} />
            <span className="pt">
              <small>{L('cp_accent', 'Accent')}</small>
              <b>{accent}</b>
            </span>
          </label>
        </div>

        <div className="preview">
          <div className="pv-play">▶ Play</div>
          <div className="pv-info">
            <div className="pv-name">{L('cp_server', 'Your Server')}</div>
            <div className="pv-bar">
              <span />
            </div>
          </div>
        </div>

        <button className="confirm" onClick={confirm}>
          {L('cp_confirm', 'Confirm')}
        </button>
      </div>
    </div>
  );
}
