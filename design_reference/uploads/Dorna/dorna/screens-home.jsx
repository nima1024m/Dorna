// screens-home.jsx — Home (3 layouts), BriefPlayer, AroundYou
// exports: Home, BriefPlayer, AroundYou, MiniPlayer

function fmt(s) { const m = Math.floor(s / 60), ss = String(s % 60).padStart(2, '0'); return `${m}:${ss}`; }
function greeting() { const h = new Date().getHours(); return h < 12 ? 'Good morning' : h < 18 ? 'Good afternoon' : 'Good evening'; }

function HomeHeader() {
  const { nav } = useApp();
  const w = DATA.weather;
  const streak = DATA.profile.streak;
  return (
    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', padding: '56px 20px 0' }}>
      <div style={{ minWidth: 0 }}>
        <h1 style={{ fontSize: 27, fontWeight: 800, color: 'var(--ink)', margin: 0, letterSpacing: '-.02em' }}>
          {greeting()}, {DATA.user.name}</h1>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 9, flexWrap: 'wrap' }}>
          <span style={{ fontSize: 13.5, color: 'var(--ink-soft)', fontWeight: 600 }}>{DATA.brief.date.replace('Monday', 'Mon')}</span>
          <span style={{ width: 4, height: 4, borderRadius: 999, background: 'var(--ink-mute)' }} />
          <div style={{ display: 'inline-flex', alignItems: 'center', gap: 5, background: 'var(--surface)',
            border: '1px solid var(--line)', padding: '3px 10px', borderRadius: 999 }}>
            <Icon name={w.icon} size={15} color="var(--accent)" fill={1} />
            <span style={{ fontSize: 12.5, color: 'var(--ink-soft)', fontWeight: 600 }}>{w.temp} · {w.label}</span>
          </div>
          <div style={{ display: 'inline-flex', alignItems: 'center', gap: 5, background: 'var(--surface-2)',
            padding: '3px 10px', borderRadius: 999 }}>
            <Icon name="checkroom" size={15} color="var(--primary)" />
            <span style={{ fontSize: 12.5, color: 'var(--primary)', fontWeight: 700 }}>{w.wear}</span>
          </div>
        </div>
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, flexShrink: 0 }}>
        <button onClick={() => nav('profile')} title={`${streak}-day streak`} style={{ border: 'none', cursor: 'pointer',
          display: 'inline-flex', alignItems: 'center', gap: 4, padding: '7px 11px', borderRadius: 999,
          background: 'var(--surface)', boxShadow: '0 2px 10px -5px rgba(16,40,64,0.35)' }}>
          <Icon name="local_fire_department" size={18} color="var(--accent)" fill={1} />
          <span style={{ fontSize: 14, fontWeight: 800, color: 'var(--ink)', fontVariantNumeric: 'tabular-nums' }}>{streak}</span>
        </button>
        <button onClick={() => nav('profile')} style={{ border: 'none', background: 'none', padding: 0, cursor: 'pointer' }}>
          <img src={DATA.user.avatar} alt="" style={{ width: 46, height: 46, borderRadius: 999,
            objectFit: 'cover', border: '2px solid var(--surface)', boxShadow: '0 2px 10px -3px rgba(16,40,64,0.3)' }} />
        </button>
      </div>
    </div>
  );
}

