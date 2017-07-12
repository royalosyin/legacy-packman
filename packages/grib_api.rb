class Grib_api < PACKMAN::Package
  url 'https://software.ecmwf.int/wiki/download/attachments/3473437/grib_api-1.23.0-Source.tar.gz'
  sha1 '2764b262c8f081fefb81112f7f7463a3a34b6e66'
  version '1.23.0'

  depends_on :netcdf_c
  depends_on :jasper
  # Openjpeg can only be download from Google Code which is blocked by our great nation!
  # depends_on :openjpeg

  def install
    args = %W[
      --prefix=#{prefix}
      --with-netcdf=#{link_root}
      --with-jasper=#{link_root}
    ]
    if PACKMAN.cygwin?
      args << "LIBS='-lcurl -lhdf5_hl -lhdf5 -lsz -lz'"
    end
    PACKMAN.run './configure', *args
    PACKMAN.replace 'fortran/Makefile', {
      /(\$\(FC\) \$\(FCFLAGS\) -o grib_types grib_types\.o grib_fortran_kinds\.o)/ => '\1 $(LDFLAGS)'
    }
    PACKMAN.run 'make install'
  end
end
