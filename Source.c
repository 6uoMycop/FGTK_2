#define _CRT_SECURE_NO_WARNINGS
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include "y_tab.h"

FILE *yyin = NULL;

int yyerror(char *str)
{
    printf("Line %i - error: \"%s\"\n", iLineNumber, str);
    return 0;
}

int yylex()
{
    char c;
    c = fgetc(yyin);

#ifdef _DEBUG
    //printf("\'%c\' %i %i\n", c, (int)c, ifComment);
#endif

	//while (c == ' ')
	//{
	//	c = fgetc(yyin);
	//}

    if (ifComment && c != '\n')
    {
        return (ANYCHAR);
    }
    if (c == '#')
    {
        ifComment = 1;
        return (c);
    }
    
    if (isdigit(c))
    {
        yylval.iNum = c - '0';
        return (DIGIT);
    }
    if (c >= 'a' && c <= 'z' && c != 'p' && c != 'r' && c != 'i' && c != 'n' && c != 't')
    {
        yylval.cVar = c;
        return (VARIABLE);
    }
    if (c >= 'A' && c <= 'Z')
    {
        yylval.cVar = c;
        return (POLYVARIABLE);
    }
    if (c == '/')
    {
        yyerror("Undefined operation '/'");
        return c;
    }
    return (c);
}

int main()
{
    yyin = fopen("input.txt", "r");
    if (yyin == NULL)
    {
        yyerror("file was not opened");
        return 0;
    }
    yyparse();
    fclose(yyin);
    //system("pause");
    return 0;
}