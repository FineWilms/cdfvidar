      program cdfvidar

      character*80 inf

      common/mapproj/du,tanl,rnml,stl1,stl2
      include 'nplevs.h' ! maxplev
      common/levpre/nplev,plev(maxplev)
      real cplev(maxplev)

      include 'gblparm.h' ! nnx nny nmax=nnx*nny = maximum dims for input grid 

      include 'newmpar.h'
      include 'netcdf.inc'

      include 'parm.h'
      include 'xyzinfo.h'  ! x,y,z,wts
      include 'latlong.h'  ! rlat,rlong
      include 'vecsuv.h'

      parameter ( pi=3.1415926536 )
      parameter ( g=9.80616 )

      common/ncdfids/dimil,dimjl,dimkl,dimtim
     &              ,idil,idjl,idkl,idnt
* dimension ids
      integer  dimil,dimjl,dimkl,dimtim
* variable ids
      integer  idil,idjl,idkl,idnt,ix,iy

      common/lconther/ther
      include 'vidar.h'
!        logical spline,oesig,debug,notop,opre,calout,oform
!        logical splineu,splinev,splinet,zerowinds,osig_in
!        character*80 zsfil,tsfil,smfil,vfil
!        common / vi / ntimes,spline,mxcyc,nvsig,nrh
!       &             ,oesig,ptop,debug,notop,opre
!       &             ,in,calout
!       &             ,iout,oform,osig_in
!       &             ,inzs,zsfil,ints,tsfil,insm,smfil
!       &             ,vfil
!       &             ,splineu,splinev,splinet,zerowinds

      logical sdiag
      real datan(nmax*maxplev)
      real zs_gbl(nmax)
      real lsm_gbl(nmax)
      common/glonlat/glon(nnx),glat(nny)

      real plevin    (maxplev)
      real hgt (il,jl,maxplev)
      real temp(il,jl,maxplev)
      real u   (il,jl,maxplev)
      real v   (il,jl,maxplev)
      real rh  (il,jl,maxplev)
      real sfcto_m(ifull)
      real lsmg_m(ifull)
      !real lsm_m(ifull) MJT lsmask
      real zsg(ifull)

      include 'sigdata.h'
!     common/sigdata/pmsl(ifull),sfct(ifull),zs(ifull),ps(ifull)
!    &             ,us(ifull,kl)    ,vs(ifull,kl)    ,ts(ifull,kl)
!    &             ,rs(ifull,kl)    ,hs(ifull,kl)    ,psg_m(ifull)
!    &             ,zsi_m(ifull)

      common/datatype/moist_var,in_type
      character*1 in_type
      character*2 moist_var

      logical ofirst, ogbl, orev, olsm_gbl
      logical testa,testb ! MJT quick fix
      character*60 timorg
      character*60 cu ! MJT quick fix
      character*3 cmonth
      character*80 zsavn,lsavn
      character*10 header
      common / comsig / dsg(kl), sgml(kl), sg(kl+1)
      common / cll / clon(ifull),clat(ifull)

      namelist/gnml/inf,vfil,ds,du,tanl,rnml,stl1,stl2,inzs,zsfil
     &             ,ints,tsfil, ogbl,zsavn,inzsavn,lsavn,inlsavn
     &             ,plevin,orev,io_out,igd,jgd,id,jd,mtimer,ntimes
     &             ,spline,mxcyc,nvsig,nrh
     &             ,oesig,sgml,dsg,ptop,debug,notop,opre,have_gp
     &             ,in,calout
     &             ,iout,oform,sdiag
     &             ,insm,smfil
     &             ,splineu,splinev,splinet,zerowinds
     &             ,grdx,grdy,slon,slat
! define vidar namelist variables
!     namelist / vi / spline,mxcyc,nvsig,nrh
!    &               ,oesig,sgml,dsg,ptop,debug,notop,opre
!    &               ,in,calout
!    &               ,iout,oform
!    &               ,insm,smfil
!    &               ,splineu,splinev,splinet,zerowinds
!    &               ,grdx,grdy,slon,slat

      data khin/0/,kuin/0/,kvin/0/,ktin/0/,krin/0/
      data igd/1/,jgd/1/,id/1/,jd/1/,mtimer/0/
      data ofirst/.true./,io_out/3/
      data ogbl/.true./,orev/.false./
      data inzs/10/, ints/0/, insm/0/, in/50/, iout/70/
      data ptop/0./, ntimes/1/, nvsig/4/
      data mxcyc/20/, oform/.true./
      data spline/.true./, notop/.false./, opre/.false./
      data debug/.false./,oesig/.true./, calout/.true./, nrh/0/
      data inzsavn/11/ , zsavn/'zsavn.ff'/
      data inlsavn/11/ , lsavn/'lsavn.ff'/
      data zsfil/'/tmp/csjjk/topog5'/
      data tsfil/'/tmp/csjjk/sfct'/
      data smfil/'/tmp/csjjk/smfil'/
      data sgml/kl*0./, dsg/kl*0./
      data plevin/maxplev*0./
      data splineu/.true./, splinev/.true./, splinet/.true./
      data sdiag/.false./
      data have_gp/.true./
      data zerowinds/.true./
      data grdx/1./
      data slon/0./
      data grdy/-1./
      data slat/90./

      save

!####################### read namelists ############################
      write(6,*)'read namelist'
      read (5, gnml)
      write(6,nml=gnml)
! read and write namelist input for vidar
!     open  ( 98, file='vidar.nml',status='unknown' )
!     read  ( 98, nml=vi )
!     write ( unit=6, nml=vi)
!####################### read namelist ############################

      spline = splineu .or. splinev .or. splinet

! set up what sigma levels the outgoing data will have
! assumes top down, ie. sg(1)=0., dsg>0

           sg(1)=0.
           if ( sgml(kl/2).gt.0. ) then
c dsg=0, sgml>0
              do l=2,kl
                sg(l)=.5*(sgml(l-1)+sgml(l))
              end do ! l=2,kl
              do l=2,kl+1
                dsg(l-1)=sg(l)-sg(l-1)
              end do ! l=2,kl+1
           elseif ( dsg(kl/2).gt.0. ) then
c sgml=0, dsg>0
              do l=2,kl-1
                sg(l)=sg(l-1)+dsg(l-1)
              end do ! l=2,kl-1
              do l=1,kl
                sgml(l)=.5*(sg(l)+sg(l+1))
              end do ! l=1,kl
           elseif ( kl.eq.35 ) then
              call calcsig(sg)
              do l=1,kl
                sgml(l)=.5*(sg(l)+sg(l+1))
                dsg(l)=sg(l+1)-sg(l)
              end do ! l=1,kl
           elseif ( oesig ) then
              do l=1,kl
                dsg(l)=1./float(kl)
                sgml(l)=(l-.5)/float(kl)
                sg(l+1)=sg(l)+dsg(l)
              end do ! l=1,kl
           else
	      write(6,*)"Wrong sigma specification: STOP"
              stop
           endif
           sg(kl+1)=1.

!####################### read topography data ############################
      write(6,*)'open ',inzs,' zsfil=',zsfil

      if ( ogbl ) then
        write(6,*)"set up cc geometry"
        open(unit=inzs,file=zsfil,status='old',form='formatted')
!       read(inzs,'(i3,i4,2f6.1,f5.2,f9.0,a47)')
!    &          ilx,jlx,rlong0,rlat0,schmidt,ds,header
        read(inzs,*)ilx,jlx,rlong0,rlat0,schmidt,ds,header
        du=rlong0
        tanl=rlat0
        rnml=schmidt
        write(6,*)"gbl mapproj=",ilx,jlx,rlong0,rlat0,schmidt,ds
        if(ilx.ne.il.or.jlx.ne.jl)
     &     stop 'wrong topo file supplied (il,jl) for cdfvidar'

        call setxyz

        rlatx=-1.e29
        rlatn= 1.e29
        rlonx=-1.e29
        rlonn= 1.e29

        do iq=1,ifull

