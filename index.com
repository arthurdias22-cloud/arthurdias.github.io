<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>SONIC: VELOCIDADE MODERNA</title>
    <!-- Carregamento do Tailwind CSS para estilização responsiva da interface -->
    <script src="https://cdn.tailwindcss.com"></script>
    <!-- Fontes modernas de estilo arcade / velocidade -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Exo+2:ital,wght@0,600;0,800;0,900;1,800;1,900&family=Orbitron:wght@700;900&display=swap" rel="stylesheet">
    <style>
        /* Estilos globais e prevenção de seleção/rolagem em dispositivos móveis */
        * {
            box-sizing: border-box;
            user-select: none;
            -webkit-user-select: none;
            -webkit-touch-callout: none;
        }

        html, body {
            margin: 0;
            padding: 0;
            width: 100%;
            height: 100%;
            overflow: hidden;
            background-color: #041538;
            font-family: 'Exo 2', sans-serif;
            touch-action: none;
        }

        canvas {
            display: block;
            width: 100%;
            height: 100%;
        }

        .font-orbitron {
            font-family: 'Orbitron', sans-serif;
        }

        /* Estilo de texto metálico e vibrante estilo Sonic Moderno */
        .sonic-title-text {
            background: linear-gradient(180deg, #ffffff 0%, #93e4ff 45%, #0088ff 85%, #0044cc 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            filter: drop-shadow(0 4px 0 #051b4d) drop-shadow(0 8px 20px rgba(0, 174, 255, 0.7));
        }

        .sonic-subtitle-badge {
            background: linear-gradient(90deg, #ff1e27 0%, #ff5e00 50%, #ffcc00 100%);
            box-shadow: 0 4px 15px rgba(255, 60, 0, 0.6), inset 0 1px 1px rgba(255, 255, 255, 0.6);
        }

        /* Painéis de vidro translúcido */
        .glass-hud {
            background: linear-gradient(135deg, rgba(6, 24, 68, 0.78) 0%, rgba(10, 42, 110, 0.65) 100%);
            backdrop-filter: blur(8px);
            -webkit-backdrop-filter: blur(8px);
            border: 1.5px solid rgba(86, 204, 255, 0.45);
            box-shadow: 0 6px 20px rgba(0, 10, 35, 0.45);
        }

        /* Botão principal estilizado */
        .btn-sonic {
            background: linear-gradient(180deg, #00d2ff 0%, #0066ff 55%, #003cb3 100%);
            border: 2px solid #99ebff;
            box-shadow: 0 6px 0 #002366, 0 12px 28px rgba(0, 162, 255, 0.65), inset 0 2px 4px rgba(255, 255, 255, 0.7);
            transition: transform 0.1s ease, filter 0.15s ease;
        }

        .btn-sonic:hover {
            filter: brightness(1.12);
            transform: translateY(-2px);
        }

        .btn-sonic:active {
            transform: translateY(4px);
            box-shadow: 0 2px 0 #002366, 0 6px 14px rgba(0, 162, 255, 0.5);
        }

        /* Botões táteis na tela */
        .touch-btn {
            backdrop-filter: blur(6px);
            -webkit-backdrop-filter: blur(6px);
            transition: transform 0.08s ease, background-color 0.1s ease, box-shadow 0.1s ease;
        }

        .touch-btn:active, .touch-btn.active-press {
            transform: scale(0.92);
        }

        /* Animação pulsante para alerta de 0 anéis */
        @keyframes pulseDanger {
            0%, 100% { color: #ff3b3b; transform: scale(1); }
            50% { color: #ffffff; transform: scale(1.12); }
        }

        .rings-danger {
            animation: pulseDanger 0.65s infinite;
        }

        /* Brilho da barra de Boost */
        @keyframes boostShimmer {
            0% { background-position: 0% 50%; }
            100% { background-position: 200% 50%; }
        }

        .boost-bar-fill {
            background: linear-gradient(90deg, #0088ff, #00f2ff, #ffffff, #00f2ff, #0088ff);
            background-size: 200% 100%;
            animation: boostShimmer 1.4s linear infinite;
        }
    </style>
</head>
<body class="relative w-screen h-screen overflow-hidden select-none">

    <!-- Canvas Principal do Jogo -->
    <canvas id="gameCanvas"></canvas>

    <!-- HUD Superior (Exibido durante a partida) -->
    <div id="hudOverlay" class="hidden pointer-events-none fixed inset-x-0 top-0 z-20 p-3 sm:p-5 flex flex-col gap-2">
        <div class="flex items-start justify-between gap-2">
            <!-- Esquerda: Anéis, Pontos e Recorde -->
            <div class="flex flex-wrap items-center gap-2 sm:gap-3">
                <!-- Contador de Anéis -->
                <div class="glass-hud rounded-2xl px-3.5 py-2 sm:px-4 sm:py-2.5 flex items-center gap-2.5">
                    <div class="w-7 h-7 sm:w-8 sm:h-8 rounded-full border-4 border-amber-300 bg-amber-500/20 shadow-[0_0_12px_rgba(251,191,36,0.9)] flex items-center justify-center">
                        <div class="w-2.5 h-2.5 rounded-full bg-yellow-200/70"></div>
                    </div>
                    <div>
                        <div class="text-[10px] sm:text-xs font-extrabold tracking-wider text-cyan-200 uppercase leading-none">ANÉIS</div>
                        <div id="hudRings" class="font-orbitron text-xl sm:text-2xl font-black text-amber-300 leading-tight drop-shadow">0</div>
                    </div>
                </div>

                <!-- Pontuação -->
                <div class="glass-hud rounded-2xl px-3.5 py-2 sm:px-4 sm:py-2.5">
                    <div class="text-[10px] sm:text-xs font-extrabold tracking-wider text-cyan-200 uppercase leading-none">PONTOS</div>
                    <div id="hudScore" class="font-orbitron text-lg sm:text-2xl font-black text-white leading-tight">000000</div>
                </div>

                <!-- Recorde (Oculto em telas muito pequenas, visível a partir de sm) -->
                <div class="hidden sm:block glass-hud rounded-2xl px-4 py-2.5">
                    <div class="text-xs font-extrabold tracking-wider text-amber-200 uppercase leading-none">RECORDE</div>
                    <div id="hudHighScore" class="font-orbitron text-xl sm:text-2xl font-black text-amber-300 leading-tight">000000</div>
                </div>
            </div>

            <!-- Direita: Velocímetro e Botão de Áudio -->
            <div class="flex items-center gap-2 sm:gap-3">
                <div class="glass-hud rounded-2xl px-3.5 py-2 sm:px-4 sm:py-2.5 text-right">
                    <div class="text-[10px] sm:text-xs font-extrabold tracking-wider text-cyan-200 uppercase leading-none">VELOCIDADE</div>
                    <div class="flex items-baseline justify-end gap-1">
                        <span id="hudSpeed" class="font-orbitron text-lg sm:text-2xl font-black text-cyan-300 leading-tight">0</span>
                        <span class="text-[10px] sm:text-xs font-bold text-cyan-100">km/h</span>
                    </div>
                </div>

                <button id="muteBtn" type="button" aria-label="Alternar Som" class="pointer-events-auto glass-hud hover:bg-blue-900/80 active:scale-95 rounded-2xl p-2.5 sm:p-3 text-white transition">
                    <svg id="iconSoundOn" class="w-6 h-6 text-cyan-300" fill="none" stroke="currentColor" stroke-width="2.2" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M11 5L6 9H2v6h4l5 4V5zM15.54 8.46a5 5 0 010 7.07M19.07 4.93a10 10 0 010 14.14"/>
                    </svg>
                    <svg id="iconSoundOff" class="hidden w-6 h-6 text-rose-400" fill="none" stroke="currentColor" stroke-width="2.2" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M11 5L6 9H2v6h4l5 4V5zM23 9l-6 6M17 9l6 6"/>
                    </svg>
                </button>
            </div>
        </div>

        <!-- Barra de Energia BOOST -->
        <div class="self-center w-full max-w-md glass-hud rounded-full px-3 py-1.5 sm:px-4 sm:py-2 flex items-center gap-3">
            <div class="flex items-center gap-1.5 shrink-0">
                <svg class="w-4 h-4 sm:w-5 sm:h-5 text-cyan-300 animate-pulse" fill="currentColor" viewBox="0 0 20 20">
                    <path fill-rule="evenodd" d="M11.3 1.046A1 1 0 0112 2v5h4a1 1 0 01.82 1.573l-7 10A1 1 0 018 18v-5H4a1 1 0 01-.82-1.573l7-10a1 1 0 011.12-.38z" clip-rule="evenodd"/>
                </svg>
                <span class="font-orbitron text-xs sm:text-sm font-black tracking-wider text-cyan-200 italic">BOOST</span>
            </div>
            <div class="relative flex-1 h-3.5 sm:h-4 bg-slate-950/80 rounded-full overflow-hidden border border-cyan-400/40 p-0.5">
                <div id="hudBoostFill" class="boost-bar-fill h-full rounded-full transition-all duration-75" style="width: 65%;"></div>
            </div>
            <span id="hudBoostPct" class="font-orbitron text-xs font-bold text-white w-9 text-right">65%</span>
        </div>
    </div>

    <!-- Controles Táteis / Na Tela (Cantos Inferiores) -->
    <div id="touchControls" class="hidden pointer-events-none fixed inset-x-0 bottom-0 z-20 p-3 sm:p-6 flex items-end justify-between">
        <!-- Canto Inferior Esquerdo: DESLIZAR -->
        <button id="btnTouchSlide" type="button" class="touch-btn pointer-events-auto rounded-2xl sm:rounded-3xl px-4 py-3.5 sm:px-6 sm:py-4 bg-amber-500/30 border-2 border-amber-300/80 text-white shadow-[0_6px_20px_rgba(245,158,11,0.4)] flex flex-col items-center justify-center min-w-[96px] sm:min-w-[116px]">
            <svg class="w-6 h-6 sm:w-7 sm:h-7 text-amber-300 mb-0.5" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M19 13l-7 7-7-7m14-8l-7 7-7-7"/>
            </svg>
            <span class="font-orbitron text-xs sm:text-sm font-black tracking-wider">DESLIZAR</span>
        </button>

        <!-- Canto Inferior Direito: BOOST + PULAR -->
        <div class="flex items-end gap-2.5 sm:gap-4">
            <button id="btnTouchBoost" type="button" class="touch-btn pointer-events-auto rounded-2xl sm:rounded-3xl px-4 py-3.5 sm:px-6 sm:py-4 bg-cyan-500/35 border-2 border-cyan-300/90 text-white shadow-[0_6px_22px_rgba(6,182,212,0.5)] flex flex-col items-center justify-center min-w-[92px] sm:min-w-[114px]">
                <svg class="w-6 h-6 sm:w-7 sm:h-7 text-cyan-300 mb-0.5" fill="currentColor" viewBox="0 0 20 20">
                    <path fill-rule="evenodd" d="M11.3 1.046A1 1 0 0112 2v5h4a1 1 0 01.82 1.573l-7 10A1 1 0 018 18v-5H4a1 1 0 01-.82-1.573l7-10a1 1 0 011.12-.38z" clip-rule="evenodd"/>
                </svg>
                <span class="font-orbitron text-xs sm:text-sm font-black tracking-wider">BOOST</span>
            </button>

            <button id="btnTouchJump" type="button" class="touch-btn pointer-events-auto rounded-2xl sm:rounded-3xl px-5 py-4 sm:px-7 sm:py-5 bg-blue-600/45 border-2 border-sky-300/95 text-white shadow-[0_6px_24px_rgba(37,99,235,0.6)] flex flex-col items-center justify-center min-w-[100px] sm:min-w-[124px]">
                <svg class="w-7 h-7 sm:w-8 sm:h-8 text-sky-200 mb-0.5" fill="none" stroke="currentColor" stroke-width="2.6" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M5 15l7-7 7 7"/>
                </svg>
                <span class="font-orbitron text-xs sm:text-sm font-black tracking-wider">PULAR</span>
            </button>
        </div>
    </div>

    <!-- Tela Inicial (Title Screen) -->
    <div id="startScreen" class="fixed inset-0 z-30 flex items-center justify-center p-4 bg-gradient-to-b from-blue-950/65 via-sky-900/55 to-blue-950/80 backdrop-blur-[3px]">
        <div class="w-full max-w-2xl glass-hud rounded-3xl p-6 sm:p-8 text-center border-2 border-cyan-300/60 shadow-[0_20px_60px_rgba(0,15,50,0.85)] relative overflow-hidden">
            <!-- Detalhe decorativo superior -->
            <div class="inline-block sonic-subtitle-badge text-white font-orbitron text-xs sm:text-sm font-black tracking-widest uppercase px-4 py-1 rounded-full mb-3 transform -skew-x-12">
                AÇÃO EM ALTA VELOCIDADE
            </div>

            <!-- Título Principal -->
            <h1 class="font-orbitron text-4xl sm:text-6xl font-black italic tracking-tight sonic-title-text leading-none mb-2">
                SONIC
            </h1>
            <h2 class="font-orbitron text-xl sm:text-3xl font-black italic tracking-wider text-amber-300 drop-shadow-[0_3px_0_#78350f] mb-6">
                VELOCIDADE MODERNA
            </h2>

            <!-- Painel de Comandos -->
            <div class="bg-slate-950/65 border border-cyan-400/35 rounded-2xl p-4 sm:p-5 mb-6 text-left grid grid-cols-1 sm:grid-cols-3 gap-3">
                <div class="bg-blue-950/60 border border-sky-400/30 rounded-xl p-3 flex flex-col justify-between">
                    <span class="inline-block self-start bg-sky-500/30 border border-sky-300/60 text-sky-200 font-orbitron text-[11px] font-bold px-2.5 py-0.5 rounded-md mb-1.5">
                        ESPAÇO / ↑
                    </span>
                    <div class="text-white font-extrabold text-sm leading-snug">Pular &amp; Ataque Teleguiado</div>
                    <div class="text-cyan-200/80 text-xs mt-1">Aperte no ar para travar mira nos Badniks!</div>
                </div>

                <div class="bg-blue-950/60 border border-cyan-400/30 rounded-xl p-3 flex flex-col justify-between">
                    <span class="inline-block self-start bg-cyan-500/30 border border-cyan-300/60 text-cyan-200 font-orbitron text-[11px] font-bold px-2.5 py-0.5 rounded-md mb-1.5">
                        SHIFT / X
                    </span>
                    <div class="text-white font-extrabold text-sm leading-snug">Boost (Impulso)</div>
                    <div class="text-cyan-200/80 text-xs mt-1">Atravessa inimigos e atrai anéis próximos!</div>
                </div>

                <div class="bg-blue-950/60 border border-amber-400/30 rounded-xl p-3 flex flex-col justify-between">
                    <span class="inline-block self-start bg-amber-500/30 border border-amber-300/60 text-amber-200 font-orbitron text-[11px] font-bold px-2.5 py-0.5 rounded-md mb-1.5">
                        ↓ / S
                    </span>
                    <div class="text-white font-extrabold text-sm leading-snug">Deslizar / Rolar</div>
                    <div class="text-cyan-200/80 text-xs mt-1">Passe sob lasers e quebre barreiras baixas!</div>
                </div>
            </div>

            <!-- Recorde Atual na Tela Inicial -->
            <div class="mb-6 flex items-center justify-center gap-2 text-amber-300 font-bold text-sm sm:text-base">
                <span>RECORDE ATUAL:</span>
                <span id="startHighScore" class="font-orbitron font-black text-lg sm:text-xl">000000</span>
            </div>

            <!-- Botão JOGAR -->
            <button id="btnStartGame" type="button" class="btn-sonic w-full sm:w-auto px-12 py-4 rounded-2xl font-orbitron text-xl sm:text-2xl font-black italic tracking-wider text-white uppercase cursor-pointer">
                JOGAR
            </button>
        </div>
    </div>

    <!-- Tela de Resultados / Game Over -->
    <div id="gameOverScreen" class="hidden fixed inset-0 z-30 flex items-center justify-center p-4 bg-slate-950/80 backdrop-blur-md">
        <div class="w-full max-w-xl glass-hud rounded-3xl p-6 sm:p-8 text-center border-2 border-cyan-300/60 shadow-[0_20px_60px_rgba(0,0,0,0.9)]">
            <div class="text-rose-400 font-orbitron text-sm sm:text-base font-black tracking-widest uppercase mb-1">
                FIM DE JOGO
            </div>
            <h2 class="font-orbitron text-2xl sm:text-4xl font-black italic text-white mb-5">
                RESULTADOS DA CORRIDA
            </h2>

            <!-- Classificação Estilo Sonic (Rank S, A, B, C) -->
            <div class="flex items-center justify-center gap-4 mb-6 bg-slate-950/70 border border-cyan-400/30 rounded-2xl py-4 px-5">
                <div class="text-left">
                    <div class="text-xs font-extrabold uppercase tracking-wider text-cyan-200">CLASSIFICAÇÃO</div>
                    <div id="rankLabel" class="text-sm sm:text-base font-bold text-white">VELOCIDADE SÔNICA!</div>
                </div>
                <div id="rankBadge" class="font-orbitron text-5xl sm:text-6xl font-black italic text-amber-300 drop-shadow-[0_0_18px_rgba(251,191,36,0.9)]">
                    S
                </div>
            </div>

            <!-- Estatísticas -->
            <div class="grid grid-cols-2 gap-3 mb-6 text-left">
                <div class="bg-blue-950/65 border border-cyan-400/25 rounded-xl p-3">
                    <div class="text-[11px] font-bold text-cyan-200 uppercase">PONTUAÇÃO FINAL</div>
                    <div id="finalScore" class="font-orbitron text-xl sm:text-2xl font-black text-white">0</div>
                </div>
                <div class="bg-blue-950/65 border border-amber-400/30 rounded-xl p-3">
                    <div class="text-[11px] font-bold text-amber-200 uppercase">RECORDE</div>
                    <div id="finalHighScore" class="font-orbitron text-xl sm:text-2xl font-black text-amber-300">0</div>
                </div>
                <div class="bg-blue-950/65 border border-cyan-400/25 rounded-xl p-3">
                    <div class="text-[11px] font-bold text-cyan-200 uppercase">DISTÂNCIA</div>
                    <div id="finalDistance" class="font-orbitron text-lg sm:text-xl font-black text-sky-300">0 m</div>
                </div>
                <div class="bg-blue-950/65 border border-cyan-400/25 rounded-xl p-3">
                    <div class="text-[11px] font-bold text-cyan-200 uppercase">VELOCIDADE MÁXIMA</div>
                    <div id="finalMaxSpeed" class="font-orbitron text-lg sm:text-xl font-black text-cyan-300">0 km/h</div>
                </div>
                <div class="bg-blue-950/65 border border-cyan-400/25 rounded-xl p-3">
                    <div class="text-[11px] font-bold text-cyan-200 uppercase">BADNIKS DESTRUÍDOS</div>
                    <div id="finalBadniks" class="font-orbitron text-lg sm:text-xl font-black text-emerald-300">0</div>
                </div>
                <div class="bg-blue-950/65 border border-cyan-400/25 rounded-xl p-3">
                    <div class="text-[11px] font-bold text-cyan-200 uppercase">ANÉIS COLETADOS</div>
                    <div id="finalRings" class="font-orbitron text-lg sm:text-xl font-black text-amber-300">0</div>
                </div>
            </div>

            <!-- Botão Jogar Novamente -->
            <button id="btnRestartGame" type="button" class="btn-sonic w-full sm:w-auto px-10 py-4 rounded-2xl font-orbitron text-lg sm:text-xl font-black italic tracking-wider text-white uppercase cursor-pointer">
                JOGAR NOVAMENTE
            </button>
        </div>
    </div>

    <script>
        /**
         * ============================================================================
         * SONIC: VELOCIDADE MODERNA
         * Jogo de Ação/Plataforma em Alta Velocidade em HTML5 Canvas + Web Audio API
         * ============================================================================
         */

        // ----------------------------------------------------------------------------
        // 1. SISTEMA DE ÁUDIO SINTETIZADO (WEB AUDIO API)
        // ----------------------------------------------------------------------------
        class SoundEngine {
            constructor() {
                this.ctx = null;
                this.muted = false;
                this.ringPanToggle = 1;
                this.lastGrindSoundTime = 0;
            }

            // Inicializa o contexto de áudio após a primeira interação do usuário
            init() {
                if (!this.ctx) {
                    const AudioCtx = window.AudioContext || window.webkitAudioContext;
                    if (AudioCtx) {
                        this.ctx = new AudioCtx();
                    }
                }
                if (this.ctx && this.ctx.state === 'suspended') {
                    this.ctx.resume().catch(() => {});
                }
            }

            toggleMute() {
                this.muted = !this.muted;
                return this.muted;
            }

            // Som clássico de coleta de anel (duas notas agudas cristalinas alternando estéreo)
            playRing() {
                if (this.muted || !this.ctx) return;
                const now = this.ctx.currentTime;

                const osc = this.ctx.createOscillator();
                const gain = this.ctx.createGain();
                osc.type = 'sine';

                // Notas B5 (987.77 Hz) -> E6 (1318.51 Hz)
                osc.frequency.setValueAtTime(987.77, now);
                osc.frequency.setValueAtTime(1318.51, now + 0.065);

                gain.gain.setValueAtTime(0.16, now);
                gain.gain.exponentialRampToValueAtTime(0.001, now + 0.34);

                if (this.ctx.createStereoPanner) {
                    const panner = this.ctx.createStereoPanner();
                    panner.pan.setValueAtTime(this.ringPanToggle * 0.45, now);
                    this.ringPanToggle *= -1;
                    osc.connect(gain);
                    gain.connect(panner);
                    panner.connect(this.ctx.destination);
                } else {
                    osc.connect(gain);
                    gain.connect(this.ctx.destination);
                }

                osc.start(now);
                osc.stop(now + 0.35);
            }

            // Som de Pulo
            playJump() {
                if (this.muted || !this.ctx) return;
                const now = this.ctx.currentTime;
                const osc = this.ctx.createOscillator();
                const gain = this.ctx.createGain();

                osc.type = 'triangle';
                osc.frequency.setValueAtTime(240, now);
                osc.frequency.exponentialRampToValueAtTime(680, now + 0.18);

                gain.gain.setValueAtTime(0.18, now);
                gain.gain.exponentialRampToValueAtTime(0.001, now + 0.2);

                osc.connect(gain);
                gain.connect(this.ctx.destination);
                osc.start(now);
                osc.stop(now + 0.21);
            }

            // Som de trava de mira do Ataque Teleguiado
            playLockOn() {
                if (this.muted || !this.ctx) return;
                const now = this.ctx.currentTime;
                const osc = this.ctx.createOscillator();
                const gain = this.ctx.createGain();

                osc.type = 'sine';
                osc.frequency.setValueAtTime(920, now);
                osc.frequency.setValueAtTime(1480, now + 0.035);

                gain.gain.setValueAtTime(0.11, now);
                gain.gain.exponentialRampToValueAtTime(0.001, now + 0.09);

                osc.connect(gain);
                gain.connect(this.ctx.destination);
                osc.start(now);
                osc.stop(now + 0.1);
            }

            // Som de disparo do Ataque Teleguiado
            playHomingDash() {
                if (this.muted || !this.ctx) return;
                const now = this.ctx.currentTime;
                const osc = this.ctx.createOscillator();
                const gain = this.ctx.createGain();

                osc.type = 'sawtooth';
                osc.frequency.setValueAtTime(750, now);
                osc.frequency.exponentialRampToValueAtTime(220, now + 0.18);

                gain.gain.setValueAtTime(0.16, now);
                gain.gain.exponentialRampToValueAtTime(0.001, now + 0.19);

                osc.connect(gain);
                gain.connect(this.ctx.destination);
                osc.start(now);
                osc.stop(now + 0.2);
            }

            // Impacto / Destruição de Badnik
            playBadnikSmash() {
                if (this.muted || !this.ctx) return;
                const now = this.ctx.currentTime;

                // Grave de impacto
                const osc = this.ctx.createOscillator();
                const gain = this.ctx.createGain();
                osc.type = 'square';
                osc.frequency.setValueAtTime(190, now);
                osc.frequency.exponentialRampToValueAtTime(48, now + 0.22);

                gain.gain.setValueAtTime(0.22, now);
                gain.gain.exponentialRampToValueAtTime(0.001, now + 0.24);

                osc.connect(gain);
                gain.connect(this.ctx.destination);
                osc.start(now);
                osc.stop(now + 0.25);

                // Estalo metálico
                const pop = this.ctx.createOscillator();
                const popGain = this.ctx.createGain();
                pop.type = 'triangle';
                pop.frequency.setValueAtTime(520, now);
                pop.frequency.exponentialRampToValueAtTime(1100, now + 0.1);
                popGain.gain.setValueAtTime(0.14, now);
                popGain.gain.exponentialRampToValueAtTime(0.001, now + 0.11);
                pop.connect(popGain);
                popGain.connect(this.ctx.destination);
                pop.start(now);
                pop.stop(now + 0.12);
            }

            // Explosão sônica ao ativar o Boost
            playBoostBoom() {
                if (this.muted || !this.ctx) return;
                const now = this.ctx.currentTime;

                // Sub-bass boom
                const osc = this.ctx.createOscillator();
                const gain = this.ctx.createGain();
                osc.type = 'sine';
                osc.frequency.setValueAtTime(150, now);
                osc.frequency.exponentialRampToValueAtTime(36, now + 0.35);

                gain.gain.setValueAtTime(0.3, now);
                gain.gain.exponentialRampToValueAtTime(0.001, now + 0.36);

                osc.connect(gain);
                gain.connect(this.ctx.destination);
                osc.start(now);
                osc.stop(now + 0.37);

                // Turbina aguda
                const turbine = this.ctx.createOscillator();
                const tGain = this.ctx.createGain();
                turbine.type = 'sawtooth';
                turbine.frequency.setValueAtTime(280, now);
                turbine.frequency.exponentialRampToValueAtTime(840, now + 0.25);
                tGain.gain.setValueAtTime(0.1, now);
                tGain.gain.exponentialRampToValueAtTime(0.001, now + 0.26);
                turbine.connect(tGain);
                tGain.connect(this.ctx.destination);
                turbine.start(now);
                turbine.stop(now + 0.27);
            }

            // Mola Vermelha (Spring)
            playSpring() {
                if (this.muted || !this.ctx) return;
                const now = this.ctx.currentTime;
                const osc = this.ctx.createOscillator();
                const gain = this.ctx.createGain();

                osc.type = 'triangle';
                osc.frequency.setValueAtTime(220, now);
                osc.frequency.exponentialRampToValueAtTime(980, now + 0.28);

                gain.gain.setValueAtTime(0.22, now);
                gain.gain.exponentialRampToValueAtTime(0.001, now + 0.3);

                osc.connect(gain);
                gain.connect(this.ctx.destination);
                osc.start(now);
                osc.stop(now + 0.31);
            }

            // Painel de Impulso (Dash Pad)
            playDashPad() {
                if (this.muted || !this.ctx) return;
                const now = this.ctx.currentTime;
                const notes = [440, 587.33, 880, 1174.66];
                notes.forEach((freq, idx) => {
                    const osc = this.ctx.createOscillator();
                    const gain = this.ctx.createGain();
                    osc.type = 'sawtooth';
                    osc.frequency.setValueAtTime(freq, now + idx * 0.035);
                    gain.gain.setValueAtTime(0.11, now + idx * 0.035);
                    gain.gain.exponentialRampToValueAtTime(0.001, now + idx * 0.035 + 0.12);
                    osc.connect(gain);
                    gain.connect(this.ctx.destination);
                    osc.start(now + idx * 0.035);
                    osc.stop(now + idx * 0.035 + 0.13);
                });
            }

            // Deslizar (Slide)
            playSlide() {
                if (this.muted || !this.ctx) return;
                const now = this.ctx.currentTime;
                const osc = this.ctx.createOscillator();
                const gain = this.ctx.createGain();

                osc.type = 'sine';
                osc.frequency.setValueAtTime(480, now);
                osc.frequency.exponentialRampToValueAtTime(160, now + 0.16);

                gain.gain.setValueAtTime(0.14, now);
                gain.gain.exponentialRampToValueAtTime(0.001, now + 0.17);

                osc.connect(gain);
                gain.connect(this.ctx.destination);
                osc.start(now);
                osc.stop(now + 0.18);
            }

            // Faíscas metálicas ao deslizar no trilho (Grind Rail)
            playGrindSpark() {
                if (this.muted || !this.ctx) return;
                const now = this.ctx.currentTime;
                if (now - this.lastGrindSoundTime < 0.07) return;
                this.lastGrindSoundTime = now;

                const osc = this.ctx.createOscillator();
                const gain = this.ctx.createGain();
                osc.type = 'square';
                osc.frequency.setValueAtTime(1400 + Math.random() * 900, now);
                gain.gain.setValueAtTime(0.035, now);
                gain.gain.exponentialRampToValueAtTime(0.001, now + 0.05);

                osc.connect(gain);
                gain.connect(this.ctx.destination);
                osc.start(now);
                osc.stop(now + 0.055);
            }

            // Dano e espalhamento clássico de anéis
            playRingScatter() {
                if (this.muted || !this.ctx) return;
                const now = this.ctx.currentTime;
                for (let i = 0; i < 7; i++) {
                    const osc = this.ctx.createOscillator();
                    const gain = this.ctx.createGain();
                    osc.type = 'sine';
                    const start = now + i * 0.04;
                    osc.frequency.setValueAtTime(1100 + (i % 3) * 260, start);
                    osc.frequency.exponentialRampToValueAtTime(750, start + 0.14);

                    gain.gain.setValueAtTime(0.15, start);
                    gain.gain.exponentialRampToValueAtTime(0.001, start + 0.15);

                    osc.connect(gain);
                    gain.connect(this.ctx.destination);
                    osc.start(start);
                    osc.stop(start + 0.16);
                }
            }

            // Game Over
            playGameOver() {
                if (this.muted || !this.ctx) return;
                const now = this.ctx.currentTime;
                const notes = [440, 392, 349.23, 293.66, 220];
                notes.forEach((freq, i) => {
                    const osc = this.ctx.createOscillator();
                    const gain = this.ctx.createGain();
                    osc.type = 'triangle';
                    const start = now + i * 0.13;
                    osc.frequency.setValueAtTime(freq, start);
                    gain.gain.setValueAtTime(0.18, start);
                    gain.gain.exponentialRampToValueAtTime(0.001, start + 0.25);
                    osc.connect(gain);
                    gain.connect(this.ctx.destination);
                    osc.start(start);
                    osc.stop(start + 0.26);
                });
            }
        }

        // ----------------------------------------------------------------------------
        // 2. CONFIGURAÇÃO DO CANVAS E ESTADO GLOBAL DO JOGO
        // ----------------------------------------------------------------------------
        const canvas = document.getElementById('gameCanvas');
        const ctx = canvas.getContext('2d');
        const sound = new SoundEngine();

        // Referências da Interface (DOM)
        const ui = {
            startScreen: document.getElementById('startScreen'),
            gameOverScreen: document.getElementById('gameOverScreen'),
            hudOverlay: document.getElementById('hudOverlay'),
            touchControls: document.getElementById('touchControls'),
            hudRings: document.getElementById('hudRings'),
            hudScore: document.getElementById('hudScore'),
            hudHighScore: document.getElementById('hudHighScore'),
            hudSpeed: document.getElementById('hudSpeed'),
            hudBoostFill: document.getElementById('hudBoostFill'),
            hudBoostPct: document.getElementById('hudBoostPct'),
            startHighScore: document.getElementById('startHighScore'),
            finalScore: document.getElementById('finalScore'),
            finalHighScore: document.getElementById('finalHighScore'),
            finalDistance: document.getElementById('finalDistance'),
            finalMaxSpeed: document.getElementById('finalMaxSpeed'),
            finalBadniks: document.getElementById('finalBadniks'),
            finalRings: document.getElementById('finalRings'),
            rankBadge: document.getElementById('rankBadge'),
            rankLabel: document.getElementById('rankLabel'),
            muteBtn: document.getElementById('muteBtn'),
            iconSoundOn: document.getElementById('iconSoundOn'),
            iconSoundOff: document.getElementById('iconSoundOff'),
            btnStartGame: document.getElementById('btnStartGame'),
            btnRestartGame: document.getElementById('btnRestartGame'),
            btnTouchSlide: document.getElementById('btnTouchSlide'),
            btnTouchBoost: document.getElementById('btnTouchBoost'),
            btnTouchJump: document.getElementById('btnTouchJump')
        };

        // Persistência de Recorde via localStorage
        const STORAGE_KEY = 'sonic_velocidade_moderna_recorde_v1';
        let highScore = 0;
        try {
            const saved = localStorage.getItem(STORAGE_KEY);
            if (saved) highScore = parseInt(saved, 10) || 0;
        } catch (e) {
            highScore = 0;
        }

        function saveHighScore(val) {
            if (val > highScore) {
                highScore = Math.floor(val);
                try {
                    localStorage.setItem(STORAGE_KEY, String(highScore));
                } catch (e) {}
            }
            ui.startHighScore.textContent = String(highScore).padStart(6, '0');
            ui.hudHighScore.textContent = String(highScore).padStart(6, '0');
        }
        saveHighScore(highScore);

        // Dimensões lógicas do viewport
        let viewWidth = window.innerWidth;
        let viewHeight = window.innerHeight;
        let dpr = Math.min(window.devicePixelRatio || 1, 2);

        function resizeCanvas() {
            viewWidth = window.innerWidth;
            viewHeight = window.innerHeight;
            dpr = Math.min(window.devicePixelRatio || 1, 2);
            canvas.width = Math.floor(viewWidth * dpr);
            canvas.height = Math.floor(viewHeight * dpr);
            ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
        }
        window.addEventListener('resize', resizeCanvas);
        resizeCanvas();

        // Estado de entradas do jogador
        const input = {
            jumpPressed: false,
            jumpJustPressed: false,
            boostHeld: false,
            boostJustPressed: false,
            slideHeld: false,
            slideJustPressed: false
        };

        // Constantes físicas e de mundo (em unidades lógicas de mundo)
        const WORLD = {
            BASE_GROUND_Y: 540,
            GRAVITY: 2350,
            JUMP_VELOCITY: -860,
            SPRING_VELOCITY: -1240,
            HOMING_BOUNCE_VELOCITY: -740,
            BASE_RUN_SPEED: 520,
            MAX_RUN_SPEED: 820,
            BOOST_SPEED: 1320,
            DASH_PAD_SPEED: 1460,
            HOMING_SPEED: 1750,
            HOMING_RANGE: 370
        };

        // Estado principal da partida
        const game = {
            state: 'TITLE', // 'TITLE' | 'PLAYING' | 'GAMEOVER'
            time: 0,
            score: 0,
            rings: 0,
            totalRingsCollected: 0,
            badniksDestroyed: 0,
            distanceMeters: 0,
            maxSpeedKmh: 0,
            boostEnergy: 65, // 0 a 100
            isBoosting: false,
            camera: {
                x: 0,
                y: 260,
                zoom: 1,
                shake: 0
            },
            nextChunkX: 0,
            difficulty: 0,
            speedLines: []
        };

        // Objeto do Jogador (Sonic Moderno)
        const sonic = {
            x: 180,
            y: WORLD.BASE_GROUND_Y,
            vx: WORLD.BASE_RUN_SPEED,
            vy: 0,
            width: 38,
            height: 56,
            grounded: true,
            coyoteTimer: 0,
            jumpBufferTimer: 0,
            isRolling: false, // Pulo em bola
            isSliding: false, // Deslizando no chão
            slideTimer: 0,
            isGrinding: false,
            currentRail: null,
            isHoming: false,
            homingTarget: null,
            homingTimer: 0,
            lockedTarget: null,
            invulnTimer: 0,
            hurtTimer: 0,
            dashPadTimer: 0,
            animFrame: 0,
            afterimages: [],
            boostShockwave: 0
        };

        // Coleções de entidades do mundo
        let terrainSegments = []; // Plataformas de solo e plataformas aéreas
        let grindRails = [];      // Trilhos metálicos elevados
        let rings = [];           // Anéis dourados fixos no cenário
        let scatteredRings = [];  // Anéis quicando após sofrer dano
        let badniks = [];         // Inimigos (Motobug e Buzz Bomber)
        let springs = [];         // Molas vermelhas
        let dashPads = [];        // Painéis de impulso no chão
        let obstacles = [];       // Portões de laser elevados & barreiras quebráveis
        let itemCapsules = [];    // Cápsulas de bônus (+10 Anéis / Boost Max)
        let particles = [];       // Partículas de faíscas, poeira, explosões e energia
        let floatingTexts = [];   // Pontuações flutuantes (+100, +300, BOOST!)

        // Inicializa linhas de velocidade estilo anime nas bordas da tela
        for (let i = 0; i < 36; i++) {
            game.speedLines.push({
                angle: (Math.PI * 2 * i) / 36 + (Math.random() - 0.5) * 0.1,
                length: 0.25 + Math.random() * 0.35,
                offset: Math.random(),
                speed: 2.5 + Math.random() * 3.5,
                width: 1.5 + Math.random() * 2.5
            });
        }

        // ----------------------------------------------------------------------------
        // 3. CONTROLES DE TECLADO, MOUSE E TOQUE
        // ----------------------------------------------------------------------------
        function triggerJumpInput() {
            sound.init();
            if (game.state === 'TITLE') {
                startGame();
                return;
            }
            if (game.state === 'GAMEOVER') {
                return;
            }
            input.jumpPressed = true;
            input.jumpJustPressed = true;
            sonic.jumpBufferTimer = 0.14;
        }

        function releaseJumpInput() {
            input.jumpPressed = false;
        }

        function triggerBoostInput(active) {
            sound.init();
            if (active && !input.boostHeld) {
                input.boostJustPressed = true;
            }
            input.boostHeld = active;
            ui.btnTouchBoost.classList.toggle('active-press', active);
        }

        function triggerSlideInput(active) {
            sound.init();
            if (active && !input.slideHeld) {
                input.slideJustPressed = true;
            }
            input.slideHeld = active;
            ui.btnTouchSlide.classList.toggle('active-press', active);
        }

        window.addEventListener('keydown', (e) => {
            if (e.repeat) return;
            const code = e.code;

            if (code === 'Space' || code === 'ArrowUp' || code === 'KeyW' || code === 'KeyZ') {
                e.preventDefault();
                triggerJumpInput();
            } else if (code === 'ShiftLeft' || code === 'ShiftRight' || code === 'KeyX' || code === 'KeyE' || code === 'ArrowRight') {
                e.preventDefault();
                triggerBoostInput(true);
            } else if (code === 'ArrowDown' || code === 'KeyS' || code === 'KeyC') {
                e.preventDefault();
                triggerSlideInput(true);
            } else if (code === 'Enter') {
                if (game.state === 'TITLE' || game.state === 'GAMEOVER') {
                    startGame();
                }
            }
        });

        window.addEventListener('keyup', (e) => {
            const code = e.code;
            if (code === 'Space' || code === 'ArrowUp' || code === 'KeyW' || code === 'KeyZ') {
                releaseJumpInput();
            } else if (code === 'ShiftLeft' || code === 'ShiftRight' || code === 'KeyX' || code === 'KeyE' || code === 'ArrowRight') {
                triggerBoostInput(false);
            } else if (code === 'ArrowDown' || code === 'KeyS' || code === 'KeyC') {
                triggerSlideInput(false);
            }
        });

        // Configuração dos botões táteis na tela (Pointer Events funcionam tanto no toque quanto no mouse)
        function bindHoldButton(element, onStart, onEnd) {
            element.addEventListener('pointerdown', (e) => {
                e.preventDefault();
                e.stopPropagation();
                onStart();
            });
            const endHandler = (e) => {
                e.preventDefault();
                onEnd();
            };
            element.addEventListener('pointerup', endHandler);
            element.addEventListener('pointerleave', endHandler);
            element.addEventListener('pointercancel', endHandler);
        }

        bindHoldButton(
            ui.btnTouchJump,
            () => {
                ui.btnTouchJump.classList.add('active-press');
                triggerJumpInput();
            },
            () => {
                ui.btnTouchJump.classList.remove('active-press');
                releaseJumpInput();
            }
        );

        bindHoldButton(
            ui.btnTouchBoost,
            () => triggerBoostInput(true),
            () => triggerBoostInput(false)
        );

        bindHoldButton(
            ui.btnTouchSlide,
            () => triggerSlideInput(true),
            () => triggerSlideInput(false)
        );

        // Botões de Iniciar, Reiniciar e Mudo
        ui.btnStartGame.addEventListener('click', () => {
            sound.init();
            startGame();
        });

        ui.btnRestartGame.addEventListener('click', () => {
            sound.init();
            startGame();
        });

        ui.muteBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            sound.init();
            const isMuted = sound.toggleMute();
            ui.iconSoundOn.classList.toggle('hidden', isMuted);
            ui.iconSoundOff.classList.toggle('hidden', !isMuted);
        });

        // ----------------------------------------------------------------------------
        // 4. GERADOR PROCEDURAL DE FASES (CHUNKS ESTILO ROOFTOP RUN / SEASIDE HILL)
        // ----------------------------------------------------------------------------
        function addRingArc(startX, startY, count, spacingX, arcHeight) {
            for (let i = 0; i < count; i++) {
                const t = count > 1 ? i / (count - 1) : 0.5;
                const yOffset = Math.sin(t * Math.PI) * arcHeight;
                rings.push({
                    x: startX + i * spacingX,
                    y: startY - yOffset,
                    collected: false,
                    phase: i * 0.4
                });
            }
        }

        function addRingLine(startX, y, count, spacingX) {
            for (let i = 0; i < count; i++) {
                rings.push({
                    x: startX + i * spacingX,
                    y: y,
                    collected: false,
                    phase: i * 0.35
                });
            }
        }

        function generateNextChunk() {
            const x = game.nextChunkX;
            const gY = WORLD.BASE_GROUND_Y;
            const diff = Math.min(game.difficulty, 1);

            // Escolhe um padrão de pista variado e rítmico
            const patternIndex = game.nextChunkX < 1800
                ? 0
                : Math.floor(Math.random() * 8);

            switch (patternIndex) {
                case 0: {
                    // Pista Clássica Costeira: Dash Pad + Arco de Anéis + Motobug
                    const len = 1350;
                    terrainSegments.push({ x, y: gY, width: len, height: 420, isFloating: false });
                    dashPads.push({ x: x + 180, y: gY, width: 74 });
                    addRingArc(x + 320, gY - 40, 7, 52, 85);
                    badniks.push({
                        type: 'motobug',
                        x: x + 860,
                        y: gY,
                        baseX: x + 860,
                        patrolRange: 90,
                        vx: -110,
                        alive: true,
                        anim: 0
                    });
                    addRingLine(x + 1020, gY - 36, 4, 48);
                    game.nextChunkX += len;
                    break;
                }

                case 1: {
                    // Desafio de Deslize: Portão de Laser Elevado + Barreiras Baixas Quebráveis
                    const len = 1480;
                    terrainSegments.push({ x, y: gY, width: len, height: 420, isFloating: false });
                    addRingLine(x + 150, gY - 34, 4, 46);

                    // Portão de Laser elevado (exige deslizar por baixo: folga de 36px do chão)
                    obstacles.push({
                        type: 'laserGate',
                        x: x + 440,
                        y: gY - 150,
                        width: 44,
                        beamBottomY: gY - 36,
                        active: true
                    });

                    addRingLine(x + 530, gY - 24, 5, 46);

                    // Barreira baixa rachada (quebrada deslizando ou com Boost)
                    obstacles.push({
                        type: 'lowBarrier',
                        x: x + 860,
                        y: gY - 44,
                        width: 48,
                        height: 44,
                        broken: false
                    });
                    obstacles.push({
                        type: 'lowBarrier',
                        x: x + 1040,
                        y: gY - 44,
                        width: 48,
                        height: 44,
                        broken: false
                    });

                    itemCapsules.push({
                        x: x + 1250,
                        y: gY - 26,
                        kind: Math.random() < 0.5 ? 'rings' : 'boost',
                        opened: false
                    });
                    game.nextChunkX += len;
                    break;
                }

                case 2: {
                    // Expresso Trilho de Grind + Mola Vermelha + Buzz Bomber no final
                    const len = 1650;
                    terrainSegments.push({ x, y: gY, width: len, height: 420, isFloating: false });

                    springs.push({ x: x + 180, y: gY, bounceAnim: 0 });

                    // Trilho elevado metálico
                    const railX = x + 340;
                    const railY = gY - 195;
                    const railLen = 780;
                    grindRails.push({ x: railX, y: railY, width: railLen });
                    addRingLine(railX + 40, railY - 34, 12, 60);

                    // Inimigos no chão para quem optar pela rota inferior
                    badniks.push({
                        type: 'motobug',
                        x: x + 650,
                        y: gY,
                        baseX: x + 650,
                        patrolRange: 100,
                        vx: -120,
                        alive: true,
                        anim: 0
                    });

                    // Buzz Bomber voador após o trilho para encadear Ataque Teleguiado!
                    badniks.push({
                        type: 'buzzbomber',
                        x: railX + railLen + 170,
                        y: railY - 35,
                        baseY: railY - 35,
                        alive: true,
                        anim: 0
                    });
                    addRingArc(railX + railLen + 240, railY - 90, 5, 50, 60);

                    game.nextChunkX += len;
                    break;
                }

                case 3: {
                    // Corrente Aérea de Ataque Teleguiado sobre o Oceano!
                    const leftGround = 340;
                    const gapWidth = 860;
                    const rightGround = 420;

                    terrainSegments.push({ x, y: gY, width: leftGround, height: 420, isFloating: false });
                    springs.push({ x: x + 240, y: gY, bounceAnim: 0 });

                    // 3 Buzz Bombers suspensos sobre o abismo para saltar em sequência com Homing Attack
                    const b1X = x + leftGround + 160;
                    const b2X = x + leftGround + 420;
                    const b3X = x + leftGround + 680;

                    badniks.push({ type: 'buzzbomber', x: b1X, y: gY - 170, baseY: gY - 170, alive: true, anim: 0 });
                    addRingArc(b1X + 40, gY - 230, 3, 45, 35);

                    badniks.push({ type: 'buzzbomber', x: b2X, y: gY - 210, baseY: gY - 210, alive: true, anim: 0 });
                    addRingArc(b2X + 40, gY - 270, 3, 45, 35);

                    badniks.push({ type: 'buzzbomber', x: b3X, y: gY - 175, baseY: gY - 175, alive: true, anim: 0 });

                    // Plataforma de segurança inferior para não haver morte injusta
                    terrainSegments.push({
                        x: x + leftGround + 240,
                        y: gY - 30,
                        width: 360,
                        height: 36,
                        isFloating: true
                    });

                    terrainSegments.push({
                        x: x + leftGround + gapWidth,
                        y: gY,
                        width: rightGround,
                        height: 420,
                        isFloating: false
                    });
                    addRingLine(x + leftGround + gapWidth + 80, gY - 36, 4, 48);

                    game.nextChunkX += leftGround + gapWidth + rightGround;
                    break;
                }

                case 4: {
                    // Rota Dupla: Terraços de Rooftop Run + Cápsula de Energia
                    const len = 1600;
                    terrainSegments.push({ x, y: gY, width: len, height: 420, isFloating: false });

                    // Plataforma aérea superior
                    const plat1X = x + 280;
                    const plat1Y = gY - 165;
                    terrainSegments.push({ x: plat1X, y: plat1Y, width: 460, height: 38, isFloating: true });
                    addRingLine(plat1X + 40, plat1Y - 34, 6, 62);
                    itemCapsules.push({ x: plat1X + 410, y: plat1Y - 26, kind: 'boost', opened: false });

                    // Segunda plataforma ainda mais alta
                    const plat2X = x + 840;
                    const plat2Y = gY - 255;
                    terrainSegments.push({ x: plat2X, y: plat2Y, width: 440, height: 38, isFloating: true });
                    addRingArc(plat2X + 50, plat2Y - 40, 6, 56, 70);

                    // Rota inferior com Dash Pad e Portão de Laser
                    dashPads.push({ x: x + 200, y: gY, width: 74 });
                    obstacles.push({
                        type: 'laserGate',
                        x: x + 640,
                        y: gY - 150,
                        width: 44,
                        beamBottomY: gY - 36,
                        active: true
                    });
                    badniks.push({
                        type: 'motobug',
                        x: x + 1060,
                        y: gY,
                        baseX: x + 1060,
                        patrolRange: 110,
                        vx: -130,
                        alive: true,
                        anim: 0
                    });

                    game.nextChunkX += len;
                    break;
                }

                case 5: {
                    // Rodovia Supersônica de Boost (Ideal para velocidade máxima!)
                    const len = 1750;
                    terrainSegments.push({ x, y: gY, width: len, height: 420, isFloating: false });

                    dashPads.push({ x: x + 140, y: gY, width: 74 });
                    addRingLine(x + 260, gY - 36, 10, 52);

                    // Fileira de Motobugs para atropelar com Boost ou encadear Homing Attack
                    for (let i = 0; i < 3; i++) {
                        badniks.push({
                            type: 'motobug',
                            x: x + 880 + i * 190,
                            y: gY,
                            baseX: x + 880 + i * 190,
                            patrolRange: 45,
                            vx: -95,
                            alive: true,
                            anim: i
                        });
                    }
                    dashPads.push({ x: x + 1480, y: gY, width: 74 });
                    game.nextChunkX += len;
                    break;
                }

                case 6: {
                    // Salto entre Trilhos Duplos (Grind Rail Combo)
                    const len = 1720;
                    terrainSegments.push({ x, y: gY, width: len, height: 420, isFloating: false });

                    const r1X = x + 200;
                    const r1Y = gY - 140;
                    grindRails.push({ x: r1X, y: r1Y, width: 540 });
                    addRingLine(r1X + 40, r1Y - 32, 8, 58);

                    const r2X = x + 840;
                    const r2Y = gY - 220;
                    grindRails.push({ x: r2X, y: r2Y, width: 620 });
                    addRingLine(r2X + 40, r2Y - 32, 9, 60);

                    // Obstáculo baixo no chão abaixo dos trilhos
                    obstacles.push({
                        type: 'lowBarrier',
                        x: x + 680,
                        y: gY - 44,
                        width: 48,
                        height: 44,
                        broken: false
                    });
                    itemCapsules.push({ x: x + 1540, y: gY - 26, kind: 'rings', opened: false });

                    game.nextChunkX += len;
                    break;
                }

                default: {
                    // Salto sobre Falésia com Mola Central e Buzz Bomber
                    const leftW = 460;
                    const gapW = 540 + Math.floor(diff * 120);
                    const rightW = 520;

                    terrainSegments.push({ x, y: gY, width: leftW, height: 420, isFloating: false });
                    dashPads.push({ x: x + 240, y: gY, width: 74 });
                    addRingArc(x + 360, gY - 55, 6, 54, 110);

                    // Plataforma ilha no meio do abismo com mola
                    const islandX = x + leftW + gapW * 0.35;
                    terrainSegments.push({ x: islandX, y: gY + 15, width: 170, height: 380, isFloating: false });
                    springs.push({ x: islandX + 85, y: gY + 15, bounceAnim: 0 });

                    badniks.push({
                        type: 'buzzbomber',
                        x: islandX + 230,
                        y: gY - 180,
                        baseY: gY - 180,
                        alive: true,
                        anim: 0
                    });

                    terrainSegments.push({
                        x: x + leftW + gapW,
                        y: gY,
                        width: rightW,
                        height: 420,
                        isFloating: false
                    });
                    addRingLine(x + leftW + gapW + 90, gY - 36, 5, 50);

                    game.nextChunkX += leftW + gapW + rightW;
                    break;
                }
            }
        }

        // ----------------------------------------------------------------------------
        // 5. EFEITOS DE PARTÍCULAS E TEXTOS FLUTUANTES
        // ----------------------------------------------------------------------------
        function spawnParticles(x, y, color, count, speedScale = 1, gravity = 600) {
            for (let i = 0; i < count; i++) {
                const angle = Math.random() * Math.PI * 2;
                const speed = (90 + Math.random() * 280) * speedScale;
                particles.push({
                    x,
                    y,
                    vx: Math.cos(angle) * speed,
                    vy: Math.sin(angle) * speed - 80,
                    size: 2.5 + Math.random() * 4.5,
                    color,
                    alpha: 1,
                    life: 0.35 + Math.random() * 0.35,
                    maxLife: 0.7,
                    gravity
                });
            }
        }

        function spawnFloatingText(x, y, text, color = '#fde047') {
            floatingTexts.push({
                x,
                y,
                text,
                color,
                vy: -85,
                life: 0.85,
                maxLife: 0.85
            });
        }

        // ----------------------------------------------------------------------------
        // 6. INICIALIZAÇÃO E REINÍCIO DA PARTIDA
        // ----------------------------------------------------------------------------
        function startGame() {
            game.state = 'PLAYING';
            game.time = 0;
            game.score = 0;
            game.rings = 0;
            game.totalRingsCollected = 0;
            game.badniksDestroyed = 0;
            game.distanceMeters = 0;
            game.maxSpeedKmh = 0;
            game.boostEnergy = 65;
            game.isBoosting = false;
            game.nextChunkX = 0;
            game.difficulty = 0;

            sonic.x = 180;
            sonic.y = WORLD.BASE_GROUND_Y;
            sonic.vx = WORLD.BASE_RUN_SPEED;
            sonic.vy = 0;
            sonic.grounded = true;
            sonic.coyoteTimer = 0;
            sonic.jumpBufferTimer = 0;
            sonic.isRolling = false;
            sonic.isSliding = false;
            sonic.slideTimer = 0;
            sonic.isGrinding = false;
            sonic.currentRail = null;
            sonic.isHoming = false;
            sonic.homingTarget = null;
            sonic.homingTimer = 0;
            sonic.lockedTarget = null;
            sonic.invulnTimer = 0;
            sonic.hurtTimer = 0;
            sonic.dashPadTimer = 0;
            sonic.afterimages = [];
            sonic.boostShockwave = 0;

            game.camera.x = sonic.x + 220;
            game.camera.y = WORLD.BASE_GROUND_Y - 150;
            game.camera.zoom = 1;
            game.camera.shake = 0;

            // Limpa entidades anteriores
            terrainSegments = [];
            grindRails = [];
            rings = [];
            scatteredRings = [];
            badniks = [];
            springs = [];
            dashPads = [];
            obstacles = [];
            itemCapsules = [];
            particles = [];
            floatingTexts = [];

            // Gera os primeiros trechos da pista
            while (game.nextChunkX < 4500) {
                generateNextChunk();
            }

            // Atualiza visibilidade das telas
            ui.startScreen.classList.add('hidden');
            ui.gameOverScreen.classList.add('hidden');
            ui.hudOverlay.classList.remove('hidden');
            ui.touchControls.classList.remove('hidden');
            updateHUD();
        }

        function triggerGameOver() {
            if (game.state === 'GAMEOVER') return;
            game.state = 'GAMEOVER';
            sound.playGameOver();
            saveHighScore(game.score);

            ui.hudOverlay.classList.add('hidden');
            ui.touchControls.classList.add('hidden');
            ui.gameOverScreen.classList.remove('hidden');

            const finalPts = Math.floor(game.score);
            ui.finalScore.textContent = finalPts.toLocaleString('pt-BR');
            ui.finalHighScore.textContent = highScore.toLocaleString('pt-BR');
            ui.finalDistance.textContent = `${Math.floor(game.distanceMeters)} m`;
            ui.finalMaxSpeed.textContent = `${Math.floor(game.maxSpeedKmh)} km/h`;
            ui.finalBadniks.textContent = String(game.badniksDestroyed);
            ui.finalRings.textContent = String(game.totalRingsCollected);

            // Cálculo de Rank estilo Sonic Moderno (S, A, B, C)
            let rank = 'C';
            let label = 'CONTINUE TREINANDO!';
            let colorClass = 'text-sky-300';

            if (finalPts >= 18000 || (game.distanceMeters >= 1100 && game.badniksDestroyed >= 8)) {
                rank = 'S';
                label = 'VELOCIDADE SÔNICA SUPREMA!';
                colorClass = 'text-amber-300';
            } else if (finalPts >= 10000 || game.distanceMeters >= 650) {
                rank = 'A';
                label = 'CORRIDA INCRÍVEL!';
                colorClass = 'text-rose-400';
            } else if (finalPts >= 4500 || game.distanceMeters >= 320) {
                rank = 'B';
                label = 'MUITO BOM!';
                colorClass = 'text-emerald-300';
            }

            ui.rankBadge.textContent = rank;
            ui.rankBadge.className = `font-orbitron text-5xl sm:text-6xl font-black italic drop-shadow-[0_0_18px_rgba(255,255,255,0.65)] ${colorClass}`;
            ui.rankLabel.textContent = label;
        }

        // ----------------------------------------------------------------------------
        // 7. MECÂNICAS DE DANO, ANÉIS ESPALHADOS E ATAQUE TELEGUIADO
        // ----------------------------------------------------------------------------
        function damageSonic() {
            if (sonic.invulnTimer > 0 || game.state !== 'PLAYING') return;

            if (game.rings > 0) {
                // Sistema clássico de saúde por Anéis: espalha até 20 anéis quicando pelo chão!
                const lostRings = Math.min(game.rings, 20);
                game.rings = 0;
                sonic.invulnTimer = 1.65;
                sonic.hurtTimer = 0.42;
                sonic.isHoming = false;
                sonic.isSliding = false;
                sonic.isGrinding = false;
                sonic.vy = -480;
                sonic.vx = Math.max(260, sonic.vx * 0.55);
                game.camera.shake = 14;
                sound.playRingScatter();

                spawnFloatingText(sonic.x, sonic.y - 70, 'ANÉIS PERDIDOS!', '#ff5555');

                for (let i = 0; i < lostRings; i++) {
                    const angle = -Math.PI * 0.15 - (Math.PI * 0.7) * (i / Math.max(1, lostRings - 1));
                    const speed = 260 + (i % 4) * 95;
                    scatteredRings.push({
                        x: sonic.x,
                        y: sonic.y - 36,
                        vx: sonic.vx * 0.65 + Math.cos(angle) * speed,
                        vy: Math.sin(angle) * speed - 140,
                        life: 4.5,
                        collectDelay: 0.35,
                        phase: i * 0.5
                    });
                }
            } else {
                // 0 Anéis -> Game Over
                game.camera.shake = 20;
                spawnParticles(sonic.x, sonic.y - 28, '#38bdf8', 24, 1.4);
                triggerGameOver();
            }
        }

        // Procura o melhor alvo para o Ataque Teleguiado (Badniks, Molas ou Cápsulas)
        function findHomingTarget() {
            if (sonic.grounded || sonic.isGrinding || sonic.isHoming) return null;

            let bestTarget = null;
            let bestDist = WORLD.HOMING_RANGE;
            const sx = sonic.x;
            const sy = sonic.y - 28;

            // 1. Badniks vivos
            for (const b of badniks) {
                if (!b.alive) continue;
                const dx = b.x - sx;
                const dy = (b.y - 22) - sy;
                if (dx > -35 && dx < WORLD.HOMING_RANGE && dy > -180 && dy < 260) {
                    const dist = Math.hypot(dx, dy);
                    if (dist < bestDist) {
                        bestDist = dist;
                        bestTarget = { kind: 'badnik', ref: b, x: b.x, y: b.y - 22 };
                    }
                }
            }

            // 2. Cápsulas de itens fechadas
            for (const c of itemCapsules) {
                if (c.opened) continue;
                const dx = c.x - sx;
                const dy = c.y - sy;
                if (dx > -25 && dx < WORLD.HOMING_RANGE && dy > -150 && dy < 240) {
                    const dist = Math.hypot(dx, dy);
                    if (dist < bestDist) {
                        bestDist = dist;
                        bestTarget = { kind: 'capsule', ref: c, x: c.x, y: c.y };
                    }
                }
            }

            // 3. Molas Vermelhas (Springs)
            for (const s of springs) {
                const dx = s.x - sx;
                const dy = (s.y - 16) - sy;
                if (dx > -20 && dx < WORLD.HOMING_RANGE * 0.85 && dy > -80 && dy < 250) {
                    const dist = Math.hypot(dx, dy);
                    if (dist < bestDist) {
                        bestDist = dist;
                        bestTarget = { kind: 'spring', ref: s, x: s.x, y: s.y - 16 };
                    }
                }
            }

            return bestTarget;
        }

        function defeatBadnik(b) {
            b.alive = false;
            game.badniksDestroyed += 1;
            game.score += 300;
            game.boostEnergy = Math.min(100, game.boostEnergy + 14);
            game.camera.shake = Math.max(game.camera.shake, 8);
            sound.playBadnikSmash();
            spawnParticles(b.x, b.y - 22, '#fb923c', 16, 1.3);
            spawnParticles(b.x, b.y - 22, '#38bdf8', 10, 1.1);
            spawnFloatingText(b.x, b.y - 45, '+300', '#38bdf8');
        }

        function openCapsule(c) {
            c.opened = true;
            game.camera.shake = Math.max(game.camera.shake, 7);
            sound.playBadnikSmash();
            if (c.kind === 'rings') {
                game.rings += 10;
                game.totalRingsCollected += 10;
                game.score += 500;
                game.boostEnergy = Math.min(100, game.boostEnergy + 18);
                sound.playRing();
                spawnParticles(c.x, c.y, '#facc15', 18, 1.2);
                spawnFloatingText(c.x, c.y - 35, '+10 ANÉIS!', '#fde047');
            } else {
                game.boostEnergy = 100;
                game.score += 500;
                spawnParticles(c.x, c.y, '#00f2ff', 20, 1.3);
                spawnFloatingText(c.x, c.y - 35, 'BOOST MÁXIMO!', '#22d3ee');
            }
        }

        // ----------------------------------------------------------------------------
        // 8. LOOP DE ATUALIZAÇÃO DE FÍSICA E LÓGICA (FIXED/CLAMPED DT)
        // ----------------------------------------------------------------------------
        function update(dt) {
            game.time += dt;

            if (game.state !== 'PLAYING') {
                // Animação suave do cenário de fundo na tela inicial
                game.camera.x += 260 * dt;
                return;
            }

            // Atualiza temporizadores
            if (sonic.invulnTimer > 0) sonic.invulnTimer -= dt;
            if (sonic.hurtTimer > 0) sonic.hurtTimer -= dt;
            if (sonic.dashPadTimer > 0) sonic.dashPadTimer -= dt;
            if (sonic.coyoteTimer > 0) sonic.coyoteTimer -= dt;
            if (sonic.jumpBufferTimer > 0) sonic.jumpBufferTimer -= dt;
            if (sonic.boostShockwave > 0) sonic.boostShockwave = Math.max(0, sonic.boostShockwave - dt * 2.8);
            if (game.camera.shake > 0) game.camera.shake = Math.max(0, game.camera.shake - dt * 38);

            // Escala gradual de dificuldade com a distância
            game.difficulty = Math.min(1, game.distanceMeters / 1800);

            // --- GERENCIAMENTO DO BOOST (IMPULSO) ---
            const wantsBoost = input.boostHeld && game.boostEnergy > 1 && sonic.hurtTimer <= 0;
            if (wantsBoost) {
                if (!game.isBoosting) {
                    game.isBoosting = true;
                    sonic.boostShockwave = 1.0;
                    game.camera.shake = Math.max(game.camera.shake, 9);
                    sound.playBoostBoom();
                    spawnParticles(sonic.x - 15, sonic.y - 28, '#00f2ff', 14, 1.4, 0);
                }
                game.boostEnergy = Math.max(0, game.boostEnergy - 22 * dt);
                if (game.boostEnergy <= 0) {
                    game.isBoosting = false;
                }
            } else {
                game.isBoosting = false;
            }

            // --- GERENCIAMENTO DO DESLIZE / ROLAR (SLIDE) ---
            if (input.slideHeld && sonic.grounded && !sonic.isGrinding && sonic.hurtTimer <= 0) {
                if (!sonic.isSliding) {
                    sonic.isSliding = true;
                    sonic.vx = Math.max(sonic.vx, WORLD.BASE_RUN_SPEED + 190);
                    sound.playSlide();
                    spawnParticles(sonic.x, sonic.y - 6, '#38bdf8', 8, 0.8, 200);
                }
                sonic.slideTimer += dt;
            } else {
                sonic.isSliding = false;
                sonic.slideTimer = 0;
            }

            // --- ATAQUE TELEGUIADO (HOMING ATTACK) ---
            if (!sonic.isHoming) {
                const prevLock = sonic.lockedTarget;
                sonic.lockedTarget = findHomingTarget();
                if (sonic.lockedTarget && (!prevLock || prevLock.ref !== sonic.lockedTarget.ref)) {
                    sound.playLockOn();
                }
            } else {
                sonic.lockedTarget = null;
            }

            // --- PULO E DISPARO DO ATAQUE TELEGUIADO ---
            if (input.jumpJustPressed) {
                if (sonic.grounded || sonic.coyoteTimer > 0 || sonic.isGrinding) {
                    // Pulo normal a partir do chão ou trilho
                    sonic.grounded = false;
                    sonic.coyoteTimer = 0;
                    sonic.jumpBufferTimer = 0;
                    sonic.isGrinding = false;
                    sonic.currentRail = null;
                    sonic.isSliding = false;
                    sonic.isRolling = true;
                    sonic.vy = WORLD.JUMP_VELOCITY;
                    sound.playJump();
                    spawnParticles(sonic.x, sonic.y, '#e0f2fe', 8, 0.7, 300);
                } else if (!sonic.isHoming && sonic.lockedTarget) {
                    // Dispara o Ataque Teleguiado no alvo travado!
                    sonic.isHoming = true;
                    sonic.isRolling = true;
                    sonic.homingTarget = sonic.lockedTarget;
                    sonic.homingTimer = 0.48;
                    sound.playHomingDash();
                    spawnParticles(sonic.x, sonic.y - 26, '#00f2ff', 14, 1.2, 0);
                } else if (!sonic.isHoming && sonic.vy > -220 && sonic.homingTimer <= 0) {
                    // Impulso aéreo rápido (Jump Dash) quando não há inimigo travado
                    sonic.homingTimer = 0.25;
                    sonic.isRolling = true;
                    sonic.vx = Math.max(sonic.vx, WORLD.MAX_RUN_SPEED + 160);
                    sonic.vy = Math.min(sonic.vy, -140);
                    sound.playHomingDash();
                    spawnParticles(sonic.x - 10, sonic.y - 26, '#38bdf8', 10, 1.0, 0);
                }
            }

            // Corte variável de altura do pulo ao soltar o botão cedo
            if (!input.jumpPressed && sonic.vy < -320 && !sonic.isHoming) {
                sonic.vy += WORLD.GRAVITY * 1.6 * dt;
            }

            // --- MOVIMENTO E FÍSICA ---
            if (sonic.isHoming && sonic.homingTarget) {
                sonic.homingTimer -= dt;
                const target = sonic.homingTarget;
                // Atualiza posição atual do alvo caso seja um Badnik móvel
                const tx = target.ref.x;
                const ty = target.kind === 'badnik' ? target.ref.y - 22 : target.ref.y;
                const dx = tx - sonic.x;
                const dy = ty - (sonic.y - 24);
                const dist = Math.hypot(dx, dy);

                if (dist < 38 || sonic.homingTimer <= 0) {
                    // Impacto do Ataque Teleguiado!
                    sonic.isHoming = false;
                    sonic.homingTarget = null;
                    sonic.x = tx;
                    sonic.y = ty + 20;
                    sonic.vy = WORLD.HOMING_BOUNCE_VELOCITY;
                    sonic.vx = Math.max(sonic.vx, WORLD.BASE_RUN_SPEED + 150);
                    sonic.isRolling = true;

                    if (target.kind === 'badnik' && target.ref.alive) {
                        defeatBadnik(target.ref);
                    } else if (target.kind === 'capsule' && !target.ref.opened) {
                        openCapsule(target.ref);
                    } else if (target.kind === 'spring') {
                        sonic.vy = WORLD.SPRING_VELOCITY;
                        target.ref.bounceAnim = 1;
                        sound.playSpring();
                    }
                } else {
                    sonic.vx = (dx / dist) * WORLD.HOMING_SPEED;
                    sonic.vy = (dy / dist) * WORLD.HOMING_SPEED;
                    sonic.x += sonic.vx * dt;
                    sonic.y += sonic.vy * dt;
                }
            } else {
                // Velocidade alvo horizontal
                const naturalMax = WORLD.BASE_RUN_SPEED + game.difficulty * (WORLD.MAX_RUN_SPEED - WORLD.BASE_RUN_SPEED);
                let targetVx = naturalMax;

                if (sonic.dashPadTimer > 0) {
                    targetVx = WORLD.DASH_PAD_SPEED;
                } else if (game.isBoosting) {
                    targetVx = WORLD.BOOST_SPEED;
                } else if (sonic.isGrinding) {
                    targetVx = Math.max(naturalMax + 210, sonic.vx);
                } else if (sonic.isSliding) {
                    targetVx = Math.max(naturalMax + 110, sonic.vx - 95 * dt);
                }

                // Aceleração suave
                const accel = game.isBoosting ? 2400 : 780;
                if (sonic.vx < targetVx) {
                    sonic.vx = Math.min(targetVx, sonic.vx + accel * dt);
                } else if (sonic.vx > targetVx) {
                    sonic.vx = Math.max(targetVx, sonic.vx - 540 * dt);
                }

                const prevX = sonic.x;
                const prevY = sonic.y;

                sonic.x += sonic.vx * dt;

                if (sonic.isGrinding && sonic.currentRail) {
                    // Sonic deslizando no trilho metálico
                    sonic.y = sonic.currentRail.y;
                    sonic.vy = 0;
                    sonic.grounded = false;
                    sonic.isRolling = false;
                    game.score += 180 * dt;
                    game.boostEnergy = Math.min(100, game.boostEnergy + 6 * dt);
                    sound.playGrindSpark();

                    // Faíscas douradas nos tênis
                    if (Math.random() < 0.75) {
                        particles.push({
                            x: sonic.x - 8,
                            y: sonic.y - 2,
                            vx: -120 - Math.random() * 140,
                            vy: -40 - Math.random() * 120,
                            size: 2.5 + Math.random() * 2.5,
                            color: Math.random() < 0.5 ? '#fde047' : '#fb923c',
                            alpha: 1,
                            life: 0.25,
                            maxLife: 0.25,
                            gravity: 500
                        });
                    }

                    // Saiu do final do trilho
                    if (sonic.x > sonic.currentRail.x + sonic.currentRail.width + 12) {
                        sonic.isGrinding = false;
                        sonic.currentRail = null;
                        sonic.vy = -220; // Pequeno impulso ao sair do trilho
                    }
                } else {
                    // Gravidade normal
                    sonic.vy += WORLD.GRAVITY * dt;
                    sonic.y += sonic.vy * dt;

                    const wasGrounded = sonic.grounded;
                    sonic.grounded = false;

                    // 1. Checa colisão com Trilhos de Grind (ao cair sobre eles)
                    if (sonic.vy >= 0) {
                        for (const rail of grindRails) {
                            if (
                                sonic.x >= rail.x - 10 &&
                                sonic.x <= rail.x + rail.width + 10 &&
                                prevY <= rail.y + 14 &&
                                sonic.y >= rail.y - 4
                            ) {
                                sonic.y = rail.y;
                                sonic.vy = 0;
                                sonic.isGrinding = true;
                                sonic.currentRail = rail;
                                sonic.isRolling = false;
                                sonic.isSliding = false;
                                sound.playGrindSpark();
                                break;
                            }
                        }
                    }

                    // 2. Checa colisão com Plataformas e Solo
                    if (!sonic.isGrinding && sonic.vy >= 0) {
                        for (const seg of terrainSegments) {
                            if (
                                sonic.x + 14 >= seg.x &&
                                sonic.x - 14 <= seg.x + seg.width &&
                                prevY <= seg.y + 18 &&
                                sonic.y >= seg.y
                            ) {
                                sonic.y = seg.y;
                                sonic.vy = 0;
                                sonic.grounded = true;
                                sonic.isRolling = false;
                                break;
                            }
                        }
                    }

                    if (wasGrounded && !sonic.grounded && sonic.vy >= 0) {
                        sonic.coyoteTimer = 0.12;
                    }

                    // Jump Buffer ao tocar o chão
                    if (sonic.grounded && sonic.jumpBufferTimer > 0) {
                        sonic.grounded = false;
                        sonic.jumpBufferTimer = 0;
                        sonic.isRolling = true;
                        sonic.vy = WORLD.JUMP_VELOCITY;
                        sound.playJump();
                    }
                }
            }

            // Queda em abismo profundo
            if (sonic.y > WORLD.BASE_GROUND_Y + 340) {
                triggerGameOver();
                return;
            }

            // --- PONTUAÇÃO E DISTÂNCIA ---
            const distDelta = (sonic.vx * dt) / 36;
            game.distanceMeters += distDelta;
            game.score += distDelta * (game.isBoosting ? 18 : 10);

            const currentKmh = Math.round((sonic.vx / WORLD.BASE_RUN_SPEED) * 210);
            if (currentKmh > game.maxSpeedKmh) {
                game.maxSpeedKmh = currentKmh;
            }

            // Rastro de pós-imagem (Afterimage) em alta velocidade / Boost / Homing
            if (game.isBoosting || sonic.isHoming || sonic.dashPadTimer > 0) {
                if (Math.random() < 0.7) {
                    sonic.afterimages.push({
                        x: sonic.x,
                        y: sonic.y,
                        isBall: sonic.isRolling || sonic.isSliding || sonic.isHoming,
                        alpha: 0.55
                    });
                }
            }
            for (let i = sonic.afterimages.length - 1; i >= 0; i--) {
                sonic.afterimages[i].alpha -= dt * 2.8;
                if (sonic.afterimages[i].alpha <= 0) {
                    sonic.afterimages.splice(i, 1);
                }
            }

            // Animação de corrida do Sonic
            sonic.animFrame += (sonic.vx / 45) * dt;

            // --- ATUALIZAÇÃO DE ENTIDADES E COLISÕES ---
            const sonicCenterY = sonic.isSliding || sonic.isRolling ? sonic.y - 18 : sonic.y - 28;
            const sonicHitRadius = sonic.isSliding || sonic.isRolling ? 20 : 25;
            const magnetRadius = game.isBoosting ? 240 : 52;

            // 1. Anéis Fixos
            for (const r of rings) {
                if (r.collected) continue;
                r.phase += dt * 5;
                const dx = sonic.x - r.x;
                const dy = sonicCenterY - r.y;
                const dist = Math.hypot(dx, dy);

                // Atração magnética durante o Boost
                if (game.isBoosting && dist < magnetRadius && dist > 1) {
                    r.x += (dx / dist) * 1150 * dt;
                    r.y += (dy / dist) * 1150 * dt;
                }

                if (dist < 40) {
                    r.collected = true;
                    game.rings += 1;
                    game.totalRingsCollected += 1;
                    game.score += 50;
                    game.boostEnergy = Math.min(100, game.boostEnergy + 3.5);
                    sound.playRing();
                    spawnParticles(r.x, r.y, '#fde047', 6, 0.6, 100);
                }
            }

            // 2. Anéis Espalhados (após dano)
            for (let i = scatteredRings.length - 1; i >= 0; i--) {
                const sr = scatteredRings[i];
                sr.life -= dt;
                sr.collectDelay -= dt;
                sr.phase += dt * 8;
                sr.vy += WORLD.GRAVITY * 0.65 * dt;
                sr.x += sr.vx * dt;
                sr.y += sr.vy * dt;

                // Quica no chão
                for (const seg of terrainSegments) {
                    if (sr.x >= seg.x && sr.x <= seg.x + seg.width && sr.y >= seg.y - 8 && sr.vy > 0) {
                        sr.y = seg.y - 8;
                        sr.vy = -sr.vy * 0.72;
                        sr.vx *= 0.88;
                    }
                }

                if (sr.collectDelay <= 0) {
                    const dist = Math.hypot(sonic.x - sr.x, sonicCenterY - sr.y);
                    if (dist < 46) {
                        game.rings += 1;
                        game.totalRingsCollected += 1;
                        game.score += 25;
                        sound.playRing();
                        spawnParticles(sr.x, sr.y, '#fde047', 5, 0.5, 80);
                        scatteredRings.splice(i, 1);
                        continue;
                    }
                }

                if (sr.life <= 0) {
                    scatteredRings.splice(i, 1);
                }
            }

            // 3. Dash Pads (Painéis de Impulso)
            for (const dp of dashPads) {
                if (
                    sonic.grounded &&
                    Math.abs(sonic.y - dp.y) < 16 &&
                    sonic.x >= dp.x - 15 &&
                    sonic.x <= dp.x + dp.width + 15
                ) {
                    if (sonic.dashPadTimer <= 0.1) {
                        sound.playDashPad();
                        game.score += 150;
                        game.boostEnergy = Math.min(100, game.boostEnergy + 15);
                        spawnParticles(dp.x + dp.width * 0.5, dp.y - 10, '#22d3ee', 12, 1.2, 0);
                        spawnFloatingText(dp.x + 20, dp.y - 45, 'IMPULSO!', '#22d3ee');
                    }
                    sonic.dashPadTimer = 0.65;
                    sonic.vx = WORLD.DASH_PAD_SPEED;
                }
            }

            // 4. Molas Vermelhas (Springs)
            for (const sp of springs) {
                if (sp.bounceAnim > 0) sp.bounceAnim = Math.max(0, sp.bounceAnim - dt * 4);
                const dist = Math.hypot(sonic.x - sp.x, (sonic.y - 14) - (sp.y - 14));
                if (dist < 38 && sonic.vy >= -200) {
                    sonic.y = sp.y - 22;
                    sonic.vy = WORLD.SPRING_VELOCITY;
                    sonic.grounded = false;
                    sonic.isRolling = true;
                    sonic.isSliding = false;
                    sonic.isGrinding = false;
                    sp.bounceAnim = 1;
                    sound.playSpring();
                    spawnParticles(sp.x, sp.y - 18, '#f87171', 12, 1.0, 200);
                }
            }

            // 5. Cápsulas de Itens
            for (const cap of itemCapsules) {
                if (cap.opened) continue;
                const dist = Math.hypot(sonic.x - cap.x, sonicCenterY - cap.y);
                if (dist < 42) {
                    openCapsule(cap);
                    if (!sonic.grounded && !game.isBoosting) {
                        sonic.vy = -460;
                    }
                }
            }

            // 6. Obstáculos (Portões de Laser Elevados e Barreiras Baixas)
            for (const obs of obstacles) {
                if (obs.type === 'laserGate') {
                    // Checa se Sonic atravessa a coluna do laser sem estar deslizando/rolando baixo
                    if (Math.abs(sonic.x - obs.x) < 22) {
                        const sonicHeadY = sonic.isSliding ? sonic.y - 24 : sonic.y - 52;
                        if (sonicHeadY < obs.beamBottomY && sonic.y > obs.y) {
                            if (game.isBoosting) {
                                // Boost atravessa!
                                spawnParticles(obs.x, sonicCenterY, '#00f2ff', 8, 1.0, 0);
                            } else {
                                damageSonic();
                            }
                        }
                    }
                } else if (obs.type === 'lowBarrier' && !obs.broken) {
                    if (
                        sonic.x + 16 >= obs.x &&
                        sonic.x - 16 <= obs.x + obs.width &&
                        sonic.y > obs.y + 4
                    ) {
                        if (sonic.isSliding || sonic.isRolling || game.isBoosting) {
                            // Quebra a barreira com estilo!
                            obs.broken = true;
                            game.score += 120;
                            game.camera.shake = Math.max(game.camera.shake, 6);
                            sound.playBadnikSmash();
                            spawnParticles(obs.x + 24, obs.y + 22, '#94a3b8', 14, 1.1, 500);
                            spawnFloatingText(obs.x + 20, obs.y - 20, '+120', '#e2e8f0');
                        } else {
                            obs.broken = true;
                            damageSonic();
                        }
                    }
                }
            }

            // 7. Badniks (Motobug & Buzz Bomber)
            for (const b of badniks) {
                if (!b.alive) continue;
                b.anim += dt * 8;

                if (b.type === 'motobug') {
                    b.x += b.vx * dt;
                    if (b.x < b.baseX - b.patrolRange) {
                        b.x = b.baseX - b.patrolRange;
                        b.vx = Math.abs(b.vx);
                    } else if (b.x > b.baseX + b.patrolRange) {
                        b.x = b.baseX + b.patrolRange;
                        b.vx = -Math.abs(b.vx);
                    }
                } else if (b.type === 'buzzbomber') {
                    b.y = b.baseY + Math.sin(b.anim * 0.5) * 14;
                }

                const bCenterY = b.y - 22;
                const dist = Math.hypot(sonic.x - b.x, sonicCenterY - bCenterY);
                if (dist < sonicHitRadius + 22) {
                    // Sonic derrota o Badnik se estiver em Boost, Rolando/Pulando, Deslizando ou em Ataque Teleguiado
                    const canDestroy = game.isBoosting || sonic.isRolling || sonic.isSliding || sonic.isHoming || sonic.vy > 80;
                    if (canDestroy) {
                        defeatBadnik(b);
                        if (!sonic.grounded && !game.isBoosting && !sonic.isHoming) {
                            sonic.vy = WORLD.HOMING_BOUNCE_VELOCITY * 0.85;
                        }
                    } else {
                        damageSonic();
                    }
                }
            }

            // --- ATUALIZAÇÃO DE PARTÍCULAS E TEXTOS ---
            for (let i = particles.length - 1; i >= 0; i--) {
                const p = particles[i];
                p.life -= dt;
                p.vy += p.gravity * dt;
                p.x += p.vx * dt;
                p.y += p.vy * dt;
                p.alpha = Math.max(0, p.life / p.maxLife);
                if (p.life <= 0) particles.splice(i, 1);
            }

            for (let i = floatingTexts.length - 1; i >= 0; i--) {
                const ft = floatingTexts[i];
                ft.life -= dt;
                ft.y += ft.vy * dt;
                if (ft.life <= 0) floatingTexts.splice(i, 1);
            }

            // --- GERAÇÃO CONTÍNUA E LIMPEZA DE ENTIDADES ATRÁS DA CÂMERA ---
            while (game.nextChunkX < sonic.x + 3400) {
                generateNextChunk();
            }

            const cullX = sonic.x - 1100;
            terrainSegments = terrainSegments.filter(s => s.x + s.width > cullX);
            grindRails = grindRails.filter(r => r.x + r.width > cullX);
            rings = rings.filter(r => !r.collected && r.x > cullX);
            badniks = badniks.filter(b => b.alive && b.x > cullX);
            springs = springs.filter(s => s.x > cullX);
            dashPads = dashPads.filter(d => d.x + d.width > cullX);
            obstacles = obstacles.filter(o => o.x + (o.width || 40) > cullX);
            itemCapsules = itemCapsules.filter(c => !c.opened && c.x > cullX);

            // --- CÂMERA DINÂMICA COM ZOOM-OUT EM ALTA VELOCIDADE ---
            const speedRatio = Math.max(0, Math.min(1, (sonic.vx - WORLD.BASE_RUN_SPEED) / (WORLD.BOOST_SPEED - WORLD.BASE_RUN_SPEED)));
            const baseResponsiveScale = Math.min(1.05, Math.max(0.72, viewWidth / 1280));
            const targetZoom = baseResponsiveScale * (1.0 - speedRatio * 0.22);
            game.camera.zoom += (targetZoom - game.camera.zoom) * Math.min(1, dt * 5.5);

            const lookAheadX = (viewWidth * 0.26) / game.camera.zoom;
            game.camera.x = sonic.x + lookAheadX;

            const targetCamY = Math.min(WORLD.BASE_GROUND_Y - 120, sonic.y - 110);
            game.camera.y += (targetCamY - game.camera.y) * Math.min(1, dt * 6);

            // Atualiza HUD
            updateHUD();

            // Reseta flags de pressionamento instantâneo
            input.jumpJustPressed = false;
            input.boostJustPressed = false;
            input.slideJustPressed = false;
        }

        function updateHUD() {
            ui.hudRings.textContent = String(game.rings);
            if (game.rings === 0) {
                ui.hudRings.classList.add('rings-danger');
            } else {
                ui.hudRings.classList.remove('rings-danger');
            }

            const scoreInt = Math.floor(game.score);
            ui.hudScore.textContent = String(scoreInt).padStart(6, '0');
            if (scoreInt > highScore) {
                saveHighScore(scoreInt);
            }

            const kmh = Math.round((sonic.vx / WORLD.BASE_RUN_SPEED) * 210);
            ui.hudSpeed.textContent = String(kmh);

            const boostPct = Math.round(game.boostEnergy);
            ui.hudBoostFill.style.width = `${boostPct}%`;
            ui.hudBoostPct.textContent = `${boostPct}%`;
        }

        // ----------------------------------------------------------------------------
        // 9. RENDERIZAÇÃO VISUAL (ESTÉTICA MODERN SONIC: ROOFTOP RUN + SEASIDE HILL)
        // ----------------------------------------------------------------------------
        function drawBackground() {
            const w = viewWidth;
            const h = viewHeight;

            // 1. Céu Azul Vibrante estilo Sonic Moderno
            const skyGrad = ctx.createLinearGradient(0, 0, 0, h * 0.75);
            skyGrad.addColorStop(0, '#0047b3');
            skyGrad.addColorStop(0.45, '#0ea5e9');
            skyGrad.addColorStop(1, '#bae6fd');
            ctx.fillStyle = skyGrad;
            ctx.fillRect(0, 0, w, h);

            // Brilho solar no horizonte
            const sunX = w * 0.78;
            const sunY = h * 0.22;
            const sunGrad = ctx.createRadialGradient(sunX, sunY, 10, sunX, sunY, 220);
            sunGrad.addColorStop(0, 'rgba(255, 255, 240, 0.95)');
            sunGrad.addColorStop(0.25, 'rgba(254, 240, 138, 0.45)');
            sunGrad.addColorStop(1, 'rgba(254, 240, 138, 0)');
            ctx.fillStyle = sunGrad;
            ctx.beginPath();
            ctx.arc(sunX, sunY, 220, 0, Math.PI * 2);
            ctx.fill();

            // 2. Nuvens estilizadas com paralaxe lenta
            ctx.fillStyle = 'rgba(255, 255, 255, 0.82)';
            for (let i = 0; i < 6; i++) {
                const cloudSpan = 420;
                const cx = ((i * cloudSpan - game.camera.x * 0.04) % (w + 400) + (w + 400)) % (w + 400) - 200;
                const cy = h * (0.12 + (i % 3) * 0.07);
                ctx.beginPath();
                ctx.arc(cx, cy, 34, 0, Math.PI * 2);
                ctx.arc(cx + 28, cy - 10, 42, 0, Math.PI * 2);
                ctx.arc(cx + 64, cy, 32, 0, Math.PI * 2);
                ctx.fill();
            }

            // 3. Horizonte Oceânico Cintilante (Seaside Hill)
            const horizonY = h * 0.56;
            const seaGrad = ctx.createLinearGradient(0, horizonY, 0, h);
            seaGrad.addColorStop(0, '#0284c7');
            seaGrad.addColorStop(0.35, '#06b6d4');
            seaGrad.addColorStop(1, '#0369a1');
            ctx.fillStyle = seaGrad;
            ctx.fillRect(0, horizonY, w, h - horizonY);

            // Reflexos de ondas no mar
            ctx.fillStyle = 'rgba(255, 255, 255, 0.26)';
            for (let i = 0; i < 18; i++) {
                const waveX = ((i * 190 - game.camera.x * 0.12) % (w + 200) + (w + 200)) % (w + 200) - 100;
                const waveY = horizonY + 14 + (i % 6) * 24;
                const waveW = 45 + (i % 4) * 22;
                ctx.fillRect(waveX, waveY, waveW, 3);
            }

            // 4. Metrópole Costeira Futurista & Torres estilo Rooftop Run (Paralaxe Média)
            const bldgSpan = 260;
            const numBldgs = Math.ceil(w / bldgSpan) + 3;
            const startIdx = Math.floor((game.camera.x * 0.22) / bldgSpan);

            for (let i = 0; i < numBldgs; i++) {
                const idx = startIdx + i;
                const bx = idx * bldgSpan - game.camera.x * 0.22;
                const seed = Math.abs(idx * 73 + 19);
                const bh = 110 + (seed % 140);
                const bw = 95 + (seed % 55);
                const by = horizonY + 18 - bh;

                // Corpo branco/azulado do arranha-céu moderno
                ctx.fillStyle = seed % 2 === 0 ? '#e0f2fe' : '#f8fafc';
                ctx.fillRect(bx, by, bw, bh + 30);

                // Faixas de vidro azul ciano
                ctx.fillStyle = '#38bdf8';
                for (let wy = by + 16; wy < horizonY + 10; wy += 22) {
                    ctx.fillRect(bx + 12, wy, bw - 24, 9);
                }

                // Telhado terracota / cúpula estilo Spagonia (Rooftop Run)
                if (seed % 3 === 0) {
                    ctx.fillStyle = '#ea580c';
                    ctx.beginPath();
                    ctx.moveTo(bx - 6, by);
                    ctx.lineTo(bx + bw * 0.5, by - 36);
                    ctx.lineTo(bx + bw + 6, by);
                    ctx.closePath();
                    ctx.fill();
                } else {
                    // Antena futurista
                    ctx.fillStyle = '#0284c7';
                    ctx.fillRect(bx + bw * 0.5 - 3, by - 32, 6, 32);
                }
            }
        }

        // Desenha o terreno com padrão quadriculado clássico marrom/laranja e grama esmeralda
        function drawTerrain() {
            for (const seg of terrainSegments) {
                const { x, y, width, height, isFloating } = seg;

                // Base de terra quadriculada (estilo Green Hill / Seaside Hill)
                const tileSize = 36;
                ctx.save();
                ctx.beginPath();
                if (isFloating) {
                    ctx.roundRect(x, y, width, height, 10);
                } else {
                    ctx.rect(x, y, width, height);
                }
                ctx.clip();

                // Fundo marrom quente
                ctx.fillStyle = '#9a3412';
                ctx.fillRect(x, y, width, height);

                // Quadriculado laranja-âmbar
                ctx.fillStyle = '#d97706';
                const cols = Math.ceil(width / tileSize) + 1;
                const rows = Math.ceil(height / tileSize) + 1;
                for (let r = 0; r < rows; r++) {
                    for (let c = 0; c < cols; c++) {
                        if ((r + c) % 2 === 0) {
                            ctx.fillRect(x + c * tileSize, y + r * tileSize, tileSize, tileSize);
                        }
                    }
                }

                // Sombra de profundidade
                const dirtGrad = ctx.createLinearGradient(0, y, 0, y + height);
                dirtGrad.addColorStop(0, 'rgba(0,0,0,0.12)');
                dirtGrad.addColorStop(1, 'rgba(15, 23, 42, 0.65)');
                ctx.fillStyle = dirtGrad;
                ctx.fillRect(x, y, width, height);

                // Faixa superior de grama verde vibrante
                ctx.fillStyle = '#16a34a';
                ctx.fillRect(x, y, width, 16);
                ctx.fillStyle = '#4ade80';
                ctx.fillRect(x, y, width, 6);

                // Dentes triangulares na borda da grama
                ctx.fillStyle = '#15803d';
                for (let gx = x; gx < x + width; gx += 24) {
                    ctx.beginPath();
                    ctx.moveTo(gx, y + 16);
                    ctx.lineTo(gx + 12, y + 25);
                    ctx.lineTo(gx + 24, y + 16);
                    ctx.closePath();
                    ctx.fill();
                }

                ctx.restore();
            }
        }

        // Desenha Trilhos Metálicos de Grind
        function drawGrindRails() {
            for (const rail of grindRails) {
                // Pilares de sustentação
                ctx.fillStyle = '#334155';
                ctx.fillRect(rail.x + 24, rail.y + 8, 10, WORLD.BASE_GROUND_Y - rail.y);
                ctx.fillRect(rail.x + rail.width - 34, rail.y + 8, 10, WORLD.BASE_GROUND_Y - rail.y);

                // Barra metálica principal
                const railGrad = ctx.createLinearGradient(0, rail.y - 4, 0, rail.y + 10);
                railGrad.addColorStop(0, '#f8fafc');
                railGrad.addColorStop(0.5, '#38bdf8');
                railGrad.addColorStop(1, '#0369a1');
                ctx.fillStyle = railGrad;
                ctx.beginPath();
                ctx.roundRect(rail.x - 6, rail.y - 4, rail.width + 12, 12, 6);
                ctx.fill();

                // Pontas luminosas de entrada/saída
                ctx.fillStyle = '#facc15';
                ctx.beginPath();
                ctx.arc(rail.x, rail.y + 2, 7, 0, Math.PI * 2);
                ctx.arc(rail.x + rail.width, rail.y + 2, 7, 0, Math.PI * 2);
                ctx.fill();
            }
        }

        // Desenha Painéis de Impulso (Dash Pads) e Molas Vermelhas (Springs)
        function drawPadsAndSprings() {
            // Dash Pads
            for (const dp of dashPads) {
                ctx.fillStyle = '#0f172a';
                ctx.beginPath();
                ctx.roundRect(dp.x, dp.y - 10, dp.width, 10, 4);
                ctx.fill();

                // Setas animadas neon
                const pulse = Math.floor(game.time * 16) % 3;
                for (let i = 0; i < 3; i++) {
                    ctx.fillStyle = i === pulse ? '#ffffff' : '#00f2ff';
                    const ax = dp.x + 12 + i * 20;
                    ctx.beginPath();
                    ctx.moveTo(ax, dp.y - 8);
                    ctx.lineTo(ax + 12, dp.y - 5);
                    ctx.lineTo(ax, dp.y - 2);
                    ctx.closePath();
                    ctx.fill();
                }
            }

            // Molas Vermelhas
            for (const sp of springs) {
                const ext = sp.bounceAnim * 14;
                // Base metálica
                ctx.fillStyle = '#64748b';
                ctx.fillRect(sp.x - 14, sp.y - 8 - ext * 0.5, 28, 8);

                // Almofada vermelha com estrela amarela
                ctx.fillStyle = '#ef4444';
                ctx.beginPath();
                ctx.roundRect(sp.x - 20, sp.y - 20 - ext, 40, 13, 6);
                ctx.fill();

                ctx.fillStyle = '#facc15';
                ctx.beginPath();
                ctx.arc(sp.x, sp.y - 13.5 - ext, 5, 0, Math.PI * 2);
                ctx.fill();
            }
        }

        // Desenha Obstáculos (Portões de Laser Elevados e Barreiras Baixas)
        function drawObstacles() {
            for (const obs of obstacles) {
                if (obs.type === 'laserGate') {
                    // Emissor superior suspenso
                    ctx.fillStyle = '#1e293b';
                    ctx.strokeStyle = '#94a3b8';
                    ctx.lineWidth = 2;
                    ctx.beginPath();
                    ctx.roundRect(obs.x - 22, obs.y - 24, 44, 26, 6);
                    ctx.fill();
                    ctx.stroke();

                    // Feixe de plasma vermelho pulsante
                    const flicker = 0.75 + Math.sin(game.time * 30) * 0.25;
                    ctx.fillStyle = `rgba(244, 63, 94, ${0.35 * flicker})`;
                    ctx.fillRect(obs.x - 12, obs.y, 24, obs.beamBottomY - obs.y);

                    ctx.fillStyle = '#ffe4e6';
                    ctx.fillRect(obs.x - 4, obs.y, 8, obs.beamBottomY - obs.y);

                    // Indicador visual para deslizar por baixo
                    ctx.fillStyle = '#facc15';
                    ctx.font = '900 11px "Orbitron", sans-serif';
                    ctx.textAlign = 'center';
                    ctx.fillText('↓ DESLIZE', obs.x, obs.y - 30);
                } else if (obs.type === 'lowBarrier' && !obs.broken) {
                    // Barreira metálica rachada
                    ctx.fillStyle = '#475569';
                    ctx.strokeStyle = '#cbd5e1';
                    ctx.lineWidth = 2;
                    ctx.beginPath();
                    ctx.roundRect(obs.x, obs.y, obs.width, obs.height, 6);
                    ctx.fill();
                    ctx.stroke();

                    // Listras de alerta
                    ctx.fillStyle = '#f59e0b';
                    ctx.fillRect(obs.x + 6, obs.y + 8, obs.width - 12, 8);
                    ctx.fillRect(obs.x + 6, obs.y + 26, obs.width - 12, 8);
                }
            }
        }

        // Desenha Anéis Dourados Giratórios com Sombreamento 3D
        function drawSingleRing(x, y, phase, alpha = 1) {
            const spin = Math.abs(Math.cos(phase));
            const rx = Math.max(3.5, 13 * spin);
            const ry = 14;

            ctx.save();
            ctx.globalAlpha = alpha;
            ctx.translate(x, y);

            // Brilho externo
            ctx.shadowColor = '#facc15';
            ctx.shadowBlur = 10;

            // Aro dourado
            ctx.strokeStyle = '#f59e0b';
            ctx.lineWidth = 5;
            ctx.beginPath();
            ctx.ellipse(0, 0, rx, ry, 0, 0, Math.PI * 2);
            ctx.stroke();

            // Reflexo brilhante interno
            ctx.strokeStyle = '#fef08a';
            ctx.lineWidth = 2;
            ctx.beginPath();
            ctx.ellipse(-rx * 0.15, -1, rx * 0.85, ry * 0.85, 0, 0, Math.PI * 2);
            ctx.stroke();

            ctx.restore();
        }

        function drawRingsAndCapsules() {
            for (const r of rings) {
                if (!r.collected) {
                    drawSingleRing(r.x, r.y, r.phase, 1);
                }
            }

            for (const sr of scatteredRings) {
                const blink = sr.life < 1.2 ? (Math.floor(sr.life * 16) % 2 === 0 ? 0.35 : 1) : 1;
                drawSingleRing(sr.x, sr.y, sr.phase, blink);
            }

            // Cápsulas de Itens
            for (const cap of itemCapsules) {
                if (cap.opened) continue;
                ctx.save();
                ctx.translate(cap.x, cap.y);

                // Base metálica
                ctx.fillStyle = '#334155';
                ctx.fillRect(-16, 14, 32, 10);

                // Domo de vidro
                ctx.fillStyle = 'rgba(186, 230, 253, 0.35)';
                ctx.strokeStyle = '#38bdf8';
                ctx.lineWidth = 2.5;
                ctx.beginPath();
                ctx.arc(0, 0, 20, 0, Math.PI * 2);
                ctx.fill();
                ctx.stroke();

                // Ícone interno
                if (cap.kind === 'rings') {
                    ctx.strokeStyle = '#facc15';
                    ctx.lineWidth = 3.5;
                    ctx.beginPath();
                    ctx.arc(0, 0, 9, 0, Math.PI * 2);
                    ctx.stroke();
                } else {
                    ctx.fillStyle = '#00f2ff';
                    ctx.beginPath();
                    ctx.moveTo(2, -11);
                    ctx.lineTo(-7, 2);
                    ctx.lineTo(0, 2);
                    ctx.lineTo(-2, 11);
                    ctx.lineTo(7, -2);
                    ctx.lineTo(0, -2);
                    ctx.closePath();
                    ctx.fill();
                }

                ctx.restore();
            }
        }

        // Desenha Badniks (Motobug e Buzz Bomber)
        function drawBadniks() {
            for (const b of badniks) {
                if (!b.alive) continue;
                ctx.save();
                ctx.translate(b.x, b.y);

                if (b.type === 'motobug') {
                    // Roda inferior
                    ctx.fillStyle = '#1e293b';
                    ctx.beginPath();
                    ctx.arc(0, -10, 10, 0, Math.PI * 2);
                    ctx.fill();
                    ctx.strokeStyle = '#94a3b8';
                    ctx.lineWidth = 2;
                    ctx.stroke();

                    // Carapaça vermelha de joaninha robô
                    ctx.fillStyle = '#dc2626';
                    ctx.beginPath();
                    ctx.arc(0, -16, 22, Math.PI, 0);
                    ctx.closePath();
                    ctx.fill();

                    // Pintas pretas na carapaça
                    ctx.fillStyle = '#0f172a';
                    ctx.beginPath();
                    ctx.arc(-4, -26, 4, 0, Math.PI * 2);
                    ctx.arc(8, -23, 3.5, 0, Math.PI * 2);
                    ctx.fill();

                    // Cabeça azul escura e olho brilhante
                    ctx.fillStyle = '#1d4ed8';
                    ctx.beginPath();
                    ctx.arc(-18, -18, 9, 0, Math.PI * 2);
                    ctx.fill();

                    ctx.fillStyle = '#facc15';
                    ctx.beginPath();
                    ctx.arc(-21, -20, 3.2, 0, Math.PI * 2);
                    ctx.fill();
                } else if (b.type === 'buzzbomber') {
                    // Asas translúcidas vibrando
                    const wingFlap = Math.sin(b.anim * 4) * 8;
                    ctx.fillStyle = 'rgba(224, 242, 254, 0.75)';
                    ctx.beginPath();
                    ctx.ellipse(2, -34 + wingFlap * 0.4, 16, 7, -0.3, 0, Math.PI * 2);
                    ctx.fill();

                    // Abdômen amarelo e preto
                    ctx.fillStyle = '#facc15';
                    ctx.beginPath();
                    ctx.ellipse(12, -16, 14, 9, 0.25, 0, Math.PI * 2);
                    ctx.fill();
                    ctx.strokeStyle = '#0f172a';
                    ctx.lineWidth = 3;
                    ctx.stroke();

                    // Tórax e cabeça azul metálico
                    ctx.fillStyle = '#0284c7';
                    ctx.beginPath();
                    ctx.arc(-6, -20, 12, 0, Math.PI * 2);
                    ctx.fill();

                    // Olho vermelho agressivo
                    ctx.fillStyle = '#ef4444';
                    ctx.beginPath();
                    ctx.arc(-11, -22, 4, 0, Math.PI * 2);
                    ctx.fill();
                }

                ctx.restore();
            }
        }

        // Desenha a Mira do Ataque Teleguiado (Homing Attack Reticle)
        function drawHomingReticle() {
            const target = sonic.lockedTarget || sonic.homingTarget;
            if (!target) return;

            const tx = target.ref.x;
            const ty = target.kind === 'badnik' ? target.ref.y - 22 : target.ref.y;
            const rot = game.time * 5;
            const pulse = 1 + Math.sin(game.time * 18) * 0.14;

            ctx.save();
            ctx.translate(tx, ty);
            ctx.rotate(rot);
            ctx.scale(pulse, pulse);

            // Círculo externo verde-ciano brilhante
            ctx.strokeStyle = '#22c55e';
            ctx.lineWidth = 3;
            ctx.shadowColor = '#4ade80';
            ctx.shadowBlur = 14;
            ctx.beginPath();
            ctx.arc(0, 0, 30, 0, Math.PI * 2);
            ctx.stroke();

            // 4 Triângulos apontando para o centro
            ctx.fillStyle = '#ef4444';
            for (let i = 0; i < 4; i++) {
                ctx.rotate(Math.PI / 2);
                ctx.beginPath();
                ctx.moveTo(0, -18);
                ctx.lineTo(-6, -34);
                ctx.lineTo(6, -34);
                ctx.closePath();
                ctx.fill();
            }

            ctx.restore();
        }

        // Desenha o Sonic Moderno Vetorial Animado
        function drawModernSonic(x, y, isAfterimage = false, alpha = 1) {
            // Pisca durante invulnerabilidade pós-dano
            if (!isAfterimage && sonic.invulnTimer > 0 && Math.floor(sonic.invulnTimer * 18) % 2 === 0) {
                return;
            }

            ctx.save();
            ctx.translate(x, y);
            ctx.globalAlpha = alpha;

            const isBall = sonic.isRolling || sonic.isSliding || sonic.isHoming;

            // --- AURA DO BOOST (IMPULSO) ---
            if (!isAfterimage && (game.isBoosting || sonic.dashPadTimer > 0)) {
                ctx.save();
                const auraGrad = ctx.createLinearGradient(38, -26, -130, -26);
                auraGrad.addColorStop(0, 'rgba(255, 255, 255, 0.92)');
                auraGrad.addColorStop(0.3, 'rgba(0, 242, 255, 0.72)');
                auraGrad.addColorStop(1, 'rgba(0, 102, 255, 0)');
                ctx.fillStyle = auraGrad;

                // Cone aerodinâmico de energia sônica
                ctx.beginPath();
                ctx.moveTo(42, -26);
                ctx.quadraticCurveTo(12, -68, -135, -52);
                ctx.lineTo(-105, -26);
                ctx.lineTo(-135, 0);
                ctx.quadraticCurveTo(12, 14, 42, -26);
                ctx.closePath();
                ctx.fill();

                // Onda de choque inicial do Boost
                if (sonic.boostShockwave > 0) {
                    ctx.strokeStyle = `rgba(165, 243, 252, ${sonic.boostShockwave})`;
                    ctx.lineWidth = 4;
                    ctx.beginPath();
                    ctx.ellipse(10, -26, (1.1 - sonic.boostShockwave) * 70, (1.1 - sonic.boostShockwave) * 95, 0, 0, Math.PI * 2);
                    ctx.stroke();
                }
                ctx.restore();
            }

            // --- MODO BOLA DE SPIN / ATAQUE TELEGUIADO / DESLIZE ---
            if (isBall) {
                const ballY = sonic.isSliding ? -16 : -24;
                const radius = sonic.isSliding ? 17 : 22;

                // Rastro de energia azul
                ctx.fillStyle = isAfterimage ? '#00f2ff' : '#0284c7';
                ctx.beginPath();
                ctx.arc(0, ballY, radius + 3, 0, Math.PI * 2);
                ctx.fill();

                // Esfera principal azul royal
                ctx.fillStyle = isAfterimage ? '#38bdf8' : '#1d4ed8';
                ctx.beginPath();
                ctx.arc(0, ballY, radius, 0, Math.PI * 2);
                ctx.fill();

                // Espinhos girando em alta rotação
                ctx.save();
                ctx.translate(0, ballY);
                ctx.rotate(game.time * 28);
                ctx.strokeStyle = '#7dd3fc';
                ctx.lineWidth = 3.5;
                for (let i = 0; i < 3; i++) {
                    ctx.rotate((Math.PI * 2) / 3);
                    ctx.beginPath();
                    ctx.arc(0, 0, radius * 0.65, 0, Math.PI * 0.85);
                    ctx.stroke();
                }
                ctx.restore();

                ctx.restore();
                return;
            }

            // --- CORPO DO SONIC MODERNO EM CORRIDA / GRIND ---
            const speedFactor = Math.min(1, (sonic.vx - 300) / 800);
            const leanAngle = sonic.isGrinding ? -0.15 : 0.16 + speedFactor * 0.22;
            const bobY = sonic.isGrinding ? 0 : Math.abs(Math.sin(sonic.animFrame * 2)) * -4;

            ctx.translate(0, bobY);
            ctx.rotate(leanAngle);

            const blueMain = isAfterimage ? '#00f2ff' : '#1d4ed8';
            const blueHighlight = isAfterimage ? '#bae6fd' : '#3b82f6';
            const peachColor = isAfterimage ? '#7dd3fc' : '#fed7aa';

            // 1. Pernas e Tênis Vermelhos Icônicos
            if (sonic.isGrinding) {
                // Pose de surf/grind no trilho
                drawSonicShoe(-10, -4, -0.2, isAfterimage);
                drawSonicShoe(12, -6, 0.25, isAfterimage);
            } else if (speedFactor > 0.62) {
                // Efeito infinito (Figure-8) nos pés em velocidade supersônica!
                ctx.strokeStyle = isAfterimage ? '#38bdf8' : '#ef4444';
                ctx.lineWidth = 7;
                ctx.beginPath();
                const rot = sonic.animFrame * 3.2;
                ctx.ellipse(0, -10, 20, 9, 0.1, rot, rot + Math.PI * 1.4);
                ctx.stroke();

                ctx.strokeStyle = '#ffffff';
                ctx.lineWidth = 3;
                ctx.beginPath();
                ctx.ellipse(0, -10, 17, 7, 0.1, rot + 0.4, rot + Math.PI);
                ctx.stroke();
            } else {
                // Pernas articuladas em corrida
                const legPhase = sonic.animFrame * 2;
                const foot1X = Math.cos(legPhase) * 15;
                const foot1Y = -6 + Math.min(0, Math.sin(legPhase) * 9);
                const foot2X = Math.cos(legPhase + Math.PI) * 15;
                const foot2Y = -6 + Math.min(0, Math.sin(legPhase + Math.PI) * 9);

                ctx.strokeStyle = blueMain;
                ctx.lineWidth = 5;
                ctx.beginPath();
                ctx.moveTo(0, -24);
                ctx.lineTo(foot2X, foot2Y - 4);
                ctx.moveTo(0, -24);
                ctx.lineTo(foot1X, foot1Y - 4);
                ctx.stroke();

                drawSonicShoe(foot2X, foot2Y, Math.sin(legPhase + Math.PI) * 0.4, isAfterimage);
                drawSonicShoe(foot1X, foot1Y, Math.sin(legPhase) * 0.4, isAfterimage);
            }

            // 2. Torso esguio moderno + barriga pêssego
            ctx.fillStyle = blueMain;
            ctx.beginPath();
            ctx.ellipse(0, -30, 10, 13, 0.15, 0, Math.PI * 2);
            ctx.fill();

            ctx.fillStyle = peachColor;
            ctx.beginPath();
            ctx.ellipse(4, -30, 6, 9, 0.15, 0, Math.PI * 2);
            ctx.fill();

            // 3. Braços e Luvas Brancas estendidas para trás em velocidade
            ctx.strokeStyle = peachColor;
            ctx.lineWidth = 4;
            ctx.beginPath();
            ctx.moveTo(-2, -36);
            ctx.lineTo(-20 - speedFactor * 8, -32 + Math.sin(sonic.animFrame * 2) * 4);
            ctx.stroke();

            ctx.fillStyle = isAfterimage ? '#e0f2fe' : '#ffffff';
            ctx.beginPath();
            ctx.arc(-22 - speedFactor * 8, -32 + Math.sin(sonic.animFrame * 2) * 4, 5.5, 0, Math.PI * 2);
            ctx.fill();

            // 4. Cabeça e os 3 Espinhos Aerodinâmicos (Quills)
            const quillFlutter = Math.sin(game.time * 24) * 2.5;
            ctx.fillStyle = blueMain;

            // Espinho superior
            ctx.beginPath();
            ctx.moveTo(2, -56);
            ctx.quadraticCurveTo(-18, -62, -34 - speedFactor * 10, -50 + quillFlutter);
            ctx.lineTo(-10, -45);
            ctx.closePath();
            ctx.fill();

            // Espinho médio
            ctx.beginPath();
            ctx.moveTo(0, -48);
            ctx.quadraticCurveTo(-20, -50, -36 - speedFactor * 12, -38 - quillFlutter);
            ctx.lineTo(-10, -38);
            ctx.closePath();
            ctx.fill();

            // Espinho inferior
            ctx.beginPath();
            ctx.moveTo(-2, -41);
            ctx.quadraticCurveTo(-18, -40, -30 - speedFactor * 8, -29 + quillFlutter);
            ctx.lineTo(-8, -33);
            ctx.closePath();
            ctx.fill();

            // Crânio principal
            ctx.beginPath();
            ctx.arc(3, -47, 13.5, 0, Math.PI * 2);
            ctx.fill();

            // Brilho superior nos espinhos
            ctx.strokeStyle = blueHighlight;
            ctx.lineWidth = 2;
            ctx.beginPath();
            ctx.arc(3, -47, 11.5, -Math.PI * 0.85, -Math.PI * 0.25);
            ctx.stroke();

            // Orelha triangular
            ctx.fillStyle = blueMain;
            ctx.beginPath();
            ctx.moveTo(-2, -57);
            ctx.lineTo(2, -66);
            ctx.lineTo(8, -56);
            ctx.closePath();
            ctx.fill();

            if (!isAfterimage) {
                // Focinho pêssego e nariz preto
                ctx.fillStyle = peachColor;
                ctx.beginPath();
                ctx.ellipse(12, -43, 8.5, 5.5, 0, 0, Math.PI * 2);
                ctx.fill();

                ctx.fillStyle = '#0f172a';
                ctx.beginPath();
                ctx.ellipse(20, -44, 3, 2, 0, 0, Math.PI * 2);
                ctx.fill();

                // Olho verde esmeralda moderno determinado
                ctx.fillStyle = '#ffffff';
                ctx.beginPath();
                ctx.ellipse(10, -49, 5.5, 7, -0.15, 0, Math.PI * 2);
                ctx.fill();

                ctx.fillStyle = '#10b981';
                ctx.beginPath();
                ctx.ellipse(12, -49, 2.6, 4.4, -0.1, 0, Math.PI * 2);
                ctx.fill();

                ctx.fillStyle = '#0f172a';
                ctx.beginPath();
                ctx.ellipse(12.5, -49, 1.4, 2.6, -0.1, 0, Math.PI * 2);
                ctx.fill();
            }

            ctx.restore();
        }

        function drawSonicShoe(sx, sy, angle, isAfterimage) {
            ctx.save();
            ctx.translate(sx, sy);
            ctx.rotate(angle);

            // Sapato vermelho
            ctx.fillStyle = isAfterimage ? '#38bdf8' : '#ef4444';
            ctx.beginPath();
            ctx.ellipse(3, -3, 11, 5.5, 0, 0, Math.PI * 2);
            ctx.fill();

            // Faixa branca e fivela dourada
            if (!isAfterimage) {
                ctx.fillStyle = '#ffffff';
                ctx.fillRect(0, -8, 4.5, 10);
                ctx.fillStyle = '#facc15';
                ctx.fillRect(3.5, -5, 3, 4);
            }

            ctx.restore();
        }

        // Desenha Partículas e Textos Flutuantes
        function drawParticlesAndTexts() {
            for (const p of particles) {
                ctx.save();
                ctx.globalAlpha = p.alpha;
                ctx.fillStyle = p.color;
                ctx.beginPath();
                ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
                ctx.fill();
                ctx.restore();
            }

            for (const ft of floatingTexts) {
                ctx.save();
                ctx.globalAlpha = Math.min(1, ft.life / ft.maxLife * 1.3);
                ctx.font = '900 18px "Orbitron", sans-serif';
                ctx.textAlign = 'center';
                ctx.fillStyle = '#0f172a';
                ctx.fillText(ft.text, ft.x + 2, ft.y + 2);
                ctx.fillStyle = ft.color;
                ctx.fillText(ft.text, ft.x, ft.y);
                ctx.restore();
            }
        }

        // Desenha Linhas de Velocidade estilo Anime nas bordas da tela em alta velocidade
        function drawSpeedLines() {
            const speedRatio = (sonic.vx - WORLD.BASE_RUN_SPEED) / (WORLD.BOOST_SPEED - WORLD.BASE_RUN_SPEED);
            if (speedRatio <= 0.25 && !game.isBoosting) return;

            const intensity = game.isBoosting ? 0.85 : Math.min(0.65, (speedRatio - 0.25) * 0.9);
            const cx = viewWidth * 0.5;
            const cy = viewHeight * 0.5;
            const maxRadius = Math.hypot(cx, cy);

            ctx.save();
            for (const line of game.speedLines) {
                const cycle = (game.time * line.speed + line.offset) % 1;
                const innerR = maxRadius * (0.58 + (1 - cycle) * 0.25);
                const outerR = maxRadius * 1.15;

                const x1 = cx + Math.cos(line.angle) * innerR;
                const y1 = cy + Math.sin(line.angle) * innerR;
                const x2 = cx + Math.cos(line.angle) * outerR;
                const y2 = cy + Math.sin(line.angle) * outerR;

                const grad = ctx.createLinearGradient(x1, y1, x2, y2);
                grad.addColorStop(0, 'rgba(255, 255, 255, 0)');
                grad.addColorStop(0.5, `rgba(186, 230, 253, ${intensity * 0.65})`);
                grad.addColorStop(1, `rgba(255, 255, 255, ${intensity})`);

                ctx.strokeStyle = grad;
                ctx.lineWidth = line.width;
                ctx.beginPath();
                ctx.moveTo(x1, y1);
                ctx.lineTo(x2, y2);
                ctx.stroke();
            }
            ctx.restore();
        }

        function render() {
            ctx.clearRect(0, 0, viewWidth, viewHeight);

            // 1. Cenário de fundo com paralaxe
            drawBackground();

            // 2. Câmera do mundo com Zoom Dinâmico e Screen Shake
            ctx.save();
            const shakeX = game.camera.shake > 0 ? (Math.random() - 0.5) * game.camera.shake : 0;
            const shakeY = game.camera.shake > 0 ? (Math.random() - 0.5) * game.camera.shake : 0;

            ctx.translate(viewWidth * 0.5 + shakeX, viewHeight * 0.58 + shakeY);
            ctx.scale(game.camera.zoom, game.camera.zoom);
            ctx.translate(-game.camera.x, -game.camera.y);

            // Elementos do mundo
            drawTerrain();
            drawGrindRails();
            drawPadsAndSprings();
            drawObstacles();
            drawRingsAndCapsules();
            drawBadniks();

            // Pós-imagens de velocidade do Sonic
            for (const ai of sonic.afterimages) {
                drawModernSonic(ai.x, ai.y, true, ai.alpha * 0.55);
            }

            // Personagem principal (Sonic Moderno)
            if (game.state === 'PLAYING') {
                drawModernSonic(sonic.x, sonic.y, false, 1);
                drawHomingReticle();
            }

            // Partículas e pontuações flutuantes
            drawParticlesAndTexts();

            ctx.restore();

            // 3. Efeitos de tela (Linhas de velocidade anime nas bordas)
            if (game.state === 'PLAYING') {
                drawSpeedLines();
            }
        }

        // ----------------------------------------------------------------------------
        // 10. LOOP PRINCIPAL DE ANIMAÇÃO (WINDOW.ONLOAD)
        // ----------------------------------------------------------------------------
        let lastTimestamp = 0;

        function gameLoop(timestamp) {
            if (!lastTimestamp) lastTimestamp = timestamp;
            const rawDt = (timestamp - lastTimestamp) / 1000;
            lastTimestamp = timestamp;

            // Limita dt para evitar saltos físicos em trocas de aba
            const dt = Math.min(rawDt, 0.05);

            // Sub-steps para colisão precisa mesmo em velocidades de Boost acima de 450 km/h
            const steps = 2;
            const subDt = dt / steps;
            for (let i = 0; i < steps; i++) {
                update(subDt);
            }

            render();
            requestAnimationFrame(gameLoop);
        }

        window.onload = function () {
            resizeCanvas();
            requestAnimationFrame(gameLoop);
        };
    </script>
</body>
</html>
