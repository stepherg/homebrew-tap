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
     (var/"log/rbus").mkpath
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
       PID_FILE="#{var}/run/rbus/rtrouted.pid"
       LOG_FILE="#{var}/log/rbus/rtrouted.log"
       ERR_FILE="#{var}/log/rbus/rtrouted.err"
 
       # Ensure clean PID file
       rm -f "$PID_FILE"
 
       # Start rtrouted in the background
       #{opt_bin}/rtrouted "$@" >> "$LOG_FILE" 2>> "$ERR_FILE" &
       PID=$!
 
       # Write PID to file
       echo $PID > "$PID_FILE"
 
       # Trap signals to ensure proper cleanup
       trap 'kill -TERM $PID; wait $PID; rm -f "$PID_FILE"; exit 0' TERM INT
 
       # Wait for the process to exit
       wait $PID
 
       # Clean up PID file
       rm -f "$PID_FILE"
     EOS
     (bin/"rtrouted-wrapper").write wrapper
     (bin/"rtrouted-wrapper").chmod 0755
 
     # Install stop script
     stop = <<~EOS
       #!/bin/bash
       PID_FILE="#{var}/run/rbus/rtrouted.pid"
       LOG_FILE="#{var}/log/rbus/rtrouted.log"
       ERR_FILE="#{var}/log/rbus/rtrouted.err"
 
       if [ ! -f "$PID_FILE" ]; then
         echo "No PID file found at $PID_FILE. Is rtrouted running?" >> "$ERR_FILE"
         exit 0
       fi
 
       PID=$(cat "$PID_FILE")
       if [ -z "$PID" ]; then
         echo "PID file $PID_FILE is empty." >> "$ERR_FILE"
         rm -f "$PID_FILE"
         exit 0
       fi
 
       # Check if process is running
       if ! ps -p "$PID" > /dev/null; then
         echo "Process $PID not running. Cleaning up PID file." >> "$ERR_FILE"
         rm -f "$PID_FILE"
         exit 0
       fi
 
       # Send SIGTERM to rtrouted
       echo "Stopping rtrouted (PID $PID)..." >> "$LOG_FILE"
       kill -TERM "$PID"
 
       # Wait for process to exit (up to 10 seconds)
       for i in {1..10}; do
         if ! ps -p "$PID" > /dev/null; then
           echo "rtrouted stopped." >> "$LOG_FILE"
           rm -f "$PID_FILE"
           exit 0
         fi
         sleep 1
       done
 
       # If still running, try SIGKILL
       echo "rtrouted did not stop with SIGTERM, sending SIGKILL..." >> "$ERR_FILE"
       kill -KILL "$PID" 2>/dev/null
       rm -f "$PID_FILE"
       echo "rtrouted forcefully stopped." >> "$LOG_FILE"
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
         <key>StandardOutPath</key>
         <string>#{var}/log/rbus/rtrouted.log</string>
         <key>StandardErrorPath</key>
         <string>#{var}/log/rbus/rtrouted.err</string>
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
         #{opt_bin}/rtrouted
 
       The service uses a control script (#{opt_bin}/rtrouted-control) that dispatches to:
         - #{opt_bin}/rtrouted-wrapper (start)
         - #{opt_bin}/rtrouted-stop (stop)
 
       Optional arguments for rtrouted can be passed to the wrapper script or configured in:
         #{etc}/rbus/rtrouted.conf
 
       Logs are written to:
         #{var}/log/rbus/rtrouted.log
         #{var}/log/rbus/rtrouted.err
 
       PID file is written to:
         #{var}/run/rbus/rtrouted.pid
 
       If the service fails to stop properly, you can manually run:
         #{opt_bin}/rtrouted-stop
       or:
         kill -TERM $(cat #{var}/run/rbus/rtrouted.pid)
     EOS
   end
 
   test do
     # Basic test to verify rbuscli binary
     system "#{bin}/rbuscli", "--version"
   end
 end