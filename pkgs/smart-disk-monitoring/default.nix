{
  lib,
  stdenv,
  fetchFromGitHub,
  smartmontools,
  jq,
}:
stdenv.mkDerivation rec {
  pname = "smart-disk-monitoring";
  version = "unstable-2024-01-09";

  src = fetchFromGitHub {
    owner = "micha37-martins";
    repo = "S.M.A.R.T-disk-monitoring-for-Prometheus";
    rev = "7fbbf6ea315dd13210db6d7d173a977a86b4c579";
    hash = "sha256-1gvyypdwyp5q3imcmk9rc5ads7qbzhk8hwsgmkhp5nm9ilg9fd9d";
  };

  nativeBuildInputs = [];
  buildInputs = [smartmontools jq];

  installPhase = ''
    install -Dm755 smartmon.sh $out/bin/smartmon.sh

    # Create wrapper script that ensures dependencies are available
    mkdir -p $out/bin
    cat > $out/bin/smart-disk-monitoring <<EOF
    #!${stdenv.shell}
    export PATH="${lib.makeBinPath [smartmontools jq]}:\$PATH"
    exec $out/bin/smartmon.sh "\$@"
    EOF
    chmod +x $out/bin/smart-disk-monitoring

    # Install systemd service and timer
    mkdir -p $out/lib/systemd/system
    cat > $out/lib/systemd/system/smart-disk-monitoring.service <<EOF
    [Unit]
    Description=S.M.A.R.T. disk monitoring for Prometheus
    After=network.target

    [Service]
    Type=oneshot
    ExecStartPre=/bin/sh -c 'mkdir -p /var/lib/node_exporter/textfile_collector'
    ExecStart=/bin/sh -c '${smartmontools}/bin/smartctl --version && $out/bin/smart-disk-monitoring > /var/lib/node_exporter/textfile_collector/smart_metrics.prom'
    User=root

    [Install]
    WantedBy=multi-user.target
    EOF

    cat > $out/lib/systemd/system/smart-disk-monitoring.timer <<EOF
    [Unit]
    Description=Run S.M.A.R.T. disk monitoring every 5 minutes

    [Timer]
    OnBootSec=1min
    OnUnitActiveSec=5min

    [Install]
    WantedBy=timers.target
    EOF
  '';

  meta = with lib; {
    description = "S.M.A.R.T. disk monitoring script for Prometheus node-exporter";
    homepage = "https://github.com/micha37-martins/S.M.A.R.T-disk-monitoring-for-Prometheus";
    license = licenses.mit;
    maintainers = [];
    platforms = platforms.linux;
  };
}
