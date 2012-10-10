
////////////////////////////////////////////////////////////////////////
//
//  Modus
//  C++ Music Library
//  (Examples)
//
//  Arturo Cepeda P�rez
//  July 2012
//
////////////////////////////////////////////////////////////////////////

#include "modus.h"

#include "./../audio/audio.fmod.h"
#include "FMOD/mxsoundgenfmod.h"

#include <iostream>
#include <conio.h>

#define LOOP 4

#define TEMPO       120.0f
#define MIN_TEMPO   60.0f
#define MAX_TEMPO   180.0f

// define to avoid 100% CPU usage
#define REDUCE_CPU_USAGE

// try with a higher value in case it doesn't sound properly
#define FMOD_DSP_BUFFER_SIZE    512

#ifdef _MSC_VER
#pragma comment(lib, ".\\..\\..\\..\\lib\\Win32\\modus.lib")
#pragma comment(lib, ".\\..\\..\\..\\soundgen\\externals\\FMOD\\lib.win32\\fmodex_vc.lib")
#endif

using namespace std;

struct SGlobal
{
    MCInstrument* mDrums;
    MCScore* mScore;
};

void TimerTick(const MSTimePosition& mTimePosition, void* pData);

int main(int argc, char* argv[])
{
    // header
    cout << "\n  Modus " << MODUS_VERSION;
    cout << "\n  C++ Music Library";
    cout << "\n  Sample Application\n\n";

    // global data
    SGlobal sGlobal;

    // instrument
    MSRange mDrumsRange = {35, 59};
    sGlobal.mDrums = new MCInstrument(1, mDrumsRange, 16);

    // score
    sGlobal.mScore = new MCScore();
    sGlobal.mScore->loadScriptFromFile(".\\..\\..\\common\\scripts\\score.drums.sample.txt");

    // sound generator
    CAudio::init(FMOD_DSP_BUFFER_SIZE);
    MCSoundGenFMOD* mSoundGen = new MCSoundGenFMOD(sGlobal.mDrums->getNumberOfChannels(), false, 
                                                   CAudio::getSoundSystem());
    mSoundGen->loadSamplePack(".\\..\\..\\common\\instruments\\drums.msp");

    // drums settings
    sGlobal.mDrums->setScore(sGlobal.mScore);
    sGlobal.mDrums->setSoundGen(mSoundGen);

    // real time settings
    float fTempo = TEMPO;
    char iIntensityChange = 0;

    // timer
    MCTimer mTimer(fTempo, 4);
    mTimer.setCallbackTick(TimerTick, &sGlobal);
    mTimer.start();

    cout << "\n  Playing! Options:\n";
    cout << "\n    W -> tempo +";
    cout << "\n    Q -> tempo -\n";
    cout << "\n    P -> intensity +";
    cout << "\n    O -> intensity -\n";
    cout << "\n    S -> play with sticks (default)";
    cout << "\n    B -> play with brushes\n";
    cout << "\n    ESC -> quit\n\n";

    int iLastKey = 0;
    unsigned int i;

    while(iLastKey != 27)
    {
        // key pressed
        if(_kbhit())
        {
            iLastKey = toupper(_getch());

            switch(iLastKey)
            {
            // tempo +
            case 'W':

                if(fTempo < MAX_TEMPO)
                {
                    fTempo += 1.0f;
                    mTimer.setTempo(fTempo);
                }

                break;

            // tempo -
            case 'Q':

                if(fTempo > MIN_TEMPO)
                {
                    fTempo -= 1.0f;
                    mTimer.setTempo(fTempo);
                }

                break;

            // intensity +
            case 'P':

                if(iIntensityChange < 127)
                {
                    iIntensityChange++;
                    sGlobal.mDrums->setIntensityVariation(iIntensityChange);
                }

                break;

            // intensity -
            case 'O':

                if(iIntensityChange > -127)
                {
                    iIntensityChange--;
                    sGlobal.mDrums->setIntensityVariation(iIntensityChange);
                }

                break;

            // play with sticks
            case 'S':

                for(i = 0; i < sGlobal.mScore->getNumberOfEntries(); i++)
                    sGlobal.mScore->getEntry(i)->Note.Mode = 0;

                break;

            // play with brushes
            case 'B':

                for(i = 0; i < sGlobal.mScore->getNumberOfEntries(); i++)
                    sGlobal.mScore->getEntry(i)->Note.Mode = 1;

                break;
            }
        }

        // timer update
        if(mTimer.update())
            CAudio::update();
#ifdef REDUCE_CPU_USAGE
        else
            Sleep(1);
#endif
    }

    delete sGlobal.mDrums;
    delete sGlobal.mScore;
    delete mSoundGen;

    CAudio::release();

    return 0;
}

void TimerTick(const MSTimePosition& mTimePosition, void* pData)
{
    SGlobal* sGlobal = (SGlobal*)pData;

    // loop management
    if(mTimePosition.Measure % LOOP == 1 && mTimePosition.Measure > LOOP && 
       mTimePosition.Beat == 1 && mTimePosition.Tick == 0)
    {
        sGlobal->mScore->displace(LOOP);
    }

    // update
    sGlobal->mDrums->update(mTimePosition);
}