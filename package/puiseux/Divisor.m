declare attributes Crv : is_hyp, is_planar, is_smooth, is_plane_quartic;
declare attributes Crv : unif, index;
declare attributes Crv : g, U, Q0, A, R, F, rF, OF, BOF, K, DEs, OurB, NormB, T;
declare attributes Crv : initialized;
declare attributes Crv : cantor_eqs;

declare verbose EndoCheck, 3;


forward InitializeCurve;
forward AlgebraicUniformizer;
forward OurBasisOfDifferentials;
forward NormalizedBasisOfDifferentials;

forward CandidateDivisors;
forward IrreducibleComponentsFromBranches;
forward IrreducibleComponentCheck;

forward DivisorFromMatrixSplit;


import "LocalInfo.m": DevelopPoint, InitializeImageBranch;
import "FractionalCRT.m": RandomSplitPrime, FractionalCRTSplit, ReduceMatrixSplit, ReduceCurveSplit;
import "Cantor.m": CantorEquations;


function InitializeCurve(X, P0)

if not assigned X`initialized then
    X`initialized := false;
end if;
if X`initialized then
    return 0;
end if;
X`is_hyp := IsHyperelliptic(X);
X`is_planar := IsPlaneCurve(X);
X`is_smooth := IsNonSingular(X);
X`g := Genus(X);
X`is_plane_quartic := (X`is_planar) and (X`is_smooth) and (X`g eq 3);
if IsAffine(X) then
    X`U := X; X`Q0 := P0;
else
    X`U, X`Q0 := AffinePatch(X, P0);
end if;
X`A := Ambient(X`U);
X`R := CoordinateRing(X`A);
X`F := BaseRing(X`R);
if Type(X`F) eq FldRat then
    X`rF := 1;
    X`OF := Integers();
else
    X`rF := Denominator(X`F.1) * X`F.1;
    X`OF := Order([ X`rF^i : i in [0..Degree(X`F) - 1] ]);
end if;
X`BOF := Basis(X`OF);
X`K := FieldOfFractions(X`R);
X`DEs := DefiningEquations(X`U);
X`unif, X`index := AlgebraicUniformizer(X);
X`OurB := OurBasisOfDifferentials(X);
X`NormB, X`T := NormalizedBasisOfDifferentials(X);
if X`is_planar then
    X`cantor_eqs := CantorEquations(X`DEs[1], X`g);
end if;
X`initialized := true;
return 0;

end function;


function AlgebraicUniformizer(X)
/*
 * Input:   A curve X.
 * Output:  A uniformizing element at P0
 *          and the corresponding index.
 */

Gens := GeneratorsSequence(X`R);
M := Matrix([ [ Evaluate(Derivative(DE, gen), X`Q0) : gen in Gens ] : DE in X`DEs ]);
/* Default is the first coordinate: */
i0 := 1;
for i in [1..#Gens] do
    if &and[ M[j, i] eq 0 : j in [1..#Rows(M)] ] then
        i0 := i;
    end if;
end for;
return Gens[i0], i0;

end function;


function OurBasisOfDifferentials(X);
/*
 * Input:   A curve X.
 * Output:  A basis of global differentials on X, represented by elements of
 *          the ambient.
 */

g := X`g;
R := X`R;
x := R.1; y := R.2;
if X`is_hyp then
    f := X`DEs[1];
    c2 := MonomialCoefficient(f, y^2);
    c1 := &+[ MonomialCoefficient(f, x^i*y) * x^i : i in [0..g] ];
    return [ x^(i-1) / (y + c1/(2*c2)) : i in [1..g] ];
elif X`is_plane_quartic then
    f := X`DEs[1];
    if X`index eq 1 then
        return [ X`K ! (n / Derivative(f, 2)) : n in [x,y,1] ];
    else
        return [ X`K ! (n / Derivative(f, 1)) : n in [x,y,1] ];
    end if;
else
    B := BasisOfDifferentialsFirstKind(X`U);
    du := Differential(AlgebraicUniformizer(X));
    return [ X`K ! (b / du) : b in B ];
end if;

end function;


function NormalizedBasisOfDifferentials(X)
/*
 * Input:   A curve X.
 * Output:  A differential basis Bnorm that is normalized with respect to the uniformizing parameter,
 *          and a matrix T such that multiplication by T sends B to Bnorm.
 */

