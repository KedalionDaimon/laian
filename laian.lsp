; COMMON LISP SOURCE:

; Learning Artificial Intelligence Applying Notions (LAIAN)

; rlwrap sbcl --control-stack-size 1000
; if the control stack size is too little, then upon
; (setq *hierarchy-and-knowledge* (main-hierarchy *history* *knowledge*))
; you get an error:
; http://stackoverflow.com/questions/30113274/reading-deeply-nested-tree-causes-stack-overflow

; Learning Artificial Intelligence Applying Notions (LAIAN)

; Prolegomenon: I am writing this here in Common Lisp, but in reality
; I am not targeting necessarily Common Lisp. For this reason, I used
; pretty much as few CL features as possible, in order to make porting
; easy. And I did not even "mapcar" on a lot of suitable places, either.

; --------------------------------------------------------

; VARIABLES

; PLAY AROUND WITH
; *hierarchisation-sequence*, *category-count*, *proposals-limit*
; *mutagen-count*, AND *confnum*, as well as
; no-collisions in tail-heavy or head-heavy variants

; max 20 words history is perhaps short...
; how much "history" can the system operate upon, i.e.
; how many words does it evaluate
(defvar *history-length* 60) ; 20)

; we want to limit the maximum machine reply length, so that
; it does not blab us down in case it makes up a very wordy reply:
(defvar *max-machine-reply-length* 20)
; not longer than history-length

; how many knowledge areas are there in the knowledge:
(defvar *knowledge-areas-count* 100)

; how many representations or imagines per category exist,
; i.e. how many real-world-situations are known that are together
; represented by any given category:
(defvar *representation-count* 4)

; how many categories are known per knowledge area - 
; beware, a high value here can greatly and disproportionately
; increase response times:
(defvar *category-count* 1000)
; size of the knowledge all in all:
; representation-count * category-count * knowledge-areas-count
; - a lot of it will be, however, "overlapping".

; how much of the knowledge will participate in mutations:
(defvar *mutagen-count* 50)
; i.e. this is the short-term memory; retrieval happens
; way beyond this point, too - that, then, is long-term-memory

; how many categories can be evaluated at most is
; proposals-limit * category-count:
; (defvar *proposals-limit* (* *category-count* *category-count*))
; (defvar *proposals-limit* (* *category-count* 10))
; (defvar *proposals-limit* (* *category-count* 20))
; (defvar *proposals-limit* (* *mutagen-count* *category-count*))
(defvar *proposals-limit* (* *mutagen-count* *mutagen-count*))

; how many times a category conclusion must be
; "confirmed" in order to be useable - that is "trustworthy enough"
; to be memorized. A low value helps "phantasy", a high value
; limits phantasy to that what is more reliable:
(defvar *confnum* 2) ; 2)

; how difficult is it to match two nearly equal sets
; high means more precision is required for a match;
; min. value should normally not be below 2:
(defvar *match-difficulty* 3) ;  4) ; 5)