c       convert conformal cubic lats & longs to degrees (-90 to 90) & (0 to 360)
c       used in sint16; N.B. original rlong is -pi to pi
          rlat(iq)=rlat(iq)*180./pi
          rlong(iq)=rlong(iq)*180./pi
          if(rlong(iq).lt.0.)rlong(iq)=rlong(iq)+360.
          if(rlat(iq).gt.rlatx)then
            rlatx=rlat(iq)
            ilatx=iq
          endif
          if(rlong(iq).gt.rlonx)then
            rlonx=rlong(iq)
            ilonx=iq
          endif
          if(rlat(iq).lt.rlatn)then
            rlatn=rlat(iq)
            ilatn=iq
          endif
          if(rlong(iq).lt.rlonn)then
            rlonn=rlong(iq)
            ilonn=iq
          endif

        enddo  ! iq loop

        write(6,*)"rlong,rlat(1,1)=",rlong(1),rlat(1)
        write(6,*)"rlong:x,n=",rlonx,ilonx,rlonn,ilonn
        write(6,*)"rlatg:x,n=",rlatx,ilatx,rlatn,ilatn
      else ! ( not ogbl ) then
        open(inzs,file=zsfil,form='formatted',recl=il*7,status='old')
        write(6,*)'read zsfil header'
        read(inzs,*,err=25)ilt,jlk,ds,du,tanl,rnml,stl1,stl2
 25     if(ilt.eq.0.or.jlk.eq.0)then
           write(6,*)'no header in newtopo file'
        else
           write(6,*)'Header information for topofile'
           write(6,*)'ilt,jlk,ds,du,tanl,rnml,stl1,stl2'
     &           ,ilt,jlk,ds,du,tanl,rnml,stl1,stl2
           if(ilt.ne.il.or.jlk.ne.jl)stop 'wrong topofile supplied'
        endif     ! (ilt.eq.0.or.jlk.eq.0)
        write(6,*)"set up model grid params by calling lconset ds=",ds
        call lconset(ds)
      endif ! ( ogbl ) then

      write(6,*)'read model grid zsg = g*zs'
      read(inzs,*)zsg

      write(6,*)'convert g*zs to zs(m)'
      do iq=1,ifull
        zs(iq)=zsg(iq)/g ! convert ascii read in zs*g to zs(m)
      enddo !iq=1,ifull

      write(6,*)'read model grid land-sea mask (0=ocean, 1=land)'
      read(inzs,*)lsm_m
      close(inzs)

      ijd=id+il*(jd-1)
      write(6,*)"ijd=",ijd," zs(m)=",zs(ijd)," lsm_m=",lsm_m(ijd)
!####################### read topography data ############################

!####################### open input netcdf file ############################
      write(6,*)'inf='
      write(6,*)inf
      ncid = ncopn(inf,ncnowrit,ier)
      write(6,*)'ncid=',ncid
      if(ier.ne.0) then
        write(6,*)' cannot open netCDF file; error code ',ier
        stop
      end if

!####################### get attributes of input netcdf file ############################
      call ncinq(ncid,ndims,nvars,ngatts,irecd,ier)
      write(6,'("ndims,nvars,ngatts,irecd,ier")')
      write(6,'(5i6)') ndims,nvars,ngatts,irecd,ier

c Get dimensions
      write(6,*) "get dim1 ncid=",ncid
c turn OFF fatal netcdf errors
      call ncpopt(0)
      lonid = ncdid(ncid,'lon',ier)
      write(6,*)"lon ncid,lonid,ier=",ncid,lonid,ier
c turn on fatal netcdf errors
c     write(6,*)"NCVERBOS,NCFATAL=",NCVERBOS,NCFATAL
c     call ncpopt(NCVERBOS+NCFATAL)
      if ( ier.eq.0 ) then
        write(6,*)"ncid,lonid=",ncid,lonid
        ier= nf_inq_dimlen(ncid,lonid,ix)
        write(6,*)"input ix,ier=",ix,ier
        latid= ncdid(ncid,'lat',ier)
        ier= nf_inq_dimlen(ncid,latid,iy)
        write(6,*)"input iy,ier=",iy,ier
        ier = nf_inq_varid(ncid,'lon',idv)
! get glon from input dataset
        ier = nf_get_var_real(ncid,idv,glon)
        ier = nf_inq_varid(ncid,'lat',idv)
        ier = nf_get_var_real(ncid,idv,glat)
      else
        write(6,*)"now try longitude"
        lonid = ncdid(ncid,'longitude',ier)
        write(6,*)"lonid=",lonid," ier=",ier
        ier= nf_inq_dimlen(ncid,lonid,ix)
        write(6,*)"input ix=",ix," ier=",ier
        ier = nf_inq_varid(ncid,'longitude',idv)
        ier = nf_get_var_real(ncid,idv,glon)
        write(6,*)"glon=",(glon(i),i=1,ix)

        latid= ncdid(ncid,'latitude',ier)
        ier= nf_inq_dimlen(ncid,latid,iy)
        write(6,*)"input iy=",iy
        ier = nf_inq_varid(ncid,'latitude',idv)
        ier = nf_get_var_real(ncid,idv,glat)
        write(6,*)"glat=",(glat(i),i=1,iy)
      endif ! ( ier .eq. 0 ) then

! find grid spacing for input data set
! NOTE: assumes even grid spacing!!!!
      slon = glon(1)
      elon = glon(ix)
      slat = glat(1)
      elat = glat(iy)
      write(6,*)"==================> slon=",slon," elon=",elon," ix=",ix
      write(6,*)"==================> slat=",slat," elat=",elat," iy=",iy
      dlon = (glon(ix)-glon(1))/float(ix-1)
      dlat = (glat(iy)-glat(1))/float(iy-1)
      write(6,*)"============================> dlon=",dlon," dlat=",dlat

!     if ( dlon .ne.0 ) stop

      ier = nf_inq_dimid(ncid,'pres',idpres)
      in_type="p"
      if ( ier .ne. 0 ) then
         ier = nf_inq_dimid(ncid,'lvl',idpres)
         in_type="s"
      endif
      write(6,*)"ier=",ier," idpres=",idpres," in_type=",in_type
      
      ier= nf_inq_dimlen(ncid,idpres,nplev)
      write(6,*)"ier=",ier," nplev=",nplev

      ier = nf_inq_varid(ncid,'pres',ivpres)
      if ( ier .ne. 0 ) then
         ier = nf_inq_varid(ncid,'lvl',ivpres)
      endif
      write(6,*)"ier=",ier," ivpres=",ivpres

      ier = nf_get_var_real(ncid,ivpres,plev)
      write(6,*)"ier=",ier," ivpres=",ivpres
      write(6,*)"input nplev=",nplev
      write(6,*)"plevs=",(plev(k),k=1,nplev)

      orev = plev(nplev).gt.plev(1)
      write(6,*)"#################################### orev=",orev

      if(orev) then
        do k=1,nplev
          datan(k)=plev(k)
        enddo
        do k=1,nplev
          plev(k)=datan(nplev+1-k)
        enddo
      endif

      xplev = -1.
      do k=1,nplev
         xplev=max(xplev,plev(k))
      enddo
      write(6,*)"xplev=",xplev

      osig_in = .false.
      if ( .01 .lt. xplev .and. xplev .lt. 800.  ) then
        write(6,*)"^^^^^^^^^actualy sigma levels^^^^^^^ fix plevs"
        osig_in = .true.
        do k=1,nplev
          plev(k)=plev(k)*1000. !
        enddo
        write(6,*)"plevs=",(plev(k),k=1,nplev)
      else if ( xplev .le. .01  ) then
        write(6,*)"^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ fix plevs"
        do k=1,nplev
          plev(k)=plevin(k)
        enddo
        write(6,*)"plevs=",(plev(k),k=1,nplev)
        stop 'xplev < 800 in cdfvidar'
      endif

      ier = nf_inq_dimid(ncid,'time',idtim)
      write(6,*)"ier=",ier," idtim=",idtim

