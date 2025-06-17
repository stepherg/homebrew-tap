class Rbus < Formula
  desc "RDK-Bus (RBUS) messaging framework"
  homepage "https://github.com/rdkcentral/rbus"
  url "https://github.com/stepherg/rbus/archive/6cdba0a03ec26cb551786234742ebdff233abe0f.tar.gz"
  version "2.3.0" # Matches CMakeLists.txt
  sha256 "6cb3970efa4b2b546b0af1aea15ceca4c6d5e795f1a7f168612f7b81dd6114fe"
  license "Apache-2.0"

  depends_on "cmake" => :build
  depends_on "cjson"
  depends_on "msgpack-c"
  depends_on "stepherg/tap/linenoise"

  def install
    # Configure CMake with Homebrew dependencies
    args = std_cmake_args + %W[
      -DBUILD_FOR_DESKTOP=OFF
      -DBUILD_RBUS_DAEMON=ON
      -DBUILD_RBUS_SAMPLE_APPS=OFF
      -DBUILD_RBUS_TEST_APPS=OFF
      -DBUILD_ONLY_RTMESSAGE=OFF
      -DENABLE_RDKLOGGER=OFF
      -DRDKC_BUILD=OFF
      -DWITH_SPAKE2=OFF
      -DMSG_ROUNDTRIP_TIME=OFF
      -DENABLE_UNIT_TESTING=OFF
    ]
    mkdir "build" do
      system "cmake", "..", *args
      system "make"
      system "make", "install"
    end
  end

  test do
    # Basic test to verify rbuscli binary
    system "#{bin}/rbuscli", "--version"
  end
end
