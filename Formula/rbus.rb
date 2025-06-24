class Rbus < Formula
  desc "RDK-Bus (RBUS) messaging framework"
  homepage "https://github.com/rdkcentral/rbus"
  url "https://github.com/stepherg/rbus/archive/47c405dc4aea747a7af1e568586420e8aa5510dd.tar.gz"
  version "2.3.1"
  sha256 "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
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
      -DCMAKE_POLICY_VERSION_MINIMUM=3.5
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
