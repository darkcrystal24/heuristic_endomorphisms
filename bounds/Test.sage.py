"""
 *  Bound functionality
 *
 *  Copyright (C) 2016-2017
 *            Edgar Costa      (edgarcosta@math.dartmouth.edu)
 *            Davide Lombardo  (davide.lombardo@math.u-psud.fr)
 *            Jeroen Sijsling  (jeroen.sijsling@uni-ulm.de)
 *
 *  See LICENSE.txt for license details.
"""

# This file was *autogenerated* from the file Test.sage
from sage.all_cmdline import *   # import sage library

_sage_const_3 = Integer(3); _sage_const_2 = Integer(2); _sage_const_1 = Integer(1); _sage_const_0 = Integer(0); _sage_const_7 = Integer(7); _sage_const_6 = Integer(6); _sage_const_5 = Integer(5); _sage_const_4 = Integer(4); _sage_const_100 = Integer(100); _sage_const_8 = Integer(8); _sage_const_14 = Integer(14)
load("constants.sage")
load("DiscriminantBound.sage")
load("EndomorphismRankBound.sage")
attach("Genus2Factors.sage")
load("GeometricallyIrreducible.sage")
#load("MagmaInterface.m")
load("NonCM.sage")
load("NonIsogenous.sage")
load("NonQM.sage")
load("PointCounting.sage")
load("TwistPolynomials.sage")



def testHigherGenus() :
    R = PolynomialRing(QQ, names=('u',)); (u,) = R._first_ngens(1)

    # Reducible example
    f = u**_sage_const_6 -_sage_const_7 *u**_sage_const_4 +_sage_const_14 *u**_sage_const_2 -_sage_const_7 
    h = _sage_const_0 

    # Trivial endomorphisms in genus 3
    f = u**_sage_const_7 -_sage_const_2 *u**_sage_const_6 +_sage_const_5 *u**_sage_const_5 -_sage_const_2 *u**_sage_const_4 +u**_sage_const_3 +_sage_const_4 *u**_sage_const_2 +_sage_const_2 *u
    h = u**_sage_const_2 +_sage_const_1 

    # RM by Q(sqrt(5))
    f = R([_sage_const_0 , -_sage_const_2 , _sage_const_1 ])
    h = R([_sage_const_1 , _sage_const_1 , _sage_const_0 , _sage_const_1 ])


    # RM by Q(\sqrt{17})
    f = R([-_sage_const_3 , _sage_const_8 , _sage_const_5 , _sage_const_7 , _sage_const_2 , _sage_const_1 ])
    h = _sage_const_0 

    # Stupid full CM
    f = u**_sage_const_5  + _sage_const_1 
    f = u**_sage_const_7  + _sage_const_1 
    h = _sage_const_0 

    C = HyperellipticCurve(f,h)
    LPolys = ComputeLPolys(C)

    type, bd = DiscriminantBound(LPolys)

    print "Type", type
    print "Bound", bd.factor()

    print "Bound on the Z-rank of the endomorphism ring", EndomorphismRankBound(LPolys, C.genus())

def TestEC() :
    LPolys1 = [ _sage_const_0  for i in range(_sage_const_0 ,maxP) ]
    LPolys2 = [ _sage_const_0  for i in range(_sage_const_0 ,maxP) ]
    # p1 = [0, -1, 1, 0, 0]
    # p2 = [0, -1, 1, -10, -20]

    p1 = [_sage_const_0 , -_sage_const_1 , _sage_const_0 , _sage_const_1 , _sage_const_0 ]
    p2 = [_sage_const_0 , _sage_const_1 , _sage_const_0 , _sage_const_1 , _sage_const_0 ]

    E1 = EllipticCurve(p1)
    E2 = EllipticCurve(p2)

    LPolys1 = ComputeLPolys(E1)
    LPolys2 = ComputeLPolys(E2)

	
    #d = E1.discriminant() * E2.discriminant()
    #for p in range(2,maxP) :
    #    if is_prime(p) and d%p != 0 :
    #        E1p = E1.base_extend(FiniteField(p))
    #        E2p = E2.base_extend(FiniteField(p))
    #        LPolys1[p] = E1p.frobenius_polynomial()
    #        LPolys2[p] = E2p.frobenius_polynomial()
    #print "Finished computing L-functions"
    print "Can prove there is no isogeny over the ground field?", CertifyNonIsogenous(LPolys1, LPolys2, false)
    print "Can prove there is no isogeny geometrically?", CertifyNonIsogenous(LPolys1, LPolys2)


def TestPicard() :
    R = PolynomialRing(QQ, names=('x',)); (x,) = R._first_ngens(1)
    LPolys = magma.computeLPolys2(_sage_const_100 )
    print "Finished computing L-polynomials"
    LPolysInternal = [R(l) for l in LPolys]
    LPolysInternal.insert(_sage_const_0 ,_sage_const_0 )
    print "Finished converting L-polys to Sage"
    type, bound = DiscriminantBound(LPolysInternal)

    print "Type", type
    print "Discriminant bound", bound

def TestDetectGenus2Factor() :
    R = PolynomialRing(QQ, names=('x',)); (x,) = R._first_ngens(1)

    f = x**_sage_const_7 +x**_sage_const_6 +x**_sage_const_5 +x**_sage_const_3 +x**_sage_const_2 +x
    h = x**_sage_const_4 +x**_sage_const_2 +_sage_const_1 
    # d = 3993
    # Cannot prove anything, which is correct because the quotient abelian surface is QM


    f = x**_sage_const_5 -x**_sage_const_4 +x**_sage_const_3 
    h = x**_sage_const_4 +_sage_const_1 
    # d = 7744
    # OK, confirms that the quotient abelian surface has no extra endomorphisms (it used to: why did this stop working?)

    # f = x^8+x^2+1
    # h = 0


    C = HyperellipticCurve(f,h)
    LPolys = ComputeLPolys(C)


    Genus2LPolys = Genus2FactorTwistedLPolys(LPolys)

    type, bound = DiscriminantBound(Genus2LPolys, true)
    print "Type", type
    print "Discriminant bound", bound

"==== a curve of genus 3 with full CM ===="
__time__=misc.cputime(); __wall__=misc.walltime(); testHigherGenus(); print("Time: CPU %.2f s, Wall: %.2f s"%(misc.cputime(__time__), misc.walltime(__wall__)))
"====================================="
	
"==== Isogenies between elliptic curves ===="
__time__=misc.cputime(); __wall__=misc.walltime(); TestEC(); print("Time: CPU %.2f s, Wall: %.2f s"%(misc.cputime(__time__), misc.walltime(__wall__)))
"====================================="
	
"==== Proving that the genus 2 quotient of a threefold has no extra endomorphisms ===="
__time__=misc.cputime(); __wall__=misc.walltime(); TestDetectGenus2Factor(); print("Time: CPU %.2f s, Wall: %.2f s"%(misc.cputime(__time__), misc.walltime(__wall__)))
"====================================="

