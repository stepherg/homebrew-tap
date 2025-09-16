class Rbus < Formula
  desc "RDK-Bus (RBUS) messaging framework"
  homepage "https://github.com/rdkcentral/rbus"
  url "https://github.com/stepherg/rbus/archive/47c405dc4aea747a7af1e568586420e8aa5510dd.tar.gz"
  # Upstream commit snapshot; explicit version required for non-tag tarball
  version "2.3.3" # adjust if upstream tag mismatch
  sha256 "413adc6d8e757e883285040c479e628348a6e371fb0611460f6b748c92b7d776"
  license "Apache-2.0"
  head "https://github.com/rdkcentral/rbus.git", branch: "main"

  depends_on "cmake" => :build
  depends_on "cjson"
  depends_on "msgpack-c"
  depends_on "stepherg/tap/linenoise"

  def install
    args = std_cmake_args + %w[
      -DBUILD_FOR_DESKTOP=OFF
      -DBUILD_RBUS_DAEMON=ON
      -DBUILD_RBUS_SAMPLE_APPS=OFF
      -DBUILD_RBUS_TEST_APPS=OFF
      -DBUILD_ONLY_RTMESSAGE=OFF
      -DENABLE_RDKLOGGER=OFF
      -DRDKC_BUILD=OFF
      -DWITH_SPAKE2=OFF
      -DMSG_ROUNDTRIP_TIME=ON
      -DENABLE_UNIT_TESTING=OFF
      -DCMAKE_POLICY_VERSION_MINIMUM=3.5
    ]
    mkdir "build" do
      system "cmake", "..", *args
      system "make"
      system "make", "install"
    end

    # Wrapper to ensure stale UDS socket /tmp/rtrouted is removed when the
    # service stops (e.g. via `brew services stop rbus`).
    (libexec/"rtrouted-service").write <<~EOS
      #!/usr/bin/env bash
      set -euo pipefail
      SOCKET="/tmp/rtrouted"
      cleanup() {
        if [ -S "$SOCKET" ]; then
          rm -f "$SOCKET"
        fi
      }
      trap cleanup EXIT INT TERM
      exec "#{opt_bin}/rtrouted" "$@"
    EOS
    (libexec/"rtrouted-service").chmod 0755
  end

  service do
    run [opt_libexec/"rtrouted-service"]
    keep_alive true
    log_path var/"log/rtrouted.log"
    error_log_path var/"log/rtrouted.log"
  end

  def caveats
    <<~EOS
      A launchable service has been defined for rtrouted.
      To start now and restart at login:
        brew services start #{name.downcase}
      Or, if you don't want/need a background service you can run:
        #{opt_bin}/rtrouted
      The service wrapper automatically removes /tmp/rtrouted on shutdown.
    EOS
  end

  test do
    # Launch daemon briefly to ensure it starts then terminate.
    pid = fork do
      exec bin/"rtrouted"
    end
    sleep 2
    assert_match "rtrouted", shell_output("ps -p #{pid} -o comm=")
  ensure
    Process.kill("TERM", pid) if pid
    Process.wait(pid) if pid
    uds = Pathname("/tmp/rtrouted")
    uds.unlink if uds.exist?
    refute_predicate uds, :exist?
  end
end
