class RbusJsonrpc < Formula
  desc "JSON-RPC server for rbus"
  homepage "https://github.com/stepherg/rbus-jsonrpc"
  url "https://github.com/stepherg/rbus-jsonrpc/archive/refs/tags/v0.0.1.tar.gz"
  version "0.0.1"
  sha256 "0d6d95d67fe48a4b906e8d1b709b053d76b5959c27f80cd7e162807a3cd8b9ab"
  license "Apache-2.0"

  depends_on "cmake" => :build
  depends_on "pkg-config" => :build
  depends_on "libwebsockets"
  depends_on "jansson"
  depends_on "openssl@3"
  depends_on "rbus"

  def install
    # Create build directory
    mkdir "build" do
      system "cmake", "..", *std_cmake_args
      system "make"

      # Install executables
      bin.install "rbus_jsonrpc"
    end

    # Install configuration file to etc/rbus
    (etc/"rbus").install "config.json"

     # Install start script
     start = <<~EOS
      #!/bin/bash

      PID=$(/usr/bin/pgrep rbus_jsonrpc)
  
      if [[ "$PID" ]]; then
         echo "rbus_jsonrpc already running..."
         exit 0
      fi

      #{opt_bin}/rbus_jsonrpc -c #{etc}/rbus/config.json &
 
     EOS
     (bin/"rbus-jsonrpc-start").write start
     (bin/"rbus-jsonrpc-start").chmod 0755
 
     # Install stop script
     stop = <<~EOS
      #!/bin/bash
 
      PID=$(/usr/bin/pgrep rbus_jsonrpc)
  
      if [[ -z "$PID" ]]; then
         exit 0
      fi

      # Check if process is running
      if ! ps -p "$PID" > /dev/null; then
         exit 0
      fi
 
      # Send SIGTERM to rbus_jsonrpc
      echo "Stopping rbus_jsonrpc (PID $PID)..."
      kill -TERM "$PID"
 
      # Wait for process to exit (up to 10 seconds)
      for i in {1..10}; do
         if ! ps -p "$PID" > /dev/null; then
            echo "rbus_jsonrpc stopped."
            exit 0
         fi
         sleep 1
      done
 
      # If still running, try SIGKILL
      echo "rbus_jsonrpc did not stop with SIGTERM, sending SIGKILL..."
      kill -KILL "$PID" 2>/dev/null
      echo "rbus_jsonrpc forcefully stopped."
      exit 0
     EOS
     (bin/"rbus-jsonrpc-stop").write stop
     (bin/"rbus-jsonrpc-stop").chmod 0755 
  end

  def caveats
    <<~EOS
      To start rbus-jsonrpc server:
         #{opt_bin}/rbus-jsonrpc-start

      To stop rbus-jsonrpc server:
         #{opt_bin}/rbus-jsonrpc-stop

      The configuration file is installed at:
         #{etc}/rbus/config.json
    EOS
  end

