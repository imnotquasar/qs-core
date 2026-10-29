import { useEffect, useState } from 'react';
import {
  FaChevronLeft,
  FaChevronRight,
  FaChevronDown,
  FaArrowLeft,
  FaRegAddressCard,
  FaCalendarAlt,
  FaFlag,
  FaMars,
  FaVenus,
  FaVenusMars,
  FaPlay,
  FaPlus,
  FaTrashAlt,
  FaSignOutAlt,
} from 'react-icons/fa';
import useNuiEvent from './hooks/useNuiEvent';
import { fetchNui } from './utils/fetchNui';
import type { Character, Colors, Loc, OpenData, SetCharactersData } from './types';
import './index.css';

const isBrowser = !(window as any).invokeNative;

const DEFAULT_T: Loc = {
  select_title: 'Select your character',
  create_title: 'Character creation',
  create_subtitle: 'Create your character to begin your adventure in our city.',
  create_slot: 'Create character',
  civilian: 'Civilian',
  firstname: 'First name',
  lastname: 'Last name',
  dob: 'Date of birth',
  nationality: 'Nationality',
  sex: 'Gender',
  male: 'Male',
  female: 'Female',
  day: 'Day',
  month: 'Month',
  year: 'Year',
  back: 'Back',
  create: 'Create my character',
  select: 'Select',
  play: 'Play',
  delete: 'Delete',
  settings: 'Settings',
  quit: 'Quit game',
  pose: 'Change pose',
  delete_confirm: 'Delete?',
  confirm_delete_msg: 'This character will be permanently deleted. This cannot be undone.',
  confirm_quit_msg: 'Are you sure you want to quit the game?',
  confirm_yes: 'Confirm',
  confirm_no: 'Cancel',
  months: ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
  err_invalid_input: 'Please fill in first and last name.',
  err_max_characters: 'You have reached the character limit.',
  err_no_license: 'Could not read your license.',
  err_not_found: 'Character not found.',
  err_not_owner: 'That character is not yours.',
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

const pad = (n: number) => String(n).padStart(2, '0');

interface Opt {
  value: string;
  label: string;
}

function Dropdown({ value, options, placeholder, onChange }: { value: string; options: Opt[]; placeholder: string; onChange: (v: string) => void }) {
  const [open, setOpen] = useState(false);
  const selected = options.find((o) => o.value === value);
  return (
    <div className={`dd ${open ? 'open' : ''}`}>
      <button type="button" className="dd-head" onClick={() => setOpen((o) => !o)}>
        <span className={selected ? '' : 'ph'}>{selected ? selected.label : placeholder}</span>
        <FaChevronDown className="dd-caret" />
      </button>
      {open && (
        <>
          <div className="dd-overlay" onClick={() => setOpen(false)} />
          <div className="dd-menu">
            {options.map((o) => (
              <div key={o.value} className={`dd-item ${o.value === value ? 'sel' : ''}`} onClick={() => { onChange(o.value); setOpen(false); }}>
                {o.label}
              </div>
            ))}
          </div>
        </>
      )}
    </div>
  );
}

const emptyForm = { firstname: '', lastname: '', nationality: '', sex: 'male', day: '', month: '', year: '' };

interface Confirm {
  title: string;
  message: string;
  danger?: boolean;
  onYes: () => void;
}

const sample: Character[] = isBrowser
  ? [
      { citizenid: 'QS0A1B2C', charinfo: { firstname: 'Angelo', lastname: 'Moretti', nationality: 'Italian', sex: 'male' }, money: { cash: 1250, bank: 58230 }, job: { name: 'unemployed', label: 'Civilian' } },
      { citizenid: 'QS9Z8Y7X', charinfo: { firstname: 'Lena', lastname: 'Cruz', nationality: 'Spanish', sex: 'female' }, money: { cash: 430, bank: 12010 }, job: { name: 'police', label: 'Police' } },
    ]
  : [];

export default function App() {
  const [visible, setVisible] = useState(isBrowser);
  const [t, setT] = useState<Loc>(DEFAULT_T);
  const [characters, setCharacters] = useState<Character[]>(sample);
  const [maxSlots, setMaxSlots] = useState(5);
  const [index, setIndex] = useState(0);
  const [creating, setCreating] = useState(false);
  const [form, setForm] = useState(emptyForm);
  const [toast, setToast] = useState('');
  const [confirm, setConfirm] = useState<Confirm | null>(null);

  useNuiEvent<Colors>('theme', applyTheme);
  useNuiEvent<OpenData>('open', (d) => {
    if (d?.t) setT(d.t);
    setCreating(false);
    setVisible(true);
  });
  useNuiEvent('close', () => setVisible(false));
  useNuiEvent<SetCharactersData>('setCharacters', (d) => {
    const list = d.characters || [];
    setCharacters(list);
    setMaxSlots(d.maxSlots || 5);
    setIndex(0);
    setConfirm(null);

    if (list.length === 0) setCreating(true);
  });
  useNuiEvent<{ code: string }>('error', (d) => {
    const map: Record<string, string> = {
      invalid_input: t.err_invalid_input,
      max_characters: t.err_max_characters,
      no_license: t.err_no_license,
      not_found: t.err_not_found,
      not_owner: t.err_not_owner,
    };
    setToast(map[d.code] || `Error: ${d.code}`);
    window.setTimeout(() => setToast(''), 3000);
  });

  const current = characters[index];

  const go = (dir: number) => {
    if (characters.length < 2) return;
    const n = (index + dir + characters.length) % characters.length;
    setIndex(n);
    setConfirm(null);
    fetchNui('highlight', { citizenid: characters[n].citizenid });
  };

  const play = () => {
    if (current) fetchNui('selectCharacter', { citizenid: current.citizenid });
  };

  const askDelete = () => {
    if (!current) return;
    setConfirm({
      title: t.delete,
      message: t.confirm_delete_msg,
      danger: true,
      onYes: () => {
        fetchNui('deleteCharacter', { citizenid: current.citizenid });
        setConfirm(null);
      },
    });
  };

  const askQuit = () => {
    setConfirm({
      title: t.quit,
      message: t.confirm_quit_msg,
      onYes: () => {
        fetchNui('quit');
        setConfirm(null);
      },
    });
  };

  const submit = () => {
    if (!form.firstname.trim() || !form.lastname.trim()) {
      setToast(t.err_invalid_input);
      window.setTimeout(() => setToast(''), 3000);
      return;
    }
    const dob = form.day && form.month && form.year ? `${form.year}-${form.month}-${form.day}` : '';
    fetchNui('createCharacter', { firstname: form.firstname, lastname: form.lastname, nationality: form.nationality, sex: form.sex, dob });
    setForm(emptyForm);
    setCreating(false);
  };

  useEffect(() => {
    if (!visible || creating || confirm) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'ArrowLeft') go(-1);
      else if (e.key === 'ArrowRight') go(1);
      else if (e.key === 'Enter') play();
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);

  }, [visible, creating, confirm, index, characters]);

  useEffect(() => {
    if (!confirm) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') setConfirm(null);
      else if (e.key === 'Enter') confirm.onYes();
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [confirm]);

  if (!visible) return null;

  const days: Opt[] = Array.from({ length: 31 }, (_, i) => ({ value: pad(i + 1), label: String(i + 1) }));
  const months: Opt[] = t.months.map((name, i) => ({ value: pad(i + 1), label: name }));
  const years: Opt[] = Array.from({ length: 2008 - 1950 + 1 }, (_, i) => ({ value: String(2008 - i), label: String(2008 - i) }));
  const ci = current?.charinfo || {};

  return (
    <div className="stage">
      {!creating && (
        <div className="panel">
          <div className="char">
            <div className="tag">{current ? current.job?.label || current.job?.name || t.civilian : '—'}</div>
            <div className="cname">{current ? ci.firstname || 'Unknown' : ''}</div>
            <div className="cname sur">{current ? ci.lastname || '' : t.civilian}</div>
          </div>

          <div className="menu">
            {current && (
              <button className="mitem primary" onClick={play}>
                <FaPlay className="mi-ico" />
                <span className="mi-label">{t.play}</span>
              </button>
            )}
            {characters.length < maxSlots && (
              <button className="mitem" onClick={() => setCreating(true)}>
                <FaPlus className="mi-ico" />
                <span className="mi-label">{t.create_slot}</span>
              </button>
            )}
            {current && (
              <button className="mitem danger" onClick={askDelete}>
                <FaTrashAlt className="mi-ico" />
                <span className="mi-label">{t.delete}</span>
              </button>
            )}
            <button className="mitem" onClick={askQuit}>
              <FaSignOutAlt className="mi-ico" />
              <span className="mi-label">{t.quit}</span>
            </button>
          </div>

          {characters.length > 1 && (
            <div className="foot">
              <div className="nav">
                <button onClick={() => go(-1)} aria-label="Previous">
                  <FaChevronLeft />
                </button>
                <span>{index + 1} / {characters.length}</span>
                <button onClick={() => go(1)} aria-label="Next">
                  <FaChevronRight />
                </button>
              </div>
            </div>
          )}
        </div>
      )}

      {creating && (
        <div className="create-layer">
          <button className="create-back" onClick={() => setCreating(false)}>
            <FaArrowLeft /> {t.back}
          </button>

          <div className="create-head">
            <h1>{t.create_title}</h1>
            <p>{t.create_subtitle}</p>
          </div>

          <div className="create-form">
            <label className="field">
              <div className="field-main">
                <span className="fl">{t.firstname}</span>
                <input value={form.firstname} maxLength={30} placeholder="John" onChange={(e) => setForm({ ...form, firstname: e.target.value })} />
              </div>
              <FaRegAddressCard className="field-icon" />
            </label>

            <label className="field">
              <div className="field-main">
                <span className="fl">{t.lastname}</span>
                <input value={form.lastname} maxLength={30} placeholder="Doe" onChange={(e) => setForm({ ...form, lastname: e.target.value })} />
              </div>
              <FaRegAddressCard className="field-icon" />
            </label>

            <div className="field">
              <div className="field-main">
                <span className="fl">{t.dob}</span>
                <div className="dob-row">
                  <Dropdown value={form.day} options={days} placeholder={t.day} onChange={(v) => setForm({ ...form, day: v })} />
                  <Dropdown value={form.month} options={months} placeholder={t.month} onChange={(v) => setForm({ ...form, month: v })} />
                  <Dropdown value={form.year} options={years} placeholder={t.year} onChange={(v) => setForm({ ...form, year: v })} />
                </div>
              </div>
              <FaCalendarAlt className="field-icon" />
            </div>

            <label className="field">
              <div className="field-main">
                <span className="fl">{t.nationality}</span>
                <input value={form.nationality} maxLength={40} placeholder="American" onChange={(e) => setForm({ ...form, nationality: e.target.value })} />
              </div>
              <FaFlag className="field-icon" />
            </label>

            <div className="field">
              <div className="field-main">
                <span className="fl">{t.sex}</span>
                <div className="gsel">
                  <button className={`gbtn ${form.sex === 'male' ? 'active' : ''}`} onClick={() => setForm({ ...form, sex: 'male' })}>
                    <FaMars />
                  </button>
                  <button className={`gbtn ${form.sex === 'female' ? 'active' : ''}`} onClick={() => setForm({ ...form, sex: 'female' })}>
                    <FaVenus />
                  </button>
                </div>
              </div>
              <FaVenusMars className="field-icon" />
            </div>

            <button className="create-btn" onClick={submit}>
              {t.create}
            </button>
          </div>
        </div>
      )}

      {confirm && (
        <div className="confirm-layer">
          <div className="confirm-box">
            <h2>{confirm.title}</h2>
            <p>{confirm.message}</p>
            <div className="confirm-actions">
              <button className="cbtn-no" onClick={() => setConfirm(null)}>
                {t.confirm_no}
              </button>
              <button className="cbtn-yes" onClick={confirm.onYes}>
                {t.confirm_yes}
              </button>
            </div>
          </div>
        </div>
      )}

      {toast && <div className="toast">{toast}</div>}
    </div>
  );
}