!########## get number of times in input netcdf file ###########

      ier= nf_inq_dimlen(ncid,idtim,narch)
      write(6,*)"ier=",ier," narch=",narch
      narch=min(narch,ntimes)

      ier = nf_inq_varid(ncid,'time',ivtim)
      write(6,*)"ier=",ier," ivtim=",ivtim

      !call ncagtc(ncid,ivtim,"time_origin",timorg,20,ier)
      ier = nf_get_att_text(ncid,ivtim,'units',timorg) ! MJT quick fix
      write(6,*)"ier=",ier," timorg=",timorg

      if (ier.eq.0) then
        i=index(timorg,'since')
      else
        timorg='hours'
        i=0
      end if

      if (i.ne.0) then
        i=scan(timorg,' ')-1
        cu=''
        cu(1:i)=timorg(1:i)
        timorg(1:19)=timorg(i+8:i+26)
        read(timorg(1:4),*) iyr
        read(timorg(6:7),*) imn
        read(timorg(9:10),*) idy
        read(timorg(12:13),*) ihr
        read(timorg(15:16),*) imi 
      else
        cu=timorg
        ier = nf_get_att_text(ncid,ivtim,'time_origin',timorg)
        write(6,*)"ier=",ier," timorg=",timorg
        if (ier.ne.0) stop "timorg"
        read(timorg,'(i2)') idy
        read(timorg,'(3x,a3)') cmonth
        write(6,*)"cmonth=",cmonth
        imn = icmonth_to_imn(cmonth)
        write(6,*)"imn=",imn
        read(timorg,'(9x,i2)') iyr
        read(timorg,'(12x,i2)') ihr
        read(timorg,'(15x,i2)') imi
      end if

      if ( iyr .lt. 10 ) iyr = iyr+2000
      if ( iyr .lt. 100 ) iyr = iyr+1900

      write(6,'("iyr,imn,idy,ihr,imi=",5i4)')iyr,imn,idy,ihr,imi

      do j=1,iy
       do i=1,ix
         datan(i+(j-1)*ix     )=glon(i)
         datan(i+(j-1)*ix+nmax)=glat(j)
       enddo ! i
      enddo ! j

! printout of glon
      do j=1,iy,iy-1
        do i=1,ix,ix-1
          write(6,*)i,j,datan(i+(j-1)*ix)
        enddo
      enddo

       call prt_pan(rlong,il,jl,2,'rlong')
       call prt_pan(rlat ,il,jl,2,'rlat')

      write(6,*)"============= sintp16 clon++++++++++++++++++++++++++++"
      write(6,*)" nplev=",nplev

      call sintp16(datan,ix,iy,clon,sdiag)

      !call prt_pan(clon,il,jl,1,'clon')
       call prt_pan(clon,il,jl,2,'clon')
      !call prt_pan(clon,il,jl,3,'clon')
      !call prt_pan(clon,il,jl,4,'clon')
      !call prt_pan(clon,il,jl,5,'clon')
      !call prt_pan(clon,il,jl,6,'clon')

! printout of glat
      do j=1,iy,iy-1
        do i=1,ix,ix-1
          write(6,*)i,j,datan(i+(j-1)*ix+nmax)
        enddo
      enddo

      write(6,*)"============= sintp16 clat++++++++++++++++++++++++++++"
      write(6,*)" nplev=",nplev

      call sintp16(datan(1+nmax),ix,iy,clat,sdiag)

      !call prt_pan(clat,il,jl,1,'clat pan1')
       call prt_pan(clat,il,jl,2,'clat pan2')
      !call prt_pan(clat,il,jl,3,'clat pan3')
      !call prt_pan(clat,il,jl,4,'clat pan4')
      !call prt_pan(clat,il,jl,5,'clat pan5')
      !call prt_pan(clat,il,jl,6,'clat pan6')

      write(6,'("ix,iy,nplev,narch=",4i5)')ix,iy,nplev,narch

      write(6,*)"++++++++++++++++++++++++++++++++++++++++++++++++++++++"

      write(6,*)" nplev=",nplev
      write(6,*)" inlsavn=",inlsavn

      write(6,*)'read land-sea mask (0=ocean, 1=land) inlsavn=',inlsavn
      if(inlsavn.gt.0)then
        olsm_gbl=.true.
        write(6,*)"AVN land sea mask"
        write(6,*)"open sfc. orog. for avn data"
        open(inlsavn,file=lsavn,form='formatted',status='old')
!       rewind inlsavn
        write(6,*)"note that it runs north to south"
        read(inlsavn,*)((lsm_gbl(i+(j-1)*ix),i=1,ix),j=1,iy)
        close(inlsavn)
        call amap ( lsm_gbl, ix, iy, 'gbl lsmsk', 0., 0. )
      else
        olsm_gbl=.false.
        write(6,*)"######################## WARNING!!!!!!!!!!!!!!!!"
        write(6,*)"######################## since inlsavn le 0 ####"
        write(6,*)"######################## setting input lsm == 1!"
      write(6,*)" nplev=",nplev,ix,iy
        do j=1,iy
         do i=1,ix
          lsm_gbl(i+(j-1)*ix)=1.
         enddo ! i
        enddo ! j
      endif
      write(6,*)" nplev=",nplev

      write(6,*)"Now deal with sfc. zs inzsavn=",inzsavn
      if(inzsavn.gt.0)then
        write(6,*)"open sfc. orog. for avn data"
        open(inzsavn,file=zsavn,form='formatted',status='old')
! read in free formatted avn sfc. orography (28-mar-2000)
! note that it runs north to south
!       rewind inzsavn
        read(inzsavn,*)((zs_gbl(i+(j-1)*ix),i=1,ix),j=1,iy)
        call amap ( zs_gbl, ix, iy, 'gbl sfczs(m)', 0., 0. )
        !write(6,*)"interp. zsavn to output grid"
        !call sintp16(zs_gbl,ix,iy,zs,sdiag)
        !write(6,*) 'findxn model sfc.height (m)'
        !call findxn(zs,ifull,-1.e29,xa,kx,an,kn)
        write(6,*) 'close unit inzsavn=',inzsavn
        close(inzsavn)
      endif

      write(6,*)' reading variables '

c***********************************************************************
      do iarch=1,narch
