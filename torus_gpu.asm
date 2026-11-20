; ============================================================================
; Win64 Pure x86-64 Assembly + OpenGL GLSL Raymarcher Demoscene Music Player
; Features:
;   - Fast single-pass raymarcher with bounding-sphere early-out & dFdx/dFdy CA
;   - 32-channel, 28-segment LED demoscene VU meter / spectrum in background
;   - Macro-warped, bending & undulating chrome torus SDF (space warping)
;   - Auto-advances to the next track when the current track finishes
;   - Top player bar with Prev, right-pointing Play/Pause, Next,
;     interactive Seek bar (gyorstekero), and Speaker Mute + Volume slider
;   - HUD hidden by default ([H] toggles 5 visual sliders)
;   - Crisp 5x7 bitmap font in GLSL 1.20 (packed vec4 uniform arrays)
; ============================================================================

[BITS 64]
default rel

%define MAX_TRACKS 32
%define MAX_SCROLL 192      ; 48 * vec4

extern GetModuleHandleA
extern RegisterClassExA
extern CreateWindowExA
extern PeekMessageA
extern TranslateMessage
extern DispatchMessageA
extern DefWindowProcA
extern PostQuitMessage
extern GetDC
extern ReleaseDC
extern ChoosePixelFormat
extern SetPixelFormat
extern SwapBuffers
extern GetClientRect
extern MessageBoxA
extern ExitProcess
extern FindFirstFileA
extern FindNextFileA
extern FindClose
extern lstrcpyA
extern lstrcatA

extern wglCreateContext
extern wglMakeCurrent
extern wglGetProcAddress
extern glViewport
extern glRectf

extern mciSendStringA
extern mciGetErrorStringA

