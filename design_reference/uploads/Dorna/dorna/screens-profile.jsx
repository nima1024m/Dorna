// screens-profile.jsx — Profile, SavedPhrases, KeyboardIntro, KeyboardDemo, Settings

function Toggle({ on, onClick }) {
  return (
    <button onClick={onClick} style={{ width: 50, height: 30, borderRadius: 999, border: 'none', cursor: 'pointer', flexShrink: 0,
      background: on ? 'var(--primary)' : 'var(--surface-3)', position: 'relative', transition: 'background .2s' }}>
      <span style={{ position: 'absolute', top: 3, left: on ? 23 : 3, width: 24, height: 24, borderRadius: 999, background: '#fff',
        boxShadow: '0 1px 4px rgba(0,0,0,0.25)', transition: 'left .2s' }} />
    </button>
  );
}

function Profile() {
  const { nav } = useApp();
  const pf = DATA.profile;
  return (
    <div style={{ minHeight: '100%' }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '54px 20px 0' }}>
        <DornaMark size={22} />
        <div style={{ display: 'flex', gap: 8 }}>
          <button onClick={() => nav('settings')} style={iconBtnStyle}><Icon name="settings" size={24} color="var(--ink-soft)" /></button>
        </div>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', marginTop: 18 }}>
        <div style={{ position: 'relative' }}>
          <img src={DATA.user.avatar} alt="" style={{ width: 104, height: 104, borderRadius: 999, objectFit: 'cover',
            border: '4px solid var(--surface)', boxShadow: '0 8px 24px -10px rgba(16,40,64,0.4)' }} />
          <div style={{ position: 'absolute', bottom: 2, right: 2, width: 34, height: 34, borderRadius: 999, background: 'var(--primary)',
            border: '3px solid var(--bg)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <Icon name="military_tech" size={19} color="#fff" fill={1} /></div>
        </div>
        <h1 style={{ fontSize: 26, fontWeight: 800, color: 'var(--ink)', margin: '14px 0 0', letterSpacing: '-.02em' }}>{DATA.user.name}</h1>
        <div style={{ display: 'inline-flex', alignItems: 'center', gap: 6, marginTop: 8, background: 'var(--surface-3)',
          padding: '7px 15px', borderRadius: 999 }}>
          <Icon name="local_fire_department" size={18} color="var(--accent)" fill={1} />
          <span style={{ fontSize: 14, fontWeight: 700, color: 'var(--primary)' }}>{pf.streak}-day streak</span>
        </div>
      </div>

      <div style={{ padding: '22px 20px 28px', display: 'flex', flexDirection: 'column', gap: 18 }}>
        <div style={{ display: 'flex', gap: 11 }}>
          {[['phrases', 'Phrases learned'], ['conversations', 'Conversations'], ['briefs', 'Briefs heard']].map(([k, label]) => (
            <Card key={k} pad={14} soft style={{ flex: 1, textAlign: 'center' }}>
              <div style={{ fontSize: 26, fontWeight: 800, color: 'var(--primary)' }}>{pf.stats[k]}</div>
              <div style={{ fontSize: 11.5, color: 'var(--ink-soft)', marginTop: 2, lineHeight: 1.2 }}>{label}</div>
            </Card>
          ))}
        </div>

        <Card pad={18} style={{ position: 'relative', overflow: 'hidden' }}>
          <Icon name="trending_up" size={92} color="var(--surface-2)" style={{ position: 'absolute', top: -8, right: -8 }} />
          <div style={{ position: 'relative' }}>
            <div style={{ fontSize: 17, fontWeight: 800, color: 'var(--ink)' }}>You're improving</div>
            <p style={{ fontSize: 14, color: 'var(--ink-soft)', margin: '8px 0 14px', lineHeight: 1.45 }}>
              Keep practicing these areas to sound more natural:</p>
            <div style={{ display: 'flex', gap: 9, flexWrap: 'wrap' }}>
              {pf.weakAreas.map(w => (
                <span key={w} style={{ display: 'inline-flex', alignItems: 'center', gap: 7, background: 'var(--surface-2)',
                  padding: '8px 14px', borderRadius: 999, fontSize: 13.5, fontWeight: 600, color: 'var(--ink)' }}>
                  <span style={{ width: 7, height: 7, borderRadius: 999, background: 'var(--primary)' }} />{w}</span>
              ))}
            </div>
          </div>
        </Card>

        <div>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
            <span style={{ fontSize: 17, fontWeight: 800, color: 'var(--ink)' }}>Interests</span>
            <button onClick={() => nav('interests')} style={{ background: 'none', border: 'none', cursor: 'pointer',
              color: 'var(--primary)', fontWeight: 700, fontSize: 14 }}>Edit</button>
          </div>
          <div style={{ display: 'flex', gap: 9, flexWrap: 'wrap' }}>
            {pf.interests.map(it => (
              <span key={it} style={{ padding: '9px 16px', borderRadius: 999, fontSize: 14, fontWeight: 600, color: 'var(--ink)',
                background: 'var(--surface)', border: '1px solid var(--line)' }}>{it}</span>
            ))}
          </div>
        </div>

        <Card onClick={() => nav('saved')} pad={16} style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
          <div style={{ width: 46, height: 46, borderRadius: 13, background: 'var(--surface-2)',
            display: 'flex', alignItems: 'center', justifyContent: 'center' }}><Icon name="bookmark" size={24} color="var(--primary)" fill={1} /></div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 15.5, fontWeight: 700, color: 'var(--ink)' }}>Saved phrases</div>
            <div style={{ fontSize: 13, color: 'var(--ink-soft)' }}>{pf.savedCount} phrases collected</div>
          </div>
          <Icon name="chevron_right" size={22} color="var(--ink-mute)" />
        </Card>

        <Card onClick={() => nav('keyboardintro')} pad={16} style={{ display: 'flex', alignItems: 'center', gap: 14,
          background: 'linear-gradient(135deg, var(--hero-from), var(--hero-to))', border: 'none' }}>
          <div style={{ width: 46, height: 46, borderRadius: 13, background: 'rgba(255,255,255,0.18)',
            display: 'flex', alignItems: 'center', justifyContent: 'center' }}><Icon name="keyboard" size={24} color="#fff" /></div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 15.5, fontWeight: 700, color: '#fff' }}>Dorna keyboard</div>
            <div style={{ fontSize: 13, color: 'rgba(255,255,255,0.85)' }}>Fix your English anywhere you type</div>
          </div>
          <Icon name="chevron_right" size={22} color="#fff" />
        </Card>
      </div>
    </div>
  );
}

