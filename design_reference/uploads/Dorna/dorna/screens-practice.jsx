// screens-practice.jsx — PracticeHub, TalkLive, Feedback, PracticeDeck, PhraseDetail

function PracticeHub() {
  const { nav } = useApp();
  return (
    <div style={{ minHeight: '100%', position: 'relative' }}>
      <div style={{ padding: '56px 20px 0' }}>
        <h1 style={{ fontSize: 30, fontWeight: 800, color: 'var(--ink)', margin: 0, letterSpacing: '-.02em' }}>Practice</h1>
        <p style={{ fontSize: 14.5, color: 'var(--ink-soft)', marginTop: 6 }}>Rehearse before it counts.</p>
      </div>
      <div style={{ padding: '20px 20px 28px', display: 'flex', flexDirection: 'column', gap: 18 }}>
        {/* live CTA */}
        <div onClick={() => nav('talklive')} style={{ cursor: 'pointer', borderRadius: 'var(--r-card)', padding: 22, color: '#fff',
          position: 'relative', overflow: 'hidden', background: 'linear-gradient(135deg, var(--hero-from), var(--hero-to))',
          boxShadow: '0 18px 40px -18px color-mix(in srgb, var(--primary) 70%, transparent)' }}>
          <div style={{ position: 'absolute', top: -30, right: -20, width: 140, height: 140, borderRadius: 999, background: 'rgba(255,255,255,0.08)' }} />
          <div style={{ position: 'relative', display: 'flex', alignItems: 'center', gap: 16 }}>
            <div style={{ width: 56, height: 56, borderRadius: 999, background: 'rgba(255,255,255,0.18)',
              display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
              <Icon name="mic" size={30} fill={1} color="#fff" /></div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 20, fontWeight: 800 }}>Talk with Dorna</div>
              <div style={{ fontSize: 13.5, opacity: 0.9, marginTop: 2 }}>Live roleplay — speak and get instant feedback</div>
            </div>
            <Icon name="arrow_forward" size={24} color="#fff" />
          </div>
        </div>

        {/* scenarios */}
        <div>
          <Eyebrow color="var(--ink-soft)" style={{ marginBottom: 12 }}>Practice a scene</Eyebrow>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
            {DATA.situations.slice(0, 4).map(s => (
              <Card key={s.id} onClick={() => nav('talklive', { scene: s.title })} pad={15} soft
                style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
                <div style={{ width: 42, height: 42, borderRadius: 12, background: 'var(--surface-3)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <Icon name={s.icon} size={22} color="var(--primary)" /></div>
                <div style={{ fontSize: 14.5, fontWeight: 700, color: 'var(--ink)', lineHeight: 1.25 }}>{s.title}</div>
              </Card>
            ))}
          </div>
        </div>

        {/* flashcards */}
        <Card onClick={() => nav('deck')} pad={16} style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
          <div style={{ width: 46, height: 46, borderRadius: 13, background: 'var(--surface-3)',
            display: 'flex', alignItems: 'center', justifyContent: 'center' }}><Icon name="style" size={24} color="var(--primary)" /></div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 15.5, fontWeight: 700, color: 'var(--ink)' }}>Phrase flashcards</div>
            <div style={{ fontSize: 13, color: 'var(--ink-soft)' }}>6 cards · Break the ice</div>
          </div>
          <Icon name="chevron_right" size={22} color="var(--ink-mute)" />
        </Card>

        {/* library */}
        <div>
          <Eyebrow color="var(--ink-soft)" style={{ marginBottom: 12 }}>Phrase library</Eyebrow>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
            {DATA.phrases.slice(0, 4).map(p => (
              <Card key={p.id} onClick={() => nav('phrase', { id: p.id })} pad={14} soft
                style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 15, fontWeight: 600, color: 'var(--ink)' }}>{p.text}</div>
                  <div style={{ fontSize: 12.5, color: 'var(--ink-mute)', fontFamily: 'monospace', whiteSpace: 'nowrap',
                    overflow: 'hidden', textOverflow: 'ellipsis' }}>{p.ipa}</div>
                </div>
                <HearBtn text={p.text} variant="icon" />
              </Card>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

// ── Talk with Dorna (live) ───────────────────────────────────────────
const DORNA_LINES = [
  'Hi! Tell me what you do.',
  'Nice! And what brings you to the event tonight?',
  'Love that. How are you finding Toronto so far?',
  "Great chatting — want to wrap up and see your feedback?",
];
const USER_LINES = [
  'I am software engineer.',
  "I'm here to meet people in tech.",
  "It's great, still settling in.",
];

function TalkLive() {
  const { back, nav, params } = useApp();
  const scene = params.scene || 'Networking event';
  const [msgs, setMsgs] = React.useState([{ who: 'dorna', text: DORNA_LINES[0] }]);
  const [state, setState] = React.useState('idle'); // idle | listening
  const [turn, setTurn] = React.useState(0);
  const scrollRef = React.useRef(null);

  React.useEffect(() => { const id = setTimeout(() => speak(DORNA_LINES[0]), 450); return () => clearTimeout(id); }, []);
  React.useEffect(() => { if (scrollRef.current) scrollRef.current.scrollTop = scrollRef.current.scrollHeight; }, [msgs, state]);

  const tap = () => {
    if (state === 'listening') return;
    setState('listening');
    setTimeout(() => {
      const u = USER_LINES[turn % USER_LINES.length];
      setMsgs(m => [...m, { who: 'you', text: u }]);
      setState('idle');
      const nextD = DORNA_LINES[Math.min(turn + 1, DORNA_LINES.length - 1)];
      setTimeout(() => { setMsgs(m => [...m, { who: 'dorna', text: nextD }]); speak(nextD); }, 700);
      setTurn(t => t + 1);
    }, 1900);
  };

  return (
    <div style={{ minHeight: '100%', display: 'flex', flexDirection: 'column', height: '100%' }}>
      <TopBar title="Talk with Dorna" onBack={() => { window.speechSynthesis && window.speechSynthesis.cancel(); back(); }} accent
        action={<button onClick={() => nav('settings')} style={iconBtnStyle}><Icon name="settings" size={22} color="var(--ink-soft)" /></button>} />
      <div style={{ textAlign: 'center', marginTop: -2, marginBottom: 8 }}>
        <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6, fontSize: 13, fontWeight: 600, color: 'var(--ink-soft)',
          background: 'var(--surface-2)', padding: '7px 14px', borderRadius: 999 }}>
          <Icon name="restaurant" size={16} color="var(--primary)" />Scene: {scene}</span>
      </div>

      <div ref={scrollRef} style={{ flex: 1, overflowY: 'auto', padding: '8px 20px 0', display: 'flex', flexDirection: 'column', gap: 14 }}>
        {msgs.map((m, i) => m.who === 'dorna' ? (
          <div key={i} style={{ alignSelf: 'flex-start', maxWidth: '85%' }}>
            <div style={{ display: 'flex', alignItems: 'flex-start', gap: 10, background: 'color-mix(in srgb, var(--accent) 12%, white)',
              border: '1px solid var(--line)', padding: '13px 15px', borderRadius: '18px 18px 18px 5px' }}>
              <button onClick={() => speak(m.text)} style={{ width: 30, height: 30, borderRadius: 999, border: 'none', cursor: 'pointer',
                background: 'var(--primary)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                <Icon name="volume_up" size={17} color="#fff" fill={1} /></button>
              <span style={{ fontSize: 15.5, color: 'var(--ink)', lineHeight: 1.4 }}>{m.text}</span>
            </div>
            <span style={{ fontSize: 11.5, color: 'var(--ink-mute)', marginLeft: 6, marginTop: 4, display: 'inline-block' }}>Dorna · just now</span>
          </div>
        ) : (
          <div key={i} style={{ alignSelf: 'flex-end', maxWidth: '85%', textAlign: 'right' }}>
            <div style={{ background: 'linear-gradient(135deg, var(--hero-from), var(--hero-to))', color: '#fff',
              padding: '13px 16px', borderRadius: '18px 18px 5px 18px', fontSize: 15.5, lineHeight: 1.4, textAlign: 'left' }}>{m.text}</div>
            <span style={{ fontSize: 11.5, color: 'var(--ink-mute)', marginRight: 6, marginTop: 4, display: 'inline-block' }}>You · transcribed</span>
          </div>
        ))}
        {state === 'listening' && (
          <div style={{ alignSelf: 'flex-end', display: 'flex', alignItems: 'center', gap: 8, padding: '10px 16px',
            background: 'var(--surface-2)', borderRadius: 999 }}>
            <Waveform playing color="var(--primary)" count={9} height={18} seed={9} />
            <span style={{ fontSize: 12.5, color: 'var(--ink-soft)', fontWeight: 600 }}>Listening…</span>
          </div>
        )}
      </div>

      {/* mic dock */}
      <div style={{ padding: '12px 20px 16px', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 14 }}>
        <button onClick={tap} style={{ position: 'relative', width: 84, height: 84, borderRadius: 999, border: 'none', cursor: 'pointer',
          background: 'linear-gradient(135deg, var(--hero-from), var(--hero-to))',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: '0 12px 30px -8px color-mix(in srgb, var(--primary) 60%, transparent)' }}>
          {state === 'listening' && <span style={{ position: 'absolute', inset: -8, borderRadius: 999,
            border: '3px solid var(--accent)', animation: 'ping 1.2s ease-out infinite' }} />}
          <Icon name="mic" size={36} fill={1} color="#fff" />
        </button>
        <span style={{ fontSize: 14, fontWeight: 700, color: 'var(--primary)' }}>{state === 'listening' ? 'Listening…' : 'Tap to speak'}</span>
        <div style={{ display: 'flex', gap: 12, width: '100%' }}>
          <GhostBtn icon="keyboard" onClick={tap} style={{ flex: 1, borderColor: 'var(--line)', color: 'var(--ink)' }}>Type instead</GhostBtn>
          <GhostBtn icon="check_circle" onClick={() => { window.speechSynthesis && window.speechSynthesis.cancel(); nav('feedback'); }}
            style={{ flex: 1, background: 'var(--surface-2)', borderColor: 'transparent' }}>End & feedback</GhostBtn>
        </div>
      </div>
    </div>
  );
}

// ── Feedback ─────────────────────────────────────────────────────────
function Feedback() {
  const { back, nav, resetTo } = useApp();
  const [added, setAdded] = React.useState(false);
  const [toast, setToast] = React.useState(false);
  const saveAll = () => { setToast(true); setTimeout(() => resetTo('home'), 1100); };
  return (
    <div style={{ minHeight: '100%', display: 'flex', flexDirection: 'column' }}>
      <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12, padding: '54px 20px 6px' }}>
        <button onClick={back} style={{ ...iconBtnStyle, marginTop: 2 }}><Icon name="close" size={26} color="var(--ink-soft)" /></button>
        <h1 style={{ fontSize: 24, fontWeight: 800, color: 'var(--ink)', margin: 0, letterSpacing: '-.02em', flex: 1, lineHeight: 1.2 }}>
          Nice chat! Here's how to level up</h1>
      </div>
      <div style={{ padding: '14px 20px 120px', display: 'flex', flexDirection: 'column', gap: 14 }}>
        <Card pad={17}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12 }}>
            <Icon name="auto_fix_high" size={20} color="var(--primary)" fill={1} />
            <span style={{ fontSize: 14.5, fontWeight: 700, color: 'var(--ink)' }}>Say it better</span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 12 }}>
            <div>
              <div style={{ fontSize: 16, color: 'var(--ink-mute)', textDecoration: 'line-through' }}>I am software engineer.</div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 8 }}>
                <Icon name="arrow_forward" size={18} color="var(--primary)" />
                <span style={{ fontSize: 17, fontWeight: 700, color: 'var(--ink)' }}>
                  I'm {added && <span style={{ color: 'var(--accent)' }}>a </span>}software engineer.</span>
              </div>
            </div>
            <button onClick={() => { setAdded(true); speak("I'm a software engineer."); }} disabled={added}
              style={{ flexShrink: 0, border: 'none', cursor: added ? 'default' : 'pointer', padding: '9px 13px', borderRadius: 'var(--r-sm)',
                background: added ? 'var(--surface-3)' : 'var(--surface-2)', color: 'var(--primary)', fontWeight: 800, fontSize: 12, letterSpacing: '.04em' }}>
              {added ? 'ADDED' : "ADD 'A'"}</button>
          </div>
        </Card>

        <Card pad={17}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 10 }}>
            <Icon name="chat" size={20} color="var(--primary)" />
            <span style={{ fontSize: 14.5, fontWeight: 700, color: 'var(--ink)' }}>Sounds more natural</span>
          </div>
          <div style={{ fontSize: 17, fontStyle: 'italic', color: 'var(--ink)', fontWeight: 600 }}>"I work as a software engineer"</div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: 8 }}>
            <Icon name="info" size={16} color="var(--ink-mute)" />
            <span style={{ fontSize: 13, color: 'var(--ink-soft)' }}>Used more commonly in social settings.</span>
          </div>
        </Card>

        <Card pad={17}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12 }}>
            <Icon name="record_voice_over" size={20} color="var(--primary)" />
            <span style={{ fontSize: 14.5, fontWeight: 700, color: 'var(--ink)' }}>Pronunciation</span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 12,
            background: 'var(--surface-2)', borderRadius: 'var(--r-sm)', padding: '13px 15px' }}>
            <div>
              <div style={{ fontSize: 18, fontWeight: 700, color: 'var(--ink)' }}>engineer</div>
              <div style={{ fontSize: 13.5, color: 'var(--ink-soft)', fontFamily: 'monospace' }}>/ˌen.dʒɪˈnɪər/</div>
            </div>
            <div style={{ display: 'flex', gap: 8 }}>
              <button onClick={() => speak('engineer', { slow: true })} style={{ width: 42, height: 42, borderRadius: 999, border: 'none', cursor: 'pointer',
                background: 'var(--surface-3)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Icon name="volume_up" size={21} color="var(--accent)" /></button>
              <button style={{ width: 42, height: 42, borderRadius: 999, cursor: 'pointer', background: 'transparent',
                border: '2px solid var(--primary)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Icon name="mic" size={20} color="var(--primary)" /></button>
            </div>
          </div>
        </Card>

        <div style={{ display: 'flex', gap: 10, background: 'var(--surface-2)', borderRadius: 'var(--r-panel)', padding: '14px 15px' }}>
          <Icon name="tips_and_updates" size={20} color="var(--accent)" fill={1} />
          <span style={{ fontSize: 14, color: 'var(--ink)', lineHeight: 1.45 }}>
            In English, always use <b>a</b> or <b>an</b> before a singular job title — "a teacher", "an engineer".</span>
        </div>
      </div>

      <div style={{ position: 'sticky', bottom: 0, padding: '14px 20px 26px',
        background: 'linear-gradient(to top, var(--bg) 55%, transparent)', marginTop: 'auto' }}>
        <PrimaryBtn icon="bookmark" onClick={saveAll}>Save what I learned</PrimaryBtn>
        <div style={{ textAlign: 'center', marginTop: 12 }}>
          <button onClick={() => nav('talklive')} style={{ background: 'none', border: 'none', cursor: 'pointer',
            color: 'var(--primary)', fontWeight: 700, fontSize: 15 }}>Talk again</button>
        </div>
      </div>
      {toast && <Toast text="Saved to your phrases" />}
    </div>
  );
}

function Toast({ text }) {
  return (
    <div style={{ position: 'absolute', left: '50%', bottom: 110, transform: 'translateX(-50%)', zIndex: 50,
      background: 'var(--ink)', color: '#fff', padding: '12px 20px', borderRadius: 999, fontSize: 14, fontWeight: 600,
      display: 'flex', alignItems: 'center', gap: 8, boxShadow: '0 10px 30px -8px rgba(0,0,0,0.4)', animation: 'pop .25s ease' }}>
      <Icon name="check_circle" size={19} color="var(--accent)" fill={1} />{text}</div>
  );
}

// ── Practice flashcards deck ─────────────────────────────────────────
function PracticeDeck() {
  const { back, nav, toggleSave, saved } = useApp();
  const deck = DATA.practiceDeck;
  const [i, setI] = React.useState(1);
  const card = deck.cards[i];
  const cid = 'deck' + i;
  const go = (d) => setI(v => Math.max(0, Math.min(deck.cards.length - 1, v + d)));
  return (
    <div style={{ minHeight: '100%', display: 'flex', flexDirection: 'column' }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '54px 18px 6px' }}>
        <button onClick={back} style={iconBtnStyle}><Icon name="menu" size={24} color="var(--ink-soft)" /></button>
        <div style={{ textAlign: 'center' }}>
          <div style={{ fontSize: 12.5, color: 'var(--ink-soft)', fontWeight: 600 }}>{deck.scene}</div>
          <div style={{ fontSize: 16, fontWeight: 800, color: 'var(--primary)' }}>{deck.lesson}</div>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ fontSize: 13, fontWeight: 700, color: 'var(--ink-soft)', background: 'var(--surface-2)', padding: '5px 11px', borderRadius: 999 }}>
            {i + 1} / {deck.cards.length}</span>
        </div>
      </div>

      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center', padding: '0 20px', position: 'relative' }}>
        <div style={{ position: 'relative' }}>
          {/* peek of next card */}
          <div style={{ position: 'absolute', inset: 0, transform: 'translateX(14px) scale(.95)', opacity: 0.5,
            background: 'var(--surface)', borderRadius: 'var(--r-card)', border: '1px solid var(--line)' }} />
          <Card pad={26} style={{ position: 'relative', minHeight: 280 }}>
            <Eyebrow style={{ marginBottom: 14 }}>Current card</Eyebrow>
            <div style={{ fontSize: 27, fontWeight: 800, color: 'var(--ink)', letterSpacing: '-.02em', lineHeight: 1.18 }}>{card.text}</div>
            <div style={{ marginTop: 22, background: 'color-mix(in srgb, var(--accent) 10%, white)', borderRadius: 'var(--r-panel)',
              padding: 16, display: 'flex', alignItems: 'center', gap: 12 }}>
              <button onClick={() => speak(card.text)} style={{ ...iconBtnStyle, width: 34, height: 34, flexShrink: 0 }}>
                <Icon name="volume_up" size={22} color="var(--accent)" /></button>
              <span style={{ flex: 1, fontSize: 14.5, fontStyle: 'italic', color: 'var(--ink-soft)', fontFamily: 'monospace' }}>{card.ipa}</span>
            </div>
            <div style={{ marginTop: 14 }}><HearBtn text={card.text} /></div>
          </Card>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 18, marginTop: 24 }}>
          <button onClick={() => go(-1)} disabled={i === 0} style={navArrow(i === 0)}><Icon name="chevron_left" size={26} color={i === 0 ? 'var(--ink-mute)' : 'var(--primary)'} /></button>
          <div style={{ display: 'flex', gap: 7 }}>
            {deck.cards.map((_, k) => <span key={k} onClick={() => setI(k)} style={{ cursor: 'pointer', height: 8, borderRadius: 999,
              width: k === i ? 22 : 8, background: k === i ? 'var(--primary)' : 'var(--surface-3)', transition: 'all .2s' }} />)}
          </div>
          <button onClick={() => go(1)} disabled={i === deck.cards.length - 1} style={navArrow(i === deck.cards.length - 1)}>
            <Icon name="chevron_right" size={26} color={i === deck.cards.length - 1 ? 'var(--ink-mute)' : 'var(--primary)'} /></button>
        </div>
      </div>

      <div style={{ padding: '16px 20px 20px', display: 'flex', gap: 12 }}>
        <GhostBtn icon={saved.has(cid) ? 'bookmark' : 'bookmark_border'} onClick={() => toggleSave(cid)}
          style={{ flex: '0 0 auto', background: 'var(--surface-2)', borderColor: 'transparent' }}>{saved.has(cid) ? 'Saved' : 'Save'}</GhostBtn>
        <PrimaryBtn icon="mic" onClick={() => nav('talklive', { scene: deck.scene })} style={{ flex: 1 }}>Practice this</PrimaryBtn>
      </div>
    </div>
  );
}
function navArrow(dis) {
  return { width: 48, height: 48, borderRadius: 999, cursor: dis ? 'default' : 'pointer',
    background: 'var(--surface)', border: '1px solid var(--line)', display: 'flex', alignItems: 'center', justifyContent: 'center',
    opacity: dis ? 0.5 : 1 };
}