section .data
    class_name  db "DemoTorus64kSOTA", 0
    win_title   db "x86-64 ASM Demoscene Player | [N/P] Track  [SPACE] Pause  [H] HUD  [M] Mute  [ESC] Exit", 0
    err_title   db "GLSL Shader Compile Error", 0
    mci_err_ttl db "MCI Audio Error", 0

    music_pattern   db "music\*.mp3", 0
    music_prefix    db "music\", 0
    mci_open_head   db 'open "', 0
    mci_open_tail   db '" type mpegvideo alias bgm', 0
    mci_open_plain  db '" alias bgm', 0
    mci_tf_cmd      db "set bgm time format milliseconds", 0
    mci_play_once   db "play bgm", 0
    mci_pause_cmd   db "pause bgm", 0
    mci_seek_head   db "seek bgm to ", 0
    mci_pos_cmd     db "status bgm position", 0
    mci_len_cmd     db "status bgm length", 0
    mci_mode_cmd    db "status bgm mode", 0
    mci_close_cmd   db "close bgm", 0
    vol_cmd_buf     db "setaudio bgm volume to "
    vol_num_buf     db "800", 0, 0, 0, 0, 0

    ; 8 demoscene zene kulcsai + pontos metaadatok
    meta_cyber      db "cyberride", 0
    info_cyber      db "TRACK: CYBERRIDE // DEMO: EXTENSION // HW: AMIGA // AUTHOR: JESTER (SANITY) // SCENE: PYGMY PROJECTS // YEAR: 1993", 0
    tag_cyber       db "CYBERRIDE", 0

    meta_aglow      db "aglow", 0
    info_aglow      db "TRACK: AGLOW // DEMO: MINDFLOW // HW: AMIGA // AUTHOR: STROBO // SCENE: STELLAR // YEAR: 1994", 0
    tag_aglow       db "AGLOW", 0

    meta_decalogue  db "decalogue", 0
    info_decalogue  db "TRACK: THE DECALOGUE // DEMO: CRYSTAL DREAM 2 // HW: PC // AUTHOR: VOGUE // SCENE: TRITON // YEAR: 1993", 0
    tag_decalogue   db "THE DECALOGUE", 0

    meta_insanity   db "livininsanity", 0
    info_insanity   db "TRACK: LIVIN' INSANITY // DEMO: FASTTRACKER 2 // HW: PC // AUTHOR: DUNE // SCENE: ORANGE / REBELS // YEAR: 1996", 0
    tag_insanity    db "LIVIN' INSANITY", 0

    meta_nexus7     db "nexusseven", 0
    info_nexus7     db "TRACK: NEXUS 7 // DEMO: NEXUS 7 // HW: AMIGA // AUTHOR: MOBY // SCENE: ANDROMEDA // YEAR: 1994", 0
    tag_nexus7      db "NEXUS 7", 0

    meta_stardust   db "stardust", 0
    info_stardust   db "TRACK: STARDUST // DEMO: STARDUST // HW: PC // AUTHOR: SKAVEN // SCENE: FUTURE CREW // YEAR: 1992", 0
    tag_stardust    db "STARDUST", 0

    meta_2nd2       db "secondreality", 0
    info_2nd2       db "TRACK: SECOND REALITY II // DEMO: SECOND REALITY // HW: PC // AUTHOR: PURPLE MOTION & SKAVEN // SCENE: FUTURE CREW // YEAR: 1993", 0
    tag_2nd2        db "SECOND REALITY II", 0

    meta_sota       db "stateoftheart", 0
    info_sota       db "TRACK: STATE OF THE ART // DEMO: STATE OF THE ART // HW: AMIGA // AUTHOR: TRAVOLTA // SCENE: SPACEBALLS // YEAR: 1992", 0
    tag_sota        db "STATE OF THE ART", 0

    lbl_track       db "TRACK: ", 0
    lbl_empty       db "NO MP3 IN MUSIC FOLDER // ADD MP3 TO MUSIC SUBDIR // DEMO: CHROME TORUS // HW: WIN64 X86-64 // AUTHOR: KAROLYIA79 // SCENE: DEMOSCENE // YEAR: 2026", 0
    lbl_tail        db " // DEMO: DEMOSCENE ARCHIVE // HW: RETRO & PC // SCENE: DEMOSCENE", 0
    tag_empty       db "NO MP3", 0

    fn_glCreateShader       db "glCreateShader", 0
    fn_glShaderSource       db "glShaderSource", 0
    fn_glCompileShader      db "glCompileShader", 0
    fn_glGetShaderiv        db "glGetShaderiv", 0
    fn_glGetShaderInfoLog   db "glGetShaderInfoLog", 0
    fn_glCreateProgram      db "glCreateProgram", 0
    fn_glAttachShader       db "glAttachShader", 0
    fn_glLinkProgram        db "glLinkProgram", 0
    fn_glUseProgram         db "glUseProgram", 0
    fn_glGetUniformLocation db "glGetUniformLocation", 0
    fn_glUniform1f          db "glUniform1f", 0
    fn_glUniform1i          db "glUniform1i", 0
    fn_glUniform2f          db "glUniform2f", 0
    fn_glUniform4f          db "glUniform4f", 0
    fn_glUniform4fv         db "glUniform4fv", 0

    u_time_name       db "u_time", 0
    u_res_name        db "u_res", 0
    u_phases_name     db "u_phases", 0
    u_sliders_name    db "u_sliders", 0
    u_extra_name      db "u_extra", 0
    u_player_name     db "u_player", 0
    u_scroll_name     db "u_scroll", 0
    u_scroll_len_name db "u_scroll_len", 0
    u_top_name        db "u_top", 0
    u_top_len_name    db "u_top_len", 0

    align 8
    wndclass:
        dd 80
        dd 0x23
        dq WndProc
        dd 0, 0
        dq 0, 0, 0, 0, 0
        dq class_name
        dq 0

    align 4
    pfd:
        dw 40
        dw 1
        dd 0x25
        db 0
        db 32
        db 0,0,0,0,0,0,0,0,0,0,0,0,0
        db 24
        db 8
        db 0,0,0,0,0,0

    time        dd 0.0
    dt_step     dd 0.016
    rot_phase   dd 0.0
    mag_phase   dd 0.0

    ; HUD sliderek (5 db)
    slider0     dd 0.21         ; 0. ROT SPD
    slider1     dd 0.18         ; 1. AMBIENT
    slider2     dd 0.34         ; 2. MAG SPD
    slider3     dd 0.42         ; 3. MAG PWR
    slider4     dd 0.65         ; 4. SPIKES

    ; Player sav hangero (kulon a felso savban)
    vol_level   dd 0.80
    saved_vol   dd 0.80
    muted_flag  dd 0
    last_vol_i  dd -1

    max_rot_spd dd 2.0
    max_mag_spd dd 5.0

    hud_visible dd 0.0          ; Alapbol rejtve ([H] gomb kapcsolja)
    drag_mode   dd 0            ; 0=none, 1=HUD slider, 2=seek bar, 3=volume bar
    active_sldr dd -1
    paused_flag dd 0

    c_neg1      dd -1.0
    c_pos1      dd 1.0
    c_zero      dd 0.0
    c_1000      dd 1000.0
    c_space_f   dd 32.0
    bass_env    dd 0.0

    track_count  dd 0
    cur_track    dd 0
    track_pos_ms dd 0
    track_len_ms dd 0
    scroll_len   dd 0
    top_len      dd 0

    align 8
    hInstance    dq 0
    hwnd         dq 0
    hdc          dq 0
    hglrc        dq 0
    hFind        dq 0
    msg          times 48 db 0
    rect         times 4 dd 0
    find_data    times 320 db 0
    mci_cmd_buf  times 320 db 0
    mci_ret_buf  times 64 db 0
    mci_err_buf  times 256 db 0
    scroller_txt times 256 db 0
    top_txt      times 64 db 0
    u_scroll_arr times MAX_SCROLL dd 32.0
    u_top_arr    times 32 dd 32.0

    tracks_buf   times (MAX_TRACKS * 128) db 0

    shader_ok    dd 0
    shader_log   times 512 db 0

    glCreateShader       dq 0
    glShaderSource       dq 0
    glCompileShader      dq 0
    glGetShaderiv        dq 0
    glGetShaderInfoLog   dq 0
    glCreateProgram      dq 0
    glAttachShader       dq 0
    glLinkProgram        dq 0
    glUseProgram         dq 0
    glGetUniformLocation dq 0
    glUniform1f          dq 0
    glUniform1i          dq 0
    glUniform2f          dq 0
    glUniform4f          dq 0
    glUniform4fv         dq 0

    prog_id          dd 0
    u_time_loc       dd 0
    u_res_loc        dd 0
    u_phases_loc     dd 0
    u_sliders_loc    dd 0
    u_extra_loc      dd 0
    u_player_loc     dd 0
    u_scroll_loc     dd 0
    u_scroll_len_loc dd 0
    u_top_loc        dd 0
    u_top_len_loc    dd 0

    real_rot_spd   dd 0.0
    real_mag_spd   dd 0.0
    pos_ms_f       dd 0.0
    len_ms_f       dd 0.0
    paused_f       dd 0.0
    muted_f        dd 0.0

    frag_shader_src:
        db "#version 120", 10
        db "uniform float u_time;", 10
        db "uniform vec2 u_res;", 10
        db "uniform vec2 u_phases;", 10
        db "uniform vec4 u_sliders;", 10
        db "uniform vec4 u_extra;", 10
        db "uniform vec4 u_player;", 10
        db "uniform vec4 u_scroll[48];", 10
        db "uniform int u_scroll_len;", 10
        db "uniform vec4 u_top[8];", 10
        db "uniform int u_top_len;", 10
        db "mat2 rot(float a){float s=sin(a),c=cos(a);return mat2(c,-s,s,c);}", 10
        db "float gyroid(vec3 p, float f, float ph){", 10
        db "  vec3 a=p*f+ph, b=p*f-ph;", 10
        db "  return sin(a.x)*cos(b.y)+sin(a.y)*cos(b.z)+sin(a.z)*cos(b.x);", 10
        db "}", 10
        db "float spikeField(vec3 p){", 10
        db "  vec3 wp=p+0.20*vec3(sin(p.y*3.2+u_time*2.2),cos(p.z*3.2-u_time*2.2),sin(p.x*3.2+u_time*2.2));", 10
        db "  float g1=max(0.0, gyroid(wp, 7.2, u_time*2.8)*0.6667);", 10
        db "  float g2=max(0.0, gyroid(wp.yzx, 13.0, -u_time*3.5)*0.6667);", 10
        db "  float s1=g1*g1*g1;", 10
        db "  float s2=g2*g2*g2*0.4;", 10
        db "  return (s1+s2)*u_extra.y*u_extra.z;", 10
        db "}", 10
        db "vec3 magPos(float th, float a){", 10
        db "  vec3 p=vec3(1.22*(1.0-cos(th)),1.22*sin(th),0.0);", 10
        db "  mat2 rA=rot(-a);", 10
        db "  p.yz*=rA; p.xz*=rA;", 10
        db "  return p;", 10
        db "}", 10
        db "vec3 cubePos(float th, float a){", 10
        db "  float oppTh=th+3.14159265;", 10
        db "  vec3 p=vec3(1.22*(1.0-cos(oppTh)), -1.22*sin(oppTh), 0.42);", 10
        db "  mat2 rA=rot(-a);", 10
        db "  p.yz*=rA; p.xz*=rA;", 10
        db "  return p;", 10
        db "}", 10
        db "float sdRoundBox(vec3 p, vec3 b, float r){", 10
        db "  vec3 q=abs(p)-b;", 10
        db "  return length(max(q,0.0))+min(max(q.x,max(q.y,q.z)),0.0)-r;", 10
        db "}", 10
        db "float mapTorus(vec3 p){", 10
        db "  float a=u_phases.x;", 10
        db "  float bass=u_extra.y;", 10
        db "  mat2 rA=rot(a);", 10
        db "  p.xz*=rA; p.yz*=rA;", 10
        db "  float bendAmp=0.18+0.16*bass;", 10
        db "  p.x+=bendAmp*sin(p.y*2.4+u_time*2.6);", 10
        db "  p.z+=bendAmp*cos(p.y*2.4-u_time*2.1);", 10
        db "  float waveAmp=0.22+0.20*bass;", 10
        db "  float ringWave=sin(p.x*2.1+u_time*2.9)*cos(p.z*2.1-u_time*2.3)+0.45*sin((p.x-p.z)*1.8-u_time*3.4);", 10
        db "  p.y+=waveAmp*ringWave;", 10
        db "  float lobe=sin(p.x*2.3-u_time*2.5)+cos(p.z*2.3+u_time*2.7);", 10
        db "  float majorR=1.15*(1.0+0.04*bass)+(0.09+0.07*bass)*lobe;", 10
        db "  float tubeWave=sin(p.x*3.1+p.z*2.7+u_time*4.2);", 10
        db "  float minorR=0.42+(0.045+0.045*bass)*tubeWave;", 10
        db "  float d=length(vec2(length(p.xz)-majorR,p.y))-minorR;", 10
        db "  if(d<0.28){", 10
        db "    float sp=spikeField(p);", 10
        db "    float orgMix=clamp(1.0 - sp*3.2, 0.22, 1.0);", 10
        db "    float wp=u_time*(1.55 + 0.45*orgMix);", 10
        db "    vec3 w=p+(0.24+0.18*orgMix)*vec3(sin(p.y*3.4+wp),cos(p.z*3.4-wp),sin(p.x*3.4+wp));", 10
        db "    float a1=(0.015+0.006*sin(u_time*1.13))*orgMix;", 10
        db "    float a2=(0.007+0.003*cos(u_time*1.89))*orgMix;", 10
        db "    float a3=(0.0035*sin(u_time*2.7))*orgMix;", 10
        db "    d+=gyroid(w,5.8,u_time*1.9)*a1;", 10
        db "    d+=gyroid(w.yzx,12.7,-u_time*2.75)*a2;", 10
        db "    d+=gyroid(w.zxy,23.1,u_time*3.4)*a3;", 10
        db "    d-=sp*0.095;", 10
        db "  }", 10
        db "  return d;", 10
        db "}", 10
        db "float mapCube(vec3 p){", 10
        db "  float a=u_phases.x, th=u_phases.y;", 10
        db "  vec3 cp=cubePos(th, a);", 10
        db "  vec3 q=p-cp;", 10
        db "  q.xy*=rot(u_time*1.3); q.yz*=rot(-u_time*0.95);", 10
        db "  return sdRoundBox(q, vec3(0.16), 0.02);", 10
        db "}", 10
        db "float map(vec3 p){", 10
        db "  return min(mapTorus(p), mapCube(p));", 10
        db "}", 10
        ; --- Gyors 4-pontos tetraeder normalvektor (6 helyett 4 map hivas) ---
        db "vec3 calcNormal(vec3 p){", 10
        db "  vec2 e=vec2(0.003,-0.003);", 10
        db "  return normalize(e.xyy*map(p+e.xyy)+e.yyx*map(p+e.yyx)+e.yxy*map(p+e.yxy)+e.xxx*map(p+e.xxx));", 10
        db "}", 10
        db "float calcSoftShadow(vec3 ro, vec3 rd, float maxd){", 10
        db "  float res=1.0, t=0.04;", 10
        db "  for(int i=0;i<12;i++){", 10
        db "    float h=map(ro+rd*t);", 10
        db "    res=min(res, 7.0*h/t);", 10
        db "    t+=clamp(h*0.60, 0.02, 0.22);", 10
        db "    if(res<0.01 || t>maxd) break;", 10
        db "  }", 10
        db "  return clamp(res, 0.0, 1.0);", 10
        db "}", 10
        db "float calcAO(vec3 p, vec3 n){", 10
        db "  float occ=0.0, sca=1.0;", 10
        db "  for(int i=1;i<=3;i++){", 10
        db "    float hr=0.03*float(i);", 10
        db "    float d=map(p+n*hr);", 10
        db "    occ+=(hr-d)*sca; sca*=0.7;", 10
        db "  }", 10
        db "  return clamp(1.0-3.2*occ, 0.0, 1.0);", 10
        db "}", 10
        db "vec3 envReflect(vec3 r, vec3 lm, float magI, float bass){", 10
        db "  float hy=clamp(r.y*0.5+0.5, 0.0, 1.0);", 10
        db "  vec3 e=mix(vec3(0.06,0.09,0.16), vec3(0.62,0.78,0.98), hy);", 10
        db "  float band=0.5+0.5*sin(r.x*8.0+r.y*10.0+u_time*1.5);", 10
        db "  e+=vec3(0.18,0.24,0.32)*band*band;", 10
        db "  vec3 ldir=normalize(lm);", 10
        db "  float sun=pow(max(dot(normalize(r), ldir), 0.0), 32.0);", 10
        db "  e+=vec3(1.6,2.1,2.6)*magI*sun*(0.7+0.3*bass);", 10
        db "  return e;", 10
        db "}", 10
        ; --- 32 csatornas, 28 szegmenses hatter LED VU-meter ---
        db "vec3 vuMeter(float sPx, float sPy){", 10
        db "  float vuX0=28.0;", 10
        db "  float vuX1=u_res.x-28.0;", 10
        db "  float vuW=max(vuX1-vuX0, 1.0);", 10
        db "  float vuTop=54.0;", 10
        db "  float vuBot=u_res.y-66.0;", 10
        db "  float vuH=max(vuBot-vuTop, 1.0);", 10
        db "  if(sPx<vuX0 || sPx>vuX1 || sPy<vuTop || sPy>vuBot) return vec3(0.0);", 10
        db "  float chPos=((sPx-vuX0)/vuW)*32.0;", 10
        db "  float chIdx=floor(chPos);", 10
        db "  float chFrac=fract(chPos);", 10
        db "  if(chFrac<0.15 || chFrac>0.85) return vec3(0.0);", 10
        db "  float hNorm=(vuBot-sPy)/vuH;", 10
        db "  float segPos=hNorm*28.0;", 10
        db "  float segIdx=floor(segPos);", 10
        db "  float segFrac=fract(segPos);", 10
        db "  if(segFrac<0.22 || segFrac>0.84) return vec3(0.0);", 10
        db "  float isAct=(u_player.y>0.5 && u_player.z<0.5 && u_extra.w<0.5)?1.0:0.0;", 10
        db "  float tSec=u_player.x*0.001;", 10
        db "  float bass=u_extra.y;", 10
        db "  float volScale=0.25+0.75*clamp(u_player.w,0.0,1.0);", 10
        db "  float band=chIdx/31.0;", 10
        db "  float subW=exp(-band*7.5);", 10
        db "  float midW=exp(-pow((band-0.42)*3.4,2.0));", 10
        db "  float hiW=exp(-pow((band-0.84)*4.2,2.0));", 10
        db "  float beat1=pow(0.5+0.5*sin(tSec*14.4+chIdx*0.55),3.0);", 10
        db "  float beat2=pow(0.5+0.5*cos(tSec*9.6-chIdx*0.85+sin(tSec*2.4)*1.5),4.0);", 10
        db "  float arp=0.5+0.5*sin(tSec*21.6+floor(mod(tSec*7.2+chIdx*0.37,8.0))*1.3);", 10
        db "  float hiHat=pow(0.5+0.5*sin(tSec*28.8+chIdx*1.9),7.0);", 10
        db "  float lvl=bass*(0.88*subW+0.28*midW)+midW*(0.42*beat1+0.32*arp)+hiW*(0.52*hiHat+0.30*beat2);", 10
        db "  lvl=clamp(lvl*volScale*isAct, 0.0, 0.98);", 10
        db "  float peakLvl=clamp(lvl+0.07*isAct*(0.5+0.5*sin(tSec*6.0+chIdx)), 0.0, 0.99);", 10
        db "  float litSeg=floor(lvl*28.0);", 10
        db "  float peakSeg=floor(peakLvl*28.0);", 10
        db "  vec3 ledCol=mix(vec3(0.08,0.58,0.92), vec3(0.18,0.92,0.68), clamp(hNorm*1.6,0.0,1.0));", 10
        db "  ledCol=mix(ledCol, vec3(1.0,0.76,0.18), smoothstep(0.55,0.82,hNorm));", 10
        db "  ledCol=mix(ledCol, vec3(1.0,0.24,0.36), smoothstep(0.82,0.96,hNorm));", 10
        db "  if(segIdx<=litSeg && isAct>0.5){", 10
        db "    return ledCol*(0.55+0.30*bass);", 10
        db "  }", 10
        db "  if(abs(segIdx-peakSeg)<0.5 && isAct>0.5 && peakSeg>0.5){", 10
        db "    return ledCol*0.85;", 10
        db "  }", 10
        db "  return vec3(0.022,0.038,0.068);", 10
        db "}", 10
        db "float glyph(int ch, vec2 p){", 10
        db "  int col=int(floor(p.x));", 10
        db "  int row=int(floor(p.y));", 10
        db "  if(col<0||col>4||row<0||row>6) return 0.0;", 10
        db "  vec2 m=vec2(0.0);", 10
        db "  if(ch==38) m=vec2(412053.0,19021.0);", 10
        db "  if(ch==39) m=vec2(135296.0,0.0);", 10
        db "  if(ch==40) m=vec2(69896.0,8322.0);", 10
        db "  if(ch==41) m=vec2(266306.0,2184.0);", 10
        db "  if(ch==44) m=vec2(0.0,4232.0);", 10
        db "  if(ch==45) m=vec2(14.0,0.0);", 10
        db "  if(ch==46) m=vec2(0.0,132.0);", 10
        db "  if(ch==47) m=vec2(34884.0,8464.0);", 10
        db "  if(ch==48) m=vec2(476789.0,26158.0);", 10
        db "  if(ch==49) m=vec2(143492.0,4238.0);", 10
        db "  if(ch==50) m=vec2(476198.0,8735.0);", 10
        db "  if(ch==51) m=vec2(476198.0,1582.0);", 10
        db "  if(ch==52) m=vec2(103729.0,31777.0);", 10
        db "  if(ch==53) m=vec2(1033153.0,1582.0);", 10
        db "  if(ch==54) m=vec2(476113.0,17966.0);", 10
        db "  if(ch==55) m=vec2(1016900.0,8456.0);", 10
        db "  if(ch==56) m=vec2(476718.0,17966.0);", 10
        db "  if(ch==57) m=vec2(476719.0,1070.0);", 10
        db "  if(ch==58) m=vec2(4224.0,4224.0);", 10
        db "  if(ch==65) m=vec2(476735.0,17969.0);", 10
        db "  if(ch==66) m=vec2(1001022.0,17982.0);", 10
        db "  if(ch==67) m=vec2(476688.0,16942.0);", 10
        db "  if(ch==68) m=vec2(1001009.0,17982.0);", 10
        db "  if(ch==69) m=vec2(1032734.0,16927.0);", 10
        db "  if(ch==70) m=vec2(1032734.0,16912.0);", 10
        db "  if(ch==71) m=vec2(476695.0,17966.0);", 10
        db "  if(ch==72) m=vec2(575039.0,17969.0);", 10
        db "  if(ch==73) m=vec2(462980.0,4238.0);", 10
        db "  if(ch==74) m=vec2(231490.0,19020.0);", 10
        db "  if(ch==75) m=vec2(576152.0,21073.0);", 10
        db "  if(ch==76) m=vec2(541200.0,16927.0);", 10
        db "  if(ch==77) m=vec2(585397.0,17969.0);", 10
        db "  if(ch==78) m=vec2(583347.0,17969.0);", 10
        db "  if(ch==79) m=vec2(476721.0,17966.0);", 10
        db "  if(ch==80) m=vec2(1001022.0,16912.0);", 10
        db "  if(ch==81) m=vec2(476721.0,22093.0);", 10
        db "  if(ch==82) m=vec2(1001022.0,21073.0);", 10
        db "  if(ch==83) m=vec2(508430.0,1086.0);", 10
        db "  if(ch==84) m=vec2(1020036.0,4228.0);", 10
        db "  if(ch==85) m=vec2(575025.0,17966.0);", 10
        db "  if(ch==86) m=vec2(575025.0,17732.0);", 10
        db "  if(ch==87) m=vec2(575029.0,22385.0);", 10
        db "  if(ch==88) m=vec2(574788.0,10801.0);", 10
        db "  if(ch==89) m=vec2(574788.0,4228.0);", 10
        db "  if(ch==90) m=vec2(1016900.0,8735.0);", 10
        db "  if(ch==91) m=vec2(467208.0,8462.0);", 10
        db "  if(ch==93) m=vec2(460866.0,2126.0);", 10
        db "  if(row<4){", 10
        db "    float bp=float((3-row)*5+(4-col));", 10
        db "    return mod(floor(m.x/exp2(bp)),2.0);", 10
        db "  } else {", 10
        db "    float bp=float((6-row)*5+(4-col));", 10
        db "    return mod(floor(m.y/exp2(bp)),2.0);", 10
        db "  }", 10
        db "}", 10
        db "int scrollChar(int idx){", 10
        db "  if(u_scroll_len<=0) return 32;", 10
        db "  int q=idx/u_scroll_len;", 10
        db "  int pos=idx-q*u_scroll_len;", 10
        db "  if(pos<0) pos+=u_scroll_len;", 10
        db "  if(pos>=u_scroll_len) pos-=u_scroll_len;", 10
        db "  int vIdx=pos/4;", 10
        db "  int cIdx=pos-vIdx*4;", 10
        db "  vec4 v=vec4(32.0);", 10
        db "  for(int i=0;i<48;i++){", 10
        db "    if(i==vIdx){ v=u_scroll[i]; break; }", 10
        db "  }", 10
        db "  float fch=(cIdx==0)?v.x:((cIdx==1)?v.y:((cIdx==2)?v.z:v.w));", 10
        db "  return int(floor(fch+0.5));", 10
        db "}", 10
        db "int topChar(int idx){", 10
        db "  if(idx<0 || idx>=u_top_len) return 32;", 10
        db "  int vIdx=idx/4;", 10
        db "  int cIdx=idx-vIdx*4;", 10
        db "  vec4 v=vec4(32.0);", 10
        db "  for(int i=0;i<8;i++){", 10
        db "    if(i==vIdx){ v=u_top[i]; break; }", 10
        db "  }", 10
        db "  float fch=(cIdx==0)?v.x:((cIdx==1)?v.y:((cIdx==2)?v.z:v.w));", 10
        db "  return int(floor(fch+0.5));", 10
        db "}", 10
        ; --- Egymenetes raymarch befoglalo gomb (R=2.85) gyorsitassal ---
        db "vec3 renderScene(vec2 uv){", 10
        db "  float bass=u_extra.y;", 10
        db "  float camA=sin(u_time*0.28)*0.22;", 10
        db "  float camZ=-3.25+0.12*cos(u_time*0.35)-0.06*bass;", 10
        db "  vec3 ro=vec3(sin(camA)*3.25, 0.18*sin(u_time*0.4), camZ);", 10
        db "  vec3 rd=normalize(vec3(uv*1.48, 1.0));", 10
        db "  rd.xz*=rot(-camA*0.85);", 10
        db "  float a=u_phases.x, th=u_phases.y;", 10
        db "  vec3 lm=magPos(th, a);", 10
        db "  float t=9.0;", 10
        db "  float b=dot(ro,rd);", 10
        db "  float c=dot(ro,ro)-8.1225;", 10
        db "  float h=b*b-c;", 10
        db "  if(h>0.0){", 10
        db "    float sq=sqrt(h);", 10
        db "    float t0=max(0.0, -b-sq);", 10
        db "    float t1=-b+sq;", 10
        db "    if(t1>0.0){", 10
        db "      t=t0;", 10
        db "      for(int i=0;i<64;i++){", 10
        db "        float d=map(ro+rd*t);", 10
        db "        if(d<0.003 || t>t1) break;", 10
        db "        t+=d*0.55;", 10
        db "      }", 10
        db "      if(t>t1) t=9.0;", 10
        db "    }", 10
        db "  }", 10
        db "  vec3 col=vec3(0.0);", 10
        db "  float amb=u_sliders.y*0.32;", 10
        db "  float magI=u_sliders.w*2.8*(1.0+0.35*bass);", 10
        db "  if(t<8.5){", 10
        db "    vec3 p=ro+rd*t, n=calcNormal(p);", 10
        db "    float ao=calcAO(p, n);", 10
        db "    vec3 ldir=lm-p; float dist=length(ldir); ldir/=dist;", 10
        db "    float sh=calcSoftShadow(p+n*0.015, ldir, dist);", 10
        db "    float atten=1.0/(1.0+0.26*dist*dist);", 10
        db "    float diff=max(dot(n,ldir),0.0);", 10
        db "    float spec=pow(diff,56.0);", 10
        db "    float ndv=max(dot(n,-rd),0.0);", 10
        db "    float fres=0.65+0.35*pow(1.0-ndv,3.0);", 10
        db "    vec3 reflDir=reflect(rd, n);", 10
        db "    vec3 reflCol=envReflect(reflDir, lm-p, magI, bass);", 10
        db "    float rt=0.04, rhit=0.0;", 10
        db "    for(int j=0;j<12;j++){", 10
        db "      vec3 rp=p+n*0.02+reflDir*rt;", 10
        db "      if(dot(rp,rp)>8.1225) break;", 10
        db "      float rdStep=map(rp);", 10
        db "      if(rdStep<0.008){ rhit=1.0; break; }", 10
        db "      rt+=clamp(rdStep*0.70, 0.03, 0.38);", 10
        db "      if(rt>3.2) break;", 10
        db "    }", 10
        db "    if(rhit>0.5){", 10
        db "      vec3 rp=p+n*0.02+reflDir*rt;", 10
        db "      vec3 rn=calcNormal(rp);", 10
        db "      float rdiff=max(dot(rn, normalize(lm-rp)), 0.0);", 10
        db "      reflCol=mix(reflCol, vec3(0.85,0.92,1.0)*(0.25+0.95*rdiff)*magI, 0.72);", 10
        db "    }", 10
        db "    float isCube=step(mapCube(p), mapTorus(p));", 10
        db "    vec3 pr=p; mat2 rA=rot(a); pr.xz*=rA; pr.yz*=rA;", 10
        db "    float spVal=spikeField(pr);", 10
        db "    float orgBoost=clamp(1.0 - spVal*3.0, 0.25, 1.0);", 10
        db "    float spGlow=clamp(spVal*5.5, 0.0, 1.0);", 10
        db "    vec3 chromeBase=vec3(0.76,0.82,0.90);", 10
        db "    vec3 cubeBase=vec3(0.95,0.58,0.25);", 10
        db "    vec3 baseCol=mix(chromeBase, cubeBase, isCube);", 10
        db "    float reflAmt=mix(0.78*fres*(0.6+0.4*orgBoost), 0.35*fres, isCube);", 10
        db "    col=baseCol*(amb+0.08)*ao;", 10
        db "    col=mix(col, baseCol*reflCol, reflAmt);", 10
        db "    col+=vec3(1.8,2.25,2.7)*magI*(diff*sh*0.55+spec*sh*1.8)*atten*(0.35+0.65*ao);", 10
        db "    col+=(1.0-isCube)*vec3(0.25,0.85,1.25)*spGlow*(0.35+0.65*diff);", 10
        db "  } else {", 10
        db "    float horizon=gl_FragCoord.y/u_res.y;", 10
        db "    col=vec3(0.015,0.022,0.045+0.06*horizon)+vec3(0.01,0.02,0.04)*bass;", 10
        db "    float sPy=u_res.y-gl_FragCoord.y;", 10
        db "    col+=vuMeter(gl_FragCoord.x, sPy);", 10
        db "  }", 10
        db "  if(magI>0.001){", 10
        db "    for(int k=0;k<6;k++){", 10
        db "      float fk=float(k);", 10
        db "      vec3 lp=magPos(th-fk*0.14*(0.3+u_sliders.z), a);", 10
        db "      float tc=dot(lp-ro,rd);", 10
        db "      if(tc>0.0 && tc<t){", 10
        db "        vec3 gVec=ro+rd*tc-lp;", 10
        db "        float wgt=exp(-fk*0.55);", 10
        db "        float g=(0.024*magI*wgt)/(dot(gVec,gVec)+0.007+fk*0.003);", 10
        db "        col+=mix(vec3(1.7,2.2,2.6),vec3(0.3,0.8,1.8),fk*0.18)*g;", 10
        db "      }", 10
        db "    }", 10
        db "  }", 10
        db "  return col;", 10
        db "}", 10
        db "void main(){", 10
        db "  float bass=u_extra.y;", 10
        db "  vec2 uv=(gl_FragCoord.xy-0.5*u_res)/u_res.y;", 10
        db "  vec3 col=renderScene(uv);", 10
        db "  vec2 caPix=uv*((2.4+7.5*bass)*dot(uv,uv));", 10
        db "  vec3 grad=dFdx(col)*caPix.x+dFdy(col)*caPix.y;", 10
        db "  col.r+=grad.r;", 10
        db "  col.b-=grad.b;", 10
        db "  col*=0.94+0.06*sin(gl_FragCoord.y*3.14159);", 10
        db "  col*=1.0-0.25*dot(uv,uv);", 10
        db "  col=col/(1.0+col*0.24);", 10
        db "  col=pow(clamp(col,0.0,1.0),vec3(0.85));", 10
        db "  float px=gl_FragCoord.x;", 10
        db "  float py=u_res.y-gl_FragCoord.y;", 10
        ; --- FELSO PLAYER SAV (py: 8..38) ---
        db "  if(py>=8.0 && py<=38.0 && px>=12.0 && px<=u_res.x-12.0){", 10
        db "    col=mix(col,vec3(0.03,0.06,0.12),0.86);", 10
        db "    if(py<9.5||py>36.5||px<13.5||px>u_res.x-13.5) col=vec3(0.25,0.65,0.95);", 10
        ; 1. Prev gomb (px: 20..64)
        db "    if(px>=20.0 && px<=64.0 && py>=12.0 && py<=34.0){", 10
        db "      col=mix(col,vec3(0.12,0.22,0.36),0.75);", 10
        db "      if(abs(px-36.0)<1.3 && abs(py-23.0)<5.5) col=vec3(0.4,0.9,1.0);", 10
        db "      float ptx=48.0-px; float pty=abs(py-23.0);", 10
        db "      if(ptx>=0.0 && ptx<=9.0 && pty<=(9.0-ptx)*0.6) col=vec3(0.4,0.9,1.0);", 10
        db "    }", 10
        ; 2. Play/Pause gomb (px: 70..114)
        db "    if(px>=70.0 && px<=114.0 && py>=12.0 && py<=34.0){", 10
        db "      vec3 stCol=(u_player.z>0.5)?vec3(1.0,0.65,0.2):vec3(0.25,0.95,0.65);", 10
        db "      col=mix(col,stCol*0.28,0.8);", 10
        db "      if(u_player.z>0.5){", 10
        db "        if(abs(px-87.0)<2.2 && abs(py-23.0)<6.5) col=stCol;", 10
        db "        if(abs(px-97.0)<2.2 && abs(py-23.0)<6.5) col=stCol;", 10
        db "      } else {", 10
        db "        float triX=px-87.0; float triY=abs(py-23.0);", 10
        db "        if(triX>=0.0 && triX<=12.0 && triY<=(12.0-triX)*0.55) col=stCol;", 10
        db "      }", 10
        db "    }", 10
        ; 3. Next gomb (px: 120..164)
        db "    if(px>=120.0 && px<=164.0 && py>=12.0 && py<=34.0){", 10
        db "      col=mix(col,vec3(0.12,0.22,0.36),0.75);", 10
        db "      float ntx=px-136.0; float nty=abs(py-23.0);", 10
        db "      if(ntx>=0.0 && ntx<=9.0 && nty<=(9.0-ntx)*0.6) col=vec3(0.4,0.9,1.0);", 10
        db "      if(abs(px-148.0)<1.3 && abs(py-23.0)<5.5) col=vec3(0.4,0.9,1.0);", 10
        db "    }", 10
        ; 4. Track szamlalo + cim (px: 174 .. seekX0-12)
        db "    float seekX0=u_res.x-430.0;", 10
        db "    float seekX1=u_res.x-176.0;", 10
        db "    if(px>=174.0 && px<seekX0-10.0 && py>=14.0 && py<=32.0){", 10
        db "      int tci=int(floor((px-174.0)/15.0));", 10
        db "      if(tci>=0 && tci<u_top_len){", 10
        db "        float tCellX=mod(px-174.0,15.0);", 10
        db "        if(tCellX>=1.0 && tCellX<13.5){", 10
        db "          vec2 tgp=vec2((tCellX-1.0)/2.5, (py-14.25)/2.5);", 10
        db "          if(glyph(topChar(tci),tgp)>0.5) col=vec3(0.96,0.93,0.68)*(1.0+0.18*bass);", 10
        db "        }", 10
        db "      }", 10
        db "    }", 10
        ; 5. Gyorstekero-bar (Seek bar: seekX0 .. seekX1)
        db "    if(px>=seekX0-2.0 && px<=seekX1+2.0 && py>=15.0 && py<=31.0){", 10
        db "      float sW=seekX1-seekX0;", 10
        db "      float tFrac=(u_player.y>0.5)?clamp(u_player.x/u_player.y,0.0,1.0):0.0;", 10
        db "      if(px>=seekX0 && px<=seekX1 && abs(py-23.0)<=4.0){", 10
        db "        float f=(px-seekX0)/sW;", 10
        db "        col=(f<=tFrac)?mix(vec3(0.22,0.82,1.0),vec3(0.45,0.96,1.0),bass):vec3(0.11,0.16,0.25);", 10
        db "      }", 10
        db "      float skx=seekX0+tFrac*sW;", 10
        db "      if(abs(px-skx)<=3.5 && abs(py-23.0)<=7.0) col=vec3(0.98,0.99,1.0);", 10
        db "    }", 10
        ; 6. Hangszoro ikon + Mute jelzes (volIconX: u_res.x-160 .. u_res.x-142)
        db "    float spkX=u_res.x-158.0;", 10
        db "    if(px>=spkX && px<=spkX+16.0 && py>=15.0 && py<=31.0){", 10
        db "      vec3 spkCol=(u_extra.w>0.5)?vec3(1.0,0.35,0.35):vec3(0.4,0.9,1.0);", 10
        db "      if(px>=spkX+1.0 && px<=spkX+4.5 && abs(py-23.0)<=2.5) col=spkCol;", 10
        db "      float cx=px-(spkX+4.5);", 10
        db "      if(cx>=0.0 && cx<=4.5 && abs(py-23.0)<=(2.5+cx*0.9)) col=spkCol;", 10
        db "      if(u_extra.w>0.5){", 10
        db "        float dx=px-(spkX+13.0); float dy=py-23.0;", 10
        db "        if(abs(dx)<=3.0 && abs(abs(dx)-abs(dy))<1.1) col=spkCol;", 10
        db "      } else {", 10
        db "        if(abs(px-(spkX+11.5))<1.1 && abs(py-23.0)<=3.5) col=spkCol;", 10
        db "        if(abs(px-(spkX+14.5))<1.1 && abs(py-23.0)<=5.5) col=spkCol;", 10
        db "      }", 10
        db "    }", 10
        ; 7. Hangero csuszka a felso savban (volX0: u_res.x-138 .. volX1: u_res.x-24)
        db "    float volX0=u_res.x-138.0;", 10
        db "    float volX1=u_res.x-24.0;", 10
        db "    if(px>=volX0-4.0 && px<=volX1+4.0 && py>=15.0 && py<=31.0){", 10
        db "      float vW=volX1-volX0;", 10
        db "      float vVal=clamp(u_player.w,0.0,1.0);", 10
        db "      if(px>=volX0 && px<=volX1 && abs(py-23.0)<=4.0){", 10
        db "        float vf=(px-volX0)/vW;", 10
        db "        col=(vf<=vVal)?vec3(0.95,0.45,0.85):vec3(0.11,0.16,0.25);", 10
        db "      }", 10
        db "      float vkx=volX0+vVal*vW;", 10
        db "      if(abs(px-vkx)<=3.5 && abs(py-23.0)<=7.0) col=vec3(0.98,0.99,1.0);", 10
        db "    }", 10
        db "  }", 10
        ; --- ALSO HULLAMOZO SCROLLER (5x7 font, 3x3 px/pont) ---
        db "  float sy_bot=u_res.y-36.0;", 10
        db "  if(py>sy_bot-22.0 && py<sy_bot+24.0){", 10
        db "    col=mix(col,vec3(0.02,0.04,0.08),0.72);", 10
        db "    if(abs(py-(sy_bot-22.0))<1.0 || abs(py-(sy_bot+24.0))<1.0) col=vec3(0.2,0.5,0.8);", 10
        db "    float scX=px+u_time*140.0;", 10
        db "    int idx=int(floor(scX/22.0));", 10
        db "    int ch=scrollChar(idx);", 10
        db "    float wave=sin(px*0.025-u_time*4.5)*4.0;", 10
        db "    float cellX=mod(scX,22.0);", 10
        db "    float cellY=py-(sy_bot-11.0+wave);", 10
        db "    if(cellX>=3.0 && cellX<18.0 && cellY>=0.0 && cellY<21.0){", 10
        db "      vec2 gp=vec2((cellX-3.0)/3.0, cellY/3.0);", 10
        db "      if(glyph(ch,gp)>0.5){", 10
        db "        vec3 scCol=mix(vec3(0.25,0.88,1.0),vec3(1.0,0.68,0.22),0.5+0.5*sin(px*0.012+u_time*3.0));", 10
        db "        col=scCol*(1.0+0.22*bass);", 10
        db "      }", 10
        db "    }", 10
        db "  }", 10
        ; --- HUD PANEL (5 slider: ROT SPD, AMBIENT, MAG SPD, MAG PWR, SPIKES) ---
        db "  if(u_extra.x>0.5){", 10
        db "    if(px>=12.0 && px<=350.0 && py>=46.0 && py<=198.0){", 10
        db "      col=mix(col,vec3(0.04,0.06,0.10),0.84);", 10
        db "      if(px<13.5||px>348.5||py<47.5||py>196.5) col=vec3(0.25,0.45,0.68);", 10
        db "      for(int k=0;k<5;k++){", 10
        db "        float sy=60.0+float(k)*28.0;", 10
        db "        float val=(k==0)?u_sliders.x:((k==1)?u_sliders.y:((k==2)?u_sliders.z:((k==3)?u_sliders.w:u_extra.z)));", 10
        db "        vec3 barCol=(k==0)?vec3(0.25,0.65,1.0):((k==1)?vec3(0.25,0.9,0.55):((k==2)?vec3(0.2,0.9,0.95):((k==3)?vec3(1.0,0.85,0.35):vec3(1.0,0.38,0.28))));", 10
        db "        if(px>=24.0 && px<=210.0 && abs(py-sy)<=4.0){", 10
        db "          float frac=(px-24.0)/186.0;", 10
        db "          col=(frac<=val)?barCol:vec3(0.15,0.19,0.25);", 10
        db "        }", 10
        db "        float kx=24.0+val*186.0;", 10
        db "        if(abs(px-kx)<=4.5 && abs(py-sy)<=7.5) col=vec3(0.98,0.99,1.0);", 10
        db "        float lx0=220.0;", 10
        db "        if(px>=lx0 && px<lx0+119.0 && py>=(sy-7.0) && py<(sy+7.0)){", 10
        db "          int ci=int(floor((px-lx0)/17.0));", 10
        db "          int lch=32;", 10
        db "          if(k==0){ if(ci==0)lch=82;if(ci==1)lch=79;if(ci==2)lch=84;if(ci==4)lch=83;if(ci==5)lch=80;if(ci==6)lch=68; }", 10
        db "          if(k==1){ if(ci==0)lch=65;if(ci==1)lch=77;if(ci==2)lch=66;if(ci==3)lch=73;if(ci==4)lch=69;if(ci==5)lch=78;if(ci==6)lch=84; }", 10
        db "          if(k==2){ if(ci==0)lch=77;if(ci==1)lch=65;if(ci==2)lch=71;if(ci==4)lch=83;if(ci==5)lch=80;if(ci==6)lch=68; }", 10
        db "          if(k==3){ if(ci==0)lch=77;if(ci==1)lch=65;if(ci==2)lch=71;if(ci==4)lch=80;if(ci==5)lch=87;if(ci==6)lch=82; }", 10
        db "          if(k==4){ if(ci==0)lch=83;if(ci==1)lch=80;if(ci==2)lch=73;if(ci==3)lch=75;if(ci==4)lch=69;if(ci==5)lch=83; }", 10
        db "          float lCellX=mod(px-lx0,17.0);", 10
        db "          if(lCellX>=1.0 && lCellX<11.0){", 10
        db "            vec2 lgp=vec2((lCellX-1.0)/2.0, (py-(sy-7.0))/2.0);", 10
        db "            if(glyph(lch,lgp)>0.5) col=barCol;", 10
        db "          }", 10
        db "        }", 10
        db "      }", 10
        db "    }", 10
        db "  }", 10
        db "  gl_FragColor=vec4(col,1.0);", 10
        db "}", 10, 0

    frag_shader_ptr dq frag_shader_src

