import { useEffect, useRef, useState } from 'react';
import useNuiEvent from './hooks/useNuiEvent';
import { fetchNui } from './utils/fetchNui';
import type { Colors, NotifyData, NotifyType, Toast } from './types';
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
    '--n-success': c.health,
    '--n-primary': c.accent,
  };
  const style = document.documentElement.style;
  for (const key in map) {
    const val = map[key];
    if (val) style.setProperty(key, val);
  }
}

const TITLES: Record<NotifyType, string> = {
  success: 'Success',
  error: 'Error',
  info: 'Information',
  primary: 'Notice',
};

const CP_PRESETS = [
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
function rgbaStr(rgb: number[], a: number): string {
  return `rgba(${Math.round(rgb[0])}, ${Math.round(rgb[1])}, ${Math.round(rgb[2])}, ${a})`;
}
function buildPalette(primaryHex: string, accentHex: string): Colors {
  const p = hexToRgb(primaryHex);
  const a = hexToRgb(accentHex);
  const pd = darken(p, 0.2);
  return {
    text: '#f2f6ff',
    muted: '#97a3ba',
    primary: primaryHex,
    primaryDim: toHex(pd),
    accent: accentHex,
    gradientFrom: rgbaStr(p, 0.6),
    gradientTo: rgbaStr(pd, 0.3),
    glow: rgbaStr(p, 0.45),
    border: rgbaStr(a, 0.5),
    panel: rgbaStr(darken(p, 0.58), 0.32),
    health: '#5cf07c',
    armor: '#3b82f6',
    hunger: '#f0a83a',
    thirst: '#24c8d8',
  };
}

function ColorPicker(props: {
  primary: string;
  accent: string;
  setPrimary: (v: string) => void;
  setAccent: (v: string) => void;
  onConfirm: () => void;
  onClose: () => void;
  loc: Record<string, string>;
}) {
  const { primary, accent, setPrimary, setAccent, onConfirm, onClose, loc } = props;
  const L = (k: string, fb: string) => loc[k] || fb;
  const pal = buildPalette(primary, accent);
  const vars = {
    ['--cp-primary' as any]: pal.primary,
    ['--cp-accent' as any]: pal.accent,
    ['--cp-glow' as any]: pal.glow,
    ['--cp-border' as any]: pal.border,
    ['--cp-panel' as any]: pal.panel,
  };
  return (
    <div className="cp-wrap" style={vars}>
      <div className="cp-card">
        <div className="cp-head">
          <div className="cp-kicker">{L('cp_kicker', 'Personalize')}</div>
          <h1>{L('cp_title', 'Choose Your Colors')}</h1>
          <p>{L('cp_desc', 'Pick the palette your HUD, menus and notifications will use.')}</p>
        </div>

        <div className="cp-label">{L('cp_presets', 'Presets')}</div>
        <div className="cp-presets">
          {CP_PRESETS.map((pr) => (
            <div
              key={pr.name}
              className={`cp-sw${pr.primary === primary && pr.accent === accent ? ' on' : ''}`}
              style={{ background: `linear-gradient(135deg, ${pr.primary}, ${pr.accent})` }}
              title={pr.name}
              onClick={() => {
                setPrimary(pr.primary);
                setAccent(pr.accent);
              }}
            />
          ))}
        </div>

        <div className="cp-label">{L('cp_custom', 'Custom')}</div>
        <div className="cp-customs">
          <label className="cp-pick">
            <input type="color" value={primary} onChange={(e) => setPrimary(e.target.value)} />
            <span className="cp-pt">
              <small>{L('cp_primary', 'Primary')}</small>
              <b>{primary}</b>
            </span>
          </label>
          <label className="cp-pick">
            <input type="color" value={accent} onChange={(e) => setAccent(e.target.value)} />
            <span className="cp-pt">
              <small>{L('cp_accent', 'Accent')}</small>
              <b>{accent}</b>
            </span>
          </label>
        </div>

        <div className="cp-preview">
          <div className="cp-pv-play">▶ Play</div>
          <div className="cp-pv-info">
            <div className="cp-pv-name">{L('cp_server', 'Your Server')}</div>
            <div className="cp-pv-bar">
              <span />
            </div>
          </div>
        </div>

        <div className="cp-actions">
          <button className="cp-cancel" onClick={onClose}>
            {L('cp_cancel', 'Cancel')}
          </button>
          <button className="cp-confirm" onClick={onConfirm}>
            {L('cp_confirm', 'Confirm')}
          </button>
        </div>
      </div>
    </div>
  );
}

interface ProgressState {
  id: number;
  duration: number;
  label: string;
}

function LockpickGame({ rounds, onEnd }: { rounds: number; onEnd: (ok: boolean) => void }) {
  const [round, setRound] = useState(1);
  const [angle, setAngle] = useState(0);
  const angleRef = useRef(0);
  const target = useRef({ start: 90, size: 70 });
  const speed = useRef(2.4);
  const done = useRef(false);
  const [fb, setFb] = useState<'none' | 'hit' | 'miss'>('none');

  const newTarget = (r: number) => {
    const size = Math.max(26, 72 - (r - 1) * 11);
    const start = Math.random() * (360 - size);
    target.current = { start, size };
    speed.current = 2.4 + (r - 1) * 0.8;
  };

  useEffect(() => {
    newTarget(1);
    let raf = 0;
    const loop = () => {
      angleRef.current = (angleRef.current + speed.current) % 360;
      setAngle(angleRef.current);
      raf = requestAnimationFrame(loop);
    };
    raf = requestAnimationFrame(loop);
    return () => cancelAnimationFrame(raf);
  }, []);

  const attempt = () => {
    if (done.current) return;
    const { start, size } = target.current;
    const a = angleRef.current;
    const hit = a >= start && a <= start + size;
    if (hit) {
      setFb('hit');
      if (round >= rounds) {
        done.current = true;
        window.setTimeout(() => onEnd(true), 260);
      } else {
        const nr = round + 1;
        setRound(nr);
        newTarget(nr);
        window.setTimeout(() => setFb('none'), 170);
      }
    } else {
      done.current = true;
      setFb('miss');
      window.setTimeout(() => onEnd(false), 380);
    }
  };

  useNuiEvent('lockpick:lock', attempt);
  useNuiEvent('lockpick:cancel', () => {
    if (!done.current) {
      done.current = true;
      onEnd(false);
    }
  });

  const R = 42;
  const C = 2 * Math.PI * R;
  const arcLen = (target.current.size / 360) * C;
  const arcOffset = -((target.current.start / 360) * C);

  return (
    <div className="lp-wrap">
      <div className={`lp-card ${fb}`}>
        <div className="lp-ring">
          <svg viewBox="0 0 100 100" className="lp-svg">
            <circle className="lp-bg" cx="50" cy="50" r="47" />
            <circle className="lp-track" cx="50" cy="50" r={R} />
            <circle
              className="lp-zone"
              cx="50"
              cy="50"
              r={R}
              strokeDasharray={`${arcLen} ${C}`}
              strokeDashoffset={arcOffset}
              transform="rotate(-90 50 50)"
            />
            <g transform={`rotate(${angle} 50 50)`}>
              <line className="lp-needle" x1="50" y1="50" x2="50" y2="9" />
            </g>
            <circle className="lp-hub" cx="50" cy="50" r="4.5" />
          </svg>
        </div>
        <div className="lp-info">
          <div className="lp-round">{round} / {rounds}</div>
          <div className="lp-hint">
            <kbd>SPACE</kbd> · <kbd>ESC</kbd>
          </div>
        </div>
      </div>
    </div>
  );
}

export default function App() {
  const [toasts, setToasts] = useState<Toast[]>([]);
  const [prog, setProg] = useState<ProgressState | null>(null);
  const [percent, setPercent] = useState(0);
  const nextId = useRef(1);

  const [cpOpen, setCpOpen] = useState(false);
  const [cpPrimary, setCpPrimary] = useState('#3b82f6');
  const [cpAccent, setCpAccent] = useState('#5cbaf0');
  const [loc, setLoc] = useState<Record<string, string>>({});
  const [death, setDeath] = useState<{ seconds: number; canRespawn: boolean } | null>(isBrowser ? { seconds: 12, canRespawn: false } : null);
  const [lockpick, setLockpick] = useState<number | null>(null);

  useNuiEvent<{ rounds: number }>('lockpick:start', (d) => setLockpick(d?.rounds || 3));

  useNuiEvent<Colors>('theme', applyTheme);
  useNuiEvent<Record<string, string>>('locale', (d) => d && setLoc(d));
  useNuiEvent<{ visible: boolean; seconds: number; canRespawn: boolean }>('death', (d) => {
    setDeath(d && d.visible ? { seconds: d.seconds, canRespawn: d.canRespawn } : null);
  });
  const titleFor = (type: NotifyType) => loc[`nt_${type === 'primary' ? 'notice' : type}`] || TITLES[type];

  useNuiEvent<Colors>('colors:open', (pal) => {
    if (pal?.primary) setCpPrimary(pal.primary);
    if (pal?.accent) setCpAccent(pal.accent);
    setCpOpen(true);
  });

  const confirmColors = () => {
    const pal = buildPalette(cpPrimary, cpAccent);
    fetchNui('colors:save', pal);
    setCpOpen(false);
  };
  const closeColors = () => {
    fetchNui('colors:close');
    setCpOpen(false);
  };

  useEffect(() => {
    if (!cpOpen) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') closeColors();
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [cpOpen]);

  useNuiEvent<{ duration: number; label?: string }>('progress:start', (d) => {
    setProg({ id: Date.now(), duration: d.duration || 3000, label: d.label || '' });
  });
  useNuiEvent('progress:cancel', () => setProg(null));

  useEffect(() => {
    if (!prog) {
      setPercent(0);
      return;
    }
    const start = performance.now();
    setPercent(0);
    const iv = window.setInterval(() => {
      const p = Math.min(100, ((performance.now() - start) / prog.duration) * 100);
      setPercent(p);
      if (p >= 100) window.clearInterval(iv);
    }, 40);
    const t = window.setTimeout(() => setProg(null), prog.duration + 120);
    return () => {
      window.clearInterval(iv);
      window.clearTimeout(t);
    };
  }, [prog]);

  useNuiEvent<NotifyData>('notify', (d) => {
    if (!d || !d.message) return;
    const id = nextId.current++;
    const duration = d.duration || 4000;
    const type = d.type || 'info';
    const title = d.title || titleFor(type);
    setToasts((t) => [...t, { id, message: d.message, title, type, duration }]);
    window.setTimeout(() => {
      setToasts((t) => t.filter((x) => x.id !== id));
    }, duration);
  });

  useEffect(() => {
    fetchNui('uiReady');
    if (isBrowser) {
      setToasts([
        { id: -1, title: 'Success', message: 'Outfit saved.', type: 'success', duration: 999999 },
        { id: -2, title: 'Error', message: 'Too heavy to carry.', type: 'error', duration: 999999 },
        { id: -3, title: 'Information', message: 'This is an information message.', type: 'info', duration: 999999 },
      ]);
    }
  }, []);

  const CIRC = 2 * Math.PI * 42;

  return (
    <>
      {death && (
        <div className="death">
          <div className="death-vignette" />
          <div className="death-scanline" />
          <div className="death-content">
            <div className="death-flat" />
            <div className="death-title">{loc.death_title || 'YOU ARE DOWN'}</div>
            <div className="death-sub">{loc.death_sub || 'You are bleeding out. Hold on for the paramedics.'}</div>
            <div className="death-keys">
              <div className={`dkey ${death.canRespawn ? '' : 'locked'}`}>
                <kbd>E</kbd>
                <span>
                  {death.canRespawn
                    ? loc.death_respawn || 'Respawn at hospital'
                    : (loc.death_wait || 'You can give up in %ds').replace('%d', String(death.seconds))}
                </span>
              </div>
              <div className="dkey">
                <kbd>G</kbd>
                <span>{loc.death_ems || 'Call paramedics'}</span>
              </div>
            </div>
          </div>
        </div>
      )}

      <div className="toasts">
        {toasts.map((t) => (
          <div key={t.id} className={`toast ${t.type}`} style={{ ['--hold' as any]: `${(t.duration || 4000) - 300}ms` }}>
            <span className="tdot" />
            <div className="tbody">
              <span className="ttitle">{t.title || titleFor(t.type || 'info')}</span>
              <span className="tmsg">{t.message}</span>
            </div>
          </div>
        ))}
      </div>

      {prog && (
        <div className="pring" key={prog.id}>
          <div className="pring-circle">
            <svg className="pring-svg" viewBox="0 0 100 100">
              <circle className="pring-bg" cx="50" cy="50" r="47" />
              <circle className="pring-track" cx="50" cy="50" r="42" />
              <circle
                className="pring-bar"
                cx="50"
                cy="50"
                r="42"
                style={{ strokeDasharray: CIRC, strokeDashoffset: CIRC, ['--dur' as any]: `${prog.duration}ms` }}
              />
            </svg>
            <span className="pring-pct">{Math.round(percent)}%</span>
          </div>
          {prog.label && <div className="pring-label">{prog.label}</div>}
        </div>
      )}

      {lockpick !== null && (
        <LockpickGame
          rounds={lockpick}
          onEnd={(ok) => {
            fetchNui('lockpick:done', { success: ok });
            setLockpick(null);
          }}
        />
      )}

      {cpOpen && (
        <ColorPicker
          primary={cpPrimary}
          accent={cpAccent}
          setPrimary={setCpPrimary}
          setAccent={setCpAccent}
          onConfirm={confirmColors}
          onClose={closeColors}
          loc={loc}
        />
      )}
    </>
  );
}
