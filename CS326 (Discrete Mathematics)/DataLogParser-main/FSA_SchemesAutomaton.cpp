#include "FSA_SchemesAutomaton.h"
using namespace std;
void SchemesAutomaton::S0() {
    if (EndOfFile()){
        Serr();
    }
    else if (CurrentLetter() == 'S') {
        Accept();
        S1();
    }
    else {
        Serr();
    }
}

void SchemesAutomaton::S1() {
    if (EndOfFile()){
        Serr();
    }
    else if (CurrentLetter() == 'c') {
        Accept();
        S2();
    }
    else {
        Serr();
    }
}

void SchemesAutomaton::S2() {
    if (EndOfFile()){
        Serr();
    }
    else if (CurrentLetter() == 'h') {
        Accept();
        S3();
    }
    else {
        Serr();
    }
}

void SchemesAutomaton::S3() {
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

void SchemesAutomaton::S4() {
    if (EndOfFile()){
        Serr();
    }
    else if (CurrentLetter() == 'm') {
        Accept();
        S5();
    }
    else {
        Serr();
    }
}

void SchemesAutomaton::S5() {
    if (EndOfFile()){
        Serr();
    }
    else if (CurrentLetter() == 'e') {
        Accept();
        S6();
    }
    else {
        Serr();
    }
}

void SchemesAutomaton::S6() {
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