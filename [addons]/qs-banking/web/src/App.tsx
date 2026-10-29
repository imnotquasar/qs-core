import { useEffect, useState } from 'react';
import {
  FaUniversity, FaTimes, FaWallet, FaArrowDown, FaArrowUp, FaExchangeAlt,
  FaHistory, FaCreditCard, FaCheck, FaRegCopy,
} from 'react-icons/fa';
import useNuiEvent from './hooks/useNuiEvent';
import { fetchNui } from './utils/fetchNui';
import type { Colors, BankData, Transaction, Locale } from './types';
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

const money = (n: number) => '$' + (n || 0).toLocaleString('en-US');

// clipboard copy that also works inside FiveM's CEF (no secure context)
const fallbackCopy = (text: string) => {
  const ta = document.createElement('textarea');
  ta.value = text;
  ta.style.position = 'fixed';
  ta.style.top = '-1000px';
  ta.style.opacity = '0';
  document.body.appendChild(ta);
  ta.focus();
  ta.select();
  try { document.execCommand('copy'); } catch {}
  document.body.removeChild(ta);
};
const copyText = (text: string) => {
  try {
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(text).catch(() => fallbackCopy(text));
    } else {
      fallbackCopy(text);
    }
  } catch { fallbackCopy(text); }
};
const QUICK = [100, 500, 1000, 5000, 25000];

const DEMO: BankData = {
  mode: 'bank', cash: 4300, bank: 128500, account: 'QS482910375',
  history: [
    { type: 'deposit', amount: 5000, balance: 128500, label: 'Cash deposit', created: '2026-07-05 14:12' },
    { type: 'transfer_out', amount: 1200, balance: 123500, label: 'Transfer to QS100200300', created: '2026-07-05 13:50' },
    { type: 'withdraw', amount: 800, balance: 124700, label: 'Cash withdrawal', created: '2026-07-05 12:31' },
  ],
};

type Tab = 'deposit' | 'withdraw' | 'transfer' | 'history';

export default function App() {
  const [open, setOpen] = useState(isBrowser);
  const [data, setData] = useState<BankData>(DEMO);
  const [tab, setTab] = useState<Tab>('deposit');
  const [amount, setAmount] = useState('');
  const [account, setAccount] = useState('');
  const [locale, setLocale] = useState<Locale>({});

  const L = (k: string, fb: string) => locale[k] || fb;

  useNuiEvent<Colors>('theme', applyTheme);
  useNuiEvent<Locale>('locale', (l) => l && setLocale(l));
  useNuiEvent<BankData>('open', (d) => {
    if (!d) return;
    setData(d);
    setTab('deposit');
    setAmount('');
    setAccount('');
    setOpen(true);
  });
  useNuiEvent('close', () => setOpen(false));
  useNuiEvent<Partial<BankData>>('update', (d) => d && setData((cur) => ({ ...cur, ...d })));

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => { if (e.key === 'Escape') close(); };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, []);

  const close = () => { setOpen(false); fetchNui('close'); };

  const copyAccount = () => {
    if (!data.account) return;
    copyText(data.account);
    fetchNui('accountCopied', { account: data.account });
  };

  const submit = () => {
    const amt = Math.floor(Number(amount) || 0);
    if (tab === 'deposit') { if (amt > 0) fetchNui('deposit', { amount: amt }); }
    else if (tab === 'withdraw') { if (amt > 0) fetchNui('withdraw', { amount: amt }); }
    else if (tab === 'transfer') { if (amt > 0 && account.trim()) fetchNui('transfer', { account: account.trim(), amount: amt }); }
    setAmount('');
  };

  if (!open) return null;

  const isAtm = data.mode === 'atm';
  const tabs: { id: Tab; label: string; icon: JSX.Element }[] = [
    { id: 'deposit', label: L('ui_deposit', 'Deposit'), icon: <FaArrowDown /> },
    { id: 'withdraw', label: L('ui_withdraw', 'Withdraw'), icon: <FaArrowUp /> },
    ...(!isAtm ? [{ id: 'transfer' as Tab, label: L('ui_transfer', 'Transfer'), icon: <FaExchangeAlt /> }] : []),
    { id: 'history', label: L('ui_history', 'History'), icon: <FaHistory /> },
  ];

  const sign = (t: Transaction) => (t.type === 'deposit' || t.type === 'transfer_in' ? '+' : '-');
  const isPos = (t: Transaction) => t.type === 'deposit' || t.type === 'transfer_in';

  return (
    <div className="wrap">
      <div className="bank">
        <header className="bhead">
          <div className="brand"><FaUniversity className="bic" /><span>{isAtm ? L('ui_atm', 'ATM') : L('ui_bank', 'Bank')}</span></div>
          <button className="x" onClick={close}><FaTimes /></button>
        </header>

        <div className="cards">
          <div className="card bankcard copyable" onClick={copyAccount} title={L('ui_copy_account', 'Click to copy account number')}>
            <div className="cardtop"><FaCreditCard /><span>{L('ui_balance', 'Balance')}</span><FaRegCopy className="copyico" /></div>
            <div className="cardbal">{money(data.bank)}</div>
            <div className="cardacc">{L('ui_account', 'Account')}: <b>{data.account}</b></div>
          </div>
          <div className="card cashcard">
            <div className="cardtop"><FaWallet /><span>{L('ui_cash', 'Cash')}</span></div>
            <div className="cardbal sm">{money(data.cash)}</div>
          </div>
        </div>

        <nav className="btabs">
          {tabs.map((t) => (
            <button key={t.id} className={t.id === tab ? 'on' : ''} onClick={() => setTab(t.id)}>
              {t.icon}<span>{t.label}</span>
            </button>
          ))}
        </nav>

        <div className="bbody">
          {tab === 'history' ? (
            <div className="hlist">
              {data.history.length === 0 && <div className="hempty">{L('ui_no_history', 'No transactions yet.')}</div>}
              {data.history.map((t, i) => (
                <div className="hrow" key={i}>
                  <div className="hmain">
                    <span className="hlabel">{t.label || t.type}</span>
                    <span className="hdate">{t.created}</span>
                  </div>
                  <span className={`hamt ${isPos(t) ? 'pos' : 'neg'}`}>{sign(t)}{money(t.amount)}</span>
                </div>
              ))}
            </div>
          ) : (
            <div className="pane">
              {tab === 'transfer' && (
                <input className="fld" placeholder={L('ui_to_account', 'Recipient account number')} value={account} onChange={(e) => setAccount(e.target.value)} />
              )}
              <input className="fld" type="number" placeholder={L('ui_amount', 'Amount')} value={amount} onChange={(e) => setAmount(e.target.value)} />
              <div className="quick">
                {QUICK.map((q) => (
                  <button key={q} onClick={() => setAmount(String(q))}>{money(q)}</button>
                ))}
                <button onClick={() => setAmount(String(tab === 'withdraw' || tab === 'transfer' ? data.bank : data.cash))}>MAX</button>
              </div>
              <button className="confirm" onClick={submit}>
                <FaCheck /> {L('ui_confirm', 'Confirm')}
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
