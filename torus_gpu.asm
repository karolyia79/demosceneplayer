; ============================================================================
; Chrome Torus - Modern Win64 Pure x86-64 Assembly + GLSL Demoscene Engine
; Features:
;   - Volumetric Raymarched God Rays & Shadowed Light Scattering
;   - Real-time Raymarched Mirror Floor with Bass Shockwave Ripples ([G])
;   - Kinetic Outer Orbiting Shard Ring ([C])
;   - Modern PBR-style Materials: Chrome / Obsidian Magma / Iridescent Glass ([W])
;   - 5-shape SDF Morphing: Torus, Plasma, Menger, Rings, Metaballs ([0-5])
;   - Beat-Synced Camera Kick Punch & Digital Micro-Glitch ([X])
;   - Real-time WASAPI Loopback 32-band Goertzel FFT + 64k ASM Synth ([S])
; ============================================================================

[BITS 64]
default rel

%define MAX_TRACKS 32
%define MAX_SCROLL 192
%define FFT_N      256
%define SYNTH_SAMPLES 4096
%define SYNTH_BYTES   (SYNTH_SAMPLES * 2)

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
extern GetWindowRect
extern GetWindowLongPtrA
extern SetWindowLongPtrA
extern SetWindowPos
extern MonitorFromWindow
extern GetMonitorInfoA
extern MessageBoxA
extern ExitProcess
extern FindFirstFileA
extern FindNextFileA
extern FindClose
extern GetFullPathNameA
extern lstrcpyA
extern lstrcatA
extern LoadLibraryA
extern GetProcAddress
extern QueryPerformanceFrequency
extern QueryPerformanceCounter
extern VirtualAlloc
extern VirtualFree
extern CreateFileA
extern WriteFile
extern CloseHandle

extern wglCreateContext
extern wglMakeCurrent
extern wglGetProcAddress
extern glViewport
extern glRectf
extern glReadPixels
extern glPixelStorei

extern mciSendStringA
extern mciGetErrorStringA
extern waveOutOpen
extern waveOutPrepareHeader
extern waveOutWrite
extern waveOutReset
extern waveOutClose

