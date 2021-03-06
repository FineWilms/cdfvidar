
ifneq ($(CUSTOM),yes)
FC = ifort
LIBS = -L $(NETCDF_ROOT)/lib -lnetcdf -lnetcdff
INC = -I $(NETCDF_ROOT)/include
FFLAGS =
PPFLAG90 = -fpp
PPFLAG77 = -fpp
endif

ifeq ($(GFORTRAN),yes)
FC = gfortran
PPFLAG90 = -x f95-cpp-input
PPFLAG77 = -x f77-cpp-input
endif

OBJ2= dryadj.o findxn.o filt.o sintp16.o vidar.o invert.o\
      cdfvidar.o vispl.o esmtrv.o amap.o mslp.o lconset.o \
      maxmin.o fill.o outcdf.o prt_pan.o \
      setxyz_m.o ccinterp.o jimcc_m.o \
      latltoij_m.o xyzinfo_m.o newmpar_m.o indices_m.o \
      parm_m.o precis_m.o ind_m.o jimco_m.o jim_utils.o nfft_m.o \
      latlong_m.o comsig_m.o cll_m.o sigdata_m.o netcdf_m.o

cdfvidar : $(OBJ2)
	$(FC) $(FFLAGS) $(OBJ2) $(LIBS) -o cdfvidar

clean:
	rm -f *.o core cdfvidar *.mod

.SUFFIXES:.f90
.f.o:
	$(FC) -c $(FFLAGS) $(INC) $(PPFLAG77) $<
.f90.o:
	$(FC) -c $(FFLAGS) $(INC) $(PPFLAG90) $<
%.o : %.mod

cdfvidar.o sintp16.o setxyz.o: latlong_m.o
cdfvidar.o vidar.o : comsig_m.o
cdfvidar.o outcdf.o : cll_m.o
cdfvidar.o vidar.o : sigdata_m.o
cdfvidar.o : ccinterp.o
cdfvidar.o vispl.o dryadj.o : lmax.h
cdfvidar.o vidar.o vispl.o : nplevs.h
cdfvidar.o vidar.o : vidar.h
cdfvidar.o outcdf.o : netcdf_m.o
utilities.o : utilities.f90
ccinterp.o : ccinterp.f90 setxyz_m.o xyzinfo_m.o latltoij_m.o newmpar_m.o indices_m.o precis_m.o
latltoij_m.o : latltoij_m.f90 xyzinfo_m.o newmpar_m.o precis_m.o
setxyz_m.o : setxyz_m.f90 newmpar_m.o indices_m.o parm_m.o precis_m.o ind_m.o xyzinfo_m.o jimco_m.o jimcc_m.o 
xyzinfo_m.o : xyzinfo_m.f90 precis_m.o
newmpar_m.o : newmpar_m.f90 
precis_m.o : precis_m.f90
indices_m.o : indices_m.f90
parm_m.o : parm_m.f90 precis_m.o 
ind_m.o : ind_m.f90 newmpar_m.o 
jimcc_m.o : jimcc_m.f90 parm_m.o precis_m.o 
jimco_m.o : jimco_m.f90 precis_m.o jim_utils.o nfft_m.o 
jim_utils.o : jim_utils.f90 precis_m.o 
nfft_m.o : nfft_m.f90 precis_m.o 
