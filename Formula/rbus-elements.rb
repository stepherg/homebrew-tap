class RbusElements < Formula
   desc "RBUS-based data model management for device information"
   homepage "https://github.com/stepherg/rbus-elements"
   url "https://github.com/stepherg/rbus-elements/archive/refs/tags/v0.0.2.tar.gz"
   version "0.0.2"
   sha256 "093b2b89c9cab0654e49c7c9c96cf14dc89f140825f2602795e17e3b449953a1"
   license "Apache-2.0"
 
   depends_on "cmake" => :build
   depends_on "stepherg/tap/rbus"
   depends_on "cjson"
 
   def install
     system "cmake", "-S", ".", "-B", "build", *std_cmake_args
     system "cmake", "--build", "build"
     bin.install "build/rbus_elements"
     etc.install "elements.json"

     # Install start script
     start = <<~EOS
      #!/bin/bash

      PID=$(/usr/bin/pgrep rbus_elements)
  
      if [[ "$PID" ]]; then
         echo "rbus_elements already running..."
         exit 0
      fi

      #{opt_bin}/rbus_elements #{etc}/elements.json &
 
     EOS
     (bin/"rbus-elements-start").write start
     (bin/"rbus-elements-start").chmod 0755
 
     # Install stop script
     stop = <<~EOS
      #!/bin/bash
 
      PID=$(/usr/bin/pgrep rbus_elements)
  
      if [[ -z "$PID" ]]; then
         exit 0
      fi

      # Check if process is running
      if ! ps -p "$PID" > /dev/null; then
         exit 0
      fi
 
      # Send SIGTERM to rbus_elements
      echo "Stopping rbus_elements (PID $PID)..."
      kill -TERM "$PID"
 
      # Wait for process to exit (up to 10 seconds)
      for i in {1..10}; do
         if ! ps -p "$PID" > /dev/null; then
            echo "rbus_elements stopped."
            exit 0
         fi
         sleep 1
      done
 
      # If still running, try SIGKILL
      echo "rbus_elements did not stop with SIGTERM, sending SIGKILL..."
      kill -KILL "$PID" 2>/dev/null
      echo "rbus_elements forcefully stopped."
      exit 0
     EOS
     (bin/"rbus-elements-stop").write stop
     (bin/"rbus-elements-stop").chmod 0755 

   end
 
   def caveats
      <<~EOS
       To start rbus:
          #{opt_bin}/rbus-elements-start
  
       To stop rbus:
          #{opt_bin}/rbus-elements-stop 
      EOS
    end
 
   test do
     # Create a temporary JSON file for testing
     (testpath/"elements.json").write <<~EOS
       [
         {
           "name": "Device.Test.Parameter",
           "type": 0,
           "value": "test"
         }
       ]
     EOS
 
     # Run the executable with the test JSON file
     assert_match /Successfully registered/, shell_output("#{bin}/rbus_elements #{testpath}/elements.json 2>&1")
   end
 end