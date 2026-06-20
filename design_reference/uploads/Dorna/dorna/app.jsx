// app.jsx — App shell: context provider, router, bottom nav, audio engine, tweaks

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "theme": "Deep Blue",
  "radius": "Soft",
  "font": "Inter",
  "heroStyle": "Gradient",
  "homeLayout": "Hero",
  "bigWaveform": true
}/*EDITMODE-END*/;

// which screens show the bottom tab bar, and which tab is active
const SCREEN_META = {
  home:        { nav: 'today' },
  brief:       { nav: null },
  aroundyou:   { nav: 'today' },
  calendar:    { nav: null },
  location:    { nav: null },
  eventprep:   { nav: null },
  coffee:      { nav: null },
  practice:    { nav: 'practice' },
  talklive:    { nav: null },
  feedback:    { nav: null },
  deck:        { nav: 'practice' },
  phrase:      { nav: null },
  profile:     { nav: 'profile' },
  saved:       { nav: null },
  keyboardintro:{ nav: null },
  keyboarddemo:{ nav: null },
  settings:    { nav: null },
  notification:{ nav: null },
};

const ONBOARDING = ['welcome', 'language', 'interests', 'situations', 'calendar', 'location', 'building'];

function App() {
  const [t, setTweak] = useTweaks(TWEAK_DEFAULTS);

  // tokens derived from tweaks
  const theme = THEME_PRESETS[t.theme] || THEME_PRESETS['Deep Blue'];
  const rad = RADIUS_PRESETS[t.radius] || RADIUS_PRESETS['Soft'];
  const fontFamily = FONTS[t.font] || FONTS.Inter;
  const tokens = { ...theme, ...rad, fontFamily };

  // ── navigation ──
  const [stack, setStack] = React.useState([{ screen: 'welcome', params: {} }]);
  const cur = stack[stack.length - 1];
  const [dir, setDir] = React.useState('fwd');

  const nav = React.useCallback((screen, params = {}) => {
    setDir('fwd');
    setStack(s => [...s, { screen, params }]);
  }, []);
  const replace = React.useCallback((screen, params = {}) => {
    setDir('fwd');
    setStack(s => [...s.slice(0, -1), { screen, params }]);
  }, []);
  const back = React.useCallback(() => {
    setDir('back');
    setStack(s => (s.length > 1 ? s.slice(0, -1) : s));
  }, []);
  const resetTo = React.useCallback((screen, params = {}) => {
    setDir('fwd');
    setStack([{ screen, params }]);
  }, []);
  const goTab = React.useCallback((screen) => {
    setDir('fwd');
    setStack([{ screen, params: {} }]);
    window.speechSynthesis && window.speechSynthesis.cancel();
  }, []);

  // ── shared user state ──
  const [nativeLang, setNativeLang] = React.useState('fa');
  const [challengeDone, setChallengeDone] = React.useState(false);
  const [reminderSeen, setReminderSeen] = React.useState(false);
  const [interests, setInterests] = React.useState(new Set(['soccer', 'tech', 'travel']));
  const [situations, setSituations] = React.useState(new Set(['smalltalk', 'networking']));
  const [calendar, setCalendar] = React.useState(true);
  const [location, setLocation] = React.useState(true);
  const [saved, setSaved] = React.useState(new Set(DATA.phrases.filter(p => p.save).map(p => p.id)));
  const toggleSave = React.useCallback((id) => {
    setSaved(s => { const n = new Set(s); n.has(id) ? n.delete(id) : n.add(id); return n; });
  }, []);

  // ── audio engine ──
  const [audio, setAudio] = React.useState({ playing: false, time: 0, seg: 2, started: false });
  const tick = React.useRef(null);
  React.useEffect(() => {
    if (audio.playing) {
      tick.current = setInterval(() => {
        setAudio(a => {
          const nt = a.time + 1;
          if (nt >= DATA.brief.duration) { return { ...a, playing: false, time: DATA.brief.duration }; }
          return { ...a, time: nt };
        });
      }, 1000);
    }
    return () => clearInterval(tick.current);
  }, [audio.playing]);
  const audioCtl = {
    toggle: () => setAudio(a => ({ ...a, playing: !a.playing, started: true })),
    play:   () => setAudio(a => ({ ...a, playing: true, started: true })),
    pause:  () => setAudio(a => ({ ...a, playing: false })),
    seek:   (s) => setAudio(a => ({ ...a, time: Math.max(0, Math.min(DATA.brief.duration, s)) })),
    nudge:  (d) => setAudio(a => ({ ...a, time: Math.max(0, Math.min(DATA.brief.duration, a.time + d)) })),
    setSeg: (i) => setAudio(a => ({ ...a, seg: i })),
  };

  const ctx = {
    nav, back, replace, resetTo, goTab, screen: cur.screen, params: cur.params,
    t, setTweak, tokens,
    interests, setInterests, situations, setSituations,
    nativeLang, setNativeLang,
    challengeDone, setChallengeDone, reminderSeen, setReminderSeen,
    calendar, setCalendar, location, setLocation,
    saved, toggleSave, audio, audioCtl,
  };

  // root css vars
  const rootStyle = {
    '--primary': theme.primary, '--primary-deep': theme.primaryDeep, '--accent': theme.accent,
    '--hero-from': theme.heroFrom, '--hero-to': theme.heroTo,
    '--bg': '#F1F6FB', '--surface': '#FFFFFF', '--surface-2': '#E8F1F9', '--surface-3': '#DCEAF6',
    '--ink': '#16283A', '--ink-soft': '#56697B', '--ink-mute': '#8499A8', '--line': '#DEE8F1',
    '--fa-font': "'Vazirmatn', 'Inter', system-ui, sans-serif",
    '--r-card': rad.card, '--r-panel': rad.panel, '--r-btn': rad.btn, '--r-chip': rad.chip, '--r-sm': rad.sm,
    fontFamily, color: 'var(--ink)', background: 'var(--bg)',
    height: '100%', display: 'flex', flexDirection: 'column', position: 'relative',
    overflow: 'hidden',
  };

  const SCREENS = {
    welcome: window.Welcome, language: window.Language, interests: window.Interests, situations: window.Situations,
    calendar: window.CalendarConnect, location: window.LocationConnect, building: window.BuildingBrief,
    home: window.Home, brief: window.BriefPlayer, aroundyou: window.AroundYou,
    eventprep: window.EventPrep, coffee: window.CoffeeScene,
    practice: window.PracticeHub, talklive: window.TalkLive, feedback: window.Feedback,
    deck: window.PracticeDeck, phrase: window.PhraseDetail,
    profile: window.Profile, saved: window.SavedPhrases,
    keyboardintro: window.KeyboardIntro, keyboarddemo: window.KeyboardDemo, settings: window.Settings,
    notification: window.NotificationPreview,
  };
  const ScreenComp = SCREENS[cur.screen] || (() => <div style={{ padding: 40 }}>Missing: {cur.screen}</div>);
  const meta = SCREEN_META[cur.screen] || {};
  const showNav = !!meta.nav;
  const isOnb = ONBOARDING.includes(cur.screen);

  return (
    <DornaCtx.Provider value={ctx}>
      <IOSDevice dark={false}>
        <div style={rootStyle} className="dorna-root">
          {/* scrollable screen area */}
          <div style={{ flex: 1, position: 'relative', overflow: 'hidden' }}>
            <div
              key={cur.screen + stack.length}
              className={dir === 'fwd' ? 'screen-enter' : 'screen-enter-back'}
              style={{ position: 'absolute', inset: 0, overflowY: 'auto', overflowX: 'hidden',
                       WebkitOverflowScrolling: 'touch' }}
            >
              <ScreenComp />
            </div>
          </div>
          {showNav && <BottomNav active={meta.nav} goTab={goTab} tokens={tokens} />}
        </div>
      </IOSDevice>

      <TweaksPanel>
        <TweakSection label="Look & feel" />
        <TweakSelect label="Theme" value={t.theme}
          options={Object.keys(THEME_PRESETS)} onChange={v => setTweak('theme', v)} />
        <TweakRadio label="Corners" value={t.radius}
          options={['Soft', 'Rounded', 'Sharp']} onChange={v => setTweak('radius', v)} />
        <TweakSelect label="Font" value={t.font}
          options={['Inter', 'Jakarta', 'System']} onChange={v => setTweak('font', v)} />
        <TweakSection label="Brand" />
        <TweakRadio label="Hero fill" value={t.heroStyle}
          options={['Gradient', 'Solid']} onChange={v => setTweak('heroStyle', v)} />
        <TweakToggle label="Animated waveform" value={t.bigWaveform}
          onChange={v => setTweak('bigWaveform', v)} />
        <TweakSection label="Home layout" />
        <TweakRadio label="Today screen" value={t.homeLayout}
          options={['Hero', 'Compact', 'Cards']} onChange={v => setTweak('homeLayout', v)} />
      </TweaksPanel>
    </DornaCtx.Provider>
  );
}

