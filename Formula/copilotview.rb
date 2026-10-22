class Copilotview < Formula
  desc "Browse, search and summarize past GitHub Copilot CLI sessions"
  homepage "https://github.com/mahata/copilotview"
  url "https://github.com/mahata/copilotview/releases/download/v0.2.0/copilotview-0.2.0.tar.gz"
  sha256 "e29a67f8e7a0ecab3fbc1890226a4a7357c1ddfc50030c4107d7119906b208f7"
  license "MIT"

  depends_on "node"

  def install
    libexec.install "cli.js", "web"
    (bin/"copilotview").write <<~SH
      #!/bin/bash
      exec "#{formula_opt_bin("node")}/node" "#{libexec}/cli.js" "$@"
    SH
  end

  test do
    (testpath/"sessions").mkpath
    system bin/"copilotview", "index", "--source", testpath/"sessions", "--index", testpath/"index.db"
    assert_match "Sessions:   0", shell_output("#{bin}/copilotview stats --index #{testpath}/index.db")

    port = free_port
    pid = spawn bin/"copilotview", "serve", "--index", testpath/"index.db", "--port", port.to_s
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