section .text
    global WinMain
    global main

; ----------------------------------------------------------------------------
; Segedfuggvenyek: ASCII szam konverzio es MCI hossz lekero
; ----------------------------------------------------------------------------
parse_uint_ascii:
    xor eax, eax
.loop:
    movzx edx, byte [rsi]
    cmp dl, '0'
    jl .done
    cmp dl, '9'
    jg .done
    sub dl, '0'
    imul eax, 10
    add eax, edx
    inc rsi
    jmp .loop
.done:
    ret

append_uint_ascii:
    push rbx
    sub rsp, 32
    mov rbx, rsp
    xor ecx, ecx
.div_loop:
    xor edx, edx
    mov r8d, 10
    div r8d
    add dl, '0'
    mov [rbx + rcx], dl
    inc ecx
    test eax, eax
    jnz .div_loop
.rev_loop:
    dec ecx
    mov al, [rbx + rcx]
    mov [rdi], al
    inc rdi
    test ecx, ecx
    jnz .rev_loop
    mov byte [rdi], 0
    add rsp, 32
    pop rbx
    ret

query_track_length:
    push rsi
    sub rsp, 32
    mov dword [mci_ret_buf], 0
    lea rcx, [mci_len_cmd]
    lea rdx, [mci_ret_buf]
    mov r8d, 32
    xor r9d, r9d
    call mciSendStringA
    test eax, eax
    jnz .done
    lea rsi, [mci_ret_buf]
    call parse_uint_ascii
    mov [track_len_ms], eax
