#!/bin/bash

#build script for CABLE
#Simplified from previous build script. Only set up for raijin 
#Usage: 
#> ./build3
#   OR
#> ./build3 mpi
#builds MPI version of CABLE

## gadi.nci.org.au
host_gadi()
{
   . /etc/bashrc
   module purge
   module add intel-compiler/2019.5.281
   module add netcdf/4.6.3
   # This is required so that the netcdf-fortran library is discoverable by
   # pkg-config:
   prepend_path PKG_CONFIG_PATH "${NETCDF_BASE}/lib/Intel/pkgconfig"

   if ! pkg-config --exists netcdf-fortran; then
       echo -e "\nUnable to find netcdf-fortran via pkg-config. Exiting...\n"
       exit 1
   fi

   if [[ $1 = 'mpi' ]]; then
      module add intel-mpi/2019.5.281
      export FC='mpif90'
   else
      export FC='ifort'
   fi

   CFLAGS="-O2 -fp-model precise"
   
   if [[ $1 = 'MGK' ]]; then
      CFLAGS='-O2'
   fi

   if [[ $1 = 'debug' ]]; then
      CFLAGS='-O0 -traceback -g -fp-model precise -ftz -fpe0'
      #CFLAGS='-O0 -traceback -g -fp-model precise -ftz -fpe0 -check all,noarg_temp_created'
   fi

   CFLAGS+=" $(pkg-config --cflags netcdf-fortran)"
   export CFLAGS
   LDFLAGS=$(pkg-config --libs netcdf-fortran)
   export LDFLAGS
   
   if [[ $1 = 'mpi' ]]; then
    build_build mpi
   else
    build_build
   fi 
   cd ../
   build_status
}

clean_build()
{
      rm -fr .tmp
      echo  ''
      echo  'cleaning up'
      echo  ''
      echo  'Press Enter too continue buiding, Control-C to abort now.'
      echo  ''
      read dummy
}


build_build()
{
   if [[ ! -d .tmp ]]; then
      mkdir .tmp
   fi

   if [[ -f cable ]]; then
      echo  ''
      echo  'cable executable exists. copying to dated backup file'
      echo  ''
      mv cable cable.`date +%d.%m.%y`
   fi

   # directories contain source code
   ALB="../science/albedo"
   RAD="../science/radiation"
   CAN="../science/canopy"
   CNP="../science/casa-cnp"
   GWH="../science/gw_hydro"
   MIS="../science/misc"
   ROU="../science/roughness"
   SOI="../science/soilsnow"
   LUC="../science/landuse"
   OFF="../offline"
   UTI="../util"
   PAR="../params"
   SLI="../science/sli"
   POP="../science/pop"
   /bin/cp -p $ALB/*90 ./.tmp
   /bin/cp -p $CAN/*90 ./.tmp
   /bin/cp -p $CNP/*90 ./.tmp
   /bin/cp -p $GWH/*90 ./.tmp
   /bin/cp -p $MIS/*90 ./.tmp
   /bin/cp -p $RAD/*90 ./.tmp
   /bin/cp -p $ROU/*90 ./.tmp
   /bin/cp -p $SOI/*90 ./.tmp
   /bin/cp -p $SLI/*90 ./.tmp
   /bin/cp -p $POP/*90 ./.tmp
   /bin/cp -p $LUC/*90 ./.tmp
   /bin/cp -p $OFF/*90 ./.tmp

/bin/cp -p $UTI/*90 ./.tmp
/bin/cp -p $PAR/*90 ./.tmp

/bin/cp -p Makefile  ./.tmp

cd .tmp/

echo  ''
echo "Build setup complete." 
echo  'Compiling now ...'
echo  ''

echo  ''
echo  'Building from source common across serial and MPI applications'
echo  ''
echo  ''
echo  'Building drivers for either serial or MPI application'
echo  ''

if [[ $1 = 'mpi' ]]; then
    make mpi
else
    make
fi

}

build_status()
{
   if [[ -f .tmp/cable ]]; then
   	mv .tmp/cable .
    echo  ''
   	echo 'BUILD OK'
    echo  ''
   elif [[ -f .tmp/cable-mpi ]]; then
   	mv .tmp/cable-mpi .
    echo  ''
   	echo  'BUILD OK'
    echo  ''
   else
      echo  ''
      echo 'Oooops. Something went wrong'
      echo  ''
   fi
   exit
}
###########################################
## build.ksh - MAIN SCRIPT STARTS HERE   ##
###########################################

if [[ $1 = 'clean' ]]; then
   clean_build
fi

if [[ $1 = 'mpi' ]]; then
  echo  ''
  echo "Building cable_mpi" 
  echo  ''
	host_gadi mpi
else
  echo  ''
  echo "Building cable (serial)" 
  echo  ''
	host_gadi $1
fi
