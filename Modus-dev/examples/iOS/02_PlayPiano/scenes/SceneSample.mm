
////////////////////////////////////////////////////////////////////////
//
//  Modus
//  C++ Music Library
//  Sample Application
//
//  Arturo Cepeda
//
////////////////////////////////////////////////////////////////////////


#include "SceneSample.h"
#include "GEUtils.h"


//
//  global data
//
MCTimer* mTimer;
bool bSamplesLoaded = false;
bool bThreadEnd = false;


//
//  GESceneSampleThreads
//
void* GESceneSampleThreads::LoadSamplesThread(void* lp)
{
   GESceneSample* cScene = (GESceneSample*)lp;
   MCSoundGenOpenAL* mSoundGen = cScene->getSoundGen();
   
   mSoundGen->loadSamplePack(GEDevice::getResourcePath(@"PianoWav.msp"), 
                             GESceneSampleCallbacks::SampleLoaded, lp);   
   mTimer->start();
   bSamplesLoaded = true;
   
   return NULL;
}

void* GESceneSampleThreads::MusicTimerThread(void* lp)
{
   while(!bThreadEnd)
      mTimer->update();
   
   return NULL;
}


//
//  GESceneSampleCallbacks
//
void GESceneSampleCallbacks::SampleLoaded(unsigned int TotalSamples, unsigned int Loaded, void* Data)
{
   GESceneSample* cScene = (GESceneSample*)Data;
   cScene->updateSamplesLoaded(TotalSamples, Loaded);
}

void GESceneSampleCallbacks::TimerTick(const MSTimePosition& TimePosition, void* Data)
{
   GESceneSample* cScene = (GESceneSample*)Data;
   cScene->updatePiano(TimePosition);
}

void GESceneSampleCallbacks::PlayNote(unsigned int Instrument, const MSNote& Note, void* Data)
{
   GESceneSample* cScene = (GESceneSample*)Data;   
   cScene->setIntensity(Note.Pitch, Note.Intensity);
}

void GESceneSampleCallbacks::ReleaseNote(unsigned int Instrument, const MSNote& Note, void* Data)
{
   GESceneSample* cScene = (GESceneSample*)Data;
   cScene->setIntensity(Note.Pitch, 0);
}

void GESceneSampleCallbacks::Damper(unsigned int Instrument, bool DamperState, void* Data)
{
   GESceneSample* cScene = (GESceneSample*)Data;
   cScene->setDamper(DamperState);
}


//
//  GESceneSample
//
GESceneSample::GESceneSample(GERendering* Render, void* GlobalData) : GEScene(Render, GlobalData)
{
   // initialize piano status
   memset(iIntensity, 0, 88);
   bDamper = false;
}