.done:
    add rsp, 32
    pop rsi
    ret

; ----------------------------------------------------------------------------
; Lejatszasi lista beolvasasa: music\*.mp3
; ----------------------------------------------------------------------------
playlist_scan:
    push rbx
    push rsi
    push rdi
    sub rsp, 48

    mov dword [track_count], 0
    mov dword [cur_track], 0

    lea rcx, [music_pattern]
    lea rdx, [find_data]
    call FindFirstFileA
    cmp rax, -1
    je .done
    mov [hFind], rax

.loop_file:
    mov eax, [find_data]
    test eax, 0x10
    jnz .next_file

    mov eax, [track_count]
    cmp eax, MAX_TRACKS
    jge .close_find

    imul eax, 128
    lea rdi, [tracks_buf]
    add rdi, rax
    lea rsi, [find_data + 44]
    mov ecx, 127
.copy_name:
    movzx edx, byte [rsi]
    mov [rdi], dl
    test dl, dl
    jz .copied_name
    inc rsi
    inc rdi
    dec ecx
    jnz .copy_name
    mov byte [rdi], 0
.copied_name:
    inc dword [track_count]

.next_file:
    mov rcx, [hFind]
    lea rdx, [find_data]
    call FindNextFileA
    test eax, eax
    jnz .loop_file

