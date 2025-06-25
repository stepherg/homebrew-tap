class RbusDatamodels < Formula
   desc "RBUS-based data model management for device information"
   homepage "https://github.com/stepherg/rbus-datamodels"
   url "https://github.com/stepherg/rbus-datamodels/archive/refs/tags/v0.0.1.tar.gz"
   version "0.0.1"
   sha256 "a7ace6567860df9d0f29775c914a930e7a9f0718c78c3435b49871050c1a16c3"
   license "Apache-2.0"
 
   depends_on "cmake" => :build
   depends_on "stepherg/tap/rbus"
   depends_on "cjson"
 
   def install
     system "cmake", "-S", ".", "-B", "build", *std_cmake_args
     system "cmake", "--build", "build"
     bin.install "build/rbus-datamodels"
     etc.install "datamodels.json"

     # Install start script
     start = <<~EOS
      #!/bin/bash

      PID=$(/usr/bin/pgrep rbus-datamodels)
  
      if [[ "$PID" ]]; then
         echo "rbus-datamodels already running..."
         exit 0
      fi

      #{opt_bin}/rbus-datamodels #{etc}/datamodels.json &
 
     EOS
     (bin/"rbus-datamodels-start").write start
     (bin/"rbus-datamodels-start").chmod 0755
 
     # Install stop script
     stop = <<~EOS
      #!/bin/bash
 
      PID=$(/usr/bin/pgrep rbus-datamodels)
  
      if [[ -z "$PID" ]]; then
         exit 0
      fi

      # Check if process is running
      if ! ps -p "$PID" > /dev/null; then
         exit 0
      fi
 
      # Send SIGTERM to rbus-datamodels
      echo "Stopping rbus-datamodels (PID $PID)..."
      kill -TERM "$PID"
 
      # Wait for process to exit (up to 10 seconds)
      for i in {1..10}; do
         if ! ps -p "$PID" > /dev/null; then
            echo "rbus-datamodels stopped."
            exit 0
         fi
         sleep 1
      done
 
      # If still running, try SIGKILL
      echo "rbus-datamodels did not stop with SIGTERM, sending SIGKILL..."
      kill -KILL "$PID" 2>/dev/null
      echo "rbus-datamodels forcefully stopped."
      exit 0
     EOS
     (bin/"rbus-datamodels-stop").write stop
     (bin/"rbus-datamodels-stop").chmod 0755 

   end
 
   def caveats
      <<~EOS
       To start rbus:
          #{opt_bin}/rbus-datamodels-start
  
       To stop rbus:
          #{opt_bin}/rbus-datamodels-stop 
      EOS
    end
 
   test do
     # Create a temporary JSON file for testing
     (testpath/"datamodels.json").write <<~EOS
       [
         {
           "name": "Device.Test.Parameter",
           "type": 0,
           "value": "test"
         }
       ]
     EOS
 
     # Run the executable with the test JSON file
     assert_match /Successfully registered/, shell_output("#{bin}/rbus-datamodels #{testpath}/datamodels.json 2>&1")
   end
 end