section .data
    class_name  db "DemoTorus64kUltra", 0
    win_title   db "K79 x86-64 Modern Demo | [0-5] Morph [C] KineticRing [W] Mat [X] Glitch [G] Floor [S] Synth [F11] Full [H] HUD", 0
    err_title   db "GLSL Shader Compile Error", 0
    mci_err_ttl db "MCI Audio Error", 0

    dll_ole32   db "ole32.dll", 0
    dll_shell32 db "shell32.dll", 0
    fn_CoInitializeEx    db "CoInitializeEx", 0
    fn_CoCreateInstance  db "CoCreateInstance", 0
    fn_DragAcceptFiles   db "DragAcceptFiles", 0
    fn_DragQueryFileA    db "DragQueryFileA", 0
    fn_DragFinish        db "DragFinish", 0

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

    ; WASAPI COM GUIDs
    align 4
    CLSID_MMDeviceEnumerator:
        dd 0xBCDE0395
        dw 0xE52F, 0x467C
        db 0x8E, 0x3D, 0xC4, 0x57, 0x92, 0x91, 0x69, 0x2E
    IID_IMMDeviceEnumerator:
        dd 0xA95664D2
        dw 0x9614, 0x4F35
        db 0xA7, 0x46, 0xDE, 0x8D, 0xB6, 0x36, 0x17, 0xE6
    IID_IAudioClient:
        dd 0x1CB9AD4C
        dw 0xDBFA, 0x4C32
        db 0xB1, 0x78, 0xC2, 0xF5, 0x68, 0xA7, 0x03, 0xB2
    IID_IAudioCaptureClient:
        dd 0xC8ADBD64
        dw 0xE71E, 0x48A0
        db 0xA4, 0xDE, 0x18, 0x5C, 0x39, 0x5C, 0xD3, 0x17

    ; Built-in demoscene track metadata
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
    lbl_tail        db " // DEMO: DEMOSCENE ARCHIVE // HW: RETRO & PC // SCENE: DEMOSCENE", 0
    info_synth      db "MODE: 64K PROCEDURAL ASM SYNTH // 5-VOICE CHIP & ACID GROOVE (138 BPM) // VOLUMETRIC RAYMARCHER // PRESS [S] FOR MP3", 0
    tag_synth       db "64K ASM SYNTH", 0

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
    u_fx_name         db "u_fx", 0
    u_demo_name       db "u_demo", 0
    u_bands_name      db "u_bands", 0
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

    ; PCM 44100 Hz 16-bit Mono WAVEFORMATEX for 64k Procedural Synth
    align 4
    synth_wfx:
        dw 1                ; WAVE_FORMAT_PCM
        dw 1                ; nChannels = 1
        dd 44100            ; nSamplesPerSec
        dd 88200            ; nAvgBytesPerSec
        dw 2                ; nBlockAlign
        dw 16               ; wBitsPerSample
        dw 0                ; cbSize

    time        dd 0.0
    dt_step     dd 0.016
    rot_phase   dd 0.0
    mag_phase   dd 0.0

    ; HUD sliders (5)
    slider0     dd 0.22         ; 0. ROT SPD
    slider1     dd 0.18         ; 1. AMBIENT
    slider2     dd 0.34         ; 2. MAG SPD
    slider3     dd 0.44         ; 3. MAG PWR
    slider4     dd 0.65         ; 4. SPIKES

    vol_level   dd 0.80
    saved_vol   dd 0.80
    muted_flag  dd 0
    last_vol_i  dd -1

    max_rot_spd dd 2.0
    max_mag_spd dd 5.0

    hud_visible dd 0.0
    drag_mode   dd 0
    active_sldr dd -1
    paused_flag dd 0

    ; Engine FX state
    morph_mode  dd 1            ; 0=Auto-Morph, 1=Torus, 2=Plasma, 3=Menger, 4=Rings, 5=Metaballs
    morph_val   dd 0.0          ; 0.0 .. 4.0
    grid_on     dd 1.0          ; 1.0 = Raymarched Reflective Ripple Floor ON ([G])
    copper_on   dd 1.0          ; 1.0 = Kinetic Outer Shard Ring ON ([C])
    holo_mode   dd 0            ; 0=Liquid Chrome, 1=Obsidian Magma, 2=Iridescent Glass ([W])
    holo_mode_f dd 0.0
    glitch_on   dd 1.0          ; 1.0 = Beat Kick Punch & Digital Micro-Glitch ON ([X])
    flash_env   dd 0.0          ; F12 screenshot flash
    shot_idx    dd 1
    is_fullscr  dd 0
    synth_mode  dd 0            ; 1 = 64k procedural synth active
    dropped_flg dd 0

    c_neg1      dd -1.0
    c_pos1      dd 1.0
    c_two_f     dd 2.0
    c_zero      dd 0.0
    c_1000      dd 1000.0
    c_space_f   dd 32.0
    c_max_dt    dd 0.10
    c_fps_iv    dd 0.25
    c_flash_dec dd 4.0
    bass_env    dd 0.0
    high_env    dd 0.0
    fps_val_f   dd 60.0
    fps_accum   dd 0.0
    fps_frames  dd 0

    ; Goertzel & Synth constants
    c_f_start   dd 45.0
    c_f_step    dd 1.2035
    c_g_start   dd 0.032
    c_g_step    dd 1.046
    c_two       dd 2.0
    c_half      dd 0.5
    c_atk       dd 0.65
    c_dec       dd 0.84
    c_bass_mul  dd 0.34
    c_high_mul  dd 0.28
    c_i16_scale dd 0.000030517578125 ; 1.0 / 32768.0
    c_synth_out dd 24000.0
    c_44100     dd 44100.0

    ; Chord frequencies for 64k Synth: D2, Bb1, C2, A1 (Hz)
    chord_root  dd 73.416, 58.270, 65.406, 55.000
    ; Arpeggio ratios
    arp_ratios  dd 2.0, 2.3784, 2.9966, 4.0

    track_count  dd 0
    cur_track    dd 0
    track_pos_ms dd 0
    track_len_ms dd 0
    scroll_len   dd 0
    top_len      dd 0

    ; WASAPI state
    wasapi_ok    dd 0
    wfx_rate     dd 48000
    wfx_ch       dd 2
    wfx_bits     dd 32
    wfx_is_float dd 1
    fft_wr_idx   dd 0

    ; Synth state
    hWaveOut     dq 0
    synth_smp_i  dd 0
    synth_lp_y   dd 0.0
    synth_prev_n dd 0.0
    lfsr_state   dd 0xACE1

    align 8
    hInstance    dq 0
    hwnd         dq 0
    hdc          dq 0
    hglrc        dq 0
    hFind        dq 0
    qpc_freq     dq 1
    qpc_last     dq 0
    qpc_now      dq 0
    saved_style  dq 0
    saved_rect   times 4 dd 0
    mon_info     times 10 dd 0

    pCoInitializeEx   dq 0
    pCoCreateInstance dq 0
    pDragAcceptFiles  dq 0
    pDragQueryFileA   dq 0
    pDragFinish       dq 0

    pEnumerator    dq 0
    pDevice        dq 0
    pAudioClient   dq 0
    pCaptureClient dq 0
    pwfx           dq 0

    msg           times 48 db 0
    rect          times 4 dd 0
    find_data     times 320 db 0
    dropped_path  times 260 db 0
    rel_path_buf  times 260 db 0
    full_path_buf times 260 db 0
    shot_name     times 32 db 0
    mci_cmd_buf   times 640 db 0
    mci_ret_buf   times 64 db 0
    mci_err_buf   times 256 db 0
    scroller_txt  times 256 db 0
    top_txt       times 64 db 0
    u_scroll_arr  times MAX_SCROLL dd 32.0
    u_top_arr     times 32 dd 32.0
    u_bands       times 32 dd 0.0
    goertzel_c    times 32 dd 0.0
    goertzel_g    times 32 dd 0.0
    fft_ring      times 512 dd 0.0

    align 8
    whdr0        times 48 db 0
    whdr1        times 48 db 0
    synth_buf0   times SYNTH_BYTES db 0
    synth_buf1   times SYNTH_BYTES db 0

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
    u_fx_loc         dd 0
    u_demo_loc       dd 0
    u_bands_loc      dd 0
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
        db "uniform vec4 u_fx;", 10
        db "uniform vec4 u_demo;", 10
        db "uniform vec4 u_bands[8];", 10
        db "uniform vec4 u_scroll[48];", 10
        db "uniform int u_scroll_len;", 10
        db "uniform vec4 u_top[8];", 10
        db "uniform int u_top_len;", 10
        db "mat2 rot(float a){float s=sin(a),c=cos(a);return mat2(c,-s,s,c);}", 10
        db "float smin(float a, float b, float k){", 10
        db "  float h=clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);", 10
        db "  return mix(b, a, h)-k*h*(1.0-h);", 10
        db "}", 10
        db "float getBand(int idx){", 10
        db "  int vIdx=idx/4;", 10
        db "  int cIdx=idx-vIdx*4;", 10
        db "  vec4 v=vec4(0.0);", 10
        db "  for(int i=0;i<8;i++){ if(i==vIdx){ v=u_bands[i]; break; } }", 10
        db "  return (cIdx==0)?v.x:((cIdx==1)?v.y:((cIdx==2)?v.z:v.w));", 10
        db "}", 10
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
        db "  vec3 p=vec3(1.25*(1.0-cos(th)),1.25*sin(th),0.0);", 10
        db "  mat2 rA=rot(-a);", 10
        db "  p.yz*=rA; p.xz*=rA;", 10
        db "  return p;", 10
        db "}", 10
        db "vec3 cubePos(float th, float a){", 10
        db "  float oppTh=th+3.14159265;", 10
        db "  vec3 p=vec3(1.25*(1.0-cos(oppTh)), -1.25*sin(oppTh), 0.42);", 10
        db "  mat2 rA=rot(-a);", 10
        db "  p.yz*=rA; p.xz*=rA;", 10
        db "  return p;", 10
        db "}", 10
        db "float sdRoundBox(vec3 p, vec3 b, float r){", 10
        db "  vec3 q=abs(p)-b;", 10
        db "  return length(max(q,0.0))+min(max(q.x,max(q.y,q.z)),0.0)-r;", 10
        db "}", 10
        ; --- Shape 0: Warped Chrome Torus ---
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
        db "    d+=gyroid(w,5.8,u_time*1.9)*(0.015+0.006*sin(u_time*1.13))*orgMix;", 10
        db "    d+=gyroid(w.yzx,12.7,-u_time*2.75)*(0.007+0.003*cos(u_time*1.89))*orgMix;", 10
        db "    d-=sp*0.095;", 10
        db "  }", 10
        db "  return d;", 10
        db "}", 10
        ; --- Shape 1: Spiky Ferrofluid Plasma Star ---
        db "float mapPlasma(vec3 p){", 10
        db "  float a=u_phases.x;", 10
        db "  float bass=u_extra.y;", 10
        db "  mat2 rA=rot(a*1.1);", 10
        db "  p.xz*=rA; p.xy*=rA;", 10
        db "  float r=1.08+0.12*bass;", 10
        db "  float d=length(p)-r;", 10
        db "  if(d<0.45){", 10
        db "    float g1=gyroid(p, 4.2, u_time*2.1);", 10
        db "    float g2=gyroid(p.yzx, 8.5, -u_time*3.0);", 10
        db "    float sp=spikeField(p*1.15);", 10
        db "    d+=g1*(0.08+0.06*bass)+g2*0.035-sp*0.18;", 10
        db "  }", 10
        db "  return d;", 10
        db "}", 10
        ; --- Shape 2: Iterated Menger Fractal Sponge ---
        db "float mapMenger(vec3 p){", 10
        db "  float a=u_phases.x;", 10
        db "  float bass=u_extra.y;", 10
        db "  mat2 rA=rot(a*0.85);", 10
        db "  p.xz*=rA; p.yz*=rot(a*0.65);", 10
        db "  float sc=1.0+0.08*bass;", 10
        db "  p/=sc;", 10
        db "  float d=sdRoundBox(p, vec3(0.95), 0.03);", 10
        db "  float s=1.0;", 10
        db "  for(int m=0;m<3;m++){", 10
        db "    vec3 a3=mod(p*s, 2.0)-1.0;", 10
        db "    s*=3.0;", 10
        db "    vec3 r=abs(1.0-3.0*abs(a3));", 10
        db "    float da=max(r.x,r.y);", 10
        db "    float db=max(r.y,r.z);", 10
        db "    float dc=max(r.z,r.x);", 10
        db "    float c=(min(da,min(db,dc))-1.0)/s;", 10
        db "    d=max(d, c);", 10
        db "  }", 10
        db "  return d*sc;", 10
        db "}", 10
        ; --- Shape 3: Braided Interlocking Double Rings ---
        db "float mapRings(vec3 p){", 10
        db "  float a=u_phases.x;", 10
        db "  float bass=u_extra.y;", 10
        db "  mat2 rA=rot(a);", 10
        db "  p.xz*=rA; p.yz*=rA;", 10
        db "  vec3 p1=p; p1.xy*=rot(0.55+0.2*sin(u_time));", 10
        db "  vec3 p2=p; p2.yz*=rot(1.02-0.2*cos(u_time));", 10
        db "  float rMaj=1.18+0.08*bass;", 10
        db "  float rMin=0.26+0.04*bass;", 10
        db "  float d1=length(vec2(length(p1.xz)-rMaj, p1.y))-rMin;", 10
        db "  float d2=length(vec2(length(p2.xy)-rMaj, p2.z))-rMin;", 10
        db "  float d=min(d1, d2);", 10
        db "  if(d<0.22) d-=spikeField(p)*0.07;", 10
        db "  return d;", 10
        db "}", 10
        ; --- Shape 4: Smooth Liquid Metaballs ---
        db "float mapMetaballs(vec3 p){", 10
        db "  float a=u_phases.x;", 10
        db "  float bass=u_extra.y;", 10
        db "  mat2 rA=rot(a);", 10
        db "  p.xz*=rA; p.yz*=rA;", 10
        db "  float d=10.0;", 10
        db "  for(int i=0;i<6;i++){", 10
        db "    float fi=float(i);", 10
        db "    float t=u_time*(1.35+0.15*fi)+fi*1.0472;", 10
        db "    vec3 bp=vec3(sin(t*1.1+fi), cos(t*0.9-fi*0.7), sin(t*1.3+fi*1.4))*(0.74+0.15*bass);", 10
        db "    float r=0.33+0.05*sin(u_time*3.0+fi)+0.05*bass;", 10
        db "    d=smin(d, length(p-bp)-r, 0.36);", 10
        db "  }", 10
        db "  return d;", 10
        db "}", 10
        db "float evalShape(int id, vec3 p){", 10
        db "  if(id==0) return mapTorus(p);", 10
        db "  if(id==1) return mapPlasma(p);", 10
        db "  if(id==2) return mapMenger(p);", 10
        db "  if(id==3) return mapRings(p);", 10
        db "  return mapMetaballs(p);", 10
        db "}", 10
        db "float mapMainObj(vec3 p){", 10
        db "  float mv=clamp(u_fx.x, 0.0, 4.0);", 10
        db "  int s0=int(floor(mv));", 10
        db "  float fr=mv-float(s0);", 10
        db "  float d0=evalShape(s0, p);", 10
        db "  if(fr<0.001) return d0;", 10
        db "  int s1=(s0<4)?(s0+1):4;", 10
        db "  float d1=evalShape(s1, p);", 10
        db "  return mix(d0, d1, smoothstep(0.0, 1.0, fr));", 10
        db "}", 10
        db "float mapCube(vec3 p){", 10
        db "  float a=u_phases.x, th=u_phases.y;", 10
        db "  vec3 cp=cubePos(th, a);", 10
        db "  vec3 q=p-cp;", 10
        db "  q.xy*=rot(u_time*1.3); q.yz*=rot(-u_time*0.95);", 10
        db "  return sdRoundBox(q, vec3(0.16), 0.02);", 10
        db "}", 10
        ; --- Kinetic Outer Orbiting Shard Ring ([C]) ---
        db "float mapKineticRing(vec3 p){", 10
        db "  if(u_demo.x<0.5) return 99.0;", 10
        db "  float bass=u_extra.y;", 10
        db "  p.xy*=rot(0.32*sin(u_time*0.4));", 10
        db "  p.xz*=rot(-u_time*0.55);", 10
        db "  float ang=atan(p.z, p.x);", 10
        db "  float seg=6.2831853/16.0;", 10
        db "  float id=floor((ang+3.14159265)/seg);", 10
        db "  float a=mod(ang+3.14159265, seg)-0.5*seg;", 10
        db "  float rad=length(p.xz);", 10
        db "  float rOff=2.12+0.14*sin(id*2.1+u_time*3.2)+0.18*bass*fract(sin(id*17.3)*437.5);", 10
        db "  vec3 q=vec3(rad-rOff, p.y-0.12*cos(id*1.7-u_time*2.6), a*rad);", 10
        db "  q.xy*=rot(id*0.4+u_time*1.4);", 10
        db "  return sdRoundBox(q, vec3(0.045, 0.035, 0.13), 0.008);", 10
        db "}", 10
        db "float map(vec3 p){", 10
        db "  float d=min(mapMainObj(p), mapCube(p));", 10
        db "  return min(d, mapKineticRing(p));", 10
        db "}", 10
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
        db "  vec3 e=mix(vec3(0.04,0.03,0.09), vec3(0.55,0.82,1.0), hy);", 10
        db "  float band=0.5+0.5*sin(r.x*8.0+r.y*10.0+u_time*1.5);", 10
        db "  e+=vec3(0.18,0.24,0.34)*band*band;", 10
        db "  vec3 ldir=normalize(lm);", 10
        db "  float sun=pow(max(dot(normalize(r), ldir), 0.0), 32.0);", 10
        db "  e+=vec3(1.6,2.1,2.6)*magI*sun*(0.7+0.3*bass);", 10
        db "  return e;", 10
        db "}", 10
        ; --- Shade Surface Helper (shared between Primary Ray & Mirror Floor Reflection) ---
        db "vec3 shadeHit(vec3 p, vec3 rd, vec3 lm, float magI, float bass, float amb){", 10
        db "  float a=u_phases.x;", 10
        db "  vec3 n=calcNormal(p);", 10
        db "  float ao=calcAO(p, n);", 10
        db "  vec3 ldir=lm-p; float dist=length(ldir); ldir/=dist;", 10
        db "  float sh=calcSoftShadow(p+n*0.015, ldir, dist);", 10
        db "  float atten=1.0/(1.0+0.26*dist*dist);", 10
        db "  float diff=max(dot(n,ldir),0.0);", 10
        db "  float spec=pow(diff,56.0);", 10
        db "  float ndv=max(dot(n,-rd),0.0);", 10
        db "  float fres=0.65+0.35*pow(1.0-ndv,3.0);", 10
        db "  vec3 reflDir=reflect(rd, n);", 10
        db "  vec3 reflCol=envReflect(reflDir, lm-p, magI, bass);", 10
        db "  float rt=0.04, rhit=0.0;", 10
        db "  for(int j=0;j<12;j++){", 10
        db "    vec3 rp=p+n*0.02+reflDir*rt;", 10
        db "    if(dot(rp,rp)>8.41) break;", 10
        db "    float rdStep=map(rp);", 10
        db "    if(rdStep<0.008){ rhit=1.0; break; }", 10
        db "    rt+=clamp(rdStep*0.70, 0.03, 0.38);", 10
        db "    if(rt>3.2) break;", 10
        db "  }", 10
        db "  if(rhit>0.5){", 10
        db "    vec3 rp=p+n*0.02+reflDir*rt;", 10
        db "    vec3 rn=calcNormal(rp);", 10
        db "    float rdiff=max(dot(rn, normalize(lm-rp)), 0.0);", 10
        db "    reflCol=mix(reflCol, vec3(0.85,0.92,1.0)*(0.25+0.95*rdiff)*magI, 0.72);", 10
        db "  }", 10
        db "  float dMain=mapMainObj(p);", 10
        db "  float dCube=mapCube(p);", 10
        db "  float dRing=mapKineticRing(p);", 10
        db "  float isCube=step(dCube, dMain)*step(dCube, dRing);", 10
        db "  float isRing=step(dRing, dMain)*step(dRing, dCube);", 10
        db "  vec3 pr=p; mat2 rA=rot(a); pr.xz*=rA; pr.yz*=rA;", 10
        db "  float spVal=spikeField(pr);", 10
        db "  float orgBoost=clamp(1.0 - spVal*3.0, 0.25, 1.0);", 10
        db "  float spGlow=clamp(spVal*5.5, 0.0, 1.0);", 10
        db "  vec3 chromeBase=vec3(0.76,0.82,0.90);", 10
        db "  vec3 cubeBase=vec3(0.95,0.58,0.25);", 10
        db "  vec3 ringBase=vec3(0.22,0.82,1.0);", 10
        db "  vec3 baseCol=mix(chromeBase, cubeBase, isCube);", 10
        db "  baseCol=mix(baseCol, ringBase, isRing);", 10
        db "  float reflAmt=mix(0.78*fres*(0.6+0.4*orgBoost), 0.35*fres, isCube);", 10
        db "  vec3 c=baseCol*(amb+0.08)*ao;", 10
        db "  c=mix(c, baseCol*reflCol, reflAmt);", 10
        db "  c+=vec3(1.8,2.25,2.7)*magI*(diff*sh*0.55+spec*sh*1.8)*atten*(0.35+0.65*ao);", 10
        db "  c+=(1.0-isCube)*(1.0-isRing)*vec3(0.25,0.85,1.25)*spGlow*(0.35+0.65*diff);", 10
        db "  c+=isRing*vec3(0.15,0.75,1.0)*(0.35+0.55*bass);", 10
        ; Modern PBR Material Switcher ([W]: 0=Liquid Chrome, 1=Obsidian Magma, 2=Iridescent Glass)
        db "  if(u_demo.y>0.5 && u_demo.y<1.5){", 10
        db "    float crack=smoothstep(0.32, 0.92, abs(gyroid(pr, 6.2, u_time*0.8)));", 10
        db "    float rim=pow(1.0-ndv, 2.2);", 10
        db "    vec3 obs=vec3(0.05,0.06,0.08)*(0.3+0.7*diff)+reflCol*0.28*fres;", 10
        db "    vec3 lava=mix(vec3(1.0,0.18,0.03), vec3(1.0,0.85,0.25), crack)*(0.55+1.35*bass)*(1.0-crack*0.45+spGlow);", 10
        db "    c=obs+lava*(0.35+0.65*rim)+vec3(1.0,0.45,0.15)*spec*0.55;", 10
        db "  } else if(u_demo.y>=1.5){", 10
        db "    vec3 irid=0.5+0.5*cos(vec3(0.0,2.1,4.2)+ndv*7.5+u_time*1.4);", 10
        db "    float rim=pow(1.0-ndv, 1.6);", 10
        db "    c=mix(reflCol*1.15, irid*1.45, 0.35+0.55*rim)+vec3(1.0)*spec*1.4;", 10
        db "  }", 10
        db "  return c;", 10
        db "}", 10
        ; --- Real 32-Channel, 28-Segment LED Spectrum Analyzer ---
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
        db "  float isAct=(u_player.z<0.5 && u_extra.w<0.5)?1.0:0.0;", 10
        db "  float bass=u_extra.y;", 10
        db "  float lvl=clamp(getBand(int(chIdx))*isAct, 0.0, 0.98);", 10
        db "  float peakLvl=clamp(lvl+0.07*isAct, 0.0, 0.99);", 10
        db "  float litSeg=floor(lvl*28.0);", 10
        db "  float peakSeg=floor(peakLvl*28.0);", 10
        db "  vec3 ledCol=mix(vec3(0.08,0.58,0.92), vec3(0.18,0.92,0.68), clamp(hNorm*1.6,0.0,1.0));", 10
        db "  ledCol=mix(ledCol, vec3(1.0,0.76,0.18), smoothstep(0.55,0.82,hNorm));", 10
        db "  ledCol=mix(ledCol, vec3(1.0,0.24,0.36), smoothstep(0.82,0.96,hNorm));", 10
        db "  if(segIdx<=litSeg && lvl>0.01){", 10
        db "    return ledCol*(0.55+0.30*bass);", 10
        db "  }", 10
        db "  if(abs(segIdx-peakSeg)<0.5 && lvl>0.03){", 10
        db "    return ledCol*0.85;", 10
        db "  }", 10
        db "  return vec3(0.018,0.028,0.052);", 10
        db "}", 10
        ; --- Deep Space Dust / Starfield ---
        db "vec3 starField(vec2 uv, float bass){", 10
        db "  vec3 sCol=vec3(0.0);", 10
        db "  for(int l=0;l<3;l++){", 10
        db "    float fl=float(l)+1.0;", 10
        db "    float spd=u_time*(0.15+0.08*fl)+bass*0.04*fl;", 10
        db "    vec2 p=uv*(3.5+fl*2.2)+vec2(sin(fl*12.3), cos(fl*7.1))*spd;", 10
        db "    vec2 id=floor(p);", 10
        db "    vec2 gv=fract(p)-0.5;", 10
        db "    float rnd=fract(sin(dot(id, vec2(127.1,311.7)))*43758.5453);", 10
        db "    if(rnd>0.72){", 10
        db "      vec2 off=vec2(fract(rnd*19.1)-0.5, fract(rnd*47.3)-0.5)*0.6;", 10
        db "      float d=length(gv-off);", 10
        db "      float tw=0.55+0.45*sin(u_time*4.5+rnd*30.0);", 10
        db "      float st=smoothstep(0.055, 0.0, d)*tw*(0.42/fl);", 10
        db "      sCol+=mix(vec3(0.55,0.82,1.0), vec3(0.95,0.85,1.0), fract(rnd*7.0))*st;", 10
        db "    }", 10
        db "  }", 10
        db "  return sCol;", 10
        db "}", 10
        db "float glyph(int ch, vec2 p){", 10
        db "  int col=int(floor(p.x));", 10
        db "  int row=int(floor(p.y));", 10
        db "  if(col<0||col>4||row<0||row>6) return 0.0;", 10
        db "  vec2 m=vec2(0.0);", 10
        db "  if(ch==33) m=vec2(135300.0,132.0);", 10
        db "  if(ch==38) m=vec2(412053.0,19021.0);", 10
        db "  if(ch==39) m=vec2(135296.0,0.0);", 10
        db "  if(ch==40) m=vec2(69896.0,8322.0);", 10
        db "  if(ch==41) m=vec2(266306.0,2184.0);", 10
        db "  if(ch==43) m=vec2(4254.0,4224.0);", 10
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
        ; --- Modern Volumetric Raymarcher + Reflective Ripple Floor + God Rays ---
        db "vec3 renderScene(vec2 uv){", 10
        db "  float bass=u_extra.y;", 10
        db "  float high=u_demo.w;", 10
        db "  float kickPunch=smoothstep(0.55, 0.98, bass)*u_demo.z;", 10
        db "  float camA=sin(u_time*0.28)*0.24;", 10
        db "  float camZ=-3.45+0.12*cos(u_time*0.35)-0.26*kickPunch;", 10
        db "  vec2 shake=vec2(sin(u_time*73.0), cos(u_time*91.0))*(0.020*kickPunch + 0.014*smoothstep(0.52,0.95,high)*u_demo.z);", 10
        db "  vec3 ro=vec3(sin(camA)*3.45+shake.x, 0.28+0.16*sin(u_time*0.4)+shake.y, camZ);", 10
        db "  vec3 rd=normalize(vec3(uv*1.48, 1.0));", 10
        db "  rd.xz*=rot(-camA*0.85);", 10
        db "  float a=u_phases.x, th=u_phases.y;", 10
        db "  vec3 lm=magPos(th, a);", 10
        db "  float t=9.0;", 10
        db "  float b=dot(ro,rd);", 10
        db "  float c=dot(ro,ro)-8.41;", 10
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
        db "    vec3 p=ro+rd*t;", 10
        db "    col=shadeHit(p, rd, lm, magI, bass, amb);", 10
        db "  } else {", 10
        db "    float horizon=gl_FragCoord.y/u_res.y;", 10
        db "    col=vec3(0.008,0.012,0.028+0.045*horizon)+vec3(0.008,0.016,0.032)*bass;", 10
        db "    col+=starField(uv, bass);", 10
        db "    float sPy=u_res.y-gl_FragCoord.y;", 10
        db "    col+=vuMeter(gl_FragCoord.x, sPy);", 10
        ; Raymarched Dark Mirror Floor with Bass Shockwave Ripples (y = -1.78, [G])
        db "    if(u_fx.y>0.5 && rd.y<-0.005){", 10
        db "      float tf=(-1.78-ro.y)/rd.y;", 10
        db "      if(tf>0.0 && tf<32.0){", 10
        db "        vec3 fp=ro+rd*tf;", 10
        db "        float rDist=length(fp.xz);", 10
        db "        float rip=sin(rDist*4.5-u_time*4.8)*exp(-rDist*0.24)*(0.035+0.055*bass);", 10
        db "        vec3 fNorm=normalize(vec3(fp.x*rip*0.35, 1.0, fp.z*rip*0.35));", 10
        db "        vec3 rDir=reflect(rd, fNorm);", 10
        db "        float rt=0.05, rHit=0.0;", 10
        db "        for(int ri=0;ri<28;ri++){", 10
        db "          vec3 rp=fp+rDir*rt;", 10
        db "          if(dot(rp,rp)>8.5 && rt>3.2) break;", 10
        db "          float rStep=map(rp);", 10
        db "          if(rStep<0.012){ rHit=1.0; break; }", 10
        db "          rt+=clamp(rStep*0.65, 0.04, 0.35);", 10
        db "          if(rt>7.0) break;", 10
        db "        }", 10
        db "        vec3 floorRefl=envReflect(rDir, lm-fp, magI, bass)*0.32;", 10
        db "        if(rHit>0.5){", 10
        db "          floorRefl=shadeHit(fp+rDir*rt, rDir, lm, magI, bass, amb);", 10
        db "        }", 10
        db "        float lDist2=dot(fp-lm, fp-lm);", 10
        db "        vec3 poolLight=vec3(0.28,0.68,1.0)*magI/(1.0+lDist2*0.28);", 10
        db "        float shockRing=smoothstep(0.86, 0.99, sin(rDist*3.2-u_time*5.2))*exp(-rDist*0.22)*bass;", 10
        db "        float fresFloor=pow(1.0-max(dot(fNorm,-rd),0.0), 3.0);", 10
        db "        float fog=exp(-tf*0.095);", 10
        db "        vec3 fCol=vec3(0.012,0.016,0.030)+poolLight*0.55+floorRefl*(0.24+0.52*fresFloor)+vec3(0.2,0.85,1.0)*shockRing*0.75;", 10
        db "        col=mix(col, fCol, fog*0.92);", 10
        db "        t=tf;", 10
        db "      }", 10
        db "    }", 10
        db "  }", 10
        ; Volumetric Raymarched God Rays / Shadowed Light Scattering
        db "  if(magI>0.01){", 10
        db "    float tEnd=min(t, 6.2);", 10
        db "    float stepV=tEnd/22.0;", 10
        db "    float jit=fract(sin(dot(gl_FragCoord.xy, vec2(12.9898,78.233)))*43758.5453);", 10
        db "    vec3 volAcc=vec3(0.0);", 10
        db "    for(int vi=0;vi<22;vi++){", 10
        db "      float tv=(float(vi)+jit)*stepV;", 10
        db "      vec3 vp=ro+rd*tv;", 10
        db "      vec3 toL=lm-vp;", 10
        db "      float dL=length(toL);", 10
        db "      float occ=clamp(map(vp+normalize(toL)*min(dL*0.5, 0.45))*4.5, 0.15, 1.0);", 10
        db "      float phase=1.0/(1.0+dL*dL*1.45);", 10
        db "      volAcc+=vec3(0.32,0.74,1.0)*phase*occ;", 10
        db "    }", 10
        db "    col+=volAcc*stepV*magI*(0.24+0.18*bass);", 10
        ; Orbiting light trail + Anamorphic Lens Flare
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
        db "    vec3 lRel=lm-ro; lRel.xz*=rot(camA*0.85);", 10
        db "    if(lRel.z>0.2 && length(lRel)<t){", 10
        db "      vec2 lUV=lRel.xy/(lRel.z*1.48);", 10
        db "      float streak=exp(-abs(uv.y-lUV.y)*65.0)*exp(-abs(uv.x-lUV.x)*2.4);", 10
        db "      col+=vec3(0.35,0.85,1.0)*streak*magI*(0.32+0.35*bass);", 10
        db "    }", 10
        db "  }", 10
        db "  return col;", 10
        db "}", 10
        db "void main(){", 10
        db "  float bass=u_extra.y;", 10
        db "  float high=u_demo.w;", 10
        db "  vec2 uv=(gl_FragCoord.xy-0.5*u_res)/u_res.y;", 10
        db "  vec2 sUv=uv;", 10
        db "  float glitchTrig=max(smoothstep(0.64,0.98,bass), smoothstep(0.60,0.95,high))*u_demo.z;", 10
        db "  if(glitchTrig>0.01){", 10
        db "    float bandId=floor(gl_FragCoord.y/14.0);", 10
        db "    float rnd=fract(sin(bandId*91.7+floor(u_time*30.0)*17.3)*43758.5453);", 10
        db "    if(rnd>0.78) sUv.x+=(rnd-0.89)*0.16*glitchTrig;", 10
        db "  }", 10
        db "  vec3 col=renderScene(sUv);", 10
        db "  vec2 caPix=uv*((2.4+8.5*bass+5.0*glitchTrig)*dot(uv,uv));", 10
        db "  vec3 grad=dFdx(col)*caPix.x+dFdy(col)*caPix.y;", 10
        db "  col.r+=grad.r;", 10
        db "  col.b-=grad.b;", 10
        db "  col*=1.0-0.26*dot(uv,uv);", 10
        db "  col=col/(1.0+col*0.24);", 10
        db "  col=pow(clamp(col,0.0,1.0),vec3(0.85));", 10
        db "  col=mix(col, vec3(1.0), clamp(u_fx.w, 0.0, 1.0));", 10
        db "  float px=gl_FragCoord.x;", 10
        db "  float py=u_res.y-gl_FragCoord.y;", 10
        ; --- TOP PLAYER BAR (py: 8..38) ---
        db "  if(py>=8.0 && py<=38.0 && px>=12.0 && px<=u_res.x-12.0){", 10
        db "    col=mix(col,vec3(0.03,0.06,0.12),0.86);", 10
        db "    if(py<9.5||py>36.5||px<13.5||px>u_res.x-13.5) col=vec3(0.25,0.65,0.95);", 10
        ; 1. Prev button (20..64)
        db "    if(px>=20.0 && px<=64.0 && py>=12.0 && py<=34.0){", 10
        db "      col=mix(col,vec3(0.12,0.22,0.36),0.75);", 10
        db "      if(abs(px-36.0)<1.3 && abs(py-23.0)<5.5) col=vec3(0.4,0.9,1.0);", 10
        db "      float ptx=48.0-px; float pty=abs(py-23.0);", 10
        db "      if(ptx>=0.0 && ptx<=9.0 && pty<=(9.0-ptx)*0.6) col=vec3(0.4,0.9,1.0);", 10
        db "    }", 10
        ; 2. Play/Pause button (70..114)
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
        ; 3. Next button (120..164)
        db "    if(px>=120.0 && px<=164.0 && py>=12.0 && py<=34.0){", 10
        db "      col=mix(col,vec3(0.12,0.22,0.36),0.75);", 10
        db "      float ntx=px-136.0; float nty=abs(py-23.0);", 10
        db "      if(ntx>=0.0 && ntx<=9.0 && nty<=(9.0-ntx)*0.6) col=vec3(0.4,0.9,1.0);", 10
        db "      if(abs(px-148.0)<1.3 && abs(py-23.0)<5.5) col=vec3(0.4,0.9,1.0);", 10
        db "    }", 10
        ; Layout anchors from right edge
        db "    float seekX0=u_res.x-430.0;", 10
        db "    float seekX1=u_res.x-176.0;", 10
        db "    float timeX0=seekX0-144.0;", 10
        db "    float fpsX0=timeX0-86.0;", 10
        ; 4. Track title (174 .. fpsX0-10)
        db "    if(px>=174.0 && px<fpsX0-10.0 && py>=14.0 && py<=32.0){", 10
        db "      int tci=int(floor((px-174.0)/14.0));", 10
        db "      if(tci>=0 && tci<u_top_len){", 10
        db "        float tCellX=mod(px-174.0,14.0);", 10
        db "        if(tCellX>=1.0 && tCellX<12.5){", 10
        db "          vec2 tgp=vec2((tCellX-1.0)/2.3, (py-14.5)/2.4);", 10
        db "          if(glyph(topChar(tci),tgp)>0.5) col=vec3(0.96,0.93,0.68)*(1.0+0.18*bass);", 10
        db "        }", 10
        db "      }", 10
        db "    }", 10
        ; 4b. Live FPS readout (fpsX0 .. fpsX0+74, 6 chars: XXXFPS)
        db "    if(px>=fpsX0 && px<fpsX0+74.0 && py>=15.0 && py<=31.0){", 10
        db "      int fci=int(floor((px-fpsX0)/12.0));", 10
        db "      float fCellX=mod(px-fpsX0,12.0);", 10
        db "      if(fCellX>=1.0 && fCellX<11.0){", 10
        db "        vec2 fgp=vec2((fCellX-1.0)/2.0, (py-15.5)/2.1);", 10
        db "        int fpsI=int(floor(u_fx.z+0.5));", 10
        db "        int fch=32;", 10
        db "        if(fci==0){ int h=fpsI/100; if(h>9)h=9; fch=(h>0)?(48+h):32; }", 10
        db "        if(fci==1){ int t=(fpsI/10)-(fpsI/100)*10; fch=(fpsI>=10)?(48+t):32; }", 10
        db "        if(fci==2) fch=48+(fpsI-(fpsI/10)*10);", 10
        db "        if(fci==3) fch=70;", 10
        db "        if(fci==4) fch=80;", 10
        db "        if(fci==5) fch=83;", 10
        db "        if(glyph(fch,fgp)>0.5) col=vec3(0.32,0.95,0.68);", 10
        db "      }", 10
        db "    }", 10
        ; 4c. MM:SS/MM:SS Time readout (timeX0 .. timeX0+132, 11 chars)
        db "    if(px>=timeX0 && px<timeX0+132.0 && py>=15.0 && py<=31.0){", 10
        db "      int mci=int(floor((px-timeX0)/12.0));", 10
        db "      float mCellX=mod(px-timeX0,12.0);", 10
        db "      if(mCellX>=1.0 && mCellX<11.0){", 10
        db "        vec2 mgp=vec2((mCellX-1.0)/2.0, (py-15.5)/2.1);", 10
        db "        int pSec=int(floor(u_player.x*0.001));", 10
        db "        int lSec=int(floor(u_player.y*0.001));", 10
        db "        int pM=pSec/60; if(pM>99)pM=99; int pS=pSec-(pSec/60)*60;", 10
        db "        int lM=lSec/60; if(lM>99)lM=99; int lS=lSec-(lSec/60)*60;", 10
        db "        int mch=32;", 10
        db "        if(mci==0) mch=48+(pM/10);", 10
        db "        if(mci==1) mch=48+(pM-(pM/10)*10);", 10
        db "        if(mci==2) mch=58;", 10
        db "        if(mci==3) mch=48+(pS/10);", 10
        db "        if(mci==4) mch=48+(pS-(pS/10)*10);", 10
        db "        if(mci==5) mch=47;", 10
        db "        if(mci==6) mch=48+(lM/10);", 10
        db "        if(mci==7) mch=48+(lM-(lM/10)*10);", 10
        db "        if(mci==8) mch=58;", 10
        db "        if(mci==9) mch=48+(lS/10);", 10
        db "        if(mci==10) mch=48+(lS-(lS/10)*10);", 10
        db "        if(glyph(mch,mgp)>0.5) col=vec3(0.55,0.88,1.0);", 10
        db "      }", 10
        db "    }", 10
        ; 5. Seek bar (seekX0 .. seekX1)
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
        ; 6. Speaker icon + Mute (u_res.x-158 .. u_res.x-142)
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
        ; 7. Volume slider (u_res.x-138 .. u_res.x-24)
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
        ; --- BOTTOM SINE SCROLLER ---
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
        ; --- HUD PANEL ([H]) ---
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

