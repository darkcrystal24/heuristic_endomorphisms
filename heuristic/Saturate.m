// TODO: Generalize to isogenies

intrinsic VerifySaturated(GeoEndList::List, P::.) -> BoolElt
{Verifies whether the endomorphism ring is saturated in the algebra found so far.}
// Optional argument if lattice was calculated already

Rs := GeoEndList[2];
// Creation of relevant algebras
g := #Rows(Rs[1]) div 2;
// Ambient matrix algebra, plus generators of the endomorphism ring
A := Algebra(MatrixRing(Rationals(), 2*g)); GensA := [ A ! Eltseq(R) : R in Rs ];
// As a subalgebra
B := sub<A | GensA>; GensB := [ B ! gen : gen in GensA ];
// As an associative algebra
C := AssociativeAlgebra(B); GensC := [ C ! gen : gen in GensB ];

OC := Order(Integers(), GensC);
DOC := Discriminant(OC); DOM := Discriminant(MaximalOrder(C));
test, ind := IsSquare(DOC / DOM); ind := Integers() ! ind;

ps := [ tup[1] : tup in Factorization(ind) ];
for p in ps do
    test, R := VerifySaturatedAtPrime(GeoEndList, P, p);
    if not test then
        return false, R;
    end if;
end for;
return true, 0;

end intrinsic;


intrinsic VerifySaturatedAtPrime(GeoEndList::List, P::., p::RngIntElt) -> BoolElt
{Verifies whether the endomorphism ring is saturated in the algebra found so far, looking only at the prime p.}

Rs := GeoEndList[2];
CC := Parent(P[1,1]); RR := RealField(CC); JP := ComplexStructure(P);
I := [0..(p - 1)]; d := #Rs; CP := CartesianPower(I, d);

for tup in [ tup : tup in CP | not &and[ c eq 0 : c in tup ] ] do
    R := &+[ tup[i]*Rs[i] : i in [1..#Rs] ]/p;
    if &and[ c in Integers() : c in Eltseq(R) ] then
        D := JP*R - R*JP;
        if &and[ (RR ! Abs(d)) lt RR`epscomp : d in Eltseq(D) ] then
            return false, R;
        end if;
    end if;
end for;
return true, 0;

end intrinsic;
