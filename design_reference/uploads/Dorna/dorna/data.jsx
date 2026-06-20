// data.jsx — shared context, design tokens, content data, helpers, icons
// Exported to window: DornaCtx, useApp, Icon, speak, THEME_PRESETS, RADIUS_PRESETS, FONTS, DATA

const DornaCtx = React.createContext(null);
const useApp = () => React.useContext(DornaCtx);

// ── Theme presets (darker, minimal blues) ───────────────────────────
const THEME_PRESETS = {
  'Deep Blue': { primary: '#0B5390', primaryDeep: '#073A66', accent: '#15A8CC', heroFrom: '#0C4C86', heroTo: '#1597C0' },
  'Ocean':     { primary: '#0A6FA8', primaryDeep: '#064E78', accent: '#19BBD8', heroFrom: '#0A6098', heroTo: '#16B6D6' },
  'Midnight':  { primary: '#143C68', primaryDeep: '#0A2342', accent: '#3F8FC0', heroFrom: '#10294A', heroTo: '#205F90' },
  'Slate':     { primary: '#335A7C', primaryDeep: '#223C54', accent: '#5E97B8', heroFrom: '#2C4D6B', heroTo: '#4E86AA' },
};

const RADIUS_PRESETS = {
  Soft:    { card: '26px', panel: '20px', btn: '16px', chip: '999px', sm: '12px' },
  Rounded: { card: '32px', panel: '26px', btn: '999px', chip: '999px', sm: '16px' },
  Sharp:   { card: '16px', panel: '12px', btn: '10px', chip: '8px', sm: '8px' },
};

const FONTS = {
  Inter:   "'Inter', system-ui, sans-serif",
  Jakarta: "'Plus Jakarta Sans', system-ui, sans-serif",
  System:  "-apple-system, system-ui, sans-serif",
};

// Persian / Farsi text stack (RTL glosses)
const FA_FONT = "'Vazirmatn', 'Inter', system-ui, sans-serif";

// ── Speech (browser TTS) ─────────────────────────────────────────────
function speak(text, { slow = false } = {}) {
  try {
    const synth = window.speechSynthesis;
    if (!synth) return;
    synth.cancel();
    const u = new SpeechSynthesisUtterance(String(text).replace(/[^\x00-\x7F]/g, ''));
    u.lang = 'en-US';
    u.rate = slow ? 0.62 : 0.95;
    u.pitch = 1.0;
    const voices = synth.getVoices();
    const pref = voices.find(v => /en-US/i.test(v.lang) && /(Samantha|Google US|Aaron|Ava|Female|Natural)/i.test(v.name))
      || voices.find(v => /en-US/i.test(v.lang)) || voices.find(v => /en/i.test(v.lang));
    if (pref) u.voice = pref;
    synth.speak(u);
  } catch (e) { /* no-op */ }
}
// warm voices list
if (typeof window !== 'undefined' && window.speechSynthesis) {
  window.speechSynthesis.onvoiceschanged = () => window.speechSynthesis.getVoices();
}

// ── Icon (Material Symbols) ──────────────────────────────────────────
function Icon({ name, size = 24, fill = 0, weight = 300, color, style = {}, className = '' }) {
  return (
    <span
      className={'material-symbols-outlined ' + className}
      style={{
        fontSize: size, color: color || 'inherit', lineHeight: 1,
        fontVariationSettings: `'FILL' ${fill}, 'wght' ${weight}, 'GRAD' 0, 'opsz' 24`,
        userSelect: 'none', ...style,
      }}
    >{name}</span>
  );
}