; ============================================================================
; ASCII & String Utilities
; ============================================================================
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

extract_filename_only:
    push rsi
    mov rax, rcx
    mov rsi, rcx
.scan:
    movzx edx, byte [rsi]
    test dl, dl
    jz .done
    cmp dl, '\'
    je .mark
    cmp dl, '/'
    je .mark
    inc rsi
    jmp .scan
.mark:
    inc rsi
    mov rax, rsi
    jmp .scan
.done:
    pop rsi
    ret

; ============================================================================
; Goertzel 32-Band Filter Bank Setup + WASAPI Loopback Init & Update
; ============================================================================
fft_init_tables:
    push rbx
    sub rsp, 32

    cvtsi2ss xmm4, dword [wfx_rate]
    movss xmm5, [c_f_start]
    movss xmm6, [c_g_start]
    lea rbx, [goertzel_c]
    lea rdx, [goertzel_g]
    xor ecx, ecx

.loop:
    movss [rsp], xmm5
    fldpi
    fadd st0, st0
    fmul dword [rsp]
    movss [rsp], xmm4
    fdiv dword [rsp]
    fcos
    fadd st0, st0
    fstp dword [rbx + rcx * 4]

    movss [rdx + rcx * 4], xmm6

    mulss xmm5, [c_f_step]
    mulss xmm6, [c_g_step]
    inc ecx
    cmp ecx, 32
    jl .loop

    add rsp, 32
    pop rbx
    ret

