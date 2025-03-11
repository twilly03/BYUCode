#include "FSA_ColonDashAutomaton.h"

void ColonDashAutomaton::S0() {
    if (EndOfFile()){
        Serr();
    }
    else if (CurrentLetter() == ':') {
        Accept();
        S1();
    }
    else {
        Serr();
    }
}

void ColonDashAutomaton::S1() {
    if (EndOfFile()){
        Serr();
    }
    else if (CurrentLetter() == '-') {
        Accept();
    }
    else {
        Serr();
    }
}