g := X`g;
P := DevelopPoint(X, X`Q0, g);
BP := [ Evaluate(b, P) : b in X`OurB ];
T := Matrix([ [ Coefficient(BP[i], j - 1) : j in [1..g] ] : i in [1..g] ])^(-1);
NormB := [ &+[ T[i,j] * X`OurB[j] : j in [1..g] ] : i in [1..g] ];
return NormB, T;

end function;


function CandidateDivisors(X, d)
/*
 * Input:   A curve X
 *          and a degree d.
 * Output:  Equations for divisors of degree d coming from the ambient of X.
 */

g := X`g;
R := X`R;
F := X`F;
dim := Rank(R);

if X`is_hyp then
    x,y := Explode(GeneratorsSequence(R));
    Rprod := PolynomialRing(F, 2 * dim);
    Xdivs := [ x^i : i in [0..(d div 2)] ] cat [ x^i*y : i in [0..((d - g - 1) div 2)] ];
elif X`is_planar then
    x,y := Explode(GeneratorsSequence(R));
    Rprod := PolynomialRing(F, 2 * dim);
    f := DefiningEquations(X`U)[1];
    Xdivs := [ x^i*y^j : i in [0..d], j in [0..(Degree(f) - 1)] | i + j le d ];
end if;

hs := [ hom<R -> Rprod | [ Rprod.j : j in [ ((i-1)*dim + 1)..i*dim ] ]> : i in [1..2] ];
CP := CartesianPower(Xdivs, 2);
return [ &*[ hs[i](tup[i]) : i in [1..2] ] : tup in CP ];

end function;


function IrreducibleComponentsFromBranches(X, fs, P, alphaP)
/*
 * Input:   A curve X,
 *          a basis of divisor equations fs,
 *          the precision n used when determining these,
 *          and branch expansions P and alphaP.
 * Output:  The irreducible components corresponding that fit the given data.
 */

