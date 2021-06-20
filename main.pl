% Odysseas Lomvardeas 3362
% Alexandros Sofoulakis 3346
% Melina Zikou 3357

query(ListOfKeywords) :- generate_keyword_score_pairs(ListOfKeywords).

generate_keyword_score_pairs([]).
generate_keyword_score_pairs([Keyword|ListOfKeywords]) :- 
    parse(Keyword),
    generate_keyword_score_pairs(ListOfKeywords).

parse(Keyword) :- print(Keyword), nl.