// screens-connect.jsx — CalendarConnect & LocationConnect (two persuasive onboarding screens w/ JS-driven animation)

// JS cycle hook (preview-safe — CSS animations can freeze in iframe, state ticks don't)
function useCycle(count, ms) {
  const [i, setI] = React.useState(0);
  React.useEffect(() => { const id = setInterval(() => setI(v => (v + 1) % count), ms); return () => clearInterval(id); }, [count, ms]);
  return i;
}
function useTick(ms = 45, step = 0.018) {
  const [p, setP] = React.useState(0);
  React.useEffect(() => { const id = setInterval(() => setP(v => (v + step) % 1), ms); return () => clearInterval(id); }, [ms, step]);
  return p;
}

const CAL_EVENTS = [
  { t: '9:00', title: 'Team standup', icon: 'groups', phrase: "Morning! How was everyone's weekend?" },
  { t: '1:00', title: 'Client call', icon: 'call', phrase: 'Thanks for taking the time today.' },
  { t: '5:00', title: 'Networking event', icon: 'local_bar', phrase: 'Hi — what brings you here tonight?' },
];

function CalendarConnect() {
  const { nav, back, calendar, setCalendar } = useApp();
  const active = useCycle(CAL_EVENTS.length, 2100);
  const ev = CAL_EVENTS[active];
  return (
    <div style={{ minHeight: '100%', display: 'flex', flexDirection: 'column' }}>
      <div style={{ paddingTop: 54, paddingInline: 18, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <button onClick={back} style={iconBtnStyle}><Icon name="close" size={24} color="var(--ink-soft)" /></button>
        <ProgressDots n={5} i={3} />
        <div style={{ width: 40 }} />
      </div>

      <div style={{ padding: '14px 24px 0' }}>
        <div style={{ display: 'inline-flex', alignItems: 'center', gap: 7, background: 'var(--surface-3)',
          padding: '6px 13px', borderRadius: 999, marginBottom: 14 }}>
          <Icon name="calendar_today" size={16} color="var(--primary)" />
          <span style={{ fontSize: 12, fontWeight: 800, letterSpacing: '.04em', color: 'var(--primary)' }}>YOUR CALENDAR</span>
        </div>
        <h1 style={{ fontSize: 29, fontWeight: 800, color: 'var(--ink)', margin: 0, letterSpacing: '-.02em', lineHeight: 1.12 }}>
          Your calendar becomes your script</h1>
        <p style={{ fontSize: 15, color: 'var(--ink-soft)', marginTop: 12, lineHeight: 1.5 }}>
          Before every meeting and event, Dorna gives you the exact words to open with — pulled from what's actually on your day.</p>
      </div>

      {/* animated agenda */}
      <div style={{ padding: '20px 20px 0', flex: 1 }}>
        <Card pad={16} style={{ position: 'relative', overflow: 'hidden' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
            <span style={{ fontSize: 13, fontWeight: 800, color: 'var(--ink)' }}>Today</span>
            <span style={{ fontSize: 11.5, color: 'var(--ink-mute)', fontWeight: 600 }}>Mon, Jun 1</span>
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            {CAL_EVENTS.map((e, k) => {
              const on = k === active;
              return (
                <div key={e.t} style={{ display: 'flex', alignItems: 'center', gap: 11, padding: '11px 12px',
                  borderRadius: 'var(--r-panel)', transition: 'all .35s',
                  background: on ? 'color-mix(in srgb, var(--primary) 9%, white)' : 'var(--surface-2)',
                  outline: on ? '1.5px solid var(--primary)' : '1.5px solid transparent' }}>
                  <span style={{ fontSize: 12.5, fontWeight: 800, color: on ? 'var(--primary)' : 'var(--ink-mute)',
                    width: 34, fontVariantNumeric: 'tabular-nums' }}>{e.t}</span>
                  <div style={{ width: 30, height: 30, borderRadius: 9, flexShrink: 0, display: 'flex', alignItems: 'center', justifyContent: 'center',
                    background: on ? 'var(--primary)' : 'var(--surface-3)', transition: 'all .35s' }}>
                    <Icon name={e.icon} size={17} color={on ? '#fff' : 'var(--primary)'} fill={on ? 1 : 0} /></div>
                  <span style={{ flex: 1, fontSize: 14, fontWeight: on ? 700 : 600, color: 'var(--ink)' }}>{e.title}</span>
                  {on && <span style={{ width: 8, height: 8, borderRadius: 999, background: 'var(--accent)' }} className="dot-pulse" />}
                </div>
              );
            })}
          </div>

          {/* phrase bubble for active event */}
          <div style={{ marginTop: 14, display: 'flex', gap: 10, alignItems: 'flex-start' }}>
            <div style={{ width: 30, height: 30, borderRadius: 999, flexShrink: 0, marginTop: 2,
              background: 'linear-gradient(135deg, var(--hero-from), var(--hero-to))',
              display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Icon name="auto_awesome" size={16} color="#fff" fill={1} /></div>
            <div key={active} className="bubble-rise" style={{ flex: 1, background: 'var(--surface-2)',
              borderRadius: '5px 14px 14px 14px', padding: '12px 14px', border: '1px solid var(--line)' }}>
              <div style={{ fontSize: 10.5, fontWeight: 800, letterSpacing: '.06em', color: 'var(--primary)', marginBottom: 4 }}>
                DORNA SUGGESTS · {ev.t}</div>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 8 }}>
                <span style={{ fontSize: 15, fontWeight: 600, color: 'var(--ink)' }}>{ev.phrase}</span>
                <button onClick={() => speak(ev.phrase)} style={{ width: 32, height: 32, borderRadius: 999, border: 'none', cursor: 'pointer',
                  background: 'var(--surface-3)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                  <Icon name="volume_up" size={18} color="var(--accent)" /></button>
              </div>
            </div>
          </div>
        </Card>
      </div>

      <div style={{ padding: '16px 24px 30px' }}>
        <PrimaryBtn icon={calendar ? 'check_circle' : 'calendar_today'} onClick={() => { setCalendar(true); nav('location'); }}>
          {calendar ? 'Calendar connected — continue' : 'Connect calendar'}</PrimaryBtn>
        <div style={{ textAlign: 'center', marginTop: 14 }}>
          <button onClick={() => nav('location')} style={{ background: 'none', border: 'none', cursor: 'pointer',
            color: 'var(--ink-soft)', fontWeight: 600, fontSize: 15 }}>Maybe later</button>
        </div>
      </div>
    </div>
  );
}

const LOC_VENUES = [
  { icon: 'local_cafe', label: 'Coffee shop', tag: 'You like: Coffee', phrase: 'Is this seat taken?', x: 24, y: 30 },
  { icon: 'fitness_center', label: 'Gym', tag: 'You like: Fitness', phrase: 'How many sets you got left?', x: 71, y: 36 },
  { icon: 'palette', label: 'Art gallery', tag: 'You like: Art', phrase: 'What do you make of this one?', x: 58, y: 70 },
];

function LocationConnect() {
  const { nav, back, location, setLocation } = useApp();
  const active = useCycle(LOC_VENUES.length, 2100);
  const p = useTick(45, 0.02);
  const v = LOC_VENUES[active];
  return (
    <div style={{ minHeight: '100%', display: 'flex', flexDirection: 'column' }}>
      <div style={{ paddingTop: 54, paddingInline: 18, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <button onClick={back} style={iconBtnStyle}><Icon name="arrow_back" size={24} color="var(--primary)" /></button>
        <ProgressDots n={5} i={4} />
        <div style={{ width: 40 }} />
      </div>

      <div style={{ padding: '14px 24px 0' }}>
        <div style={{ display: 'inline-flex', alignItems: 'center', gap: 7, background: 'var(--surface-3)',
          padding: '6px 13px', borderRadius: 999, marginBottom: 14 }}>
          <Icon name="location_on" size={16} color="var(--primary)" />
          <span style={{ fontSize: 12, fontWeight: 800, letterSpacing: '.04em', color: 'var(--primary)' }}>YOUR PLACES</span>
        </div>
        <h1 style={{ fontSize: 29, fontWeight: 800, color: 'var(--ink)', margin: 0, letterSpacing: '-.02em', lineHeight: 1.12 }}>
          Turn places into openings</h1>
        <p style={{ fontSize: 15, color: 'var(--ink-soft)', marginTop: 12, lineHeight: 1.5 }}>
          When you're near somewhere that fits your interests, Dorna turns it into a chance to talk — with openers made for that spot.</p>
      </div>

      {/* animated map */}
      <div style={{ padding: '20px 20px 0', flex: 1 }}>
        <Card pad={0} style={{ overflow: 'hidden' }}>
          <div style={{ position: 'relative', height: 230, backgroundImage: 'url(dorna/assets/map-thumb.png)',
            backgroundSize: 'cover', backgroundPosition: 'center' }}>
            <div style={{ position: 'absolute', inset: 0, background: 'color-mix(in srgb, var(--bg) 18%, transparent)' }} />
            {/* you pin + radar */}
            <div style={{ position: 'absolute', left: '45%', top: '50%', transform: 'translate(-50%,-50%)' }}>
              {[0, 0.5].map((off, idx) => {
                const ph = (p + off) % 1;
                return <span key={idx} style={{ position: 'absolute', left: '50%', top: '50%',
                  width: 30, height: 30, marginLeft: -15, marginTop: -15, borderRadius: 999,
                  border: '2px solid var(--primary)', transform: `scale(${1 + ph * 2.6})`, opacity: 0.5 * (1 - ph) }} />;
              })}
              <div style={{ position: 'relative', width: 18, height: 18, borderRadius: 999, background: 'var(--primary)',
                border: '3px solid #fff', boxShadow: '0 2px 8px rgba(0,0,0,0.3)' }} />
            </div>
            {/* venue pins */}
            {LOC_VENUES.map((venue, k) => {
              const on = k === active;
              return (
                <div key={venue.label} style={{ position: 'absolute', left: venue.x + '%', top: venue.y + '%',
                  transform: `translate(-50%,-50%) scale(${on ? 1.12 : 0.92})`, transition: 'transform .35s', zIndex: on ? 5 : 2 }}>
                  <div style={{ width: 40, height: 40, borderRadius: 999, display: 'flex', alignItems: 'center', justifyContent: 'center',
                    background: on ? 'linear-gradient(135deg, var(--hero-from), var(--hero-to))' : '#fff',
                    border: on ? 'none' : '1px solid var(--line)',
                    boxShadow: on ? '0 8px 18px -6px color-mix(in srgb, var(--primary) 60%, transparent)' : '0 2px 8px rgba(16,40,64,0.18)',
                    transition: 'all .35s' }}>
                    <Icon name={venue.icon} size={21} color={on ? '#fff' : 'var(--primary)'} fill={on ? 1 : 0} /></div>
                </div>
              );
            })}
          </div>
          {/* opportunity bubble */}
          <div key={active} className="bubble-rise" style={{ padding: '14px 16px', display: 'flex', alignItems: 'center', gap: 12 }}>
            <div style={{ width: 40, height: 40, borderRadius: 12, flexShrink: 0, background: 'var(--surface-2)',
              display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Icon name={v.icon} size={22} color="var(--primary)" /></div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 7 }}>
                <span style={{ fontSize: 14.5, fontWeight: 700, color: 'var(--ink)' }}>{v.label}</span>
                <span style={{ fontSize: 10, fontWeight: 800, color: 'var(--accent)', background: 'color-mix(in srgb, var(--accent) 12%, white)',
                  padding: '2px 7px', borderRadius: 999 }}>{v.tag}</span>
              </div>
              <div style={{ fontSize: 13, color: 'var(--ink-soft)', fontStyle: 'italic', marginTop: 1 }}>"{v.phrase}"</div>
            </div>
            <button onClick={() => speak(v.phrase)} style={{ width: 34, height: 34, borderRadius: 999, border: 'none', cursor: 'pointer',
              background: 'var(--surface-3)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
              <Icon name="volume_up" size={19} color="var(--accent)" /></button>
          </div>
        </Card>
        <div style={{ display: 'flex', alignItems: 'center', gap: 7, justifyContent: 'center', marginTop: 16 }}>
          <Icon name="lock" size={15} color="var(--ink-mute)" />
          <span style={{ fontSize: 13, color: 'var(--ink-mute)' }}>Private to you. Change anytime.</span>
        </div>
      </div>

      <div style={{ padding: '16px 24px 30px' }}>
        <PrimaryBtn icon={location ? 'check_circle' : 'location_on'} onClick={() => { setLocation(true); nav('building'); }}>
          {location ? 'Location on — finish setup' : 'Enable location'}</PrimaryBtn>
        <div style={{ textAlign: 'center', marginTop: 14 }}>
          <button onClick={() => nav('building')} style={{ background: 'none', border: 'none', cursor: 'pointer',
            color: 'var(--ink-soft)', fontWeight: 600, fontSize: 15 }}>Maybe later</button>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { CalendarConnect, LocationConnect, useCycle, useTick });
