import { useEffect, useRef, useState } from 'react';
import { FaBox } from 'react-icons/fa';
import useNuiEvent from './hooks/useNuiEvent';
import { fetchNui } from './utils/fetchNui';
import ItemImg from './ItemImg';
import type { InvItem, Slot } from './types';

const SIZE = 440;
const C = SIZE / 2;
const R_OUT = 200;
const R_IN = 96;
const GAP = 1.6;
const DEADZONE = 60;

const polar = (r: number, deg: number) => {
  const a = ((deg - 90) * Math.PI) / 180;
  return [C + r * Math.cos(a), C + r * Math.sin(a)];
};

function sector(a0: number, a1: number) {
  const [x0, y0] = polar(R_OUT, a0);
  const [x1, y1] = polar(R_OUT, a1);
  const [x2, y2] = polar(R_IN, a1);
  const [x3, y3] = polar(R_IN, a0);
  const large = a1 - a0 > 180 ? 1 : 0;
  return `M${x0} ${y0}A${R_OUT} ${R_OUT} 0 ${large} 1 ${x1} ${y1}L${x2} ${y2}A${R_IN} ${R_IN} 0 ${large} 0 ${x3} ${y3}Z`;
}

const asItem = (s: Slot) => (s && typeof s === 'object' ? (s as InvItem) : null);

export default function Radial({ L }: { L: (k: string, fb: string) => string }) {
  const [open, setOpen] = useState(false);
  const [items, setItems] = useState<Slot[]>([]);
  const [hover, setHover] = useState<number | null>(null);
  const hoverRef = useRef<number | null>(null);
  const itemsRef = useRef<Slot[]>([]);
  const ref = useRef<HTMLDivElement>(null);

  const setHovered = (i: number | null) => {
    hoverRef.current = i;
    setHover(i);
  };

  const applyItems = (list?: Slot[]) => {
    itemsRef.current = list || [];
    setItems(itemsRef.current);
  };

  const select = (slot: number | null) => {
    setOpen(false);
    fetchNui('radial:select', { slot });
  };

  const hoveredUsable = () => {
    const i = hoverRef.current;
    const it = i === null ? null : asItem(itemsRef.current[i]);
    return it && it.useable && i !== null ? i + 1 : null;
  };

  useNuiEvent<{ items: Slot[] }>('radial:open', (d) => {
    applyItems(d?.items);
    setHovered(null);
    setOpen(true);
  });
  useNuiEvent<{ items: Slot[] }>('radial:set', (d) => d && applyItems(d.items));
  useNuiEvent('radial:close', () => setOpen(false));
  useNuiEvent('radial:release', () => select(hoveredUsable()));

  const step = 360 / Math.max(items.length, 1);

  useEffect(() => {
    if (!open) return;
    const move = (e: MouseEvent) => {
      const r = ref.current?.getBoundingClientRect();
      if (!r) return;
      const dx = e.clientX - (r.left + r.width / 2);
      const dy = e.clientY - (r.top + r.height / 2);
      if (Math.hypot(dx, dy) < DEADZONE) {
        setHovered(null);
        return;
      }
      const deg = (Math.atan2(dy, dx) * 180) / Math.PI + 90;
      setHovered(Math.floor((((deg + step / 2) % 360) + 360) % 360 / step));
    };
    const key = (e: KeyboardEvent) => {
      if (e.key === 'Tab') e.preventDefault();
      if (e.key === 'Escape') {
        setOpen(false);
        fetchNui('radial:close');
      }
    };
    window.addEventListener('mousemove', move);
    window.addEventListener('keydown', key);
    return () => {
      window.removeEventListener('mousemove', move);
      window.removeEventListener('keydown', key);
    };
  }, [open, step]);

  if (!open) return null;

  const hi = hover !== null ? asItem(items[hover]) : null;

  return (
    <div className="radial-wrap">
      <div className="radial" ref={ref} style={{ width: SIZE, height: SIZE }}>
        <svg width={SIZE} height={SIZE} className="radial-svg">
          {items.map((s, i) => {
            const it = asItem(s);
            const mid = i * step;
            return (
              <path
                key={i}
                d={sector(mid - step / 2 + GAP, mid + step / 2 - GAP)}
                className={`rseg ${it ? 'filled' : ''} ${it && !it.useable ? 'locked' : ''} ${hover === i ? 'hover' : ''}`}
                onClick={() => it && it.useable && select(i + 1)}
              />
            );
          })}
        </svg>

        {items.map((s, i) => {
          const it = asItem(s);
          const [x, y] = polar((R_IN + R_OUT) / 2, i * step);
          return (
            <div
              key={i}
              className={`rcell ${hover === i ? 'hover' : ''} ${it && !it.useable ? 'locked' : ''}`}
              style={{ left: x, top: y }}
            >
              <span className="rkey">{i + 1}</span>
              {it ? (
                <>
                  <div className="rthumb">
                    <ItemImg item={it} />
                  </div>
                  <span className="rcount">{it.count}</span>
                </>
              ) : (
                <span className="rempty" />
              )}
            </div>
          );
        })}

        <div className="rcenter">
          {hi ? (
            <>
              <span className="rc-label">{hi.label}</span>
              <span className="rc-sub">{hi.useable ? `x${hi.count}` : L('ui_not_usable', 'Not usable')}</span>
            </>
          ) : hover !== null ? (
            <span className="rc-sub">{L('ui_empty', 'Empty')}</span>
          ) : (
            <>
              <FaBox className="rc-ico" />
              <span className="rc-label">{L('ui_title', 'Inventory')}</span>
            </>
          )}
        </div>
      </div>
    </div>
  );
}
