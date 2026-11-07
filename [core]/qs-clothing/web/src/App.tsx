import { useEffect, useState, type CSSProperties } from 'react';
import {
  FaChevronLeft,
  FaChevronRight,
  FaCheck,
  FaTimes,
  FaSmile,
  FaTshirt,
  FaShoePrints,
  FaGlasses,
  FaPenNib,
  FaUsers,
  FaUserEdit,
  FaUndo,
} from 'react-icons/fa';
import useNuiEvent from './hooks/useNuiEvent';
import { fetchNui } from './utils/fetchNui';
import type { Category, Colors, Feature, Heritage, OpenData, Parent, Section, Skin, SkinEntry } from './types';
import './index.css';

const isBrowser = !(window as any).invokeNative;

const SECTION_ICON: Record<string, JSX.Element> = {
  heritage: <FaUsers />,
  features: <FaUserEdit />,
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
  { key: 'heritage', label: 'Heritage' },
  { key: 'features', label: 'Face Shape' },
  { key: 'face', label: 'Face & Hair' },
  { key: 'upper', label: 'Upper Body' },
  { key: 'lower', label: 'Lower Body' },
  { key: 'accessories', label: 'Accessories' },
  { key: 'tattoos', label: 'Tattoos' },
];
const sampleCats: Category[] = [
  { key: 'eyes', label: 'Eye Color', kind: 'eyecolor', max: 31, section: 'features' },
  { key: 'hair', label: 'Hair', kind: 'component', id: 2, max: 80, section: 'face' },
  { key: 'top', label: 'Top', kind: 'component', id: 11, max: 400, section: 'upper' },
  { key: 'legs', label: 'Legs', kind: 'component', id: 4, max: 150, section: 'lower' },
  { key: 'hat', label: 'Hat', kind: 'prop', id: 0, max: 150, section: 'accessories' },
];
const sampleFathers: Parent[] = [
  { id: 0, name: 'Benjamin' },
  { id: 1, name: 'Daniel' },
  { id: 2, name: 'Joshua' },
];
const sampleMothers: Parent[] = [
  { id: 21, name: 'Hannah' },
  { id: 22, name: 'Aubrey' },
  { id: 23, name: 'Jasmine' },
];
const sampleFeatures: Feature[] = [
  { key: 'nose_width', label: 'Nose Width' },
  { key: 'nose_height', label: 'Nose Height' },
  { key: 'nose_length', label: 'Nose Length' },
  { key: 'brow_height', label: 'Brow Height' },
  { key: 'cheekbone_height', label: 'Cheekbone Height' },
  { key: 'lip_thickness', label: 'Lip Thickness' },
  { key: 'jaw_width', label: 'Jaw Width' },
  { key: 'chin_height', label: 'Chin Height' },
];

const DEFAULT_HERITAGE: Heritage = { father: 0, mother: 21, shape: 0, skin: 0 };

function ParentCard({
  label,
  list,
  value,
  onChange,
  tone,
}: {
  label: string;
  list: Parent[];
  value: number;
  onChange: (id: number) => void;
  tone: 'father' | 'mother';
}) {
  const idx = Math.max(0, list.findIndex((p) => p.id === value));
  const cur = list[idx];
  const step = (dir: number) => {
    if (!list.length) return;
    onChange(list[wrap(idx + dir, 0, list.length - 1)].id);
  };
  return (
    <div className={`pcard ${tone}`}>
      <span className="plabel">{label}</span>
      <div className="pavatar">{cur ? cur.name.charAt(0) : '?'}</div>
      <span className="pname">{cur ? cur.name : '—'}</span>
      <div className="stepper pstep">
        <button onClick={() => step(-1)}>
          <FaChevronLeft />
        </button>
        <span className="pcount">
          {idx + 1}/{list.length}
        </span>
        <button onClick={() => step(1)}>
          <FaChevronRight />
        </button>
      </div>
    </div>
  );
}

function MixSlider({
  label,
  left,
  right,
  value,
  onChange,
}: {
  label: string;
  left: string;
  right: string;
  value: number;
  onChange: (v: number) => void;
}) {
  const pct = Math.round(value * 100);
  return (
    <div className="crow">
      <div className="srow-head">
        <span className="clabel">{label}</span>
        <span className="sval">
          {100 - pct}% · {pct}%
        </span>
      </div>
      <input
        type="range"
        className="slider mix"
        min={0}
        max={100}
        step={1}
        value={pct}
        style={{ '--pct': `${pct}%` } as CSSProperties}
        onChange={(e) => onChange(Number(e.target.value) / 100)}
      />
      <div className="slider-ends">
        <span>{left}</span>
        <span>{right}</span>
      </div>
    </div>
  );
}