wasapi_init:
    push rbx
    sub rsp, 64

    lea rcx, [dll_ole32]
    call LoadLibraryA
    test rax, rax
    jz .fail
    mov rbx, rax

    mov rcx, rbx
    lea rdx, [fn_CoInitializeEx]
    call GetProcAddress
    test rax, rax
    jz .fail
    mov [pCoInitializeEx], rax

    mov rcx, rbx
    lea rdx, [fn_CoCreateInstance]
    call GetProcAddress
    test rax, rax
    jz .fail
    mov [pCoCreateInstance], rax

    ; COINIT_APARTMENTTHREADED (2) - required so MCI DirectShow MP3 driver loads!
    xor ecx, ecx
    mov edx, 2
    call [pCoInitializeEx]

    lea rcx, [CLSID_MMDeviceEnumerator]
    xor edx, edx
    mov r8d, 23
    lea r9, [IID_IMMDeviceEnumerator]
    lea rax, [pEnumerator]
    mov [rsp + 32], rax
    call [pCoCreateInstance]
    test eax, eax
    js .fail

    mov rcx, [pEnumerator]
    xor edx, edx
    xor r8d, r8d
    lea r9, [pDevice]
    mov rax, [rcx]
    call [rax + 32]
    test eax, eax
    js .fail

    mov rcx, [pDevice]
    lea rdx, [IID_IAudioClient]
    mov r8d, 23
    xor r9d, r9d
    lea rax, [pAudioClient]
    mov [rsp + 32], rax
    mov rax, [rcx]
    call [rax + 24]
    test eax, eax
    js .fail

    mov rcx, [pAudioClient]
    lea rdx, [pwfx]
    mov rax, [rcx]
    call [rax + 64]
    test eax, eax
    js .fail

    mov rsi, [pwfx]
    movzx eax, word [rsi + 2]
    test eax, eax
    jz .fail
    mov [wfx_ch], eax

    mov eax, [rsi + 4]
    test eax, eax
    jz .fail
    mov [wfx_rate], eax

    movzx eax, word [rsi + 14]
    mov [wfx_bits], eax

    movzx eax, word [rsi]
    cmp eax, 3
    je .is_flt
    cmp eax, 0xFFFE
    jne .is_int
    mov eax, [rsi + 24]
    cmp eax, 3
    je .is_flt
