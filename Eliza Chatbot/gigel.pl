:- ensure_loaded('chat.pl').

myFind([Key|_], Key):- !.
myFind([_|Tail], Key):- myFind(Tail, Key).

% Returneaza true dacă regula dată ca argument se potriveste cu
% replica data de utilizator. Replica utilizatorului este
% reprezentata ca o lista de tokens. Are nevoie de
% memoria replicilor utilizatorului pentru a deduce emoția/tag-ul
% conversației.
match_rule(Tokens, _UserMemory, rule(Tokens, _, _, _, _)).

% Primeste replica utilizatorului (ca lista de tokens) si o lista de
% reguli, iar folosind match_rule le filtrează doar pe cele care se
% potrivesc cu replica dată de utilizator.

find_matching_rules(_, [], _, []).
find_matching_rules(Tokens, [Head|Tail], UserMemory, [Head|MatchingRules]):- match_rule(Tokens, UserMemory, Head), 
																find_matching_rules(Tokens, Tail, UserMemory, MatchingRules),!.
find_matching_rules(Tokens, [_|Tail], UserMemory, MatchingRules):- find_matching_rules(Tokens, Tail, UserMemory, MatchingRules).

% Intoarce in Answer replica lui Gigel. Selecteaza un set de reguli
% (folosind predicatul rules) pentru care cuvintele cheie se afla in
% replica utilizatorului, in ordine; pe setul de reguli foloseste
% find_matching_rules pentru a obtine un set de raspunsuri posibile.
% Dintre acestea selecteaza pe cea mai putin folosita in conversatie.
%
% Replica utilizatorului este primita in Tokens ca lista de tokens.
% Replica lui Gigel va fi intoarsa tot ca lista de tokens.
%
% UserMemory este memoria cu replicile utilizatorului, folosita pentru
% detectarea emotiei / tag-ului.
% BotMemory este memoria cu replicile lui Gigel și va si folosită pentru
% numararea numarului de utilizari ale unei replici.
%
% In Actions se vor intoarce actiunile de realizat de catre Gigel in
% urma replicii (e.g. exit).
%
% Hint: min_score, ord_subset, find_matching_rules

getAllRulles([],[]).
getAllRulles([_, Head2|Tail],AllRules):-rules([Head2], HeadRules), getAllRulles(Tail, TailRules), 
									append(HeadRules, TailRules, AllRules).
getAllRulles([Head|Tail],AllRules):- rules([Head], HeadRules), getAllRulles(Tail, TailRules), append(HeadRules, TailRules, AllRules).

choseBestHelper(_, [], BestAnswer, BestAnswer, _).
choseBestHelper(BotMemory, [Head|_], Head, _, _):- unwords(Head, Word), \+ get_dict(Word, BotMemory, _), !.
choseBestHelper(BotMemory, [Head|Tail], Answer, BestAnswer, UsedBest):- unwords(Head, Word),
					 get_dict(Word, BotMemory, Used), Used >= UsedBest, choseBestHelper(BotMemory, Tail, Answer, BestAnswer, UsedBest).
choseBestHelper(BotMemory, [Head|Tail], Answer, _, UsedBest):- unwords(Head, Word), 
					 get_dict(Word, BotMemory, Used), Used < UsedBest, choseBestHelper(BotMemory, Tail, Answer, Head, Used).

choseBest(BotMemory, Replies, Answer):- choseBestHelper(BotMemory, Replies, Answer, [nu, inteleg], 1000).


splitRulesHead([rule(_, Replies, Actions,_,_)|_], Replies, Actions).

select_answer(Tokens, UserMemory, BotMemory, Answer, Actions) :- getAllRulles(Tokens, AllRules), 
						find_matching_rules(Tokens, AllRules, UserMemory, AllMatched), splitRulesHead(AllMatched, Replies, Actions), 
						choseBest(BotMemory, Replies, Answer).


% Esuează doar daca valoarea exit se afla in lista Actions.
% Altfel, returnează true.
handle_actions(Actions) :- myFind(Actions, exit), !, fail.
handle_actions(_).

% Caută frecvența (numărul de apariți) al fiecarui cuvânt din fiecare
% cheie a memoriei.
% e.g
% ?- find_occurrences(memory{'joc tenis': 3, 'ma uit la box': 2, 'ma uit la un film': 4}, Result).
% Result = count{box:2, film:4, joc:3, la:6, ma:6, tenis:3, uit:6, un:4}.
% Observați ca de exemplu cuvântul tenis are 3 apariți deoarce replica
% din care face parte a fost spusă de 3 ori (are valoarea 3 în memorie).
% Recomandăm pentru usurința să folosiți înca un dicționar în care să tineți
% frecvențele cuvintelor, dar puteți modifica oricum structura, această funcție
% nu este testată direct.

% find_occurrences/2
% find_occurrences(+UserMemory, -Result)
find_occurrences(_UserMemory, _Result) :- fail.