// ── Phrase detail ────────────────────────────────────────────────────
function PhraseDetail() {
  const { back, nav, params, toggleSave, saved } = useApp();
  const p = DATA.phrases.find(x => x.id === params.id) || DATA.phrases[0];
  const [slow, setSlow] = React.useState(false);
  const isSaved = saved.has(p.id);
  return (
    <div style={{ minHeight: '100%', display: 'flex', flexDirection: 'column' }}>
      <TopBar title="Phrase Detail" onBack={back} accent
        action={<button onClick={() => toggleSave(p.id)} style={iconBtnStyle}>
          <Icon name={isSaved ? 'bookmark' : 'bookmark_border'} size={24} fill={isSaved ? 1 : 0} color="var(--primary)" /></button>} />
      <div style={{ padding: '10px 20px 120px' }}>
        <Eyebrow color="var(--ink-soft)" style={{ marginBottom: 12 }}>Today, try saying</Eyebrow>
        <Card pad={20}>
          <div style={{ fontSize: 28, fontWeight: 800, color: 'var(--ink)', letterSpacing: '-.02em', lineHeight: 1.15 }}>{p.text}</div>
          <Gloss fa={p.text_fa} size={16} style={{ marginTop: 10 }} />
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, margin: '18px 0', paddingTop: 16, paddingBottom: 16,
            borderTop: '1px solid var(--line)', borderBottom: '1px solid var(--line)' }}>
            <button onClick={() => speak(p.text, { slow })} style={{ width: 40, height: 40, borderRadius: 999, border: 'none', cursor: 'pointer',
              background: 'var(--surface-3)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
              <Icon name="volume_up" size={22} color="var(--accent)" /></button>
            <span style={{ flex: 1, fontSize: 14, color: 'var(--ink-soft)', fontFamily: 'monospace', whiteSpace: 'nowrap',
              overflow: 'hidden', textOverflow: 'ellipsis' }}>{p.ipa}</span>
            <HearBtn text={p.text} slow={slow} size="sm" />
            <button onClick={() => setSlow(s => !s)} style={{ display: 'flex', alignItems: 'center', gap: 6, background: 'none', border: 'none', cursor: 'pointer' }}>
              <span style={{ fontSize: 13, color: 'var(--ink-soft)', fontWeight: 600 }}>Slow</span>
              <span style={{ width: 38, height: 22, borderRadius: 999, background: slow ? 'var(--primary)' : 'var(--surface-3)',
                position: 'relative', transition: 'background .2s' }}>
                <span style={{ position: 'absolute', top: 2, left: slow ? 18 : 2, width: 18, height: 18, borderRadius: 999, background: '#fff', transition: 'left .2s' }} /></span>
            </button>
          </div>
          <div style={{ background: 'var(--surface-2)', borderRadius: 'var(--r-panel)', padding: '14px 16px' }}>
            <span style={{ fontSize: 14.5, color: 'var(--ink)', lineHeight: 1.5 }}>{p.meaning}</span>
            <Gloss fa={p.meaning_fa} size={14} style={{ marginTop: 8 }} />
          </div>
        </Card>

        <Eyebrow color="var(--ink-soft)" style={{ margin: '24px 0 12px' }}>When to use it</Eyebrow>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          {p.when.map((w, i) => (
            <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 12, background: 'color-mix(in srgb, var(--accent) 8%, white)',
              border: '1px solid var(--line)', borderRadius: 'var(--r-panel)', padding: '14px 16px' }}>
              <Icon name="check_circle" size={22} color="var(--primary)" fill={1} />
              <span style={{ fontSize: 14.5, color: 'var(--ink)' }}>{w}</span>
            </div>
          ))}
        </div>
      </div>
      <div style={{ position: 'sticky', bottom: 0, padding: '14px 20px 26px',
        background: 'linear-gradient(to top, var(--bg) 55%, transparent)', marginTop: 'auto' }}>
        <PrimaryBtn icon="mic" onClick={() => nav('talklive')}>Practice saying it</PrimaryBtn>
        <div style={{ textAlign: 'center', marginTop: 12 }}>
          <button onClick={() => toggleSave(p.id)} style={{ background: 'none', border: 'none', cursor: 'pointer',
            color: 'var(--primary)', fontWeight: 700, fontSize: 15 }}>{isSaved ? 'Remove from my phrases' : 'Save to my phrases'}</button>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { PracticeHub, TalkLive, Feedback, PracticeDeck, PhraseDetail, Toast });