.close_find:
    mov rcx, [hFind]
    call FindClose

.done:
    add rsp, 48
    pop rdi
    pop rsi
    pop rbx
    ret

match_alnum_key:
    push rsi
    push rdi
    push rbx
    mov rsi, rcx
    mov rbx, rdx

.outer_pos:
    movzx eax, byte [rsi]
    test al, al
    jz .no_match

    mov rdi, rbx
    push rsi

.match_here:
    movzx ecx, byte [rdi]
    test cl, cl
    jz .matched_ok

.skip_non_alnum_src:
    movzx eax, byte [rsi]
    test al, al
    jz .no_match_pop
    inc rsi
    cmp al, 'A'
    jl .chk_l
    cmp al, 'Z'
    jg .chk_l
    add al, 32
.chk_l:
    cmp al, 'a'
    jl .chk_d
    cmp al, 'z'
    jg .chk_d
    jmp .cmp_now
.chk_d:
    cmp al, '0'
    jl .skip_non_alnum_src
    cmp al, '9'
    jg .skip_non_alnum_src

.cmp_now:
    cmp al, cl
    jne .no_match_pop
    inc rdi
    jmp .match_here

.matched_ok:
    pop rsi
    mov eax, 1
    pop rbx
    pop rdi
    pop rsi
    ret

.no_match_pop:
    pop rsi
    inc rsi
    jmp .outer_pos

.no_match:
    xor eax, eax
    pop rbx
    pop rdi
    pop rsi
    ret

build_scroller_text:
    push rbx
    push rsi
    push rdi
    sub rsp, 48

    mov byte [scroller_txt], 0
    mov byte [top_txt], 0

    mov eax, [track_count]
    test eax, eax
    jnz .has_track

    lea rcx, [scroller_txt]
    lea rdx, [lbl_empty]
    call lstrcpyA

    lea rcx, [top_txt]
    lea rdx, [tag_empty]
    call lstrcpyA
    jmp .to_uniform_arr

.has_track:
    mov eax, [cur_track]
    imul eax, 128
    lea rbx, [tracks_buf]
    add rbx, rax

    mov rcx, rbx
    lea rdx, [meta_cyber]
    call match_alnum_key
    test eax, eax
    jz .chk_aglow
    lea rcx, [scroller_txt]
    lea rdx, [info_cyber]
    call lstrcpyA
    lea rcx, [top_txt]
    lea rdx, [tag_cyber]
    call lstrcpyA
    jmp .to_uniform_arr

.chk_aglow:
    mov rcx, rbx
    lea rdx, [meta_aglow]
    call match_alnum_key
    test eax, eax
    jz .chk_decalogue
    lea rcx, [scroller_txt]
    lea rdx, [info_aglow]
    call lstrcpyA
    lea rcx, [top_txt]
    lea rdx, [tag_aglow]
    call lstrcpyA
    jmp .to_uniform_arr

.chk_decalogue:
    mov rcx, rbx
    lea rdx, [meta_decalogue]
    call match_alnum_key
    test eax, eax
    jz .chk_insanity
    lea rcx, [scroller_txt]
    lea rdx, [info_decalogue]
    call lstrcpyA
    lea rcx, [top_txt]
    lea rdx, [tag_decalogue]
    call lstrcpyA
    jmp .to_uniform_arr

