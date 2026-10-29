import { useEffect, useState } from 'react';
import { FaChevronLeft, FaChevronRight, FaCheck, FaTimes, FaSmile, FaTshirt, FaShoePrints, FaGlasses, FaPenNib } from 'react-icons/fa';
import useNuiEvent from './hooks/useNuiEvent';
import { fetchNui } from './utils/fetchNui';
import type { Category, Colors, OpenData, Section, Skin, SkinEntry } from './types';
import './index.css';

const isBrowser = !(window as any).invokeNative;

const SECTION_ICON: Record<string, JSX.Element> = {
  face: <FaSmile />,
  upper: <FaTshirt />,
  lower: <FaShoePrints />,
  accessories: <FaGlasses />,
  tattoos: <FaPenNib />,
};

function applyTheme(c: Colors) {
  if (!c) return;
  const map: Record<string, string | undefined> = {
    '--hud-text': c.text,
    '--hud-muted': c.muted,
    '--hud-primary': c.primary,
    '--hud-primary-dim': c.primaryDim,
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
    style.setProperty('--hud-accent-strong', `rgba(${a}, 0.4)`);
  }
  const p = rgb(c.primary);
  if (p) style.setProperty('--hud-primary-soft', `rgba(${p}, 0.2)`);
}

const wrap = (v: number, min: number, max: number) => (v < min ? max : v > max ? min : v);

const sampleSections: Section[] = [
  { key: 'face', label: 'Face & Hair' },
  { key: 'upper', label: 'Upper Body' },
  { key: 'lower', label: 'Lower Body' },
  { key: 'accessories', label: 'Accessories' },
];
const sampleCats: Category[] = [
  { key: 'hair', label: 'Hair', kind: 'component', id: 2, max: 80, section: 'face' },
  { key: 'top', label: 'Top', kind: 'component', id: 11, max: 400, section: 'upper' },
  { key: 'legs', label: 'Legs', kind: 'component', id: 4, max: 150, section: 'lower' },
  { key: 'hat', label: 'Hat', kind: 'prop', id: 0, max: 150, section: 'accessories' },
];

export default function App() {
  const [visible, setVisible] = useState(isBrowser);
  const [cats, setCats] = useState<Category[]>(sampleCats);
  const [sections, setSections] = useState<Section[]>(sampleSections);
  const [active, setActive] = useState('face');
  const [creator, setCreator] = useState(isBrowser);
  const [skin, setSkin] = useState<Skin>({ sex: 'male' });
  const [disabled, setDisabled] = useState<string[]>([]);

  const [loc, setLoc] = useState<Record<string, string>>({});
  const L = (k: string, fb: string) => loc[k] || fb;

  useNuiEvent<Colors>('theme', applyTheme);
  useNuiEvent<Record<string, string>>('locale', (d) => d && setLoc(d));
  useNuiEvent<OpenData>('open', (d) => {
    if (d) {
      setCats(d.categories || []);
      setSkin(d.skin || {});
      const secs = d.sections || [];
      setSections(secs);
      setCreator(!!d.creator);
      setDisabled(d.disabled || []);
      setActive(d.defaultSection || secs[0]?.key || '');
    }
    setVisible(true);
  });

  const entry = (key: string): SkinEntry => {
    const e = skin[key];
    return e && typeof e === 'object' ? (e as SkinEntry) : { drawable: 0, texture: 0 };
  };

  const change = (cat: Category, field: 'drawable' | 'texture', dir: number) => {
    const cur = entry(cat.key);
    const next: SkinEntry = { ...cur };
    if (field === 'drawable') {
      const min = cat.kind === 'prop' || cat.kind === 'overlay' ? -1 : 0;
      next.drawable = wrap(cur.drawable + dir, min, cat.max);
      next.texture = 0;
    } else {
      next.texture = wrap(cur.texture + dir, 0, 15);
    }
    setSkin((p) => ({ ...p, [cat.key]: next }));
    fetchNui('change', { key: cat.key, drawable: next.drawable, texture: next.texture });
  };

  const close = (persist: boolean) => {
    setVisible(false);
    fetchNui(persist ? 'save' : 'cancel', persist ? { skin } : undefined);
  };

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && visible) close(false);
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);

  }, [visible, skin]);

  if (!visible) return null;

  const firstSection = sections[0]?.key;
  const shown = cats.filter((c) => (c.section || firstSection) === active);

  return (
    <div className="editor">
      <div className="ehead">
        <span className="etitle">{creator ? L('ui_create', 'Create character') : L('ui_appearance', 'Appearance')}</span>
        <div className="rotate">
          <button onClick={() => fetchNui('rotate', { dir: -1 })} aria-label={L('ui_rotate_l', 'Rotate left')}>
            <FaChevronLeft />
          </button>
          <button onClick={() => fetchNui('rotate', { dir: 1 })} aria-label={L('ui_rotate_r', 'Rotate right')}>
            <FaChevronRight />
          </button>
        </div>
      </div>

      <div className="tabs">
        {sections.map((s) => {
          const off = disabled.includes(s.key);
          return (
            <button
              key={s.key}
              className={`tab ${active === s.key ? 'active' : ''} ${off ? 'disabled' : ''}`}
              disabled={off}
              onClick={() => {
                if (off) return;
                setActive(s.key);
                fetchNui('section', { key: s.key });
              }}
            >
              <span className="tab-ico">{SECTION_ICON[s.key] || <FaTshirt />}</span>
              <span className="tab-label">{L('tab_' + s.key, s.label)}</span>
            </button>
          );
        })}
      </div>

      <div className="rows">
        {shown.map((cat) => {
          const e = entry(cat.key);
          return (
            <div className="crow" key={cat.key}>
              <span className="clabel">{L('cat_' + cat.key, cat.label)}</span>
              <div className="ctrls">
                <div className="stepper">
                  <button onClick={() => change(cat, 'drawable', -1)}>
                    <FaChevronLeft />
                  </button>
                  <span className="val">{cat.kind === 'tattoo' && e.drawable === 0 ? '—' : e.drawable}</span>
                  <button onClick={() => change(cat, 'drawable', 1)}>
                    <FaChevronRight />
                  </button>
                </div>
                {cat.kind !== 'tattoo' && (
                  <div className="stepper tex">
                    <span className="texlbl">{L('ui_tex', 'Tex')}</span>
                    <button onClick={() => change(cat, 'texture', -1)}>
                      <FaChevronLeft />
                    </button>
                    <span className="val">{e.texture}</span>
                    <button onClick={() => change(cat, 'texture', 1)}>
                      <FaChevronRight />
                    </button>
                  </div>
                )}
              </div>
            </div>
          );
        })}
      </div>

      <div className="efoot">
        <button className="btn ghost" onClick={() => close(false)}>
          <FaTimes /> {L('ui_cancel', 'Cancel')}
        </button>
        <button className="btn primary" onClick={() => close(true)}>
          <FaCheck /> {creator ? L('ui_confirm', 'Confirm') : L('ui_save', 'Save')}
        </button>
      </div>
    </div>
  );
}
