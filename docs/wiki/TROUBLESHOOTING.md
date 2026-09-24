# Troubleshooting

## First checks

```bash
remnawave-manager status
remnawave-manager doctor
remnawave-manager logs
```

Repair:

```bash
remnawave-manager repair
```

Restart:

```bash
remnawave-manager restart
```

## Transport problems

Check DNS, required TCP/UDP ports, enabled transports, certificates/Reality parameters and Node connectivity.

Reapply transports:

```bash
remnawave-manager protocols
```

or:

```bash
remnawave-manager bind
```

## Backup before repair

```bash
remnawave-manager backup
remnawave-manager repair
```

Manager log:

```text
/var/log/remnawave-manager.log
```
