#!/bin/sh
#
#     @(#)spm_MAKE.sh	2.21 JA, mods by Matthew Brett 99/11/04
#
# spm_MAKE.sh will compile spm*.c scripts in a platform specific fashion
# see mex
#
# default compilation is for Sun cc
# pass string to script from list below for other compile types
# e.g. ./spm_MAKE.sh windows

if [ $# = 0 ]; then
	arch="sun";
else
	if [ $1 = "--help" ]; then
		echo "spm_MAKE [architecture/compiler]"
		echo "Call with architecture/compiler as argument, where"
		echo "architecture/compiler may be:"
		echo "   sun (default)   - Sun (SunOS, solaris) ?DEC, using cc"
		echo "   windows         - windows (NT, 95/98), using EGCS gcc"
		echo "   gcc             - gcc compile for unix, including Sun, linux"
		echo "   sgi             - Irix 32 bit compile with cc"
		echo "   sgi64           - Irix 64 bit compile with cc"
		echo "   hpux            - ?HPUX (HP) or ??AIX (IBM) compile with cc"
		exit
	else
		arch=$1;
	fi
fi

echo
echo "SPM mex file compile for $arch"
echo 

added_objs="spm_mapping.o"

case $arch in
    sun)
	echo "(default) unix compile for Sun CC"
	echo ""
	CC="cc -xO5"
	cmex5="mex     COPTIMFLAGS=-xO5"
	cmex4="mex -V4 COPTIMFLAGS=-xO5";;
    windows)
	echo "Windows compile with EGCS gcc/mingw32"
	echo "see http://www.mrc-cbu.cam.ac.uk/Imaging/gnumex20.html"
	echo "for instructions about installing gcc for"
	echo "compiling Mex files."
	echo ""
	deff=-DSPM_WIN32
	CC="gcc -mno-cygwin $deff"
	cmex5="mex.bat $deff "
	cmex4="mex.bat $deff -V4 "
	# Windows added utility files
	$CC -c -o win32mmap.o win32mmap.c
	$cmex5 spm_win32utils.c
	added_objs="win32mmap.o spm_mapping.obj";;
    gcc)
	echo "optimised standard unix compile for gcc"
	echo "this should work on Sun, Linux etc"
	echo "Note that the path to the gccopts.sh file may need"
	echo "changing."
	echo ""
	CC="gcc -O2"
	cmex5="mex     COPTIMFLAGS=-O2 -f gccopts.sh"
	cmex4="mex -V4 COPTIMFLAGS=-O2 -f gccopts.sh";;
    sgi)
	# unix compile for CC
	echo "Feedback from users with R10000 O2 and R10000 Indigo2 systems"
	echo "running IRIX6.5 suggests that the cmex program with Matlab 5.x"
	echo "compiles with the old 32bit (o32) instruction set (MIPS2) only,"
	echo "while cc by default compiles with the new32 bit (n32 or MIPS4)."
	echo "Matlab 5.x only likes o32 for O2 R10000 systems."
	echo ""
	echo "We also suggest you modify your options file mexopts.sh in"
	echo 'the sgi section: change LD="ld" to LD="ld -o32"'
	echo "this tells the linker to use o32 instead of n32."
	echo ""
	CC="cc -mips2 -O"
	cmex5="mex"
	cmex4="mex -V4";;
    sgi64)
	echo "not optimised sgi 64 bit compile for CC"
	echo ""
	CC="cc -mips4 -64"
	cmex5="mex"
	cmex4="mex -V4";;
    hpux)
	echo "unix compile for hpux cc, and maybe aix cc"
	echo ""
	echo "Under HPUX 10.20 with MATLAB 5.2.1 and gcc, you may wish"
	echo "to modify this spm_MAKE.sh file to say something like:"
	echo '	CC    = "gcc -O -fpic"'
	echo '	cmex5 = "mex COPTIMFLAGS=-O -f gccopts.sh";;'
	echo "where the gccopts.sh file is modified to remove the +z"
	echo "(which is used with version 9.0 and possibly also 10.0)."
	echo ""
	CC="cc -O +z -Ae +DAportable"
	cmex5="mex     COPTIMFLAGS=-O"
	cmex4="mex -V4 COPTIMFLAGS=-O";;
   *)
	echo "Sorry, not set up for architecture $arch"
	exit;;
