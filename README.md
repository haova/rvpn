# RVPN

## Quick Start

Install:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/haova/rvpn/master/install.sh)"
```

To start wireguard:

```bash
./scripts/sync.sh & ./scripts/start.sh
```

To stop wireguard:

```bash
./scripts/stop.sh
```

Connect to peer:

```bash
./scripts/sync.sh & ./scripts/start.sh <PEER_IP/HOST>
```

## Features

### `rvpn.sh`

You can run any script and test by `rvpn.sh` command. To see my help:

```bash
sudo ./rvpn.sh
```

## License

None.
