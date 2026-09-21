import { useState, useRef, useEffect } from "react";

type Tab = "signin" | "signup";
type RegistrationRole = "alumno" | "instructor" | "externo";

/* ── Smooth lerp helper ── */
function lerp(a: number, b: number, t: number) { return a + (b - a) * t; }

/* ── Tux penguin with smooth eye tracking ── */
function TuxPenguin({ sensitiveFieldFocused }: { sensitiveFieldFocused: boolean }) {
  const svgRef = useRef<SVGSVGElement>(null);
  const rafRef = useRef<number>(0);
  const targetRef = useRef({ x: 0, y: 0 });
  const currentRef = useRef({ x: 0, y: 0 });
  const [pupil, setPupil] = useState({ x: 0, y: 0 });
  const [wingRaise, setWingRaise] = useState(0); // 0 = down, 1 = covering eyes
  const [blink, setBlink] = useState(false);

  const L = { x: 120, y: 152 };
  const R = { x: 180, y: 152 };
  const MAX = 8;

  // Smooth RAF loop
  useEffect(() => {
    function tick() {
      currentRef.current.x = lerp(currentRef.current.x, targetRef.current.x, 0.1);
      currentRef.current.y = lerp(currentRef.current.y, targetRef.current.y, 0.1);
      setPupil({ x: currentRef.current.x, y: currentRef.current.y });
      rafRef.current = requestAnimationFrame(tick);
    }
    rafRef.current = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(rafRef.current);
  }, []);

  // Mouse tracking
  useEffect(() => {
    function onMove(e: MouseEvent) {
      if (sensitiveFieldFocused || !svgRef.current) return;
      const rect = svgRef.current.getBoundingClientRect();
      const sx = 300 / rect.width;
      const sy = 420 / rect.height;
      const mx = (e.clientX - rect.left) * sx;
      const my = (e.clientY - rect.top) * sy;
      const cx = (L.x + R.x) / 2;
      const cy = (L.y + R.y) / 2;
      const dx = mx - cx;
      const dy = my - cy;
      const dist = Math.sqrt(dx * dx + dy * dy) || 1;
      const t = Math.min(dist, 80) / 80;
      targetRef.current = { x: (dx / dist) * MAX * t, y: (dy / dist) * MAX * t };
    }
    window.addEventListener("mousemove", onMove);
    return () => window.removeEventListener("mousemove", onMove);
  }, [sensitiveFieldFocused]);

  // Reacciona únicamente al número de control o la matrícula.
  useEffect(() => {
    if (sensitiveFieldFocused) {
      targetRef.current = { x: 0, y: MAX };
      setWingRaise(1);
    } else {
      setWingRaise(0);
    }
  }, [sensitiveFieldFocused]);

  // Occasional blinking
  useEffect(() => {
    const schedule = () => {
      const delay = 2500 + Math.random() * 3000;
      return setTimeout(() => {
        setBlink(true);
        setTimeout(() => { setBlink(false); schedule(); }, 120);
      }, delay);
    };
    const t = schedule();
    return () => clearTimeout(t);
  }, []);

  const lx = L.x + pupil.x;
  const ly = L.y + pupil.y;
  const rx = R.x + pupil.x;
  const ry = R.y + pupil.y;

  // Wing arm positions interpolated via CSS transform
  const wingAngleL = wingRaise * -95; // degrees
  const wingAngleR = wingRaise * 95;

  return (
    <svg
      ref={svgRef}
      viewBox="0 0 300 440"
      style={{ width: "min(100%, 260px)", maxHeight: "min(440px, calc(100dvh - 190px))", display: "block", filter: "drop-shadow(0 20px 40px rgba(0,0,0,0.5))" }}
      aria-label="Lexus the penguin"
    >
      <defs>
        <radialGradient id="tBodyG" cx="38%" cy="30%" r="70%">
          <stop offset="0%" stopColor="#1e2f5e"/>
          <stop offset="60%" stopColor="#111a3a"/>
          <stop offset="100%" stopColor="#080d1e"/>
        </radialGradient>
        <radialGradient id="tBellyG" cx="48%" cy="35%" r="60%">
          <stop offset="0%" stopColor="#ffffff"/>
          <stop offset="70%" stopColor="#e0ecfa"/>
          <stop offset="100%" stopColor="#bdd4ed"/>
        </radialGradient>
        <radialGradient id="tEyeG" cx="45%" cy="42%" r="58%">
          <stop offset="0%" stopColor="#ffffff"/>
          <stop offset="100%" stopColor="#e8f2ff"/>
        </radialGradient>
        <radialGradient id="tHeadG" cx="35%" cy="28%" r="68%">
          <stop offset="0%" stopColor="#263060"/>
          <stop offset="100%" stopColor="#090e20"/>
        </radialGradient>
        <linearGradient id="tBeakG" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#fcd34d"/>
          <stop offset="100%" stopColor="#d97706"/>
        </linearGradient>
        <linearGradient id="tFootG" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#fcd34d"/>
          <stop offset="100%" stopColor="#c2690a"/>
        </linearGradient>
        <radialGradient id="tWingG" cx="60%" cy="25%" r="70%">
          <stop offset="0%" stopColor="#1e2f5e"/>
          <stop offset="100%" stopColor="#080d1e"/>
        </radialGradient>
        <filter id="tShadow">
          <feDropShadow dx="0" dy="5" stdDeviation="8" floodColor="#000" floodOpacity="0.4"/>
        </filter>
        <filter id="tGlow">
          <feGaussianBlur stdDeviation="3" result="blur"/>
          <feComposite in="SourceGraphic" in2="blur" operator="over"/>
        </filter>
      </defs>

      {/* Ground shadow */}
      <ellipse cx="150" cy="432" rx="80" ry="8" fill="rgba(0,0,0,0.3)"/>

      {/* ── FEET ── */}
      {/* Left foot */}
      <g>
        <path d="M100 418 Q90 408 82 412 Q76 420 84 424 Q92 428 100 418Z" fill="url(#tFootG)"/>
        <path d="M112 420 Q104 408 96 410 Q90 416 96 422 Q104 426 112 420Z" fill="url(#tFootG)"/>
        <path d="M124 418 Q118 408 110 412 Q106 420 114 424 Q122 426 124 418Z" fill="url(#tFootG)"/>
        <ellipse cx="104" cy="420" rx="26" ry="10" fill="url(#tFootG)" opacity="0.7"/>
      </g>
      {/* Right foot */}
      <g>
        <path d="M176 418 Q172 408 164 412 Q160 420 168 424 Q176 426 176 418Z" fill="url(#tFootG)"/>
        <path d="M188 420 Q184 408 176 410 Q170 416 176 422 Q184 426 188 420Z" fill="url(#tFootG)"/>
        <path d="M200 418 Q198 408 190 408 Q182 412 186 420 Q192 426 200 418Z" fill="url(#tFootG)"/>
        <ellipse cx="188" cy="420" rx="26" ry="10" fill="url(#tFootG)" opacity="0.7"/>
      </g>

      {/* ── BODY ── */}
      {/* Main body — wide and round like a sitting penguin */}
      <ellipse cx="150" cy="298" rx="90" ry="115" fill="url(#tBodyG)" filter="url(#tShadow)"/>

      {/* Belly — large prominent white oval */}
      <ellipse cx="150" cy="308" rx="58" ry="88" fill="url(#tBellyG)"/>
      {/* Belly inner sheen */}
      <ellipse cx="140" cy="275" rx="18" ry="26" fill="rgba(255,255,255,0.22)" style={{ transform: "rotate(-12deg)", transformOrigin: "140px 275px" }}/>

      {/* ── WINGS ── */}
      {/* Left wing — rotates from shoulder */}
      <g style={{
        transformOrigin: "72px 238px",
        transform: `rotate(${wingAngleL}deg)`,
        transition: "transform 0.45s cubic-bezier(0.34,1.5,0.64,1)"
      }}>
        {/* Wing shape: broad flipper */}
        <path d="M72 238 C46 260 34 300 36 348 C48 328 60 300 68 278 C72 300 74 330 72 355 C82 330 86 295 78 238 Z" fill="url(#tWingG)"/>
        <path d="M52 330 C46 340 40 350 42 358 C48 348 52 338 52 330Z" fill="rgba(255,255,255,0.07)"/>
      </g>

      {/* Right wing */}
      <g style={{
        transformOrigin: "228px 238px",
        transform: `rotate(${wingAngleR}deg)`,
        transition: "transform 0.45s cubic-bezier(0.34,1.5,0.64,1)"
      }}>
        <path d="M228 238 C254 260 266 300 264 348 C252 328 240 300 232 278 C228 300 226 330 228 355 C218 330 214 295 222 238 Z" fill="url(#tWingG)"/>
        <path d="M248 330 C254 340 260 350 258 358 C252 348 248 338 248 330Z" fill="rgba(255,255,255,0.07)"/>
      </g>

      {/* ── HEAD ── */}
      {/* Large round head */}
      <ellipse cx="150" cy="162" rx="72" ry="70" fill="url(#tHeadG)" filter="url(#tShadow)"/>
      {/* Head gloss */}
      <ellipse cx="128" cy="118" rx="22" ry="14" fill="rgba(255,255,255,0.07)" style={{ transform: "rotate(-25deg)", transformOrigin: "128px 118px" }}/>

      {/* Face patch — key feature of Tux */}
      <ellipse cx="150" cy="162" rx="46" ry="44" fill="url(#tBellyG)" opacity="0.22"/>

      {/* ── EYES ── */}
      {/* Outer ring (slight shadow socket) */}
      <circle cx={L.x} cy={L.y} r="25" fill="rgba(0,0,0,0.2)"/>
      <circle cx={R.x} cy={R.y} r="25" fill="rgba(0,0,0,0.2)"/>
      {/* White sclera */}
      <circle cx={L.x} cy={L.y} r="22" fill="url(#tEyeG)"/>
      <circle cx={R.x} cy={R.y} r="22" fill="url(#tEyeG)"/>

      {/* Blink eyelids */}
      {blink && (
        <>
          <ellipse cx={L.x} cy={L.y - 11} rx="22" ry="24" fill="url(#tHeadG)"/>
          <ellipse cx={R.x} cy={R.y - 11} rx="22" ry="24" fill="url(#tHeadG)"/>
        </>
      )}

      {/* Pupils — layered for depth */}
      {!blink && (
        <>
          {/* Left eye */}
          <circle cx={lx} cy={ly} r="13" fill="#08111f"/>
          <circle cx={lx} cy={ly} r="10" fill="#0d1a30"/>
          <circle cx={lx} cy={ly} r="6.5" fill="#030a15"/>
          <circle cx={lx - 4} cy={ly - 4} r="3.2" fill="white" opacity="0.9"/>
          <circle cx={lx + 2.5} cy={ly - 1.5} r="1.5" fill="white" opacity="0.45"/>
          {/* Right eye */}
          <circle cx={rx} cy={ry} r="13" fill="#08111f"/>
          <circle cx={rx} cy={ry} r="10" fill="#0d1a30"/>
          <circle cx={rx} cy={ry} r="6.5" fill="#030a15"/>
          <circle cx={rx - 4} cy={ry - 4} r="3.2" fill="white" opacity="0.9"/>
          <circle cx={rx + 2.5} cy={ry - 1.5} r="1.5" fill="white" opacity="0.45"/>
        </>
      )}

      {/* ── BEAK ── */}
      {/* Upper beak — wide and round */}
      <path d="M132 156 Q150 148 168 156 Q164 170 150 178 Q136 170 132 156Z" fill="url(#tBeakG)"/>
      {/* Beak crease */}
      <path d="M140 163 Q150 168 160 163" fill="none" stroke="#c2690a" strokeWidth="1.8" strokeLinecap="round"/>
      {/* Beak highlight */}
      <ellipse cx="146" cy="157" rx="7" ry="4" fill="rgba(255,255,255,0.3)" style={{ transform: "rotate(-8deg)", transformOrigin: "146px 157px" }}/>

      {/* Neck blend */}
      <ellipse cx="150" cy="210" rx="56" ry="26" fill="url(#tBodyG)"/>
    </svg>
  );
}

