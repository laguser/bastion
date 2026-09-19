<div align="center">
  <br>
  <img src="assets/bastion.png" width="620" alt="Bastion">

  <h2>bastion</h2>
  <p><i>intelligent server hardening & performance tuning</i></p>
  
  <p>
    <code>root</code> · <code>bbr</code> · <code>fail2ban</code> · <code>ufw</code> · <code>gemini-flash</code>
  </p>

  <p>
    <a href="#-русский">русский</a> · <a href="#-english">english</a>
  </p>

  <p>
    <img src="https://img.shields.io/badge/os-ubuntu_%7C_debian-000000?style=flat-square&logo=linux&logoColor=white" alt="OS">
    <img src="https://img.shields.io/badge/ai-gemini_flash-000000?style=flat-square&logo=google&logoColor=white" alt="AI">
    <img src="https://img.shields.io/badge/tcp-google_bbr-000000?style=flat-square" alt="TCP">
    <img src="https://img.shields.io/badge/license-mit-000000?style=flat-square" alt="License">
  </p>
  <br>
</div>

---

### ⚡ Быстрый старт / Quick Start

Выполните одну команду от имени `root`:

```bash
bash <(curl -sSL https://raw.githubusercontent.com/laguser/bastion/main/setup.sh)
```

---

# 🇷🇺 Русский

## ◈ О проекте

**Bastion** — минималистичный инструмент для превращения свежего VPS в защищенный и оптимизированный сервер за 60 секунд.

* Работает напрямую из-под `root` (вход по паролю сохранён).
* Никакого визуального шума — чистый интерактивный интерфейс.
* Тюнинг ядра по стандартам безопасности и скорости.

---

## ◈ Режимы работы

| Режим | Описание |
| :--- | :--- |
| **`[1] Automatic`** | Моментальное применение оптимальных настроек без лишних вопросов. |
| **`[2] Manual`** | Пошаговый диалог. Достаточно нажимать `[Enter]` для выбора дефолтных значений. |
| **`[3] AI-Powered`** | Анализ через **Gemini Flash**. Нейросеть считывает CPU, RAM, диск и подбирает параметры. |

---

## ◈ Безопасность

* **OpenSSH Hardening**: Приоритетный drop-in (`00-bastion.conf`), `MaxAuthTries 3`, `LoginGraceTime 30`, `LogLevel VERBOSE`, `MaxStartups 10:30:60`, отключение X11.
* **Lockout Protection**: Проверка фактического прослушивания порта через `ss` перед отключением резервного доступа, аварийный порт 22 с rate-limit.
* **Fail2Ban (systemd-native)**: Анализ системного журнала напрямую через `python3-systemd`, авто-вайтлист текущего IP администратора (`ignoreip`).
* **UFW Firewall & Multi-Protocol Auto-Detect**: Интеллектуальное сканирование активных TCP/UDP сервисов (WireGuard, OpenVPN, Mail, Docker) с сохранением доступа и автоматическим бэкапом правил в `/var/backups/bastion/`.
* **Защита `/dev/shm`**: Монтирование с флагами `noexec,nosuid,nodev` против исполнения скриптов и полезных нагрузок из shared memory.
* **Ядро (DoS Shield)**: Криптографические `tcp_syncookies`, защита от TIME-WAIT атак (`tcp_rfc1337 = 1`), фильтрация обратного пути (`rp_filter`), защита от спуфинга и ICMP Broadcast.
* **Безопасность IPv6**: Полная блокировка Router Advertisements (`accept_ra = 0`) и ICMP redirects.
* **Права ядра & Память**: Ограничение доступа к `dmesg`, адресам ядра (`kptr_restrict = 2`), защита трассировки процессов (`kernel.yama.ptrace_scope = 1`).
* **Аварийный откат**: Автоматическое резервное копирование `sshd_config`, `fstab`, `system.conf` и `ufw` перед любыми модификациями.
* **Автообновления**: Фоновая служба `unattended-upgrades` для своевременных патчей безопасности.

---

## ◈ Оптимизация

* **Google BBR**: Алгоритм контроля перегрузки TCP от Google — максимальная пропускная способность и минимальный пинг.
* **Буферы TCP**: Расширение окон сокетов до 16 МБ для высокоскоростных гигабитных каналов.
* **Лимиты файлов**: Поднятие системного ограничения `nofile` до 65 535 (никаких `Too many open files`).
* **Swap & Filesystem Check**: Интеллектуальное выделение Swap с проверкой свободного места на диске, флагом `nofail` в `/etc/fstab` и приоритетом RAM (`swappiness = 10`).
* **Детект виртуализации**: Автоматическое отключение тюнинга хостового ядра и swap внутри легковесных контейнеров (LXC/OpenVZ).

---

## ◈ Смена пароля

В конце любого из режимов скрипт предлагает задать новый пароль для `root`.

---

# 🇬🇧 English

## ◈ Overview

**Bastion** is a minimalist automation suite that hardens and tunes a fresh Linux VPS in under a minute.

* Root-focused workflow (preserves password authentication).
* Minimalist terminal interface with smart Enter-defaults.
* Kernel-level hardening & network congestion tuning.

---

## ◈ Modes

| Mode | Description |
| :--- | :--- |
| **`[1] Automatic`** | Instant hardening using battle-tested defaults. |
| **`[2] Manual`** | Interactive wizard. Press `[Enter]` to accept recommended values. |
| **`[3] AI-Powered`** | Tailored calibration via **Google Gemini Flash** based on server specs. |

---

## ◈ Hardening Features

* **OpenSSH Hardening**: Highest priority drop-in (`00-bastion.conf`), `MaxAuthTries 3`, `LoginGraceTime 30s`, `LogLevel VERBOSE`, `MaxStartups 10:30:60`, keepalive watchdog.
* **Lockout Protection**: Verifies socket binding before dropping fallbacks; maintains emergency rate-limited port 22 access.
* **Fail2Ban (systemd-native)**: Native journal stream via `python3-systemd`, dynamic whitelist for active SSH client IP (`ignoreip`).
* **Firewall (UFW) & Auto-Detect**: Intelligent multi-protocol (TCP & UDP) detection of running workloads (WireGuard, OpenVPN, Mail, Docker) with automated backup to `/var/backups/bastion/`.
* **Protected `/dev/shm`**: Mounted with `noexec,nosuid,nodev` to neutralize RAM payload execution.
* **Kernel DoS Shield**: TCP SYN cookies, RFC 1337 TIME-WAIT assassination protection, reverse path filtering, IPv6 RA rejection, and restricted `dmesg`/ptrace access.
* **Container Aware**: Automatically adapts configuration if running inside LXC or OpenVZ environments.
* **Unattended Upgrades**: Automated upstream security patches without disruption.

---

## ◈ Performance Tuning

* **Google BBR**: Next-generation TCP flow control yielding reduced bufferbloat and latency.
* **Extended TCP Windows**: Up to 16MB read/write socket buffers for gigabit bandwidth.
* **Resource Limits**: System-wide file descriptor ceiling raised to 65,535.
* **Virtual Memory**: Safe swap allocation with disk bounds, `nofail` flag, and `vm.swappiness = 10`.

---

<br>
<div align="center">
  <p>Engineered with 🤍 by <a href="https://github.com/laguser">laguser</a></p>
  <sub><i>Security by design · Performance by default</i></sub>
</div>
