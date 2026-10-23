class Copilotview < Formula
  desc "Browse, search and summarize past GitHub Copilot CLI sessions"
  homepage "https://github.com/mahata/copilotview"
  url "https://github.com/mahata/copilotview/releases/download/v0.8.0/copilotview-0.8.0.tar.gz"
  sha256 "10bd5ffe8a6a48f8655c55885677bcb3d60bcc34e53d5a9a81e445d80a92d339"
  license "MIT"

  depends_on "node"

  def install
    libexec.install "cli.js", "web", "VERSION"
    (bin/"copilotview").write <<~SH
      #!/bin/bash
      exec "#{formula_opt_bin("node")}/node" "#{libexec}/cli.js" "$@"
    SH
    bin.install_symlink bin/"copilotview" => "cv"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/copilotview --version")

    (testpath/"sessions").mkpath
    system bin/"copilotview", "index", "--source", testpath/"sessions", "--index", testpath/"index.db"
    assert_match "Sessions:   0", shell_output("#{bin}/copilotview stats --index #{testpath}/index.db")
    assert_match "Sessions:   0", shell_output("#{bin}/cv stats --index #{testpath}/index.db")

    port = free_port
    pid = spawn bin/"copilotview", "serve", "--source", testpath/"sessions", "--index", testpath/"index.db",
                "--port", port.to_s
    url = "http://127.0.0.1:#{port}/"
    assert_match "<title>copilotview</title>",
                 shell_output("curl -fsS --retry 10 --retry-connrefused --retry-delay 1 #{url}")
  ensure
    if pid
      Process.kill("TERM", pid)
      Process.wait(pid)
    end
  end
end
