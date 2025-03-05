#include "FSA_RightParenAutomaton.h"
using namespace std;
void RightParenAutomaton::S0() {
    if (EndOfFile()){
        Serr();
    }
    else if (CurrentLetter() == ')') {
        Accept();
    }
    else {
        Serr();
    }
}