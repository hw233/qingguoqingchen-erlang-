%%% -------------------------------------------------------------------
%%% 9秒社团全球首次开源发布
%%% http://www.9miao.com
%%% -------------------------------------------------------------------
%% @copyright 2007 Mochi Media, Inc.
%% @author Bob Ippolito <bob@mochimedia.com>

%% @doc Useful numeric algorithms for floats that cover some deficiencies
%% in the math module. More interesting is digits/1, which implements
%% the algorithm from:
%% http://www.cs.indiana.edu/~burger/fp/index.html
%% See also "Printing Floating-Point Numbers Quickly and Accurately"
%% in Proceedings of the SIGPLAN '96 Conference on Programming Language
%% Design and Implementation.

-module(num_util).
-author("Bob Ippolito <bob@mochimedia.com>").
-export([digits/1, frexp/1, int_pow/2, int_ceil/1]).

%% IEEE 754 Float exponent bias
-define(FLOAT_BIAS, 1022).
-define(MIN_EXP, -1074).
-define(BIG_POW, 4503599627370496).

%% External API

%% @spec digits(number()) -> string()
%% @doc  Returns a string that accurately represents the given integer or float
%%       using a conservative amount of digits. Great for generating
%%       human-readable output, or compact ASCII serializations for floats.
digits(N) when is_integer(N) ->
    integer_to_list(N);
digits(0.0) ->
    "0.0";
digits(Float) ->
    {Frac, Exp} = frexp(Float),
    Exp1 = Exp - 53,
    Frac1 = trunc(abs(Frac) * (1 bsl 53)),
    [Place | Digits] = digits1(Float, Exp1, Frac1),
    R = insert_decimal(Place, [$0 + D || D <- Digits]),
    case Float < 0 of
        true ->
            [$- | R];
        _ ->
            R
    end.

%% @spec frexp(F::float()) -> {Frac::float(), Exp::float()}
%% @doc  Return the fractional and exponent part of an IEEE 754 double,
%%       equivalent to the libc function of the same name.
%%       F = Frac * pow(2, Exp).
frexp(F) ->
    frexp1(unpack(F)).

%% @spec int_pow(X::integer(), N::integer()) -> Y::integer()
%% @doc  Moderately efficient way to exponentiate integers.
%%       int_pow(10, 2) = 100.
int_pow(_X, 0) ->
    1;
int_pow(X, N) when N > 0 ->
    int_pow(X, N, 1).

%% @spec int_ceil(F::float()) -> integer()
%% @doc  Return the ceiling of F as an integer. The ceiling is defined as
%%       F when F == trunc(F);
%%       trunc(F) when F &lt; 0;
%%       trunc(F) + 1 when F &gt; 0.
int_ceil(X) ->
    T = trunc(X),
    case (X - T) of
        Neg when Neg < 0 -> T;
        Pos when Pos > 0 -> T + 1;
        _ -> T
    end.


%% Internal API

int_pow(X, N, R) when N < 2 ->
    R * X;
int_pow(X, N, R) ->
    int_pow(X * X, N bsr 1, case N band 1 of 1 -> R * X; 0 -> R end).

insert_decimal(0, S) ->
    "0." ++ S;
insert_decimal(Place, S) when Place > 0 ->
    L = length(S),
    case Place - L of
         0 ->
            S ++ ".0";
        N when N < 0 ->
            {S0, S1} = lists:split(L + N, S),
            S0 ++ "." ++ S1;
        N when N < 6 ->
            %% More places than digits
            S ++ lists:duplicate(N, $0) ++ ".0";
        _ ->
            insert_decimal_exp(Place, S)
    end;
insert_decimal(Place, S) when Place > -6 ->
    "0." ++ lists:duplicate(abs(Place), $0) ++ S;
insert_decimal(Place, S) ->
    insert_decimal_exp(Place, S).