.is_int:
    mov dword [wfx_is_float], 0
    jmp .init_client
.is_flt:
    mov dword [wfx_is_float], 1

.init_client:
    mov rcx, [pAudioClient]
    xor edx, edx
    mov r8d, 0x00020000
    mov r9, 10000000
    mov qword [rsp + 32], 0
    mov rax, [pwfx]
    mov [rsp + 40], rax
    mov qword [rsp + 48], 0
    mov rax, [rcx]
    call [rax + 24]
    test eax, eax
    js .fail

    mov rcx, [pAudioClient]
    lea rdx, [IID_IAudioCaptureClient]
    lea r8, [pCaptureClient]
    mov rax, [rcx]
    call [rax + 112]
    test eax, eax
    js .fail

    mov rcx, [pAudioClient]
    mov rax, [rcx]
    call [rax + 80]
    test eax, eax
    js .fail

    mov dword [wasapi_ok], 1

.fail:
    call fft_init_tables
    add rsp, 64
    pop rbx
    ret

wasapi_update:
    push rbx
    push rsi
    push rdi
    push r12
    sub rsp, 72

    cmp dword [wasapi_ok], 0
    je .done

.pkt_loop:
    mov dword [rsp + 56], 0
    mov rcx, [pCaptureClient]
    lea rdx, [rsp + 56]
    mov rax, [rcx]
    call [rax + 40]
    test eax, eax
    js .analyze
    mov ecx, [rsp + 56]
    test ecx, ecx
    jz .analyze

    mov qword [rsp + 32], 0
    mov qword [rsp + 40], 0
    mov qword [rsp + 48], 0
    mov dword [rsp + 56], 0
    mov dword [rsp + 60], 0
    mov rcx, [pCaptureClient]
    lea rdx, [rsp + 48]
    lea r8, [rsp + 56]
    lea r9, [rsp + 60]
    mov rax, [rcx]
    call [rax + 24]
    test eax, eax
    js .analyze

    mov rsi, [rsp + 48]
    mov ecx, [rsp + 56]
    mov edx, [rsp + 60]
    test edx, 2
    jnz .release_pkt
    test rsi, rsi
    jz .release_pkt
    test ecx, ecx
    jz .release_pkt

    mov r8d, [wfx_ch]
    mov r9d, [fft_wr_idx]
    lea rdi, [fft_ring]

    cmp dword [wfx_is_float], 0
    je .copy_i16

.copy_f32:
    movss xmm0, [rsi]
    cmp r8d, 2
    jl .store_f32
    addss xmm0, [rsi + 4]
    mulss xmm0, [c_half]
.store_f32:
    movss [rdi + r9 * 4], xmm0
    inc r9d
    and r9d, 511
    mov eax, r8d
    shl eax, 2
    add rsi, rax
    dec ecx
    jnz .copy_f32
    mov [fft_wr_idx], r9d
    jmp .release_pkt

.copy_i16:
    movsx eax, word [rsi]
    cvtsi2ss xmm0, eax
    cmp r8d, 2
    jl .scale_i16
    movsx eax, word [rsi + 2]
    cvtsi2ss xmm1, eax
    addss xmm0, xmm1
    mulss xmm0, [c_half]
.scale_i16:
    mulss xmm0, [c_i16_scale]
    movss [rdi + r9 * 4], xmm0
    inc r9d
    and r9d, 511
    mov eax, r8d
    shl eax, 1
    add rsi, rax
    dec ecx
    jnz .copy_i16
    mov [fft_wr_idx], r9d

.release_pkt:
    mov rcx, [pCaptureClient]
    mov edx, [rsp + 56]
    mov rax, [rcx]
    call [rax + 32]
    jmp .pkt_loop

.analyze:
    lea rsi, [fft_ring]
    lea rdi, [u_bands]
    lea rbx, [goertzel_c]
    lea r12, [goertzel_g]
    mov r8d, [fft_wr_idx]
    sub r8d, FFT_N
    and r8d, 511

    xor ecx, ecx
.band_loop:
    movss xmm3, [rbx + rcx * 4]
    xorps xmm1, xmm1
    xorps xmm2, xmm2
    mov edx, r8d
    xor eax, eax

.sample_loop:
    movss xmm0, [rsi + rdx * 4]
    movaps xmm4, xmm3
    mulss xmm4, xmm1
    addss xmm0, xmm4
    subss xmm0, xmm2
    movaps xmm2, xmm1
    movaps xmm1, xmm0

    inc edx
    and edx, 511
    inc eax
    cmp eax, FFT_N
    jl .sample_loop

    movaps xmm0, xmm1
    mulss xmm0, xmm0
    movaps xmm4, xmm2
    mulss xmm4, xmm4
    addss xmm0, xmm4
    movaps xmm4, xmm3
    mulss xmm4, xmm1
    mulss xmm4, xmm2
    subss xmm0, xmm4
    maxss xmm0, [c_zero]
    sqrtss xmm0, xmm0
    mulss xmm0, [r12 + rcx * 4]
    minss xmm0, [c_pos1]

    movss xmm4, [rdi + rcx * 4]
    comiss xmm0, xmm4
    jbe .decay
    subss xmm0, xmm4
    mulss xmm0, [c_atk]
    addss xmm4, xmm0
    jmp .store_band
.decay:
    mulss xmm4, [c_dec]
.store_band:
    movss [rdi + rcx * 4], xmm4

    inc ecx
    cmp ecx, 32
    jl .band_loop

    ; Sub-bass & Kick envelope (bands 0..3)
    movss xmm0, [rdi]
    addss xmm0, [rdi + 4]
    addss xmm0, [rdi + 8]
    addss xmm0, [rdi + 12]
    mulss xmm0, [c_bass_mul]
    minss xmm0, [c_pos1]
    movss [bass_env], xmm0

    ; Snare & Hi-Hat transient envelope (bands 20..27)
    movss xmm0, [rdi + 80]
    addss xmm0, [rdi + 84]
    addss xmm0, [rdi + 88]
    addss xmm0, [rdi + 92]
    addss xmm0, [rdi + 96]
    addss xmm0, [rdi + 100]
    addss xmm0, [rdi + 104]
    addss xmm0, [rdi + 108]
    mulss xmm0, [c_high_mul]
    minss xmm0, [c_pos1]
    movss [high_env], xmm0