function BottomNav({ active, goTab }) {
  const tabs = [
    { id: 'today', screen: 'home', icon: 'graphic_eq', label: 'Today' },
    { id: 'practice', screen: 'practice', icon: 'forum', label: 'Practice' },
    { id: 'profile', screen: 'profile', icon: 'person', label: 'Profile' },
  ];
  return (
    <nav style={{
      display: 'flex', justifyContent: 'space-around', alignItems: 'center',
      background: 'rgba(255,255,255,0.86)', backdropFilter: 'blur(16px)',
      WebkitBackdropFilter: 'blur(16px)', borderTop: '1px solid var(--line)',
      paddingTop: 8, paddingBottom: 26, flexShrink: 0, zIndex: 30,
    }}>
      {tabs.map(tab => {
        const on = active === tab.id;
        return (
          <button key={tab.id} onClick={() => goTab(tab.screen)}
            style={{
              background: 'none', border: 'none', cursor: 'pointer',
              display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3,
              padding: '4px 18px', borderRadius: 16,
            }}>
            <div style={{
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              width: 52, height: 30, borderRadius: 999,
              background: on ? 'var(--surface-3)' : 'transparent',
              transition: 'background .2s',
            }}>
              <Icon name={tab.icon} size={23} fill={on ? 1 : 0} weight={on ? 500 : 300}
                color={on ? 'var(--primary)' : 'var(--ink-mute)'} />
            </div>
            <span style={{ fontSize: 11, fontWeight: on ? 700 : 500,
              color: on ? 'var(--primary)' : 'var(--ink-mute)' }}>{tab.label}</span>
          </button>
        );
      })}
    </nav>
  );
}

window.App = App;
