// screens-prep.jsx — EventPrep (networking), CoffeeScene

function ChatBubble({ children, faint }) {
  return (
    <div style={{ alignSelf: 'flex-start', maxWidth: '88%', padding: '13px 16px',
      borderRadius: '18px 18px 18px 5px', fontSize: 14.5, lineHeight: 1.45,
      background: faint ? 'var(--surface-2)' : 'color-mix(in srgb, var(--primary-container, #6ab2fe) 26%, white)',
      border: '1px solid var(--line)', color: 'var(--ink)' }}>{children}</div>
  );
}

function EventPrep() {
  const { back, nav } = useApp();
  const e = DATA.networking;
  return (
    <div style={{ minHeight: '100%', display: 'flex', flexDirection: 'column' }}>
      <TopBar title={e.title} sub={e.time} onBack={back} accent
        action={<button style={iconBtnStyle}><Icon name="calendar_today" size={22} color="var(--primary)" /></button>} />
      <div style={{ padding: '6px 20px 120px', display: 'flex', flexDirection: 'column', gap: 24 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 7, color: 'var(--ink-soft)' }}>
          <Icon name="location_on" size={18} color="var(--ink-soft)" />
          <span style={{ fontSize: 14, fontWeight: 600 }}>{e.place}</span>
        </div>

        <section>
          <Eyebrow style={{ marginBottom: 11 }}>Who you'll meet</Eyebrow>
          <Card pad={15} style={{ display: 'flex', alignItems: 'center', gap: 13 }}>
            <div style={{ display: 'flex' }}>
              {e.avatars.map((a, i) => <img key={i} src={a} alt="" style={{ width: 34, height: 34, borderRadius: 999,
                objectFit: 'cover', border: '2px solid var(--surface)', marginLeft: i ? -10 : 0 }} />)}
              <div style={{ width: 34, height: 34, borderRadius: 999, marginLeft: -10, background: 'var(--surface-3)',
                border: '2px solid var(--surface)', display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontSize: 11, fontWeight: 800, color: 'var(--primary)' }}>+12</div>
            </div>
            <span style={{ fontSize: 14, color: 'var(--ink)', fontWeight: 500 }}>{e.crowd}</span>
          </Card>
        </section>

        <section>
          <Eyebrow style={{ marginBottom: 11 }}>Break the ice</Eyebrow>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
            {e.icebreakers.map((t, i) => (
              <div key={i}>
                <div style={{ display: 'flex', alignItems: 'flex-end', gap: 8 }}>
                  <ChatBubble faint={i === 1}>{t}</ChatBubble>
                  <HearBtn text={t} variant="icon" />
                </div>
                <Gloss fa={e.icebreakers_fa && e.icebreakers_fa[i]} size={13.5} style={{ marginTop: 6, marginInline: '4px' }} />
              </div>
            ))}
          </div>
        </section>

        <section>
          <Eyebrow style={{ marginBottom: 14 }}>Keep it going</Eyebrow>
          <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between' }}>
            {e.steps.map((s, i) => (
              <React.Fragment key={s}>
                <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8, width: 64 }}>
                  <div style={{ width: 40, height: 40, borderRadius: 999, display: 'flex', alignItems: 'center', justifyContent: 'center',
                    fontWeight: 800, fontSize: 16,
                    background: i === 0 ? 'var(--primary)' : 'var(--surface-3)', color: i === 0 ? '#fff' : 'var(--primary)' }}>{i + 1}</div>
                  <span style={{ fontSize: 12.5, fontWeight: 600, color: 'var(--ink)' }}>{s}</span>
                </div>
                {i < e.steps.length - 1 && <div style={{ flex: 1, height: 2, background: 'var(--surface-3)', marginTop: 19 }} />}
              </React.Fragment>
            ))}
          </div>
        </section>

        <section>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 11 }}>
            <Eyebrow>Handy phrases</Eyebrow>
            <button onClick={() => nav('deck')} style={{ background: 'none', border: 'none', cursor: 'pointer',
              color: 'var(--primary)', fontWeight: 700, fontSize: 13 }}>View all</button>
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
            {['Nice to meet you!', 'What do you do for a living?'].map(p => (
              <Card key={p} pad={15} soft style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 10 }}>
                <span style={{ fontSize: 16, fontWeight: 600, color: 'var(--ink)' }}>{p}</span>
                <HearBtn text={p} variant="icon" />
              </Card>
            ))}
          </div>
        </section>
      </div>
      <StickyCTA><PrimaryBtn icon="mic" onClick={() => nav('talklive')}>Rehearse with Dorna</PrimaryBtn></StickyCTA>
    </div>
  );
}

