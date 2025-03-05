#ifndef MULTIPLYPARENAUTOMATON_H
#define MULTIPLYPARENAUTOMATON_H

#include "Automaton.h"

class MultiplyAutomaton : public Automaton
{
public:
    MultiplyAutomaton() : Automaton(TokenType::MULTIPLY) {}  // Call the base constructor
    void S0();
};

#endif // MULTIPLYAUTOMATON_H