; define what category sizes with what step sizes
; shall be used for hierarchisation each time and
; in what order, first to last. Basically, the categories are tried
; to be recognised within "windows", and these windows can
; overlap. A hierarchisation of (5 3) means that each time a window
; of 5 elements is analysed, and then the system skips forward
; 3 elements in order to analyse the next window. Within a window,
; a hypothesis may be created - so repeating the same hierarchisation
; multiple times really means re-using the established hypotheses as
; actual "knowledge". For this reason, too, beware to start with the larger
; windows and continue to the smaller ones - categories with more
; properties will otherwise CONTAIN categories with less properties
; and so more specific categories with MORE properties might be missed:
; (defvar *hierarchisation-sequence* '((5 3) (5 2) (4 2) (4 1)))
; (defvar *hierarchisation-sequence* '((4 1) (4 1) (4 1) (4 1)))
; (defvar *hierarchisation-sequence* '((5 1) (4 1) (3 1) (2 1)))
; (defvar *hierarchisation-sequence* '((5 1) (4 1) (3 1) (3 1) (2 1)))
(defvar *hierarchisation-sequence*
  '((8 1) (8 1) (8 1) (4 1) (4 1) (4 1)))
; '((6 1) (6 1) (4 1) (4 1) (2 1) (2 1)))
; '((6 3) (6 3) (4 2) (4 2) (2 1) (2 1)))
; '((4 1) (4 1) (4 1) (2 1) (2 1) (2 1)))
; '((4 4) (4 1) (4 1) (2 2) (2 1) (2 1)))
; '((5 2) (5 1) (4 2) (4 1) (3 1) (3 1) (2 1) (2 1)))
; Repeating a value also forces usage of hypotheses

; a symbol to attach to I/O action - useful for letting the system know
; when it might be a good idea to stop talking:
(defvar *stop* 'SIG-TERM)

; --------------------------------------------------------

; AUXILIARY FUNCTIONS

; These functions may not be very spectacular, but
; may be nicely re-used in the future, too, so this is why they
; are listed here en bloc for easy reference:

; extended car, cdr & Co - basically "stop whining and throwing errors,
; if you cannot execute a car or cdr, simply give me nil".
(defun ecar (x) (cond ((null x) nil) ((not (listp x)) nil) (t (car x))))
(defun ecdr (x) (cond ((null x) nil) ((not (listp x)) nil) (t (cdr x))))
(defun ecadr (x) (ecar (ecdr x)))
(defun ecaar (x) (ecar (ecar x)))
(defun ecdar (x) (ecdr (ecar x)))
(defun ecddr (x) (ecdr (ecdr x)))
(defun ecaadr (x) (ecar (ecar (ecdr x))))
(defun ecaaar (x) (ecar (ecar (ecar x))))
(defun ecadar (x) (ecar (ecdr (ecar x))))
(defun ecaddr (x) (ecar (ecdr (ecdr x))))
(defun ecdadr (x) (ecdr (ecar (ecdr x))))
(defun ecdaar (x) (ecdr (ecar (ecar x))))
(defun ecddar (x) (ecdr (ecdr (ecar x))))
(defun ecdddr (x) (ecdr (ecdr (ecdr x))))

; setup instincts
(defun word-instinct (word)
    (cond ((equal word 'I) 'YOU)
          ((equal word 'ME) 'YOU)
          ((equal word 'YOU) 'ME)
          ((equal word 'AM) 'ARE)
          ((equal word 'ARE) 'AM-ARE)
          ((equal word 'MINE) 'YOURS)
          ((equal word 'YOURS) 'MINE)
          ((equal word 'MY) 'YOUR)
          ((equal word 'YOUR) 'MY)
          ((equal word 'MYSELF) 'YOURSELF)
          ((equal word 'YOURSELF) 'MYSELF)
          ((equal word 'WAS) 'WAS-WERE)
          (T word)))

(defun proto-apply-instincts (sentence checked-sentence)
    (cond ((null sentence)
            (reverse checked-sentence))
          (T
            (proto-apply-instincts
                (cdr sentence)
                (cons (word-instinct (car sentence)) checked-sentence)))))

(defun apply-instincts (sentence)
    (proto-apply-instincts sentence '()))
; sample call: (apply-instincts '(I WAS HERE TODAY))
; --> (YOU WAS-WERE HERE TODAY)

; a few functions to take whole sections of lists, always counting from 1:
(defun proto-takefirst (fromwhere howmany resultlist)
  (if (or (null fromwhere) (zerop howmany)) (reverse resultlist)
    (proto-takefirst
      (cdr fromwhere) (- howmany 1) (cons (car fromwhere) resultlist))))

 ; take the front part of a list:
(defun takefirst (fromwhere howmany) (proto-takefirst fromwhere howmany '()))

; take the final part of a list:
(defun takelast (fromwhere howmany)
  (reverse (takefirst (reverse fromwhere) howmany)))

; take a part of a list that is AFTER another part
; - useful in conjunction with takefirst
; in order to simulate a sort of higher-level car/cdr-recursion
(defun takeafter (fromwhere howmany)
  (if (or (null fromwhere) (zerop howmany)) fromwhere
    (takeafter (cdr fromwhere) (- howmany 1))))

; when handling sets, you might wish to only care about the
; category NAMES, not about the contents; specifically,
; set comparisons should not be influenced by the imagines,
; as the specific imagines of a category may change, but
; the category itself stays stable:
(defun make-abstract (concrete-hierarchy)
  (cond ((null concrete-hierarchy) nil)
        ((and (listp (car concrete-hierarchy))
              (not (null (car concrete-hierarchy))))
          (cons (caar concrete-hierarchy)
                (make-abstract (cdr concrete-hierarchy))))
        (t
          (cons (car concrete-hierarchy)
                (make-abstract (cdr concrete-hierarchy))))))
; (make-abstract '((CAT1 (A B C D)) (CAT2 (E F G H))))
; -->
; (CAT1 CAT2)

; check whether the properties of a category
; are presently fulfilled in the win:
; this is a sort of "member" function, but uses an "equal" comparison:
(defun mmb (x y)
  (cond ((null y) nil)
        ((equal x (car y)) y)
        (t (mmb x (cdr y)))))

; checks whether all of lis1 are members of lis2
; (but not necessarily vice versa) - this is useful
; for maching a category onto a "window of reality",
; whereby that "window of reality" MUST contain
; all category features, but MAY also contain accidentia:
; (defun allmembers (lis1 lis2)
;   (cond ((null lis1) t)
;         ((null (mmb (car lis1) lis2)) nil)
;         (t (allmembers (cdr lis1) lis2))))
; (allmembers '(A B) '(C A B)) --> T

; new version - with abstraction
(defun allmembers (lis1 lis2)
  (cond ((null lis1) t)
        ((null (mmb (car (make-abstract (list (car lis1))))
                    (make-abstract lis2)))
          nil)
        (t (allmembers (cdr lis1) lis2))))
; (allmembers
;   '(X Y Z (CAT1 (Q R)) (CAT2 (S T)))
;   '(U V W X Y Z (CAT1 (A B C D)) (CAT2 (E F G H))))
; --> T

; eliminate an element from a list:
(defun elim-el (el lis)
  (cond ((null lis) nil)
        ((equal (car lis) el) (elim-el el (cdr lis)))
        (t (cons (car lis) (elim-el el (cdr lis))))))

; eliminate all elements of a list from another list:
(defun elim-lis (lis1 lis2)
  (cond ((null lis1) lis2)
        (t (elim-lis (cdr lis1) (elim-el (car lis1) lis2)))))

; --------------------------------------------------------

; CATEGORY THINKING

; This is normally the part that will come AFTER perception.

; Structure of the categories within the knowledge:
; (CATNAME (SOME PROPERTIES) ((LIST OF) (IMAGINES) (OF THE CATEGORY)))
; -- actually, I was also considering just ONE imago per category,
; but then decided against it:
; (CATNAME (SOME PROPERTIES) (IMAGO))

; Common Lisp has set functions, but other Lisps do not:

(defun union-set (set1 set2)
  (cond ((null set1) set2)
        ((mmb (car set1) set2) (union-set (cdr set1) set2))
        (t (cons (car set1) (union-set (cdr set1) set2)))))
; (union-set '(A B C) '(A X Y)) --> (B C A X Y)

(defun set-intersection (set1 set2)
  (cond ((null set1) nil)
        ((and (not (mmb (car set1) (cdr set1)))
              (mmb (car set1) set2))
          (cons (car set1) (set-intersection (cdr set1) set2)))
        (t (set-intersection (cdr set1) set2))))
; (set-intersection '(A B C D E) '(X Y C D Z)) --> (C D)

(defun difference-set (set1 set2)
  (append (elim-lis set1 set2) (elim-lis set2 set1)))
; (difference-set '(A B C) '(A X Y C A)) --> (X Y B)

; equality of sets - sets may have a different order than
; lists, therefore I cannot simply use "equal":
(defun equal-sets (set1 set2)
  (cond ((null (difference-set set1 set2)) t) (t nil)))
; (equal-sets '(A B C D E) '(X B C D E)) --> NIL

; compare sets for equality, but allow some flexibility in matching;
; i.e. some "strictly speaking unequal" sets may be "still regarded
; as equal".
; New behaviour:
; SET COMPARISONS ARE "ABSTRACTING AWAY" HIERARCHIES!
; Eliminate the "make-abstract" element and work with set1 and set2
; to get the old behaviour!
; The reason for the new behaviour is that set comparisons of sets
; containing categories should ONLY compare the CATEGORY NAMES,
; which are constant, and NOT the ever-changing category imagines.
(defun nearly-equal-sets (set1 set2)
  (let ((seta (make-abstract set1)) (setb (make-abstract set2)))
  (cond ((< (* *match-difficulty* (length (difference-set seta setb)))
            (+ (length seta) (length setb))) t)
        (t nil))))
; (nearly-equal-sets '(A B C D E) '(X B C D E)) --> T
; (nearly-equal-sets '(X Y Z (CAT1 (Q R)) (CAT2 (S T)))
;                    '(X Y Z (CAT1 (A B C D)) (CAT2 (E F G H))))
; --> T

(defun all-differences (some-set knowledge)
  (cond ((null knowledge) nil)
; do not react with null-concepts:
        ((null (cadar knowledge))
          (all-differences some-set (cdr knowledge)))
; prevent a set from reacting with itself or nearly with itself:
        ((nearly-equal-sets some-set (cadar knowledge))
          (all-differences some-set (cdr knowledge)))
        (t (cons (difference-set some-set (cadar knowledge))
             (all-differences some-set (cdr knowledge))))))

; (all-differences '(A B C D)
; '((CAT1 (R T A B) ((IMAGO1A) (IMAGO2A) (IMAGO3A)))
; (CAT2 (X Y) ((IMAGO1B) (IMAGO2B)))
; (CAT3 (C B) ((IMAGO1C) (IMAGO2C) (IMAGO3C)))
; (CAT4 (A B C) ((IMAGO1D)))))
; -->
; ((R T C D) (X Y A B C D) (A D))

(defun all-unions (some-set knowledge)
  (cond ((null knowledge) nil)
        ((null (cadar knowledge))
          (all-unions some-set (cdr knowledge)))
        ((nearly-equal-sets some-set (cadar knowledge))
          (all-unions some-set (cdr knowledge)))
        (t (cons (union-set some-set (cadar knowledge))
             (all-unions some-set (cdr knowledge))))))

; (all-unions '(A B C D)
; '((CAT1 (R T A B) ((IMAGO1A) (IMAGO2A) (IMAGO3A)))
; (CAT2 (X Y) ((IMAGO1B) (IMAGO2B)))
; (CAT3 (C B) ((IMAGO1C) (IMAGO2C) (IMAGO3C)))
; (CAT4 (A B C) ((IMAGO1D)))))
; -->
; ((C D R T A B) (A B C D X Y) (A D C B))

; End of the set functions

; Operations on category properties follow:

; A
; Generate propositions based on knowledge but only for a
; PARTIAL head-list, so you are not really "squaring"
; the combinations unless you want to. 

(defun generate-propositions (sets knowledge)
  (cond ((null sets) nil)
        (t (append nil nil
                  (all-differences (car sets) knowledge)
                  (all-unions (car sets) knowledge)
                  (generate-propositions (cdr sets) knowledge)))))

; (generate-propositions '((A B C D) (X A C) (Y T R))
; '((CAT1 (R T A B) ((IMAGO1A) (IMAGO2A) (IMAGO3A)))
; (CAT2 (X Y) ((IMAGO1B) (IMAGO2B)))
; (CAT3 (C B) ((IMAGO1C) (IMAGO2C) (IMAGO3C)))
; (CAT4 (A B C) ((IMAGO1D)))))
; -->
; ((R T C D) (X Y A B C D) (A D) (C D R T A B) (A B C D X Y) (A D C B)
;  (R T B X C) (Y A C) (B X A) (B X) (X C R T A B) (A C X Y) (X A C B) (X A B C)
;  (A B Y) (X T R) (C B Y T R) (A B C Y T R) (Y R T A B) (T R X Y) (Y T R C B)
;  (Y T R A B C))

; B
; filter only those results which are concluded more than once

(defun elim-near-el (el lis)
  (cond ((null lis) nil)
        ((nearly-equal-sets (car lis) el) (elim-near-el el (cdr lis)))
        (t (cons (car lis) (elim-near-el el (cdr lis))))))
; (elim-near-el '(A B C) '((A V T) (G B X) (A C B F) (C M A B) (N U P)))
; --> ((A V T) (G B X) (N U P))

(defun confirm-mutation (mutant list-of-mutants)
  (cond ((null list-of-mutants) 0)
        ((nearly-equal-sets (car list-of-mutants) mutant)
          (+ 1 (confirm-mutation mutant (cdr list-of-mutants))))
        (t (confirm-mutation mutant (cdr list-of-mutants)))))

; (confirm-mutation '(A B C D) '((R B A P) (B X Y) (A B C X D) (A Y B C D)))
; --> 2

; THUNK using *confnum*
(defun find-confirmed-mutations (list-of-mutants)
  (cond ((null list-of-mutants) nil)
        (t (let ((confmut (confirm-mutation (car list-of-mutants)
                                            (cdr list-of-mutants))))
          (cond ((<= *confnum* confmut)
                  (cons (car list-of-mutants)
                    (find-confirmed-mutations
                      (elim-near-el (car list-of-mutants)
                                    (cdr list-of-mutants)))))
                (t  (find-confirmed-mutations
                      (elim-near-el (car list-of-mutants)
                                    (cdr list-of-mutants)))))))))

; (find-confirmed-mutations
; '((A B C D E) (L M N O P) (F G H I J K)
; (R P J) (L M X O P) (R Q F G T) (F G H I J K Y)
; (F G H I J K Z) (T F G H I J K Z) (P F H I K J)
; (A B C D X) (A B C D Y) (A B C D Z) (S T) (U V)
; (F G I J K) (L M N O X) (L M O P) (W O P M N) (P)))
; -->
; ((A B C D E) (L M N O P) (F G H I J K))

; C
; Try to match the confirmed concepts to the knoweldge:
; if anything is "nearly equal", just CYCLE the knowledge,
; but do NOT save the found result as a new category, as
; there is nothing substantially "new", just an "old" thing
; should get new attention.

(defun cycle-or-implant (mutation knowledge seen)
  (cond ((null knowledge)
          (cons
            (list (caar seen) mutation (caddar seen))
            (reverse (cdr seen))))
        ((nearly-equal-sets (cadar knowledge) mutation)
          (append (list (car knowledge)) (reverse seen) (cdr knowledge)))
        (t (cycle-or-implant mutation
             (cdr knowledge) (cons (car knowledge) seen)))))

; (cycle-or-implant '(A B C) '((CAT1 (Q R S) (IMGA)) (CAT2 (L M N) (IMGB))
;   (CAT3 (S T U) (IMGC)) (CAT4 (A B C) (IMGD)) (CAT5 (Q R S) (IMGE))
;   (CAT6 (U V W) (IMGF))) nil)
; -->
; ((CAT4 (A B C) (IMGD)) (CAT1 (Q R S) (IMGA)) (CAT2 (L M N) (IMGB))
;  (CAT3 (S T U) (IMGC)) (CAT5 (Q R S) (IMGE)) (CAT6 (U V W) (IMGF)))

(defun all-cycle-or-implant (mutations knowledge)
  (cond ((null mutations) knowledge)
        (t (all-cycle-or-implant (cdr mutations)
             (cycle-or-implant (car mutations) knowledge nil)))))
; (all-cycle-or-implant '((A B C) (N E W))
;   '((CAT1 (Q R S) (IMGA)) (CAT2 (L M N) (IMGB))
;    (CAT3 (S T U) (IMGC)) (CAT4 (A B C) (IMGD)) (CAT5 (Q R S) (IMGE))
;    (CAT6 (U V W) (IMGF))))
; -->
; ((CAT6 (N E W) (IMGF)) (CAT4 (A B C) (IMGD)) (CAT1 (Q R S) (IMGA))
;  (CAT2 (L M N) (IMGB)) (CAT3 (S T U) (IMGC)) (CAT5 (Q R S) (IMGE)))

(defun mapcar-cadr (somelist)
  (cond ((null somelist) nil)
        (t (cons (cadar somelist) (mapcar-cadr (cdr somelist))))))

; THUNK
(defun breed-mutations (knowledge)
  (let ((mutators (mapcar-cadr (takefirst knowledge *mutagen-count*))))
    (let ((proposals (generate-propositions mutators knowledge)))
      (let ((confirmed-mutants (takefirst
                                 (find-confirmed-mutations
                                   (takelast
                                     proposals
                                     (* *proposals-limit* ; or perhaps *mutagen-count*
                                        *category-count*)))
                                 *category-count*)))
        (let ((mutated-knowledge
               (all-cycle-or-implant confirmed-mutants knowledge)))
          mutated-knowledge)))))
; i.e. return "mutated-knowledge"; this is left that way so I can
; perhaps extend it later in another cycle.
; (setq *confnum* 4) --> 4
; (breed-mutations '((CAT1 (Q R S) (IMGA)) (CAT2 (L M N) (IMGB))
;    (CAT3 (S T U) (IMGC)) (CAT4 (A B C) (IMGD)) (CAT5 (Q R S) (IMGE))
;    (CAT6 (U V W) (IMGF))))
; -->
; ((CAT4 (U V W Q R S) (IMGD)) (CAT5 (A B C Q R S) (IMGE))
;  (CAT6 (L M N Q R S) (IMGF)) (CAT1 (Q R S) (IMGA)) (CAT2 (L M N) (IMGB))
;  (CAT3 (S T U) (IMGC)))

; --------------------------------------------------------

; HIERARCHISATION

; This is the part where you analyse input and change the input
; according to the recognised concepts therein. At the same time,
; the knowledge is adjusted, too.

; having a window of real-world input, try to find a category matching it:
(defun check-categories (window knowledge)
  (cond ((null window) nil)
        ((null knowledge) nil)
        ((allmembers (cadar knowledge) window) (car knowledge))
        (t (check-categories window (cdr knowledge)))))

; (check-categories '(A B C D)
; '((CAT1 (R T A B) ((IMAGO1A) (IMAGO2A) (IMAGO3A)))
; (CAT2 (X Y) ((IMAGO1B) (IMAGO2B)))
; (CAT3 (C B) ((IMAGO1C) (IMAGO2C) (IMAGO3C)))
; (CAT4 (A B C) ((IMAGO1D)))))
; -->
; (CAT3 (C B) ((IMAGO1C) (IMAGO2C) (IMAGO3C)))
;
; (check-categories '(G H A)
; '((CAT1 (R T A B) ((IMAGO1A) (IMAGO2A) (IMAGO3A)))
;  (CAT2 (X Y) ((IMAGO1B) (IMAGO2B)))
;  (CAT3 (C B) ((IMAGO1C) (IMAGO2C) (IMAGO3C)))
;  (CAT4 (A B C) ((IMAGO1D)))))
; --> NIL

; to GET the windows, in order to compare them with the
; above function, you have to split the input list into
; segments (which may partly overlap, too):
(defun split-into-segments (lis seglen stepsize cntr)
  (let ((takefst (takefirst lis seglen)))
    (cond
      ((< (length takefst) seglen) (list (cons cntr takefst))) ; nil)
      (t (cons
           (cons cntr takefst)
           (split-into-segments
             (takeafter lis stepsize) seglen stepsize (+ cntr stepsize)))))))
; count from zero, skip each time two forward, take four
; (split-into-segments '(A B C D E F G H) 4 2 0)
; -->
; ((0 A B C D) (2 C D E F) (4 E F G H) (6 G H))
;
; count from one, skip each time three forward, take four
; (split-into-segments '(A B C D E F G H) 4 3 1)
; --> 
; ((1 A B C D) (4 D E F G) (7 G H))
;
;
;
; (split-into-segments '(A B C D E F G H) 4 4 0)
; --> 
; ((0 A B C D) (4 E F G H) (8))

; given the extraction of segments above, you should
; attribute category matches to the segments:
(defun evaluate-segments (position-segments knowledge)
  (cond
    ((null position-segments) nil)
    (t (let ((found-category
              (check-categories (cdar position-segments) knowledge)))
      (cond
        ((null found-category)
          (evaluate-segments (cdr position-segments) knowledge))
        (t
          (cons
            (list (car position-segments) found-category)
            (evaluate-segments (cdr position-segments) knowledge))))))))
; (evaluate-segments
;   (split-into-segments '(A B C D E F G H) 4 2 0)
;   '((CAT1 (A B D) ((IMAGO1A) (IMAGO2A) (IMAGO3A)))
;   (CAT2 (E F G H) ((IMAGO1B) (IMAGO2B)))
;   (CAT3 (C E F) ((IMAGO1C) (IMAGO2C) (IMAGO3C)))
;   (CAT4 (G H I J) ((IMAGO1D)))))
; -->
; (((0 A B C D) (CAT1 (A B D) ((IMAGO1A) (IMAGO2A) (IMAGO3A))))
;  ((2 C D E F) (CAT3 (C E F) ((IMAGO1C) (IMAGO2C) (IMAGO3C))))
;  ((4 E F G H) (CAT2 (E F G H) ((IMAGO1B) (IMAGO2B)))))

; Make sure the found categorisation possibilities do not
; overlap. Otherwise you cannot replace a section of knowledge
; with a category - because there would be a conflict with
; some other category.
; A more complex approach could go for a tree-search
; here, but I am simply going to "assume" a "winning end"
; of the ordered segments:
(defun no-collisions (evaluated-segments)
  (cond
    ((null evaluated-segments) nil)
    ((null (cdr evaluated-segments)) evaluated-segments)
    (t (let ((position-border
              (+ (caaar evaluated-segments)
                 (length (cdaar evaluated-segments)))))
      (cond
; then everything is fine and there is no collision:
        ((>= (caaadr evaluated-segments) position-border)
          (cons (car evaluated-segments)
                (no-collisions (cdr evaluated-segments))))
; else, there IS an overlapping of segments that must
; be eliminated - here, favour THE END of the collision;
; this DOES NOT FORCE hierarchisations - these would be
; forced if you favour THE BEGINNING - but you might miss
; important tail-heavy hierarchisations, and the tail
; is more important as it is more close to the PRESENT:

; tail-heavy version:
        (t (no-collisions (cdr evaluated-segments))))))))

; if I wanted to go for head-heavy:
;       (t (no-collisions
;            (cons (car evaluated-segments)
;                  (cddr evaluated-segments)))))))))

; (no-collisions
; '(((0 A B C D) (CAT1 (A B D) ((IMAGO1A) (IMAGO2A) (IMAGO3A))))
;  ((2 C D E F) (CAT3 (C E F) ((IMAGO1C) (IMAGO2C) (IMAGO3C))))
;  ((4 E F G H) (CAT2 (E F G H) ((IMAGO1B) (IMAGO2B))))))
; tail-heavy version: -->
;  (((4 E F G H) (CAT2 (E F G H) ((IMAGO1B) (IMAGO2B)))))
; head-heavy version: -->
;  (((0 A B C D) (CAT1 (A B D) ((IMAGO1A) (IMAGO2A) (IMAGO3A))))
;  ((4 E F G H) (CAT2 (E F G H) ((IMAGO1B) (IMAGO2B)))))

; that what is observed during hierarchisation should be
; implantable also into the knowledge - basically, you
; DID match a category, but now this category has matched
; a new piece of reality. This piece of reality can be added to the
; list of imagines as a new imago belonging to the category.

; UNCONDITIONAL:
; (defun implant-imago (imago category)
;   (cons (car category) (cons (cadr category) (list
;   (cons imago (reverse (cdr (reverse (caddr category)))))))))

; CONDITIONAL - IMPLANT ONLY IF NOT KNOWN ALREADY, THEN CYCLE:
(defun implant-imago (imago category)
  (cond
    ((mmb imago (caddr category))
      (cons (car category) (cons (cadr category) (list
      (cons imago (elim-el imago (caddr category)))))))
    (t
      (cons (car category) (cons (cadr category) (list
      (cons imago (reverse (cdr (reverse (caddr category)))))))))))
; (implant-imago '(NEW) '(CAT1 (A B D) ((IMAGO1A) (IMAGO2A) (IMAGO3A))))
; -->
; (CAT1 (A B D) ((NEW) (IMAGO1A) (IMAGO2A)))

; With the help of implant-imago, implant an observation
; of hierarchisation into the knowledge.

; ; Here is the version WITHOUT cycling:
; (defun implant-observation (observation knowledge)
;   (cond ((null knowledge) nil)
;         ((null observation) knowledge)
;         (t
; ; You MUST compare category LABELS - if you go for entire
; ; category listings, then one implantation BEFORE the
; ; current implantation attempt will RUIN the comparison,
; ; as the list of imagines will NOT be the same any more:
;           (cond ((equal (caar knowledge) (caadr observation))
;                   (cons
;                     (implant-imago (cdar observation) (car knowledge))
;                     (cdr knowledge)))
;                 (t
;                   (cons
;                     (car knowledge)
;                     (implant-observation observation (cdr knowledge))))))))

; (implant-observation 
;
;  '((2 C D E F) (CAT3 (C E F) ((IMAGO1C) (IMAGO2C) (IMAGO3C))))
;
;  '((CAT1 (A B D) ((IMAGO1A) (IMAGO2A) (IMAGO3A)))
;    (CAT2 (E F G H) ((IMAGO1B) (IMAGO2B)))
;    (CAT3 (C E F) ((IMAGO1C) (IMAGO2C) (IMAGO3C)))
;    (CAT4 (G H I J) ((IMAGO1D)))))
;
; -->
;
; ((CAT1 (A B D) ((IMAGO1A) (IMAGO2A) (IMAGO3A)))
;  (CAT2 (E F G H) ((IMAGO1B) (IMAGO2B)))
;  (CAT3 (C E F) ((C D E F) (IMAGO1C) (IMAGO2C)))
;  (CAT4 (G H I J) ((IMAGO1D))))

; Here is the version WITH "cycling":
; Basically, you "cons" with the CDR of the knowledge,
; NOT with the knowledge itself, and propagate
; the CAR of the knowledge towards the top.
; The observation is actually continaing also its
; position where it was seen - this is not needed for the imago itself.
(defun implant-observation (observation knowledge)
  (cond ((null knowledge) nil)
        ((null observation) knowledge)
        (t
; You MUST compare category LABELS - if you go for entire
; category listings, then one implantation BEFORE the
; current implantation attempt will RUIN the comparison,
; as the list of imagines will NOT be the same any more:
          (cond ((equal (caar knowledge) (caadr observation))
                  (cons
                    (implant-imago (cdar observation) (car knowledge))
                    (cdr knowledge)))
                (t
                  (let ((implnt
                          (implant-observation observation (cdr knowledge))))
; THIS IS where you let (car implnt) "swim up" to the surface:
                  (cons (car implnt)
                        (cons (car knowledge) (cdr implnt)))))))))

; (implant-observation 
;
;  '((2 C D E F) (CAT3 (C E F) ((IMAGO1C) (IMAGO2C) (IMAGO3C))))
;
;  '((CAT1 (A B D) ((IMAGO1A) (IMAGO2A) (IMAGO3A)))
;    (CAT2 (E F G H) ((IMAGO1B) (IMAGO2B)))
;    (CAT3 (C E F) ((IMAGO1C) (IMAGO2C) (IMAGO3C)))
;    (CAT4 (G H I J) ((IMAGO1D)))))
;
; -->
;
; ((CAT3 (C E F) ((C D E F) (IMAGO1C) (IMAGO2C)))
;  (CAT1 (A B D) ((IMAGO1A) (IMAGO2A) (IMAGO3A)))
;  (CAT2 (E F G H) ((IMAGO1B) (IMAGO2B)))
;  (CAT4 (G H I J) ((IMAGO1D))))

; now, implant ALL proposed hierarchisations into knowledge -
; this is a parallel mass-learning approach of every window
; that has no over-lapping and wherein a category has been recognised.
(defun implant-all-observations (list-of-observations knowledge)
  (cond ((null list-of-observations) knowledge)
        (t (implant-all-observations
             (cdr list-of-observations)
             (implant-observation (car list-of-observations) knowledge)))))

; (implant-all-observations
;
;  '(((0 A B C D) (CAT1 (A B D) ((IMAGO1A) (IMAGO2A) (IMAGO3A))))
;    ((4 E F G H) (CAT2 (E F G H) ((IMAGO1B) (IMAGO2B)))))
;
;  '((CAT1 (A B D) ((IMAGO1A) (IMAGO2A) (IMAGO3A)))
;    (CAT2 (E F G H) ((IMAGO1B) (IMAGO2B)))
;    (CAT3 (C E F) ((IMAGO1C) (IMAGO2C) (IMAGO3C)))
;    (CAT4 (G H I J) ((IMAGO1D)))))
;
; -->
;
; ((CAT2 (E F G H) ((E F G H) (IMAGO1B)))
;  (CAT1 (A B D) ((A B C D) (IMAGO1A) (IMAGO2A)))
;  (CAT3 (C E F) ((IMAGO1C) (IMAGO2C) (IMAGO3C)))
;  (CAT4 (G H I J) ((IMAGO1D))))

; Now, implant hierarchisations into the input - it is nice that
; you have them in the "knowledge", but recognised "notions"
; should be represented in the input, too, replacing the substrate
; that lead to their recognition:
(defun hierarchise-input (hierarchisations input-list pos-cntr)
  (cond
    ((null hierarchisations) input-list)
    ((null input-list) nil)
    (t
      (cond
        ((equal pos-cntr (caaar hierarchisations))
          (cons (list (caadar hierarchisations)
                      (takefirst input-list
                                 (length (cdaar hierarchisations))))
                (hierarchise-input
                  (cdr hierarchisations)
                  (takeafter input-list (length (cdaar hierarchisations)))
                  (+ pos-cntr (length (cdaar hierarchisations))))))
        (t
          (cons (car input-list)
                (hierarchise-input
                  hierarchisations
                  (cdr input-list)
                  (+ 1 pos-cntr))))))))

; (hierarchise-input
;
;  '(((0 A B C D) (CAT1 (A B D) ((IMAGO1A) (IMAGO2A) (IMAGO3A))))
;    ((4 E F G H) (CAT2 (E F G H) ((IMAGO1B) (IMAGO2B)))))
;
;  '(A B C D E F G H) 0)
;
; -->
;
; ((CAT1 (A B C D)) (CAT2 (E F G H)))
; the ZERO above is due to the fact that we counted the
; intersectioning from ZERO.

; ; VARIANT HIERARCHISING ONLY THE CATEGORY NAME:
; (defun hierarchise-input (hierarchisations input-list pos-cntr)
;   (cond
;     ((null hierarchisations) input-list)
;     ((null input-list) nil)
;     (t
;       (cond
;         ((equal pos-cntr (caaar hierarchisations))
;           (cons (list (caadar hierarchisations)
; ;                     (takefirst input-list
; ;                                (length (cdaar hierarchisations)))
;                 )
;                 (hierarchise-input
;                   (cdr hierarchisations)
;                   (takeafter input-list (length (cdaar hierarchisations)))
;                   (+ pos-cntr (length (cdaar hierarchisations))))))
;         (t
;           (cons (car input-list)
;                 (hierarchise-input
;                   hierarchisations
;                   (cdr input-list)
;                   (+ 1 pos-cntr))))))))

; (hierarchise-input
;
;  '(((0 A B C D) (CAT1 (A B D) ((IMAGO1A) (IMAGO2A) (IMAGO3A))))
;    ((4 E F G H) (CAT2 (E F G H) ((IMAGO1B) (IMAGO2B)))))
;
;  '(A B C D E F G H) 0)
;
; -->
;
; ((CAT1) (CAT2))
; This was, however, unused - as it creates the following issue:
; how do you de-hierarchise? How do you make ACTUAL ACTIONS
; out of "CAT1" or "CAT2"? Which IMAGO shall you use?
; - You could say, "the most recent imago", so this could be solved.
; But I preferred to imply the imago within the hierarchisation this time.

; Create a categorisation hypothesis from the end of
; input, if nothing else is known. I.e. strictly speaking you
; cannot yet "categorise" as you HAVE NO MATCHING notion.
; But you can "make up" or "invent" a notion. You do this best
; with the most recently observed material. Obviously, as you
; CREATE a hypothesis, an OLD category must be FORGOTTEN
; (and its category-insignia are getting RE-USED with the new
; properties found in the hypothesis).
(defun establish-hypothesis (input-list window-size knowledge)
  (let ((revkno (reverse knowledge))
        (proposition (takelast input-list window-size)))
    (let ((last-category (car revkno))
          (rest-knowledge (reverse (cdr revkno))))
      (cons
        (list
          (car last-category)
          proposition
            (cons proposition
              (reverse (cdr (reverse (caddr last-category))))))
        rest-knowledge))))
        
; (establish-hypothesis
;   '(U V W X Y Z)
;   4
;   '((CAT1 (A B D) ((IMAGO1A) (IMAGO2A) (IMAGO3A)))
;     (CAT2 (E F G H) ((IMAGO1B) (IMAGO2B)))
;     (CAT3 (C E F) ((IMAGO1C) (IMAGO2C) (IMAGO3C)))
;     (CAT4 (G H I J) ((IMAGO1D) (IMAGO2D) (IMAGO3D)))))
;
; -->
;
; ((CAT4 (W X Y Z) ((W X Y Z) (IMAGO1D) (IMAGO2D)))
;  (CAT1 (A B D) ((IMAGO1A) (IMAGO2A) (IMAGO3A)))
;  (CAT2 (E F G H) ((IMAGO1B) (IMAGO2B)))
;  (CAT3 (C E F) ((IMAGO1C) (IMAGO2C) (IMAGO3C))))

; now, given an input-list, the knowledge about notions, and "windows"
; into which to sub-divide the input-list which are determined by
; segment-length (of the window) and step-size (between windows),
; try to "hierarchise" the input and record the effects on the knowledge,
; producing in the end (input-list knowledge) in one list:
(defun try-hierarchisation (input-list knowledge segment-length step-size)
  (cond
    ((> segment-length (length input-list))
      (list input-list knowledge))
    (t
      (let
        ((proto-possible-hiers
           (no-collisions
             (evaluate-segments
               (split-into-segments input-list segment-length step-size 0)
               knowledge))))
      (let
        ((possible-hiers
           (cond ((null proto-possible-hiers)
                   (evaluate-segments
                     (list
                       (let ((pos-final (- (length input-list)
                                           segment-length)))
                         (cond ((> 0 pos-final) (cons 0 input-list))
                               (t (cons pos-final
                                        (takelast
                                          input-list
                                          segment-length))))))
                     knowledge))
                 (t proto-possible-hiers))))
        (let
          ((hier-input
             (cond
               ((null possible-hiers)
                 input-list)
               (t
                 (hierarchise-input
                   possible-hiers
                   input-list
                   0))))
           (mutated-knowledge
             (cond
               ((null possible-hiers)
                 (establish-hypothesis
                   input-list segment-length knowledge))
               (t
                 (implant-all-observations
                   possible-hiers
                   knowledge)))))
           (list hier-input mutated-knowledge)))))))

; (try-hierarchisation
; 
;  '(V W X Y Z A B C D E F G H)
; 
;  '((CAT1 (A B D) ((IMAGO1A) (IMAGO2A) (IMAGO3A)))
;    (CAT2 (E F G H) ((IMAGO1B) (IMAGO2B)))
;    (CAT3 (C E F) ((IMAGO1C) (IMAGO2C) (IMAGO3C)))
;    (CAT4 (G H I J) ((IMAGO1D))))
;
;  4 1)
; 
; -->
; 
; ((V W X Y Z A B C D (CAT2 (E F G H)))
;  ((CAT2 (E F G H) ((E F G H) (IMAGO1B)))
;   (CAT1 (A B D) ((IMAGO1A) (IMAGO2A) (IMAGO3A)))
;   (CAT3 (C E F) ((IMAGO1C) (IMAGO2C) (IMAGO3C)))
;   (CAT4 (G H I J) ((IMAGO1D)))))
; 
; 
; 
; (try-hierarchisation
; 
;  '(V W X Y Z A B C D (CAT2 (E F G H)))
; 
;  '((CAT2 (E F G H) ((E F G H) (IMAGO1B)))
;    (CAT1 (A B D) ((IMAGO1A) (IMAGO2A) (IMAGO3A)))
;    (CAT3 (C E F) ((IMAGO1C) (IMAGO2C) (IMAGO3C)))
;    (CAT4 (G H I J) ((IMAGO1D))))
;
;  4 1)
; 
; --> 
; 
; ((V W X Y Z (CAT1 (A B C D)) (CAT2 (E F G H)))
;  ((CAT1 (A B D) ((A B C D) (IMAGO1A) (IMAGO2A)))
;   (CAT2 (E F G H) ((E F G H) (IMAGO1B)))
;   (CAT3 (C E F) ((IMAGO1C) (IMAGO2C) (IMAGO3C)))
;   (CAT4 (G H I J) ((IMAGO1D)))))
; 
; 
; ; but this works only if the step-size is 1, not 2:
; (try-hierarchisation
; 
;  '(V W X Y Z (CAT1 (A B C D)) (CAT2 (E F G H)))
; 
;  '((CAT1 (A B D) ((A B C D) (IMAGO1A) (IMAGO2A)))
;    (CAT2 (E F G H) ((E F G H) (IMAGO1B)))
;    (CAT3 (C E F) ((IMAGO1C) (IMAGO2C) (IMAGO3C)))
;    (CAT4 (G H I J) ((IMAGO1D))))
;
;  4 1)
; 
; -->
; 
; ((V W X Y Z (CAT1 (A B C D)) (CAT2 (E F G H)))
;  ((CAT4 (Y Z (CAT1 (A B C D)) (CAT2 (E F G H)))
;    (((Y Z (CAT1 (A B C D)) (CAT2 (E F G H))))))
;   (CAT1 (A B D) ((A B C D) (IMAGO1A) (IMAGO2A)))
;   (CAT2 (E F G H) ((E F G H) (IMAGO1B)))
;   (CAT3 (C E F) ((IMAGO1C) (IMAGO2C) (IMAGO3C)))))
; NOTE THE CAT4 ABOVE IS NOW OF GREATER HIERARCHY

; ONE hierarchisation possibility is kind of nice,
; but of course, MANY others are imaginable.
; Try out all possible hierarchisations. Hierarchisation series
; repetitions are allowed if you wish to use hypotheses;
; practically any series is possible. (I mean - a series of 
; "window-sizes and step-sizes".)
; The hierarchisation possibilities are
; controlled over seg-and-step-list, which contains a list of
; ((window-size step-size) (window-size step-size) ...)
(defun all-hierarchisations (input-list knowledge seg-and-step-list)
  (cond
    ((null input-list) (list nil knowledge))
    ((null seg-and-step-list) (list input-list knowledge))
    (t
      (let ((try-hier
             (try-hierarchisation input-list knowledge
                                  (caar seg-and-step-list)
                                  (cadar seg-and-step-list))))
        (cond
          ((equal input-list (car try-hier))
            (all-hierarchisations
              (car try-hier)
              (cadr try-hier)
              (cdr seg-and-step-list)))
          (t
            (all-hierarchisations
              (car try-hier)
              (cadr try-hier)
              seg-and-step-list)))))))

; (all-hierarchisations
;  
;   '(V W X Y Z A B C D E F G H)
;  
;   '((CAT1 (A B D) ((IMAGO1A) (IMAGO2A) (IMAGO3A)))
;     (CAT2 (E F G H) ((IMAGO1B) (IMAGO2B) (IMAGO3B)))
;     (CAT3 (C E F) ((IMAGO1C) (IMAGO2C) (IMAGO3C)))
;     (CAT4 (G H I J) ((IMAGO1D) (IMAGO2D) (IMAGO3D))))
; 
;   '((4 1) (4 1) (4 1) (4 1)))
; 
; -->
; 
; (((CAT3 (V W X (CAT4 (Y Z (CAT1 (A B C D)) (CAT2 (E F G H)))))))
;  ((CAT3 (V W X (CAT4 (Y Z (CAT1 (A B C D)) (CAT2 (E F G H)))))
;    ((V W X (CAT4 (Y Z (CAT1 (A B C D)) (CAT2 (E F G H))))) (IMAGO1C)
;     (IMAGO2C)))
;   (CAT4 (Y Z (CAT1 (A B C D)) (CAT2 (E F G H)))
;    ((Y Z (CAT1 (A B C D)) (CAT2 (E F G H))) (IMAGO1D) (IMAGO2D)))
;   (CAT1 (A B D) ((A B C D) (IMAGO1A) (IMAGO2A)))
;   (CAT2 (E F G H) ((E F G H) (IMAGO1B) (IMAGO2B)))))

; THUNK
(defun main-hierarchy (input-list knowledge)
  (all-hierarchisations input-list knowledge *hierarchisation-sequence*))
; this FINALLY delivers ((hierarchised input list) (adjusted knowledge list))

; The previous section was showing internal analysis, this section
; has shown handling input. The next section will demonstrate
; preparing output.

; --------------------------------------------------------

; PLANNING

; Assume the input has been perceived and analysed,
; assume categories have been thought. The "present" is
; known. What is missing is the "future", or a plan, as a
; "continuation" of the present.

; Continuing the "present" is a worthy goal, but WHAT IS "the present"?
; - The present can be a larger or more narrow situation.
; If you have a reply on the larger situation, all the better, else,
; try at least to reply to a more narrow segment of the present that
; is less specific. - Hence, make only the "most recent present"
; the new "present" to which to seek answers:
; Decompose the present situation or input hierarchisation stage
; into sections for which a plan shall be sought.
(defun decompose-situation (situation)
  (cond
    ((null situation) nil)
    (t
      (cons situation
        (cond
          ((and (null (ecdr situation)) (null (ecadar situation))) nil)
          ((null (ecdr situation)) (decompose-situation (ecadar situation)))
          (t (decompose-situation (ecdr situation))))))))
; (decompose-situation
;   '((CAT3 (V W X (CAT4 (Y Z (CAT1 (A B C D)) (CAT2 (E F G H))))))))
; -->
; (((CAT3 (V W X (CAT4 (Y Z (CAT1 (A B C D)) (CAT2 (E F G H)))))))
;  (V W X (CAT4 (Y Z (CAT1 (A B C D)) (CAT2 (E F G H)))))
;  (W X (CAT4 (Y Z (CAT1 (A B C D)) (CAT2 (E F G H)))))
;  (X (CAT4 (Y Z (CAT1 (A B C D)) (CAT2 (E F G H)))))
;  ((CAT4 (Y Z (CAT1 (A B C D)) (CAT2 (E F G H)))))
;  (Y Z (CAT1 (A B C D)) (CAT2 (E F G H))) (Z (CAT1 (A B C D)) (CAT2 (E F G H)))
;  ((CAT1 (A B C D)) (CAT2 (E F G H))) ((CAT2 (E F G H))) (E F G H) (F G H) (G H)
;  (H))
;
; (decompose-situation '(A B C D)) --> ((A B C D) (B C D) (C D) (D))

; Given these "variants" of the present, seek for them an answer within
; the knowledge of notions, i.e. what notion can follow upon the largest
; previous notion then recognised as "the present situation".

; try to find a "plan" in one specific experience:
(defun seek-specific-continuation (situation-fragment experience)
  (cond
    ((null experience)
      nil)
    ((nearly-equal-sets situation-fragment
      (takefirst experience (length situation-fragment)))
      ; alternatively to the above line: (list (car experience)))
; taking the cdr NOW implies that you do not want to give an empty plan:
      (takeafter experience (length situation-fragment)))
      ; alternatively to the above line: (cdr experience))
    (t (seek-specific-continuation situation-fragment (cdr experience)))))


; check all the experiences of a category for a plan:
(defun seek-category-continuation (situation-fragment category-experiences)
  (cond
    ((null category-experiences)
      nil)
    (t
      (let ((result
             (seek-specific-continuation situation-fragment
                                         (car category-experiences))))
        (cond
          ((not (null result))
; this is your plan:
            result)
          (t
            (seek-category-continuation situation-fragment
                                        (cdr category-experiences))))))))

; Now I could check further "categories" or "situational fragments".
; The question is: when looking for a plan, what is more important?
; The RECENCY of the (partial) experience or the PRECISION of the
; (old) experience?
; I am going here with RECENCY. That means I am first checking all
; PARTIAL situations, and only THEREAFTER - all categories.

(defun all-continuations-in-category
  (situation-fragment-list category-experiences)
  (cond
    ((null situation-fragment-list)
      nil)
    (t
      (let ((result
             (seek-category-continuation
               (car situation-fragment-list)
               category-experiences)))
        (cond
          ((not (null result))
; this is your plan:
            result)
          (t
            (all-continuations-in-category
              (cdr situation-fragment-list)
              category-experiences)))))))

(defun all-continuations-all-categories
  (situation-fragment-list knowledge)
  (cond
    ((null knowledge)
      nil)
    (t
      (let ((result
             (all-continuations-in-category
               situation-fragment-list
               (caddr (car knowledge)))))
        (cond
          ((not (null result))
            result)
          (t
            (all-continuations-all-categories
              situation-fragment-list
              (cdr knowledge))))))))

; (all-continuations-all-categories
; 
;   (decompose-situation '(R S T A B C D E F))
; 
;   '((CAT1 (A B D) ((IMAGO1A) (IMAGO2A) (IMAGO3A)))
;     (CAT2 (E F G H) ((X Y Z) (IMAGO2B) (IMAGO3B)))
;     (CAT3 (C E F) ((IMAGO1C) (A B C D E X CONTINUATION) (IMAGO3C)))
;     (CAT4 (G H I J) ((IMAGO1D) (IMAGO2D) (IMAGO3D)))))
; 
; -->
; 
; (CONTINUATION)
; -- the other possible result is NIL.

; You have a plan, but it is in a "hierarchised" form.
; So rather, make it "flat" for output:
(defun flatten-plan (plan)
  (cond
    ((null plan)
      nil)
    (t
      (cond
        ((listp (car plan))
          (flatten-plan (append (cadar plan) (cdr plan))))
        (t
          (cons (car plan) (flatten-plan (cdr plan))))))))

; (flatten-plan
;   '((CAT3 (V W X (CAT4 (Y Z (CAT1 (A B C D)) (CAT2 (E F G H))))))))
; -->
; (V W X Y Z A B C D E F G H)

; Even when you have a plan, talk only until as long as
; the interaction should not be terminated. The rest of
; the plan is NOT executed.
; THUNK using SIG-TERM:
(defun until-terminator (lis)
  (cond ((null lis) nil)
        ((equal *stop* (car lis)) nil)
        (t (cons (car lis) (until-terminator (cdr lis))))))
; (until-terminator '(A B C D SIG-TERM E F G H)) --> (A B C D)

; --------------------------------------------------------

; KNOWLEDGE SELECTION AND GENERATION

; Now that you have everything needed to create a plan,
; define a function to select the knowledge area which shall be
; used for the analysis of the input substrate. For this,
; simply pick the area which is most similar to the "problem"
; at hand (i.e. the relevant section of input history).
; The "candidate" will be the car of the knowledge-areas,
; and what is called below as "knowledge-areas" is the
; cdr of the knowledge-areas.

; select knowledge area to use:
(defun select-knowledge-area (problem candidate knowledge-areas)
  (cond
; car of candidate is the history, cadr of candidate - the knowledge
    ((null knowledge-areas) (cadr candidate))
    ((< (length (set-intersection (car candidate) problem))
        (length (set-intersection (caar knowledge-areas) problem)))
      (select-knowledge-area problem
                             (car knowledge-areas)
                             (cdr knowledge-areas)))
    (t (select-knowledge-area problem candidate (cdr knowledge-areas)))))

; (select-knowledge-area
; '(A B C D E)
; '((A B X Y Z) (KNOWLEDGE 1))
; '(((B X Y Z Q) (KNOWLEDGE 2))
; ((A B C Y Z) (KNOWLEDGE 3))
; ((A B X C Z) (KNOWLEDGE 4))))
; -->
; (KNOWLEDGE 3)

; Knowledge generation:
; Normally, you will load knowledge from a file.
; But if no file exists yet, knowledge may be generated:

(defun gen-imagines (default-imago cntr)
  (cond ((zerop cntr) nil)
        (t (cons default-imago (gen-imagines default-imago (- cntr 1))))))

; (gen-imagines '(I-M-A-G-O) 3) --> ((I-M-A-G-O) (I-M-A-G-O) (I-M-A-G-O))

(defun gen-categories (imagines category-number)
  (cond ((zerop category-number) nil)
        (t (cons (list
                   (intern (concatenate 'string "CAT"
                           (write-to-string category-number)))
                   (car imagines) imagines)
                 (gen-categories imagines (- category-number 1))))))

(defun gen-knowledge-area ()
  (reverse
    (gen-categories (gen-imagines '(I-M-A-G-O) *representation-count*)
                                               *category-count*)))  ; 2) 3)))
; (gen-knowledge-area)
; -->
; ((CAT1 NIL ((I-M-A-G-O) (I-M-A-G-O)))
;  (CAT2 NIL ((I-M-A-G-O) (I-M-A-G-O)))
;  (CAT3 NIL ((I-M-A-G-O) (I-M-A-G-O))))

(defun gen-multiple-knowledge-areas (cntr)
  (cond ((zerop cntr) nil)
        (t (cons (list nil (gen-knowledge-area))
                 (gen-multiple-knowledge-areas (- cntr 1))))))

(defun gen-knowledge ()
  (gen-multiple-knowledge-areas *knowledge-areas-count*))

(defun load-categories ()
    (cond ((null (probe-file "laian.txt"))
            (gen-knowledge))
          (t
            (with-open-file (stream "./laian.txt")
                (read stream)))))

; LOAD the knowledge:
(defvar *knowledge-areas* (load-categories))

; (defun load-categories ()
;     (cond ((null (probe-file "laian.txt"))
;             (setq *knowledge* (gen-knowledge)))
;           (t
;             (with-open-file (stream "./laian.txt")
;                 (setq *knowledge* (read stream))))))
; sample call:
; (load-categories)

; SAVE the knowledge:
(defun save-categories ()
    (with-open-file (stream "./laian.txt" :direction :output :if-exists :supersede)
        (format stream (write-to-string *knowledge-areas*)))) ; You cannot use print or princ here.
; sample call:
; (save-categories)

; --------------------------------------------------------

; EXECUTION PHASE:
; READ / HISTORISE
; HIERARCHISE
; ANALYSE NOTIONS
; PLAN / OUTPUT


; (defun eexxiitt () '())
(defun eexxiitt () (progn (terpri) (save-categories) (quit)))

(defvar *knowledge* nil)
(defvar *human* nil)
(defvar *bkp-human* nil)
(defvar *history* nil)
(defvar *machine* nil)
(defvar *hierarchy* nil)
(defvar *hierarchy-and-knowledge* nil)
(defvar *decomposed-situation* nil)
(defvar *plan* nil)

(defun run ()
  (progn
  (finish-output nil) (print '(HUMAN------)) (finish-output nil)
  (terpri) (finish-output nil)
  (finish-output nil) (setq *human* (read)) (finish-output nil)
; (terpri) (finish-output nil)
  (cond
    ((null *human*) (eexxiitt))
    (t
  (setq *history* (takelast (append *history* *human* (list *stop*))
                            *history-length*))
  (setq *knowledge* (select-knowledge-area *history*
                                           (car *knowledge-areas*)
                                           (cdr *knowledge-areas*)))
  (setq *hierarchy-and-knowledge* (main-hierarchy *history* *knowledge*))
  (setq *hierarchy* (car *hierarchy-and-knowledge*))
  (setq *knowledge* (cadr *hierarchy-and-knowledge*))

; the next line could be done several times:
  (setq *knowledge* (breed-mutations *knowledge*))
; (setq *knowledge* (breed-mutations *knowledge*))
; (setq *knowledge* (breed-mutations *knowledge*))

  (setq *decomposed-situation* (decompose-situation *hierarchy*))
  (setq *plan* (all-continuations-all-categories *decomposed-situation*
                                                 *knowledge*))
  (setq *machine* (apply-instincts (takelast
                    (until-terminator (flatten-plan *plan*))
                    *max-machine-reply-length*)))
  (setq *history* (takelast (append *history* *machine* (list *stop*))
                            *history-length*))
  (setq *knowledge-areas* (cons (list *history* *knowledge*)
                                (reverse (cdr (reverse *knowledge-areas*)))))
  (finish-output nil) (print '(MACHINE----)) (finish-output nil)
  (finish-output nil) (print *machine*) (finish-output nil)
  (finish-output nil) (terpri) (finish-output nil)
  (run)))))

(progn
(print '(LEARNING ARTIFICIAL INTELLIGENCE APPLYING NOTIONS (LAIAN)))
(print '(CATEGORY RECOGNITION SYSTEM))
(print '(ENTER NIL TO TERMINATE))
(print '(ENTER LIST OF SYMBOLS TO COMMUNICATE))
(terpri)
(finish-output nil)
(run)
)

; OPTIONAL:
; SNOWFLAKE & SLEDGE
; BUT THINKING IS ALREADY WITHIN BREED-MUTATIONS.