.chk_insanity:
    mov rcx, rbx
    lea rdx, [meta_insanity]
    call match_alnum_key
    test eax, eax
    jz .chk_nexus7
    lea rcx, [scroller_txt]
    lea rdx, [info_insanity]
    call lstrcpyA
    lea rcx, [top_txt]
    lea rdx, [tag_insanity]
    call lstrcpyA
    jmp .to_uniform_arr

.chk_nexus7:
    mov rcx, rbx
    lea rdx, [meta_nexus7]
    call match_alnum_key
    test eax, eax
    jz .chk_stardust
    lea rcx, [scroller_txt]
    lea rdx, [info_nexus7]
    call lstrcpyA
    lea rcx, [top_txt]
    lea rdx, [tag_nexus7]
    call lstrcpyA
    jmp .to_uniform_arr

.chk_stardust:
    mov rcx, rbx
    lea rdx, [meta_stardust]
    call match_alnum_key
    test eax, eax
    jz .chk_2nd2
    lea rcx, [scroller_txt]
    lea rdx, [info_stardust]
    call lstrcpyA
    lea rcx, [top_txt]
    lea rdx, [tag_stardust]
    call lstrcpyA
    jmp .to_uniform_arr

.chk_2nd2:
    mov rcx, rbx
    lea rdx, [meta_2nd2]
    call match_alnum_key
    test eax, eax
    jz .chk_sota
    lea rcx, [scroller_txt]
    lea rdx, [info_2nd2]
    call lstrcpyA
    lea rcx, [top_txt]
    lea rdx, [tag_2nd2]
    call lstrcpyA
    jmp .to_uniform_arr

.chk_sota:
    mov rcx, rbx
    lea rdx, [meta_sota]
    call match_alnum_key
    test eax, eax
    jz .generic_info
    lea rcx, [scroller_txt]
    lea rdx, [info_sota]
    call lstrcpyA
    lea rcx, [top_txt]
    lea rdx, [tag_sota]
    call lstrcpyA
    jmp .to_uniform_arr

.generic_info:
    lea rcx, [scroller_txt]
    lea rdx, [lbl_track]
    call lstrcpyA
    lea rcx, [scroller_txt]
    mov rdx, rbx
    call lstrcatA
    lea rcx, [scroller_txt]
    lea rdx, [lbl_tail]
    call lstrcatA

    lea rcx, [top_txt]
    mov rdx, rbx
    call lstrcpyA

.to_uniform_arr:
    lea rdi, [u_scroll_arr]
    movss xmm0, [c_space_f]
    xor ecx, ecx
.clear_sc:
    movss [rdi + rcx * 4], xmm0
    inc ecx
    cmp ecx, MAX_SCROLL
    jl .clear_sc

    lea rsi, [scroller_txt]
    xor ecx, ecx
.sc_loop:
    cmp ecx, MAX_SCROLL - 4
    jge .sc_pad
    movzx eax, byte [rsi]
    test al, al
    jz .sc_pad
    cmp al, 'a'
    jl .sc_store
    cmp al, 'z'
    jg .sc_store
    sub al, 32
.sc_store:
    cvtsi2ss xmm0, eax
    movss [rdi + rcx * 4], xmm0
    inc rsi
    inc ecx
    jmp .sc_loop

.sc_pad:
    add ecx, 4
    mov [scroll_len], ecx

    lea rdi, [u_top_arr]
    movss xmm0, [c_space_f]
    xor ecx, ecx
.clear_top:
    movss [rdi + rcx * 4], xmm0
    inc ecx
    cmp ecx, 32
    jl .clear_top

    xor ecx, ecx
    mov eax, '['
    cvtsi2ss xmm0, eax
    movss [rdi + rcx * 4], xmm0
    inc ecx

    mov eax, [cur_track]
    inc eax
    cmp eax, 10
    jl .cur_one_dig
    xor edx, edx
    mov r8d, 10
    div r8d
    add eax, '0'
    cvtsi2ss xmm0, eax
    movss [rdi + rcx * 4], xmm0
    inc ecx
    mov eax, edx
.cur_one_dig:
    add eax, '0'
    cvtsi2ss xmm0, eax
    movss [rdi + rcx * 4], xmm0
    inc ecx

    mov eax, '/'
    cvtsi2ss xmm0, eax
    movss [rdi + rcx * 4], xmm0
    inc ecx

    mov eax, [track_count]
    test eax, eax
    jnz .has_cnt_digit
    mov eax, 1
.has_cnt_digit:
    cmp eax, 10
    jl .cnt_one_dig
    xor edx, edx
    mov r8d, 10
    div r8d
    add eax, '0'
    cvtsi2ss xmm0, eax
    movss [rdi + rcx * 4], xmm0
    inc ecx
    mov eax, edx
.cnt_one_dig:
    add eax, '0'
    cvtsi2ss xmm0, eax
    movss [rdi + rcx * 4], xmm0
    inc ecx

    mov eax, ']'
    cvtsi2ss xmm0, eax
    movss [rdi + rcx * 4], xmm0
    inc ecx
    inc ecx

    lea rsi, [top_txt]
.top_loop:
    cmp ecx, 30
    jge .top_done
    movzx eax, byte [rsi]
    test al, al
    jz .top_done
    cmp al, 'a'
    jl .top_store
    cmp al, 'z'
    jg .top_store
    sub al, 32
.top_store:
    cvtsi2ss xmm0, eax
    movss [rdi + rcx * 4], xmm0
    inc rsi
    inc ecx
    jmp .top_loop

.top_done:
    mov [top_len], ecx

    cmp dword [prog_id], 0
    je .out
    mov ecx, [prog_id]
    call [glUseProgram]

    mov ecx, [u_scroll_len_loc]
    mov edx, [scroll_len]
    call [glUniform1i]

    mov ecx, [u_scroll_loc]
    mov edx, 48
    lea r8, [u_scroll_arr]
    call [glUniform4fv]

    mov ecx, [u_top_len_loc]
    mov edx, [top_len]
    call [glUniform1i]

    mov ecx, [u_top_loc]
    mov edx, 8
    lea r8, [u_top_arr]
    call [glUniform4fv]

.out:
    add rsp, 48
    pop rdi
    pop rsi
    pop rbx
    ret

audio_play_current:
    push rbx
    sub rsp, 48

    mov dword [track_pos_ms], 0
    mov dword [track_len_ms], 0
    call build_scroller_text

    mov eax, [track_count]
    test eax, eax
    jz .ret

    lea rcx, [mci_close_cmd]
    xor edx, edx
    xor r8d, r8d
    xor r9d, r9d
    call mciSendStringA

    mov eax, [cur_track]
    imul eax, 128
    lea rbx, [tracks_buf]
    add rbx, rax

    ; 1. Megnyitas: type mpegvideo
    lea rcx, [mci_cmd_buf]
    lea rdx, [mci_open_head]
    call lstrcpyA

    lea rcx, [mci_cmd_buf]
    lea rdx, [music_prefix]
    call lstrcatA

    lea rcx, [mci_cmd_buf]
    mov rdx, rbx
    call lstrcatA

    lea rcx, [mci_cmd_buf]
    lea rdx, [mci_open_tail]
    call lstrcatA

    lea rcx, [mci_cmd_buf]
    xor edx, edx
    xor r8d, r8d
    xor r9d, r9d
    call mciSendStringA
    test eax, eax
    jz .opened_ok

    ; 2. Fallback megnyitas: type mpegvideo nelkul
    lea rcx, [mci_cmd_buf]
    lea rdx, [mci_open_head]
    call lstrcpyA

    lea rcx, [mci_cmd_buf]
    lea rdx, [music_prefix]
    call lstrcatA

    lea rcx, [mci_cmd_buf]
    mov rdx, rbx
    call lstrcatA

    lea rcx, [mci_cmd_buf]
    lea rdx, [mci_open_plain]
    call lstrcatA

    lea rcx, [mci_cmd_buf]
    xor edx, edx
    xor r8d, r8d
    xor r9d, r9d
    call mciSendStringA
    test eax, eax
    jnz .show_mci_err

.opened_ok:
    lea rcx, [mci_tf_cmd]
    xor edx, edx
    xor r8d, r8d
    xor r9d, r9d
    call mciSendStringA

    call query_track_length

    mov dword [last_vol_i], -1
    call audio_set_volume

    mov dword [paused_flag], 0
    lea rcx, [mci_play_once]
    xor edx, edx
    xor r8d, r8d
    xor r9d, r9d
    call mciSendStringA
    test eax, eax
    jz .ret

.show_mci_err:
    mov ecx, eax
    lea rdx, [mci_err_buf]
    mov r8d, 255
    call mciGetErrorStringA

    xor ecx, ecx
    lea rdx, [mci_err_buf]
    lea r8, [mci_err_ttl]
    mov r9d, 0x30
    call MessageBoxA

.ret:
    add rsp, 48
    pop rbx
    ret

; Gyorstekeres: xmm0 = 0.0 .. 1.0 arany
audio_seek_fraction:
    push rdi
    sub rsp, 48

    mov eax, [track_count]
    test eax, eax
    jz .done
    mov eax, [track_len_ms]
    test eax, eax
    jnz .has_len
    movss [rsp + 32], xmm0
    call query_track_length
    movss xmm0, [rsp + 32]
    mov eax, [track_len_ms]
    test eax, eax
    jz .done

.has_len:
    cvtsi2ss xmm1, eax
    mulss xmm0, xmm1
    cvtss2si eax, xmm0
    test eax, eax
    jns .min_ok
    xor eax, eax
.min_ok:
    cmp eax, [track_len_ms]
    jle .max_ok
    mov eax, [track_len_ms]
.max_ok:
    mov [track_pos_ms], eax

    lea rcx, [mci_cmd_buf]
    lea rdx, [mci_seek_head]
    call lstrcpyA

    lea rdi, [mci_cmd_buf + 12]
    mov eax, [track_pos_ms]
    call append_uint_ascii

    lea rcx, [mci_cmd_buf]
    xor edx, edx
    xor r8d, r8d
    xor r9d, r9d
    call mciSendStringA

    cmp dword [paused_flag], 0
    jne .done

    lea rcx, [mci_play_once]
    xor edx, edx
    xor r8d, r8d
    xor r9d, r9d
    call mciSendStringA

.done:
    add rsp, 48
    pop rdi
    ret

audio_next_track:
    sub rsp, 40
    mov eax, [track_count]
    test eax, eax
    jz .done
    mov ecx, [cur_track]
    inc ecx
    cmp ecx, eax
    jl .set_idx
    xor ecx, ecx
.set_idx:
    mov [cur_track], ecx
    call audio_play_current
.done:
    add rsp, 40
    ret

audio_prev_track:
    sub rsp, 40
    mov eax, [track_count]
    test eax, eax
    jz .done
    mov ecx, [cur_track]
    dec ecx
    jns .set_idx
    mov ecx, eax
    dec ecx