function FeatureSlider({ label, value, onChange }: { label: string; value: number; onChange: (v: number) => void }) {
  const v = Math.round(value * 100);
  const pct = (v + 100) / 2;
  return (
    <div className="crow">
      <div className="srow-head">
        <span className="clabel">{label}</span>
        <span className={`sval ${v !== 0 ? 'on' : ''}`}>{v > 0 ? `+${v}` : v}</span>
      </div>
      <input
        type="range"
        className="slider center"
        min={-100}
        max={100}
        step={1}
        value={v}
        style={{ '--pct': `${pct}%` } as CSSProperties}
        onChange={(e) => onChange(Number(e.target.value) / 100)}
        onDoubleClick={() => onChange(0)}
      />
    </div>
  );
}

export default function App() {
  const [visible, setVisible] = useState(isBrowser);
  const [cats, setCats] = useState<Category[]>(sampleCats);
  const [sections, setSections] = useState<Section[]>(sampleSections);
  const [fathers, setFathers] = useState<Parent[]>(sampleFathers);
  const [mothers, setMothers] = useState<Parent[]>(sampleMothers);
  const [features, setFeatures] = useState<Feature[]>(sampleFeatures);
  const [active, setActive] = useState(isBrowser ? new URLSearchParams(location.search).get('tab') || 'heritage' : 'heritage');
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
      setFathers(d.fathers || []);
      setMothers(d.mothers || []);
      setFeatures(d.features || []);
      setCreator(!!d.creator);
      setDisabled(d.disabled || []);
      setActive(d.defaultSection || secs[0]?.key || '');
    }
    setVisible(true);
  });

  const entry = (key: string): SkinEntry => {
    const e = skin[key];
    return e && typeof e === 'object' && !Array.isArray(e) && 'drawable' in e ? (e as SkinEntry) : { drawable: 0, texture: 0 };
  };

  const heritage: Heritage = { ...DEFAULT_HERITAGE, ...(skin.heritage || {}) };
  const featureValues: number[] = features.map((_, i) => Number(skin.features?.[i]) || 0);

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

  const setHeritage = (patch: Partial<Heritage>) => {
    const next = { ...heritage, ...patch };
    setSkin((p) => ({ ...p, heritage: next }));
    fetchNui('heritage', next);
  };

  const setFeature = (i: number, value: number) => {
    setSkin((p) => {
      const list = features.map((_, j) => Number(p.features?.[j]) || 0);
      list[i] = value;
      return { ...p, features: list };
    });
    fetchNui('feature', { index: i + 1, value });
  };

  const resetFeatures = () => {
    features.forEach((_, i) => {
      if (featureValues[i] !== 0) fetchNui('feature', { index: i + 1, value: 0 });
    });
    setSkin((p) => ({ ...p, features: features.map(() => 0) }));
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
        {active === 'heritage' && (
          <>
            <div className="parents">
              <ParentCard
                tone="father"
                label={L('ui_father', 'Father')}
                list={fathers}
                value={heritage.father}
                onChange={(id) => setHeritage({ father: id })}
              />
              <ParentCard
                tone="mother"
                label={L('ui_mother', 'Mother')}
                list={mothers}
                value={heritage.mother}
                onChange={(id) => setHeritage({ mother: id })}
              />
            </div>
            <MixSlider
              label={L('ui_resemblance', 'Resemblance')}
              left={L('ui_father', 'Father')}
              right={L('ui_mother', 'Mother')}
              value={heritage.shape}
              onChange={(v) => setHeritage({ shape: v })}
            />
            <MixSlider
              label={L('ui_skintone', 'Skin Tone')}
              left={L('ui_father', 'Father')}
              right={L('ui_mother', 'Mother')}
              value={heritage.skin}
              onChange={(v) => setHeritage({ skin: v })}
            />
          </>
        )}

        {shown.map((cat) => {
          const e = entry(cat.key);
          const noTexture = cat.kind === 'tattoo' || cat.kind === 'eyecolor';
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
                {!noTexture && (
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

        {active === 'features' && (
          <>
            <div className="subhead">
              <span>{L('ui_face_shape', 'Face shape')}</span>
              <button className="reset" onClick={resetFeatures}>
                <FaUndo /> {L('ui_reset', 'Reset')}
              </button>
            </div>
            {features.map((f, i) => (
              <FeatureSlider
                key={f.key}
                label={L('feat_' + f.key, f.label)}
                value={featureValues[i]}
                onChange={(v) => setFeature(i, v)}
              />
            ))}
          </>
        )}
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