// ── Content data ─────────────────────────────────────────────────────
const DATA = {
  user: {
    name: 'Nima',
    city: 'Toronto, Canada',
    avatar: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBNleNS4dur5hPhH7a01_PZL4gbHT7fW58qqFFsc69E2S-fGXPOe-7jp0nGE1cPPEOomMYuUkFfvWSsW72lC3VIzH_7hGHjUOwMmqgkHB6vWyIlqzTe60Su2URPxrbQ0uDJB0W4fdNBX43FvJdmJItyRCIwtrvOuEPCoj5RtkBXQuKk2ULDXnvuXYZnRbGe65LZF0qHQsJ4lJCqIY0pGUuKbSUoXeKPyjTSB3ZR_PHDalb4zj2KQleVEuyeTVLEuJLsARn3R9ZC0sY',
  },
  interests: [
    { id: 'soccer', label: 'Soccer' }, { id: 'tech', label: 'Tech' }, { id: 'movies', label: 'Movies' },
    { id: 'music', label: 'Music' }, { id: 'food', label: 'Food & cooking' }, { id: 'travel', label: 'Travel' },
    { id: 'fitness', label: 'Fitness' }, { id: 'art', label: 'Art' }, { id: 'business', label: 'Business' },
    { id: 'cars', label: 'Cars' }, { id: 'gaming', label: 'Gaming' }, { id: 'books', label: 'Books' },
    { id: 'nature', label: 'Nature' }, { id: 'photo', label: 'Photography' }, { id: 'startups', label: 'Startups' },
    { id: 'newcomer', label: 'Newcomer life' },
  ],
  situations: [
    { id: 'smalltalk', icon: 'chat_bubble', title: 'Small talk & making friends', ex: '"Hi, how\u2019s your day going?"' },
    { id: 'networking', icon: 'groups', title: 'Networking events', ex: '"So, what brings you here tonight?"' },
    { id: 'work', icon: 'work', title: 'At work / with coworkers', ex: '"Do you have a moment to sync?"' },
    { id: 'cafe', icon: 'local_cafe', title: 'Coffee shops & cafes', ex: '"Can I get a medium latte, please?"' },
    { id: 'neighbours', icon: 'home', title: 'Neighbours & community', ex: '"Beautiful weather we\u2019re having!"' },
    { id: 'shopping', icon: 'shopping_bag', title: 'Shopping & services', ex: '"Do you have this in a smaller size?"' },
  ],
  // Daily brief segments + transcripts
  brief: {
    date: 'Monday, Jun 1',
    duration: 330,
    segments: [
      { id: 'weather', label: 'Weather', icon: 'wb_sunny', dur: 35,
        transcript: 'Good morning, Nima. It\u2019s a clear day in Toronto \u2014 around 12 degrees and sunny, warming up to 18 by the afternoon. A light jacket should be plenty.',
        fa: '\u0635\u0628\u062d \u0628\u062e\u06cc\u0631 \u0646\u06cc\u0645\u0627. \u0627\u0645\u0631\u0648\u0632 \u062f\u0631 \u062a\u0648\u0631\u0646\u062a\u0648 \u0647\u0648\u0627 \u0635\u0627\u0641 \u0627\u0633\u062a \u2014 \u062d\u062f\u0648\u062f \u06f1\u06f2 \u062f\u0631\u062c\u0647 \u0648 \u0622\u0641\u062a\u0627\u0628\u06cc\u060c \u0628\u0639\u062f\u0627\u0632\u0638\u0647\u0631 \u062a\u0627 \u06f1\u06f8 \u062f\u0631\u062c\u0647 \u06af\u0631\u0645 \u0645\u06cc\u200c\u0634\u0648\u062f. \u06cc\u06a9 \u06a9\u0627\u067e\u0634\u0646 \u0633\u0628\u06a9 \u06a9\u0627\u0641\u06cc \u0627\u0633\u062a.' },
      { id: 'happening', label: "What\u2019s happening", icon: 'public', dur: 55,
        transcript: 'The waterfront has a small food festival running all weekend, and transit on the 5 line is back to normal after yesterday\u2019s delays. Good day to be out and about.',
        fa: '\u0627\u06cc\u0646 \u0622\u062e\u0631 \u0647\u0641\u062a\u0647 \u06cc\u06a9 \u062c\u0634\u0646\u0648\u0627\u0631\u0647\u0654 \u06a9\u0648\u0686\u06a9 \u063a\u0630\u0627 \u062f\u0631 \u0633\u0627\u062d\u0644 \u0628\u0631\u067e\u0627\u0633\u062a\u060c \u0648 \u062e\u0637 \u06f5 \u0645\u062a\u0631\u0648 \u0628\u0639\u062f \u0627\u0632 \u062a\u0623\u062e\u06cc\u0631\u0647\u0627\u06cc \u062f\u06cc\u0631\u0648\u0632 \u0628\u0647 \u062d\u0627\u0644\u062a \u0639\u0627\u062f\u06cc \u0628\u0631\u06af\u0634\u062a\u0647. \u0631\u0648\u0632 \u062e\u0648\u0628\u06cc \u0628\u0631\u0627\u06cc \u0628\u06cc\u0631\u0648\u0646 \u0631\u0641\u062a\u0646 \u0627\u0633\u062a.' },
      { id: 'phrases', label: 'Useful phrases', icon: 'forum', dur: 95, highlight: '"How\u2019s it going?"',
        highlight_fa: '\u0627\u0648\u0636\u0627\u0639 \u0686\u0637\u0648\u0631\u0647\u061f',
        transcript: 'When you meet someone in the morning, a very common way to check in is by saying "How\u2019s it going?" It\u2019s casual and perfect for your new Canadian neighbours.',
        fa: '\u0648\u0642\u062a\u06cc \u0635\u0628\u062d \u06a9\u0633\u06cc \u0631\u0627 \u0645\u06cc\u200c\u0628\u06cc\u0646\u06cc\u062f\u060c \u06cc\u06a9 \u0631\u0627\u0647 \u0631\u0627\u06cc\u062c \u0628\u0631\u0627\u06cc \u0627\u062d\u0648\u0627\u0644\u200c\u067e\u0631\u0633\u06cc \u06af\u0641\u062a\u0646 «How\u2019s it going?» \u0627\u0633\u062a. \u062e\u0648\u062f\u0645\u0627\u0646\u06cc \u0627\u0633\u062a \u0648 \u0628\u0631\u0627\u06cc \u0647\u0645\u0633\u0627\u06cc\u0647\u200c\u0647\u0627\u06cc \u062c\u062f\u06cc\u062f \u06a9\u0627\u0646\u0627\u062f\u0627\u06cc\u06cc\u200c\u062a\u0627\u0646 \u0639\u0627\u0644\u06cc \u0627\u0633\u062a.' },
      { id: 'goodtoknow', label: 'Good to know', icon: 'tips_and_updates', dur: 40,
        transcript: 'Good to know: here, when a cashier asks "How\u2019s it going?", it isn\u2019t really a question \u2014 a simple "Good, you?" is all you need.',
        fa: '\u062e\u0648\u0628 \u0627\u0633\u062a \u0628\u062f\u0627\u0646\u06cc\u062f: \u0627\u06cc\u0646\u062c\u0627 \u0648\u0642\u062a\u06cc \u0635\u0646\u062f\u0648\u0642\u200c\u062f\u0627\u0631 \u0645\u06cc\u200c\u067e\u0631\u0633\u062f «How\u2019s it going?» \u0648\u0627\u0642\u0639\u0627\u064b \u0633\u0624\u0627\u0644 \u0646\u06cc\u0633\u062a \u2014 \u06cc\u06a9 «Good, you?» \u0633\u0627\u062f\u0647 \u06a9\u0627\u0641\u06cc \u0627\u0633\u062a.' },
      { id: 'challenge', label: 'Challenge', icon: 'bolt', dur: 45,
        transcript: 'Today\u2019s challenge: use the phrase "How\u2019s it going?" with one new person. You\u2019ve got this.',
        fa: '\u0686\u0627\u0644\u0634 \u0627\u0645\u0631\u0648\u0632: \u062c\u0645\u0644\u0647\u0654 «How\u2019s it going?» \u0631\u0627 \u0628\u0627 \u06cc\u06a9 \u0646\u0641\u0631 \u062c\u062f\u06cc\u062f \u0628\u0647 \u06a9\u0627\u0631 \u0628\u0628\u0631. \u0627\u0632 \u067e\u0633\u0634 \u0628\u0631\u0645\u06cc\u0627\u06cc.' },
    ],
  },
  // Today's plan events
  events: [
    { id: 'networking', time: '5:00 PM', title: 'Networking event', place: 'Downtown Tech Meetup',
      dot: 'primary', kind: 'networking' },
    { id: 'coffee', time: '7:30 PM', title: 'Coffee with Sara', place: 'Sam James Coffee Bar',
      dot: 'accent', kind: 'coffee' },
  ],
  weather: { temp: '12\u00b0', label: 'Sunny', icon: 'wb_sunny', wear: 'Light jacket' },
  // Today's challenge (also the brief's closing segment) — the daily habit hook
  challenge: {
    phrase: 'How\u2019s it going?',
    task: 'Use “How\u2019s it going?” with one new person today.',
    task_fa: '\u0627\u0645\u0631\u0648\u0632 \u062c\u0645\u0644\u0647\u0654 «How\u2019s it going?» \u0631\u0627 \u0628\u0627 \u06cc\u06a9 \u0646\u0641\u0631 \u062c\u062f\u06cc\u062f \u0628\u0647 \u06a9\u0627\u0631 \u0628\u0628\u0631.',
  },
  // Tomorrow's plan — a forward-looking peek so the brief feels ahead of the day
  tomorrow: [
    { id: 't1', time: '9:00 AM', title: 'Coffee with a coworker', place: 'Dineen Coffee Co.', dot: 'accent', kind: 'coffee' },
  ],
  // Lock-screen push notification (event-triggered, ~2h before)
  notification: {
    time: '3:02', day: 'Monday, June 1',
    app: 'DORNA', when: '2h ago',
    title: 'Networking event at 5:00 PM',
    body: '3 openers are ready. Tap to prep before you go.',
  },
  // Around you venues
  venues: [
    { id: 'coffee', icon: 'local_cafe', title: 'Coffee shop', phrase: 'Is this seat taken?', phrase_fa: '\u0627\u06cc\u0646 \u0635\u0646\u062f\u0644\u06cc \u062e\u0627\u0644\u06cc\u0647\u061f', dist: '40 m' },
    { id: 'gym', icon: 'fitness_center', title: 'Gym', phrase: 'How many sets you got left?', phrase_fa: '\u0686\u0646\u062f \u0633\u062a \u062f\u06cc\u06af\u0647 \u0645\u0648\u0646\u062f\u0647\u061f', dist: '120 m' },
    { id: 'bus', icon: 'directions_bus', title: 'Bus stop', phrase: 'Do you know if the 5 is running?', phrase_fa: '\u0645\u06cc\u200c\u062f\u0648\u0646\u06cc\u062f \u0627\u062a\u0648\u0628\u0648\u0633 \u06f5 \u06a9\u0627\u0631 \u0645\u06cc\u200c\u06a9\u0646\u0647\u061f', dist: '60 m' },
    { id: 'grocery', icon: 'shopping_cart', title: 'Grocery store', phrase: 'Have you tried these before?', phrase_fa: '\u062a\u0627 \u062d\u0627\u0644\u0627 \u0627\u06cc\u0646\u200c\u0647\u0627 \u0631\u0648 \u0627\u0645\u062a\u062d\u0627\u0646 \u06a9\u0631\u062f\u06cc\u062f\u061f', dist: '200 m' },
  ],
  here: { name: 'Central Library', dist: '50 m', tip: 'Quiet spot \u2014 keep it low-key. Try a soft opener.', tip_fa: '\u062c\u0627\u06cc \u0622\u0631\u0627\u0645\u06cc \u0627\u0633\u062a \u2014 \u0622\u0631\u0627\u0645 \u0628\u0627\u0634. \u0628\u0627 \u06cc\u06a9 \u0634\u0631\u0648\u0639 \u0645\u0644\u0627\u06cc\u0645 \u0627\u0645\u062a\u062d\u0627\u0646 \u06a9\u0646.' },
  // Phrase library
  phrases: [
    { id: 'p1', text: 'Do you come here often?', text_fa: '\u0632\u06cc\u0627\u062f \u0628\u0647 \u0627\u06cc\u0646\u062c\u0627 \u0645\u06cc\u200c\u0622\u06cc\u06cc\u062f\u061f', ipa: '/du\u02d0 ju\u02d0 k\u028cm h\u026a\u0259r \u02c8\u0252f.\u0259n/', save: true,
      meaning: 'A classic conversation starter, though sometimes seen as a bit of a cliche in social settings.',
      meaning_fa: '\u06cc\u06a9 \u062c\u0645\u0644\u0647\u0654 \u06a9\u0644\u0627\u0633\u06cc\u06a9 \u0628\u0631\u0627\u06cc \u0634\u0631\u0648\u0639 \u06af\u0641\u062a\u06af\u0648\u060c \u0647\u0631\u0686\u0646\u062f \u06af\u0627\u0647\u06cc \u06a9\u0645\u06cc \u06a9\u0644\u06cc\u0634\u0647\u200c\u0627\u06cc \u0628\u0647 \u0646\u0638\u0631 \u0645\u06cc\u200c\u0631\u0633\u062f.',
      when: ['Meeting someone new at a cafe or social event.', 'Breaking the ice in a place you visit regularly.'] },
    { id: 'p2', text: 'That looks good \u2014 what did you order?', text_fa: '\u062e\u0648\u0634\u0645\u0632\u0647 \u0628\u0647 \u0646\u0638\u0631 \u0645\u06cc\u200c\u0631\u0633\u062f \u2014 \u0686\u06cc \u0633\u0641\u0627\u0631\u0634 \u062f\u0627\u062f\u06cc\u062f\u061f', ipa: '/\u00f0\u00e6t l\u028aks g\u028ad/', save: false,
      meaning: 'Friendly, low-pressure way to start chatting with someone nearby.',
      meaning_fa: '\u0631\u0627\u0647\u06cc \u062f\u0648\u0633\u062a\u0627\u0646\u0647 \u0648 \u0628\u062f\u0648\u0646 \u0641\u0634\u0627\u0631 \u0628\u0631\u0627\u06cc \u0634\u0631\u0648\u0639 \u06af\u0641\u062a\u06af\u0648 \u0628\u0627 \u06a9\u0633\u06cc \u062f\u0631 \u06a9\u0646\u0627\u0631\u062a\u0627\u0646.',
      when: ['Standing in line at a cafe or food spot.', 'Sitting near someone at a counter.'] },
    { id: 'p3', text: 'Is this seat taken?', text_fa: '\u0627\u06cc\u0646 \u0635\u0646\u062f\u0644\u06cc \u062e\u0627\u0644\u06cc\u0647\u061f', ipa: '/\u026az \u00f0\u026as si\u02d0t \u02c8te\u026ak\u0259n/', save: true,
      meaning: 'Polite way to ask if you can sit somewhere.',
      meaning_fa: '\u0631\u0627\u0647\u06cc \u0645\u0624\u062f\u0628\u0627\u0646\u0647 \u0628\u0631\u0627\u06cc \u067e\u0631\u0633\u06cc\u062f\u0646 \u0627\u06cc\u0646\u06a9\u0647 \u0622\u06cc\u0627 \u0645\u06cc\u200c\u062a\u0648\u0627\u0646\u06cc\u062f \u062c\u0627\u06cc\u06cc \u0628\u0646\u0634\u06cc\u0646\u06cc\u062f.',
      when: ['A busy cafe or library.', 'On transit or at an event.'] },
    { id: 'p4', text: "What do you think of the event so far?", text_fa: '\u062a\u0627 \u0627\u06cc\u0646\u062c\u0627 \u0646\u0638\u0631\u062a\u0627\u0646 \u062f\u0631\u0628\u0627\u0631\u0647\u0654 \u0627\u06cc\u0646 \u0628\u0631\u0646\u0627\u0645\u0647 \u0686\u06cc\u0633\u062a\u061f', ipa: '/w\u0252t du\u02d0 ju\u02d0 \u03b8\u026a\u014bk \u0259v \u00f0i \u026a\u02c8v\u025bnt s\u0259\u028a f\u0251\u02d0/', save: false,
      meaning: 'Keeps a conversation going at a gathering once you\u2019ve broken the ice.',
      meaning_fa: '\u06af\u0641\u062a\u06af\u0648 \u0631\u0627 \u062f\u0631 \u06cc\u06a9 \u062f\u0648\u0631\u0647\u0645\u06cc \u0627\u062f\u0627\u0645\u0647 \u0645\u06cc\u200c\u062f\u0647\u062f\u060c \u0628\u0639\u062f \u0627\u0632 \u0627\u06cc\u0646\u06a9\u0647 \u0633\u0631 \u0635\u062d\u0628\u062a \u0631\u0627 \u0628\u0627\u0632 \u06a9\u0631\u062f\u06cc\u062f.',
      when: ['Mid-way through a networking event.', 'Standing with someone between sessions.'] },
    { id: 'p5', text: 'Nice to meet you!', text_fa: '\u0627\u0632 \u0622\u0634\u0646\u0627\u06cc\u06cc\u200c\u062a\u0627\u0646 \u062e\u0648\u0634\u0648\u0642\u062a\u0645!', ipa: '/na\u026as tu\u02d0 mi\u02d0t ju\u02d0/', save: true,
      meaning: 'The standard friendly greeting when you first meet someone.',
      meaning_fa: '\u0627\u062d\u0648\u0627\u0644\u200c\u067e\u0631\u0633\u06cc \u062f\u0648\u0633\u062a\u0627\u0646\u0647\u0654 \u0631\u0627\u06cc\u062c \u0648\u0642\u062a\u06cc \u0628\u0631\u0627\u06cc \u0628\u0627\u0631 \u0627\u0648\u0644 \u0628\u0627 \u06a9\u0633\u06cc \u0622\u0634\u0646\u0627 \u0645\u06cc\u200c\u0634\u0648\u06cc\u062f.',
      when: ['First handshake at any event.', 'Being introduced by a friend.'] },
    { id: 'p6', text: 'What do you do for a living?', text_fa: '\u0634\u063a\u0644\u062a\u0627\u0646 \u0686\u06cc\u0633\u062a\u061f', ipa: '/w\u0252t du\u02d0 ju\u02d0 du\u02d0 f\u0254\u02d0r \u0259 \u02c8l\u026av\u026a\u014b/', save: false,
      meaning: 'A natural follow-up once a conversation gets going.',
      meaning_fa: '\u067e\u06cc\u200c\u06af\u06cc\u0631\u06cc \u0637\u0628\u06cc\u0639\u06cc \u0648\u0642\u062a\u06cc \u06af\u0641\u062a\u06af\u0648 \u062f\u0627\u0631\u062f \u062c\u0627 \u0645\u06cc\u200c\u0627\u0641\u062a\u062f.',
      when: ['After introductions at a meetup.', 'Getting to know a new coworker.'] },
  ],
  // Networking event detail
  networking: {
    time: '5:00 PM \u00b7 Today', title: 'Networking event', place: 'Downtown Tech Meetup',
    crowd: 'Professionals, recruiters, students',
    avatars: [
      'https://lh3.googleusercontent.com/aida-public/AB6AXuA3E5bEOP4_tgEkRFM6pFzEhwk2DOUxRqZwfnbAKgT_ufZn730bbbm6ec7A5mMrXRnGjFXl7VPqoFYoMMnJgQ-O4fl8jr1J9f1oZS92l00OnIHvBaePb3xhnWBNprJ38tHI1AwpjbG7Amc8KUzf89PnOumuoUvdKzFtKr85TYlcuHtLdN-KyOerOQMW1KiS409Jkm6ynW1W1R_i5P718nuGrMi0NMluuVk7TlBXDR-DmGm_PVYQKBmH7-7-u-0ddDu4qa6RvWXtGiE',
      'https://lh3.googleusercontent.com/aida-public/AB6AXuBC_hG523Mm7oNEcPSI4XSaFuMzLe-QytsEZViwpj9XGtqw97GBgXSY5H3X6lG2hBmt4RXjP8r8aFvki-Fq0rt13IP1qHmQw_HTFBZ8M4--XMIhBQ2dCUOQ3z-IP9ceWFPdO9UPLK32Kh1dhZLgHrgk5od_splxpckQH4my_nPOnPif5sbnvGvTXzasMAseRw24MxSteFMMkOVqv1t40gh9K1yFymWsXpQePzgDc1TycbKGVkU7dttEd3IFxlpbiF98eebTUMHd94A',
    ],
    icebreakers: [
      'Hi, I\u2019m Nima \u2014 what brings you here tonight?',
      'I\u2019m new here, do you come to these often?',
    ],
    icebreakers_fa: [
      '\u0633\u0644\u0627\u0645\u060c \u0645\u0646 \u0646\u06cc\u0645\u0627 \u0647\u0633\u062a\u0645 \u2014 \u0686\u06cc \u0634\u062f \u06a9\u0647 \u0627\u0645\u0634\u0628 \u0627\u06cc\u0646\u062c\u0627 \u0627\u0648\u0645\u062f\u06cc\u062f\u061f',
      '\u0645\u0646 \u062a\u0627\u0632\u0647\u200c\u0648\u0627\u0631\u062f\u0645\u060c \u0634\u0645\u0627 \u0632\u06cc\u0627\u062f \u0628\u0647 \u0627\u06cc\u0646 \u0628\u0631\u0646\u0627\u0645\u0647\u200c\u0647\u0627 \u0645\u06cc\u0627\u06cc\u06cc\u062f\u061f',
    ],
    steps: ['Open', 'Ask', 'Follow up'],
  },
  // Coffee shop scene
  coffee: {
    title: 'Coffee Shop', vibe: 'Casual, friendly vibe',
    starters: [
      { text: 'That looks good \u2014 what did you order?', fa: '\u062e\u0648\u0634\u0645\u0632\u0647 \u0628\u0647 \u0646\u0638\u0631 \u0645\u06cc\u200c\u0631\u0633\u062f \u2014 \u0686\u06cc \u0633\u0641\u0627\u0631\u0634 \u062f\u0627\u062f\u06cc\u062f\u061f', ipa: '/\u00f0\u00e6t l\u028aks g\u028ad/' },
      { text: 'Is this seat taken?', fa: '\u0627\u06cc\u0646 \u0635\u0646\u062f\u0644\u06cc \u062e\u0627\u0644\u06cc\u0647\u061f', ipa: '/\u026az \u00f0\u026as si\u02d0t \u02c8te\u026ak\u0259n/' },
      { text: 'Do you come here often?', fa: '\u0632\u06cc\u0627\u062f \u0628\u0647 \u0627\u06cc\u0646\u062c\u0627 \u0645\u06cc\u200c\u0622\u06cc\u06cc\u062f\u061f', ipa: '/du\u02d0 ju\u02d0 k\u028cm h\u026a\u0259r \u02c8\u0252f.\u0259n/' },
    ],
    tip: 'A smile and eye contact go a long way.',
    tip_fa: '\u06cc\u06a9 \u0644\u0628\u062e\u0646\u062f \u0648 \u062a\u0645\u0627\u0633 \u0686\u0634\u0645\u06cc \u062e\u06cc\u0644\u06cc \u06a9\u0645\u06a9 \u0645\u06cc\u200c\u06a9\u0646\u062f.',
  },
  // Practice cards (deck)
  practiceDeck: {
    scene: 'Networking', lesson: 'Break the ice',
    cards: [
      { text: 'Hi, what brings you here tonight?', ipa: '/ha\u026a w\u0252t br\u026a\u014bz ju\u02d0 h\u026a\u0259r t\u0259\u02c8na\u026at/' },
      { text: 'What do you think of the event so far?', ipa: '/w\u0252t du\u02d0 ju\u02d0 \u03b8\u026a\u014bk \u0259v \u00f0i \u026a\u02c8v\u025bnt s\u0259\u028a f\u0251\u02d0/' },
      { text: 'What do you do for a living?', ipa: '/w\u0252t du\u02d0 ju\u02d0 du\u02d0 f\u0254\u02d0r \u0259 \u02c8l\u026av\u026a\u014b/' },
      { text: 'Have you been to one of these before?', ipa: '/h\u00e6v ju\u02d0 b\u026an tu\u02d0 w\u028cn \u0259v \u00f0i\u02d0z b\u026a\u02c8f\u0254\u02d0/' },
      { text: 'It was great talking with you.', ipa: '/\u026at w\u0252z gre\u026at \u02c8t\u0254\u02d0k\u026a\u014b w\u026a\u00f0 ju\u02d0/' },
      { text: 'Can I get your contact?', ipa: '/k\u00e6n a\u026a g\u025bt j\u0254\u02d0r \u02c8k\u0252nt\u00e6kt/' },
    ],
  },
  // Profile
  profile: {
    stats: { phrases: 24, conversations: 8, briefs: 12 },
    streak: 6,
    weakAreas: ['articles (a/an)', 'past tense'],
    interests: ['Tech', 'Music', 'Travel', 'Cooking'],
    savedCount: 14,
  },
};

Object.assign(window, { DornaCtx, useApp, Icon, speak, THEME_PRESETS, RADIUS_PRESETS, FONTS, FA_FONT, DATA });