/* ── Main App ── */
export default function App() {
  const [tab, setTab] = useState<Tab>("signin");
  const [role, setRole] = useState<RegistrationRole>("alumno");
  const [sensitiveFieldFocused, setSensitiveFieldFocused] = useState(false);

  return (
    <div
      className="flex flex-col lg:flex-row"
      style={{
        fontFamily: "var(--font-body)", width: "100%", height: "100dvh", minHeight: 0,
        overflowX: "hidden", overflowY: "auto", overscrollBehaviorY: "contain",
        background: "#080c18", colorScheme: "dark",
      }}
    >
      {/* ── Left panel: form ── */}
      <div
        className="w-full lg:w-auto lg:flex-1 flex flex-col items-center px-4 sm:px-6 lg:px-8 py-10 relative"
        style={{
          background:
            "radial-gradient(ellipse at 30% 20%, #1e0a3c 0%, transparent 55%), radial-gradient(ellipse at 80% 80%, #0a1a3a 0%, transparent 50%), #080c18",
          minWidth: 0,
          minHeight: "100dvh",
          height: "max-content",
          boxSizing: "border-box",
        }}
      >
        <div
          className="absolute rounded-full pointer-events-none hidden md:block"
          style={{
            width: 320, height: 320, top: "5%", left: "2%",
            background: "radial-gradient(circle, rgba(120,40,200,0.15) 0%, transparent 70%)",
            filter: "blur(50px)",
          }}
        />

        <div
          className="absolute hidden xl:block pointer-events-none"
          style={{
            width: "clamp(170px, 15vw, 215px)",
            top: tab === "signin" ? "clamp(90px, 14vh, 160px)" : "8px",
            right: "5%",
            zIndex: 1,
            transition: "top 550ms cubic-bezier(0.22, 1, 0.36, 1)",
          }}
          aria-hidden="true"
        >
          <ToucanAccent />
        </div>

        <div className="w-full relative z-10 my-auto" style={{ maxWidth: 600, minWidth: 0 }}>
          {/* Brand */}
          <div className="flex items-center gap-2.5 mb-8">
            <span style={{ fontFamily: "var(--font-display)", fontWeight: 700, fontSize: 20, color: "#fff", letterSpacing: "-0.03em" }}>
              Innovación Tucán
            </span>
          </div>

          {/* Heading */}
          <div className="mb-7">
            <h1 style={{ fontFamily: "var(--font-display)", fontWeight: 700, fontSize: "clamp(26px, 3vw, 36px)", color: "#fff", letterSpacing: "-0.03em", lineHeight: 1.15, marginBottom: 8 }}>
              {tab === "signin" ? "Bienvenido a Comunidad Unix ITC" : "Crea tu cuenta"}
            </h1>
            <p style={{ fontSize: 14, color: "rgba(255,255,255,0.42)", lineHeight: 1.6 }}>
              {tab === "signin" ? "Inicia sesión para continuar aprendiendo." : "Únete y comienza aprender."}
            </p>
          </div>

          {/* Tab switcher */}
          <div className="flex mb-7" style={{ background: "rgba(255,255,255,0.06)", borderRadius: 13, padding: 4, gap: 4 }}>
            {(["signin", "signup"] as Tab[]).map((t) => (
              <button
                key={t}
                onClick={() => { setSensitiveFieldFocused(false); setTab(t); }}
                style={{
                  flex: 1, padding: "10px 0", borderRadius: 10, border: "none", cursor: "pointer",
                  fontFamily: "var(--font-display)", fontWeight: 600, fontSize: 13.5, letterSpacing: "-0.01em",
                  transition: "all 0.2s ease",
                  background: tab === t ? "linear-gradient(135deg, rgba(249,115,22,0.25), rgba(168,85,247,0.25))" : "transparent",
                  color: tab === t ? "#fff" : "rgba(255,255,255,0.35)",
                  boxShadow: tab === t ? "0 1px 0 rgba(255,255,255,0.06) inset, 0 2px 10px rgba(0,0,0,0.2)" : "none",
                  borderTop: tab === t ? "1px solid rgba(249,115,22,0.3)" : "1px solid transparent",
                }}
              >
                {t === "signin" ? "Iniciar sesión" : "Registrarse"}
              </button>
            ))}
          </div>

          {/* Tipo de registro: solo aparece al crear una cuenta */}
          {tab === "signup" && (
            <div className="mb-6">
              <p style={{ fontSize: 13, color: "rgba(255,255,255,0.5)", marginBottom: 10 }}>
                Selecciona tu tipo de registro
              </p>
              <div className="grid grid-cols-3 gap-2" role="group" aria-label="Tipo de registro">
                {(["alumno", "instructor", "externo"] as RegistrationRole[]).map((option) => (
                  <button
                    key={option}
                    type="button"
                    aria-pressed={role === option}
                    onClick={() => { setSensitiveFieldFocused(false); setRole(option); }}
                    style={{
                      minWidth: 0, minHeight: 84, padding: "12px 4px", borderRadius: 12,
                      display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 5,
                      cursor: "pointer", fontFamily: "var(--font-body)", fontSize: 12, fontWeight: 600,
                      color: role === option ? "#fff" : "rgba(255,255,255,0.5)",
                      background: role === option ? "linear-gradient(135deg, rgba(249,115,22,0.22), rgba(168,85,247,0.25))" : "rgba(255,255,255,0.05)",
                      border: role === option ? "1px solid rgba(249,115,22,0.65)" : "1px solid rgba(255,255,255,0.1)",
                      boxShadow: role === option ? "0 4px 18px rgba(168,85,247,0.16)" : "none",
                      transform: role === option ? "translateY(-2px)" : "translateY(0)",
                      transition: "background 0.25s ease, border-color 0.25s ease, box-shadow 0.25s ease, transform 0.25s ease, color 0.25s ease",
                    }}
                  >
                    <RoleIcon role={option} />
                    <span>{option === "alumno" ? "Alumno" : option === "instructor" ? "Instructor" : "Externo"}</span>
                  </button>
                ))}
              </div>
            </div>
          )}

          {/* Maqueta visual: el botón de Google aún no inicia sesión */}
          <form className="flex flex-col gap-4" onSubmit={(e) => e.preventDefault()}>
            {tab === "signup" && (
              <Field label="Nombre completo *" type="text" placeholder="Tu nombre completo" autoComplete="name" required />
            )}
            {tab === "signup" && (
              <>
                {role === "alumno" && (
                  <>
                    <Field label="ID / número de control *" type="text" placeholder="Ej. 21040123" required onFocus={() => setSensitiveFieldFocused(true)} onBlur={() => setSensitiveFieldFocused(false)} />
                    <InstitutionField />
                  </>
                )}
                {role === "instructor" && (
                  <>
                    <Field label="Matrícula del instructor *" type="text" placeholder="Tu matrícula" required onFocus={() => setSensitiveFieldFocused(true)} onBlur={() => setSensitiveFieldFocused(false)} />
                    <InstitutionField />
                    <Field label="Departamento / Academia *" type="text" placeholder="Ej. Academia de Sistemas" required />
                    <Field label="Especialidad / Área de conocimiento *" type="text" placeholder="Ej. Desarrollo de Software" required />
                    <AcademicDegreeField />
                  </>
                )}
                {role === "externo" && (
                  <ExternalExperienceField />
                )}
              </>
            )}

            <SocialButton label={tab === "signin" ? "Iniciar sesión con Google" : "Registrarse con Google"} />
          </form>

          <p className="text-center mt-6" style={{ fontSize: 13, color: "rgba(255,255,255,0.28)" }}>
            {tab === "signin" ? "¿No tienes cuenta? " : "¿Ya tienes cuenta? "}
            <button
              onClick={() => { setSensitiveFieldFocused(false); setTab(tab === "signin" ? "signup" : "signin"); }}
              style={{ background: "none", border: "none", cursor: "pointer", color: "rgba(249,115,22,0.9)", fontFamily: "var(--font-body)", fontSize: 13, padding: 0, fontWeight: 500 }}
            >
              {tab === "signin" ? "Regístrate" : "Inicia sesión"}
            </button>
          </p>
        </div>
      </div>

      {/* ── Right panel: Tux illustration ── */}
      <div
        className="hidden lg:flex flex-col items-center justify-center relative overflow-hidden"
        style={{
          width: "36%", minWidth: 0, height: "100dvh", position: "sticky", top: 0, alignSelf: "flex-start", flexShrink: 0,
          background: "linear-gradient(175deg, #0d1033 0%, #1a2060 30%, #1e2870 55%, #162060 80%, #0d1545 100%)",
        }}
      >
        {/* Stars */}
        {STARS.map((s, i) => (
          <div key={i} className="absolute rounded-full" style={{ left: `${s.x}%`, top: `${s.y}%`, width: s.r, height: s.r, background: "#fff", opacity: s.o }} />
        ))}

        {/* Cloud strips */}
        {[{ top: "8%", left: "10%", w: 120, opacity: 0.18 }, { top: "14%", right: "8%", w: 90, opacity: 0.14 }, { top: "22%", left: "5%", w: 70, opacity: 0.12 }].map((c, i) => (
          <div key={i} className="absolute" style={{ top: c.top, left: (c as any).left, right: (c as any).right, width: c.w, height: 12, borderRadius: 6, background: "rgba(180,200,255,0.5)", opacity: c.opacity, filter: "blur(3px)" }} />
        ))}

        {/* Mountains */}
        <svg viewBox="0 0 500 200" className="absolute bottom-0 left-0 w-full" style={{ height: "19%" }} preserveAspectRatio="none">
          <polygon points="0,200 100,40 200,200" fill="#0d2a5e" opacity="0.9"/>
          <polygon points="60,200 180,20 300,200" fill="#102f6e" opacity="0.85"/>
          <polygon points="200,200 340,30 480,200" fill="#0d2a5e" opacity="0.9"/>
          <polygon points="350,200 430,60 500,200" fill="#0e2f72" opacity="0.8"/>
          {/* Snow caps */}
          <polygon points="100,40 85,75 115,75" fill="#dce8ff" opacity="0.7"/>
          <polygon points="180,20 160,65 200,65" fill="#dce8ff" opacity="0.75"/>
          <polygon points="340,30 322,72 358,72" fill="#dce8ff" opacity="0.7"/>
          <polygon points="430,60 418,88 442,88" fill="#dce8ff" opacity="0.65"/>
          {/* Water / ice base */}
          <rect x="0" y="175" width="500" height="25" fill="#1a4a6e" opacity="0.5"/>
        </svg>

        {/* Tux */}
        <div className="relative z-10 flex flex-col items-center" style={{ marginBottom: "10%" }}>
          <TuxPenguin sensitiveFieldFocused={sensitiveFieldFocused} />
          <p
            style={{
              fontFamily: "var(--font-display)", fontWeight: 700,
              fontSize: "clamp(18px, 2vw, 24px)", color: "#fff",
              letterSpacing: "-0.03em", lineHeight: 1.2,
              marginTop: 16, textAlign: "center",
              textShadow: "0 2px 16px rgba(0,0,0,0.5)",
            }}
          >
            {sensitiveFieldFocused ? "¡No miro, lo prometo!" : "¡Hola! Soy Lexus🐧"}
          </p>
          <p style={{ fontSize: 13, color: "rgba(255,255,255,0.38)", marginTop: 6, textAlign: "center" }}>
            {sensitiveFieldFocused ? "Estoy mirando hacia otro lado." : "Tu compañero de confianza en Linux."}
          </p>
        </div>

        {/* Dots */}
        <div className="absolute bottom-6 flex gap-2">
          {[0, 1, 2].map(i => (
            <div key={i} style={{ width: i === 0 ? 20 : 6, height: 6, borderRadius: 3, background: i === 0 ? "#f97316" : "rgba(255,255,255,0.2)" }} />
          ))}
        </div>
      </div>
    </div>
  );
}

