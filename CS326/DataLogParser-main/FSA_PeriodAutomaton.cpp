#include "FSA_PeriodAutomaton.h"
using namespace std;
void PeriodAutomaton::S0() {
    if (EndOfFile()){
        Serr();
    }
   else if (CurrentLetter() == '.') {
        Accept();
    }
    else {
        Serr();
    }
}