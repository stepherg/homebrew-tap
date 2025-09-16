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
      CHILD_PID=""
      LOG="#{var}/log/rtrouted-supervisor.log"

      mkdir -p "#{var}/log"
      echo "[$(date -u +%FT%TZ)] supervisor starting" >> "$LOG"

      start_child() {
        "#{opt_bin}/rtrouted" "$@" &
        CHILD_PID=$!
        echo "[$(date -u +%FT%TZ)] forked initial rtrouted pid=$CHILD_PID" >> "$LOG"
      }

      shutdown() {
        TARGET_PID="${ADOPTED_PID:-$CHILD_PID}"
        if [ -n "${TARGET_PID}" ] && kill -0 "$TARGET_PID" 2>/dev/null; then
          echo "[$(date -u +%FT%TZ)] sending SIGTERM to $TARGET_PID" >> "$LOG"
          kill -TERM "$TARGET_PID" 2>/dev/null || true
          for i in 1 2 3 4 5; do
            if ! kill -0 "$TARGET_PID" 2>/dev/null; then
              break
            fi
            sleep 1
          done
          if kill -0 "$TARGET_PID" 2>/dev/null; then
            echo "[$(date -u +%FT%TZ)] escalating SIGKILL to $TARGET_PID" >> "$LOG"
            kill -KILL "$TARGET_PID" 2>/dev/null || true
          fi
        fi
        if [ -S "$SOCKET" ]; then
          rm -f "$SOCKET" || true
          echo "[$(date -u +%FT%TZ)] removed socket $SOCKET" >> "$LOG"
        fi
        echo "[$(date -u +%FT%TZ)] supervisor exiting" >> "$LOG"
        exit 0
      }

      trap shutdown INT TERM EXIT
      start_child "$@"

      # Give daemon a moment to potentially double-fork & create socket
      sleep 1
      if [ ! -S "$SOCKET" ]; then
        # Wait a little longer if not ready yet
        for i in 1 2 3 4; do
          sleep 0.5
          [ -S "$SOCKET" ] && break
        done
      fi

      # If the original child exited but another rtrouted is running with socket, adopt it
      if ! kill -0 "$CHILD_PID" 2>/dev/null; then
        for PID in $(/usr/bin/pgrep -x rtrouted || true); do
          if [ -S "$SOCKET" ]; then
            ADOPTED_PID=$PID
            echo "[$(date -u +%FT%TZ)] adopted daemon pid=$ADOPTED_PID" >> "$LOG"
            break
          fi
        done
      fi

      TARGET_PID="${ADOPTED_PID:-$CHILD_PID}"
      if [ -n "$TARGET_PID" ]; then
        wait "$TARGET_PID" || true
      fi
      if [ -S "$SOCKET" ]; then
        rm -f "$SOCKET" || true
        echo "[$(date -u +%FT%TZ)] removed socket $SOCKET after natural exit" >> "$LOG"
      fi
    EOS
    (libexec/"rtrouted-service").chmod 0755
  end

  service do
    run [opt_libexec/"rtrouted-service"]
    # not using keep_alive so that stop actually terminates the process
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
end