.done:
    add rsp, 72
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; ============================================================================
; 64k Procedural 5-Voice ASM Synthesizer (waveOutOpen)
; ============================================================================
fast_sin_01:
    subss xmm0, [c_half]
    movaps xmm1, xmm0
    andps xmm1, [.abs_mask]
    movss xmm2, [c_half]
    subss xmm2, xmm1
    mulss xmm0, xmm2
    mulss xmm0, [.sixteen]
    ret
    align 16
.abs_mask dd 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF
.sixteen  dd 16.0

synth_fill_buffer:
    push rbx
    push rsi
    push rdi
    sub rsp, 32

    mov rdi, rcx
    mov ecx, SYNTH_SAMPLES
    mov esi, [synth_smp_i]

.smp_loop:
    mov eax, esi
    xor edx, edx
    mov ebx, 4800
    div ebx
    mov r8d, eax
    mov r9d, edx

    cvtsi2ss xmm3, r9d
    xorps xmm5, xmm5

    ; --- 1. KICK DRUM ---
    test r8d, 3
    jnz .chk_snare
    movaps xmm0, xmm3
    mulss xmm0, [.k_pdec]
    addss xmm0, [c_pos1]
    movss xmm1, [.k_psweep]
    divss xmm1, xmm0
    addss xmm1, [.k_pbase]
    mulss xmm1, xmm3
    divss xmm1, [c_44100]
    cvttss2si eax, xmm1
    cvtsi2ss xmm2, eax
    subss xmm1, xmm2
    movaps xmm0, xmm1
    call fast_sin_01
    movaps xmm1, xmm3
    mulss xmm1, [.k_edec]
    addss xmm1, [c_pos1]
    movss xmm2, [.k_gain]
    divss xmm2, xmm1
    mulss xmm0, xmm2
    addss xmm5, xmm0

.chk_snare:
    ; --- 2. SNARE DRUM ---
    mov eax, r8d
    and eax, 7
    cmp eax, 4
    jne .chk_hat
    movaps xmm0, xmm3
    mulss xmm0, [.sn_freq]
    divss xmm0, [c_44100]
    cvttss2si eax, xmm0
    cvtsi2ss xmm2, eax
    subss xmm0, xmm2
    call fast_sin_01
    mulss xmm0, [c_half]
    mov eax, [lfsr_state]
    mov edx, eax
    shr edx, 1
    test eax, 1
    jz .sn_no_tap
    xor edx, 0xB400
.sn_no_tap:
    mov [lfsr_state], edx
    and edx, 0xFFFF
    sub edx, 32768
    cvtsi2ss xmm1, edx
    mulss xmm1, [c_i16_scale]
    addss xmm0, xmm1
    movaps xmm1, xmm3
    mulss xmm1, [.sn_edec]
    addss xmm1, [c_pos1]
    movss xmm2, [.sn_gain]
    divss xmm2, xmm1
    mulss xmm0, xmm2
    addss xmm5, xmm0

.chk_hat:
    ; --- 3. HI-HAT ---
    mov eax, r8d
    and eax, 3
    cmp eax, 2
    jne .do_bass
    mov eax, [lfsr_state]
    mov edx, eax
    shr edx, 1
    test eax, 1
    jz .hh_no_tap
    xor edx, 0xB400
.hh_no_tap:
    mov [lfsr_state], edx
    and edx, 0xFFFF
    sub edx, 32768
    cvtsi2ss xmm0, edx
    mulss xmm0, [c_i16_scale]
    movaps xmm1, xmm0
    subss xmm0, [synth_prev_n]
    movss [synth_prev_n], xmm1
    movaps xmm1, xmm3
    mulss xmm1, [.hh_edec]
    addss xmm1, [c_pos1]
    movss xmm2, [.hh_gain]
    divss xmm2, xmm1
    mulss xmm0, xmm2
    addss xmm5, xmm0

.do_bass:
    ; --- 4. ROLLING ACID / SAWTOOTH BASSLINE ---
    mov eax, r8d
    shr eax, 4
    and eax, 3
    lea rbx, [chord_root]
    movss xmm0, [rbx + rax * 4]
    test r8d, 1
    jz .bass_oct_ok
    addss xmm0, xmm0
.bass_oct_ok:
    cvtsi2ss xmm1, esi
    mulss xmm0, xmm1
    divss xmm0, [c_44100]
    cvttss2si eax, xmm0
    cvtsi2ss xmm2, eax
    subss xmm0, xmm2
    addss xmm0, xmm0
    subss xmm0, [c_pos1]
    movss xmm1, [synth_lp_y]
    subss xmm0, xmm1
    mulss xmm0, [.bass_cut]
    addss xmm1, xmm0
    movss [synth_lp_y], xmm1
    movaps xmm2, xmm3
    mulss xmm2, [.bass_dec]
    addss xmm2, [c_pos1]
    movss xmm0, [.bass_gain]
    divss xmm0, xmm2
    mulss xmm1, xmm0
    addss xmm5, xmm1

    ; --- 5. FAST 50HZ DEMOSCENE ARPEGGIO ---
    mov eax, r8d
    shr eax, 4
    and eax, 3
    lea rbx, [chord_root]
    movss xmm0, [rbx + rax * 4]
    mov eax, esi
    xor edx, edx
    mov ebx, 882
    div ebx
    and eax, 3
    lea rbx, [arp_ratios]
    mulss xmm0, [rbx + rax * 4]
    cvtsi2ss xmm1, esi
    mulss xmm0, xmm1
    divss xmm0, [c_44100]
    cvttss2si eax, xmm0
    cvtsi2ss xmm2, eax
    subss xmm0, xmm2
    call fast_sin_01
    mulss xmm0, [.arp_gain]
    addss xmm5, xmm0

    mulss xmm5, [vol_level]
    mulss xmm5, [c_synth_out]
    cvtss2si eax, xmm5
    cmp eax, 32767
    jle .clip_min
    mov eax, 32767
.clip_min:
    cmp eax, -32768
    jge .store_smp
    mov eax, -32768
.store_smp:
    mov [rdi], ax
    add rdi, 2
    inc esi
    dec ecx
    jnz .smp_loop

    mov [synth_smp_i], esi
    add rsp, 32
    pop rdi
    pop rsi
    pop rbx
    ret
    align 4
.k_pdec    dd 0.0022
.k_psweep  dd 135.0
.k_pbase   dd 44.0
.k_edec    dd 0.00085
.k_gain    dd 0.72
.sn_freq   dd 190.0
.sn_edec   dd 0.0014
.sn_gain   dd 0.42
.hh_edec   dd 0.0038
.hh_gain   dd 0.24
.bass_cut  dd 0.14
.bass_dec  dd 0.00035
.bass_gain dd 0.44
.arp_gain  dd 0.14

synth_start:
    sub rsp, 56
    cmp qword [hWaveOut], 0
    jne .already_open

    lea rcx, [hWaveOut]
    mov edx, -1
    lea r8, [synth_wfx]
    xor r9d, r9d
    mov qword [rsp + 32], 0
    mov qword [rsp + 40], 0
    call waveOutOpen
    test eax, eax
    jnz .done

    lea rax, [synth_buf0]
    mov [whdr0], rax
    mov dword [whdr0 + 8], SYNTH_BYTES
    mov dword [whdr0 + 16], 0

    lea rax, [synth_buf1]
    mov [whdr1], rax
    mov dword [whdr1 + 8], SYNTH_BYTES
    mov dword [whdr1 + 16], 0

    mov rcx, [hWaveOut]
    lea rdx, [whdr0]
    mov r8d, 48
    call waveOutPrepareHeader

    mov rcx, [hWaveOut]
    lea rdx, [whdr1]
    mov r8d, 48
    call waveOutPrepareHeader

    lea rcx, [synth_buf0]
    call synth_fill_buffer
    lea rcx, [synth_buf1]
    call synth_fill_buffer

    mov rcx, [hWaveOut]
    lea rdx, [whdr0]
    mov r8d, 48
    call waveOutWrite

    mov rcx, [hWaveOut]
    lea rdx, [whdr1]
    mov r8d, 48
    call waveOutWrite

.already_open:
.done:
    add rsp, 56
    ret

synth_stop:
    sub rsp, 40
    mov rcx, [hWaveOut]
    test rcx, rcx
    jz .done
    call waveOutReset
    mov rcx, [hWaveOut]
    call waveOutClose
    mov qword [hWaveOut], 0
.done:
    add rsp, 40
    ret

synth_poll:
    sub rsp, 40
    cmp dword [synth_mode], 0
    je .done
    cmp qword [hWaveOut], 0
    je .done
    cmp dword [paused_flag], 0
    jne .done

    test dword [whdr0 + 16], 1
    jz .chk_b1
    lea rcx, [synth_buf0]
    call synth_fill_buffer
    mov rcx, [hWaveOut]
    lea rdx, [whdr0]
    mov r8d, 48
    call waveOutWrite

.chk_b1:
    test dword [whdr1 + 16], 1
    jz .done
    lea rcx, [synth_buf1]
    call synth_fill_buffer
    mov rcx, [hWaveOut]
    lea rdx, [whdr1]
    mov r8d, 48
    call waveOutWrite

.done:
    add rsp, 40
    ret

; ============================================================================
; Playlist, Metadata & MCI Audio Controls
; ============================================================================
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

    cmp dword [synth_mode], 0
    je .chk_dropped
    lea rcx, [scroller_txt]
    lea rdx, [info_synth]
    call lstrcpyA
    lea rcx, [top_txt]
    lea rdx, [tag_synth]
    call lstrcpyA
    jmp .to_uniform_arr

.chk_dropped:
    cmp dword [dropped_flg], 0
    je .chk_playlist
    lea rcx, [dropped_path]
    call extract_filename_only
    mov rbx, rax
    jmp .chk_meta_keys

.chk_playlist:
    mov eax, [track_count]
    test eax, eax
    jnz .has_track
    mov dword [synth_mode], 1
    lea rcx, [scroller_txt]
    lea rdx, [info_synth]
    call lstrcpyA
    lea rcx, [top_txt]
    lea rdx, [tag_synth]
    call lstrcpyA
    jmp .to_uniform_arr

.has_track:
    mov eax, [cur_track]
    imul eax, 128
    lea rbx, [tracks_buf]
    add rbx, rax

.chk_meta_keys:
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
    cmp dword [synth_mode], 0
    jne .copy_top_title
    cmp dword [dropped_flg], 0
    jne .copy_top_title

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

