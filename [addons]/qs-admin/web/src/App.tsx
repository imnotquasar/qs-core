import { useEffect, useMemo, useState } from 'react';
import {
  FaUserShield, FaTimes, FaSync, FaLocationArrow, FaHandPointer, FaEye, FaSnowflake,
  FaHeart, FaHeartbeat, FaSkull, FaUserSlash, FaGavel, FaBriefcase, FaUsersCog,
  FaDollarSign, FaBox, FaCrosshairs, FaGhost, FaShieldAlt, FaMapMarkerAlt, FaWrench,
  FaCar, FaTrash, FaBroom, FaBullhorn, FaCloudSunRain, FaClock,
} from 'react-icons/fa';
import useNuiEvent from './hooks/useNuiEvent';
import { fetchNui } from './utils/fetchNui';
import type { Colors, Player, States, OpenData, Locale } from './types';
import './index.css';

const isBrowser = !(window as any).invokeNative;

function applyTheme(c: Colors) {
  if (!c) return;
  const map: Record<string, string | undefined> = {
    '--hud-text': c.text, '--hud-muted': c.muted, '--hud-primary': c.primary,
    '--hud-accent': c.accent, '--hud-glow': c.glow, '--hud-border': c.border,
  };
  const style = document.documentElement.style;
  for (const key in map) { const v = map[key]; if (v) style.setProperty(key, v); }
  const rgb = (hex?: string): string | null => {
    if (!hex || hex[0] !== '#' || hex.length < 7) return null;
    const n = parseInt(hex.slice(1, 7), 16);
    return `${(n >> 16) & 255}, ${(n >> 8) & 255}, ${n & 255}`;
  };
  const a = rgb(c.accent);
  if (a) { style.setProperty('--hud-accent-soft', `rgba(${a}, 0.16)`); style.setProperty('--hud-accent-mid', `rgba(${a}, 0.3)`); }
  const p = rgb(c.primary);
  if (p) style.setProperty('--hud-primary-soft', `rgba(${p}, 0.22)`);
}

const DEMO_PLAYERS: Player[] = [
  { id: 1, name: 'John Doe', job: 'Unemployed', ping: 42, cash: 500, bank: 5000 },
  { id: 2, name: 'Jane Roe', job: 'Police', ping: 61, cash: 1200, bank: 34000 },
];