// Event-triggered reminder banner — mirrors the lock-screen push, surfaced on Home.
function EventReminder() {
  const { nav, reminderSeen, setReminderSeen } = useApp();
  if (reminderSeen) return null;
  const ev = DATA.events[0];
  return (
    <div onClick={() => nav('eventprep', { id: ev.id })} style={{ cursor: 'pointer', position: 'relative',
      display: 'flex', alignItems: 'center', gap: 13, padding: '14px 14px 14px 16px',
      borderRadius: 'var(--r-card)', background: 'var(--surface)', border: '1px solid var(--line)',
      borderLeft: '4px solid var(--accent)', boxShadow: '0 8px 26px -16px rgba(16,40,64,0.45)' }}>
      <div style={{ width: 42, height: 42, borderRadius: 12, flexShrink: 0, position: 'relative',
        background: 'color-mix(in srgb, var(--accent) 16%, white)',
        display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <Icon name="notifications_active" size={22} color="var(--primary)" fill={1} />
        <span style={{ position: 'absolute', top: 9, right: 9, width: 7, height: 7, borderRadius: 999,
          background: 'var(--accent)' }} className="dot-pulse" />
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 11, fontWeight: 800, letterSpacing: '.06em', textTransform: 'uppercase',
          color: 'var(--accent)' }}>Heads up · {ev.time}</div>
        <div style={{ fontSize: 14.5, fontWeight: 700, color: 'var(--ink)', marginTop: 2 }}>{ev.title} — 3 openers ready</div>
      </div>
      <button onClick={(e) => { e.stopPropagation(); setReminderSeen(true); }}
        style={{ ...iconBtnStyle, width: 30, height: 30, flexShrink: 0 }} aria-label="Dismiss">
        <Icon name="close" size={18} color="var(--ink-mute)" />
      </button>
    </div>
  );
}

// Daily challenge — the habit hook. Doubles as the brief's closing segment.
function ChallengeCard() {
  const { challengeDone, setChallengeDone } = useApp();
  const c = DATA.challenge;
  return (
    <Card pad={17} style={{ borderColor: challengeDone ? 'var(--accent)' : 'var(--line)' }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <Icon name="bolt" size={19} color="var(--accent)" fill={1} />
          <span style={{ fontSize: 12, fontWeight: 800, letterSpacing: '.06em', textTransform: 'uppercase', color: 'var(--ink-soft)' }}>Today's challenge</span>
        </div>
        <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4, fontSize: 12, fontWeight: 700,
          color: 'var(--accent)' }}>
          <Icon name="local_fire_department" size={15} color="var(--accent)" fill={1} />Keeps your streak
        </span>
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <span style={{ fontSize: 19, fontWeight: 800, color: 'var(--ink)', letterSpacing: '-.01em' }}>{c.phrase}</span>
        <HearBtn text={c.phrase} variant="icon" />
      </div>
      <div style={{ fontSize: 14, color: 'var(--ink-soft)', marginTop: 8, lineHeight: 1.45 }}>{c.task}</div>
      <Gloss fa={c.task_fa} />
      <button onClick={() => setChallengeDone(v => !v)} style={{ marginTop: 14, width: '100%', cursor: 'pointer',
        display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, padding: '12px', borderRadius: 'var(--r-btn)',
        border: challengeDone ? 'none' : '1.5px solid var(--primary)',
        background: challengeDone ? 'linear-gradient(135deg, var(--hero-from), var(--hero-to))' : 'transparent',
        color: challengeDone ? '#fff' : 'var(--primary)', fontWeight: 700, fontSize: 15 }}>
        <Icon name={challengeDone ? 'check_circle' : 'radio_button_unchecked'} size={20} fill={challengeDone ? 1 : 0}
          color={challengeDone ? '#fff' : 'var(--primary)'} />
        {challengeDone ? 'Done today — nice work!' : 'Mark as done'}
      </button>
    </Card>
  );
}

