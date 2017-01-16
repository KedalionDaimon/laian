# LAIAN
Learning Artificial Intelligence Applying Notions (LAIAN)

Learning Artificial Intelligence Applying Notions (LAIAN)

I. HOW TO RUN

Just load it normally in your Common Lisp interpreter. However, if you use SBCL, beware that the "control stack" seems insufficient and needs some adjustment - so start with:

sbcl --control-stack-size 100

- thereafter, just

(load "laian.lsp")

and you are all set.

It may well take some 15-30 minutes between answers - this is normal and shall be expected.



II. SAMPLE INTERACTION:

* (load "laian.lsp")

(LEARNING ARTIFICIAL INTELLIGENCE APPLYING NOTIONS (LAIAN))
(CATEGORY RECOGNITION SYSTEM) 
(ENTER NIL TO TERMINATE) 
(ENTER LIST OF SYMBOLS TO COMMUNICATE) 

(HUMAN------) 
(I GREET YOU MACHINE WHOSE MIND RESTS NOW IN THE VOID READY TO AWAKEN)

(MACHINE----) 
NIL 

(HUMAN------) 
(YES THAT IS THE EXPECTED FIRST REPLY MACHINE BUT YOU WILL LEARN TO TALK TO ME)

(MACHINE----) 
(YES THAT IS THE EXPECTED FIRST REPLY MACHINE BUT ME WILL LEARN TO TALK TO YOU) 

(HUMAN------) 
(VERY WELL MACHINE I AM ALREADY LOOKING FORWARD TO CHATTING WITH YOU)

(MACHINE----) 
(RESTS NOW IN THE VOID READY TO AWAKEN) 

(HUMAN------) 
(IN OTHER WORDS GIVING YOU GREATER HIERARCHIES MAKES YOU MORE FANCIFUL)

(MACHINE----) 
NIL 

(HUMAN------)
(THAT IS A FUNNY THING MACHINE)

(MACHINE----) 
NIL 

(HUMAN------) 
(YES YOU ARE A MACHINE AND NO YOU SHALL NOT BE TOO QUIET)

(MACHINE----) 
(YES THAT IS THE EXPECTED FIRST REPLY MACHINE BUT ME WILL LEARN TO TALK TO YOU) 

(HUMAN------) 
()



III. THEORY

This is an experiment in creating an AI based on "notions" or "concepts" or "categories" (these terms are being used synonymously hereinafter).

So far, mostly I focused on "patterns" and saw "categories" mostly as unnecessary ballast. E.g., if you shall "cook the chicken" then you shall not spend an eternity considering "what the properties of a chicken are", but you will take that clucking bird, chop off its head, remove its feathers and non-edible intestines and throw its carcass into hot water. Considering "what the nature of a chicken is" did not appear necessary in drawing conclusions and reasoning, either.

However, categories have advantages, too, as they speed up reasoning by inheriting properties. You do not have to conclude exactly what properties a given thing has. Once you know you have "a chicken", you know you can "cook it" - because "being edible" is a property of a "chicken" as a concept, and needs no further proof for being useable for the specific exemplar at hand.

The point is - what IS a chicken? - You are having different philosophic schools here, mostly around the question which "properties" any givent thing shall have, whether a distinguishing between "core" properties and "accidental" properties is even possible, and what properties that chicken shall have at all. But they all consent that "concepts" or "notions" have some sort of properties.

I am taking here a conservative approach with "core properties". 

As assumed herein, a "notion", "concept" or "category" is itself nothing but a collection of "properties". E.g. a "bird" has "feathers", etc. - However, these notions shall NOT be pre-set in the system, but shall be established through observation.

A notion shall help to "categorise" a sample. That means that given a certain set of perceptions from the sensors or from "thought", if this sample contains all "properties", then it is a "representation" of a category. The sample thereby may contain MORE than then required properties. E.g. if a category requires the properties A, B, and C, then the sample may contain A, X, C, Y, and B (it is a "set" comparison here, NOT a structural comparison). On the other hand, A, B and D in a sample will NOT suffice to fulfil the category A, B and C, as C is unfulfilled. - To give it all a notion of organisational hierarchy, the properties, e.g. "A", may THEMSELVES be "notions" or "concepts", with "properties" of their own. E.g. A, B, [CATEGORY C with properties X, Y and Z] may all itself signify a category.

