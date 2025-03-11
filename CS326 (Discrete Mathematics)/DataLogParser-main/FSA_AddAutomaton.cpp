#include "FSA_AddAutomaton.h"
using namespace std;
void AddAutomaton::S0() {
    if (EndOfFile()){
        Serr();
    }
    else if (CurrentLetter() == '+') {
        Accept();
    }
    else {
        Serr();
    }
}