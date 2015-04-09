module PACKMAN
  class LlvmCompiler < Compiler
    vendor 'llvm'
    compiler_command 'c'       => ['clang',   '-O2']
    compiler_command 'c++'     => ['clang++', '-O2']
    compiler_command 'fortran' => [nil,       nil]
    flag :rpath => -> rpath { "-Wl,-rpath,#{rpath}" }
    flag :cxxlib => '-lc++'
    check :version do |command|
      `#{command} -v 2>&1`.match(/(\d+\.\d+)/)[1]
    end
  end
end
