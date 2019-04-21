%{
    #define YYERROR_VERBOSE
    #define _CRT_SECURE_NO_WARNINGS
    #define alloca malloc
    #include <Windows.h>
    #define SIZE 64
    #define YYDEBUG 1
    char cVariable = -1;
    int ifComment = 0;
    int iLineNumber = 1;
    
    struct express
    {
        char cExVar;
        int  ifInit;
        int  iCoeffArr[SIZE];
    };
    
    struct express ePolyVariables[26];
    
    void debugOutput(struct express exp, int N)
    {
#ifdef _DEBUG
        printf("%i:\t", N);
        for(int i = 0; i < 7; i++)
        {
            printf("%i\t", exp.iCoeffArr[i]);
        }
        printf("\n");
#endif
    }
    
    void errorOutput(const char *str)
    {
        yyerror(str);
    }
    
    void printExpr(struct express exp)
    {
                int ifZero = 1;
                for(int i = 0; i < SIZE; i++)
                {
                    if(exp.iCoeffArr[i] != 0)
                    {
                        ifZero = 0;
                        break;
                    }
                }
                if(ifZero == 1)
                {
                    printf("0");
                }
                else
                {
                    int ifFirst = 1;
                    for (int i = 0; i < SIZE; i++)
                    {
                        if (exp.iCoeffArr[i] != 0)
                        {
                            if (exp.iCoeffArr[i] > 0 && !ifFirst)
                            {
                                printf("+");
                            }
                            if (i == 0 || exp.iCoeffArr[i] > 1 || exp.iCoeffArr[i] < -1)
                            {
                                printf("%i", exp.iCoeffArr[i]);
                            }
                            if (i > 0)
                            {
                                if (exp.iCoeffArr[i] > 1 || exp.iCoeffArr[i] < -1)
                                {
                                    printf("*");
                                }
                                else if (exp.iCoeffArr[i] == -1)
                                {
                                    printf("-");
                                }
                                printf("%c", exp.cExVar);
                                if (i > 1)
                                {
                                    printf("^%i", i);
                                }
                            }
                            ifFirst = 0;
                        }
                    }
                }
                printf("\n");
            }
%}

%union { int iNum; struct express stExpr; char cVar; }

%token <iNum>   DIGIT
%token <cVar>   VARIABLE POLYVARIABLE
%token ANYCHAR
%type  <cVar>   polyvar
%type  <iNum>   number
%type  <stExpr> expr

%left  LOW
%right '='
%left  '+' '-'
%left  '*'
%left  '^'
%left  UMINUS
%nonassoc COM

%%

start   :   line
        |   start '\n' line
        ;
        
comment :   ANYCHAR
        |   ANYCHAR comment
        ;

line    :   polyvar '=' expr
            {
                for(int i = 0; i < SIZE; i++)
                {
                    ePolyVariables[$1-'A'].iCoeffArr[i] = $3.iCoeffArr[i];
                }
                ePolyVariables[$1-'A'].ifInit = 1;
                ePolyVariables[$1-'A'].cExVar = $3.cExVar;
                iLineNumber++;
                debugOutput(ePolyVariables[$1-'A'], 999);
            }
        |   'p' 'r' 'i' 'n' 't' ' ' polyvar
            {
                if(ePolyVariables[$7-'A'].ifInit == 1)
                {
                    printf("$%c=", $7);
                    printExpr(ePolyVariables[$7-'A']);
                }
                else
                {
                    errorOutput("Uninitialized $-variable");
                    YYABORT;
                }
                iLineNumber++;
            }
        |   '#' comment %prec COM
            {
                ifComment = 0;
                iLineNumber++;
            }
        |   polyvar '=' expr '#' comment %prec COM
            {
                for(int i = 0; i < SIZE; i++)
                {
                    ePolyVariables[$1-'A'].iCoeffArr[i] = $3.iCoeffArr[i];
                }
                ePolyVariables[$1-'A'].ifInit = 1;
                ePolyVariables[$1-'A'].cExVar = $3.cExVar;
                ifComment = 0;
                iLineNumber++;
                debugOutput(ePolyVariables[$1-'A'], 999);
            }
        |   'p' 'r' 'i' 'n' 't' ' ' polyvar '#' comment %prec COM
            {
                if(ePolyVariables[$7-'A'].ifInit == 1)
                {
                    printf("$%c=", $7);
                    printExpr(ePolyVariables[$7-'A']);
                }
                else
                {
                    errorOutput("Uninitialized $-variable");
                    YYABORT;
                }
                ifComment = 0;
                iLineNumber++;
            }
        |   /* VOID */
            {
                iLineNumber++;  
            }           
        |   polyvar '='
            {
                errorOutput("Expected assignment after '='");
                iLineNumber++;
                YYABORT;
            }
        |   polyvar '=' '#' comment %prec COM
            {
                errorOutput("Expected assignment after '='");
                iLineNumber++;
                YYABORT;
            }           
        |   'p' 'r' 'i' 'n' 't' ' '
            {
                errorOutput("Expected $-variable as an argument");
                iLineNumber++;
                YYABORT;
            }
        |   'p' 'r' 'i' 'n' 't' ' ' '#' comment %prec COM
            {
                errorOutput("Expected $-variable as an argument");
                iLineNumber++;
                YYABORT;
            }
        ;

