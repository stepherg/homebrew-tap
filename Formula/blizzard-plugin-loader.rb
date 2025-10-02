class BlizzardPluginLoader < Formula
  desc "Dynamic Blizzard plugin discovery and registration over gRPC"
  homepage "https://github.com/stepherg/blizzard-plugin-loader"
  # Replace the tag & sha256 below with an actual released tarball when you cut a release.
  url "https://github.com/stepherg/blizzard-plugin-loader/archive/refs/tags/v0.0.1.tar.gz"
  version "0.0.1"
  sha256 "c23bccb654a47567b79f5cacf9963e94e814828edc96574c974d1cf3ba7bada7"
  license "Apache-2.0"
  head "https://github.com/stepherg/blizzard-plugin-loader.git", branch: "main"

  # Build dependencies
  depends_on "cmake" => :build
  depends_on "pkg-config" => :build
  depends_on "grpc" # provides grpc++ via pkg-config
  depends_on "abseil" # Homebrew core has abseil
  depends_on "protobuf"

  def install
    args = [
      "-S", ".",
      "-B", "build",
      "-DBUILD_EXAMPLE_CPP_PROVIDER=OFF",
      "-DINSTALL_EXAMPLE_SCRIPTS=ON",
      "-DBLIZZARD_PLUGIN_DIR=#{lib}/blizzard/plugins"
    ]
    system "cmake", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  service do
    # Use opt_lib so the symlinked Cellar path resolves correctly after upgrades.
    run [opt_bin/"blizzard-plugin-loader", opt_lib/"blizzard/plugins", "--endpoint", "localhost:50051"]
    keep_alive true
    working_dir var
    log_path var/"log/blizzard-plugin-loader.log"
    error_log_path var/"log/blizzard-plugin-loader.log"
    environment_variables BLIZZARD_ENDPOINT: "localhost:50051"
  end

  def caveats
    <<~EOS
      Plugins will be loaded from:
        #{opt_lib}/blizzard/plugins
      Provide a Blizzard server endpoint via --endpoint or BLIZZARD_ENDPOINT env var.
      Example:
  blizzard-plugin-loader #{opt_lib}/blizzard/plugins --endpoint localhost:50051
        To run as a background service (auto-restarts at login):
        brew services start #{name.downcase}
      Logs:
        tail -f #{var}/log/blizzard-plugin-loader.log
      Override endpoint for the service:
        BLIZZARD_ENDPOINT=host:port brew services restart #{name.downcase}
    EOS
  end

  test do
    # The binary supports --help usage output. Ensure it links and runs.
    assert_match "Usage:", shell_output("#{bin}/blizzard-plugin-loader --help")
  end
end
