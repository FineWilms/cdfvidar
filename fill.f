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
      
      subroutine fill(a,il,jl,value,b)

! now  assumes actual spval < value

c     routine fills in interior of an array which has undefined points
      real a(il,jl)         ! input and output array
      real value            ! array value denoting undefined
      real b(il,jl)
      dimension in(8), jn(8)   ! specifies neighbours
      data in/-1,-1,-1,0,1,1, 1, 0/
      data jn/-1, 0, 1,1,1,0,-1,-1/

      write(6,*)"fill il,jl,value=",il,jl,value

2     nrem=0
      do 6 j=2,jl-1
      do 6 i=2,il-1
      b(i,j)=a(i,j)
      if(a(i,j).lt.value)then
        neighb=0
        av=0.
        do 4 nbs=1,8
        if(a(i+in(nbs),j+jn(nbs)).gt.value)then
          neighb=neighb+1
          av=av+a(i+in(nbs),j+jn(nbs))
        endif
4       continue
        if(neighb.gt.0)then
          b(i,j)=av/neighb
        else
          nrem=nrem+1    ! number of remaining points
        endif
      endif
6     continue
      do j=2,jl-1
       do i=2,il-1
        a(i,j)=b(i,j)
       enddo
      enddo
      if(nrem.gt.0)go to 2

!     fix up any boundary points
      do 7 i=2,il-1
      if(a(i,1).lt.value)a(i,1)=a(i,2)
      if(a(i,jl).lt.value)a(i,jl)=a(i,jl-1)
7     continue
      do 8 j=2,jl-1
      if(a(1,j).lt.value)a(1,j)=a(2,j)
      if(a(il,j).lt.value)a(il,j)=a(il-1,j)
8     continue
      if(a(1,1).lt.value)a(1,1)=a(2,2)
      if(a(il,1).lt.value)a(il,1)=a(il-1,2)
      if(a(1,jl).lt.value)a(1,jl)=a(2,jl-1)
      if(a(il,jl).lt.value)a(il,jl)=a(il-1,jl-1)
      return
      end
c******************************************************************************
