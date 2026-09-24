# Installation Reference

## Single server

```bash
remnawave-manager install single
```

## Separate Panel and Node

Panel:

```bash
remnawave-manager install panel
```

Node:

```bash
remnawave-manager install node
```

## DNS

Verify:

- Panel hostname -> Panel IP;
- subscription hostname -> Panel IP;
- Reality/SNI hostname -> Node IP.

## Ports

Common ports include:

```text
TCP 443
UDP 443
TCP 8443
UDP 8443
TCP 4443
TCP 80
```

Only expose ports required by the selected configuration.