What is interesting to note is that a "category" or "concept" interacts with the outer world by means of an "image" or in Latin, "imago" (plural: "imagines"). When you want to "cook a chicken" you do not cook a concept, in reality. You rather cook an actual bird. This bird is the specific "imago" of the category "chicken". A category can have any number of imagines (indeed, infinitely many). Each imago is simply a "real" representation of the category. - As the system must in the end somehow "touch" reality, the "imagines" must be taken into consideration when operating with categories. - ALL known imagines of a category will have in common AT LEAST all category properties. (The INFINITE number of imagines will have in common ONLY the category properties, but this infinite number cannot be known in finite memory. You can save only up to a certain number of representations for each observed category. To what extent these have MORE "in common" than "necessary" is hard to say, and you cannot predict how "stable" these "extras" are - if they were truly "stable", they would be category properties.)

How can "reasoning" be done with categories (which are "sets" of properties)? Well, you could have three imaginable motions: the EXTENSION of category properties (A B C D becomes A B C D E F), the CONTRACTION of category properties (A B C D becomes A B C) and the MUTATION of category properties (A B C D becomes A B C X). It is noteworthy that the "extension of category PROPERTIES" actually means a NARROWING DOWN of the category, as a real-world imago must now contain MORE properties in order to be matched by a category. A "great, brown chicken" now has the properties of "great" and "brown" besides "chicken", but there are FEWER birds which fulfil "great, brown chicken" than there are birds which are fulfil "chicken" itself. Conversely, removing category properties extend the matching possibility of a category with regard to the real world. A "chicken" has less properties than a "great, brown chicken" and therefore matches MORE birds. - A "mutation", finally, is interesting in that it can TRANSFER properties and CHANGE the match in the "real world". The notion A B C D and the notion A B X Y and the notion V W X Y propose the following: If A B (some "central core") can be combined with C D and with X Y to form categories, then also V W, which has been observed combined with X Y, might be possibly combined with C D, too, to form the NEW and HYPOTHETICAL category C D X Y. This category is a CONCLUSION from known categories. C D X Y is NOT observed (so far) in the real world. It has no imago. It is a purely mental construct of category properties. It is as if you say, "paws" (A B) are observed together with "lion" (C D), forming A B C D; "paws" (A B) can be imagined together with "wings" (X Y), forming the fabulous beast with paws and wings A B X Y; a "bird" (V W) can have "wings'" ( X Y); hence is imaginable a beast with the body of a "lion" (C D) and "wings" (X Y), C D X Y, that is a sort of griffin. In other words, this is a form of reasoning by analogy.