void GESceneSample::init()
{   
   iNextScene = -1;
   cRender->setBackgroundColor(0.8f, 0.8f, 1.0f);
   
   iTotalSamples = 0;
   iSamplesLoaded = 0;
   fKeyboardOffset = 0.0f;
   fSlideSpeed = 0.0f;

   // textures
   cRender->loadTexture(Textures.KeyWhite, @"pianokey_white.png");
   cRender->loadTexture(Textures.KeyBlack, @"pianokey_black.png");
   cRender->loadTexture(Textures.KeyWhitePressed, @"pianokey_white_root.png");
   cRender->loadTexture(Textures.KeyBlackPressed, @"pianokey_black_root.png");
   cRender->loadTexture(Textures.PedalOn, @"pianopedal_on.png");
   cRender->loadTexture(Textures.PedalOff, @"pianopedal_off.png");
   cRender->loadTexture(Textures.Loading, @"note.png");
   
   // sprites
   cSpriteKeyWhite = new GESprite(cRender->getTexture(Textures.KeyWhite),
                                  cRender->getTextureSize(Textures.KeyWhite));
   
   cSpriteKeyBlack = new GESprite(cRender->getTexture(Textures.KeyBlack),
                                  cRender->getTextureSize(Textures.KeyBlack));
   cSpriteKeyBlack->setScale(1.0f, 0.75f);
   
   cSpriteKeyWhitePressed = new GESprite(cRender->getTexture(Textures.KeyWhitePressed),
                                         cRender->getTextureSize(Textures.KeyWhitePressed));
   
   cSpriteKeyBlackPressed = new GESprite(cRender->getTexture(Textures.KeyBlackPressed),
                                         cRender->getTextureSize(Textures.KeyBlackPressed));
   cSpriteKeyBlackPressed->setScale(1.0f, 0.75f);
   
   cSpritePedalOn = new GESprite(cRender->getTexture(Textures.PedalOn),
                                 cRender->getTextureSize(Textures.PedalOn));
   cSpritePedalOn->setScale(0.6f, 0.6f);
   
   cSpritePedalOff = new GESprite(cRender->getTexture(Textures.PedalOff),
                                  cRender->getTextureSize(Textures.PedalOff));
   cSpritePedalOff->setScale(0.6f, 0.6f);
   
   cSpritePedal = cSpritePedalOff;
   
   cSpriteLoading = new GESprite(cRender->getTexture(Textures.Loading),
                                 cRender->getTextureSize(Textures.Loading));
   cSpriteLoading->setScale(0.125f, 0.125f);

   // labels
   cTextModus = new GELabel(@"Modus\nC++ Music Library\nSample Application", @"Optima-ExtraBlack", 
                            28.0f, UITextAlignmentLeft, 1024, 128);
   cTextModus->setPosition(0.9f, 1.35f);
   cTextModus->setScale(3.0f, 3.0f);
   cTextModus->setRotation(0.0f, 0.0f, -90.0f);
   cTextModus->setColor(0.2f, 0.2f, 0.2f);
   
   cTextLoading = new GELabel(@"", @"Optima-ExtraBlack",
                              28.0f, UITextAlignmentLeft, 1024, 64);
   cTextLoading->setPosition(0.4f, 1.35f);
   cTextLoading->setScale(3.0f, 3.0f);
   cTextLoading->setRotation(0.0f, 0.0f, -90.0f);
   cTextLoading->setColor(0.2f, 0.2f, 0.2f);
   
   // initialize audio system
   cAudio = new CAudio();
   
   // Modus objects
   MSRange mPianoRange = {21, 108};
   mPiano = new MCInstrument(1, mPianoRange, mPianoRange.getSize());
   
   mSourceManager = new MCOpenALSourceManager(OPENAL_SOURCES);
   mSoundGen = new MCSoundGenOpenAL(mPianoRange.getSize(), false, 1, mSourceManager);
   mPiano->setSoundGen(mSoundGen);
   
   mTimer = new MCTimer();
   mTimer->setCallbackTick(GESceneSampleCallbacks::TimerTick, this);
   
   // set instrument callbacks
   mPiano->setCallbackPlay(GESceneSampleCallbacks::PlayNote, this);
   mPiano->setCallbackRelease(GESceneSampleCallbacks::ReleaseNote, this);
   mPiano->setCallbackDamper(GESceneSampleCallbacks::Damper, this);
   
   // create music threads
   pthread_create(&hLoadSamples, NULL, GESceneSampleThreads::LoadSamplesThread, this);
   pthread_create(&hMusicTimerThread, NULL, GESceneSampleThreads::MusicTimerThread, NULL);
}

void GESceneSample::release()
{
   // wait until the music timer thread finishes
   bThreadEnd = true;
   pthread_join(hMusicTimerThread, NULL);
   
   // release Modus objects
   delete mSoundGen;
   delete mSourceManager;
   delete mPiano;
   delete mTimer;
   
   // release audio system
   delete cAudio;
   
   // release sprites   
   delete cSpriteKeyWhite;
   delete cSpriteKeyBlack;
   delete cSpriteKeyWhitePressed;
   delete cSpriteKeyBlackPressed;
   delete cSpritePedalOn;
   delete cSpritePedalOff;
   delete cSpriteLoading;
   
   // release labels
   delete cTextModus;   
   delete cTextLoading;
}

