class Linenoise < Formula
  desc "Small self-contained alternative to readline and libedit"
  homepage "https://github.com/antirez/linenoise"
  url "https://github.com/antirez/linenoise/archive/d895173d679be70bcd8b23041fff3e458e1a3506.tar.gz"
  version "0.0.1" # Pseudo-version since no official releases
  sha256 "839ed407fe0dfa5fd7dd103abfc695dee72fea2840df8d4250ad42b0e64839e8"
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