% Atribuie un scor pentru fericire (de cate ori au fost folosit cuvinte din predicatul happy(X))
% cu cât scorul e mai mare cu atât e mai probabil ca utilizatorul să fie fericit.
get_happy_score_string([], 0).
get_happy_score_string([Head|Tail], Score):- happy(Head), get_happy_score_string(Tail, AuxScore), Score is AuxScore + 1, !.
get_happy_score_string([_|Tail], Score):- get_happy_score_string(Tail, AuxScore), Score is AuxScore + 0, !.


get_happy_score(UserMemory, Score) :-  dict_pairs(UserMemory, memory, []), !, Score is 0.
get_happy_score(UserMemory, Score) :-  dict_pairs(UserMemory, memory, [Key-Value|_]), del_dict(Key, UserMemory, Value, TailDict), 
					get_happy_score(TailDict, AuxScore), words(Key, Tokens), get_happy_score_string(Tokens, TokensScore), 
					Score is AuxScore + Value * TokensScore.

% Atribuie un scor pentru tristețe (de cate ori au fost folosit cuvinte din predicatul sad(X))
% cu cât scorul e mai mare cu atât e mai probabil ca utilizatorul să fie trist.


get_sad_score_string([], 0).
get_sad_score_string([Head|Tail], Score):- sad(Head), get_sad_score_string(Tail, AuxScore), Score is AuxScore + 1, !.
get_sad_score_string([_|Tail], Score):- get_sad_score_string(Tail, AuxScore), Score is AuxScore + 0, !.


get_sad_score(UserMemory, Score) :-  dict_pairs(UserMemory, memory, []), !, Score is 0.
get_sad_score(UserMemory, Score) :-  dict_pairs(UserMemory, memory, [Key-Value|_]), del_dict(Key, UserMemory, Value, TailDict), 
					get_sad_score(TailDict, AuxScore), words(Key, Tokens), get_sad_score_string(Tokens, TokensScore), 
					Score is AuxScore + Value * TokensScore.



% Pe baza celor doua scoruri alege emoția utilizatorul: `fericit`/`trist`,
% sau `neutru` daca scorurile sunt egale.
% e.g:
% ?- get_emotion(memory{'sunt trist': 1}, Emotion).
% Emotion = trist.
get_emotion(UserMemory, trist) :- get_sad_score(UserMemory, SadScore), get_happy_score(UserMemory, HappyScore), 
						SadScore > HappyScore.
get_emotion(UserMemory, neutru) :- get_sad_score(UserMemory, SadScore), get_happy_score(UserMemory, HappyScore), 
						SadScore == HappyScore.
get_emotion(UserMemory, fericit) :- get_sad_score(UserMemory, SadScore), get_happy_score(UserMemory, HappyScore),
						SadScore < HappyScore.

% Atribuie un scor pentru un Tag (de cate ori au fost folosit cuvinte din lista tag(Tag, Lista))
% cu cât scorul e mai mare cu atât e mai probabil ca utilizatorul să vorbească despre acel subiect.


get_tag_score_string([], _, 0).
get_tag_score_string([Head|Tail], KeyWords, Score):- myFind(KeyWords, Head),  get_tag_score_string(Tail, KeyWords, AuxScore), 
									Score is AuxScore + 1, !.
get_tag_score_string([_|Tail], KeyWords, Score):- get_tag_score_string(Tail, KeyWords, AuxScore), Score is AuxScore + 0, !.

get_tag_score(_, UserMemory, Score) :-  dict_pairs(UserMemory, memory, []), !, Score is 0.
get_tag_score(Tag, UserMemory, Score) :- dict_pairs(UserMemory, memory, [Key-Value|_]), del_dict(Key, UserMemory, Value, TailDict),
						 get_tag_score(Tag, TailDict, AuxScore), tag(Tag, KeyWords), words(Key, Tokens), 
						 get_tag_score_string(Tokens, KeyWords, TokensScore), Score is AuxScore + Value * TokensScore.

% Pentru fiecare tag calculeaza scorul și îl alege pe cel cu scorul maxim.
% Dacă toate scorurile sunt 0 tag-ul va fi none.
% e.g:
% ?- get_emotion(memory{'joc fotbal': 2, 'joc box': 3}, Tag).
% Tag = sport.
get_tag(UserMemory, sport) :- get_tag_score(sport, UserMemory, SportScore), get_tag_score(film, UserMemory, FilmScore), 
				SportScore > FilmScore.
get_tag(UserMemory, film) :- get_tag_score(sport, UserMemory, SportScore), get_tag_score(film, UserMemory, FilmScore), 
				SportScore < FilmScore.
get_tag(UserMemory, none) :- get_tag_score(sport, UserMemory, SportScore), get_tag_score(film, UserMemory, FilmScore), 
				SportScore == FilmScore.
