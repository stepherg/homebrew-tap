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
     # Create log and run directories
     (var/"run/rbus").mkpath
 
     # Install control script
     control = <<~EOS
       #!/bin/bash
       START_SCRIPT="#{opt_bin}/rtrouted-wrapper"
       STOP_SCRIPT="#{opt_bin}/rtrouted-stop"
 
       case "$1" in
         start)
           exec "$START_SCRIPT" "${@:2}"
           ;;
         stop)
           exec "$STOP_SCRIPT" "${@:2}"
           ;;
         *)
           echo "Usage: $0 {start|stop}"
           exit 1
           ;;
       esac
     EOS
     (bin/"rtrouted-control").write control
     (bin/"rtrouted-control").chmod 0755
 
     # Install start wrapper script
     wrapper = <<~EOS
       #!/bin/bash
       # Start rtrouted
       #{opt_bin}/rtrouted
   
     EOS
     (bin/"rtrouted-wrapper").write wrapper
     (bin/"rtrouted-wrapper").chmod 0755
 
     # Install stop script
     stop = <<~EOS
       #!/bin/bash

       PID=$(/usr/bin/pgrep rtrouted)
  
       # Check if process is running
       if ! ps -p "$PID" > /dev/null; then
         rm -f "/tmp/rtrouted*"
         exit 0
       fi
 
       # Send SIGTERM to rtrouted
       kill -TERM "$PID"
 
       # Wait for process to exit (up to 10 seconds)
       for i in {1..10}; do
         if ! ps -p "$PID" > /dev/null; then
            rm -f "/tmp/rtrouted*"
            exit 0
         fi
         sleep 1
       done
 
       # If still running, try SIGKILL
       kill -KILL "$PID" 2>/dev/null
       rm -f "/tmp/rtrouted*"
       exit 0
     EOS
     (bin/"rtrouted-stop").write stop
     (bin/"rtrouted-stop").chmod 0755
 
     # Install custom launchd plist
     plist = <<~EOS
       <?xml version="1.0" encoding="UTF-8"?>
       <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
       <plist version="1.0">
       <dict>
         <key>Label</key>
         <string>homebrew.mxcl.rbus</string>
         <key>ProgramArguments</key>
         <array>
           <string>#{opt_bin}/rtrouted-control</string>
           <string>start</string>
         </array>
         <key>RunAtLoad</key>
         <true/>
         <key>KeepAlive</key>
         <false/>
       </dict>
       </plist>
     EOS
     (prefix/"etc").install_symlink plist => "homebrew.mxcl.rbus.plist"
   end
 
   def caveats
     <<~EOS
       To start rbus now and restart at login:
         brew services start rbus
       Or, if you don't want/need a background service, you can run:
         #{opt_bin}/rtrouted -f
 
       The service uses a control script (#{opt_bin}/rtrouted-control) that dispatches to:
         - #{opt_bin}/rtrouted-wrapper (start)
         - #{opt_bin}/rtrouted-stop (stop)    
     EOS
   end
 
   test do
     # Basic test to verify rbuscli binary
     system "#{bin}/rbuscli", "--version"
   end
 end