// screens-onboarding.jsx — Welcome, Language, Interests, Situations, BuildingBrief
// also exports DornaMark, ProgressDots

function DornaMark({ size = 30, color = 'var(--primary)', wave = 'var(--accent)' }) {
  return (
    <div style={{ display: 'inline-flex', flexDirection: 'column', alignItems: 'center', gap: 2 }}>
      <span style={{ fontSize: size, fontWeight: 800, letterSpacing: '-.02em', color, lineHeight: 1 }}>Dorna</span>
      <svg width={size * 2.1} height={size * 0.32} viewBox="0 0 100 14" fill="none" style={{ marginTop: -1 }}>
        <path d="M2 8 C 14 1, 26 1, 38 7 S 62 13, 74 7 S 92 3, 98 7" stroke={wave}
          strokeWidth="3.5" strokeLinecap="round" fill="none" />
      </svg>
    </div>
  );
}

function ProgressDots({ n, i }) {
  return (
    <div style={{ display: 'flex', gap: 7, alignItems: 'center' }}>
      {Array.from({ length: n }).map((_, k) => (
        <div key={k} style={{
          height: 7, borderRadius: 999, transition: 'all .3s',
          width: k === i ? 22 : 7,
          background: k === i ? 'var(--primary)' : (k < i ? 'var(--primary)' : 'var(--surface-3)'),
          opacity: k <= i ? 1 : 0.6,
        }} />
      ))}
    </div>
  );
}

function Welcome() {
  const { nav, resetTo } = useApp();
  return (
    <Screen pad={false} top={0} style={{ display: 'flex', flexDirection: 'column', minHeight: '100%' }}>
      <div style={{ textAlign: 'center', paddingTop: 56, paddingBottom: 14 }}>
        <DornaMark size={17} />
      </div>
      <div style={{ padding: '0 20px' }}>
        <div style={{
          borderRadius: 'var(--r-card)', overflow: 'hidden', position: 'relative',
          boxShadow: '0 18px 50px -20px rgba(16,40,64,0.45)',
          aspectRatio: '0.82', backgroundImage: 'url(dorna/assets/city-morning.png)',
          backgroundSize: 'cover', backgroundPosition: 'center top',
        }}>
          <div style={{ position: 'absolute', inset: 0,
            background: 'linear-gradient(to top, var(--bg) 2%, transparent 28%)' }} />
        </div>
      </div>
      <div style={{ padding: '20px 28px 0', textAlign: 'center', flex: 1 }}>
        <h1 style={{ fontSize: 31, fontWeight: 800, lineHeight: 1.12, letterSpacing: '-.02em',
          color: 'var(--ink)', margin: 0 }}>Speak with confidence,<br />every day.</h1>
        <p style={{ fontSize: 15.5, lineHeight: 1.55, color: 'var(--ink-soft)', marginTop: 16, maxWidth: 320, marginInline: 'auto' }}>
          Dorna learns your day and gives you the right words for real conversations — at work, at events, and around town.
        </p>
      </div>
      <div style={{ padding: '8px 24px 34px' }}>
        <PrimaryBtn onClick={() => nav('language')}>Get started</PrimaryBtn>
        <div style={{ textAlign: 'center', marginTop: 18 }}>
          <button onClick={() => resetTo('home')} style={{
            background: 'none', border: 'none', cursor: 'pointer', color: 'var(--primary)',
            fontWeight: 700, fontSize: 15.5 }}>I already have an account</button>
        </div>
      </div>
    </Screen>
  );
}

const LANGUAGES = [
  { id: 'en', autonym: 'English', name: 'English', code: 'EN', dir: 'ltr', hello: 'Hello' },
  { id: 'fa', autonym: '\u0641\u0627\u0631\u0633\u06cc', name: 'Persian', code: 'FA', dir: 'rtl', hello: '\u0633\u0644\u0627\u0645' },
];