c***********************************************************************

      sdiag=.false.

      ier = nf_inq_varid(ncid,'time',ivtim)
      ier = nf_get_var1_real(ncid,ivtim,iarch,time)
      nt=1
      
      select case(cu) ! MJT quick fix
        case('days')
          time=time*1440. 	
	case('hours')
          time=time*60. 	
	case('minutes')
          ! no change	
	case DEFAULT
	  write(6,*) "cannot convert unknown time unit ",trim(cu)
	  stop
      end select

      write(6,*)"time=",time

      write(6,*)" input levels are bottom-up"
      write(6,*)" model levels in vidar are top-down"
      write(6,*)" nplev=",nplev

      write(6,*)"==================================================hgt"

      ier = nf_inq_varid(ncid,'hgt',idvar)
      write(6,*)"ier=",ier," idvar=",idvar
      if ( ier .ne. 0 ) then
         ier = nf_inq_varid(ncid,'geop_ht',idvar)
         write(6,*)"ier=",ier," idvar=",idvar
      endif

      if ( ier .eq. 0 ) then

      write(6,*)ncid,iarch,idvar,ix,iy,nplev
      call ncread_3d(ncid,iarch,idvar,ix,iy,nplev,datan)

      call amap (datan,ix,iy,'input hgt',0.,0.)
      call amap (datan(1+ix*iy*(nplev-1)),ix,iy,'input hgt',0.,0.)

      do k=1,nplev
       khin=k
       khout=nplev+1-k
       if(orev)khout=k
       igout=ix/2+ix*(iy/2-1)+ix*iy*(khin-1)
       write(6,*)"************************************************k=",k
       write(6,*)"===> khin,datan(igout)=",khin,datan(igout)
       call sintp16(datan(1+ix*iy*(khin-1)),ix,iy,hgt(1,1,khout),sdiag)
       write(6,*)"khout,hgt(il/2,jl.2,khout)="
     &           ,khout,hgt(il/2,jl/2,khout)
       write(6,*)'<=== model hgt(m) khin,khout=',khin,khout
       call findxn(hgt(1,1,khout),ifull,-1.e29,xa,kx,an,kn)
      enddo ! k

      !call prt_pan(hgt(1,1, 1),il,jl,1,'hgt: 1')
      !call prt_pan(hgt(1,1, 1),il,jl,2,'hgt: 1')
      !call prt_pan(hgt(1,1, 1),il,jl,3,'hgt: 1')
      !call prt_pan(hgt(1,1, 1),il,jl,4,'hgt: 1')
      !call prt_pan(hgt(1,1, 1),il,jl,5,'hgt: 1')
      !call prt_pan(hgt(1,1, 1),il,jl,6,'hgt: 1')
      !call prt_pan(hgt(1,1,nplev),il,jl,1,'hgt: nplev')
      !call prt_pan(hgt(1,1,nplev),il,jl,2,'hgt: nplev')
      !call prt_pan(hgt(1,1,nplev),il,jl,3,'hgt: nplev')
      !call prt_pan(hgt(1,1,nplev),il,jl,4,'hgt: nplev')
      !call prt_pan(hgt(1,1,nplev),il,jl,5,'hgt: nplev')
      !call prt_pan(hgt(1,1,nplev),il,jl,6,'hgt: nplev')

      !if ( k.gt.0 ) stop

      endif ! ier = 0

      write(6,*)"==================================================u"

      ier = nf_inq_varid(ncid,'u',idvar)
      write(6,*)"ier=",ier," idvar=",idvar
      if ( ier .ne. 0 ) then
         ier = nf_inq_varid(ncid,'zonal_wnd',idvar)
         write(6,*)"ier=",ier," idvar=",idvar
      endif

      call ncread_3d(ncid,iarch,idvar,ix,iy,nplev,datan)

      ! MJT quick fix
      do i=1,ix
        do j=1,iy
          k=2
          do while ((k.le.nplev).and.(abs(datan(i+ix*(j-1))).gt.1.e10))
	    if (abs(datan(i+ix*(j-1)+ix*iy*(k-1))).lt.1.e10) then
	      do l=1,k-1
	        datan(i+ix*(j-1)+ix*iy*(l-1))=datan(i+ix*(j-1)+ix*iy*(k-1))
	      end do
	    end if
            k=k+1
          end do
	end do
      end do
      do while (any(abs(datan(1:ix*iy*nplev)).ge.1.e10))
        do i=1,ix
          do j=1,iy
	    do k=1,nplev
              if (abs(datan(i+ix*(j-1)+ix*iy*(k-1))).ge.1.e10) then
	        if (k.gt.1) testa=
     &            (abs(datan(i+ix*(j-1)+ix*iy*(k-2))).lt.1.e10)
		if (k.lt.nplev) testb=
     &            (abs(datan(i+ix*(j-1)+ix*iy*k)).lt.1.e10)
		if (testa.and.testb) then
		  datan(i+ix*(j-1)+ix*iy*(k-1))=0.5*(
     &	          datan(i+ix*(j-1)+ix*iy*(k-2))
     &            +datan(i+ix*(j-1)+ix*iy*k))
		else if (testa) then
		  datan(i+ix*(j-1)+ix*iy*(k-1))=
     &            datan(i+ix*(j-1)+ix*iy*(k-2))
		else if (testb) then
		  datan(i+ix*(j-1)+ix*iy*(k-1))=
     &            datan(i+ix*(j-1)+ix*iy*k)
		end if
	      end if
	    end do
          end do
	end do    
      end do


      call amap ( datan, ix, iy, 'input u', 0., 0. )

      do k=1,nplev
        write(6,*)"************************************************k=",k
        khin=k
        khout=nplev+1-k
        if(orev)khout=k
c       igout=ix/2+ix*(iy/2-1)+ix*iy*(khin-1)
c       write(6,*)khin,datan(igout)

        call sintp16(datan(1+ix*iy*(khin-1)),ix,iy,u(1,1,khout),sdiag)

c       write(6,*)khout,u(il/2,jl/2,khout)
c       write(6,*)'model u(m) khin,khout=',khin,khout
        call findxn(u(1,1,khout),ifull,-1.e29,xa,kx,an,kn)
      enddo

      !call prt_pan(u(1,1, 1),il,jl,2,'u : 1')
      !call prt_pan(u(1,1, 1),il,jl,1,'u : 1')
      !call prt_pan(u(1,1,nplev),il,jl,2,'u : nplev')
      !call prt_pan(u(1,1,nplev),il,jl,1,'u : nplev')

      write(6,*)"==================================================v"

      ier = nf_inq_varid(ncid,'v',idvar)
      write(6,*)"ier=",ier," idvar=",idvar
      if ( ier .ne. 0 ) then
         ier = nf_inq_varid(ncid,'merid_wnd',idvar)
         write(6,*)"ier=",ier," idvar=",idvar
      endif

      call ncread_3d(ncid,iarch,idvar,ix,iy,nplev,datan)

      ! MJT quick fix 
      do i=1,ix
        do j=1,iy
          k=2
          do while ((k.le.nplev).and.(abs(datan(i+ix*(j-1))).gt.1.e10))
	    if (abs(datan(i+ix*(j-1)+ix*iy*(k-1))).lt.1.e10) then
	      do l=1,k-1
	        datan(i+ix*(j-1)+ix*iy*(l-1))=datan(i+ix*(j-1)+ix*iy*(k-1))
	      end do
	    end if
            k=k+1
          end do
	end do
      end do
      do while (any(abs(datan(1:ix*iy*nplev)).ge.1.e10))
        do i=1,ix
          do j=1,iy
	    do k=1,nplev
              if (abs(datan(i+ix*(j-1)+ix*iy*(k-1))).ge.1.e10) then
	        if (k.gt.1) testa=
     &            (abs(datan(i+ix*(j-1)+ix*iy*(k-2))).lt.1.e10)
		if (k.lt.nplev) testb=
     &            (abs(datan(i+ix*(j-1)+ix*iy*k)).lt.1.e10)
		if (testa.and.testb) then
		  datan(i+ix*(j-1)+ix*iy*(k-1))=0.5*(
     &	          datan(i+ix*(j-1)+ix*iy*(k-2))
     &            +datan(i+ix*(j-1)+ix*iy*k))
		else if (testa) then
		  datan(i+ix*(j-1)+ix*iy*(k-1))=
     &            datan(i+ix*(j-1)+ix*iy*(k-2))
		else if (testb) then
		  datan(i+ix*(j-1)+ix*iy*(k-1))=
     &            datan(i+ix*(j-1)+ix*iy*k)
		end if
	      end if
	    end do
          end do
	end do    
      end do

      call amap ( datan, ix, iy, 'input v', 0., 0. )

      do k=1,nplev
        write(6,*)"************************************************k=",k
        khin=k
        khout=nplev+1-k
        if(orev)khout=k
c       igout=ix/2+ix*(iy/2-1)+ix*iy*(khin-1)
c       write(6,*)khin,datan(igout)

        call sintp16(datan(1+ix*iy*(khin-1)),ix,iy,v(1,1,khout),sdiag)

c       write(6,*)khout,v(il/2,jl/2,khout)
c       write(6,*)'model v(m) khin,khout=',khin,khout
        call findxn(v(1,1,khout),ifull,-1.e29,xa,kx,an,kn)
      enddo

      !call prt_pan(v(1,1, 1),il,jl,2,'v : 1')
      !call prt_pan(v(1,1, 1),il,jl,1,'v : 1')
      !call prt_pan(v(1,1,nplev),il,jl,2,'v : nplev')
      !call prt_pan(v(1,1,nplev),il,jl,1,'v : nplev')

      write(6,*)"==================================================temp"

      ier = nf_inq_varid(ncid,'temp',idvar)
      write(6,*)"ier=",ier," idvar=",idvar
      if ( ier .ne. 0 ) then
         ier = nf_inq_varid(ncid,'air_temp',idvar)
         write(6,*)"ier=",ier," idvar=",idvar
      endif

      call ncread_3d(ncid,iarch,idvar,ix,iy,nplev,datan)

      ! MJT quick fix 
      do i=1,ix
        do j=1,iy
          k=2
          do while ((k.le.nplev).and.(abs(datan(i+ix*(j-1))).ge.1.e10))
	    if (abs(datan(i+ix*(j-1)+ix*iy*(k-1))).lt.1.e10) then
	      do l=1,k-1
	        datan(i+ix*(j-1)+ix*iy*(l-1))=datan(i+ix*(j-1)+ix*iy*(k-1))
	      end do
	    end if
            k=k+1
          end do
	end do
      end do
      do while (any(abs(datan(1:ix*iy*nplev)).ge.1.e10))
        do i=1,ix
          do j=1,iy
	    do k=1,nplev
              if (abs(datan(i+ix*(j-1)+ix*iy*(k-1))).ge.1.e10) then
	        if (k.gt.1) testa=
     &            (abs(datan(i+ix*(j-1)+ix*iy*(k-2))).lt.1.e10)
		if (k.lt.nplev) testb=
     &            (abs(datan(i+ix*(j-1)+ix*iy*k)).lt.1.e10)
		if (testa.and.testb) then
		  datan(i+ix*(j-1)+ix*iy*(k-1))=0.5*(
     &	          datan(i+ix*(j-1)+ix*iy*(k-2))
     &            +datan(i+ix*(j-1)+ix*iy*k))
		else if (testa) then
		  datan(i+ix*(j-1)+ix*iy*(k-1))=
     &            datan(i+ix*(j-1)+ix*iy*(k-2))
		else if (testb) then
		  datan(i+ix*(j-1)+ix*iy*(k-1))=
     &            datan(i+ix*(j-1)+ix*iy*k)
		end if
	      end if
	    end do
          end do
	end do    
      end do

      call amap ( datan, ix, iy, 'input temp', 0., 0. )

      do k=1,nplev
        write(6,*)"************************************************k=",k
        khin=k
        khout=nplev+1-k
        if(orev)khout=k
