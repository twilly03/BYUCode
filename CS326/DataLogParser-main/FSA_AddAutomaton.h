#ifndef ADDAUTOMATON_H
#define ADDAUTOMATON_H

#include "Automaton.h"

class AddAutomaton : public Automaton
{
public:
    AddAutomaton() : Automaton(TokenType::ADD) {}  // Call the base constructor
    void S0();
};

#endif // ADDAUTOMATON_H