export default function App() {
  const [open, setOpen] = useState(isBrowser);
  const [tab, setTab] = useState<'players' | 'self' | 'server'>('players');
  const [players, setPlayers] = useState<Player[]>(DEMO_PLAYERS);
  const [selId, setSelId] = useState<number | null>(isBrowser ? 1 : null);
  const [search, setSearch] = useState('');
  const [states, setStates] = useState<States>({});
  const [weathers, setWeathers] = useState<string[]>(['CLEAR', 'RAIN', 'THUNDER', 'SNOW']);
  const [groups, setGroups] = useState<string[]>(['user', 'mod', 'admin']);
  const [locale, setLocale] = useState<Locale>({});
  const [f, setF] = useState<Record<string, string>>({});
  const [announce, setAnnounce] = useState<string | null>(null);

  const L = (k: string, fb: string) => locale[k] || fb;
  const setField = (k: string, v: string) => setF((p) => ({ ...p, [k]: v }));

  useNuiEvent<Colors>('theme', applyTheme);
  useNuiEvent<Locale>('locale', (l) => l && setLocale(l));
  useNuiEvent<OpenData>('open', (d) => {
    if (d) {
      setWeathers(d.weathers || weathers);
      setGroups(d.groups || groups);
      setStates(d.states || {});
    }
    setOpen(true);
  });
  useNuiEvent('close', () => setOpen(false));
  useNuiEvent<{ players: Player[] }>('players', (d) => setPlayers(d?.players || []));
  useNuiEvent<States>('states', (d) => d && setStates(d));
  useNuiEvent<{ message: string }>('announce', (d) => {
    if (d?.message) {
      setAnnounce(d.message);
      window.setTimeout(() => setAnnounce(null), 8000);
    }
  });

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => { if (e.key === 'Escape' && open) close(); };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [open]);

  const close = () => { setOpen(false); fetchNui('close'); };
  const act = (action: string, data?: any) => fetchNui('action', { action, target: selId, data });
  const selfAct = (what: string, data?: any) => fetchNui('self', { what, data });

  const sel = useMemo(() => players.find((p) => p.id === selId) || null, [players, selId]);
  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    if (!q) return players;
    return players.filter((p) => p.name.toLowerCase().includes(q) || String(p.id).includes(q) || p.job.toLowerCase().includes(q));
  }, [players, search]);

  if (announce && !open) {
    return (
      <div className="ann-wrap">
        <div className="ann">
          <FaBullhorn />
          <span>{announce}</span>
        </div>
      </div>
    );
  }
  if (!open) return null;

  return (
    <div className="wrap">
      {announce && (
        <div className="ann-wrap"><div className="ann"><FaBullhorn /><span>{announce}</span></div></div>
      )}
      <div className="panel">
        <header className="head">
          <div className="brand"><FaUserShield className="bic" /><span>{L('ui_title', 'Admin Menu')}</span></div>
          <nav className="tabs">
            <button className={tab === 'players' ? 'on' : ''} onClick={() => setTab('players')}>{L('ui_players', 'Players')}</button>
            <button className={tab === 'self' ? 'on' : ''} onClick={() => setTab('self')}>{L('ui_self', 'Self')}</button>
            <button className={tab === 'server' ? 'on' : ''} onClick={() => setTab('server')}>{L('ui_server', 'Server')}</button>
          </nav>
          <button className="x" onClick={close}><FaTimes /></button>
        </header>

        {tab === 'players' && (
          <div className="body players">
            <div className="plist">
              <div className="ptools">
                <input placeholder={L('ui_search', 'Search player...')} value={search} onChange={(e) => setSearch(e.target.value)} />
                <button className="ibtn" onClick={() => fetchNui('refresh')} title={L('ui_refresh', 'Refresh')}><FaSync /></button>
              </div>
              <div className="pscroll">
                {filtered.map((p) => (
                  <button key={p.id} className={`prow ${p.id === selId ? 'active' : ''}`} onClick={() => setSelId(p.id)}>
                    <span className="pid">{p.id}</span>
                    <div className="pmain"><span className="pname">{p.name}</span><span className="pjob">{p.job}</span></div>
                    <span className="pping">{p.ping}ms</span>
                  </button>
                ))}
                {filtered.length === 0 && <div className="pempty">—</div>}
              </div>
            </div>

            <div className="pactions">
              {!sel ? (
                <div className="hint"><FaHandPointer /><span>{L('ui_select_hint', 'Select a player')}</span></div>
              ) : (
                <>
                  <div className="selhead">
                    <div><b>{sel.name}</b> <span className="dim">#{sel.id} · {sel.job}</span></div>
                    <div className="dim">${(sel.cash ?? 0).toLocaleString()} / ${(sel.bank ?? 0).toLocaleString()}</div>
                  </div>

                  <div className="qgrid">
                    <button onClick={() => act('goto')}><FaLocationArrow />{L('ui_goto', 'Goto')}</button>
                    <button onClick={() => act('bring')}><FaHandPointer />{L('ui_bring', 'Bring')}</button>
                    <button onClick={() => act('spectate')}><FaEye />{L('ui_spectate', 'Spectate')}</button>
                    <button onClick={() => act('freeze', { state: true })}><FaSnowflake />{L('ui_freeze', 'Freeze')}</button>
                    <button onClick={() => act('freeze', { state: false })}><FaSnowflake />{L('ui_unfreeze', 'Unfreeze')}</button>
                    <button onClick={() => act('heal')}><FaHeart />{L('ui_heal', 'Heal')}</button>
                    <button onClick={() => act('revive')}><FaHeartbeat />{L('ui_revive', 'Revive')}</button>
                    <button className="danger" onClick={() => act('kill')}><FaSkull />{L('ui_kill', 'Kill')}</button>
                  </div>

                  <div className="form">
                    <div className="frow">
                      <FaUserSlash />
                      <input placeholder={L('ui_reason', 'Reason')} value={f.kickReason || ''} onChange={(e) => setField('kickReason', e.target.value)} />
                      <button onClick={() => act('kick', { reason: f.kickReason })}>{L('ui_kick', 'Kick')}</button>
                    </div>
                    <div className="frow">
                      <FaGavel />
                      <input placeholder={L('ui_reason', 'Reason')} value={f.banReason || ''} onChange={(e) => setField('banReason', e.target.value)} />
                      <input className="sm" type="number" placeholder={L('ui_minutes', 'Min')} value={f.banMin || ''} onChange={(e) => setField('banMin', e.target.value)} />
                      <button className="danger" onClick={() => act('ban', { reason: f.banReason, minutes: f.banMin })}>{L('ui_ban', 'Ban')}</button>
                    </div>
                    <div className="frow">
                      <FaBriefcase />
                      <input placeholder={L('ui_job_name', 'Job name')} value={f.job || ''} onChange={(e) => setField('job', e.target.value)} />
                      <input className="sm" type="number" placeholder={L('ui_grade', 'Grade')} value={f.grade || ''} onChange={(e) => setField('grade', e.target.value)} />
                      <button onClick={() => act('setjob', { job: f.job, grade: f.grade })}>{L('ui_apply', 'Apply')}</button>
                    </div>
                    <div className="frow">
                      <FaUsersCog />
                      <select value={f.group || groups[0]} onChange={(e) => setField('group', e.target.value)}>
                        {groups.map((g) => <option key={g} value={g}>{g}</option>)}
                      </select>
                      <button onClick={() => act('setgroup', { group: f.group || groups[0] })}>{L('ui_apply', 'Apply')}</button>
                    </div>
                    <div className="frow">
                      <FaDollarSign />
                      <select value={f.account || 'cash'} onChange={(e) => setField('account', e.target.value)}>
                        <option value="cash">cash</option>
                        <option value="bank">bank</option>
                        <option value="black_money">black_money</option>
                      </select>
                      <input className="sm" type="number" placeholder={L('ui_amount', 'Amount')} value={f.amount || ''} onChange={(e) => setField('amount', e.target.value)} />
                      <button onClick={() => act('money', { account: f.account || 'cash', mode: 'add', amount: f.amount })}>{L('ui_add', 'Add')}</button>
                      <button onClick={() => act('money', { account: f.account || 'cash', mode: 'remove', amount: f.amount })}>{L('ui_remove', 'Remove')}</button>
                    </div>
                    <div className="frow">
                      <FaBox />
                      <input placeholder={L('ui_item', 'Item name')} value={f.item || ''} onChange={(e) => setField('item', e.target.value)} />
                      <input className="sm" type="number" placeholder={L('ui_count', 'Count')} value={f.count || ''} onChange={(e) => setField('count', e.target.value)} />
                      <button onClick={() => act('giveitem', { item: f.item, count: f.count })}>{L('ui_apply', 'Apply')}</button>
                    </div>
                    <div className="frow">
                      <FaCrosshairs />
                      <input placeholder={L('ui_weapon', 'WEAPON_...')} value={f.weapon || ''} onChange={(e) => setField('weapon', e.target.value)} />
                      <input className="sm" type="number" placeholder={L('ui_ammo', 'Ammo')} value={f.ammo || ''} onChange={(e) => setField('ammo', e.target.value)} />
                      <button onClick={() => act('giveweapon', { weapon: f.weapon, ammo: f.ammo })}>{L('ui_apply', 'Apply')}</button>
                    </div>
                  </div>
                </>
              )}
            </div>
          </div>
        )}

        {tab === 'self' && (
          <div className="body self">
            <div className="toggles">
              <button className={`tog ${states.noclip ? 'on' : ''}`} onClick={() => selfAct('noclip')}>
                <FaGhost /><span>{L('ui_noclip', 'Noclip')}</span><em>{states.noclip ? L('ui_on', 'ON') : L('ui_off', 'OFF')}</em>
              </button>
              <button className={`tog ${states.godmode ? 'on' : ''}`} onClick={() => selfAct('godmode')}>
                <FaShieldAlt /><span>{L('ui_godmode', 'Godmode')}</span><em>{states.godmode ? L('ui_on', 'ON') : L('ui_off', 'OFF')}</em>
              </button>
              <button className={`tog ${states.invisible ? 'on' : ''}`} onClick={() => selfAct('invisible')}>
                <FaEye /><span>{L('ui_invisible', 'Invisible')}</span><em>{states.invisible ? L('ui_on', 'ON') : L('ui_off', 'OFF')}</em>
              </button>
            </div>
            <div className="qgrid wide">
              <button onClick={() => selfAct('tpm')}><FaMapMarkerAlt />{L('ui_tpwaypoint', 'TP to Waypoint')}</button>
              <button onClick={() => selfAct('fixveh')}><FaWrench />{L('ui_fixveh', 'Fix Vehicle')}</button>
              <button onClick={() => selfAct('delveh')}><FaTrash />{L('ui_delveh', 'Delete Vehicle')}</button>
              <button onClick={() => selfAct('cleararea')}><FaBroom />{L('ui_cleararea', 'Clear Area')}</button>
            </div>
            <div className="form">
              <div className="frow">
                <FaCar />
                <input placeholder={L('ui_model', 'Vehicle model')} value={f.model || ''} onChange={(e) => setField('model', e.target.value)} />
                <button onClick={() => selfAct('spawnveh', { model: f.model })}>{L('ui_spawnveh', 'Spawn Vehicle')}</button>
              </div>
            </div>
          </div>
        )}

        {tab === 'server' && (
          <div className="body server">
            <div className="sec">
              <div className="slabel"><FaBullhorn /> {L('ui_announce', 'Announcement')}</div>
              <div className="frow">
                <input placeholder={L('ui_announce', 'Announcement')} value={f.ann || ''} onChange={(e) => setField('ann', e.target.value)} />
                <button onClick={() => { act('announce', { message: f.ann }); setField('ann', ''); }}>{L('ui_send', 'Send')}</button>
              </div>
            </div>
            <div className="sec">
              <div className="slabel"><FaCloudSunRain /> {L('ui_weather', 'Weather')}</div>
              <div className="wgrid">
                {weathers.map((w) => (
                  <button key={w} onClick={() => act('weather', { weather: w })}>{w}</button>
                ))}
              </div>
            </div>
            <div className="sec">
              <div className="slabel"><FaClock /> {L('ui_time', 'Time')}</div>
              <div className="frow">
                <input className="sm" type="number" min={0} max={23} placeholder="HH" value={f.hour || ''} onChange={(e) => setField('hour', e.target.value)} />
                <input className="sm" type="number" min={0} max={59} placeholder="MM" value={f.minute || ''} onChange={(e) => setField('minute', e.target.value)} />
                <button onClick={() => act('time', { hour: f.hour || '12', minute: f.minute || '0' })}>{L('ui_settime', 'Set Time')}</button>
              </div>
            </div>
            <div className="sec online"><FaUserShield /> {L('ui_online', 'Online')}: <b>{players.length}</b></div>
          </div>
        )}
      </div>
    </div>
  );
}
