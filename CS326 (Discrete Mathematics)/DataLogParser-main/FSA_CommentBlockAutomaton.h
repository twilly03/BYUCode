#ifndef COMMENTBLOCKAUTOMATON_H
#define COMMENTBLOCKAUTOMATON_H

#include "Automaton.h"

class CommentBlockAutomaton : public Automaton
{
private:
    void S1();

public:
    CommentBlockAutomaton() : Automaton(TokenType::COMMENT) {}  // Call the base constructor
    void S0();


};

#endif // COMMENTBLOCKAUTOMATON_H