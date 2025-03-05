#include "FSA_ColonAutomaton.h"

void ColonAutomaton::S0() {
    if (EndOfFile()){
        Serr();
    }
    else if (CurrentLetter() == ':') {
        Accept();
    }
    else {
        Serr();
    }
}