class Linenoise < Formula
  desc "Small self-contained alternative to readline and libedit"
  homepage "https://github.com/antirez/linenoise"
  url "https://github.com/antirez/linenoise/archive/d895173d679be70bcd8b23041fff3e458e1a3506.tar.gz"
  sha256 "839ed407fe0dfa5fd7dd103abfc695dee72fea2840df8d4250ad42b0e64839e8"
  license "BSD-2-Clause"
  head "https://github.com/antirez/linenoise.git", branch: "master"

  livecheck do
    skip "No tagged releases" # upstream has no version tags
  end

  def install
    # Build a dynamic library (macOS prefers -dynamiclib over -shared)
    system ENV.cc, "-fPIC", "-dynamiclib", "linenoise.c", "-o", "liblinenoise.dylib",
                   "-install_name", "#{lib}/liblinenoise.dylib"
    lib.install "liblinenoise.dylib"
    include.install "linenoise.h"
  end

  test do
    (testpath/"test.c").write <<~EOS
      #include <stdio.h>
      #include <linenoise.h>
      int main() {
        linenoiseHistoryAdd("homebrew-test");
        printf("ok\n");
        return 0;
      }
    EOS
    system ENV.cc, "test.c", "-L#{lib}", "-llinenoise", "-o", "test"
    assert_match "ok", shell_output("./test")
  end
end
