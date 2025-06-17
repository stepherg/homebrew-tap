class Linenoise < Formula
  desc "Small self-contained alternative to readline and libedit"
  homepage "https://github.com/antirez/linenoise"
  url "https://github.com/antirez/linenoise/archive/97e3ebb18d15624e3b5e7b9d5b376839cafc5a09.tar.gz"
  version "0.0.1" # Pseudo-version since no official releases
  sha256 "f49dc120a7d66a29969e9ed23dc34b4a50692e894d37b855caea1a698d013886"
  license "BSD-2-Clause"

  def install
    # Compile linenoise.c into a shared library
    system ENV.cc, "-shared", "-fPIC", "-arch", "arm64", "-o", "liblinenoise.dylib", "linenoise.c"
    # Install library and header
    lib.install "liblinenoise.dylib"
    include.install "linenoise.h"
  end

  test do
    # Basic test to verify library linking
    (testpath/"test.c").write <<~EOS
      #include <stdio.h>
      #include <linenoise.h>
      int main() {
        linenoiseHistoryAdd("test");
        return 0;
      }
    EOS
    system ENV.cc, "test.c", "-L#{lib}", "-llinenoise", "-o", "test"
    system "./test"
  end
end


