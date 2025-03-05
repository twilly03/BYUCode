#ifndef COLONAUTOMATON_H
#define COLONAUTOMATON_H

#include "Automaton.h"

class ColonAutomaton : public Automaton
{
public:
    ColonAutomaton() : Automaton(TokenType::COLON) {}  // Call the base constructor

    void S0();
};

#endif // COLONAUTOMATON_H

