#include "FSA_QMarkAutomaton.h"
using namespace std;
void QMarkAutomaton::S0() {
    if (EndOfFile()){
        Serr();
    }
    else if (CurrentLetter() == '?') {
        Accept();
    }
    else {
        Serr();
    }
}