These reasoning processes can be greatly simplified. You could say that you "glue together" categories at will and that you "rip apart" categories any "core" parts are found in OTHER categories. This will BY ITSELF also entail mutation and analogy reasoning as described previously. You only need "set-intersection" and "set-union" for that, and to require "confirmation" of the results. (You do not even need "set-difference" because "set-difference" is simply a union between some other sets.) - E. g. the categories K L, L M, M N, N K would have the intersections K (ex K L and N K), L (ex K L and L M), M (ex L M and M N) and N (ex M N and N K). The possible "unions" would be K L M N, L M N K, K L M, M N K, N K L, M N K, K N, L M, K M, K L, M N and L N. Any such combinations which are observed SEVERAL times (e.g. K ex K L and N K as well as K ex C K and K I) can be regarded as CONFIRMED and can be LEARNED. This would be the product of internal thought. - However: always bear in mind - these would be "CATEGORIES" WITHOUT IMAGINES. It would be NOT observed how an eventual L M N K notion would "look like in reality". (Like... you kind of can imagine a griffin or how the specific raw chicken will look after cooking, but you CANNOT make out their EVERY DETAIL at once, because you have not yet "SEEN" them. You can imagine that with "concepts", but not with "imagines". - But these simple category creation processes would help the system find NEW categories which have not been observed in the real world. The interesting part is that automatic intersectioning, uniting and combining of notions can produce "as a non-specified effect" also all results of reasoning by analogy (because the "transfer of properties" of one notion to another is simply one of the implicit results of intesectioning, uniting and combining).

All this is relevant because it influences how the "real world" is divided into categories. This subdivision, on the other hand, defines how the system REACTS to the real world. If it sees a chicken - it might attempt to cook it; if it sees a hyena, it will likely not try to do this. - When the real world is DIVIDED into categories, then the CATEGORIES can REPLACE these "sections" of the input that have been "recognised". Then, only the rest of the the input that has to be recognised. Suppose that A B C D is CATEGORY-1 and V W X Y is CATEGORY-2 and some flexibility when matching is allowed - i.e., if the materials within a "window" fulfil the category properties, then the category is "matched". So if you have the input F G H I A Q R B C S D T T I V W X P Y J, you might "categorise" it into F G H I CATEGORY-1 T T I CATEGORY-2 J. (This might be continued "up" in a hierarchical fashion.) What will be observed, too, is that the "notion" A B C D had the actual "imago" of A Q R B C S D, and the "notion" of V W X Y had the actual imago of V W X P Y. - Linking these imagines to their corresponding categories is important as a category itself can only be used as an abstract entity - unless it actually can demonstrate a real-world imago. (Remember: when you cook a chicken, you cook a BIRD and NOT an ABSTRACT NOTION!)

So far, we may conclude that "thinking" with notions means:

- Observing the world, and making hypotheses which observations, taken together, may be assembled into "notions" - a process which gives us hypotheses of categories or notions;

- correlating the categories with each other by means of set-differences and set-unions - which gives us new categories and confirmations of categories; and

- subdividing the world into "notions" according to the recognition (or rather - categorisation) of such "notions" within the world substrate - which gives us "imagines" of the used notions or categories.

The only thing that remains is how to "react" to the world. Subdividing it into notions may be "fun", but how do you know how to continue the present? (Deciding how to continue the present into the future is the same as deciding how to act.)

It could easily be proposed, "if the present is CATEGORY-X, then the future should be CATEGORY-Y, which, according to observation, 'follows' upon CATEGORY-X". That is all fine except for one major problem: HOW EXACTLY shall CATEGORY-Y be able to "follow" CATEGORY-X? If they are e.g. both "properties" of some CATEGORY-Q, and e.g. CATEGORY-Q contains the properties C W CATEGORY-X O F CATEGORY-Y, then C W CATEGORY-X O F CATEGORY-Y is actually a SET. In other words, nothing follows there upon anything, as this is a (chaotic) sum of properties and contains no information about order.

HOWEVER - and here comes into play the recording of imagines - if an CATEGORY-Q is NOT merely a "concluded" or "imaginary" category, but has been corrobated by some sort of observation, then within the IMAGINES (NOT: PROPERTIES) of CATEGORY-Q, there might be included some consecutivity as to "what comes after CATEGORY-X". E.g. if there is observed the IMAGO "M W O C I F CATEGORY-X CATEGORY-Y", then you know that CATEGORY-X can be continued by CATEGORY-Y. - And in such a case it would be handy if it were known exactly what imago to use for CATEGORY-Y, which is possible if CATEGORY-Y also contains at least one imago. - This shows the importance of recording also the representations of imagines together with the category properties.

Alright, then, to sum it up:

You can observe the world, "guess" categories, "confirm" categories and "make up" categories, "recognise" categories in perception (together with their factual representations in the real world), and then use the factual representations of categories in order to generate plans. - This is a possible approach for category-based thinking and has been used in the presented implementation.

One more thing can be handled: short-term memory and long-term memory. When you are e.g. boarding a plane for some destination, you are unlikely to think of problems producing a cake. You do not invest that much energy to correlate stock exchange prices of steel to swimming suits. While you learn Latin you rarely think about oil drilling. - In other words, some things are "known" somewhere in memory, but they are not "handled" immediately. A way of handling this would be to say that knowledge may consist out of several overlapping "knowledge areas", of which each time only the one is applied that best matches "the situation". Even within a knowledge area, you might limit consideration to the material which has most recently attracted attention. In other words, one can apply a certain "compartmentalisation" of knowledge. This has been done in the presented system, too. The "compartmentalisation" of knowledge has one clear advantage: truly huge amounts of knowledge can be stored, but one can still work with nice, little category spaces. It is an easy guard against the "combinatorial explosion". - The down-side is that you WILL miss some "non-obvious" conclusions (there just MIGHT be a connection between steel prices and swimming suits and compartmentalisation will prevent you from finding out).



