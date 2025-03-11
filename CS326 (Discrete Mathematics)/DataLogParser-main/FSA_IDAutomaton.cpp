#include "FSA_IDAutomaton.h"

void IDAutomaton::S0() {
    if (EndOfFile()){
        Serr();
    }
    else if (isalpha(CurrentLetter())) {
        Accept();
        S1();
    }
    else {
        Serr();
    }
}

void IDAutomaton::S1() {
    if (EndOfFile()){
        Serr();
    }
    else if(isalnum(CurrentLetter())) {
        Accept();
        S1();
    }
    else {
        Serr();
    }
}