/* Recovering a linear system: */
e := Maximum([ Maximum([ Denominator(Valuation(c - Coefficient(c, 0))) : c in Q ]) : Q in alphaP ]);
prec := Precision(Parent(P[1]));
M := [ ];
for f in fs do
    r := [ ];
    for Q in alphaP do
        ev := Evaluate(f, P cat Q);
        r cat:= [ Coefficient(ev, i/e) : i in [0..prec - X`g] ];
    end for;
    Append(~M, r);
end for;
M := Matrix(M);
B := Basis(Kernel(M));

/* Coerce back to ground field (possible because of echelon form): */
F := BaseRing(X`U);
B := [ [ F ! c : c in Eltseq(b) ] : b in B ];

/* Corresponding equations: */
DEs := X`DEs;
R := X`R;
Rprod := Parent(fs[1]);
d := Rank(R);
g := X`g;
hs := [ hom<R -> Rprod | [ Rprod.j : j in [ ((i-1)*d + 1)..i*d ] ]> : i in [1..2] ];
eqs := [ &+[ b[i] * fs[i] : i in [1..#fs] ] : b in B ];
eqs := eqs cat [ h(DE) : h in hs, DE in DEs ];

/* Corresponding scheme: */
A := AffineSpace(Rprod);
S := Scheme(A, eqs);

return [ S ];

/* TODO: These steps may be a time sink and should be redundant, so we avoid
 *       them. They get eliminated as the degree increases anyway. */
Is := IrreducibleComponents(S);
return [ ReducedSubscheme(I) : I in Is ];

end function;


function IrreducibleComponentCheck(X, I)
/*
 * Input:   An irreducible scheme I in X x X.
 * Output:  Whether or not I intersects P0 x X with the correct multiplicity at
 *          P0 and nowhere else.
 */

A := Ambient(I);
R := CoordinateRing(A);
eqs := [ R.i - X`Q0[i] : i in [1..2] ];
S := Scheme(A, DefiningEquations(I) cat eqs);
if Dimension(S) eq 0 then
    if Degree(ReducedSubscheme(S)) eq 1 then
        if Degree(S) eq X`g then
            /* TODO: This is potentially slightly unsafe but delivers a big speedup */
            //if Dimension(I) eq 1 then
                return true;
            //end if;
        end if;
    end if;
end if;
return false;

end function;


intrinsic DivisorFromMatrix(X::Crv, P0::Pt, M::AlgMatElt : Margin := 2^4, DegreeBound := 1) -> Sch
{Given a curve X, a point P0 of X, and a matrix M that gives the tangent
representation of an endomorphism on the standard basis of differentials,
returns a corresponding divisor (if it exists). The parameter Margin indicates
how many potentially superfluous terms are used in the development of the
branch, and the parameter DegreeBound specifies at which degree one starts to
look for a divisor.}

/* We start at a suspected estimate and then increase degree until we find an
 * appropriate divisor: */
output := InitializeCurve(X, P0);
d := DegreeBound;
NormM := X`T * M * (X`T)^(-1);
while true do
    vprintf EndoCheck : "Trying degree %o...\n", d;
    fs := CandidateDivisors(X, d);
    n := #fs + Margin;
    vprintf EndoCheck : "Number of digits in expansion: %o.\n", n;

    /* Take non-zero image branch: */
    vprintf EndoCheck : "Expanding...\n";
    P, alphaP := ApproximationsFromTangentAction(X, NormM, n);
    vprint EndoCheck, 3 : P, alphaP;
    vprintf EndoCheck : "done.\n";

    /* Fit a divisor to it: */
    vprintf EndoCheck : "Solving linear system...\n";
    ICs := IrreducibleComponentsFromBranches(X, fs, P, alphaP);
    vprintf EndoCheck : "done.\n";

    for S in ICs do
        vprintf EndoCheck : "Checking:\n";
        vprintf EndoCheck : "Step 1...\n";
        DEs := DefiningEquations(S);
        if &and[ &and[ IsWeaklyZero(Evaluate(DE, P cat Q)) : Q in alphaP ] : DE in DEs ] then
            vprintf EndoCheck : "Step 2...\n";
            if IrreducibleComponentCheck(X, S) then
                vprintf EndoCheck : "Divisor found!\n";
                return S;
            end if;
            vprintf EndoCheck : "done.\n";
        end if;
    end for;

    /* If that does not work, give up and try one degree higher: */
    d +:= 1;
end while;

end intrinsic;


intrinsic DivisorFromMatrixSplit(X::Crv, P0::Pt, M::AlgMatElt : Margin := 2^4, DegreeBound := 1, B := 300) -> Sch
{Given a curve X, a point P0 of X, and a matrix M that gives the tangent
representation of an endomorphism on the standard basis of differentials,
returns a corresponding divisor (if it exists). The parameter Margin indicates
how many potentially superfluous terms are used in the development of the
branch, and the parameter DegreeBound specifies at which degree one starts to
look for a divisor.}

/* We start at a suspected estimate and then increase degree until we find an appropriate divisor: */
output := InitializeCurve(X, P0);
d := DegreeBound;
M := X`T * M * (X`T)^(-1);
tjs0, f := InitializeImageBranch(M);

/* Some global elements needed below: */
F := X`F;
rF := X`rF;
OF := X`OF;
BOF := X`BOF;
/* TODO: Play with precision here */
P, alphaP := ApproximationsFromTangentAction(X, M, X`g);
Rprod := PolynomialRing(X`F, 2 * Rank(X`R));

