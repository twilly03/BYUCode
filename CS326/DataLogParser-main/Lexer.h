#ifndef LEXER_H
#define LEXER_H
#include <vector>
#include "Automaton.h"
#include "Token.h"

class Lexer
{
private:
    std::vector<Automaton*> automata;
    std::vector<Token*> tokens;
    std::string input;

    void CreateAutomata();

    // TODO: add any other private methods here (if needed)

public:
    Lexer(){
        CreateAutomata();
    };

    ~Lexer() {
        // TODO: need to clean up the memory in `automata` and `tokens`
    }
    void Run(std::string& input);
    
    // TODO: add other public methods here

};

#endif // LEXER_H