/* ── Helper components ── */

function ToucanAccent() {
  return (
    <svg viewBox="0 0 270 250" width="100%" role="presentation" style={{ display: "block", filter: "drop-shadow(0 16px 20px rgba(0,0,0,0.28))" }}>
      <defs>
        <linearGradient id="toucanBeak" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stopColor="#ffe16b" />
          <stop offset="65%" stopColor="#ffb522" />
          <stop offset="100%" stopColor="#f97316" />
        </linearGradient>
        <linearGradient id="toucanBody" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stopColor="#46516a" />
          <stop offset="48%" stopColor="#202b3e" />
          <stop offset="100%" stopColor="#080d1b" />
        </linearGradient>
        <linearGradient id="toucanThroat" x1="0" y1="0" x2="0.7" y2="1">
          <stop offset="0%" stopColor="#ffffff" />
          <stop offset="100%" stopColor="#dce9e4" />
        </linearGradient>
        <linearGradient id="toucanBranch" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#b98558" />
          <stop offset="100%" stopColor="#724830" />
        </linearGradient>
      </defs>
      {/* Rama y hojas */}
      <path d="M8 220 C65 220 85 192 135 201 S213 226 267 193" fill="none" stroke="url(#toucanBranch)" strokeWidth="11" strokeLinecap="round" />
      <path d="M12 216 C68 217 87 189 135 197 S211 220 263 191" fill="none" stroke="#d4a279" strokeWidth="2" strokeLinecap="round" opacity="0.72" />
      <path d="M44 211 C40 185 22 176 19 159 M76 202 C72 177 62 168 53 151 M226 211 C240 185 252 180 259 174" fill="none" stroke="#926040" strokeWidth="3" strokeLinecap="round" />
      <path d="M20 161 Q-1 151 7 130 Q28 138 20 161 M20 161 Q34 139 51 144 Q44 159 20 161 M53 152 Q31 136 37 120 Q55 128 53 152 M53 152 Q67 133 82 139 Q76 153 53 152 M259 176 Q239 164 241 149 Q261 154 259 176" fill="#80a83d" stroke="#a8cb5c" strokeWidth="1.5" />
      <path d="M19 159 7 132 M20 160 48 145 M52 150 37 121 M53 151 80 139 M258 174 242 150" fill="none" stroke="#d6e99a" strokeWidth="1" opacity="0.8" />
      {/* Cola y cuerpo */}
      <path d="M181 164 Q213 192 205 232 Q191 225 183 209 Q190 235 178 240 Q160 220 157 183Z" fill="#111b2d" />
      <path d="M165 104 C188 98 217 124 220 159 C224 188 204 210 174 209 C145 210 125 187 129 159 C132 132 145 112 165 104Z" fill="url(#toucanBody)" stroke="#4d5a6d" strokeWidth="2" />
      <path d="M159 119 Q150 145 153 173 Q159 194 181 194 Q201 189 200 169 Q184 171 173 158 Q167 143 172 126Z" fill="url(#toucanThroat)" />
      <path d="M170 127 Q192 132 206 163 Q189 172 170 163 Q158 151 170 127Z" fill="#202a39" />
      <path d="M190 151 Q202 159 205 170 Q190 169 182 160" fill="none" stroke="#4e5c6c" strokeWidth="2" />
      <path d="M176 139 Q191 144 199 158 M176 146 Q189 150 196 161 M175 153 Q187 157 192 165" fill="none" stroke="#718093" strokeWidth="1.5" strokeLinecap="round" opacity="0.65" />
      {/* Cabeza y pico curvo */}
      <path d="M143 64 C158 48 187 52 199 73 C210 92 206 121 189 132 C175 139 155 126 144 113Z" fill="#151d2b" stroke="#556173" strokeWidth="2" />
      <path d="M151 94 C130 80 91 61 41 70 C18 74 11 93 15 110 Q25 94 57 95 C93 94 124 105 151 111 Q167 114 173 101Z" fill="url(#toucanBeak)" stroke="#26303a" strokeWidth="3" strokeLinejoin="round" />
      <path d="M29 83 Q70 64 130 91" fill="none" stroke="#fff1a2" strokeWidth="2.5" strokeLinecap="round" opacity="0.85" />
      <path d="M16 109 Q22 91 44 91 Q36 78 32 76 Q14 86 16 109Z" fill="#26303a" />
      <path d="M43 109 Q94 99 149 113 Q125 128 82 124 Q54 121 43 109Z" fill="#fff9e7" stroke="#26303a" strokeWidth="2" />
      <path d="M77 122 Q115 129 149 113" fill="none" stroke="#f7b731" strokeWidth="4" strokeLinecap="round" />
      <ellipse cx="176" cy="88" rx="17" ry="21" fill="#f8faf5" />
      <circle cx="178" cy="89" r="9" fill="#efad2e" /><circle cx="179" cy="89" r="5" fill="#101723" /><circle cx="176" cy="86" r="2" fill="white" /><circle cx="181" cy="92" r="1" fill="white" opacity="0.55" />
      {/* Patas sobre la rama */}
      <path d="M156 197 L154 208 M179 199 L180 209 M150 207 Q159 213 167 207 M176 209 Q184 214 192 208" fill="none" stroke="#ee974c" strokeWidth="5" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function Field({ label, type, placeholder, autoComplete, required, onFocus, onBlur }: { label: string; type: string; placeholder: string; autoComplete?: string; required?: boolean; onFocus?: () => void; onBlur?: () => void }) {
  return (
    <div className="flex flex-col gap-1.5">
      <label style={{ fontSize: 13, fontWeight: 500, color: "rgba(255,255,255,0.5)", letterSpacing: "0.01em" }}>{label}</label>
      <input
        type={type} placeholder={placeholder} autoComplete={autoComplete} required={required}
        style={{ padding: "14px 16px", background: "rgba(255,255,255,0.06)", border: "1px solid rgba(255,255,255,0.10)", borderRadius: 12, color: "rgba(255,255,255,0.9)", fontSize: 14, outline: "none", fontFamily: "var(--font-body)", transition: "border-color 0.15s" }}
        onFocus={(e) => { e.currentTarget.style.borderColor = "rgba(249,115,22,0.55)"; onFocus?.(); }}
        onBlur={(e) => { e.currentTarget.style.borderColor = "rgba(255,255,255,0.10)"; onBlur?.(); }}
      />
    </div>
  );
}

function RoleIcon({ role }: { role: RegistrationRole }) {
  return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      {role === "alumno" ? (
        <><path d="m2 9 10-5 10 5-10 5L2 9Z"/><path d="M6 11v5c3 3 9 3 12 0v-5"/><path d="M22 9v6"/></>
      ) : role === "instructor" ? (
        <><rect x="3" y="3" width="18" height="12" rx="1"/><path d="M12 15v5m-4 1 4-4 4 4"/></>
      ) : (
        <><circle cx="9" cy="8" r="3"/><path d="M2 20v-2a7 7 0 0 1 14 0v2M17 5a3 3 0 0 1 0 6m2 4a6 6 0 0 1 3 5"/></>
      )}
    </svg>
  );
}

function InstitutionField() {
  return (
    <div className="flex flex-col gap-1.5">
      <label htmlFor="registro-institucion" style={{ fontSize: 13, fontWeight: 500, color: "rgba(255,255,255,0.5)" }}>
        Procedencia / Institución *
      </label>
      <select
        id="registro-institucion" defaultValue="" required
        style={{ width: "100%", padding: "14px 16px", background: "#222033", border: "1px solid rgba(255,255,255,0.10)", borderRadius: 12, color: "rgba(255,255,255,0.9)", fontSize: 14, outline: "none", fontFamily: "var(--font-body)", transition: "border-color 0.15s" }}
        onFocus={(e) => (e.currentTarget.style.borderColor = "rgba(249,115,22,0.55)")}
        onBlur={(e) => (e.currentTarget.style.borderColor = "rgba(255,255,255,0.10)")}
      >
        <option value="" disabled>Selecciona una opción</option>
        <option value="itc">Instituto Tecnológico de Cancún</option>
        <option value="otra">Otra institución</option>
      </select>
    </div>
  );
}

function ExternalExperienceField() {
  const [experience, setExperience] = useState<"sector" | "propia" | "">("");

  return (
    <div className="flex flex-col gap-4">
      <fieldset className="flex flex-col gap-2" style={{ border: 0, padding: 0, margin: 0, minWidth: 0 }}>
        <legend style={{ fontSize: 13, fontWeight: 500, color: "rgba(255,255,255,0.5)", marginBottom: 8 }}>
          Tipo de experiencia *
        </legend>
        {([
          { value: "sector", label: "Trabajo en el sector" },
          { value: "propia", label: "Experiencia propia" },
        ] as const).map((option) => (
          <label key={option.value} className="flex items-center gap-3 cursor-pointer" style={{ padding: "14px 16px", borderRadius: 12, border: experience === option.value ? "1px solid rgba(249,115,22,0.65)" : "1px solid rgba(255,255,255,0.10)", background: experience === option.value ? "rgba(249,115,22,0.12)" : "rgba(255,255,255,0.06)", color: "rgba(255,255,255,0.86)", fontSize: 14, transition: "border-color 0.2s ease, background 0.2s ease" }}>
            <input type="radio" name="experiencia-externo" value={option.value} checked={experience === option.value} onChange={() => setExperience(option.value)} required style={{ accentColor: "#f97316", width: 17, height: 17, flexShrink: 0 }} />
            {option.label}
          </label>
        ))}
      </fieldset>
      {experience === "sector" && (
        <Field label="Organización / procedencia *" type="text" placeholder="Escribe tu organización o procedencia" required />
      )}
    </div>
  );
}

function AcademicDegreeField() {
  const [degree, setDegree] = useState("");

  return (
    <div className="flex flex-col gap-4">
      <div className="flex flex-col gap-1.5">
        <label htmlFor="grado-academico" style={{ fontSize: 13, fontWeight: 500, color: "rgba(255,255,255,0.5)" }}>
          Grado académico / Título *
        </label>
        <select
          id="grado-academico"
          value={degree}
          onChange={(e) => setDegree(e.target.value)}
          required
          style={{ width: "100%", padding: "14px 16px", background: "#222033", border: "1px solid rgba(255,255,255,0.10)", borderRadius: 12, color: "rgba(255,255,255,0.9)", fontSize: 14, outline: "none", fontFamily: "var(--font-body)", transition: "border-color 0.15s" }}
          onFocus={(e) => (e.currentTarget.style.borderColor = "rgba(249,115,22,0.55)")}
          onBlur={(e) => (e.currentTarget.style.borderColor = "rgba(255,255,255,0.10)")}
        >
          <option value="" disabled>Selecciona una opción</option>
          <option value="mtro">Mtro.</option>
          <option value="dr">Dr.</option>
          <option value="ing">Ing.</option>
          <option value="lic">Lic.</option>
          <option value="otro">Otro (escribe cuál)</option>
        </select>
      </div>
      {degree === "otro" && (
        <Field label="Especifica tu grado o título *" type="text" placeholder="Escribe tu grado o título" required />
      )}
    </div>
  );
}

function SocialButton({ label }: { label: string }) {
  return (
    <button
      type="submit"
      style={{ width: "100%", display: "flex", alignItems: "center", justifyContent: "center", gap: 10, padding: "15px 16px", borderRadius: 12, border: "none", background: "linear-gradient(135deg, #f97316 0%, #ea580c 100%)", boxShadow: "0 4px 28px rgba(249,115,22,0.35), 0 1px 0 rgba(255,255,255,0.18) inset", cursor: "pointer", color: "#fff", fontSize: 15, fontFamily: "var(--font-display)", fontWeight: 700, transition: "transform 0.2s ease, box-shadow 0.2s ease" }}
      onMouseEnter={(e) => { e.currentTarget.style.transform = "translateY(-2px)"; e.currentTarget.style.boxShadow = "0 8px 36px rgba(249,115,22,0.48), 0 1px 0 rgba(255,255,255,0.18) inset"; }}
      onMouseLeave={(e) => { e.currentTarget.style.transform = "translateY(0)"; e.currentTarget.style.boxShadow = "0 4px 28px rgba(249,115,22,0.35), 0 1px 0 rgba(255,255,255,0.18) inset"; }}
    >
      <svg width="16" height="16" viewBox="0 0 24 24">
        <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/>
        <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
        <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/>
        <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/>
      </svg>
      {label}
    </button>
  );
}

const STARS = Array.from({ length: 80 }, (_, i) => ({
  x: (i * 137.508) % 100,
  y: (i * 97.3) % 60,
  r: i % 5 === 0 ? 2.5 : i % 3 === 0 ? 1.5 : 1,
  o: 0.2 + (i % 7) * 0.1,
}));