void GESceneSample::update()
{
   // keyboard update
   fKeyboardOffset += fSlideSpeed;
   
   fKeyboardOffset = fmin(BOUNDS_RIGHT, fKeyboardOffset);
   fKeyboardOffset = fmax(BOUNDS_LEFT, fKeyboardOffset);
   
   if(fSlideSpeed > 0.0f)
      fSlideSpeed -= SLIDE_FRICTION;
   else if(fSlideSpeed < 0.0f)
      fSlideSpeed += SLIDE_FRICTION;
   
   // rendering
   render();
}

void GESceneSample::updateSamplesLoaded(unsigned int TotalSamples, unsigned int Loaded)
{
   iTotalSamples = TotalSamples;
   iSamplesLoaded = Loaded;
}

void GESceneSample::updatePiano(const MSTimePosition& TimePosition)
{
   mPiano->update(TimePosition);
}

MCSoundGenOpenAL* GESceneSample::getSoundGen()
{
   return mSoundGen;
}

void GESceneSample::setIntensity(unsigned char Pitch, unsigned char Intensity)
{
   iIntensity[Pitch - LOWEST_NOTE] = Intensity;
}

void GESceneSample::setDamper(bool On)
{
   bDamper = On;
   cSpritePedal = bDamper? cSpritePedalOn: cSpritePedalOff;
}

void GESceneSample::render()
{
   cRender->renderBegin();

   // labels
   cRender->renderLabel(cTextModus);
  
   if(!bSamplesLoaded)
   {
      int iPercentage = 1 + (int)(((float)iSamplesLoaded / iTotalSamples) * 100);
      NSString* sLoadingText = [[NSString alloc] initWithFormat:@"Loading audio samples: %d%%", iPercentage];
      
      cTextLoading->setText(sLoadingText);      
      cRender->renderLabel(cTextLoading);
      
      float fPosY = 0.0f;
      float fPosX = 1.25f;
      
      for(unsigned int i = 1; i <= iPercentage / 5; i++)
      {
         cSpriteLoading->setPosition(fPosY, fPosX);
         cRender->renderSprite(cSpriteLoading);
         fPosX -= 0.125f;
      }
      
      cRender->renderEnd();
      return;
   }
   
   // piano keyboard   
   float fPosY = -0.1f;
   float fKeyPosX;
   
   int iNote;
   int iOctave;
   int iOffset;
   int i;
   
   // white keys
   fFirstKeyWhitePosX = fKeyboardOffset + KEY_WIDTH * 26 - (KEY_WIDTH / 2);  // number of white keys: 52, 52/2=26
   
   for(i = 0; i < 88; i++)
   {
      if(!MCNotes::isNatural(i + LOWEST_NOTE))
         continue;
      
      iNote = (i + LOWEST_NOTE) % 12;
      iOctave = (i + LOWEST_NOTE) / 12 - 2;  // pitch: [21, 108] --> octave: [0, 7]
      iOffset = 2 + (iOctave * 7);           // initial offset 2: the first C is the 3rd key
      
      switch(iNote)
      {
         case D:
            iOffset += 1;
            break;
         case E:
            iOffset += 2;
            break;
         case F:
            iOffset += 3;
            break;
         case G:
            iOffset += 4;
            break;
         case A:
            iOffset += 5;
            break;
         case B:
            iOffset += 6;
            break;
      }
      
      fKeyPosX = fFirstKeyWhitePosX - (KEY_WIDTH * iOffset);
      cSpriteKeyWhite->setPosition(fPosY, fKeyPosX);
      cRender->renderSprite(cSpriteKeyWhite);
      
      if(iIntensity[i] > 0)
      {
         cSpriteKeyWhitePressed->setPosition(fPosY, fKeyPosX);
         cSpriteKeyWhitePressed->setOpacity(iIntensity[i] / 127.0f);
         cRender->renderSprite(cSpriteKeyWhitePressed);
      }
   }   
   
   // black keys
   fPosY += 0.22f;
   fFirstKeyBlackPosX = fKeyboardOffset + KEY_WIDTH * 26;
   
   for(i = 0; i < 88; i++)
   {
      if(MCNotes::isNatural(i + LOWEST_NOTE))
         continue;
      
      iNote = (i + LOWEST_NOTE) % 12;
      iOctave = (i + LOWEST_NOTE) / 12 - 2;  // pitch: [21, 108] --> octave: [0, 7]
      iOffset = 2 + (iOctave * 7);           // initial offset 2: the first C is the 3rd key
      
      switch(iNote)
      {
         case Cs:
            iOffset += 1;
            break;
         case Ds:
            iOffset += 2;
            break;
         case Fs:
            iOffset += 4;
            break;
         case Gs:
            iOffset += 5;
            break;
         case As:
            iOffset += 6;
            break;
      }
      
      fKeyPosX = fFirstKeyBlackPosX - (KEY_WIDTH * iOffset);
      cSpriteKeyBlack->setPosition(fPosY, fKeyPosX);
      cRender->renderSprite(cSpriteKeyBlack);
      
      if(iIntensity[i] > 0)
      {
         cSpriteKeyBlackPressed->setPosition(fPosY, fKeyPosX);
         cSpriteKeyBlackPressed->setOpacity(iIntensity[i] / 127.0f);
         cRender->renderSprite(cSpriteKeyBlackPressed);
      }
   }
   
   // piano pedal
   cSpritePedal->setPosition(fPosY - 0.87f, 0.0f);
   cRender->renderSprite(cSpritePedal);
    
   cRender->renderEnd();
}

