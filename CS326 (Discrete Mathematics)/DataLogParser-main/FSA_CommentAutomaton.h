#ifndef COMMENTAUTOMATON_H
#define COMMENTAUTOMATON_H

#include "Automaton.h"

class CommentAutomaton : public Automaton
{
private:
    void S1();

public:
    CommentAutomaton() : Automaton(TokenType::COMMENT) {}  // Call the base constructor
    void S0();


};

#endif // COMMENTAUTOMATON_H