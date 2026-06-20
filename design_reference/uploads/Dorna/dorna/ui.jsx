// ui.jsx — shared UI primitives for Dorna screens
// Exports: Screen, TopBar, Eyebrow, Waveform, HearBtn, PrimaryBtn, GhostBtn, heroBg, Card

function heroBg(t) {
  return t && t.heroStyle === 'Solid'
    ? 'var(--primary)'
    : 'linear-gradient(140deg, var(--hero-from) 0%, var(--hero-to) 100%)';
}

// full screen content wrapper — clears the status bar / dynamic island
function Screen({ children, style = {}, pad = true, top = 54 }) {
  return (
    <div style={{
      minHeight: '100%', paddingTop: top,
      paddingLeft: pad ? 20 : 0, paddingRight: pad ? 20 : 0,
      boxSizing: 'border-box', ...style,
    }}>{children}</div>
  );
}

// top bar with optional back + centered title + right action
function TopBar({ title, sub, onBack, action, accent = false }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      padding: '54px 14px 8px', minHeight: 44, gap: 8,
    }}>
      <div style={{ width: 40, display: 'flex', justifyContent: 'flex-start' }}>
        {onBack && (
          <button onClick={onBack} style={iconBtnStyle}>
            <Icon name="arrow_back" size={24} color="var(--primary)" weight={400} />
          </button>
        )}
      </div>
      <div style={{ flex: 1, textAlign: 'center', display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
        {sub && <span style={{ fontSize: 11, fontWeight: 700, letterSpacing: '.06em',
          textTransform: 'uppercase', color: 'var(--primary)' }}>{sub}</span>}
        <span style={{ fontSize: 19, fontWeight: 700, color: accent ? 'var(--primary)' : 'var(--ink)',
          letterSpacing: '-.01em' }}>{title}</span>
      </div>
      <div style={{ width: 40, display: 'flex', justifyContent: 'flex-end' }}>
        {action}
      </div>
    </div>
  );
}

const iconBtnStyle = {
  width: 40, height: 40, borderRadius: 999, border: 'none', background: 'transparent',
  display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer',
  WebkitTapHighlightColor: 'transparent',
};

function Eyebrow({ children, color = 'var(--primary)', style = {} }) {
  return (
    <div style={{
      fontSize: 11, fontWeight: 800, letterSpacing: '.12em', textTransform: 'uppercase',
      color, ...style,
    }}>{children}</div>
  );
}

// animated audio waveform
function Waveform({ playing = true, color = '#fff', count = 24, height = 56, animated = true, seed = 1 }) {
  const bars = React.useMemo(() => Array.from({ length: count }, (_, i) => {
    const base = 18 + ((Math.sin(i * 1.7 + seed) + 1) / 2) * 70;
    return { h: base, d: 0.7 + ((i * 7 + seed * 13) % 9) / 10, delay: ((i * 5) % 11) / 10 };
  }), [count, seed]);
  return (
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 3, height }}>
      {bars.map((b, i) => (
        <div key={i} style={{
          width: 3, borderRadius: 999, background: color,
          height: animated && playing ? '100%' : b.h * 0.5 + '%',
          maxHeight: '100%',
          opacity: 0.55 + (b.h / 200),
          animation: animated && playing ? `wv ${b.d}s ease-in-out ${b.delay}s infinite` : 'none',
          transition: 'height .3s',
        }} />
      ))}
    </div>
  );
}

// "Hear it" pill — speaks text via TTS
function HearBtn({ text, slow = false, label = 'Hear it', variant = 'outline', size = 'md' }) {
  const [on, setOn] = React.useState(false);
  const play = (e) => {
    e && e.stopPropagation();
    speak(text, { slow });
    setOn(true);
    setTimeout(() => setOn(false), Math.min(2600, 700 + text.length * 55));
  };
  if (variant === 'icon') {
    return (
      <button onClick={play} aria-label="Hear it" style={{
        width: 38, height: 38, borderRadius: 999, border: 'none', cursor: 'pointer',
        background: on ? 'var(--primary)' : 'var(--surface-3)',
        color: on ? '#fff' : 'var(--accent)',
        display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
        WebkitTapHighlightColor: 'transparent', transition: 'all .15s',
      }}>
        <Icon name="volume_up" size={20} fill={on ? 1 : 0} color={on ? '#fff' : 'var(--accent)'} />
      </button>
    );
  }
  return (
    <button onClick={play} style={{
      display: 'inline-flex', alignItems: 'center', gap: 6, cursor: 'pointer',
      padding: size === 'sm' ? '6px 12px' : '8px 16px', borderRadius: 999,
      border: '1.5px solid ' + (on ? 'var(--primary)' : 'var(--primary)'),
      background: on ? 'var(--primary)' : 'transparent',
      color: on ? '#fff' : 'var(--primary)', fontWeight: 600, fontSize: 13,
      WebkitTapHighlightColor: 'transparent', transition: 'all .15s', flexShrink: 0,
    }}>
      <Icon name={on ? 'graphic_eq' : 'play_circle'} size={18} fill={0} color={on ? '#fff' : 'var(--primary)'} />
      {label}
    </button>
  );
}

