class RbusElements < Formula
  desc "RBUS-based data model management for device information"
  homepage "https://github.com/stepherg/rbus-elements"
  url "https://github.com/stepherg/rbus-elements/archive/refs/tags/v0.0.5.tar.gz"
  version "0.0.5"
  sha256 "5752637c11463c3a920332a71ca384b4f21634932a273e78bd112f2444b19431"
  license "Apache-2.0"
  head "https://github.com/stepherg/rbus-elements.git", branch: "main"

  depends_on "cmake" => :build
  depends_on "cjson"
  depends_on "stepherg/tap/rbus"

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    bin.install "build/rbus_elements"
    etc.install "elements.json" => "elements.json.sample"
  end

  service do
    run [opt_bin/"rbus_elements", etc/"elements.json"]
    keep_alive true
    log_path var/"log/rbus_elements.log"
    error_log_path var/"log/rbus_elements.log"
  end

  def caveats
    <<~EOS
      A sample configuration file has been installed at:
        #{etc}/elements.json.sample
      Copy it to #{etc}/elements.json and edit as needed.
      Manage as a service:
        brew services start #{name.downcase}
    EOS
  end

  test do
    (testpath/"elements.json").write <<~EOS
      [
        { "name": "Device.Test.Parameter", "type": 0, "value": "test" }
      ]
    EOS
    pid = fork { exec bin/"rbus_elements", testpath/"elements.json" }
    sleep 2
    assert_path_exists testpath/"elements.json"
    assert_match "rbus_elements", shell_output("ps -p #{pid} -o comm=")
  ensure
    Process.kill("TERM", pid) if pid
    Process.wait(pid) if pid
  end
end
