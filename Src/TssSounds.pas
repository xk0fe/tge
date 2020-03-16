{*-----------------------------------------*)
 *  The Swinging Sixties Game Engine       *
 *  Sounds Unit                            *
 *  (C) Aukiogames 2004                    *
(*-----------------------------------------*}

unit TssSounds;

interface

uses
  Classes, fmod, fmodtypes, fmoderrors, fmodpresets, SysUtils;

type
  TTssSounds = class(TPersistent)
  public
    Horn: PFSoundSample;
    Eng1: PFSoundSample;
    Eng2: PFSoundSample;
    Tyre: PFSoundSample;
    Slide: PFSoundSample;
    Punch: PFSoundSample;
    HBrake: PFSoundSample;
    PedCrash1: PFSoundSample;
    PedCrash2: PFSoundSample;
    Crash1: PFSoundSample;
    Crash2: PFSoundSample;
    Crash3: PFSoundSample;
  public
    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
  TssEngine;                                                                             
                                                          
{ TTssSounds }

constructor TTssSounds.Create;
var P: Pointer;
begin
 inherited;        
 Horn:=FSOUND_Sample_Load(FSOUND_UNMANAGED, P, FSOUND_HW2D or FSOUND_LOADMEMORY, 0, Engine.SoundFile.LoadToMemByName('Horn.wav', P));
 FreeMem(P);
 FSOUND_Sample_SetMinMaxDistance(Horn, 4.0, 32.0);

 Eng1:=FSOUND_Sample_Load(FSOUND_UNMANAGED, P, {FSOUND_HW3D or} FSOUND_LOOP_NORMAL or FSOUND_LOADMEMORY, 0, Engine.SoundFile.LoadToMemByName('Engine.wav', P));
 FreeMem(P);
 FSOUND_Sample_SetMinMaxDistance(Eng1, 4.0, 32.0);
 Eng2:=FSOUND_Sample_Load(FSOUND_UNMANAGED, P, {FSOUND_HW3D or} FSOUND_LOOP_NORMAL or FSOUND_LOADMEMORY, 0, Engine.SoundFile.LoadToMemByName('Engine2.wav', P));
 FreeMem(P);
 FSOUND_Sample_SetMinMaxDistance(Eng2, 4.0, 32.0);

 Tyre:=FSOUND_Sample_Load(FSOUND_UNMANAGED, P, FSOUND_HW3D or FSOUND_LOOP_NORMAL or FSOUND_LOADMEMORY, 0, Engine.SoundFile.LoadToMemByName('Tyre.wav', P));
 FreeMem(P);
 FSOUND_Sample_SetMinMaxDistance(Tyre, 4.0, 32.0);

 Slide:=FSOUND_Sample_Load(FSOUND_UNMANAGED, P, FSOUND_HW3D or FSOUND_LOOP_NORMAL or FSOUND_LOADMEMORY, 0, Engine.SoundFile.LoadToMemByName('Slide.wav', P));
 FreeMem(P);
 FSOUND_Sample_SetMinMaxDistance(Slide, 4.0, 32.0);

 Punch:=FSOUND_Sample_Load(FSOUND_UNMANAGED, P, FSOUND_HW3D or FSOUND_LOADMEMORY, 0, Engine.SoundFile.LoadToMemByName('Punch.wav', P));
 FreeMem(P);
 FSOUND_Sample_SetMinMaxDistance(Punch, 4.0, 32.0);

 HBrake:=FSOUND_Sample_Load(FSOUND_UNMANAGED, P, FSOUND_HW2D or FSOUND_LOADMEMORY, 0, Engine.SoundFile.LoadToMemByName('HandBrake.wav', P));
 FreeMem(P);
 FSOUND_Sample_SetMinMaxDistance(HBrake, 4.0, 32.0);

 PedCrash1:=FSOUND_Sample_Load(FSOUND_UNMANAGED, P, FSOUND_HW2D or FSOUND_LOADMEMORY, 0, Engine.SoundFile.LoadToMemByName('Pedcrash.wav', P));
 FreeMem(P);
 FSOUND_Sample_SetMinMaxDistance(PedCrash1, 4.0, 32.0);
 PedCrash2:=FSOUND_Sample_Load(FSOUND_UNMANAGED, P, FSOUND_HW2D or FSOUND_LOADMEMORY, 0, Engine.SoundFile.LoadToMemByName('Pedcrash2.wav', P));
 FreeMem(P);
 FSOUND_Sample_SetMinMaxDistance(PedCrash2, 4.0, 32.0);

 Crash1:=FSOUND_Sample_Load(FSOUND_UNMANAGED, P, FSOUND_HW3D or FSOUND_LOADMEMORY, 0, Engine.SoundFile.LoadToMemByName('Crash.wav', P));
 FreeMem(P);
 FSOUND_Sample_SetMinMaxDistance(Crash1, 4.0, 32.0);
 Crash2:=FSOUND_Sample_Load(FSOUND_UNMANAGED, P, FSOUND_HW3D or FSOUND_LOADMEMORY, 0, Engine.SoundFile.LoadToMemByName('Crash2.wav', P));
 FreeMem(P);
 FSOUND_Sample_SetMinMaxDistance(Crash2, 4.0, 32.0);
 Crash3:=FSOUND_Sample_Load(FSOUND_UNMANAGED, P, FSOUND_HW3D or FSOUND_LOADMEMORY, 0, Engine.SoundFile.LoadToMemByName('Crash3.wav', P));
 FreeMem(P);
 FSOUND_Sample_SetMinMaxDistance(Crash3, 4.0, 32.0);
end;

destructor TTssSounds.Destroy;
begin
 FSOUND_Sample_Free(Crash1);
 FSOUND_Sample_Free(Crash2);
 FSOUND_Sample_Free(Crash3);
 FSOUND_Sample_Free(PedCrash1);
 FSOUND_Sample_Free(PedCrash2);
 FSOUND_Sample_Free(HBrake);
 FSOUND_Sample_Free(Horn);
 FSOUND_Sample_Free(Slide);
 FSOUND_Sample_Free(Tyre);
 FSOUND_Sample_Free(Eng1);
 FSOUND_Sample_Free(Eng2);
 FSOUND_Sample_Free(Punch);
 inherited;
end;



end.
 