function PrimaryBtn({ children, onClick, icon, full = true, disabled = false, style = {} }) {
  return (
    <button onClick={onClick} disabled={disabled} style={{
      width: full ? '100%' : 'auto', border: 'none', cursor: disabled ? 'default' : 'pointer',
      padding: '16px 24px', borderRadius: 'var(--r-btn)',
      background: disabled ? 'var(--surface-3)' : heroBg(),
      backgroundImage: disabled ? 'none' : 'linear-gradient(135deg, var(--hero-from), var(--hero-to))',
      color: disabled ? 'var(--ink-mute)' : '#fff', fontWeight: 700, fontSize: 16,
      display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
      boxShadow: disabled ? 'none' : '0 10px 26px -8px color-mix(in srgb, var(--primary) 55%, transparent)',
      WebkitTapHighlightColor: 'transparent',
      transition: 'transform .12s', ...style,
    }}
      onMouseDown={e => !disabled && (e.currentTarget.style.transform = 'scale(.98)')}
      onMouseUp={e => (e.currentTarget.style.transform = 'scale(1)')}
      onMouseLeave={e => (e.currentTarget.style.transform = 'scale(1)')}>
      {icon && <Icon name={icon} size={20} fill={1} color="#fff" />}
      {children}
    </button>
  );
}

function GhostBtn({ children, onClick, icon, style = {} }) {
  return (
    <button onClick={onClick} style={{
      border: '1.5px solid var(--primary)', background: 'transparent', cursor: 'pointer',
      padding: '13px 22px', borderRadius: 'var(--r-btn)', color: 'var(--primary)',
      fontWeight: 600, fontSize: 15, display: 'inline-flex', alignItems: 'center',
      justifyContent: 'center', gap: 8, WebkitTapHighlightColor: 'transparent', ...style,
    }}>
      {icon && <Icon name={icon} size={19} color="var(--primary)" />}
      {children}
    </button>
  );
}

// Bilingual gloss — Persian (RTL) line shown only when the user's language is Persian.
// Honors the Settings "Your language" toggle: hides entirely when nativeLang !== 'fa'.
function Gloss({ fa, align = 'start', size = 14, color = 'var(--ink-soft)', icon = true, style = {} }) {
  const app = useApp();
  if (!fa || (app && app.nativeLang !== 'fa')) return null;
  return (
    <div dir="rtl" style={{
      display: 'flex', alignItems: 'flex-start', gap: 6,
      justifyContent: align === 'end' ? 'flex-end' : 'flex-start',
      marginTop: 6, ...style,
    }}>
      {icon && <Icon name="translate" size={Math.round(size * 0.95)} color="var(--ink-mute)" style={{ marginTop: 2, flexShrink: 0 }} />}
      <span style={{ fontSize: size, lineHeight: 1.6, color, fontFamily: 'var(--fa-font)', fontWeight: 500 }}>{fa}</span>
    </div>
  );
}

function Card({ children, onClick, style = {}, pad = 18, soft = false }) {
  return (
    <div onClick={onClick} style={{
      background: 'var(--surface)', borderRadius: 'var(--r-card)',
      border: '1px solid var(--line)', padding: pad,
      boxShadow: soft ? 'none' : '0 4px 22px -16px rgba(16,40,64,0.4)',
      cursor: onClick ? 'pointer' : 'default', ...style,
    }}>{children}</div>
  );
}

Object.assign(window, { heroBg, Screen, TopBar, Eyebrow, Waveform, HearBtn, PrimaryBtn, GhostBtn, Card, Gloss, iconBtnStyle });
