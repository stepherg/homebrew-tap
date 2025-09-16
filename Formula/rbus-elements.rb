class RbusElements < Formula
  desc "RBUS-based data model management for device information"
  homepage "https://github.com/stepherg/rbus-elements"
  url "https://github.com/stepherg/rbus-elements/archive/refs/tags/v0.0.6.tar.gz"
  version "0.0.6"
  # curl -L -o rbus-elements.tar.gz https://github.com/stepherg/rbus-elements/archive/refs/tags/v0.0.6.tar.gz
  # shasum -a 256 rbus-elements.tar.gz
  sha256 "34e90ff50a8a089983dc002bbcf3369aa272cb9d24789d7eddb517cf1c6a941d"
  license "Apache-2.0"
  head "https://github.com/stepherg/rbus-elements.git", branch: "main"

  depends_on "cmake" => :build
  depends_on "cjson"
  depends_on "jansson"
  depends_on "stepherg/tap/rbus"

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    bin.install "build/rbus_elements"
    pkgshare.install "elements.json"
  end

  service do
    run [opt_bin/"rbus_elements", opt_pkgshare/"elements.json"]
    keep_alive true
    log_path var/"log/rbus_elements.log"
    error_log_path var/"log/rbus_elements.log"
  end

  def caveats
    <<~EOS
      The bundled static model file is located at:
        #{opt_pkgshare}/elements.json
      It is not copied to etc/ because it is intended to remain unmodified; it will
      be removed automatically if the formula is uninstalled.

      Manage as a service:
        brew services start #{name.downcase}
    EOS
  end

  test do
    # Use the distributed static file
    assert_path_exists pkgshare/"elements.json"
    pid = fork { exec bin/"rbus_elements", pkgshare/"elements.json" }
    sleep 2
    assert_match "rbus_elements", shell_output("ps -p #{pid} -o comm=")
  ensure
    Process.kill("TERM", pid) if pid
    Process.wait(pid) if pid
  end
end