function SavedPhrases() {
  const { back, nav, saved } = useApp();
  const list = DATA.phrases.filter(p => saved.has(p.id));
  const extra = ["I'm a software engineer.", 'How\u2019s it going?'];
  return (
    <div style={{ minHeight: '100%' }}>
      <TopBar title="Saved phrases" onBack={back} accent />
      <div style={{ padding: '6px 20px 30px' }}>
        <p style={{ fontSize: 14, color: 'var(--ink-soft)', margin: '0 0 16px' }}>{list.length + extra.length} phrases collected · tap to review</p>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 11 }}>
          {list.map(p => (
            <Card key={p.id} onClick={() => nav('phrase', { id: p.id })} pad={15} style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 15.5, fontWeight: 700, color: 'var(--ink)' }}>{p.text}</div>
                <div style={{ fontSize: 12.5, color: 'var(--ink-mute)', fontFamily: 'monospace', whiteSpace: 'nowrap',
                  overflow: 'hidden', textOverflow: 'ellipsis' }}>{p.ipa}</div>
              </div>
              <HearBtn text={p.text} variant="icon" />
              <Icon name="chevron_right" size={20} color="var(--ink-mute)" />
            </Card>
          ))}
          {extra.map((t, i) => (
            <Card key={'x' + i} pad={15} style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 15.5, fontWeight: 700, color: 'var(--ink)' }}>{t}</div>
                <div style={{ fontSize: 12, color: 'var(--accent)', fontWeight: 700, marginTop: 2 }}>From your conversations</div>
              </div>
              <HearBtn text={t} variant="icon" />
            </Card>
          ))}
        </div>
      </div>
    </div>
  );
}

