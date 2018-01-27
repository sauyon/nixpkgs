{ stdenv, fetchurl, python, buildPythonPackage
, numpy, hdf5, cython, six, pkgconfig
, mpi4py ? null, openssh }:

assert hdf5.mpiSupport -> mpi4py != null && hdf5.mpi == mpi4py.mpi;

with stdenv.lib;

let
  mpi = hdf5.mpi;
  mpiSupport = hdf5.mpiSupport;

in buildPythonPackage rec {
  version = "2.7.1";
  pname = "h5py";
  name = "${pname}-${version}";

  src = fetchurl {
    url = "mirror://pypi/h/h5py/${name}.tar.gz";
    sha256 = "180a688311e826ff6ae6d3bda9b5c292b90b28787525ddfcb10a29d5ddcae2cc";
  };

  configure_flags = "--hdf5=${hdf5}" + optionalString mpiSupport " --mpi";

  postConfigure = ''
    ${python.executable} setup.py configure ${configure_flags}

    # Needed to run the tests reliably. See:
    # https://bitbucket.org/mpi4py/mpi4py/issues/87/multiple-test-errors-with-openmpi-30
    ${optionalString mpiSupport "export OMPI_MCA_rmaps_base_oversubscribe=yes"}
  '';

  preBuild = if mpiSupport then "export CC=${mpi}/bin/mpicc" else "";

  nativeBuildInputs = [ pkgconfig ];
  buildInputs = [ hdf5 cython ]
    ++ optional mpiSupport mpi
    ;
  propagatedBuildInputs = [ numpy six]
    ++ optionals mpiSupport [ mpi4py openssh ]
    ;

  meta = {
    description =
      "Pythonic interface to the HDF5 binary data format";
    homepage = http://www.h5py.org/;
    license = stdenv.lib.licenses.bsd2;
  };
}
