import { useEffect, useMemo, useRef, useState } from 'react';
import useNuiEvent from './hooks/useNuiEvent';
import { fetchNui } from './utils/fetchNui';
import type { ChatMessage, Colors, Suggestion } from './types';
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
}

let nextId = 1;
const now = () =>
  new Date().toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit' });

const msgType = (m: ChatMessage): ChatMessage['type'] =>
  m.type || (m.author ? 'player' : 'system');

// a stable hue per author name so names are easy to tell apart
function authorHue(name: string): number {
  let h = 0;
  for (let i = 0; i < name.length; i++) h = (h * 31 + name.charCodeAt(i)) % 360;
  return h;
}

const sample: ChatMessage[] = isBrowser
  ? [
      { id: nextId++, text: 'Welcome to Quasar Roleplay.', time: now() },
      { id: nextId++, author: 'Angelo Moretti', text: 'Hey, anyone near the docks?', time: now() },
      { id: nextId++, text: 'A player joined the server.', time: now() },
      { id: nextId++, author: 'Mia Cortez', text: 'On my way, give me two minutes.', time: now() },
    ]
  : [];

const demoSuggest: Suggestion[] = isBrowser
  ? [
      { name: '/tp', help: 'Teleport to coordinates', params: [{ name: 'x' }, { name: 'y' }, { name: 'z' }] },
      { name: '/tpm', help: 'Teleport to waypoint' },
      { name: '/time', help: 'Set the world time' },
    ]
  : [];