polyvar :   '$' POLYVARIABLE
            {
                $$ = $2;
            }
        ;

expr    :   expr '+' expr                                                    /*1*/
            {
                ZeroMemory($$.iCoeffArr, SIZE);
                if($1.cExVar != $3.cExVar)
                {
                    if(($1.cExVar != '@' && ($3.cExVar >= 'a' && $3.cExVar <= 'z')) || ($3.cExVar != '@' && ($1.cExVar >= 'a' && $1.cExVar <= 'z')))
                    {
                        errorOutput("Variables mismatch");
                        YYABORT;
                    }
                }
                $$.cExVar = (($1.cExVar != '@') ? $1.cExVar : $3.cExVar);
                for(int i = 0; i < SIZE; i++)
                {
                    $$.iCoeffArr[i] = $1.iCoeffArr[i] + $3.iCoeffArr[i];
                }
                debugOutput($$, 1);
            }
        |   expr '-' expr                                                    /*2*/
            {
                ZeroMemory($$.iCoeffArr, SIZE);
                if($1.cExVar != $3.cExVar)
                {
                    if(($1.cExVar != '@' && ($3.cExVar >= 'a' && $3.cExVar <= 'z')) || ($3.cExVar != '@' && ($1.cExVar >= 'a' && $1.cExVar <= 'z')))
                    {
                        errorOutput("Variables mismatch");
                        YYABORT;
                    }
                }
                $$.cExVar = (($1.cExVar != '@') ? $1.cExVar : $3.cExVar);
                for(int i = 0; i < SIZE; i++)
                {
                    $$.iCoeffArr[i] = $1.iCoeffArr[i] - $3.iCoeffArr[i];
                }
                debugOutput($$, 2);
            }
        |   expr '*' expr                                                    /*3*/
            {
                ZeroMemory($$.iCoeffArr, SIZE);
                if($1.cExVar != $3.cExVar)
                {
                    if(($1.cExVar != '@' && ($3.cExVar >= 'a' && $3.cExVar <= 'z')) || ($3.cExVar != '@' && ($1.cExVar >= 'a' && $1.cExVar <= 'z')))
                    {
                        errorOutput("Variables mismatch");
                        YYABORT;
                    }
                }
                $$.cExVar = (($1.cExVar != '@') ? $1.cExVar : $3.cExVar);
                for(int i = 0; i < SIZE / 2; i++)
                {
                    for(int j = 0; j < SIZE / 2; j++)
                    {
                        $$.iCoeffArr[i + j] += $1.iCoeffArr[i] * $3.iCoeffArr[j];
                    }
                }
                debugOutput($$, 3);
            }
        |   polyvar                                                          /*200*/
            {
                if(ePolyVariables[$1-'A'].ifInit != 1)
                {
                    errorOutput("Uninitialized $-variable");
                    YYABORT;
                }
                $$.cExVar = ePolyVariables[$1-'A'].cExVar;
                ZeroMemory($$.iCoeffArr, SIZE);
                for(int i = 0; i < SIZE; i++)
                {
                    $$.iCoeffArr[i] = ePolyVariables[$1-'A'].iCoeffArr[i];
                }
                debugOutput($$, 200);
            }
        |   '-' polyvar                                      %prec UMINUS    /*300*/
            {
                if(ePolyVariables[$2-'A'].ifInit != 1)
                {
                    errorOutput("Uninitialized $-variable");
                    YYABORT;
                }
                $$.cExVar = ePolyVariables[$2-'A'].cExVar;
                ZeroMemory($$.iCoeffArr, SIZE);
                for(int i = 0; i < SIZE; i++)
                {
                    $$.iCoeffArr[i] = -1 * ePolyVariables[$2-'A'].iCoeffArr[i];
                }
                debugOutput($$, 300);
            }
        |   polyvar '^' number                                               /*900*/
            {
                if(ePolyVariables[$1-'A'].ifInit != 1)
                {
                    errorOutput("Uninitialized $-variable");
                    YYABORT;
                }
                $$.cExVar = ePolyVariables[$1-'A'].cExVar;
                ZeroMemory($$.iCoeffArr, SIZE);
                int iTmp[SIZE] = { 0 };
                if($3 == 0)
                {
                    $$.iCoeffArr[0] = 1;
                }
                else
                {
                    for(int i = 0; i < SIZE; i++)
                    {
                        $$.iCoeffArr[i] = ePolyVariables[$1-'A'].iCoeffArr[i];
                    }
                    for(int n = 0; n < $3 - 1; n++)
                    {
                        for(int i = 0; i < SIZE; i++)
                        {
                            iTmp[i] = $$.iCoeffArr[i];
                            $$.iCoeffArr[i] = 0;
                        }
                        for(int i = 0; i < SIZE / 2; i++)
                        {
                            for(int j = 0; j < SIZE / 2; j++)
                            {
                                $$.iCoeffArr[i + j] += iTmp[i] * ePolyVariables[$1-'A'].iCoeffArr[j];
                            }
                        }
                    }
                }
                debugOutput($$, 900);
            }
        |   '(' '-' polyvar ')' '^' number                   %prec UMINUS    /*1000*/
            {
                if(ePolyVariables[$3-'A'].ifInit != 1)
                {
                    errorOutput("Uninitialized $-variable");
                    YYABORT;
                }
                $$.cExVar = ePolyVariables[$3-'A'].cExVar;
                ZeroMemory($$.iCoeffArr, SIZE);
                int iTmp[SIZE] = { 0 };
                if($6 == 0)
                {
                    $$.iCoeffArr[0] = 1;
                }
                else
                {
                    for(int i = 0; i < SIZE; i++)
                    {
                        $$.iCoeffArr[i] = ePolyVariables[$3-'A'].iCoeffArr[i];
                    }
                    for(int n = 0; n < $6 - 1; n++)
                    {
                        for(int i = 0; i < SIZE; i++)
                        {
                            iTmp[i] = $$.iCoeffArr[i];
                            $$.iCoeffArr[i] = 0;
                        }
                        for(int i = 0; i < SIZE / 2; i++)
                        {
                            for(int j = 0; j < SIZE / 2; j++)
                            {
                                $$.iCoeffArr[i + j] += iTmp[i] * ePolyVariables[$3-'A'].iCoeffArr[j];
                            }
                        }
                    }
                    if($6 % 2 == 1)
                    {
                        for(int i = 0; i < SIZE; i++)
                        {
                            $$.iCoeffArr[i] *= -1;
                        }
                    }
                }
                debugOutput($$, 1000);
            }
        |   '(' expr ')'                                                     /*4*/
            {
                ZeroMemory($$.iCoeffArr, SIZE);
                $$.cExVar = $2.cExVar;
                for(int i = 0; i < SIZE; i++)
                {
                    $$.iCoeffArr[i] = $2.iCoeffArr[i];
                }
                debugOutput($$, 4);
            }
        |   '-' '(' expr ')'                                 %prec UMINUS    /*5*/
            {
                ZeroMemory($$.iCoeffArr, SIZE);
                $$.cExVar = $3.cExVar;
                for(int i = 0; i < SIZE; i++)
                {
                    $$.iCoeffArr[i] = -1 * $3.iCoeffArr[i];
                }
                debugOutput($$, 5);
            }
        |   number                                                           /*6*/
            {
                ZeroMemory($$.iCoeffArr, SIZE);
                $$.cExVar = '@';
                $$.iCoeffArr[0] = $1;
                debugOutput($$, 6);
            }
        |    '-' number                                      %prec UMINUS    /*7*/
            {
                ZeroMemory($$.iCoeffArr, SIZE);
                $$.cExVar = '@';
                $$.iCoeffArr[0] = -1 * $2;
                debugOutput($$, 7);
            }
        |   number '*' expr                                                  /*8*/
            {
                ZeroMemory($$.iCoeffArr, SIZE);
                $$.cExVar = $3.cExVar;
                for(int i = 0; i < SIZE; i++)
                {
                    $$.iCoeffArr[i] = $3.iCoeffArr[i] * $1;
                }
                debugOutput($$, 8);
            }
        |   '-' number '*' expr                              %prec UMINUS    /*9*/
            {
                ZeroMemory($$.iCoeffArr, SIZE);
                $$.cExVar = $4.cExVar;
                for(int i = 0; i < SIZE; i++)
                {
                    $$.iCoeffArr[i] = -1 * $4.iCoeffArr[i] * $2;
                }
                debugOutput($$, 9);
            }
        |   VARIABLE                                                         /*10*/
            {
                ZeroMemory($$.iCoeffArr, SIZE);
                $$.iCoeffArr[1] = 1;
                $$.cExVar = $1;
                cVariable = $1;
                debugOutput($$, 10);
            }
        |   '-' VARIABLE                                     %prec UMINUS    /*11*/
            {
                ZeroMemory($$.iCoeffArr, SIZE);
                $$.iCoeffArr[1] = -1;
                $$.cExVar = $2;
                cVariable = $2;
                debugOutput($$, 11);
            }
        |   VARIABLE '^' number                                              /*12*/
            {
                ZeroMemory($$.iCoeffArr, SIZE);
                $$.iCoeffArr[$3] = 1;
                $$.cExVar = $1;
                cVariable = $1;
                debugOutput($$, 12);
            }
        |   '(' '-' VARIABLE ')' '^' number                  %prec UMINUS    /*13*/
            {
                ZeroMemory($$.iCoeffArr, SIZE);
                if ($6 % 2 == 0)
                {
                    $$.iCoeffArr[$3] = 1;
                }
                else
                {
                    $$.iCoeffArr[$3] = -1;
                }
                $$.cExVar = $3;
                cVariable = $3;
                debugOutput($$, 13);
            }
        |   '-' VARIABLE '^' number                          %prec UMINUS    /*14*/
            {
                ZeroMemory($$.iCoeffArr, SIZE);
                $$.iCoeffArr[$4] = -1;
                $$.cExVar = $2;
                cVariable = $2;
                debugOutput($$, 14);
            }
        |   number '^' number                                                /*15*/
            {
                ZeroMemory($$.iCoeffArr, SIZE);
                $$.cExVar = '@';
                if($3 == 0)
                {
                    if($1 == 0)
                    {
                        errorOutput("\"0^0\" undefined");
                        YYABORT;
                    }
                    else
                    {
                        $$.iCoeffArr[0] = 1;
                    }
                }
                else
                {
                    $$.iCoeffArr[0] = $1;
                    for(int i = 0; i < $3 - 1; i++)
                    {
                        $$.iCoeffArr[0] *= $1;
                    }
                }
                debugOutput($$, 15);
            }
        |   '-' number '^' number                            %prec UMINUS    /*16*/
            {
                ZeroMemory($$.iCoeffArr, SIZE);
                $$.cExVar = '@';
                if($4 == 0)
                {
                    $$.iCoeffArr[0] = -1;
                }
                else
                {
                    $$.iCoeffArr[0] = -1 * $2;
                    for(int i = 0; i < $4 - 1; i++)
                    {
                        $$.iCoeffArr[0] *= $2;
                    }
                }
                debugOutput($$, 16);
            }
        |   '(' '-' number ')' '^' number                    %prec UMINUS    /*17*/
            {
                ZeroMemory($$.iCoeffArr, SIZE);
                $$.cExVar = '@';
                if($6 == 0)
                {
                    $$.iCoeffArr[0] = 1;
                }
                else
                {
                    if ($6 % 2 == 0)
                    {
                        $$.iCoeffArr[0] = $3;
                        for(int i = 0; i < $6 - 1; i++)
                        {
                            $$.iCoeffArr[0] *= $3;
                        }
                    }
                    else
                    {
                        $$.iCoeffArr[0] = -1 * $3;
                        for(int i = 0; i < $6 - 1; i++)
                        {
                            $$.iCoeffArr[0] *= $3;
                        }
                    }
                }
                debugOutput($$, 17);
            }
        |   '(' expr ')' '^' number                                          /*18*/
            {
                ZeroMemory($$.iCoeffArr, SIZE);
                $$.cExVar = $2.cExVar;
                int iTmp[SIZE] = { 0 };
                if($5 == 0)
                {
                    $$.iCoeffArr[0] = 1;
                }
                else
                {
                    for(int i = 0; i < SIZE; i++)
                    {
                        $$.iCoeffArr[i] = $2.iCoeffArr[i];
                    }
                    for(int n = 0; n < $5 - 1; n++)
                    {
                        for(int i = 0; i < SIZE; i++)
                        {
                            iTmp[i] = $$.iCoeffArr[i];
                            $$.iCoeffArr[i] = 0;
                        }
                        for(int i = 0; i < SIZE / 2; i++)
                        {
                            for(int j = 0; j < SIZE / 2; j++)
                            {
                                $$.iCoeffArr[i + j] += iTmp[i] * $2.iCoeffArr[j];
                            }
                        }
                    }
                }
                debugOutput($$, 18);
            }
        |   '-' '(' expr ')' '^' number                      %prec UMINUS    /*19*/
            {
                ZeroMemory($$.iCoeffArr, SIZE);
                $$.cExVar = $3.cExVar;
                int iTmp[SIZE] = { 0 };
                if($6 == 0)
                {
                    $$.iCoeffArr[0] = -1;
                }
                else
                {
                    for(int i = 0; i < SIZE; i++)
                    {
                        $$.iCoeffArr[i] = $3.iCoeffArr[i];
                    }
                    for(int n = 0; n < $6 - 1; n++)
                    {
                        for(int i = 0; i < SIZE; i++)
                        {
                            iTmp[i] = $$.iCoeffArr[i];
                            $$.iCoeffArr[i] = 0;
                        }
                        for(int i = 0; i < SIZE / 2; i++)
                        {
                            for(int j = 0; j < SIZE / 2; j++)
                            {
                                $$.iCoeffArr[i + j] += iTmp[i] * $3.iCoeffArr[j];
                            }
                        }
                    }
                    for(int i = 0; i < SIZE; i++)
                    {
                        $$.iCoeffArr[i] *= -1;
                    }
                }
                debugOutput($$, 19);
            }
        |   '(' '-' number ')'                               %prec UMINUS    /*20*/
            {
                ZeroMemory($$.iCoeffArr, SIZE);
                $$.cExVar = '@';
                $$.iCoeffArr[0] = -1 * $3;
                debugOutput($$, 20);
            }
        |   '(' '-' VARIABLE ')'                             %prec UMINUS    /*21*/
            {
                ZeroMemory($$.iCoeffArr, SIZE);
                $$.iCoeffArr[1] = -1;
                $$.cExVar = $3;
                cVariable = $3;
                $$.iCoeffArr[0] -= (int)$3;
                debugOutput($$, 21);
            }
        |   expr expr                                        %prec '*'       /*1488*/
            {
                ZeroMemory($$.iCoeffArr, SIZE);
                if($1.cExVar != $2.cExVar)
                {
                    if(($1.cExVar != '@' && ($2.cExVar >= 'a' && $2.cExVar <= 'z')) || ($2.cExVar != '@' && ($1.cExVar >= 'a' && $1.cExVar <= 'z')))
                    {
                        errorOutput("Variables mismatch");
                        YYABORT;
                    }
                }
                $$.cExVar = (($1.cExVar != '@') ? $1.cExVar : $2.cExVar);
                for(int i = 0; i < SIZE / 2; i++)
                {
                    for(int j = 0; j < SIZE / 2; j++)
                    {
                        $$.iCoeffArr[i + j] += $1.iCoeffArr[i] * $2.iCoeffArr[j];
                    }
                }
                debugOutput($$, 1488);
            }
        /* errors */
        |   expr '-' '-'
          {
                errorOutput("Operation \"--\" undefined");
                YYABORT;
          }
        |   '-' '-' expr
          {
                errorOutput("Operation \"--\" undefined");
                YYABORT;
          }
        |   expr '+' '+'
          {
                errorOutput("Operation \"++\" undefined");
                YYABORT;
          }
        |   '+' '+' expr
          {
                errorOutput("Operation \"++\" undefined");
                YYABORT;
          }
        ;

number  :   DIGIT
            {
                $$ = $1;
            }
        |    number DIGIT
            {
                $$ = $1 * 10 + $2;
            }
        ;