c       igout=ix/2+ix*(iy/2-1)+ix*iy*(khin-1)
c       write(6,*)khin,datan(igout)
       call sintp16(datan(1+ix*iy*(khin-1)),ix,iy,temp(1,1,khout),sdiag)
c       write(6,*)khout,temp(il/2,jl/2,khout)
c       write(6,*)'model temp(m) khin,khout=',khin,khout
        call findxn(temp(1,1,khout),ifull,-1.e29,xa,kx,an,kn)
      enddo

      !call prt_pan(temp(1,1, 1),il,jl,1,'temp:  1')
      !call prt_pan(temp(1,1, 1),il,jl,2,'temp:  1')
      !call prt_pan(temp(1,1, 1),il,jl,3,'temp:  1')
      !call prt_pan(temp(1,1, 1),il,jl,4,'temp:  1')
      !call prt_pan(temp(1,1, 1),il,jl,5,'temp:  1')
      !call prt_pan(temp(1,1, 1),il,jl,6,'temp:  1')
      !call prt_pan(temp(1,1,nplev),il,jl,1,'temp: nplev')
      !call prt_pan(temp(1,1,nplev),il,jl,2,'temp: nplev')
      !call prt_pan(temp(1,1,nplev),il,jl,3,'temp: nplev')
      !call prt_pan(temp(1,1,nplev),il,jl,4,'temp: nplev')
      !call prt_pan(temp(1,1,nplev),il,jl,5,'temp: nplev')
      !call prt_pan(temp(1,1,nplev),il,jl,6,'temp: nplev')

      write(6,*)"================================================rh/q"

      ier = nf_inq_varid(ncid,'rh',idvar)
      write(6,*)"ier=",ier," idvar=",idvar
      moist_var="rh"

      if ( ier .ne. 0 ) then
         ier = nf_inq_varid(ncid,'mix_rto',idvar)
         write(6,*)"ier=",ier," idvar=",idvar
         moist_var="mr"
      endif

      write(6,*)"##################################moist_var=",moist_var

      call ncread_3d(ncid,iarch,idvar,ix,iy,nplev,datan)

      ! MJT quick fix 
      do i=1,ix
        do j=1,iy
          k=2
          do while ((k.le.nplev).and.(abs(datan(i+ix*(j-1))).gt.1.e10))
	    if (abs(datan(i+ix*(j-1)+ix*iy*(k-1))).lt.1.e10) then
	      do l=1,k-1
	        datan(i+ix*(j-1)+ix*iy*(l-1))=datan(i+ix*(j-1)+ix*iy*(k-1))
	      end do
	    end if
            k=k+1
          end do
	end do
      end do
      do while (any(abs(datan(1:ix*iy*nplev)).ge.1.e10))
        do i=1,ix
          do j=1,iy
	    do k=1,nplev
              if (abs(datan(i+ix*(j-1)+ix*iy*(k-1))).ge.1.e10) then
	        if (k.gt.1) testa=
     &            (abs(datan(i+ix*(j-1)+ix*iy*(k-2))).lt.1.e10)
		if (k.lt.nplev) testb=
     &            (abs(datan(i+ix*(j-1)+ix*iy*k)).lt.1.e10)
		if (testa.and.testb) then
		  datan(i+ix*(j-1)+ix*iy*(k-1))=0.5*(
     &	          datan(i+ix*(j-1)+ix*iy*(k-2))
     &            +datan(i+ix*(j-1)+ix*iy*k))
		else if (testa) then
		  datan(i+ix*(j-1)+ix*iy*(k-1))=
     &            datan(i+ix*(j-1)+ix*iy*(k-2))
		else if (testb) then
		  datan(i+ix*(j-1)+ix*iy*(k-1))=
     &            datan(i+ix*(j-1)+ix*iy*k)
		end if
	      end if
	    end do
          end do
	end do    
      end do

      call findxn(datan,ix*iy*nplev,-1.e29,xa,kx,an,kn)

      if ( xa .lt. .1 ) then
        moist_var="mr"
        write(6,*)"################################moist_var=",moist_var
      endif ! ( xa .lt. 1.1 ) then

      call amap ( datan, ix, iy, 'input '//moist_var, 0., 0. )

      do k=1,nplev
        write(6,*)"************************************************k=",k
        khin=k
        khout=nplev+1-k
        if(orev)khout=k

c       igout=ix/2+ix*(iy/2-1)+ix*iy*(khin-1)
c       write(6,*)khin,datan(igout)

        call sintp16(datan(1+ix*iy*(khin-1)),ix,iy,rh(1,1,khout),sdiag)

        write(6,*)"make sure data is always between 0 and 100!"
        write(6,*)"for both mixr and rh"
        do i=1,ifull
           rh(i,1,khout)=max(0.,min(100.,rh(i,1,khout)))
        enddo !i=1,ifull

c       write(6,*)khout,rh(il/2,jl/2,khout)
c       write(6,*)'model rh(m) khin,khout=',khin,khout

        call findxn(rh(1,1,khout),ifull,-1.e29,xa,kx,an,kn)

        if ( moist_var .eq. "rh" .and. xa .lt. 1.1 ) then

          write(6,*)"######################convert rh from 0-1 to 0-100"
          do i=1,ifull
            rh(i,1,khout)=max(0.,min(100.,rh(i,1,khout)*100.))
          enddo !i=1,ifull
          call findxn(rh(1,1,khout),ifull,-1.e29,xa,kx,an,kn)

        endif ! ( moist_var .eq. "rh" .and. xa .lt. 1.1 ) then

      enddo

      !call prt_pan(rh(1,1, 1),il,jl,1,moist_var//' : 1')
      !call prt_pan(rh(1,1,nplev),il,jl,1,moist_var//' : nplev')

!############################################################################
! sfc data
!############################################################################
      call findxn(hgt(1,1, 1),ifull,-1.e29,xa,kx,an,kn)
      call findxn(hgt(1,1,nplev),ifull,-1.e29,xa,kx,an,kn)
      write(6,*)"nplev=",nplev

      write(6,*)"================================================mslp"

      ier = nf_inq_varid(ncid,'mslp',idvar)
      write(6,*)"ier=",ier," idvar=",idvar
      if ( ier .ne. 0 ) then
         ier = nf_inq_varid(ncid,'pmsl',idvar)
         write(6,*)"ier=",ier," idvar=",idvar
      endif

      if ( ier .eq. 0 ) then

        call ncread_2d(ncid,iarch,idvar,ix,iy,datan)

        call amap ( datan, ix, iy, 'gbl mslp', 0., 0. )

        call sintp16(datan,ix,iy,pmsl,sdiag)

        write(6,*)" findxn model mslp(Pa)"
        call findxn(pmsl,ifull,-1.e29,xa,kx,an,kn)

        if ( an .gt. 2000. ) then
           write(6,*)"#########################convert pmsl to hPa"
           do i=1,ifull
             pmsl(i)=pmsl(i)/100. ! to convert to hPa
           enddo ! i=1,ifull
        endif ! ( an .gt. 2000. ) then

      else
           write(6,*)"No pmsl data found, setting to 0"
           do i=1,ifull
             pmsl(i)=0.
           enddo ! i=1,ifull
      endif ! ier

      call prt_pan(pmsl,il,jl,2,'pmsl')
      !call prt_pan(pmsl,il,jl,1,'pmsl')

      write(6,*)"================================================zs"

      ier = nf_inq_varid(ncid,'zs',idvar) ! from input netcdf file
      write(6,*)"ier=",ier," idvar=",idvar
      if ( ier .ne. 0 ) then
         ier = nf_inq_varid(ncid,'topo',idvar)
         write(6,*)"ier=",ier," idvar=",idvar
      endif

      if ( ier .eq. 0 ) then

         write(6,*)"######",ix,iy,nnx,nny,nmax

         call ncread_2d(ncid,iarch,idvar,ix,iy,datan)  ! zsi(m)

         call amap ( datan, ix, iy, 'gbl zs', 0., 0. )

         call sintp16(datan,ix,iy,zsi_m,sdiag)  ! (m)

         write(6,*)" findxn zsi_m(m)"
         call findxn(zsi_m,ifull,-1.e29,xa,kx,an,kn)

!        if ( an .gt. 2000. ) then
!           write(6,*)"#########################convert m2/s2 to m"
!           do i=1,ifull
!             zsi_m(i)=zsi_m(i)/9.80616
!           enddo ! i=1,ifull
!        endif ! ( an .gt. 2000. ) then

      else
           write(6,*)"No zs data found, setting to -999."
           do i=1,ifull
             zsi_m(i)=-999.
           enddo ! i=1,ifull
      endif ! ier

      call prt_pan(zs,il,jl,2,'zs(m)')
      call prt_pan(zsi_m,il,jl,2,'zsi_m(m)')
      !call prt_pan(zsi_m,il,jl,1,'zsi_m')

      write(6,*)"================================================land"
      write(6,*)"===================================== 1=land 0=ocean"

      ier = nf_inq_varid(ncid,'land',idvar)
      write(6,*)"ier=",ier," idvar=",idvar
      if ( ier .ne. 0 ) then
         ier = nf_inq_varid(ncid,'sfc_lsm',idvar)
         write(6,*)"ier=",ier," idvar=",idvar
      endif

      if ( ier .eq. 0 ) then

         olsm_gbl = .true.

!         call ncread_2d(ncid,iarch,idvar,ix,iy,lsm_gbl)
         call ncread_2d(ncid,1,idvar,ix,iy,lsm_gbl)	! MJT quick fix 

         ! MJT quick fix 
         where (abs(lsm_gbl(:)).ge.1.e10)
           lsm_gbl(:)=0.
         end where

         call amap ( lsm_gbl, ix, iy, 'lsm_gbl', 0., 0. )

         call sintp16(lsm_gbl,ix,iy,lsmg_m,sdiag)

         write(6,*)" findxn model lsmg_m"
         call findxn(lsmg_m,ifull,-1.e29,xa,kx,an,kn)

!        if ( xa .gt. 1.5 ) then
!           write(6,*)"#################convert  so that 0=ocean/1=land"
!           do i=1,ifull
!             lsmg_m(i)=lsmg_m(i)
!           enddo ! i=1,ifull
!        endif ! ( an .gt. 2000. ) then

      else
           write(6,*)"No landmask data found, setting to -999."
           do i=1,ifull
             lsmg_m(i)=-999.
           enddo ! i=1,ifull
      endif ! ier

      call prt_pan(lsmg_m,il,jl,2,'lsmg_m')
      !call prt_pan(lsmg_m,il,jl,1,'lsmg_m')

      write(6,*)"================================================ps"

      ier = nf_inq_varid(ncid,'ps',idvar)
      write(6,*)"ier=",ier," idvar=",idvar
      if ( ier .ne. 0 ) then
         ier = nf_inq_varid(ncid,'sfc_pres',idvar)
         write(6,*)"ier=",ier," idvar=",idvar
      endif

      if ( ier .eq. 0 ) then

         call ncread_2d(ncid,iarch,idvar,ix,iy,datan)

         call amap ( datan, ix, iy, 'gbl sfcp', 0., 0. )

         call sintp16(datan,ix,iy,psg_m,sdiag)

      else
           write(6,*)"No sfcp data found, setting to -999."
           do i=1,ifull
             psg_m(i)=-999.
           enddo ! i=1,ifull
      endif ! ier

      call prt_pan(psg_m,il,jl,2,'psg_m')
      !call prt_pan(psg_m,il,jl,1,'psg_m')

      write(6,*)"================================================tss"

      ier = nf_inq_varid(ncid,'tss',idvar)
      write(6,*)"ier=",ier," idvar=",idvar
      if ( ier .ne. 0 ) then
         ier = nf_inq_varid(ncid,'sfc_temp',idvar)
         write(6,*)"ier=",ier," idvar=",idvar
      endif

      if ( ier .eq. 0 ) then ! we have sfc temp data

        write(6,*)"input data has sfc temp data, now read in"

        call ncread_2d(ncid,iarch,idvar,ix,iy,datan)

        call amap ( datan, ix, iy, 'gbl sfct', 0., 0. )

        spval=-1.e10
        write(6,*)"spval=",spval
        write(6,*)"###################### do we have olsm_gbl=",olsm_gbl
        ijgd=igd+ix*(jgd-1)
        write(6,*)"igd,jgd,ijgd=",igd,jgd,ijgd
        ijd=id+il*(jd-1)
        write(6,*)"id,jd,ijd=",id,jd,ijd

        write(6,*)"prepare to interp. tss for sea and land separately"
        write(6,*)"igd,jgd,gtss=",igd,jgd,datan(ijgd)
        write(6,*)"putting only land values into datan"
        write(6,*)"putting only ocean values into datan(+nmax)"
!not done since tss already at sea level     write(6,*)"First: reduce tss to sea level"

        do j=1,iy
         do i=1,ix
          iq = i+(j-1)*ix

!         write(6,*)i,j,iq,datan(iq) ,lsm_gbl(iq)
!not done since tss already at sea level       datan(iq)=datan(iq)+zs_gbl(iq)*.0065

          datan(iq+nmax)=datan(iq)                          ! for ocean pts

          if(olsm_gbl)then

            !if ( lsm_gbl(iq) .gt. .5 ) then
            if ( lsm_gbl(iq) .lt. .5 ) then
              datan(iq)=spval                               ! land, fill in ocean pts
            else !!!  ( lsm_gbl(iq) .lt. .5 ) then
              datan(iq+nmax)=spval                          ! ocean, fill in land pts
            endif ! ( lsm_gbl(iq) .gt. .5 ) then

          endif!(olsm_gbl)then

         enddo ! ix
        enddo ! iy

        write(6,*)"two global tss arrays with spval=", spval
        write(6,*)"igd,jgd,lgtss=",igd,jgd,datan(ijgd)
        write(6,*)"igd,jgd,ogtss=",igd,jgd,datan(ijgd+nmax)

        write(6,*)"fill in missing values"

        write(6,*)"=======> for land array, fill in tss ocean values"
        call fill(datan,ix,iy,.1*spval,datan(1+2*nmax))

        if(olsm_gbl)then
           write(6,*)"=======> for ocean array, fill in tss land values"
           call fill(datan(1+nmax),ix,iy,.1*spval,datan(1+2*nmax))
        endif!(olsm_gbl)then

        write(6,*)"igd,jgd,lgtss=",igd,jgd,datan(ijgd)
        write(6,*)"igd,jgd,ogtss=",igd,jgd,datan(ijgd+nmax)


!not done since tss already at sea level     write(6,*)"tss at sea level here"

        write(6,*)"=========================> now interp. land data"
        call sintp16(datan,ix,iy,sfct,sdiag)                 ! land

        if(olsm_gbl)then
          write(6,*)"=========================> now interp. ocean data"
           call sintp16(datan(1+nmax),ix,iy,sfcto_m,sdiag)   ! ocean
        endif!(olsm_gbl)then

        call prt_pan(sfct   ,il,jl,2,'tss')
        call prt_pan(sfcto_m,il,jl,2,'tsso')

        write(6,*)"id,jd,ltss=",id,jd,sfct(ijd)
        write(6,*)"id,jd,otss=",id,jd,sfcto_m(ijd)

        if(olsm_gbl)then

          write(6,*)"now recombine two (land/ocean) fields"
!not done since tss already at sea level     write(6,*)"Also need to recompute tss at zs"

          do j=1,jl
           do i=1,il
            iq=i+(j-1)*il
!not done since tss already at sea level  sfct(i,j)=sfct(i,j)-zs(iq)*.0065
!not done since tss already at sea level  sfctl_m(i,j)=sfctl_m(i,j)-zs(iq)*.0065

! remeber, land < .5 is an ocean point
            if ( lsm_m(iq) .lt. .5 ) sfct(iq)=sfcto_m(iq)  ! set to ocean interp pnt

           enddo ! i
          enddo ! j

        endif!(olsm_gbl)then

        write(6,*)"id,jd,sfct=",id,jd,sfct(ijd)

        write(6,*)" findxn model sfct"
        call findxn(sfct,ifull,-1.e29,xa,kx,an,kn)

      else

        write(6,*)"###################no sfc temp data in input dataset"
        write(6,*)"###################setting sfc temp data to 0!!!!!!!"
        do j=1,jl
         do i=1,il
          iq=i+(j-1)*il
          sfct(iq)=0.
         enddo ! i
        enddo ! j

      endif ! ier eq 0 , sfct

      call prt_pan(sfct,il,jl,2,'sfct')
      !call prt_pan(sfct,il,jl,1,'sfct')

!############################################################################
! end sfc data
!############################################################################

      write(6,*)"check of temp data to ensure all is going okay"
      write(6,*)" findxn model temp(1)"
      call findxn(temp(1,1,1),ifull,-1.e29,xa,kx,an,kn)
      write(6,*)" findxn model temp(nplev)"
      call findxn(temp(1,1,nplev),ifull,-1.e29,xa,kx,an,kn)

      write(6,*)"nplev=",nplev
c constrain rh to 0-100
        do k=1,nplev
         do j=1,jl
          do i=1,il
           rh(i,j,k)=min(100.,max(0.,rh(i,j,k)))
          enddo ! i
         enddo ! j
        enddo ! k

!############### fix winds if CC grid ###############################
       if ( ogbl ) then

c     here use unstaggered lats and lons for u and v
c     For calculating zonal and meridional wind components, use the
c     following information, where theta is the angle between the
c     (ax,ay,az) vector [along the xg axis] and the zonal-component-vector:
c     veczon = k x r, i.e. (-y,x,0)/sqrt(x**2 + y**2)
c     vecmer = r x veczon, i.e. (-xz,-yz,x**2 + y**2)/sqrt(x**2 + y**2)
c     costh is (veczon . a) = (-y*ax + x*ay)/sqrt(x**2 + y**2)
c     sinth is (vecmer . a) = [-xz*ax - yz*ay + (x**2 + y**2)*az]/sqrt
c      using (r . a)=0, sinth collapses to az/sqrt(x**2 + y**2)
c     For rotated coordinated version, see JMcG's notes

      coslong=cos(rlong0*pi/180.)
      sinlong=sin(rlong0*pi/180.)
      coslat=cos(rlat0*pi/180.)
      sinlat=sin(rlat0*pi/180.)
      polenx=-coslat
      poleny=0.
      polenz=sinlat

      write(6,*)'polenx,poleny,polenz ',polenx,poleny,polenz
      write(6,*)'x(1),y(1),z(1)',x(1),y(1),z(1)
      write(6,*)'ax(1),ay(1),az(1)',ax(1),ay(1),az(1)
      write(6,*)'bx(1),by(1),bz(1)',bx(1),by(1),bz(1)

      write(6,*)'before zon/meridional'

      call maxmin(u,' u',0,1.)
      call maxmin(v,' v',0,1.)
      !call maxmin(hgt,' hgt',0,.001)
      !call maxmin(temp,' temp',0,1.)
      !call maxmin(rh,' rh',0,1000.)

      !call prt_pan(u(1,1, 1),il,jl,2,'u : 1')
      !call prt_pan(v(1,1, 1),il,jl,2,'v : 1')

      imidpan2 = il/2+(jk+jl/2-1)*il
      do k=1,nplev
        write(6,*)'k,u/v(imidpan2,1,k)',u(imidpan2,1,k),v(imidpan2,1,k)
      enddo

      write(6,*)"convert winds to CCAM grid convention"

      cx=-1.e29
      sx=-1.e29
      cn= 1.e29
      sn= 1.e29


      do iq=1,ifull
c       set up unit zonal vector components
        zonx=            -polenz*y(iq)
        zony=polenz*x(iq)-polenx*z(iq)
        zonz=polenx*y(iq)
        den=sqrt( max(zonx**2 + zony**2 + zonz**2,1.e-7) )  ! allow for poles
        costh= (zonx*ax(iq)+zony*ay(iq)+zonz*az(iq))/den
        sinth=-(zonx*bx(iq)+zony*by(iq)+zonz*bz(iq))/den
        cx=max(cx,costh)
        sx=max(sx,sinth)
        cn=min(cn,costh)
        sn=min(sn,sinth)
        do k=1,nplev
           uzon = u(iq,1,k)
           vmer = v(iq,1,k)
           u(iq,1,k)= costh*uzon+sinth*vmer
           v(iq,1,k)=-sinth*uzon+costh*vmer
           if(iq.eq.imidpan2)then
             write(6,'("before zon/mer; k,u,v: ",i3,2f10.2)')k,uzon,vmer
             write(6,'("zonx,zony,zonz,den,costh,sinth",
     &                6f8.4)')zonx,zony,zonz,den,costh,sinth
             write(6,'("after zon/mer; k,u,v: ",i3,2f10.2)')
     &                        k,u(iq,1,k),v(iq,1,k)
           endif
        enddo  ! k loop
      enddo      ! iq loop

      write(6,*)'cx,cn,sx,sn=',cx,cn,sx,sn
      write(6,*)'after zon/meridional'

      call maxmin(u,' u',0,1.)
      call maxmin(v,' v',0,1.)
      call maxmin(hgt,' hgt',0,.001)
      call maxmin(temp,' temp',0,1.)
      call maxmin(rh,' rh',0,1.)

      !call prt_pan(u(1,1, 1),il,jl,2,'u : 1')
      !call prt_pan(v(1,1, 1),il,jl,2,'v : 1')

!############### fix winds if DARLAM grid ###############################
       else ! not ogbl

c convert e-w/n-s lat/lon winds to model winds
c loop over all model grid points
        do k=1,nplev
         write(6,*)k,temp(1,1,k),u(1,1,k),v(1,1,k)
         do j=1,jl
          do i=1,il
c get lat lon of model grid ( just to get ther )
           call lconll(rlon,rlat,float(i),float(j))
c calculate ucmp l.c.winds
c ulc=v@u*s(th)+u@u*c(th)
           ull = u(i,j,k)
           vll = v(i,j,k)
           u(i,j,k)=vll*sin(ther)+ull*cos(ther)
c calculate vcmp l.c.winds
c vlc=v@v*c(th)-u@v*s(th)
           v(i,j,k)=vll*cos(ther)-ull*sin(ther)
          enddo ! i
         enddo ! j
         write(6,*)k,temp(1,1,k),u(1,1,k),v(1,1,k)
        enddo ! k

      endif ! not ogbl

      i=il/2
      j=jl/2
      write(6,'(6a10," at i,j=",2i3)') "p","z","t","u","v","rh",i,j
      write(6,*)"invert order of plev  nplev=",nplev
      write(6,'(6a10)')"plev","hgt","temp","u","v","rh/mr"
      do k=1,nplev
          cplev(k)=plev(nplev+1-k)
          write(6,'(5f10.2,f10.5)') cplev(k),hgt(i,j,k),temp(i,j,k)
     &                       ,u(i,j,k),v(i,j,k),rh(i,j,k)
      enddo ! k=1,nplev

      iq=il/2+(jl/2-1)*il
      write(6,'("pmsl=",f12.2," sfct=",f12.2)') pmsl(iq),sfct(iq)

      write(6,*)"calling vidar now!! ntimes,iarch=",ntimes,iarch

      if2=0

!#######################################################################
      call vidar(nplev,hgt,temp,u,v,rh
     &     ,iyr,imn,idy,ihr,iarch,time,mtimer,cplev,io_out)
!#######################################################################

      enddo ! narch

      write(6,*)'*********** Finished cdfvidar ************************'

      stop
      end ! cdfvidar
c***************************************************************************
      subroutine ncread_2d(idhist,iarch,idvar,il,jl,var)

      include 'gblparm.h'
      include 'netcdf.inc'

      integer start(3),count(3)

      real var(il*jl), addoff, sf
      integer*2 ivar(nnx*nny)
      character*30 name

      write(6,*)"ncread_2d idhist=",idhist
      write(6,*)"iarch=",iarch," idvar=",idvar
      write(6,*)"il=",il," jl=",jl," nnx,nny=",nnx,nny

c read name
      ier = nf_inq_varname(idhist,idvar,name)
      write(6,*)"ier=",ier," name=",name

      if(ier.eq.0)then

        if(il*jl.gt.nnx*nny)stop "ncread_2d il*jl.gt.nnx*nny"

        start(1) = 1
        start(2) = 1
        start(3) = iarch
        count(1) = il
        count(2) = jl
        count(3) = 1

c       write(6,'("start=",4i4)') start
c       write(6,'("count=",4i4)') count

      ier = nf_inq_vartype(idhist,idvar,itype)
      write(6,*)"itype=",itype," ier=",ier

      if ( itype .eq. nf_short ) then
         write(6,*)"variable is short"
         call ncvgt(idhist,idvar,start,count,ivar,ier)
         write(6,*)"ivar(1)=",ivar(1)," ier=",ier
         write(6,*)"ivar(il*jl)=",ivar(il*jl)
      else if ( itype .eq. nf_float ) then
         write(6,*)"variable is float"
         call ncvgt(idhist,idvar,start,count,var,ier)
         write(6,*)"var(1)=",var(1)," ier=",ier
         write(6,*)"var(il*jl)=",var(il*jl)
      else
         write(6,*)"variable is unknown"
         stop
      endif

c obtain scaling factors and offsets from attributes
        call ncagt(idhist,idvar,'add_offset',addoff,ier)
        if ( ier.ne.0 ) addoff=0.
        write(6,*)"ier=",ier," addoff=",addoff

        call ncagt(idhist,idvar,'scale_factor',sf,ier)
        if ( ier.ne.0 ) sf=1.
        write(6,*)"ier=",ier," addoff=",addoff

      else!(ier.eq.0)then
c no data found
        do i=1,il*jl
         var(i)=0
        enddo
        sf=0.
        addoff=0.
      endif!(ier.eq.0)then

c unpack data
      dx=-1.e29
      dn= 1.e29
      do j=1,il
        do i=1,il
          ij=i+(j-1)*il
      	  if ( itype .eq. nf_short ) then
           if(i.eq.1.and.j.eq.1)
     &      write(6,*)"ivar,sf,addoff=",ivar(ij),sf,addoff
            var(ij) = ivar(ij)*sf + addoff
          else
           if(i.eq.1.and.j.eq.1)
     &      write(6,*)"var,sf,addoff=",var(ij),sf,addoff
            var(ij) = var(ij)*sf + addoff
          endif
          dx=max(dx,var(ij))
          dn=min(dn,var(ij))
        end do
      end do

      write(6,*)"ncread_2d idvar=",idvar," iarch=",iarch
      write(6,*)"ncread_2d dx=",dx," dn=",dn

      return ! ncread_2d
      end
c***************************************************************************
      subroutine ncread_3d(idhist,iarch,idvar,il,jl,kl,var)
c             call ncread_3d(ncid,iarch,idvar,ix,iy,nplev,datan)

      include 'gblparm.h'
      include 'netcdf.inc'

      integer start(4),count(4)

      integer*2 ivar(nmax*35)
      real var(il*jl*kl)
      character*30 name

      write(6,*)"ncread_2d idhist=",idhist
      write(6,*)"iarch=",iarch," idvar=",idvar
      write(6,*)"il=",il," jl=",jl," nnx,nny=",nnx,nny

      ier = nf_inq_varname(idhist,idvar,name)
      write(6,*)"ier=",ier," name=",name

      start(1) = 1
      start(2) = 1
      start(3) = 1
      start(4) = iarch

      count(1) = il
      count(2) = jl
      count(3) = kl
      count(4) = 1

      write(6,'("start=",4i4)') start
      write(6,'("count=",4i4)') count

c read data
      write(6,*)"idhist=",idhist," idvar=",idvar
      ier = nf_inq_vartype(idhist,idvar,itype)
      write(6,*)"ier=",ier," itype=",itype

      if ( itype .eq. nf_short ) then
         write(6,*)"variable is short"
         call ncvgt(idhist,idvar,start,count,ivar,ier)
      else if ( itype .eq. nf_float ) then
         write(6,*)"variable is float"
         call ncvgt(idhist,idvar,start,count,var,ier)
      else
         write(6,*)"variable is unknown"
         stop
      endif

c obtain scaling factors and offsets from attributes
      call ncagt(idhist,idvar,'add_offset',addoff,ier)
      if ( ier.ne.0 ) addoff=0.
      write(6,*)"ier=",ier," addoff=",addoff

      call ncagt(idhist,idvar,'scale_factor',sf,ier)
      if ( ier.ne.0 ) sf=1.
      write(6,*)"ier=",ier," sf=",sf

c unpack data
      dx=-1.e29
      dn= 1.e29
      do k=1,kl
       do j=1,jl
        do i=1,il
          ijk=i+(j-1)*il+(k-1)*il*jl
          if(i.eq.1.and.j.eq.1.and.k.eq.1)
     &       write(6,*)"i,j,k,ijk=",i,j,k,ijk
      	  if ( itype .eq. nf_short ) then
           if(i.eq.1.and.j.eq.1.and.k.eq.1)
     &      write(6,*)"ivar,sf,addoff=",ivar(ijk),sf,addoff
            var(ijk) = ivar(ijk)*sf + addoff
          else
           if(i.eq.1.and.j.eq.1.and.k.eq.1)
     &      write(6,*)"var,sf,addoff=",var(ijk),sf,addoff
            var(ijk) = var(ijk)*sf + addoff
          endif
          if(i.eq.1.and.j.eq.1.and.k.eq.1)
     &      write(6,*)"var=",var(ijk)
          dx=max(dx,var(ijk))
          dn=min(dn,var(ijk))
        end do
       end do
      end do

      write(6,*)"ncread_3d idvar=",idvar," iarch=",iarch
      write(6,*)"ncread_3d dx=",dx," dn=",dn

      return ! ncread_3d
      end
c***********************************************************************
      subroutine filt_nc(var,il,jl,kl)

      real var(il,jl,kl)

      write(6,*) "filt_nc"

!     do k=1,kl
!      do j=1,jl
!       do i=1,il
!         var(i,j,k) = var(i,j,k)
!       end do
!      end do
!     end do

      return ! filt_nc
      end
!***********************************************************************
      function icmonth_to_imn(cmonth)

      integer icmonth_to_imn
      character*(*) cmonth

      write(6,*)"icmonth_to_imn cmonth=",cmonth

      icmonth_to_imn=0
      if ( cmonth.eq.'jan' ) icmonth_to_imn=1
      if ( cmonth.eq.'feb' ) icmonth_to_imn=2
      if ( cmonth.eq.'mar' ) icmonth_to_imn=3
      if ( cmonth.eq.'apr' ) icmonth_to_imn=4
      if ( cmonth.eq.'may' ) icmonth_to_imn=5
      if ( cmonth.eq.'jun' ) icmonth_to_imn=6
      if ( cmonth.eq.'jul' ) icmonth_to_imn=7
      if ( cmonth.eq.'aug' ) icmonth_to_imn=8
      if ( cmonth.eq.'sep' ) icmonth_to_imn=9
      if ( cmonth.eq.'oct' ) icmonth_to_imn=10
      if ( cmonth.eq.'nov' ) icmonth_to_imn=11
      if ( cmonth.eq.'dec' ) icmonth_to_imn=12

      write(6,*)"icmonth_to_imn=",icmonth_to_imn

      return 
      end
!***********************************************************************