function Language() {
  const { nav, back, nativeLang, setNativeLang } = useApp();
  return (
    <div style={{ minHeight: '100%', display: 'flex', flexDirection: 'column' }}>
      <div style={{ paddingTop: 54, paddingInline: 18, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <button onClick={back} style={iconBtnStyle}><Icon name="close" size={24} color="var(--ink-soft)" /></button>
        <ProgressDots n={5} i={0} />
        <div style={{ width: 40 }} />
      </div>
      <div style={{ padding: '14px 24px 0' }}>
        <h1 style={{ fontSize: 30, fontWeight: 800, color: 'var(--ink)', margin: 0, letterSpacing: '-.02em' }}>What's your native language?</h1>
        <p style={{ fontSize: 15, color: 'var(--ink-soft)', marginTop: 10, lineHeight: 1.5 }}>
          Dorna will explain new words and phrases in the language you know best.</p>
      </div>
      <div style={{ padding: '22px 20px 0', display: 'flex', flexDirection: 'column', gap: 12, flex: 1 }}>
        {LANGUAGES.map(l => {
          const on = nativeLang === l.id;
          return (
            <Card key={l.id} onClick={() => setNativeLang(l.id)} pad={16} soft style={{
              display: 'flex', alignItems: 'center', gap: 15,
              border: on ? '1.5px solid var(--primary)' : '1px solid var(--line)',
              background: on ? 'var(--surface-2)' : 'var(--surface)', transition: 'all .15s',
            }}>
              <div style={{ width: 52, height: 52, borderRadius: 16, flexShrink: 0,
                background: on ? heroBg() : 'var(--surface-3)',
                backgroundImage: on ? 'linear-gradient(135deg, var(--hero-from), var(--hero-to))' : 'none',
                display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <span style={{ fontSize: 16, fontWeight: 800, letterSpacing: '.02em',
                  color: on ? '#fff' : 'var(--primary)' }}>{l.code}</span>
              </div>
              <div style={{ flex: 1 }}>
                <div dir={l.dir} style={{ fontSize: 20, fontWeight: 700, color: 'var(--ink)', lineHeight: 1.15 }}>{l.autonym}</div>
                <div style={{ fontSize: 13.5, color: 'var(--ink-soft)', marginTop: 3, display: 'flex', alignItems: 'center', gap: 7 }}>
                  <span>{l.name}</span>
                  <span style={{ width: 3, height: 3, borderRadius: 999, background: 'var(--ink-mute)' }} />
                  <span dir={l.dir} style={{ fontStyle: 'italic' }}>“{l.hello}”</span>
                </div>
              </div>
              <div style={{ width: 24, height: 24, borderRadius: 999, flexShrink: 0,
                border: on ? 'none' : '2px solid var(--line)',
                background: on ? 'var(--primary)' : 'transparent',
                display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                {on && <Icon name="check" size={16} color="#fff" weight={600} />}
              </div>
            </Card>
          );
        })}
        <div style={{ display: 'flex', alignItems: 'center', gap: 7, justifyContent: 'center', marginTop: 6 }}>
          <Icon name="translate" size={15} color="var(--ink-mute)" />
          <span style={{ fontSize: 13, color: 'var(--ink-mute)' }}>You can change this anytime in Settings.</span>
        </div>
      </div>
      <div style={{ padding: '14px 24px 34px', background: 'linear-gradient(to top, var(--bg) 60%, transparent)' }}>
        <PrimaryBtn onClick={() => nav('interests')} icon="arrow_forward" disabled={!nativeLang}>Continue</PrimaryBtn>
      </div>
    </div>
  );
}

function Interests() {
  const { nav, interests, setInterests } = useApp();
  const toggle = (id) => setInterests(s => { const n = new Set(s); n.has(id) ? n.delete(id) : n.add(id); return n; });
  return (
    <div style={{ minHeight: '100%', display: 'flex', flexDirection: 'column' }}>
      <div style={{ paddingTop: 56, paddingInline: 20, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
        <ProgressDots n={5} i={1} />
      </div>
      <div style={{ padding: '22px 24px 0' }}>
        <h1 style={{ fontSize: 30, fontWeight: 800, color: 'var(--ink)', margin: 0, letterSpacing: '-.02em' }}>What are you into?</h1>
        <p style={{ fontSize: 15, color: 'var(--ink-soft)', marginTop: 10, lineHeight: 1.5 }}>
          Pick a few interests — Dorna uses them to suggest things to talk about.</p>
      </div>
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 10, padding: '24px 24px 0', alignContent: 'flex-start', flex: 1 }}>
        {DATA.interests.map(it => {
          const on = interests.has(it.id);
          return (
            <button key={it.id} onClick={() => toggle(it.id)} style={{
              display: 'inline-flex', alignItems: 'center', gap: 7, cursor: 'pointer',
              padding: '11px 18px', borderRadius: 999, fontSize: 15, fontWeight: 600,
              border: on ? '1.5px solid transparent' : '1.5px solid var(--line)',
              background: on ? 'linear-gradient(135deg, var(--hero-from), var(--hero-to))' : 'var(--surface)',
              color: on ? '#fff' : 'var(--ink)', WebkitTapHighlightColor: 'transparent',
              boxShadow: on ? '0 8px 18px -10px color-mix(in srgb, var(--primary) 60%, transparent)' : 'none',
              transition: 'all .15s',
            }}>
              {it.label}{on && <Icon name="check" size={17} color="#fff" weight={500} />}
            </button>
          );
        })}
      </div>
      <div style={{ padding: '12px 24px 34px', background: 'linear-gradient(to top, var(--bg) 60%, transparent)' }}>
        <PrimaryBtn onClick={() => nav('situations')} icon="arrow_forward" disabled={interests.size === 0}>Continue</PrimaryBtn>
      </div>
    </div>
  );
}

function Situations() {
  const { nav, back, situations, setSituations } = useApp();
  const toggle = (id) => setSituations(s => { const n = new Set(s); n.has(id) ? n.delete(id) : n.add(id); return n; });
  return (
    <div style={{ minHeight: '100%', display: 'flex', flexDirection: 'column' }}>
      <div style={{ paddingTop: 54, paddingInline: 18, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <button onClick={back} style={iconBtnStyle}><Icon name="close" size={24} color="var(--ink-soft)" /></button>
        <ProgressDots n={5} i={2} />
        <div style={{ width: 40 }} />
      </div>
      <div style={{ padding: '14px 24px 0' }}>
        <h1 style={{ fontSize: 28, fontWeight: 800, color: 'var(--ink)', margin: 0, letterSpacing: '-.02em' }}>What do you want to talk about?</h1>
        <p style={{ fontSize: 15, color: 'var(--ink-soft)', marginTop: 10, lineHeight: 1.5 }}>
          Choose the everyday situations you care about most.</p>
      </div>
      <div style={{ padding: '20px 20px 0', display: 'flex', flexDirection: 'column', gap: 11, flex: 1 }}>
        {DATA.situations.map(s => {
          const on = situations.has(s.id);
          return (
            <Card key={s.id} onClick={() => toggle(s.id)} pad={15} soft style={{
              display: 'flex', alignItems: 'center', gap: 14,
              border: on ? '1.5px solid var(--primary)' : '1px solid var(--line)',
              background: on ? 'var(--surface-2)' : 'var(--surface)', transition: 'all .15s',
            }}>
              <div style={{ width: 46, height: 46, borderRadius: 14, flexShrink: 0,
                background: on ? 'var(--primary)' : 'var(--surface-3)',
                display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Icon name={s.icon} size={24} color={on ? '#fff' : 'var(--primary)'} fill={on ? 1 : 0} />
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 15.5, fontWeight: 700, color: 'var(--ink)' }}>{s.title}</div>
                <div style={{ fontSize: 13.5, color: 'var(--ink-soft)', fontStyle: 'italic', marginTop: 2 }}>{s.ex}</div>
              </div>
              <div style={{ width: 24, height: 24, borderRadius: 999, flexShrink: 0,
                border: on ? 'none' : '2px solid var(--line)',
                background: on ? 'var(--primary)' : 'transparent',
                display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                {on && <Icon name="check" size={16} color="#fff" weight={600} />}
              </div>
            </Card>
          );
        })}
      </div>
      <div style={{ padding: '14px 24px 34px', background: 'linear-gradient(to top, var(--bg) 60%, transparent)' }}>
        <PrimaryBtn onClick={() => nav('calendar')} icon="arrow_forward" disabled={situations.size === 0}>Continue</PrimaryBtn>
      </div>
    </div>
  );
}

function BuildingBrief() {
  const { resetTo } = useApp();
  const [pct, setPct] = React.useState(8);
  React.useEffect(() => {
    const iv = setInterval(() => setPct(p => Math.min(100, p + 7 + Math.random() * 8)), 240);
    const to = setTimeout(() => resetTo('home'), 2800);
    return () => { clearInterval(iv); clearTimeout(to); };
  }, []);
  return (
    <div style={{ minHeight: '100%', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
      padding: '0 36px', position: 'relative',
      backgroundImage: 'linear-gradient(135deg, rgba(21,168,204,0.06), rgba(11,83,144,0.04))' }}>
      <div style={{ position: 'absolute', inset: 0, backgroundSize: '38px 38px', opacity: 0.5,
        backgroundImage: 'linear-gradient(var(--line) 1px, transparent 1px), linear-gradient(90deg, var(--line) 1px, transparent 1px)' }} />
      <div style={{ position: 'relative', textAlign: 'center', width: '100%' }}>
        <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'center', gap: 6, height: 56, marginBottom: 100 }}>
          {[0, 1, 2].map(i => (
            <div key={i} style={{ width: 7, borderRadius: 999, background: 'var(--accent)',
              animation: `wv ${0.8 + i * 0.15}s ease-in-out ${i * 0.12}s infinite`, height: '70%' }} />
          ))}
        </div>
        <h1 style={{ fontSize: 25, fontWeight: 800, color: 'var(--ink)', margin: 0, letterSpacing: '-.02em' }}>Building your first daily brief…</h1>
        <p style={{ fontSize: 15, color: 'var(--ink-soft)', marginTop: 12, lineHeight: 1.55 }}>
          Looking at your day, the weather, and what's worth talking about.</p>
        <div style={{ height: 6, borderRadius: 999, background: 'var(--surface-3)', marginTop: 30, overflow: 'hidden' }}>
          <div style={{ height: '100%', borderRadius: 999, width: pct + '%', transition: 'width .25s',
            background: 'linear-gradient(90deg, var(--hero-from), var(--hero-to))' }} />
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { DornaMark, ProgressDots, Welcome, Language, Interests, Situations, BuildingBrief });
