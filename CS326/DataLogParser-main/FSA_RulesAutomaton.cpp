#include "FSA_RulesAutomaton.h"
using namespace std;
void RulesAutomaton::S0() {
    if (EndOfFile()){
        Serr();
    }
    else if (CurrentLetter() == 'R') {
        Accept();
        S1();
    }
    else {
        Serr();
    }
}

void RulesAutomaton::S1() {
    if (EndOfFile()){
        Serr();
    }
    else if (CurrentLetter() == 'u') {
        Accept();
        S2();
    }
    else {
        Serr();
    }
}

void RulesAutomaton::S2() {
    if (EndOfFile()){
        Serr();
    }
    else if (CurrentLetter() == 'l') {
        Accept();
        S3();
    }
    else {
        Serr();
    }
}

void RulesAutomaton::S3() {
    if (EndOfFile()){
        Serr();
    }
    else if (CurrentLetter() == 'e') {
        Accept();
        S4();
    }
    else {
        Serr();
    }
}

void RulesAutomaton::S4() {
    if (EndOfFile()){
        Serr();
    }
    else if (CurrentLetter() == 's') {
        Accept();
    }
    else {
        Serr();
    }
}

