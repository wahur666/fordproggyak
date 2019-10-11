# Fordítóprogramok gyakorlat


<!-- TOC -->

- [Megjegyzés](#megjegyzés)
- [Bison C++](#bison-c)
- [Példák](#példák)
    - [1. példa](#1-példa)
        - [Lexikai elemek tokenné alakítása](#lexikai-elemek-tokenné-alakítása)
        - [Tesztés](#tesztés)
        - [Automatizálás](#automatizálás)
    - [2. példa](#2-példa)
    - [2. példa hibakezeléssel](#2-példa-hibakezeléssel)
    - [3. példa](#3-példa)
    - [4. példa](#4-példa)

<!-- /TOC -->

<a id="markdown-megjegyzés" name="megjegyzés"></a>
## Megjegyzés

Ez a repo nem tartalmazza a forrás fájlokat, csak a szükséges instruckicókat ahhoz, hogy az egyetemi rendszeren meg tudjátok csinálni a feladatot.
Továbbá található itt még kettő Docker fájl, aki ismeri a technológiát, az tudja, hogy kell beüzemeltetni lokálban egy megfelelő környezetet.

---

<a id="markdown-bison-c" name="bison-c"></a>
## Bison C++

Ez az eszköz fogja felépíteni az Abstract Syntax Tree-t (AST). Gyakorlatban már tanul módon környezetfüggetlen grammatika segítségével megadott szabályokból fog fát építeni. Ha a fa minden leve terminális szimbólumot tartalmaz, és a forráskód végére értünk, akkor kapunk egy helyes programot. Ha a szintaxisfa nem tudott felépülni, akkor szintaktikus hibát észlelt a rendszer, azaz az adott forráskód nem felel meg a követleményünknek. 

<a id="markdown-példák" name="példák"></a>
## Példák

Példák elérhetők a következő linken a tanárúr weboldalán: [http://deva.web.elte.hu/fordprog/bisonc++.zip](http://deva.web.elte.hu/fordprog/bisonc++.zip).

<a id="markdown-1-példa" name="1-példa"></a>
### 1. példa

Forrás az 1/ mappában található. Lényege egy helyes lista felismerése.

Első lépésként nézzük meg milyen fájlok vannak a mappában. 

```
.
|-- Makefile
|-- Parser.h
|-- Parser.ih
|-- hibas.txt
|-- jo.txt
|-- lista.cc
|-- lista.l
`-- lista.y
```

A fájlok rendere a következők:

1. `Makefile`, a Make buildtool-hoz tartozó fájl, amiben különböző `target` cimkéket helyezünk el, amik egy-egy parancs sorozatot tartalmaznak. Annak érdekében, hogy ne írjunk minden egyes műveletre egy új Batch/Shell Scriptet ebben a fájlban lehet megadni azokat.

2. `Parser.h`, `Parser.ih`,  ezek generált fájlok a Bison C++ által, itt defeinicók szerepelnek, ahhoz, hogy a parser milyen függvényet fog tartalmazni. A függvények implementációja azért nincs jelen a mappában (még), mivel az attól függ milyen automata lesz generálva a forrás fájlból.

3. `jo.txt`, `rossz.txt`, ezek a teszt fájlok, nincs bennük semmi érdekes.

4. `lista.cc`, a belépési pontja a programnak

5. `lista.l`, a Flex lexikális elemző fájla, itt szereplnek REGEX-ek amik feldarabolják a forráskódot tokenekre. 

6. `lista.y`, Bison C++ fájla, itt vannak definiálva a nem terminális szimbólumok, és a hozzájuk tartozó tulajdonságok.

<a id="markdown-lexikai-elemek-tokenné-alakítása" name="lexikai-elemek-tokenné-alakítása"></a>
#### Lexikai elemek tokenné alakítása

Első beadandóban egyelen feladat az volt, hogy valami módon megtaláljuk a lexikai egyésgeket, és ha valami nem volt megfelelő akkor hibát jeleztünk.
Ez volt az első lépés, de annak érdekében, hogy tudjuk majd használni ezeket a lexikai elemeket, át kell alakítani őket tokenekké, amit a szintatkikus elemző fog tudni használni.

Nézzük meg a `lista.l` tartalmát:

```cpp
%option noyywrap c++

%{
#include "Parserbase.h"
%}

BETU        [a-zA-Z]
SZAMJEGY    [0-9]
WS      [ \t\n]

%%

({BETU}|{SZAMJEGY})+    return Parser::ELEM;
","         return Parser::VESSZO;
"["         return Parser::NYITO;
"]"         return Parser::CSUKO;

{WS}+   // feher szokozok: semmi teendo

. {
    std::cerr << "lexikalis hiba" << std::endl;
    exit(1);
}

%%

```

Mint látható, itt már nem `cout` szerepel, azaz nem a standard outputre kerül az adatunk, hanem a `Parser` osztály tokenjeit használja. Ez csak akkor működik, ha a következő rész szerepel a fájl elején.
```cpp
%{
#include "Parserbase.h"
%}
```

De felmerülehet a kérdés, hol is van ez a `Parserbase.h` fájl, mivel jelenleg nincs a fájlok között. Valóban, ez egy helyes felvetés, autómatikusan fog generálódni, majd az `.y` fájlból. 

Most nézzük meg mi is szereplen abban a `lista.y` nevű fájlban.

```hs
%baseclass-preinclude <iostream>

%token ELEM NYITO CSUKO VESSZO
%%

start:
	NYITO lista CSUKO
;

lista:
	// ures
|
	ELEM folytatas
;

folytatas:
	// ures
|
	VESSZO ELEM folytatas
;

```

Első sorában, egy include szerepel, ami majd jelez az Bison C++-nak, hogy az `<iostream>`-re szükség lesz, mint include.

Következő sorban található a `%token` itt kell felsorolni az összes tokent amit támogat a nyelvünk. Ezek lesznem a nem terminálisok amiből építhetjük majd a nyelvtanunkat.

**FONTOS**: Itt a nagybetűs szövegek jelentik a Terminális jeleket, és a kisbetűs szövegek a Nem Terminálist.

Utána következnek a produkciós szabályok. Aki látott már `goto`-t az más ismeretes a `label` fogalmával. Itt hasonló szintaktikával adjuk meg a szabályokat. Például a `start` szabály a következő:

```hs
start:
	NYITO lista CSUKO
;
```

A `start` definiálja a start szimbólumot, és ez nagyon fontos, mivel ez lesz az első szabály amit használni fog a AST építéséhez. 
Eztán követi őket a produkációs szabályok. Esetünkben ez lesz a `NYITO` terminális, `lista` nem terminális, majd végül a `CSUKO` terminális. Mikor már nincs több szabályunk az adott nem terminálishoz, MINDIG le kell zárni egy pontosvesszővel ( `;` ) a szabályt.

A következő szabályt nézzük meg, `lista`:

```hs
lista:
	// ures
|
	ELEM folytatas
;
```

A `listá`hoz két szabály tartozik. Először az üres, azaz az Epszilon szabály, majd az `ELEM` terminális, és a `folytatas` nem terminális.

A fenti nyelvtan a következő nyelvet írja le formailag:

```
start       -> ( lista )

lista       -> epszilon | ELEM folytatas

folytatas   -> epszilon | , ELEM folytatas
```

avagy a gyakorlati példában szerepelt órán:

```

S -> ( A )

A -> epszilon | azon B

B -> epszilon | , azon B
```

Ahhoz, hogy ezeket a szabályokat használni is tudjuk, C++ kódot kell készítenünk.
A `Makefile` tartalmazza az összes szükséges parancsot, de annak érdekében, hogy lássátok nincs semmi csalás az egész mögött, a követező parancsoakt kell kiadni ahhoz, hogy leforduljon:

1. Flex `.l` fájlt leforítani, ezzel létrejön a `lex.yy.cc` fájl.

```
flex lista.l
```

2. A Bison `.y` fájlt lefordítani, ezzel létrejön a `ParserBase.h` fájl és a `parser.cc` ami tartalmazza természetesen az implementációt. A `ParserBase.h` tarlamazza a tokeneket és a függvények definicióit, a `parse.cc` meg levezetési szabályokat, olvasható és felismerhő formában, helyeken.

```
bisonc++ lista.y
```

3. Az összes fájl összefordítása egy futtatható álománnyá. Létrejön a `lista` nevű futtatható állomány.

```
g++ -o lista lista.cc parse.cc lex.yy.cc
```

<a id="markdown-tesztés" name="tesztés"></a>
#### Tesztés

A tesztek futtatása a következő módon törénik:

```
./lista jo.txt
```

és 

```
./lista hibas.txt
```

Az első kimenete semmi, mivel helyes volt a fájl, még a rossz kimenete az hogy `Syntax error`. Ami valóban helyes, mivel a `hibas.txt` tartalma a következő: 

```
[ alma, barack, 42 szilva ]
```

Látható, hogy egy vessző kimaradt a `42` és a `szilva` között.


<a id="markdown-automatizálás" name="automatizálás"></a>
#### Automatizálás

Annak érdekében, hogy ne kelljen minden egyes alkalommal kézzel összefordítani mindent ezért rendelkézsünkre áll a `Makefile`.

Fordítás: `make all`

Tisztítás: `make clean` , generált fájlokat kitörlni. `Parser.h`, `Parser.ih` megmaradnak!

<a id="markdown-2-példa" name="2-példa"></a>
### 2. példa

Adjuk meg a helyes C stílusú függvény definiciót.

A fenti leírás alapján át lehet menni az elemzésen. Az érdekes fájl számunkra itt továbbra is a `.y` fájl. Tartalma pedig:

``` hs
start:
	deklaracioLista
;

deklaracioLista:
	// ures
|
	deklaracio deklaracioLista
;

deklaracio:
	AZONOSITO AZONOSITO parameterek PONTOSVESSZO
;

parameterek:
	NYITO lista CSUKO
;

lista:
	// ures
|
	AZONOSITO AZONOSITO folytatas
;

folytatas:
	// ures
|
	VESSZO AZONOSITO AZONOSITO folytatas
;

```

Ezt felírva formálisan, a következő szabályokat adja:

```hs
start           -> deklaracioLista

deklaracioLista -> epszilon | deklaracio deklaracioLista

deklaracio      -> AZONOSITO AZONOSITO parameterek PONTOSVESSZO

parameterek     -> NYITO lista CSUKO

lista           -> epszilon | AZONOSITO AZONOSITO folytatas

folytatas       -> epszilon | VESSZO AZONOSITO AZONOSITO folytatas

```

Ettől egyszerűbben megoldottuk órán, de most példa céljából ez is helyes megoldás.

<a id="markdown-2-példa-hibakezeléssel" name="2-példa-hibakezeléssel"></a>
### 2. példa hibakezeléssel

Felmerülhet az igény arra, hogy értelmes hibaüzeneteket írjunk ki a felhasználónak, (embere válogatja, én nem ítélkezek), ekkor valahogy jelezni kellene, hol is merült fel.

A példa megegyezik az előzővel, a lényegi különbség itt van:

```hs
deklaracio:
	AZONOSITO AZONOSITO parameterek PONTOSVESSZO
|
	error PONTOSVESSZO
	{
		std::cerr << "\t- hibas deklaracio"  << std::endl;
	}
;

parameterek:
	NYITO lista CSUKO
|
	NYITO error CSUKO
	{
		std::cerr << "\t- hiba a parameterlistaban"  << std::endl;
	}
;
```

Felveszünk egy `error` szabályt, amit majd a Bison C++ fog elintézni nekünk, hogy felismerje, és itt megadhatjuk azt, hogy milyen hibaüznetet adjuk vissza a felhasználónak. Mint a lexikális elemzőnél lehet blokkot ( `{ }` ) használni arra, hogy C++ kódot írjunk a megfelelő helyre. Mikor odaér a vezérlés, akkor lefut a kódunk.

<a id="markdown-3-példa" name="3-példa"></a>
### 3. példa

A helyez zárójelezés példája, amit megoldottunk és levezettem táblán legelőször órán. A hozzá tartozó `.y` kód pedig a következő:


```hs
%baseclass-preinclude <iostream>

%token SKIP KEZDET VEG
%%

start:
	program
;

program:
	// ures
|
	SKIP program
|
	blokk program
;

blokk:
	KEZDET program VEG
;
```

<a id="markdown-4-példa" name="4-példa"></a>
### 4. példa

Ezt már nem vettük át órán, és itt megjelenik egy új konstrukció a `.y` fájlban. Nézzük meg a kódot:

```hs
%baseclass-preinclude <iostream>

%token IGAZ HAMIS NYITO CSUKO AZONOSITO
%right EKV
%right IMPL
%left VAGY
%left ES
%right NEM

%%

start:
	formula
;

formula:
	IGAZ
|
	HAMIS
|
	AZONOSITO
|
	NYITO formula CSUKO
|
	formula EKV formula
|
	formula IMPL formula
|
	formula VAGY formula
|
	formula ES formula
|
	NEM formula
;

```

Vegyük szemügyre a fájl legelejét, mivel ott van jelentős változás:

```hs
%token IGAZ HAMIS NYITO CSUKO AZONOSITO
%right EKV
%right IMPL
%left VAGY
%left ES
%right NEM
```

Definiáltunk a tokeneinket, de megjelennek precedencia szabályok és kötési oldal. Vegyük észre, a `%token` nem tartalmazza az alatta felsorolt szabályokat. Ez nagyon fontos az egyértelműség szempontjából. Nem definiálhatunk egy `tokent` készter!

Lentről felfelé csökken a precedencia a jelekre. Erre egy példa a logikai `NEM`. A `NEM` művletet kell előbb elvégezni, mielőtt bármi más műveletet alkalmaznánk. Köztudott tény, hogy az `ES` erősebben köt mint a `VAGY`, és ez itt meg is jelenik a kódban, előbb van a `VAGY` majd utána az `ES`.

Továbbá kell adni egy műveleti sorrendet is, erre lesz segítségünkre a `%right`, `%left` műveltek. Mint a nevük is mondja, jobbra és balra való kötést fejeznek ki.