insert_decimal_exp(Place, S) ->
    [C | S0] = S,
    S1 = case S0 of
             [] ->
                 "0";
             _ ->
                 S0
         end,
    Exp = case Place < 0 of
              true ->
                  "e-";
              false ->
                  "e+"
          end,
    [C] ++ "." ++ S1 ++ Exp ++ integer_to_list(abs(Place - 1)).


digits1(Float, Exp, Frac) ->
    Round = ((Frac band 1) =:= 0),
    case Exp >= 0 of
        true ->
            BExp = 1 bsl Exp,
            case (Frac =/= ?BIG_POW) of
                true ->
                    scale((Frac * BExp * 2), 2, BExp, BExp,
                          Round, Round, Float);
                false ->
                    scale((Frac * BExp * 4), 4, (BExp * 2), BExp,
                          Round, Round, Float)
            end;
        false ->
            case (Exp =:= ?MIN_EXP) orelse (Frac =/= ?BIG_POW) of
                true ->
                    scale((Frac * 2), 1 bsl (1 - Exp), 1, 1,
                          Round, Round, Float);
                false ->
                    scale((Frac * 4), 1 bsl (2 - Exp), 2, 1,
                          Round, Round, Float)
            end
    end.

scale(R, S, MPlus, MMinus, LowOk, HighOk, Float) ->
    Est = int_ceil(math:log10(abs(Float)) - 1.0e-10),
    %% Note that the scheme implementation uses a 326 element look-up table
    %% for int_pow(10, N) where we do not.
    case Est >= 0 of
        true ->
            fixup(R, S * int_pow(10, Est), MPlus, MMinus, Est,
                  LowOk, HighOk);
        false ->
            Scale = int_pow(10, -Est),
            fixup(R * Scale, S, MPlus * Scale, MMinus * Scale, Est,
                  LowOk, HighOk)
    end.

fixup(R, S, MPlus, MMinus, K, LowOk, HighOk) ->
    TooLow = case HighOk of
                 true ->
                     (R + MPlus) >= S;
                 false ->
                     (R + MPlus) > S
             end,
    case TooLow of
        true ->
            [(K + 1) | generate(R, S, MPlus, MMinus, LowOk, HighOk)];
        false ->
            [K | generate(R * 10, S, MPlus * 10, MMinus * 10, LowOk, HighOk)]
    end.

generate(R0, S, MPlus, MMinus, LowOk, HighOk) ->
    D = R0 div S,
    R = R0 rem S,
    TC1 = case LowOk of
              true ->
                  R =< MMinus;
              false ->
                  R < MMinus
          end,
    TC2 = case HighOk of
              true ->
                  (R + MPlus) >= S;
              false ->
                  (R + MPlus) > S
          end,
    case TC1 of
        false ->
            case TC2 of
                false ->
                    [D | generate(R * 10, S, MPlus * 10, MMinus * 10,
                                  LowOk, HighOk)];
                true ->
                    [D + 1]
            end;
        true ->
            case TC2 of
                false ->
                    [D];
                true ->
                    case R * 2 < S of
                        true ->
                            [D];
                        false ->
                            [D + 1]
                    end
            end
    end.

unpack(Float) ->
    <<Sign:1, Exp:11, Frac:52>> = <<Float:64/float>>,
    {Sign, Exp, Frac}.

frexp1({_Sign, 0, 0}) ->
    {0.0, 0};
frexp1({Sign, 0, Frac}) ->
    Exp = log2floor(Frac),
    <<Frac1:64/float>> = <<Sign:1, ?FLOAT_BIAS:11, (Frac-1):52>>,
    {Frac1, -(?FLOAT_BIAS) - 52 + Exp};
frexp1({Sign, Exp, Frac}) ->
    <<Frac1:64/float>> = <<Sign:1, ?FLOAT_BIAS:11, Frac:52>>,
    {Frac1, Exp - ?FLOAT_BIAS}.

log2floor(Int) ->
    log2floor(Int, 0).

log2floor(0, N) ->
    N;
log2floor(Int, N) ->
    log2floor(Int bsr 1, 1 + N).
