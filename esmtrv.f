! Conformal Cubic Atmospheric Model
    
! Copyright 2015 Commonwealth Scientific Industrial Research Organisation (CSIRO)
    
! This file is part of the Conformal Cubic Atmospheric Model (CCAM)
!
! CCAM is free software: you can redistribute it and/or modify
! it under the terms of the GNU General Public License as published by
! the Free Software Foundation, either version 3 of the License, or
! (at your option) any later version.
!
! CCAM is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
! GNU General Public License for more details.
!
! You should have received a copy of the GNU General Public License
! along with CCAM.  If not, see <http://www.gnu.org/licenses/>.

!------------------------------------------------------------------------------
      
      subroutine esmtrv ( tt, es, len1, t, it, tab1, tab2 )
c***********************************************************************
c computes saturation vapor press.(pa) for temperatures -100 < t < 102 c
c               for one dimensional arrays (len1)                      c
c  input temperatures (tt) in kelvin (k)                              c
c  output array es
c***********************************************************************
c
      dimension tt(len1), es(len1), tab1(len1),
     .          t (len1), it(len1), tab2(len1)
c
      include 'estab.h'
c
      dimension tabl1(90), tabl2(114)
c
      equivalence (tabl1(1),table(1)), (tabl2(1),table(91))
c
c table of saturation vapor pressure for -100 < t < 102 c
c in one degree increments.
c
      data tabl1/
     1       .001403, .001719, .002101, .002561, .003117, .003784,
     2       .004584, .005542, .006685, .008049, .009672, .01160,
     3       .01388,  .01658,  .01977,  .02353,  .02796,  .03316,
     4       .03925,  .04638,  .05472,  .06444,  .07577,  .08894,
     5       .1042,   .1220,   .1425,   .1662,   .1936,   .2252,
     6       .2615,   .3032,   .3511,   .4060,   .4688,   .5406,
     7       .6225,   .7159,   .8223,   .9432,  1.080,   1.236,
     8      1.413,   1.612,   1.838,   2.092,   2.380,   2.703,
     9      3.067,   3.476,   3.935,   4.449,   5.026,   5.671,
     a      6.393,   7.198,   8.097,   9.098,  10.21,   11.45,
     b     12.83,   14.36,   16.06,   17.94,   20.02,   22.33,
     c     24.88,   27.69,   30.79,   34.21,   37.98,   42.13,
     d     46.69,   51.70,   57.20,   63.23,   69.85,   77.09,
     e     85.02,   93.70,  103.20,  114.66,  127.20,  140.81,
     f    155.67,  171.69,  189.03,  207.76,  227.96,  249.67/
      data tabl2/
     1    272.98,  298.00,  324.78,  353.41,  383.98,  416.48,  451.05,
     2    487.69,  526.51,  567.52,  610.78,  656.62,  705.47,  757.53,
     3    812.94,  871.92,  934.65, 1001.3,  1072.2,  1147.4,  1227.2,
     4   1311.9,  1401.7,  1496.9,  1597.7,  1704.4,  1817.3,  1936.7,
     5   2063.0,  2196.4,  2337.3,  2486.1,  2643.0,  2808.6,  2983.1,
     6   3167.1,  3360.8,  3564.9,  3779.6,  4005.5,  4243.0,  4492.7,
     7   4755.1,  5030.7,  5320.0,  5623.6,  5942.2,  6276.2,  6626.4,
     8   6993.4,  7377.7,  7780.2,  8201.5,  8642.3,  9103.4,  9585.5,
     9  10089.,  10616.,  11166.,  11740.,  12340.,  12965.,  13617.,
     a  14298.,  15007.,  15746.,  16516.,  17318.,  18153.,  19022.,
     b  19926.,  20867.,  21845.,  22861.,  23918.,  25016.,  26156.,
     c  27340.,  28570.,  29845.,  31169.,  32542.,  33965.,  35441.,
     d  36971.,  38556.,  40198.,  41898.,  43659.,  45481.,  47367.,
     e  49317.,  51335.,  53422.,  55580.,  57809.,  60113.,  62494.,
     f  64953.,  67492.,  70113.,  72819.,  75611.,  78492.,  81463.,
     g  84528.,  87688.,  90945.,  94302.,  97761., 101325., 104994.,
     h 108774., 108774./
c
      data c27316/273.16/, c100/100./, c102/102./, c1/1./
c
      do 100 i = 1 , len1
      t(i)= tt(i) - c27316
 100  continue
c
      do 150 ii=1,len1
        t(ii)=max(t(ii),-c100)
        t(ii)=min(t(ii),c102)
 150  continue
c
      do 200 i = 1 , len1
        it(i) = int(t(i)+c100)
 200  continue
c
      do 300 i = 1 , len1
        t(i) = t(i)-(real(it(i))-c100)
 300  continue
c
      do 400 i=1,len1
        index=it(i)
        tab1(i)=table(index+1)
        tab2(i)=table(index+2)
 400  continue
c
      do 500 i = 1 , len1
        es(i) = (c1-t(i))*tab1(i)+t(i)*tab2(i)
 500  continue
c
      return
      end