esac


echo "Compiling volume utilities..."
$CC -c -o utils_uchar.o		spm_vol_utils.c -DSPM_UNSIGNED_CHAR
$CC -c -o utils_short.o		spm_vol_utils.c -DSPM_SIGNED_SHORT
$CC -c -o utils_int.o		spm_vol_utils.c -DSPM_SIGNED_INT
$CC -c -o utils_schar.o		spm_vol_utils.c -DSPM_SIGNED_CHAR
$CC -c -o utils_ushort.o	spm_vol_utils.c -DSPM_UNSIGNED_SHORT
$CC -c -o utils_uint.o		spm_vol_utils.c -DSPM_UNSIGNED_INT
$CC -c -o utils_float.o		spm_vol_utils.c -DSPM_FLOAT
$CC -c -o utils_double.o	spm_vol_utils.c -DSPM_DOUBLE

# Byteswapped images
$CC -c -o utils_short_s.o	spm_vol_utils.c -DSPM_SIGNED_SHORT -DSPM_BYTESWAP
$CC -c -o utils_int_s.o		spm_vol_utils.c -DSPM_SIGNED_INT -DSPM_BYTESWAP
$CC -c -o utils_ushort_s.o	spm_vol_utils.c -DSPM_UNSIGNED_SHORT -DSPM_BYTESWAP
$CC -c -o utils_uint_s.o	spm_vol_utils.c -DSPM_UNSIGNED_INT -DSPM_BYTESWAP
$CC -c -o utils_float_s.o	spm_vol_utils.c -DSPM_FLOAT -DSPM_BYTESWAP
$CC -c -o utils_double_s.o	spm_vol_utils.c -DSPM_DOUBLE -DSPM_BYTESWAP

$CC -c -o spm_make_lookup.o spm_make_lookup.c
$CC -c -o spm_getdata.o spm_getdata.c
$CC -c -o spm_vol_access.o  spm_vol_access.c 

# utility routine
$cmex5 -c spm_mapping.c

vol_utils="utils_uchar.o utils_short.o utils_int.o utils_float.o utils_double.o \
	utils_schar.o utils_ushort.o utils_uint.o \
	utils_short_s.o utils_int_s.o utils_float_s.o utils_double_s.o \
	utils_ushort_s.o utils_uint_s.o \
	spm_vol_access.o spm_make_lookup.o spm_getdata.o $added_objs"

echo "Adding to archive library spm_vol_utils.a..."
\rm spm_vol_utils.a
ar rcv spm_vol_utils.a $vol_utils
\rm $vol_utils

echo "Compiling mex files..."
$cmex5 spm_sample_vol.c	spm_vol_utils.a 
$cmex5 spm_slice_vol.c	spm_vol_utils.a 
$cmex5 spm_brainwarp.c	spm_vol_utils.a spm_matfuns.c
$cmex5 spm_add.c	spm_vol_utils.a 
$cmex5 spm_conv_vol.c	spm_vol_utils.a 
$cmex5 spm_render_vol.c	spm_vol_utils.a 
$cmex5 spm_global.c	spm_vol_utils.a 
$cmex5 spm_resels_vol.c	spm_vol_utils.a 
$cmex5 spm_getxyz.c	spm_vol_utils.a 

$cmex5 spm_atranspa.c
$cmex5 spm_list_files.c
$cmex5 spm_unlink.c
$cmex5 spm_kronutil.c
$cmex5 spm_project.c
$cmex5 spm_hist2.c

$cmex5 spm_max.c
$cmex5 spm_clusters.c

echo "Done."