.copy_top_title:
    lea rsi, [top_txt]
.top_loop:
    cmp ecx, 24
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

    cmp dword [synth_mode], 0
    jne .start_synth

    cmp dword [dropped_flg], 0
    jne .play_mp3
    cmp dword [track_count], 0
    jne .play_mp3

    mov dword [synth_mode], 1

.start_synth:
    lea rcx, [mci_close_cmd]
    xor edx, edx
    xor r8d, r8d
    xor r9d, r9d
    call mciSendStringA
    mov dword [paused_flag], 0
    call build_scroller_text
    call synth_start
    jmp .ret

.play_mp3:
    call synth_stop
    call build_scroller_text

    lea rcx, [mci_close_cmd]
    xor edx, edx
    xor r8d, r8d
    xor r9d, r9d
    call mciSendStringA

    cmp dword [dropped_flg], 0
    je .rel_music_dir
    lea rcx, [rel_path_buf]
    lea rdx, [dropped_path]
    call lstrcpyA
    jmp .resolve_full

.rel_music_dir:
    mov eax, [cur_track]
    imul eax, 128
    lea rbx, [tracks_buf]
    add rbx, rax
    lea rcx, [rel_path_buf]
    lea rdx, [music_prefix]
    call lstrcpyA
    lea rcx, [rel_path_buf]
    mov rdx, rbx
    call lstrcatA

.resolve_full:
    lea rcx, [rel_path_buf]
    mov edx, 260
    lea r8, [full_path_buf]
    xor r9d, r9d
    call GetFullPathNameA
    test eax, eax
    jnz .full_ok
    lea rcx, [full_path_buf]
    lea rdx, [rel_path_buf]
    call lstrcpyA

.full_ok:
    lea rcx, [mci_cmd_buf]
    lea rdx, [mci_open_head]
    call lstrcpyA
    lea rcx, [mci_cmd_buf]
    lea rdx, [full_path_buf]
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

    lea rcx, [mci_cmd_buf]
    lea rdx, [mci_open_head]
    call lstrcpyA
    lea rcx, [mci_cmd_buf]
    lea rdx, [full_path_buf]
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

    mov dword [synth_mode], 1
    mov dword [dropped_flg], 0
    mov dword [paused_flag], 0
    call build_scroller_text
    call synth_start

.ret:
    add rsp, 48
    pop rbx
    ret

audio_seek_fraction:
    push rdi
    sub rsp, 48

    cmp dword [synth_mode], 0
    jne .done
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
    mov dword [dropped_flg], 0
    mov dword [synth_mode], 0
    mov eax, [track_count]
    test eax, eax
    jz .play_anyway
    mov ecx, [cur_track]
    inc ecx
    cmp ecx, eax
    jl .set_idx
    xor ecx, ecx
.set_idx:
    mov [cur_track], ecx
.play_anyway:
    call audio_play_current
    add rsp, 40
    ret

audio_prev_track:
    sub rsp, 40
    mov dword [dropped_flg], 0
    mov dword [synth_mode], 0
    mov eax, [track_count]
    test eax, eax
    jz .play_anyway
    mov ecx, [cur_track]
    dec ecx
    jns .set_idx
    mov ecx, eax
    dec ecx
.set_idx:
    mov [cur_track], ecx
.play_anyway:
    call audio_play_current
    add rsp, 40
    ret

audio_toggle_pause:
    sub rsp, 40
    cmp dword [synth_mode], 0
    je .mp3_pause
    xor dword [paused_flag], 1
    jmp .done
.mp3_pause:
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

audio_set_volume:
    push rdi
    sub rsp, 32

    cmp dword [synth_mode], 0
    jne .vol_unchanged

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

audio_update:
    push rsi
    sub rsp, 32

    call wasapi_update
    call synth_poll

    cmp dword [synth_mode], 0
    je .mp3_status

    mov eax, [synth_smp_i]
    xor edx, edx
    mov ecx, 44
    div ecx
    mov [track_pos_ms], eax
    mov dword [track_len_ms], 0
    jmp .chk_fallback_bass

.mp3_status:
    cmp dword [paused_flag], 0
    jne .zero_bass

    mov dword [mci_ret_buf], 0
    lea rcx, [mci_mode_cmd]
    lea rdx, [mci_ret_buf]
    mov r8d, 32
    xor r9d, r9d
    call mciSendStringA
    test eax, eax
    jnz .chk_fallback_bass

    cmp byte [mci_ret_buf], 's'
    jne .still_playing
    cmp dword [dropped_flg], 0
    jne .chk_fallback_bass
    call audio_next_track
    jmp .done

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
    jnz .chk_fallback_bass

    lea rsi, [mci_ret_buf]
    call parse_uint_ascii
    mov [track_pos_ms], eax

.chk_fallback_bass:
    cmp dword [wasapi_ok], 0
    jne .done
    mov eax, [track_pos_ms]
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

    mov eax, [track_pos_ms]
    add eax, 217
    xor edx, edx
    mov ecx, 435
    div ecx
    mov eax, 435
    sub eax, edx
    cvtsi2ss xmm0, eax
    divss xmm0, xmm1
    mulss xmm0, xmm0
    mulss xmm0, xmm0
    movss [high_env], xmm0
    jmp .done

.zero_bass:
    movss xmm0, [c_zero]
    movss [bass_env], xmm0
    movss [high_env], xmm0

.done:
    add rsp, 32
    pop rsi
    ret

audio_close:
    sub rsp, 40
    call synth_stop
    lea rcx, [mci_close_cmd]
    xor edx, edx
    xor r8d, r8d
    xor r9d, r9d
    call mciSendStringA
    add rsp, 40
    ret

; ============================================================================
; Borderless Fullscreen Toggle ([F11] / [Alt+Enter])
; ============================================================================
toggle_fullscreen:
    push rbx
    sub rsp, 64

    cmp dword [is_fullscr], 0
    jne .restore_win

    mov rcx, [hwnd]
    lea rdx, [saved_rect]
    call GetWindowRect

    mov rcx, [hwnd]
    mov edx, -16
    call GetWindowLongPtrA
    mov [saved_style], rax

    mov rdx, rax
    and rdx, ~0x00CF0000
    mov rcx, [hwnd]
    mov r8, rdx
    mov edx, -16
    call SetWindowLongPtrA

    mov rcx, [hwnd]
    mov edx, 2
    call MonitorFromWindow

    mov dword [mon_info], 40
    mov rcx, rax
    lea rdx, [mon_info]
    call GetMonitorInfoA

    mov ecx, [mon_info + 4]
    mov ebx, [mon_info + 8]
    mov r9d, [mon_info + 12]
    sub r9d, ecx
    mov eax, [mon_info + 16]
    sub eax, ebx
    mov [rsp + 32], r9d
    mov [rsp + 40], eax
    mov dword [rsp + 48], 0x0220
    mov r8d, ecx
    mov r9d, ebx
    mov rcx, [hwnd]
    xor edx, edx
    call SetWindowPos

    mov dword [is_fullscr], 1
    jmp .done

.restore_win:
    mov rcx, [hwnd]
    mov edx, -16
    mov r8, [saved_style]
    call SetWindowLongPtrA

    mov ecx, [saved_rect]
    mov ebx, [saved_rect + 4]
    mov r9d, [saved_rect + 8]
    sub r9d, ecx
    mov eax, [saved_rect + 12]
    sub eax, ebx

    mov [rsp + 32], r9d
    mov [rsp + 40], eax
    mov dword [rsp + 48], 0x0224
    mov r8d, ecx
    mov r9d, ebx
    mov rcx, [hwnd]
    xor edx, edx
    call SetWindowPos

    mov dword [is_fullscr], 0

.done:
    add rsp, 64
    pop rbx
    ret

; ============================================================================
; Pixel-Perfect BMP Screenshot Capture ([F12])
; ============================================================================
capture_bmp_screenshot:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    sub rsp, 64

    mov rcx, [hwnd]
    lea rdx, [rect]
    call GetClientRect
    mov r12d, [rect + 8]
    mov r13d, [rect + 12]
    test r12d, r12d
    jle .done
    test r13d, r13d
    jle .done

    mov eax, r12d
    imul eax, 3
    add eax, 3
    and eax, ~3
    mov ebx, eax
    imul eax, r13d
    mov esi, eax
    add eax, 54
    mov edi, eax

    xor ecx, ecx
    mov edx, edi
    mov r8d, 0x3000
    mov r9d, 4
    call VirtualAlloc
    test rax, rax
    jz .done
    mov [rsp + 56], rax

    mov rcx, rax
    xor edx, edx
.clr_hdr:
    mov byte [rcx + rdx], 0
    inc edx
    cmp edx, 54
    jl .clr_hdr

    mov word [rax], 'BM'
    mov [rax + 2], edi
    mov dword [rax + 10], 54
    mov dword [rax + 14], 40
    mov [rax + 18], r12d
    mov [rax + 22], r13d
    mov word [rax + 26], 1
    mov word [rax + 28], 24
    mov [rax + 34], esi

    mov ecx, 0x0D05
    mov edx, 4
    call glPixelStorei

    mov rcx, [rsp + 56]
    add rcx, 54
    mov [rsp + 48], rcx
    mov dword [rsp + 40], 0x1401
    mov dword [rsp + 32], 0x1907
    xor ecx, ecx
    xor edx, edx
    mov r8d, r12d
    mov r9d, r13d
    call glReadPixels

    mov rsi, [rsp + 56]
    add rsi, 54
    xor edx, edx
.row_loop:
    cmp edx, r13d
    jge .write_file
    mov rcx, rsi
    xor eax, eax
.col_loop:
    cmp eax, r12d
    jge .next_row
    mov r8b, [rcx]
    mov r9b, [rcx + 2]
    mov [rcx], r9b
    mov [rcx + 2], r8b
    add rcx, 3
    inc eax
    jmp .col_loop
.next_row:
    add rsi, rbx
    inc edx
    jmp .row_loop

.write_file:
    lea rdi, [shot_name]
    mov dword [rdi], 'shot'
    mov byte [rdi + 4], '_'
    mov eax, [shot_idx]
    inc dword [shot_idx]
    mov ecx, 100
    xor edx, edx
    div ecx
    add al, '0'
    mov [rdi + 5], al
    mov eax, edx
    mov ecx, 10
    xor edx, edx
    div ecx
    add al, '0'
    mov [rdi + 6], al
    add dl, '0'
    mov [rdi + 7], dl
    mov dword [rdi + 8], '.bmp'
    mov byte [rdi + 12], 0

    lea rcx, [shot_name]
    mov edx, 0x40000000
    xor r8d, r8d
    xor r9d, r9d
    mov dword [rsp + 32], 2
    mov dword [rsp + 40], 0x80
    mov qword [rsp + 48], 0
    call CreateFileA
    cmp rax, -1
    je .free_mem
    mov rbx, rax

    mov rcx, rbx
    mov rdx, [rsp + 56]
    mov r8d, edi
    lea r9, [rsp + 48]
    mov qword [rsp + 32], 0
    call WriteFile

    mov rcx, rbx
    call CloseHandle

    mov eax, [c_pos1]
    mov [flash_env], eax

