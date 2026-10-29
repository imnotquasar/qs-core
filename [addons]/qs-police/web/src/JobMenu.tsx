import { useEffect, useState } from 'react';
import type { IconType } from 'react-icons';
import { FaTimes, FaUser } from 'react-icons/fa';
import useNuiEvent from './hooks/useNuiEvent';
import { fetchNui } from './utils/fetchNui';

const isBrowser = !(window as any).invokeNative;

export interface MenuAction {
  id: string;
  icon: IconType;
  label: [string, string];
  needsTarget?: boolean;
  danger?: boolean;
}

interface Target {
  id: number;
  name: string;
  downed?: boolean;
}

interface Props {
  icon: IconType;
  title: [string, string];
  actions: MenuAction[];
  fine?: boolean;
}

export default function JobMenu({ icon: Icon, title, actions, fine }: Props) {
  const [open, setOpen] = useState(isBrowser);
  const [target, setTarget] = useState<Target | null>(isBrowser ? { id: 12, name: 'John Doe' } : null);
  const [loc, setLoc] = useState<Record<string, string>>({});
  const [amount, setAmount] = useState('');
  const [reason, setReason] = useState('');
  const t = (k: string, fb: string) => loc[k] || fb;

  useNuiEvent<Record<string, string>>('locale', (d) => d && setLoc(d));
  useNuiEvent<{ target?: Target | null }>('menu:open', (d) => {
    setTarget(d?.target ?? null);
    setOpen(true);
  });
  useNuiEvent<{ target?: Target | null }>('menu:target', (d) => setTarget(d?.target ?? null));
  useNuiEvent('menu:close', () => setOpen(false));

  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') fetchNui('menu:close');
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [open]);

  if (!open) return null;

  const typing = (on: boolean) => fetchNui('menu:typing', { on });
  const act = (id: string, args?: string[]) => fetchNui('menu:action', { action: id, args });
  const sendFine = () => {
    const value = Math.floor(Number(amount));
    if (!value || value <= 0) return;
    act('fine', [String(value), reason.trim()]);
    setAmount('');
    setReason('');
  };

  return (
    <div className="jm">
      <div className="jm-head">
        <Icon className="jm-hico" />
        <div className="jm-titles">
          <div className="jm-sub">{t(title[0], title[1])}</div>
          <div className="jm-ttl">{t('ui_menu', 'Job Menu')}</div>
        </div>
        <button className="jm-close" onClick={() => fetchNui('menu:close')}>
          <FaTimes />
        </button>
      </div>

      <div className={`jm-target${target ? ' on' : ''}`}>
        <FaUser className="jm-tico" />
        <div className="jm-tinfo">
          <span className="jm-tlabel">{t('ui_nearest', 'Nearest player')}</span>
          <span className="jm-tname">
            {target ? `${target.name} · ID ${target.id}` : t('ui_nobody', 'No one nearby')}
          </span>
        </div>
        {target?.downed && <span className="jm-tag">{t('ui_downed', 'Downed')}</span>}
      </div>

      <div className="jm-grid">
        {actions.map((a) => {
          const ActIcon = a.icon;
          return (
            <button
              key={a.id}
              className={`jm-act${a.danger ? ' danger' : ''}`}
              disabled={a.needsTarget && !target}
              onClick={() => act(a.id)}
            >
              <ActIcon />
              <span>{t(a.label[0], a.label[1])}</span>
            </button>
          );
        })}
      </div>

      {fine && (
        <div className="jm-fine">
          <div className="jm-frow">
            <input
              className="jm-amount"
              type="number"
              min={1}
              placeholder={t('ui_amount', 'Amount')}
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              onFocus={() => typing(true)}
              onBlur={() => typing(false)}
            />
            <input
              placeholder={t('ui_reason', 'Reason')}
              maxLength={80}
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              onFocus={() => typing(true)}
              onBlur={() => typing(false)}
              onKeyDown={(e) => e.key === 'Enter' && sendFine()}
            />
          </div>
          <button className="jm-finebtn" disabled={!target || !amount} onClick={sendFine}>
            {t('ui_fine', 'Fine')}
          </button>
        </div>
      )}
    </div>
  );
}
