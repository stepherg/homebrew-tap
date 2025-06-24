class Rbus < Formula
   desc "RDK-Bus (RBUS) messaging framework"
   homepage "https://github.com/rdkcentral/rbus"
   url "https://github.com/stepherg/rbus/archive/47c405dc4aea747a7af1e568586420e8aa5510dd.tar.gz"
   version "2.3.1"
   sha256 "413adc6d8e757e883285040c479e628348a6e371fb0611460f6b748c92b7d776"
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
     # Create run directory
     (var/"run/rbus").mkpath
 
     # Install wrapper script for rtrouted
     wrapper = <<~EOS
       #!/bin/bash
       PID_FILE="#{var}/run/rbus/rtrouted.pid"
 
       # Ensure clean PID file
       rm -f "$PID_FILE"
 
       # Start rtrouted in the background
       #{opt_bin}/rtrouted &
       PID=$!
 
       # Write PID to file
       echo $PID > "$PID_FILE"
 
       # Trap signals to ensure proper cleanup
       trap 'kill -TERM $PID; wait $PID; rm -f "$PID_FILE"; exit 0' TERM INT
 
       # Wait for the process to exit
       wait $PID
 
       # Clean up PID file
       rm -f "$PID_FILE"
       rm -f "/tmp/rtrouted*"
     EOS
     (bin/"rtrouted-wrapper").write wrapper
     (bin/"rtrouted-wrapper").chmod 0755
   end
 
   service do
     run [opt_bin/"rtrouted-wrapper"]
     run_type :immediate
     keep_alive false
     process_type :background
   end
 
   def caveats
     <<~EOS
       To start rbus now and restart at login:
         brew services start rbus
       Or, if you don't want/need a background service, you can run:
         #{opt_bin}/rtrouted 
     EOS
   end
 
   test do
     # Basic test to verify rbuscli binary
     system "#{bin}/rbuscli", "--version"
   end
 end