function KeyboardIntro() {
  const { back, nav } = useApp();
  const feats = [
    { icon: 'apps', t: 'Works in WhatsApp, Gmail, LinkedIn' },
    { icon: 'spellcheck', t: 'Grammar, tone & translate' },
    { icon: 'psychology', t: 'Learns your mistakes' },
  ];
  return (
    <div style={{ minHeight: '100%', display: 'flex', flexDirection: 'column' }}>
      <div style={{ padding: '54px 14px 0' }}>
        <button onClick={back} style={iconBtnStyle}><Icon name="arrow_back" size={24} color="var(--primary)" /></button>
      </div>
      <div style={{ padding: '8px 24px 0' }}>
        <h1 style={{ fontSize: 30, fontWeight: 800, color: 'var(--ink)', margin: 0, letterSpacing: '-.02em', lineHeight: 1.1 }}>Get Dorna on your keyboard</h1>
        <p style={{ fontSize: 15.5, color: 'var(--ink-soft)', marginTop: 12, lineHeight: 1.5 }}>
          Fix your English anywhere you type — and Dorna quietly learns from your mistakes to make tomorrow's brief better.</p>
      </div>

      {/* mini phone mock */}
      <div style={{ display: 'flex', justifyContent: 'center', padding: '26px 0 10px' }}>
        <div style={{ width: 210, borderRadius: 30, background: '#16283A', padding: 9,
          boxShadow: '0 20px 44px -18px rgba(16,40,64,0.5)' }}>
          <div style={{ background: 'var(--bg)', borderRadius: 22, overflow: 'hidden', height: 320, display: 'flex', flexDirection: 'column' }}>
            <div style={{ flex: 1, padding: 14, display: 'flex', flexDirection: 'column', gap: 10 }}>
              <div style={{ alignSelf: 'flex-start', width: '70%', height: 30, borderRadius: 12, background: 'var(--surface)', border: '1px solid var(--line)' }} />
              <div style={{ alignSelf: 'flex-end', width: '80%', height: 44, borderRadius: 14,
                background: 'color-mix(in srgb, var(--accent) 16%, white)' }} />
            </div>
            <div style={{ display: 'flex', gap: 6, padding: '0 10px 8px' }}>
              {[['auto_fix_high', 'Fix'], ['tune', 'Tone'], ['translate', 'Translate']].map(([ic, l]) => (
                <div key={l} style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 4,
                  background: 'color-mix(in srgb, var(--accent) 14%, white)', borderRadius: 9, padding: '7px 4px',
                  fontSize: 11, fontWeight: 700, color: 'var(--primary)' }}>
                  <Icon name={ic} size={14} color="var(--primary)" />{l}</div>
              ))}
            </div>
            <div style={{ background: 'var(--surface-3)', padding: 8, display: 'grid', gridTemplateColumns: 'repeat(10,1fr)', gap: 3 }}>
              {Array.from({ length: 20 }).map((_, i) => <div key={i} style={{ height: 16, borderRadius: 3, background: 'var(--surface)' }} />)}
            </div>
          </div>
        </div>
      </div>

      <div style={{ padding: '14px 24px 0', display: 'flex', flexDirection: 'column', gap: 14, flex: 1 }}>
        {feats.map(f => (
          <div key={f.t} style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
            <div style={{ width: 44, height: 44, borderRadius: 999, background: 'var(--surface-2)', flexShrink: 0,
              display: 'flex', alignItems: 'center', justifyContent: 'center' }}><Icon name={f.icon} size={22} color="var(--primary)" /></div>
            <span style={{ fontSize: 16, fontWeight: 600, color: 'var(--ink)' }}>{f.t}</span>
          </div>
        ))}
      </div>
      <div style={{ padding: '18px 24px 30px' }}>
        <PrimaryBtn icon="keyboard" onClick={() => nav('keyboarddemo')}>See it in action</PrimaryBtn>
      </div>
    </div>
  );
}