void GESceneSample::inputTouchBegin(int ID, CGPoint* Point)
{
   // stop sliding
   fSlideSpeed = 0.0f;

   // check position
   float fTouchX = cPixelToPositionX->y(Point->x);
   float fTouchY = cPixelToPositionY->y(Point->y);

   // pedal
   if(fTouchX < BOUNDS_BOTTOM)
      mPiano->setDamper(!bDamper);
   
   // key
   else if(fTouchX < BOUNDS_TOP)
   {
      float fKeyNumber = (fFirstKeyWhitePosX - fTouchY) / (KEY_WIDTH * KEY_SCALE);
      
      MSNote mNote;      
      mNote.Channel = (unsigned char)fKeyNumber;
      mNote.Pitch = mNote.Channel + LOWEST_NOTE;
      mNote.Intensity = 127;
      mNote.Mode = 0;
      mNote.Duration = 0;
      
      // when the finger is under the black keys, it must be a white key
      if(fTouchX < ((BOUNDS_TOP + BOUNDS_BOTTOM) / 2) && !MCNotes::isNatural(mNote.Pitch))
      {
         // check only decimal value
         fKeyNumber -= mNote.Channel;
         
         if(fKeyNumber > 0.5f)
         {
            mNote.Channel++;
            mNote.Pitch++;
         }
         else 
         {
            mNote.Channel--;
            mNote.Pitch--;
         }
      }
      
      iFingerChannel[ID] = mNote.Channel;      
      mPiano->playNote(mNote);
   }
}

void GESceneSample::inputTouchMove(int ID, CGPoint* PreviousPoint, CGPoint* CurrentPoint)
{
   // only the first finger can slide the keyboard
   if(ID == 0)
      fSlideSpeed = (PreviousPoint->y - CurrentPoint->y) * SLIDE_RATIO;
}

void GESceneSample::inputTouchEnd(int ID, CGPoint* Point)
{
   mPiano->release(iFingerChannel[ID]);
}

void GESceneSample::updateAccelerometerStatus(float X, float Y, float Z)
{
}