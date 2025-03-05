#include "Lexer.h"
#include <iostream>
#include <fstream>
#include <sstream>

using namespace std;

int main(int argc, char* argv[]) {

    string file = argv[1];
    ifstream inFile(file);

    string input, line;
    while (getline(inFile, line)){
        input += line + '\n';
    }
    inFile.close();

    Lexer* lexer = new Lexer();
    lexer->Run(input);


    delete lexer;
    return 0;
}