function KeyboardDemo() {
  const { back } = useApp();
  const [fixed, setFixed] = React.useState(false);
  const [banner, setBanner] = React.useState(true);
  return (
    <div style={{ minHeight: '100%', display: 'flex', flexDirection: 'column', height: '100%', background: 'var(--bg)' }}>
      {/* chat header */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '52px 16px 10px', borderBottom: '1px solid var(--line)' }}>
        <button onClick={back} style={iconBtnStyle}><Icon name="arrow_back" size={24} color="var(--primary)" /></button>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 16, fontWeight: 700, color: 'var(--ink)' }}>Sarah Miller</div>
          <div style={{ fontSize: 12, color: 'var(--accent)' }}>Active now</div>
        </div>
        <Icon name="videocam" size={24} color="var(--primary)" />
        <Icon name="call" size={22} color="var(--primary)" />
      </div>

      <div style={{ flex: 1, overflowY: 'auto', padding: '14px 16px', display: 'flex', flexDirection: 'column', gap: 10 }}>
        {banner && (
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, background: 'var(--surface)', border: '1px solid var(--line)',
            borderRadius: 'var(--r-panel)', padding: '12px 14px', boxShadow: '0 4px 16px -10px rgba(16,40,64,0.3)' }}>
            <div style={{ width: 32, height: 32, borderRadius: 999, background: 'color-mix(in srgb, var(--accent) 18%, white)',
              display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
              <Icon name="auto_awesome" size={18} color="var(--primary)" fill={1} /></div>
            <span style={{ flex: 1, fontSize: 13.5, fontWeight: 600, color: 'var(--ink)' }}>Learned a new mistake — added to your phrases</span>
            <button onClick={() => setBanner(false)} style={{ ...iconBtnStyle, width: 28, height: 28 }}><Icon name="close" size={18} color="var(--ink-mute)" /></button>
          </div>
        )}
        <div style={{ alignSelf: 'flex-start', maxWidth: '80%', background: 'color-mix(in srgb, var(--accent) 12%, white)',
          border: '1px solid var(--line)', borderRadius: '16px 16px 16px 5px', padding: '12px 15px', fontSize: 15, color: 'var(--ink)' }}>
          Hey! Welcome to Toronto! How is your first week going?</div>
        <div style={{ alignSelf: 'flex-start', maxWidth: '80%', background: 'color-mix(in srgb, var(--accent) 12%, white)',
          border: '1px solid var(--line)', borderRadius: '16px 16px 16px 5px', padding: '12px 15px', fontSize: 15, color: 'var(--ink)' }}>
          What are you working on these days?</div>
        <div style={{ alignSelf: 'flex-end', maxWidth: '85%', color: '#fff', borderRadius: '16px 16px 5px 16px', padding: '12px 15px',
          fontSize: 15, background: 'linear-gradient(135deg, var(--hero-from), var(--hero-to))' }}>
          {fixed ? "It's great. I'm a software engineer." : (
            <span>It's great. I am <span style={{ textDecorationLine: 'underline', textDecorationStyle: 'wavy', textDecorationColor: '#ffd2d0', textUnderlineOffset: 3 }}>software engineer.</span></span>
          )}
        </div>
        {!fixed && (
          <div style={{ alignSelf: 'flex-start', maxWidth: '88%', background: 'var(--surface-2)', borderRadius: 'var(--r-panel)', padding: '13px 15px' }}>
            <div style={{ display: 'flex', gap: 9 }}>
              <Icon name="lightbulb" size={20} color="var(--accent)" fill={1} />
              <span style={{ fontSize: 14, color: 'var(--ink)', lineHeight: 1.5 }}>
                <b>Pro tip:</b> In English, always use the article "a" or "an" before a singular profession.</span>
            </div>
          </div>
        )}
      </div>

      {/* Dorna suggestion toolbar */}
      <div style={{ background: 'var(--surface-2)', paddingTop: 8 }}>
        <div style={{ display: 'flex', gap: 8, padding: '0 12px 10px', overflowX: 'auto' }} className="no-sb">
          <button onClick={() => { setFixed(true); speak("I'm a software engineer."); }} style={{ flexShrink: 0, display: 'inline-flex',
            alignItems: 'center', gap: 7, background: 'color-mix(in srgb, var(--accent) 14%, white)', border: '1px solid var(--line)',
            borderRadius: 999, padding: '9px 15px', cursor: 'pointer', fontSize: 14, fontWeight: 700, color: 'var(--primary)' }}>
            <Icon name="auto_fix_high" size={17} color="var(--primary)" />I'm a software engineer.</button>
          {[['auto_fix_high', 'Fix', true], ['tune', 'Tone'], ['translate', 'Translate']].map(([ic, l, active]) => (
            <button key={l} onClick={() => l === 'Fix' && setFixed(true)} style={{ flexShrink: 0, display: 'inline-flex', alignItems: 'center', gap: 6,
              background: active ? 'linear-gradient(135deg, var(--hero-from), var(--hero-to))' : 'var(--surface)',
              border: active ? 'none' : '1px solid var(--line)', borderRadius: 999, padding: '9px 16px', cursor: 'pointer',
              fontSize: 14, fontWeight: 700, color: active ? '#fff' : 'var(--ink)' }}>
              <Icon name={ic} size={16} color={active ? '#fff' : 'var(--primary)'} />{l}</button>
          ))}
        </div>
        <MiniKeyboard />
      </div>
    </div>
  );
}

