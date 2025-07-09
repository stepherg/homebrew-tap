class Rbus < Formula
  desc "RDK-Bus (RBUS) messaging framework"
  homepage "https://github.com/rdkcentral/rbus"
  url "https://github.com/stepherg/rbus/archive/47c405dc4aea747a7af1e568586420e8aa5510dd.tar.gz"
  version "2.3.3"
  sha256 "413adc6d8e757e883285040c479e628348a6e371fb0611460f6b748c92b7d776"
  license "Apache-2.0"
 
  depends_on "cmake" => :build
  depends_on "cjson"
  depends_on "msgpack-c"
  depends_on "stepherg/tap/linenoise"
 
  def preinstall
    system bin/"rtrouted-stop" if File.exist?(bin/"rtrouted-stop")
  end

  def preremove
    system bin/"rtrouted-stop" if File.exist?(bin/"rtrouted-stop")
  end

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
     -DMSG_ROUNDTRIP_TIME=ON
     -DENABLE_UNIT_TESTING=OFF
     -DCMAKE_POLICY_VERSION_MINIMUM=3.5
    ]
    mkdir "build" do
     system "cmake", "..", *args
     system "make"
     system "make", "install"
    end
 
    # Install start script
    start = <<~EOS
      #!/usr/bin/env bash
      PIDS=$(/usr/bin/pgrep rtrouted)
      if [[ "$PIDS" ]]; then
        echo "rtrouted already running (PIDs: $PIDS)."
        exit 1
      fi
      #{opt_bin}/rtrouted
    EOS
    (bin/"rtrouted-start").write start
    (bin/"rtrouted-start").chmod 0755
 
    # Install stop script
    stop = <<~EOS
      #!/usr/bin/env bash
      PIDS=$(/usr/bin/pgrep rtrouted)
      if [[ -z "$PIDS" ]]; then
        rm -f "/tmp/rtrouted"
        exit 0
      fi
      echo "Stopping rtrouted (PIDs: $PIDS)..."
      for PID in $PIDS; do
        if ps -p "$PID" > /dev/null; then
          kill -TERM "$PID"
        fi
      done
      TIMEOUT=${RBUS_STOP_TIMEOUT:-10}
      for i in $(seq 1 $TIMEOUT); do
        ALL_STOPPED=1
        for PID in $PIDS; do
          if ps -p "$PID" > /dev/null; then
            ALL_STOPPED=0
            break
          fi
        done
        if [[ $ALL_STOPPED -eq 1 ]]; then
          echo "rtrouted stopped."
          rm -f "/tmp/rtrouted"
          exit 0
        fi
        sleep 1
      done
      echo "rtrouted did not stop with SIGTERM, sending SIGKILL..."
      for PID in $PIDS; do
        if ps -p "$PID" > /dev/null; then
          kill -KILL "$PID" 2>/dev/null
        fi
      done
      sleep 1
      for PID in $PIDS; do
        if ps -p "$PID" > /dev/null; then
          echo "Failed to stop rtrouted (PID $PID)."
          exit 1
        fi
      done
      echo "rtrouted forcefully stopped."
      rm -f "/tmp/rtrouted"
      exit 0
    EOS

    (bin/"rtrouted-stop").write stop
    (bin/"rtrouted-stop").chmod 0755 
  end
 
  def caveats
    <<~EOS
    To start rbus:
      #{opt_bin}/rtrouted-start
 
    To stop rbus:
      #{opt_bin}/rtrouted-stop 
    EOS
  end
 
  test do
    # Basic test to verify rbuscli binary
    system "#{bin}/rbuscli", "--version"
  end
 end