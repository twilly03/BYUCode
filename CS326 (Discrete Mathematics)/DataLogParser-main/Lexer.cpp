#include "Lexer.h"
#include "FSA_ColonAutomaton.h"
#include "FSA_ColonDashAutomaton.h"
#include "FSA_CommaAutomaton.h"
#include "FSA_PeriodAutomaton.h"
#include "FSA_QMarkAutomaton.h"
#include "FSA_LeftParenAutomaton.h"
#include "FSA_RightParenAutomaton.h"
#include "FSA_MultiplyAutomaton.h"
#include "FSA_AddAutomaton.h"
#include "FSA_SchemesAutomaton.h"
#include "FSA_FactsAutomaton.h"
#include "FSA_RulesAutomaton.h"
#include "FSA_QueriesAutomaton.h"
#include "FSA_IDAutomaton.h"
#include "FSA_CommentAutomaton.h"
#include "FSA_CommentBlockAutomaton.h"
using namespace std;
#include <iostream>
void Lexer::CreateAutomata() {
    automata.push_back(new ColonAutomaton());
    automata.push_back(new ColonDashAutomaton());
    automata.push_back(new CommaAutomaton());
    automata.push_back(new PeriodAutomaton());
    automata.push_back(new QMarkAutomaton());
    automata.push_back(new LeftParenAutomaton());
    automata.push_back(new RightParenAutomaton());
    automata.push_back(new MultiplyAutomaton());
    automata.push_back(new AddAutomaton());
    automata.push_back(new SchemesAutomaton());
    automata.push_back(new FactsAutomaton());
    automata.push_back(new RulesAutomaton());
    automata.push_back(new QueriesAutomaton());
    automata.push_back(new IDAutomaton());
    // TODO: Add the other needed automata here
}

void Lexer::Run(std::string& input) {
    // TODO: convert this pseudo-code with the algorithm into actual C++ code
    int lineNumber = 1;
    while (input.size() > 0){
        int maxRead = 0;
        Automaton *maxAutomaton = automata[0];
        while (isspace(input[0])){
            if (input[0] == '\n'){
                lineNumber++;
            }
            input.erase(0, 1);
        }
        for (unsigned int i = 0; i < automata.size(); i++){
            int numCharsRead = automata[i]->Start(input);
            if (numCharsRead > maxRead){
                maxRead = numCharsRead;
                maxAutomaton = automata[i];
            }
        }
        if (maxRead > 0){
            Token *newToken = maxAutomaton->CreateToken(input.substr(0,maxRead), lineNumber);
            lineNumber += maxAutomaton->NewLinesRead();
            tokens.push_back(newToken);
        }
        else {
            maxRead = 1;
            Token *newToken = new Token(TokenType::UNDEFINED, input, lineNumber);
            tokens.push_back(newToken);
        }
        input.erase(0,maxRead);
    }

    Token *newToken = new Token(TokenType::EOF_TOKEN,"", lineNumber);
    tokens.push_back(newToken);

    for (unsigned int i = 0; i < tokens.size(); i++){
        tokens.at(i)->toString();
    }
    cout << "Total Tokens = " << tokens.size();
    /*
    set lineNumber to 1
    // While there are more characters to tokenize
    loop while input.size() > 0 {
        set maxRead to 0
        set maxAutomaton to the first automaton in automata

        // TODO: you need to handle whitespace inbetween tokens

        // Here is the "Parallel" part of the algorithm
        //   Each automaton runs with the same input
        foreach automaton in automata {
            numCharsRead = automaton.Start(input)
            if (numCharsRead > maxRead) {
                set maxRead to numCharsRead
                set maxAutomaton to automaton
            }
        }
        // Here is the "Max" part of the algorithm
        if maxRead > 0 {
            set newToken to maxAutomaton.CreateToken(...)
                increment lineNumber by maxAutomaton.NewLinesRead()
                add newToken to collection of all tokens
        }
        // No automaton accepted input
        // Create single character undefined token
        else {
            set maxRead to 1
                set newToken to a  new undefined Token
                (with first character of input)
                add newToken to collection of all tokens
        }
        // Update `input` by removing characters read to create Token
        remove maxRead characters from input
    }
    add end of file token to all tokens
    */
}
