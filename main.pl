% Odysseas Lomvardeas 3362
% Alexandros Sofoulakis 3346
% Melina Zikou 3357

query(ListOfKeywords) :- generate_keyword_score_pairs(ListOfKeywords).

generate_keyword_score_pairs([]).
generate_keyword_score_pairs([Keyword|ListOfKeywords]) :- 
    parse(Keyword),
    generate_keyword_score_pairs(ListOfKeywords).

% Keyword matches the pattern keyword-weight
ensure_full_keyword(Keyword, FullKeyword) :- 
    pairs_keys_values([Keyword], [_], [Weight]),
    number(Weight),                                     % Required for words with dashes (eg. semi-transparent)
    FullKeyword = Keyword,
    !.                                                  % Prevent unnecessary second pass

ensure_full_keyword(Keyword, FullKeyword) :- 
    % Keyword lacks weight
    \+ (
        pairs_keys_values([Keyword], [_], [Weight]),
        number(Weight)                                  % Required for words with dashes (eg. semi-transparent)
    ),                   
    pairs_keys_values([FullKeyword], [Keyword], [1]).   % Add default weight (1)


parse(Keyword) :- ensure_full_keyword(Keyword, FullKeyword), print(FullKeyword), nl.