export default function App() {
  const [visible, setVisible] = useState(true);
  const [open, setOpen] = useState(isBrowser);
  const [messages, setMessages] = useState<ChatMessage[]>(sample);
  const [logShown, setLogShown] = useState(isBrowser);
  const [input, setInput] = useState('');
  const [suggestions, setSuggestions] = useState<Suggestion[]>(demoSuggest);
  const [sel, setSel] = useState(0);
  const inputRef = useRef<HTMLInputElement>(null);
  const logRef = useRef<HTMLDivElement>(null);

  const histRef = useRef<string[]>([]);
  const histPos = useRef(-1);
  const draftRef = useRef('');

  const [loc, setLoc] = useState<Record<string, string>>({});
  const L = (k: string, fb: string) => loc[k] || fb;

  useNuiEvent<Colors>('theme', applyTheme);
  useNuiEvent<Record<string, string>>('locale', (d) => d && setLoc(d));
  useNuiEvent('show', () => setVisible(true));
  useNuiEvent('hide', () => setVisible(false));
  useNuiEvent('open', () => {
    setInput('');
    histPos.current = -1;
    draftRef.current = '';
    setOpen(true);
  });
  useNuiEvent<Suggestion[]>('suggestions', (list) => setSuggestions(list || []));
  useNuiEvent<ChatMessage>('message', (m) => {
    if (!m || !m.text) return;
    setMessages((prev) => [...prev.slice(-99), { ...m, id: nextId++, time: m.time || now() }]);
  });

  useEffect(() => {
    setLogShown(true);
    if (open) return;
    const timer = window.setTimeout(() => setLogShown(false), 5000);
    return () => clearTimeout(timer);
  }, [messages, open]);

  useEffect(() => {
    if (open) window.setTimeout(() => inputRef.current?.focus(), 30);
  }, [open]);
  useEffect(() => {
    if (logRef.current) logRef.current.scrollTop = logRef.current.scrollHeight;
  }, [messages, open]);
  useEffect(() => setSel(0), [input]);

  const firstToken = input.split(' ')[0];
  const hasSpace = input.includes(' ');

  const matches = useMemo(() => {
    if (!input.startsWith('/') || hasSpace || firstToken.length < 1) return [];
    const q = firstToken.toLowerCase();
    return suggestions
      .filter((s) => s.name.toLowerCase().startsWith(q))
      .sort((a, b) => a.name.localeCompare(b.name))
      .slice(0, 8);
  }, [input, firstToken, hasSpace, suggestions]);

  const activeCmd = useMemo(() => {
    if (!input.startsWith('/') || !hasSpace) return null;
    return suggestions.find((s) => s.name.toLowerCase() === firstToken.toLowerCase()) || null;
  }, [input, firstToken, hasSpace, suggestions]);

  const argIndex = hasSpace ? input.trimStart().split(' ').length - 2 : -1;

  const complete = (s: Suggestion) => {
    setInput(s.name + ' ');
    inputRef.current?.focus();
  };

  const navHistory = (dir: 1 | -1) => {
    const h = histRef.current;
    if (h.length === 0) return;
    if (dir === 1) {
      if (histPos.current === -1) draftRef.current = input;
      histPos.current = Math.min(histPos.current + 1, h.length - 1);
      setInput(h[histPos.current]);
    } else if (histPos.current <= 0) {
      histPos.current = -1;
      setInput(draftRef.current);
    } else {
      histPos.current -= 1;
      setInput(h[histPos.current]);
    }
    window.requestAnimationFrame(() => {
      const el = inputRef.current;
      if (el) el.setSelectionRange(el.value.length, el.value.length);
    });
  };

  const submit = () => {
    const msg = input.trim();
    fetchNui('send', { message: input });
    if (msg && histRef.current[0] !== msg) {
      histRef.current = [msg, ...histRef.current].slice(0, 60);
    }
    histPos.current = -1;
    draftRef.current = '';
    setInput('');
    setOpen(false);
  };
  const cancel = () => {
    setInput('');
    histPos.current = -1;
    setOpen(false);
    fetchNui('close');
  };

  const onKey = (e: React.KeyboardEvent) => {
    if (e.key === 'Tab') {
      e.preventDefault();
      if (matches.length > 0) complete(matches[sel] || matches[0]);
      return;
    }
    if (e.key === 'ArrowUp' || e.key === 'ArrowDown') {
      e.preventDefault();
      if (matches.length > 0) {
        setSel((s) => (e.key === 'ArrowDown' ? Math.min(s + 1, matches.length - 1) : Math.max(s - 1, 0)));
      } else {
        navHistory(e.key === 'ArrowUp' ? 1 : -1);
      }
      return;
    }
    if (e.key === 'Enter') {
      e.preventDefault();
      submit();
    } else if (e.key === 'Escape') {
      e.preventDefault();
      cancel();
    }
  };

  if (!visible) return null;

  return (
    <div className="chat">
      {(open || messages.length > 0) && (
        <div ref={logRef} className={`log ${open ? 'active' : ''} ${open || logShown ? '' : 'hidden'}`}>
          {messages.map((m) => {
            const t = msgType(m);
            return (
              <div className={`line ${t}`} key={m.id}>
                <span className="time">{m.time}</span>
                <span className="lbody">
                  {m.author ? (
                    <span className="author" style={{ ['--ah' as any]: authorHue(m.author) }}>
                      {m.author}
                    </span>
                  ) : (
                    <span className="badge">●</span>
                  )}
                  <span className="text">{m.text}</span>
                </span>
              </div>
            );
          })}
        </div>
      )}

      {open && (
        <div className="composer">
          <div className="inputbar">
            <span className="prompt">{input.startsWith('/') ? '/' : '›'}</span>
            <input
              ref={inputRef}
              value={input}
              maxLength={256}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={onKey}
              placeholder={L('ui_placeholder', 'Type a message or /command…')}
            />
            {histRef.current.length > 0 && <span className="hintkeys">↑↓ · Tab</span>}
          </div>

          {matches.length > 0 && (
            <div className="suggest">
              {matches.map((s, i) => (
                <div
                  key={s.name}
                  className={`sug ${i === sel ? 'sel' : ''}`}
                  onMouseEnter={() => setSel(i)}
                  onMouseDown={(e) => {
                    e.preventDefault();
                    complete(s);
                  }}
                >
                  <span className="sug-name">
                    {s.name}
                    {s.params?.map((p) => (
                      <span key={p.name} className="sug-param"> [{p.name}]</span>
                    ))}
                  </span>
                  {s.help ? <span className="sug-help">{s.help}</span> : null}
                </div>
              ))}
            </div>
          )}

          {activeCmd && (activeCmd.help || (activeCmd.params && activeCmd.params.length > 0)) && (
            <div className="hintbar">
              <span className="hint-name">{activeCmd.name}</span>
              {activeCmd.params?.map((p, i) => (
                <span key={p.name} className={`hint-param ${i === argIndex ? 'on' : ''}`}>
                  [{p.name}]
                </span>
              ))}
              {activeCmd.help ? <span className="hint-help">— {activeCmd.help}</span> : null}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
