import { useEffect, useState } from 'react';
import { FaBriefcase, FaTimes, FaTruck, FaHardHat, FaTree, FaFish, FaCheck, FaBoxOpen } from 'react-icons/fa';
import type { IconType } from 'react-icons';
import useNuiEvent from './hooks/useNuiEvent';
import { fetchNui } from './utils/fetchNui';
import type { CenterData, CenterJob, Colors, ShiftData } from './types';
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
  delivery: FaTruck,
  miner: FaHardHat,
  lumberjack: FaTree,
  fisher: FaFish,
};

const money = (n: number) => '$' + (n || 0).toLocaleString('en-US');

const DEMO: CenterData = {
  current: 'miner',
  jobs: [
    { key: 'delivery', label: 'Delivery Driver', salary: 200 },
    { key: 'miner', label: 'Miner', salary: 175 },
    { key: 'lumberjack', label: 'Lumberjack', salary: 175 },
    { key: 'fisher', label: 'Fisherman', salary: 150 },
  ],
};

function JobCard({
  job,
  current,
  t,
  onApply,
}: {
  job: CenterJob;
  current: boolean;
  t: (k: string, fb: string) => string;
  onApply: (key: string) => void;
}) {
  const Icon = ICONS[job.key] || FaBriefcase;
  return (
    <div className={`card ${current ? 'current' : ''}`}>
      {current && (
        <div className="badge">
          <FaCheck /> {t('ui_current', 'Current job')}
        </div>
      )}
      <div className="card-ico">
        <Icon />
      </div>
      <div className="card-name">{job.label}</div>
      <div className="card-desc">{t('desc_' + job.key, '')}</div>
      <div className="card-foot">
        <span className="salary">
          {money(job.salary)} <em>/ {t('ui_salary', 'paycheck')}</em>
        </span>
        {current ? (
          <button className="btn quit" onClick={() => onApply('unemployed')}>
            {t('ui_quit', 'Quit job')}
          </button>
        ) : (
          <button className="btn" onClick={() => onApply(job.key)}>
            {t('ui_apply', 'Apply')}
          </button>
        )}
      </div>
    </div>
  );
}

export default function App() {
  const [open, setOpen] = useState(isBrowser);
  const [data, setData] = useState<CenterData>(DEMO);
  const [shift, setShift] = useState<ShiftData>({ on: isBrowser, done: 2, total: 5, earned: 120 });
  const [paused, setPaused] = useState(false);
  const [loc, setLoc] = useState<Record<string, string>>({});
  const t = (k: string, fb: string) => loc[k] || fb;

  useNuiEvent<Colors>('theme', applyTheme);
  useNuiEvent<Record<string, string>>('locale', (d) => d && setLoc(d));
  useNuiEvent<CenterData>('open', (d) => {
    if (!d) return;
    setData(d);
    setOpen(true);
  });
  useNuiEvent('close', () => setOpen(false));
  useNuiEvent<ShiftData>('shift', (d) => d && setShift(d));
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

  const apply = (key: string) => fetchNui('apply', { job: key });

  if (paused) return null;

  return (
    <>
      {shift.on && (
        <div className="widget">
          <FaBoxOpen className="w-ico" />
          <span className="w-label">{t('ui_shift', 'Deliveries')}</span>
          <span className="w-count">
            {shift.done || 0}/{shift.total || 0}
          </span>
          <span className="w-sep" />
          <span className="w-label">{t('ui_earned', 'Earned')}</span>
          <span className="w-cash">{money(shift.earned || 0)}</span>
        </div>
      )}

      {open && (
        <div className="wrap">
          <div className="panel">
            <div className="head">
              <FaBriefcase className="head-ico" />
              <div className="titles">
                <div className="sub">{t('ui_center_sub', 'Employment Office')}</div>
                <div className="ttl">{t('ui_center', 'Job Center')}</div>
              </div>
              <button className="close" onClick={close}>
                <FaTimes />
              </button>
            </div>

            <div className="grid">
              {(data.jobs || []).map((j) => (
                <JobCard key={j.key} job={j} current={data.current === j.key} t={t} onApply={apply} />
              ))}
            </div>
          </div>
        </div>
      )}
    </>
  );
}