.set_idx:
    mov [cur_track], ecx
    call audio_play_current
.done:
    add rsp, 40
    ret

audio_toggle_pause:
    sub rsp, 40
    mov eax, [track_count]
    test eax, eax
    jz .done
    cmp dword [paused_flag], 0
    jne .do_resume
    mov dword [paused_flag], 1
    lea rcx, [mci_pause_cmd]
    xor edx, edx
    xor r8d, r8d
    xor r9d, r9d
    call mciSendStringA
    jmp .done
.do_resume:
    mov dword [paused_flag], 0
    lea rcx, [mci_play_once]
    xor edx, edx
    xor r8d, r8d
    xor r9d, r9d
    call mciSendStringA
.done:
    add rsp, 40
    ret

audio_init:
    sub rsp, 40
    call playlist_scan
    call audio_play_current
    add rsp, 40
    ret

audio_set_volume:
    push rdi
    sub rsp, 32

    movss xmm0, [vol_level]
    mulss xmm0, [c_1000]
    cvtss2si eax, xmm0
    test eax, eax
    jns .v_min_ok
    xor eax, eax
.v_min_ok:
    cmp eax, 1000
    jle .v_max_ok
    mov eax, 1000
.v_max_ok:
    cmp eax, [last_vol_i]
    je .vol_unchanged
    mov [last_vol_i], eax

    lea rdi, [vol_num_buf]
    cmp eax, 1000
    jl .under_1000
    mov dword [rdi], '1000'
    mov byte [rdi + 4], 0
    jmp .send_vol
.under_1000:
    mov ecx, 100
    xor edx, edx
    div ecx
    add al, '0'
    mov [rdi], al
    mov eax, edx
    mov ecx, 10
    xor edx, edx
    div ecx
    add al, '0'
    mov [rdi + 1], al
    add dl, '0'
    mov [rdi + 2], dl
    mov byte [rdi + 3], 0

.send_vol:
    lea rcx, [vol_cmd_buf]
    xor edx, edx
    xor r8d, r8d
    xor r9d, r9d
    call mciSendStringA

.vol_unchanged:
    add rsp, 32
    pop rdi
    ret

audio_update_bass:
    push rsi
    sub rsp, 32

    cmp dword [track_count], 0
    je .zero_bass
    cmp dword [paused_flag], 0
    jne .zero_bass

    ; Szam vege ellenorzese (status bgm mode -> "stopped")
    mov dword [mci_ret_buf], 0
    lea rcx, [mci_mode_cmd]
    lea rdx, [mci_ret_buf]
    mov r8d, 32
    xor r9d, r9d
    call mciSendStringA
    test eax, eax
    jnz .zero_bass

    cmp byte [mci_ret_buf], 's'
    jne .still_playing
    call audio_next_track
    jmp .zero_bass

.still_playing:
    cmp dword [track_len_ms], 0
    jne .read_pos
    call query_track_length

.read_pos:
    mov dword [mci_ret_buf], 0
    lea rcx, [mci_pos_cmd]
    lea rdx, [mci_ret_buf]
    mov r8d, 32
    xor r9d, r9d
    call mciSendStringA
    test eax, eax
    jnz .zero_bass

    lea rsi, [mci_ret_buf]
    call parse_uint_ascii
    mov [track_pos_ms], eax

    xor edx, edx
    mov ecx, 435
    div ecx
    mov eax, 435
    sub eax, edx
    cvtsi2ss xmm0, eax
    mov eax, 435
    cvtsi2ss xmm1, eax
    divss xmm0, xmm1
    mulss xmm0, xmm0
    mulss xmm0, xmm0
    movss [bass_env], xmm0
    jmp .bass_done

.zero_bass:
    movss xmm0, [c_zero]
    movss [bass_env], xmm0

.bass_done:
    add rsp, 32
    pop rsi
    ret

audio_close:
    sub rsp, 40
    lea rcx, [mci_close_cmd]
    xor edx, edx
    xor r8d, r8d
    xor r9d, r9d
    call mciSendStringA
    add rsp, 40
    ret

main:
WinMain:
    sub rsp, 104
    finit

    xor ecx, ecx
    call GetModuleHandleA
    mov [hInstance], rax
    mov [wndclass + 24], rax

    lea rcx, [wndclass]
    call RegisterClassExA

    xor ecx, ecx
    lea rdx, [class_name]
    lea r8, [win_title]
    mov r9d, 0x10CF0000
    mov dword [rsp + 32], 100
    mov dword [rsp + 40], 100
    mov dword [rsp + 48], 1280
    mov dword [rsp + 56], 720
    mov qword [rsp + 64], 0
    mov qword [rsp + 72], 0
    mov rax, [hInstance]
    mov [rsp + 80], rax
    mov qword [rsp + 88], 0
    call CreateWindowExA
    mov [hwnd], rax

    mov rcx, rax
    call GetDC
    mov [hdc], rax

    mov rcx, [hdc]
    lea rdx, [pfd]
    call ChoosePixelFormat

    mov rcx, [hdc]
    mov edx, eax
    lea r8, [pfd]
    call SetPixelFormat

    mov rcx, [hdc]
    call wglCreateContext
    mov [hglrc], rax

    mov rcx, [hdc]
    mov rdx, rax
    call wglMakeCurrent

    lea rcx, [fn_glCreateShader]
    call wglGetProcAddress
    mov [glCreateShader], rax

    lea rcx, [fn_glShaderSource]
    call wglGetProcAddress
    mov [glShaderSource], rax

    lea rcx, [fn_glCompileShader]
    call wglGetProcAddress
    mov [glCompileShader], rax

    lea rcx, [fn_glGetShaderiv]
    call wglGetProcAddress
    mov [glGetShaderiv], rax

    lea rcx, [fn_glGetShaderInfoLog]
    call wglGetProcAddress
    mov [glGetShaderInfoLog], rax

    lea rcx, [fn_glCreateProgram]
    call wglGetProcAddress
    mov [glCreateProgram], rax

    lea rcx, [fn_glAttachShader]
    call wglGetProcAddress
    mov [glAttachShader], rax

    lea rcx, [fn_glLinkProgram]
    call wglGetProcAddress
    mov [glLinkProgram], rax

    lea rcx, [fn_glUseProgram]
    call wglGetProcAddress
    mov [glUseProgram], rax

    lea rcx, [fn_glGetUniformLocation]
    call wglGetProcAddress
    mov [glGetUniformLocation], rax

    lea rcx, [fn_glUniform1f]
    call wglGetProcAddress
    mov [glUniform1f], rax

    lea rcx, [fn_glUniform1i]
    call wglGetProcAddress
    mov [glUniform1i], rax

    lea rcx, [fn_glUniform2f]
    call wglGetProcAddress
    mov [glUniform2f], rax

    lea rcx, [fn_glUniform4f]
    call wglGetProcAddress
    mov [glUniform4f], rax

    lea rcx, [fn_glUniform4fv]
    call wglGetProcAddress
    mov [glUniform4fv], rax

    mov ecx, 0x8B30
    call [glCreateShader]
    mov r12, rax

    mov rcx, r12
    mov edx, 1
    lea r8, [frag_shader_ptr]
    xor r9d, r9d
    call [glShaderSource]

    mov rcx, r12
    call [glCompileShader]

    mov rcx, r12
    mov edx, 0x8B81
    lea r8, [shader_ok]
    call [glGetShaderiv]

    cmp dword [shader_ok], 1
    je .shader_compiled_ok

    mov rcx, r12
    mov edx, 500
    xor r8d, r8d
    lea r9, [shader_log]
    call [glGetShaderInfoLog]

    xor ecx, ecx
    lea rdx, [shader_log]
    lea r8, [err_title]
    mov r9d, 0x10
    call MessageBoxA
    jmp exit_app

.shader_compiled_ok:
    call [glCreateProgram]
    mov [prog_id], eax
    mov r13d, eax

    mov ecx, r13d
    mov rdx, r12
    call [glAttachShader]

    mov ecx, r13d
    call [glLinkProgram]

    mov ecx, r13d
    call [glUseProgram]

    mov ecx, r13d
    lea rdx, [u_time_name]
    call [glGetUniformLocation]
    mov [u_time_loc], eax

    mov ecx, r13d
    lea rdx, [u_res_name]
    call [glGetUniformLocation]
    mov [u_res_loc], eax

    mov ecx, r13d
    lea rdx, [u_phases_name]
    call [glGetUniformLocation]
    mov [u_phases_loc], eax

    mov ecx, r13d
    lea rdx, [u_sliders_name]
    call [glGetUniformLocation]
    mov [u_sliders_loc], eax

    mov ecx, r13d
    lea rdx, [u_extra_name]
    call [glGetUniformLocation]
    mov [u_extra_loc], eax

    mov ecx, r13d
    lea rdx, [u_player_name]
    call [glGetUniformLocation]
    mov [u_player_loc], eax

    mov ecx, r13d
    lea rdx, [u_scroll_name]
    call [glGetUniformLocation]
    mov [u_scroll_loc], eax

    mov ecx, r13d
    lea rdx, [u_scroll_len_name]
    call [glGetUniformLocation]
    mov [u_scroll_len_loc], eax

    mov ecx, r13d
    lea rdx, [u_top_name]
    call [glGetUniformLocation]
    mov [u_top_loc], eax

    mov ecx, r13d
    lea rdx, [u_top_len_name]
    call [glGetUniformLocation]
    mov [u_top_len_loc], eax

    call audio_init

msg_loop:
    lea rcx, [msg]
    xor edx, edx
    xor r8d, r8d
    xor r9d, r9d
    mov dword [rsp + 32], 1
    call PeekMessageA
    test eax, eax
    jz render_frame

    cmp dword [msg + 8], 0x0012
    je exit_app

    lea rcx, [msg]
    call TranslateMessage
    lea rcx, [msg]
    call DispatchMessageA
    jmp msg_loop