.free_mem:
    mov rcx, [rsp + 56]
    xor edx, edx
    mov r8d, 0x8000
    call VirtualFree

.done:
    add rsp, 64
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; ============================================================================
; Entry Point & Main Loop
; ============================================================================
main:
WinMain:
    sub rsp, 104
    finit

    lea rcx, [qpc_freq]
    call QueryPerformanceFrequency
    lea rcx, [qpc_last]
    call QueryPerformanceCounter

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

    lea rcx, [dll_shell32]
    call LoadLibraryA
    test rax, rax
    jz .no_dnd
    mov rbx, rax
    mov rcx, rbx
    lea rdx, [fn_DragAcceptFiles]
    call GetProcAddress
    mov [pDragAcceptFiles], rax
    mov rcx, rbx
    lea rdx, [fn_DragQueryFileA]
    call GetProcAddress
    mov [pDragQueryFileA], rax
    mov rcx, rbx
    lea rdx, [fn_DragFinish]
    call GetProcAddress
    mov [pDragFinish], rax

    cmp qword [pDragAcceptFiles], 0
    je .no_dnd
    mov rcx, [hwnd]
    mov edx, 1
    call [pDragAcceptFiles]
.no_dnd:

    mov rcx, [hwnd]
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
    lea rdx, [u_fx_name]
    call [glGetUniformLocation]
    mov [u_fx_loc], eax

    mov ecx, r13d
    lea rdx, [u_demo_name]
    call [glGetUniformLocation]
    mov [u_demo_loc], eax

    mov ecx, r13d
    lea rdx, [u_bands_name]
    call [glGetUniformLocation]
    mov [u_bands_loc], eax

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

    call wasapi_init
    call playlist_scan
    call audio_play_current

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
    lea rcx, [qpc_now]
    call QueryPerformanceCounter
    mov rax, [qpc_now]
    sub rax, [qpc_last]
    mov rdx, [qpc_now]
    mov [qpc_last], rdx

    cvtsi2ss xmm0, rax
    cvtsi2ss xmm1, qword [qpc_freq]
    divss xmm0, xmm1
    minss xmm0, [c_max_dt]
    movss [dt_step], xmm0

    inc dword [fps_frames]
    addss xmm0, [fps_accum]
    movss [fps_accum], xmm0
    comiss xmm0, [c_fps_iv]
    jb .fps_ok
    cvtsi2ss xmm1, dword [fps_frames]
    divss xmm1, xmm0
    movss [fps_val_f], xmm1
    mov dword [fps_frames], 0
    mov dword [fps_accum], 0
.fps_ok:

    movss xmm0, [time]
    addss xmm0, [dt_step]
    movss [time], xmm0

    movss xmm1, [flash_env]
    movss xmm2, [dt_step]
    mulss xmm2, [c_flash_dec]
    subss xmm1, xmm2
    maxss xmm1, [c_zero]
    movss [flash_env], xmm1

    call audio_set_volume
    call audio_update

    mov eax, [morph_mode]
    test eax, eax
    jnz .locked_morph
    movss [rsp], xmm0
    fld dword [rsp]
    fmul dword [.morph_spd]
    fsin
    fadd dword [c_pos1]
    fmul dword [c_two_f]
    fstp dword [morph_val]
    jmp .morph_done
.locked_morph:
    dec eax
    cvtsi2ss xmm1, eax
    movss [morph_val], xmm1
.morph_done:

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

    mov eax, [holo_mode]
    cvtsi2ss xmm0, eax
    movss [holo_mode_f], xmm0

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

    mov ecx, [u_bands_loc]
    mov edx, 8
    lea r8, [u_bands]
    call [glUniform4fv]

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

    mov ecx, [u_fx_loc]
    movss xmm1, [morph_val]
    movss xmm2, [grid_on]
    movss xmm3, [fps_val_f]
    mov eax, [flash_env]
    mov [rsp + 32], eax
    call [glUniform4f]

    mov ecx, [u_demo_loc]
    movss xmm1, [copper_on]
    movss xmm2, [holo_mode_f]
    movss xmm3, [glitch_on]
    mov eax, [high_env]
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
    align 4
.morph_spd   dd 0.22

exit_app:
    call audio_close
    mov rcx, [hwnd]
    mov rdx, [hdc]
    call ReleaseDC
    xor ecx, ecx
    call ExitProcess

; ============================================================================
; Mouse & Window Message Handler
; ============================================================================
apply_seek_mouse:
    sub rsp, 40
    mov ecx, r8d
    sub ecx, 430
    mov eax, ebx
    sub eax, ecx
    test eax, eax
    jns .min_ok
    xor eax, eax
.min_ok:
    cmp eax, 254
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

apply_vol_mouse:
    mov ecx, r8d
    sub ecx, 138
    mov eax, ebx
    sub eax, ecx
    test eax, eax
    jns .min_ok
    xor eax, eax
.min_ok:
    cmp eax, 114
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
    cmp edx, 0x0104
    je .syskeydown
    cmp edx, 0x0233
    je .dropfiles
    cmp edx, 0x0201
    je .lbuttondown
    cmp edx, 0x0202
    je .lbuttonup
    cmp edx, 0x0200
    je .mousemove
    jmp DefWindowProcA

.syskeydown:
    cmp r8d, 0x0D
    jne DefWindowProcA
    sub rsp, 40
    call toggle_fullscreen
    add rsp, 40
    jmp .ret_zero

.dropfiles:
    sub rsp, 40
    cmp qword [pDragQueryFileA], 0
    je .drop_done
    mov rbx, r8
    mov rcx, rbx
    xor edx, edx
    lea r8, [dropped_path]
    mov r9d, 258
    call [pDragQueryFileA]
    mov rcx, rbx
    call [pDragFinish]

    mov dword [dropped_flg], 1
    mov dword [synth_mode], 0
    call audio_play_current
.drop_done:
    add rsp, 40
    jmp .ret_zero

.keydown:
    cmp r8d, 0x1B
    je .destroy
    cmp r8d, 0x7A
    je .do_fullscreen
    cmp r8d, 0x7B
    je .do_screenshot
    cmp r8d, 'H'
    je .toggle_hud
    cmp r8d, 'M'
    je .toggle_mute
    cmp r8d, 'G'
    je .toggle_grid
    cmp r8d, 'C'
    je .toggle_copper
    cmp r8d, 'W'
    je .cycle_mat
    cmp r8d, 'X'
    je .toggle_glitch
    cmp r8d, 'S'
    je .toggle_synth
    cmp r8d, 'A'
    je .set_auto_morph
    cmp r8d, '0'
    je .set_auto_morph
    cmp r8d, '1'
    je .set_shape_1
    cmp r8d, '2'
    je .set_shape_2
    cmp r8d, '3'
    je .set_shape_3
    cmp r8d, '4'
    je .set_shape_4
    cmp r8d, '5'
    je .set_shape_5
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

.do_fullscreen:
    sub rsp, 40
    call toggle_fullscreen
    add rsp, 40
    jmp .ret_zero

.do_screenshot:
    sub rsp, 40
    call capture_bmp_screenshot
    add rsp, 40
    jmp .ret_zero

.toggle_grid:
    movss xmm0, [grid_on]
    ucomiss xmm0, [c_zero]
    ja .hide_grid
    mov eax, [c_pos1]
    mov [grid_on], eax
    jmp .ret_zero
.hide_grid:
    mov dword [grid_on], 0
    jmp .ret_zero

.toggle_copper:
    movss xmm0, [copper_on]
    ucomiss xmm0, [c_zero]
    ja .hide_copper
    mov eax, [c_pos1]
    mov [copper_on], eax
    jmp .ret_zero
.hide_copper:
    mov dword [copper_on], 0
    jmp .ret_zero

.cycle_mat:
    mov eax, [holo_mode]
    inc eax
    cmp eax, 3
    jl .store_mat
    xor eax, eax
.store_mat:
    mov [holo_mode], eax
    jmp .ret_zero

.toggle_glitch:
    movss xmm0, [glitch_on]
    ucomiss xmm0, [c_zero]
    ja .hide_glitch
    mov eax, [c_pos1]
    mov [glitch_on], eax
    jmp .ret_zero
.hide_glitch:
    mov dword [glitch_on], 0
    jmp .ret_zero

.toggle_synth:
    sub rsp, 40
    xor dword [synth_mode], 1
    mov dword [dropped_flg], 0
    call audio_play_current
    add rsp, 40
    jmp .ret_zero

.set_auto_morph:
    mov dword [morph_mode], 0
    jmp .ret_zero
.set_shape_1:
    mov dword [morph_mode], 1
    jmp .ret_zero
.set_shape_2:
    mov dword [morph_mode], 2
    jmp .ret_zero
.set_shape_3:
    mov dword [morph_mode], 3
    jmp .ret_zero
.set_shape_4:
    mov dword [morph_mode], 4
    jmp .ret_zero
.set_shape_5:
    mov dword [morph_mode], 5
    jmp .ret_zero

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

    movsx ebx, r9w
    mov esi, r9d
    sar esi, 16

    mov rcx, [hwnd]
    lea rdx, [rect]
    call GetClientRect
    mov r8d, [rect + 8]

    cmp esi, 10
    jl .chk_hud_sliders
    cmp esi, 36
    jg .chk_hud_sliders

    cmp ebx, 20
    jl .chk_hud_sliders
    cmp ebx, 64
    jg .chk_btn_play
    call audio_prev_track
    jmp .lbtn_done

.chk_btn_play:
    cmp ebx, 70
    jl .chk_hud_sliders
    cmp ebx, 114
    jg .chk_btn_next
    call audio_toggle_pause
    jmp .lbtn_done

.chk_btn_next:
    cmp ebx, 120
    jl .chk_hud_sliders
    cmp ebx, 164
    jg .chk_seek_bar
    call audio_next_track
    jmp .lbtn_done

.chk_seek_bar:
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

    movsx ebx, r9w
    mov esi, [drag_mode]

    mov rcx, [hwnd]
    lea rdx, [rect]
    call GetClientRect
    mov r8d, [rect + 8]

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