function StickyCTA({ children }) {
  return (
    <div style={{ position: 'sticky', bottom: 0, padding: '14px 20px 28px',
      background: 'linear-gradient(to top, var(--bg) 55%, transparent)', marginTop: 'auto' }}>{children}</div>
  );
}

function CoffeeScene() {
  const { back, nav } = useApp();
  const c = DATA.coffee;
  return (
    <div style={{ minHeight: '100%', display: 'flex', flexDirection: 'column' }}>
      <TopBar title={c.title} onBack={back} accent
        action={<button style={iconBtnStyle}><Icon name="more_vert" size={22} color="var(--primary)" /></button>} />
      <div style={{ textAlign: 'center', marginTop: -4 }}>
        <span style={{ fontSize: 13.5, color: 'var(--ink-soft)', fontWeight: 600 }}>{c.vibe}</span>
      </div>
      <div style={{ padding: '14px 20px 120px', display: 'flex', flexDirection: 'column', gap: 18 }}>
        <div style={{ height: 132, borderRadius: 'var(--r-card)', position: 'relative', overflow: 'hidden',
          background: 'linear-gradient(135deg, #d9a878, #b9824f)' }}>
          <div style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <Icon name="local_cafe" size={56} color="rgba(255,255,255,0.85)" fill={1} />
          </div>
          <div style={{ position: 'absolute', top: 0, left: 0, right: 0, height: '60%',
            background: 'linear-gradient(to bottom, rgba(255,255,255,0.25), transparent)' }} />
        </div>

        <div>
          <Eyebrow color="var(--ink-soft)" style={{ marginBottom: 12 }}>Start a conversation</Eyebrow>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            {c.starters.map((s, i) => (
              <Card key={i} pad={16}>
                <div style={{ fontSize: 16.5, fontWeight: 700, color: 'var(--ink)', marginBottom: 4 }}>{s.text}</div>
                <Gloss fa={s.fa} size={14} style={{ marginBottom: 10 }} />
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 10 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 9, minWidth: 0 }}>
                    <button onClick={() => speak(s.text)} style={{ ...iconBtnStyle, width: 34, height: 34, flexShrink: 0 }}>
                      <Icon name="volume_up" size={20} color="var(--accent)" /></button>
                    <span style={{ fontSize: 13.5, fontStyle: 'italic', color: 'var(--ink-soft)', fontFamily: 'monospace',
                      whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{s.ipa}</span>
                  </div>
                  <HearBtn text={s.text} size="sm" />
                </div>
              </Card>
            ))}
          </div>
        </div>

        <div>
          <Eyebrow color="var(--ink-soft)" style={{ marginBottom: 11 }}>Quick tip</Eyebrow>
          <div style={{ display: 'flex', gap: 11, background: 'var(--surface-2)', borderRadius: 'var(--r-panel)', padding: '15px 16px' }}>
            <Icon name="lightbulb" size={22} color="var(--accent)" fill={1} />
            <div style={{ flex: 1 }}>
              <span style={{ fontSize: 14.5, color: 'var(--ink)', fontStyle: 'italic', lineHeight: 1.45 }}>{c.tip}</span>
              <Gloss fa={c.tip_fa} size={13.5} style={{ marginTop: 7 }} />
            </div>
          </div>
        </div>
      </div>
      <StickyCTA><PrimaryBtn icon="mic" onClick={() => nav('talklive')}>Practice with Dorna</PrimaryBtn></StickyCTA>
    </div>
  );
}

Object.assign(window, { EventPrep, CoffeeScene, ChatBubble, StickyCTA });
