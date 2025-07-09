class RbusElements < Formula
  desc "RBUS-based data model management for device information"
  homepage "https://github.com/stepherg/rbus-elements"
  url "https://github.com/stepherg/rbus-elements/archive/refs/tags/v0.0.3.tar.gz"
  version "0.0.3"
  sha256 "a164167c921010b2d64bd122bed735349e236ca04e24f9e057d85f5905147f72"
  license "Apache-2.0"

  depends_on "cmake" => :build
  depends_on "stepherg/tap/rbus"
  depends_on "cjson"

  def preinstall
    system bin/"rbus-elements-stop" if File.exist?(bin/"rbus-elements-stop")
  end

  def preremove
    system bin/"rbus-elements-stop" if File.exist?(bin/"rbus-elements-stop")
  end

  def install
    raise "elements.json not found in source directory" unless File.exist?("elements.json")
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build" or raise "Build failed"
    raise "Build failed: rbus_elements binary not found" unless File.exist?("build/rbus_elements")
    bin.install "build/rbus_elements"
    etc.install "elements.json"

    # Install start script
    start = <<~EOS
      #!/usr/bin/env bash
      PIDS=$(/usr/bin/pgrep rbus_elements)
      if [[ "$PIDS" ]]; then
        echo "rbus_elements already running (PIDs: $PIDS)."
        exit 1
      fi
      #{opt_bin}/rbus_elements #{etc}/elements.json &
    EOS
    (bin/"rbus-elements-start").write start
    (bin/"rbus-elements-start").chmod 0755

    # Install stop script
    stop = <<~EOS
      #!/usr/bin/env bash
      PIDS=$(/usr/bin/pgrep rbus_elements)
      if [[ -z "$PIDS" ]]; then
        exit 0
      fi
      echo "Stopping rbus_elements (PIDs: $PIDS)..."
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
          echo "rbus_elements stopped."
          exit 0
        fi
        sleep 1
      done
      echo "rbus_elements did not stop with SIGTERM, sending SIGKILL..."
      for PID in $PIDS; do
        if ps -p "$PID" > /dev/null; then
          kill -KILL "$PID" 2>/dev/null
        fi
      done
      sleep 1
      for PID in $PIDS; do
        if ps -p "$PID" > /dev/null; then
          echo "Failed to stop rbus_elements (PID $PID)."
          exit 1
        fi
      done
      echo "rbus_elements forcefully stopped."
    EOS
    (bin/"rbus-elements-stop").write stop
    (bin/"rbus-elements-stop").chmod 0755
  end

  def caveats
    <<~EOS
      The rbus-elements configuration file is located at:
        #{etc}/elements.json
      Edit this file to customize the data model.

      To start rbus-elements:
        #{opt_bin}/rbus-elements-start
      To stop rbus-elements:
        #{opt_bin}/rbus-elements-stop

      Before upgrading or uninstalling, ensure rbus_elements is stopped:
        #{opt_bin}/rbus-elements-stop
    EOS
  end

  test do
    (testpath/"elements.json").write <<~EOS
      [
        {
          "name": "Device.Test.Parameter",
          "type": 0,
          "value": "test"
        }
      ]
    EOS
    pid = fork do
      exec "#{bin}/rbus_elements", "#{testpath}/elements.json"
    end
    sleep 1
    assert_match /Successfully registered/, shell_output("ps aux | grep rbus_elements")
    system "#{bin}/rbus-elements-start"
    sleep 1
    assert_match /rbus_elements/, shell_output("ps aux | grep rbus_elements")
    system "#{bin}/rbus-elements-stop"
    sleep 1
    refute_match /rbus_elements/, shell_output("ps aux | grep rbus_elements")
  ensure
    Process.kill("TERM", pid) if pid
    Process.wait(pid) if pid
  end
end