render_frame:
    fld dword [time]
    fadd dword [dt_step]
    fstp dword [time]

    call audio_set_volume
    call audio_update_bass

    fld dword [slider0]
    fmul dword [max_rot_spd]
    fstp dword [real_rot_spd]

    fld dword [slider2]
    fmul dword [max_mag_spd]
    fstp dword [real_mag_spd]

    fld dword [rot_phase]
    fld dword [real_rot_spd]
    fmul dword [dt_step]
    faddp st1, st0
    fstp dword [rot_phase]

    fld dword [mag_phase]
    fld dword [real_mag_spd]
    fmul dword [dt_step]
    faddp st1, st0
    fstp dword [mag_phase]

    mov eax, [track_pos_ms]
    cvtsi2ss xmm0, eax
    movss [pos_ms_f], xmm0

    mov eax, [track_len_ms]
    cvtsi2ss xmm0, eax
    movss [len_ms_f], xmm0

    mov eax, [paused_flag]
    cvtsi2ss xmm0, eax
    movss [paused_f], xmm0

    mov eax, [muted_flag]
    cvtsi2ss xmm0, eax
    movss [muted_f], xmm0

    mov rcx, [hwnd]
    lea rdx, [rect]
    call GetClientRect

    xor ecx, ecx
    xor edx, edx
    mov r8d, [rect + 8]
    mov r9d, [rect + 12]
    call glViewport

    mov ecx, [prog_id]
    call [glUseProgram]

    mov ecx, [u_res_loc]
    vcvtsi2ss xmm1, xmm1, dword [rect + 8]
    vcvtsi2ss xmm2, xmm2, dword [rect + 12]
    call [glUniform2f]

    mov ecx, [u_time_loc]
    movss xmm1, [time]
    call [glUniform1f]

    mov ecx, [u_phases_loc]
    movss xmm1, [rot_phase]
    movss xmm2, [mag_phase]
    call [glUniform2f]

    sub rsp, 48
    mov ecx, [u_sliders_loc]
    movss xmm1, [slider0]
    movss xmm2, [slider1]
    movss xmm3, [slider2]
    mov eax, [slider3]
    mov [rsp + 32], eax
    call [glUniform4f]

    mov ecx, [u_extra_loc]
    movss xmm1, [hud_visible]
    movss xmm2, [bass_env]
    movss xmm3, [slider4]
    mov eax, [muted_f]
    mov [rsp + 32], eax
    call [glUniform4f]

    mov ecx, [u_player_loc]
    movss xmm1, [pos_ms_f]
    movss xmm2, [len_ms_f]
    movss xmm3, [paused_f]
    mov eax, [vol_level]
    mov [rsp + 32], eax
    call [glUniform4f]
    add rsp, 48

    movss xmm0, [c_neg1]
    movss xmm1, [c_neg1]
    movss xmm2, [c_pos1]
    movss xmm3, [c_pos1]
    call glRectf

    mov rcx, [hdc]
    call SwapBuffers

    jmp msg_loop

exit_app:
    call audio_close
    mov rcx, [hwnd]
    mov rdx, [hdc]
    call ReleaseDC
    xor ecx, ecx
    call ExitProcess

; ----------------------------------------------------------------------------
; Eger segedfuggvenyek: seek bar & volume bar
; ----------------------------------------------------------------------------
; ebx = mouseX, r8d = clientW
apply_seek_mouse:
    sub rsp, 40
    mov ecx, r8d
    sub ecx, 430            ; seekX0
    mov eax, ebx
    sub eax, ecx
    test eax, eax
    jns .min_ok
    xor eax, eax
.min_ok:
    cmp eax, 254            ; seekX1 - seekX0 = 254
    jle .max_ok
    mov eax, 254
.max_ok:
    cvtsi2ss xmm0, eax
    mov eax, 254
    cvtsi2ss xmm1, eax
    divss xmm0, xmm1
    call audio_seek_fraction
    add rsp, 40
    ret

; ebx = mouseX, r8d = clientW
apply_vol_mouse:
    mov ecx, r8d
    sub ecx, 138            ; volX0
    mov eax, ebx
    sub eax, ecx
    test eax, eax
    jns .min_ok
    xor eax, eax
.min_ok:
    cmp eax, 114            ; volX1 - volX0 = 114
    jle .max_ok
    mov eax, 114
.max_ok:
    cvtsi2ss xmm0, eax
    mov eax, 114
    cvtsi2ss xmm1, eax
    divss xmm0, xmm1
    movss [vol_level], xmm0
    mov dword [muted_flag], 0
    ret

WndProc:
    cmp edx, 0x0002
    je .destroy
    cmp edx, 0x0100
    je .keydown
    cmp edx, 0x0201
    je .lbuttondown
    cmp edx, 0x0202
    je .lbuttonup
    cmp edx, 0x0200
    je .mousemove
    jmp DefWindowProcA

.keydown:
    cmp r8d, 0x1B
    je .destroy
    cmp r8d, 'H'
    je .toggle_hud
    cmp r8d, 'M'
    je .toggle_mute
    cmp r8d, 'N'
    je .next_track
    cmp r8d, 0x27
    je .next_track
    cmp r8d, 'P'
    je .prev_track
    cmp r8d, 0x25
    je .prev_track
    cmp r8d, 0x20
    je .pause_track
    jmp DefWindowProcA

.next_track:
    sub rsp, 40
    call audio_next_track
    add rsp, 40
    jmp .ret_zero

.prev_track:
    sub rsp, 40
    call audio_prev_track
    add rsp, 40
    jmp .ret_zero

.pause_track:
    sub rsp, 40
    call audio_toggle_pause
    add rsp, 40
    jmp .ret_zero

.toggle_hud:
    movss xmm0, [hud_visible]
    ucomiss xmm0, [c_zero]
    ja .hide_hud
    mov eax, [c_pos1]
    mov [hud_visible], eax
    jmp .ret_zero
.hide_hud:
    mov dword [hud_visible], 0
    jmp .ret_zero

.toggle_mute:
    cmp dword [muted_flag], 0
    jne .unmute_vol
    mov eax, [vol_level]
    mov [saved_vol], eax
    mov dword [vol_level], 0
    mov dword [muted_flag], 1
    jmp .ret_zero
.unmute_vol:
    mov eax, [saved_vol]
    mov [vol_level], eax
    mov dword [muted_flag], 0
    jmp .ret_zero

.lbuttondown:
    push rbx
    push rsi
    sub rsp, 40

    movsx ebx, r9w          ; mouseX
    mov esi, r9d
    sar esi, 16             ; mouseY

    mov rcx, [hwnd]
    lea rdx, [rect]
    call GetClientRect
    mov r8d, [rect + 8]     ; clientW

    ; Felso player sav (py: 10..36)
    cmp esi, 10
    jl .chk_hud_sliders
    cmp esi, 36
    jg .chk_hud_sliders

    ; 1. Prev gomb (20..64)
    cmp ebx, 20
    jl .chk_hud_sliders
    cmp ebx, 64
    jg .chk_btn_play
    call audio_prev_track
    jmp .lbtn_done

.chk_btn_play:
    ; 2. Play/Pause gomb (70..114)
    cmp ebx, 70
    jl .chk_hud_sliders
    cmp ebx, 114
    jg .chk_btn_next
    call audio_toggle_pause
    jmp .lbtn_done

.chk_btn_next:
    ; 3. Next gomb (120..164)
    cmp ebx, 120
    jl .chk_hud_sliders
    cmp ebx, 164
    jg .chk_seek_bar
    call audio_next_track
    jmp .lbtn_done

.chk_seek_bar:
    ; 4. Gyorstekero-bar (W-434 .. W-172)
    mov eax, r8d
    sub eax, 434
    cmp ebx, eax
    jl .chk_spk_icon
    mov eax, r8d
    sub eax, 172
    cmp ebx, eax
    jg .chk_spk_icon
    mov dword [drag_mode], 2
    call apply_seek_mouse
    jmp .lbtn_done

.chk_spk_icon:
    ; 5. Hangszoro mute ikon (W-162 .. W-141)
    mov eax, r8d
    sub eax, 162
    cmp ebx, eax
    jl .chk_vol_bar
    mov eax, r8d
    sub eax, 141
    cmp ebx, eax
    jg .chk_vol_bar
    cmp dword [muted_flag], 0
    jne .spk_unmute
    mov eax, [vol_level]
    mov [saved_vol], eax
    mov dword [vol_level], 0
    mov dword [muted_flag], 1
    jmp .lbtn_done
.spk_unmute:
    mov eax, [saved_vol]
    mov [vol_level], eax
    mov dword [muted_flag], 0
    jmp .lbtn_done

.chk_vol_bar:
    ; 6. Hangero csuszka (W-142 .. W-20)
    mov eax, r8d
    sub eax, 142
    cmp ebx, eax
    jl .chk_hud_sliders
    mov eax, r8d
    sub eax, 20
    cmp ebx, eax
    jg .chk_hud_sliders
    mov dword [drag_mode], 3
    call apply_vol_mouse
    jmp .lbtn_done

.chk_hud_sliders:
    movss xmm0, [hud_visible]
    ucomiss xmm0, [c_zero]
    jbe .lbtn_done

    cmp ebx, 16
    jl .lbtn_done
    cmp ebx, 224
    jg .lbtn_done

    xor edx, edx
.check_band:
    mov r10d, edx
    imul r10d, 28
    add r10d, 60
    sub r10d, esi
    cmp r10d, -12
    jl .next_band
    cmp r10d, 12
    jg .next_band

    mov dword [drag_mode], 1
    mov [active_sldr], edx
    call .update_hud_slider
    jmp .lbtn_done

.next_band:
    inc edx
    cmp edx, 5
    jl .check_band

.lbtn_done:
    add rsp, 40
    pop rsi
    pop rbx
    jmp .ret_zero

.lbuttonup:
    mov dword [drag_mode], 0
    mov dword [active_sldr], -1
    jmp .ret_zero

.mousemove:
    mov eax, [drag_mode]
    test eax, eax
    jz .ret_zero

    push rbx
    push rsi
    sub rsp, 40

    movsx ebx, r9w          ; mouseX
    mov esi, [drag_mode]

    mov rcx, [hwnd]
    lea rdx, [rect]
    call GetClientRect
    mov r8d, [rect + 8]     ; clientW

    cmp esi, 2
    jne .mm_chk_vol
    call apply_seek_mouse
    jmp .mm_done

.mm_chk_vol:
    cmp esi, 3
    jne .mm_chk_hud
    call apply_vol_mouse
    jmp .mm_done

.mm_chk_hud:
    mov edx, [active_sldr]
    cmp edx, 0
    jl .mm_done
    cmp edx, 4
    jg .mm_done
    call .update_hud_slider

.mm_done:
    add rsp, 40
    pop rsi
    pop rbx
    jmp .ret_zero

.update_hud_slider:
    mov eax, ebx
    sub eax, 24
    test eax, eax
    jns .s_min_ok
    xor eax, eax
.s_min_ok:
    cmp eax, 186
    jle .s_max_ok
    mov eax, 186
.s_max_ok:
    cvtsi2ss xmm0, eax
    mov eax, 186
    cvtsi2ss xmm1, eax
    divss xmm0, xmm1
    lea r10, [slider0]
    movss [r10 + rdx * 4], xmm0
    ret

.destroy:
    sub rsp, 40
    xor ecx, ecx
    call PostQuitMessage
    add rsp, 40
.ret_zero:
    xor eax, eax
    ret