ps_rts := [ ];
prs := [ ];
I := ideal<X`OF | 1>;
DEss_red := [* *];
while true do
    /* Find new prime */
    repeat
        p_rt := RandomSplitPrime(f, B);
        p, rt := Explode(p_rt);
    until not p in [ tup[1] : tup in ps_rts ];
    Append(~ps_rts, p_rt);
    vprintf EndoCheck : "Split prime over %o\n", p;

    /* Add corresponding data: */
    pr := ideal<X`OF | [ p, rF - rt ]>;
    Append(~prs, pr);
    I *:= pr;
    X_red := ReduceCurveSplit(X, p, rt);
    M_red := ReduceMatrixSplit(M, p, rt);
    BI := Basis(I);

    /* Uncomment for check on compatibility with reduction */
    //print DivisorFromMatrix(X_red`U, X_red`Q0, (X_red`T)^(-1) * M_red * X_red`T);

    done := false;
    while true do
        vprintf EndoCheck : "Trying degree %o...\n", d;
        fs_red := CandidateDivisors(X_red, d);
        n := #fs_red + Margin;
        vprintf EndoCheck, 2 : "Number of digits in expansion: %o.\n", n;

        /* Take non-zero image branch: */
        vprintf EndoCheck, 2 : "Expanding...\n";
        P_red, alphaP_red := ApproximationsFromTangentAction(X_red, M_red, n);
        vprint EndoCheck, 3 : P_red, alphaP_red;
        vprintf EndoCheck, 2 : "done.\n";

        /* Fit a divisor to it: */
        vprintf EndoCheck, 2 : "Solving linear system...\n";
        ICs_red := IrreducibleComponentsFromBranches(X_red, fs_red, P_red, alphaP_red);
        vprintf EndoCheck, 2 : "done.\n";

        for S_red_it in ICs_red do
            vprintf EndoCheck, 2 : "Checking:\n";
            vprintf EndoCheck, 2 : "Step 1...\n";
            if IrreducibleComponentCheck(X_red, S_red_it) then
                vprintf EndoCheck, 2 : "Divisor found!\n";
                done := true;
                S_red := S_red_it;
                break;
            end if;
            vprintf EndoCheck, 2 : "done.\n";
        end for;

        if done then
            break;
        end if;

        /* If that does not work, give up and try one degree higher.
         * Note that d is initialized in the outer loop,
         * so that we keep the degree that works. */
        d +:= 1;
    end while;
    Append(~DEss_red, DefiningEquations(S_red));

    vprintf EndoCheck, 2 : "Fractional CRT...\n";
    DEs := [ ];
    for i:=1 to #DEss_red[1] do
        DE := Rprod ! 0;
        for mon in Monomials(DEss_red[1][i]) do
            exp := Exponents(mon);
            rs := [* *];
            for j:=1 to #DEss_red do
                Rprod_red := Parent(DEss_red[j][1]);
                Append(~rs, MonomialCoefficient(DEss_red[j][i], Monomial(Rprod_red, exp)));
            end for;
            DE +:= FractionalCRTSplit(rs, prs, OF, I, BOF, BI, F) * Monomial(Rprod, exp);
        end for;
        Append(~DEs, DE);
    end for;
    vprintf EndoCheck, 2 : "done.\n";

    vprintf EndoCheck : "Checking:\n";
    vprintf EndoCheck : "Step 1...\n";
    if &and[ &and[ IsWeaklyZero(Evaluate(DE, P cat Q)) : Q in alphaP ] : DE in DEs ] then
        S := Scheme(AffineSpace(Rprod), DEs);
        vprintf EndoCheck : "Step 2...\n";
        if IrreducibleComponentCheck(X, S) then
            vprintf EndoCheck : "Divisor found!\n";
            return S;
        end if;
        vprintf EndoCheck : "done.\n";
    end if;
end while;

end intrinsic;


intrinsic NonWeierstrassBasePointHyp(X::Crv, K::Fld, As::SeqEnum : B := 2^10) -> Crv, Pt, SeqEnum
{hello}

/* We could look for points in the extension, but that is laborious */
Pts := RationalPoints(X : Bound := B);
Pts_nW := [ P : P in RationalPoints(X : Bound := B) | P[2]*P[3] ne 0 ];
if #Pts_nW ne 0 then
    Hts := [ Maximum([ Height(c) : c in Eltseq(P) ]) : P in Pts ];
    min, ind := Minimum(Hts);
    if Degree(K) eq 1 then
        K := Rationals();
    end if;
    XK := ChangeRing(X, K);
    PK := XK ! Pts_nW[ind];
    AsK := As;
    return XK, PK, AsK;
end if;

/* Find non-Weierstrass point: */
f := HyperellipticPolynomials(X);
n0 := 1;
while true do
    ev0 := Evaluate(f, n0);
    if ev0 ne 0 then
        break;
    end if;
    n0 +:= 1;
end while;

/* Extend and embed: */
R<t> := PolynomialRing(K);
L := SplittingField(t^2 - ev0);
if Degree(L) eq 1 then
    L := Rationals();
end if;
XL := ChangeRing(X, L);
PL := XL ! [ L ! n0, Roots(t^2 - ev0, L)[1][1] ];
AsL := [ ChangeRing(A, L) : A in As ];
if #Pts ne 0 then
    return XL, PL, AsL;
end if;

end intrinsic;