function HeroBrief({ compact = false }) {
  const { nav, audio, audioCtl, t } = useApp();
  const onPlay = (e) => { e.stopPropagation(); audioCtl.play(); nav('brief'); };
  if (compact) {
    return (
      <div onClick={() => nav('brief')} style={{ display: 'flex', alignItems: 'center', gap: 14, cursor: 'pointer',
        borderRadius: 'var(--r-card)', padding: 16, color: '#fff',
        background: 'linear-gradient(135deg, var(--hero-from), var(--hero-to))',
        boxShadow: '0 14px 34px -16px color-mix(in srgb, var(--primary) 70%, transparent)' }}>
        <button onClick={onPlay} style={{ width: 52, height: 52, borderRadius: 999, border: 'none', cursor: 'pointer',
          background: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
          <Icon name="play_arrow" size={30} fill={1} color="var(--primary)" />
        </button>
        <div style={{ flex: 1 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <span style={{ fontSize: 17, fontWeight: 800 }}>Your 5-min brief</span>
            <span style={{ fontSize: 10.5, fontWeight: 700, background: 'rgba(255,255,255,0.22)', padding: '2px 8px', borderRadius: 999 }}>5 MIN</span>
          </div>
          <div style={{ opacity: 0.85, fontSize: 13, marginTop: 2 }}>Events, phrases & a bit of news</div>
        </div>
        <div style={{ width: 46, height: 30 }}><Waveform playing={t.bigWaveform} color="rgba(255,255,255,0.85)" count={9} height={30} seed={3} /></div>
      </div>
    );
  }
  return (
    <div onClick={() => nav('brief')} style={{ position: 'relative', overflow: 'hidden', cursor: 'pointer',
      borderRadius: 'var(--r-card)', padding: 24, color: '#fff', minHeight: 230,
      background: 'linear-gradient(135deg, var(--hero-from), var(--hero-to))',
      boxShadow: '0 20px 44px -18px color-mix(in srgb, var(--primary) 72%, transparent)',
      display: 'flex', flexDirection: 'column' }}>
      <div style={{ position: 'absolute', top: -40, right: -30, width: 180, height: 180, borderRadius: 999,
        background: 'rgba(255,255,255,0.08)' }} />
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', position: 'relative' }}>
        <h2 style={{ fontSize: 30, fontWeight: 800, margin: 0, letterSpacing: '-.02em', lineHeight: 1.05 }}>Your 5-min<br />brief</h2>
        <span style={{ fontSize: 11, fontWeight: 700, background: 'rgba(255,255,255,0.2)', backdropFilter: 'blur(6px)',
          padding: '5px 12px', borderRadius: 999, border: '1px solid rgba(255,255,255,0.25)' }}>5 MIN</span>
      </div>
      <p style={{ fontSize: 14.5, opacity: 0.9, marginTop: 8, maxWidth: 230, position: 'relative' }}>
        Today's events, useful phrases & a bit of news.</p>
      <div style={{ flex: 1 }} />
      <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', position: 'relative', marginTop: 14 }}>
        <button onClick={onPlay} style={{ width: 58, height: 58, borderRadius: 999, border: 'none', cursor: 'pointer',
          background: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: '0 8px 20px -6px rgba(0,0,0,0.3)' }}>
          <Icon name="play_arrow" size={34} fill={1} color="var(--primary)" style={{ marginLeft: 2 }} />
        </button>
        <div style={{ width: 130, height: 44, opacity: 0.9 }}>
          <Waveform playing={t.bigWaveform} color="#fff" count={22} height={44} seed={5} />
        </div>
      </div>
    </div>
  );
}

function QuickAction({ icon, title, sub, onClick, accent }) {
  return (
    <Card onClick={onClick} pad={15} soft style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 10, minWidth: 0 }}>
      <div style={{ width: 40, height: 40, borderRadius: 12, display: 'flex', alignItems: 'center', justifyContent: 'center',
        background: accent ? 'linear-gradient(135deg, var(--hero-from), var(--hero-to))' : 'var(--surface-3)' }}>
        <Icon name={icon} size={22} color={accent ? '#fff' : 'var(--primary)'} fill={accent ? 1 : 0} />
      </div>
      <div>
        <div style={{ fontSize: 14.5, fontWeight: 700, color: 'var(--ink)' }}>{title}</div>
        <div style={{ fontSize: 12.5, color: 'var(--ink-soft)', marginTop: 1 }}>{sub}</div>
      </div>
    </Card>
  );
}

function PlanList() {
  const { nav } = useApp();
  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 11 }}>
        <Eyebrow color="var(--ink-soft)">Today's plan</Eyebrow>
        <Icon name="calendar_today" size={18} color="var(--ink-mute)" />
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
        {DATA.events.map(ev => (
          <Card key={ev.id} onClick={() => nav(ev.kind === 'coffee' ? 'coffee' : 'eventprep', { id: ev.id })}
            pad={15} soft style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <span style={{ width: 9, height: 9, borderRadius: 999, flexShrink: 0,
              background: ev.dot === 'accent' ? 'var(--accent)' : 'var(--primary)' }} />
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 15, fontWeight: 700, color: 'var(--ink)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                <span style={{ color: 'var(--primary)' }}>{ev.time}</span> — {ev.title}</div>
            </div>
            <span style={{ fontSize: 11.5, fontWeight: 800, color: 'var(--primary)', background: 'var(--surface-3)',
              padding: '5px 13px', borderRadius: 999, display: 'inline-flex', alignItems: 'center', gap: 4 }}>
              <Icon name="auto_awesome" size={14} color="var(--primary)" />Prep</span>
          </Card>
        ))}
      </div>
      {/* Tomorrow peek — keeps the brief looking ahead */}
      {DATA.tomorrow && DATA.tomorrow.length > 0 && (
        <div style={{ marginTop: 16 }}>
          <Eyebrow color="var(--ink-mute)" style={{ marginBottom: 9, fontSize: 10.5 }}>Tomorrow</Eyebrow>
          {DATA.tomorrow.map(ev => (
            <Card key={ev.id} onClick={() => nav(ev.kind === 'coffee' ? 'coffee' : 'eventprep', { id: ev.id })}
              pad={13} soft style={{ display: 'flex', alignItems: 'center', gap: 12, background: 'transparent',
              border: '1px dashed var(--line)', boxShadow: 'none' }}>
              <Icon name="wb_twilight" size={20} color="var(--ink-mute)" />
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 14, fontWeight: 600, color: 'var(--ink-soft)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                  <span style={{ fontWeight: 700, color: 'var(--ink)' }}>{ev.time}</span> · {ev.title}</div>
              </div>
              <Icon name="chevron_right" size={20} color="var(--ink-mute)" />
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}

function AroundTeaser() {
  const { nav } = useApp();
  return (
    <Card onClick={() => nav('aroundyou')} pad={14} soft style={{ display: 'flex', alignItems: 'center', gap: 13,
      background: 'var(--surface-2)' }}>
      <div style={{ width: 44, height: 44, borderRadius: 13, background: 'var(--surface)', flexShrink: 0,
        display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 2px 8px -4px rgba(16,40,64,0.3)' }}>
        <Icon name="explore" size={25} color="var(--primary)" />
      </div>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 14.5, fontWeight: 700, color: 'var(--ink)' }}>Near Central Library</div>
        <div style={{ fontSize: 12.5, color: 'var(--ink-soft)', marginTop: 1 }}>Tips for starting a chat here</div>
      </div>
      <Icon name="chevron_right" size={22} color="var(--ink-mute)" />
    </Card>
  );
}

function Home() {
  const { t, audio } = useApp();
  const layout = t.homeLayout || 'Hero';
  const bottomPad = audio.started ? 92 : 24;
  return (
    <div style={{ minHeight: '100%', position: 'relative' }}>
      <HomeHeader />
      <div style={{ padding: '20px 20px', paddingBottom: bottomPad, display: 'flex', flexDirection: 'column', gap: 20 }}>
        <EventReminder />
        {layout === 'Compact' && <>
          <HeroBrief compact />
          <ChallengeCard />
          <PlanList />
          <div style={{ display: 'flex', gap: 12 }}>
            <HeroQuick icon="mic" title="Talk live" sub="Practice now" accent screen="talklive" />
            <HeroQuick icon="explore" title="Around you" sub="Local tips" screen="aroundyou" />
          </div>
        </>}
        {layout === 'Cards' && <>
          <HeroBrief />
          <ChallengeCard />
          <HomeCardsGrid />
          <PlanList />
        </>}
        {layout === 'Hero' && <>
          <HeroBrief />
          <ChallengeCard />
          <div style={{ display: 'flex', gap: 12 }}>
            <HeroQuick icon="mic" title="Talk with Dorna" sub="Live practice" accent screen="talklive" />
            <HeroQuick icon="explore" title="Around you" sub="Local tips" screen="aroundyou" />
          </div>
          <PlanList />
          <AroundTeaser />
        </>}
      </div>
      {audio.started && <MiniPlayer />}
    </div>
  );
}

function HeroQuick({ icon, title, sub, accent, screen }) {
  const { nav } = useApp();
  return <QuickAction icon={icon} title={title} sub={sub} accent={accent} onClick={() => nav(screen)} />;
}
function useAppNav(s) { /* placeholder kept for Compact branch */ }

function HomeCardsGrid() {
  const { nav } = useApp();
  const items = [
    { icon: 'mic', title: 'Talk with Dorna', sub: 'Live practice', accent: true, s: 'talklive' },
    { icon: 'style', title: 'Practice cards', sub: 'Break the ice', s: 'deck' },
    { icon: 'explore', title: 'Around you', sub: 'Local tips', s: 'aroundyou' },
    { icon: 'bookmark', title: 'Saved phrases', sub: `${DATA.profile.savedCount} collected`, s: 'saved' },
  ];
  return (
    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
      {items.map(it => <QuickAction key={it.title} icon={it.icon} title={it.title} sub={it.sub} accent={it.accent} onClick={() => nav(it.s)} />)}
    </div>
  );
}

function MiniPlayer() {
  const { nav, audio, audioCtl, t } = useApp();
  return (
    <div style={{ position: 'absolute', left: 12, right: 12, bottom: 12, zIndex: 20,
      display: 'flex', alignItems: 'center', gap: 12, padding: '10px 12px',
      background: 'rgba(255,255,255,0.9)', backdropFilter: 'blur(16px)', WebkitBackdropFilter: 'blur(16px)',
      borderRadius: 'var(--r-panel)', border: '1px solid var(--line)', boxShadow: '0 10px 30px -12px rgba(16,40,64,0.4)' }}>
      <button onClick={() => audioCtl.toggle()} style={{ width: 40, height: 40, borderRadius: 12, border: 'none', cursor: 'pointer',
        background: 'linear-gradient(135deg, var(--hero-from), var(--hero-to))', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <Icon name={audio.playing ? 'pause' : 'play_arrow'} size={22} fill={1} color="#fff" />
      </button>
      <div onClick={() => nav('brief')} style={{ flex: 1, cursor: 'pointer' }}>
        <div style={{ fontSize: 11, fontWeight: 800, letterSpacing: '.08em', textTransform: 'uppercase', color: 'var(--ink-soft)' }}>Morning brief</div>
        <div style={{ height: 14, marginTop: 2, opacity: 0.6 }}><Waveform playing={audio.playing} color="var(--primary)" count={20} height={14} seed={2} /></div>
      </div>
      <span style={{ fontSize: 12, fontWeight: 700, color: 'var(--ink-soft)', fontVariantNumeric: 'tabular-nums' }}>{fmt(audio.time)}</span>
      <button onClick={() => audioCtl.pause()} style={{ ...iconBtnStyle, width: 32, height: 32 }}><Icon name="close" size={20} color="var(--ink-mute)" /></button>
    </div>
  );
}

// ── Daily brief audio player ─────────────────────────────────────────
function BriefPlayer() {
  const { back, audio, audioCtl, t, toggleSave, saved, nativeLang } = useApp();
  const [speed, setSpeed] = React.useState(1);
  const [showFa, setShowFa] = React.useState(false);
  const segs = DATA.brief.segments;
  const seg = segs[audio.seg] || segs[0];
  const pct = (audio.time / DATA.brief.duration) * 100;
  const cycleSpeed = () => setSpeed(s => (s === 1 ? 1.25 : s === 1.25 ? 1.5 : 1));
  const seekRef = React.useRef(null);
  const onSeek = (e) => {
    const r = seekRef.current.getBoundingClientRect();
    const x = (e.clientX - r.left) / r.width;
    audioCtl.seek(Math.round(x * DATA.brief.duration));
  };
  const phraseId = 'p1';
  return (
    <div style={{ minHeight: '100%', display: 'flex', flexDirection: 'column' }}>
      <TopBar title="Daily Brief" sub={null} onBack={back} accent
        action={<button style={iconBtnStyle}><Icon name="calendar_today" size={22} color="var(--primary)" /></button>} />
      <div style={{ textAlign: 'center', marginTop: -6, marginBottom: 4 }}>
        <span style={{ fontSize: 12.5, color: 'var(--ink-soft)', fontWeight: 600 }}>{DATA.brief.date}</span>
      </div>
      <div style={{ padding: '12px 20px 24px', display: 'flex', flexDirection: 'column', gap: 18 }}>
        {/* player card */}
        <div style={{ borderRadius: 'var(--r-card)', padding: 22, color: '#fff', position: 'relative', overflow: 'hidden',
          background: 'linear-gradient(150deg, var(--hero-from), var(--hero-to))',
          boxShadow: '0 20px 44px -18px color-mix(in srgb, var(--primary) 72%, transparent)' }}>
          <div style={{ position: 'absolute', top: -30, right: -20, width: 130, height: 130, borderRadius: 999, background: 'rgba(255,255,255,0.07)' }} />
          <div style={{ textAlign: 'center', position: 'relative' }}>
            <span style={{ fontSize: 10.5, fontWeight: 800, letterSpacing: '.12em', textTransform: 'uppercase',
              background: 'rgba(255,255,255,0.18)', padding: '6px 14px', borderRadius: 999 }}>{seg.label}</span>
          </div>
          <div style={{ height: 96, margin: '20px 0 18px', position: 'relative' }}>
            <Waveform playing={audio.playing} color="#fff" count={32} height={96} seed={audio.seg + 1} />
          </div>
          {/* progress */}
          <div ref={seekRef} onClick={onSeek} style={{ height: 6, borderRadius: 999, background: 'rgba(255,255,255,0.22)', cursor: 'pointer', position: 'relative' }}>
            <div style={{ height: '100%', width: pct + '%', borderRadius: 999, background: '#fff', position: 'relative' }}>
              <div style={{ position: 'absolute', right: -6, top: '50%', transform: 'translateY(-50%)', width: 13, height: 13,
                borderRadius: 999, background: '#fff', border: '2px solid var(--primary)' }} />
            </div>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 11.5, fontWeight: 700, opacity: 0.85, marginTop: 7,
            fontVariantNumeric: 'tabular-nums' }}>
            <span>{fmt(audio.time)}</span><span>{fmt(DATA.brief.duration)}</span>
          </div>
          {/* transport */}
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: 16 }}>
            <button onClick={cycleSpeed} style={{ background: 'rgba(255,255,255,0.12)', border: '1px solid rgba(255,255,255,0.22)',
              color: '#fff', fontWeight: 800, fontSize: 12.5, padding: '7px 13px', borderRadius: 999, cursor: 'pointer' }}>{speed}x</button>
            <div style={{ display: 'flex', alignItems: 'center', gap: 22 }}>
              <button onClick={() => audioCtl.nudge(-15)} style={transBtn}><Icon name="replay" size={28} color="#fff" /></button>
              <button onClick={() => audioCtl.toggle()} style={{ width: 64, height: 64, borderRadius: 999, border: 'none', cursor: 'pointer',
                background: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 8px 20px -6px rgba(0,0,0,0.3)' }}>
                <Icon name={audio.playing ? 'pause' : 'play_arrow'} size={36} fill={1} color="var(--primary)" />
              </button>
              <button onClick={() => audioCtl.nudge(15)} style={transBtn}><Icon name="forward_media" size={28} color="#fff" /></button>
            </div>
            <button onClick={() => speak(seg.transcript)} style={transBtn}><Icon name="campaign" size={26} color="#fff" /></button>
          </div>
        </div>

        {/* segments */}
        <div>
          <Eyebrow color="var(--ink-soft)" style={{ marginBottom: 10 }}>Segments</Eyebrow>
          <div style={{ display: 'flex', gap: 8, overflowX: 'auto', paddingBottom: 4 }} className="no-sb">
            {segs.map((s, i) => {
              const on = i === audio.seg;
              return (
                <button key={s.id} onClick={() => audioCtl.setSeg(i)} style={{ flexShrink: 0, cursor: 'pointer',
                  display: 'inline-flex', alignItems: 'center', gap: 6, padding: '9px 15px', borderRadius: 999,
                  fontSize: 13.5, fontWeight: 600, border: 'none',
                  background: on ? 'var(--primary)' : 'var(--surface)', color: on ? '#fff' : 'var(--ink-soft)',
                  boxShadow: on ? '0 6px 14px -8px var(--primary)' : 'inset 0 0 0 1px var(--line)' }}>
                  <Icon name={s.icon} size={16} color={on ? '#fff' : 'var(--primary)'} fill={on ? 1 : 0} />{s.label}
                </button>
              );
            })}
          </div>
        </div>

        {/* transcript */}
        <Card pad={18}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', paddingBottom: 12,
            borderBottom: '1px solid var(--line)', marginBottom: 14 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 7 }}>
              <Icon name="notes" size={18} color="var(--primary)" />
              <span style={{ fontSize: 12, fontWeight: 800, letterSpacing: '.06em', color: 'var(--primary)' }}>LIVE TRANSCRIPT</span>
            </div>
            <button onClick={() => speak(seg.transcript)} style={iconBtnStyle}><Icon name="campaign" size={20} color="var(--primary)" /></button>
          </div>
          <p style={{ fontSize: 16, lineHeight: 1.65, color: 'var(--ink)', margin: 0 }}>
            {seg.highlight ? <Transcript text={seg.transcript} hl={seg.highlight} /> : seg.transcript}
          </p>
          {nativeLang === 'fa' && seg.fa && (
            <div style={{ marginTop: 14 }}>
              <button onClick={() => setShowFa(v => !v)} dir="rtl" style={{ display: 'inline-flex', alignItems: 'center', gap: 6,
                background: 'var(--surface-2)', border: 'none', cursor: 'pointer', padding: '8px 13px', borderRadius: 999,
                color: 'var(--primary)', fontWeight: 700, fontSize: 13.5, fontFamily: 'var(--fa-font)' }}>
                <Icon name="translate" size={17} color="var(--primary)" />
                {showFa ? '\u067e\u0646\u0647\u0627\u0646 \u06a9\u0631\u062f\u0646 \u062a\u0631\u062c\u0645\u0647' : '\u0646\u0645\u0627\u06cc\u0634 \u062a\u0631\u062c\u0645\u0647'}
                <Icon name={showFa ? 'expand_less' : 'expand_more'} size={18} color="var(--primary)" />
              </button>
              {showFa && (
                <div dir="rtl" style={{ marginTop: 10, background: 'color-mix(in srgb, var(--accent) 8%, white)',
                  border: '1px solid var(--line)', borderRadius: 'var(--r-panel)', padding: '13px 15px' }}>
                  <p style={{ fontSize: 15.5, lineHeight: 1.8, color: 'var(--ink)', margin: 0, fontFamily: 'var(--fa-font)', fontWeight: 500 }}>{seg.fa}</p>
                </div>
              )}
            </div>
          )}
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: 16 }}>
            <button onClick={() => toggleSave(phraseId)} style={{ display: 'inline-flex', alignItems: 'center', gap: 7,
              background: 'var(--surface-2)', border: 'none', cursor: 'pointer', padding: '9px 15px', borderRadius: 'var(--r-sm)',
              color: 'var(--primary)', fontWeight: 700, fontSize: 13.5 }}>
              <Icon name="bookmark" size={18} fill={saved.has(phraseId) ? 1 : 0} color="var(--primary)" />
              {saved.has(phraseId) ? 'Saved' : 'Save phrase'}
            </button>
            <div style={{ display: 'flex', gap: 5 }}>
              {segs.map((_, i) => <span key={i} style={{ width: 6, height: 6, borderRadius: 999,
                background: i === audio.seg ? 'var(--primary)' : 'var(--surface-3)' }} />)}
            </div>
          </div>
        </Card>
      </div>
    </div>
  );
}
const transBtn = { background: 'none', border: 'none', cursor: 'pointer', opacity: 0.85, padding: 4, display: 'flex' };

function Transcript({ text, hl }) {
  const parts = text.split(hl);
  return <>{parts[0]}<span style={{ background: 'color-mix(in srgb, var(--accent) 16%, transparent)', color: 'var(--primary)',
    fontWeight: 700, padding: '1px 7px', borderRadius: 6, whiteSpace: 'nowrap' }}>{hl}</span>{parts[1]}</>;
}

// ── Around you ───────────────────────────────────────────────────────
function AroundYou() {
  const { nav, back } = useApp();
  const here = DATA.here;
  return (
    <div style={{ minHeight: '100%', position: 'relative' }}>
      <TopBar title="Around you" onBack={back} accent
        action={<button onClick={() => nav('profile')} style={iconBtnStyle}><Icon name="account_circle" size={24} color="var(--primary)" /></button>} />
      <div style={{ padding: '4px 20px 110px' }}>
        <h2 style={{ fontSize: 24, fontWeight: 800, color: 'var(--ink)', margin: '6px 0 4px', letterSpacing: '-.02em' }}>Around you</h2>
        <p style={{ fontSize: 14.5, color: 'var(--ink-soft)', margin: 0 }}>Conversation tips for where you are.</p>

        <Card pad={0} style={{ overflow: 'hidden', marginTop: 18 }}>
          <div style={{ height: 150, backgroundImage: 'url(dorna/assets/map-thumb.png)', backgroundSize: 'cover', backgroundPosition: 'center' }} />
          <div style={{ padding: 16 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 7 }}>
              <Icon name="location_on" size={20} color="var(--primary)" fill={1} />
              <span style={{ fontSize: 16, fontWeight: 700, color: 'var(--ink)' }}>{here.name}</span>
              <span style={{ fontSize: 13, color: 'var(--ink-mute)' }}>· {here.dist}</span>
            </div>
            <div style={{ marginTop: 12, background: 'var(--surface-2)', borderRadius: 'var(--r-sm)',
              padding: '12px 14px', borderLeft: '3px solid var(--accent)' }}>
              <div style={{ display: 'flex', gap: 10 }}>
                <Icon name="lightbulb" size={20} color="var(--accent)" fill={1} />
                <span style={{ fontSize: 14, color: 'var(--ink)', lineHeight: 1.45, fontStyle: 'italic' }}>{here.tip}</span>
              </div>
              <Gloss fa={here.tip_fa} size={13.5} style={{ marginTop: 8 }} />
            </div>
          </div>
        </Card>

        <Eyebrow color="var(--ink-soft)" style={{ margin: '24px 0 12px' }}>Nearby venues</Eyebrow>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 11 }}>
          {DATA.venues.map(v => (
            <Card key={v.id} onClick={() => nav(v.id === 'coffee' ? 'coffee' : 'phrase', { id: v.id === 'coffee' ? 'p3' : null, text: v.phrase })}
              pad={14} soft style={{ display: 'flex', alignItems: 'center', gap: 13 }}>
              <div style={{ width: 46, height: 46, borderRadius: 999, background: 'var(--surface-3)', flexShrink: 0,
                display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Icon name={v.icon} size={24} color="var(--primary)" />
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 15, fontWeight: 700, color: 'var(--ink)' }}>{v.title}</div>
                <div style={{ fontSize: 13, color: 'var(--ink-soft)', fontStyle: 'italic', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>"{v.phrase}"</div>
                <Gloss fa={v.phrase_fa} size={12.5} style={{ marginTop: 4 }} />
              </div>
              <HearBtn text={v.phrase} variant="icon" />
              <Icon name="chevron_right" size={20} color="var(--ink-mute)" />
            </Card>
          ))}
        </div>
      </div>
      <button onClick={() => nav('talklive')} style={{ position: 'absolute', right: 18, bottom: 20, zIndex: 25,
        width: 58, height: 58, borderRadius: 999, border: 'none', cursor: 'pointer',
        background: 'linear-gradient(135deg, var(--hero-from), var(--hero-to))',
        boxShadow: '0 12px 28px -8px color-mix(in srgb, var(--primary) 65%, transparent)',
        display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <Icon name="mic" size={28} fill={1} color="#fff" />
      </button>
    </div>
  );
}

Object.assign(window, { Home, BriefPlayer, AroundYou, MiniPlayer, fmt });
