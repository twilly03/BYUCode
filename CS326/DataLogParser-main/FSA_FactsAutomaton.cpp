#include "FSA_FactsAutomaton.h"
using namespace std;
void FactsAutomaton::S0() {
    if (EndOfFile()){
        Serr();
    }
    if (CurrentLetter() == 'F') {
        Accept();
        S1();
    }
    else {
        Serr();
    }
}

void FactsAutomaton::S1() {
    if (EndOfFile()){
        Serr();
    }
    if (CurrentLetter() == 'a') {
        Accept();
        S2();
    }
    else {
        Serr();
    }
}

void FactsAutomaton::S2() {
    if (EndOfFile()){
        Serr();
    }
    if (CurrentLetter() == 'c') {
        Accept();
        S3();
    }
    else {
        Serr();
    }
}

void FactsAutomaton::S3() {
    if (EndOfFile()){
        Serr();
    }
    if (CurrentLetter() == 't') {
        Accept();
        S4();
    }
    else {
        Serr();
    }
}

void FactsAutomaton::S4() {
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