function MiniKeyboard() {
  const rows = ['qwertyuiop', 'asdfghjkl', 'zxcvbnm'];
  const Key = ({ ch, w }) => (
    <div style={{ flex: w || 1, height: 40, borderRadius: 6, background: '#fff', boxShadow: '0 1px 0 rgba(0,0,0,0.12)',
      display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 17, color: 'var(--ink)', textTransform: 'uppercase' }}>{ch}</div>
  );
  return (
    <div style={{ background: 'var(--surface-3)', padding: '8px 5px 26px', display: 'flex', flexDirection: 'column', gap: 7 }}>
      {rows.map((r, i) => (
        <div key={i} style={{ display: 'flex', gap: 5, padding: i === 1 ? '0 16px' : i === 2 ? '0 4px' : 0 }}>
          {i === 2 && <Key ch="⇧" w={1.5} />}
          {r.split('').map(c => <Key key={c} ch={c} />)}
          {i === 2 && <Key ch="⌫" w={1.5} />}
        </div>
      ))}
      <div style={{ display: 'flex', gap: 5 }}>
        <Key ch="123" w={1.5} /><Key ch="🙂" w={1} /><Key ch="space" w={5} /><Key ch="return" w={2} />
      </div>
    </div>
  );
}

// ── Lock-screen push preview ─────────────────────────────────────────
// Demonstrates the event-triggered reminder as it appears outside the app,
// ~2h before an event. Tapping the notification deep-links into event prep.
function NotificationPreview() {
  const { back, nav } = useApp();
  const n = DATA.notification;
  return (
    <div style={{ minHeight: '100%', height: '100%', position: 'relative', overflow: 'hidden',
      backgroundImage: 'url(dorna/assets/city-morning.png)', backgroundSize: 'cover', backgroundPosition: 'center' }}>
      <div style={{ position: 'absolute', inset: 0, background: 'linear-gradient(to bottom, rgba(10,30,52,0.05) 30%, rgba(10,30,52,0.45) 100%)' }} />

      {/* preview chip + close */}
      <div style={{ position: 'relative', zIndex: 2, paddingTop: 62, paddingInline: 18,
        display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6, fontSize: 12, fontWeight: 700,
          color: '#fff', background: 'rgba(255,255,255,0.22)', backdropFilter: 'blur(8px)', WebkitBackdropFilter: 'blur(8px)',
          padding: '6px 13px', borderRadius: 999, textShadow: '0 1px 6px rgba(0,0,0,0.3)' }}>
          <Icon name="lock" size={15} color="#fff" />Lock-screen preview</span>
        <button onClick={back} style={{ width: 36, height: 36, borderRadius: 999, border: 'none', cursor: 'pointer',
          background: 'rgba(255,255,255,0.22)', backdropFilter: 'blur(8px)', WebkitBackdropFilter: 'blur(8px)',
          display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <Icon name="close" size={22} color="#fff" /></button>
      </div>

      {/* clock */}
      <div style={{ position: 'relative', zIndex: 2, textAlign: 'center', marginTop: 26, color: '#fff',
        textShadow: '0 2px 16px rgba(0,0,0,0.35)' }}>
        <Icon name="lock" size={22} color="#fff" fill={1} style={{ opacity: 0.9 }} />
        <div style={{ fontSize: 16, fontWeight: 600, marginTop: 6, letterSpacing: '.01em' }}>{n.day}</div>
        <div style={{ fontSize: 86, fontWeight: 700, letterSpacing: '-.03em', lineHeight: 1, marginTop: 2,
          fontVariantNumeric: 'tabular-nums' }}>{n.time}</div>
      </div>

      {/* notification card */}
      <div style={{ position: 'absolute', left: 14, right: 14, bottom: 64, zIndex: 2 }}>
        <div onClick={() => nav('eventprep', { id: 'networking' })} style={{ cursor: 'pointer',
          background: 'rgba(255,255,255,0.82)', backdropFilter: 'blur(20px) saturate(180%)', WebkitBackdropFilter: 'blur(20px) saturate(180%)',
          borderRadius: 22, padding: '14px 15px', boxShadow: '0 16px 40px -16px rgba(0,0,0,0.5)',
          border: '0.5px solid rgba(255,255,255,0.5)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 9 }}>
            <div style={{ width: 26, height: 26, borderRadius: 7, flexShrink: 0,
              background: 'linear-gradient(135deg, var(--hero-from), var(--hero-to))',
              display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Icon name="graphic_eq" size={16} color="#fff" fill={1} /></div>
            <span style={{ fontSize: 12.5, fontWeight: 800, letterSpacing: '.04em', color: 'var(--ink-soft)', flex: 1 }}>{n.app}</span>
            <span style={{ fontSize: 12.5, color: 'var(--ink-mute)', fontWeight: 600 }}>{n.when}</span>
          </div>
          <div style={{ fontSize: 16, fontWeight: 700, color: 'var(--ink)', lineHeight: 1.3 }}>{n.title}</div>
          <div style={{ fontSize: 14.5, color: 'var(--ink-soft)', marginTop: 3, lineHeight: 1.4 }}>{n.body}</div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 5, marginTop: 11, color: 'var(--primary)', fontWeight: 700, fontSize: 13.5 }}>
            <Icon name="auto_awesome" size={16} color="var(--primary)" fill={1} />Tap to prep
            <Icon name="arrow_forward" size={16} color="var(--primary)" />
          </div>
        </div>
        <div style={{ textAlign: 'center', marginTop: 16, color: '#fff', fontSize: 13, fontWeight: 600,
          opacity: 0.9, textShadow: '0 1px 8px rgba(0,0,0,0.4)' }}>Sent ~2 hours before your event</div>
      </div>
    </div>
  );
}

function SettingsRow({ icon, title, detail, control, onClick, last }) {  return (
    <div onClick={onClick} style={{ display: 'flex', alignItems: 'center', gap: 13, padding: '14px 16px',
      borderBottom: last ? 'none' : '1px solid var(--line)', cursor: onClick ? 'pointer' : 'default' }}>
      <Icon name={icon} size={22} color="var(--primary)" />
      <span style={{ flex: 1, fontSize: 15.5, fontWeight: 600, color: 'var(--ink)' }}>{title}</span>
      {detail && <span style={{ fontSize: 14, color: 'var(--ink-soft)', fontWeight: 600 }}>{detail}</span>}
      {control}
    </div>
  );
}

function Settings() {
  const { back, nav, calendar, setCalendar, location, setLocation, nativeLang, setNativeLang } = useApp();
  const [tips, setTips] = React.useState(true);
  const langLabel = nativeLang === 'fa' ? '\u0641\u0627\u0631\u0633\u06cc' : 'English';
  return (
    <div style={{ minHeight: '100%' }}>
      <TopBar title="Settings" onBack={back} accent />
      <div style={{ padding: '6px 16px 36px', display: 'flex', flexDirection: 'column', gap: 22 }}>
        <Card pad={16} style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
          <div style={{ width: 52, height: 52, borderRadius: 999, background: 'var(--surface-3)',
            display: 'flex', alignItems: 'center', justifyContent: 'center' }}><Icon name="account_circle" size={32} color="var(--primary)" /></div>
          <div>
            <div style={{ fontSize: 17, fontWeight: 800, color: 'var(--ink)' }}>{DATA.user.name}</div>
            <div style={{ fontSize: 14, color: 'var(--ink-soft)' }}>{DATA.user.city}</div>
          </div>
        </Card>

        <div>
          <Eyebrow color="var(--ink-soft)" style={{ margin: '0 6px 10px' }}>Your day</Eyebrow>
          <Card pad={0} style={{ overflow: 'hidden' }}>
            <SettingsRow icon="calendar_today" title="Calendar" detail={calendar ? 'Connected' : 'Off'} control={<Toggle on={calendar} onClick={() => setCalendar(v => !v)} />} />
            <SettingsRow icon="location_on" title="Location" detail={location ? 'On' : 'Off'} control={<Toggle on={location} onClick={() => setLocation(v => !v)} />} />
            <SettingsRow icon="schedule" title="Daily brief time" detail="7:30 AM" control={<Icon name="chevron_right" size={20} color="var(--ink-mute)" />} />
            <SettingsRow icon="notifications_active" title="Event reminders" detail="Preview"
              control={<Icon name="chevron_right" size={20} color="var(--ink-mute)" />} onClick={() => nav('notification')} last />
          </Card>
        </div>

        <div>
          <Eyebrow color="var(--ink-soft)" style={{ margin: '0 6px 10px' }}>Explanations</Eyebrow>
          <Card pad={0} style={{ overflow: 'hidden' }}>
            <SettingsRow icon="translate" title="Your language" detail={langLabel}
              onClick={() => setNativeLang(l => (l === 'fa' ? 'en' : 'fa'))}
              control={<Icon name="unfold_more" size={20} color="var(--ink-mute)" />} />
            <SettingsRow icon="lightbulb" title="Simple English tips" control={<Toggle on={tips} onClick={() => setTips(v => !v)} />} last />
          </Card>
        </div>

        <div>
          <Eyebrow color="var(--ink-soft)" style={{ margin: '0 6px 10px' }}>Keyboard</Eyebrow>
          <Card pad={0} style={{ overflow: 'hidden' }}>
            <SettingsRow icon="keyboard" title="Dorna keyboard" detail="Set up" control={<Icon name="chevron_right" size={20} color="var(--ink-mute)" />}
              onClick={() => nav('keyboardintro')} last />
          </Card>
        </div>

        <div>
          <Eyebrow color="var(--ink-soft)" style={{ margin: '0 6px 10px' }}>Plan</Eyebrow>
          <Card pad={0} style={{ overflow: 'hidden' }}>
            <SettingsRow icon="workspace_premium" title="Free plan" control={
              <span style={{ fontSize: 13, fontWeight: 800, color: 'var(--primary)', background: 'var(--surface-3)', padding: '7px 15px', borderRadius: 999 }}>Upgrade</span>} last />
          </Card>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { Profile, SavedPhrases, KeyboardIntro, KeyboardDemo, Settings, NotificationPreview, Toggle, MiniKeyboard });
