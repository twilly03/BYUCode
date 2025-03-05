#include "FSA_CommaAutomaton.h"
using namespace std;
void CommaAutomaton::S0() {
    if (EndOfFile()){
        Serr();
    }
    else if (CurrentLetter() == ',') {
        Accept();
    }
    else {
        Serr();
    }
}