<div align="center">
  <br>
  <img src="assets/bastion.png" width="620" alt="Bastion">

  <h2>bastion</h2>
  <p><i>hardened linux vps security & optimization suite</i></p>
  
  <p>
    <code>root</code> · <code>bbr</code> · <code>fail2ban</code> · <code>ufw</code> · <code>audit</code> · <code>hidepid</code> · <code>ed25519</code>
  </p>

  <p>
    <a href="#-русский">русский</a> · <a href="#-english">english</a>
  </p>

  <p>
    <img src="https://img.shields.io/badge/os-ubuntu_%7C_debian-000000?style=flat-square&logo=linux&logoColor=white" alt="OS">
    <img src="https://img.shields.io/badge/author-laguser-000000?style=flat-square&logo=github&logoColor=white" alt="Author">
    <img src="https://img.shields.io/badge/audit-backdoor_scanner-000000?style=flat-square" alt="Audit">
    <img src="https://img.shields.io/badge/tcp-google_bbr-000000?style=flat-square" alt="TCP">
    <img src="https://img.shields.io/badge/license-mit-000000?style=flat-square" alt="License">
  </p>
  <br>
</div>

---

### ⚡ Быстрый старт / Quick Start

От имени `root` (рекомендуется — сначала скачать и просмотреть скрипт):

```bash
curl -sSLo setup.sh https://raw.githubusercontent.com/laguser/bastion/main/setup.sh
less setup.sh && bash setup.sh
```

Неинтерактивный быстрый запуск (CI / автоматическое развертывание):
```bash
curl -sSL https://raw.githubusercontent.com/laguser/bastion/main/setup.sh | bash -s -- --auto
```

Запуск только аудита и сканера бэкдоров (без изменений системы):
```bash
curl -sSLo audit.sh https://raw.githubusercontent.com/laguser/bastion/main/audit.sh
bash audit.sh
```

---

# 🇷🇺 Русский

## ◈ О проекте

**Bastion** — комплексный инструмент от **laguser** для превращения свежего Linux VPS (Ubuntu / Debian) в защищённый и производительный сервер за 60 секунд. 
Полностью автономен, не зависит от сторонних облачных API, не производит недоверенных внешних запросов во время работы и гарантирует защиту от случайной блокировки (Lockout Protection).

Включает в себя автономный сканер целостности и бэкдоров, защиту от DoS-атак на уровне ядра, изоляцию процессов пользователей, разгон сети Google BBR и строгую фильтрацию трафика.

---

## ◈ Режимы работы и CLI флаги

| Режим / Флаг | Описание |
| :--- | :--- |
| **`[1] Automatic (Recommended)`** | Моментальное развёртывание эталонного production-профиля безопасности. |
| **`[2] Interactive Wizard`** | Пошаговый мастер: SSH-ключи, порты, параметры Fail2Ban, swap, изоляция `/proc` и лимиты. |
| **`--auto` / `-y`** | Автоматический неинтерактивный режим для облачных скриптов и CI/CD. |
| **`--audit-only`** | Запуск только сканера уязвимостей и бэкдоров без изменения конфигурации ОС. |
| **`--skip-audit`** | Пропуск предварительного аудита перед установкой. |

---

## ◈ Комплексная безопасность

### 1. Сканер целостности и бэкдоров (`audit.sh`)
Перед любыми изменениями Bastion проводит аудит системы на наличие скрытых компрометаций:
* **`LD_PRELOAD` Rootkits**: Инспекция `/etc/ld.so.preload` на наличие библиотечных перехватчиков (Userland rootkits).
* **Скрытые суперпользователи**: Выявление нелегитимных аккаунтов с `UID 0` в `/etc/passwd`.
* **Пустые хэши паролей**: Проверка `/etc/shadow` на учетные записи с возможностью входа без пароля.
* **Cron & Timers Reverse Shells**: Поиск сигнатур шеллов (`/dev/tcp`, `curl|sh`, `nc -e`, `ncat`, `socat`) в планировщиках задач.
* **GTFOBins SUID бинарники**: Аудит опасных SUID-битов на системных утилитах (`nmap`, `vim`, `bash`, `python` и др.).
* **Вредоносный код в temp-директориях**: Поиск подозрительных исполняемых файлов в `/tmp` и `/dev/shm`.

### 2. Защита OpenSSH
* **Современный криптографический стек**: Drop-in конфиг `00-bastion.conf`, Kex `curve25519-sha256`, `diffie-hellman-group16-sha512`, шифры `chacha20-poly1305`, `aes256-gcm`, MACs `hmac-sha2-512-etm`.
* **Защита от спуфинга и инъекций**: `HostbasedAuthentication no`, `IgnoreRhosts yes`, отключение X11 и перенаправления агентов.
* **Защита от Lockout**: Проверка синтаксиса `sshd -t` с авто-откатом при ошибках, аварийный порт 22 с rate-limit и гарантированное сокет-детектирование (`ssh.socket`).
* **Безопасная работа с ключами**: Поддержка ED25519/RSA, отложенное отключение парольной аутентификации через сгенерированный хелпер `/root/bastion-disable-password-auth.sh`.

### 3. Экранирование ядра и изоляция
* **Изоляция процессов (`hidepid=2`)**: Монтирование `/proc` с параметром `hidepid=2` скрывает чужие процессы от обычных пользователей и взломанных демонов (`www-data`).
* **Ограничение компиляторов**: Ограничение прав (`chmod 700`) на `gcc`, `g++`, `make`, блокирующее сборку эксплойтов повышения привилегий локальными пользователями.
* **Защита `/dev/shm`**: Монтирование с опциями `noexec,nosuid,nodev` против запуска скриптов из оперативной памяти.
* **Сетевой DoS Shield**: Криптографические `tcp_syncookies`, RFC 1337 (TIME-WAIT assassination fix), антиспуфинг `rp_filter`, блокировка ICMP redirects.
* **Защита памяти ядра**: `kernel.kptr_restrict = 2`, `kernel.dmesg_restrict = 1`, `net.core.bpf_jit_harden = 2`, `fs.suid_dumpable = 0`.

### 4. Фаервол и защита от брутфорса
* **Fail2Ban (systemd-native)**: Чтение журнала через `python3-systemd`, авто-вайтлист текущего IP администратора, одновременный контроль рабочего и резервного портов.
* **UFW Firewall**: Запрет входящего трафика по умолчанию, rate-limit на порты SSH (`ufw limit`), автодетектирование уже запущенных сервисов.

---

## ◈ Сетевой разгон и оптимизация

* **Google BBR**: Независимый модуль `98-bbr.conf` с дисциплиной очередей `fq` — минимальный пинг и максимальная пропускная способность.
* **Буферы TCP**: Расширение окон сокетов до 16 МБ для высокоскоростных каналов.
* **Лимиты файлов**: Поднятие системного лимита дескрипторов `nofile` до 65 535.
* **Интеллектуальный Swap**: Автовыделение swap-файла с проверкой свободного диска, флагом `nofail` в `/etc/fstab` и приоритетом RAM (`swappiness = 10`).

---

# 🇬🇧 English

## ◈ Overview

**Bastion** is an autonomous security hardening, malware inspection, and performance optimization suite engineered by **laguser** for modern Linux servers (Ubuntu & Debian).
Completely self-contained with zero telemetry, and lockout-safe by design: password authentication is never prematurely disabled, `sshd -t` validates configuration before applying, and emergency fallback rules keep your connection alive.

---

## ◈ Operating Modes & CLI Flags

| Flag / Mode | Description |
| :--- | :--- |
| **`[1] Automatic (Recommended)`** | Instant deployment of hardened production defaults with zero prompts. |
| **`[2] Interactive Wizard`** | Guided step-by-step setup: keys, ports, swap, procfs isolation, and tuning. |
| **`--auto` / `-y`** | Unattended auto mode for cloud orchestration and CI/CD pipelines. |
| **`--audit-only`** | Execute standalone security and backdoor inspection without modifying system files. |
| **`--skip-audit`** | Skip preliminary backdoor scanning phase. |

---

## ◈ Security Architecture

* **Pre-deployment Backdoor Audit (`audit.sh`)**: Detects `LD_PRELOAD` hooks, rogue `UID 0` accounts, blank shadow passwords, cron reverse shells, and malicious SUID binaries.
* **Strict OpenSSH Cryptography**: Prioritized drop-in configuration, curve25519/diffie-hellman key exchange, chacha20/aes-gcm ciphers, and lockout-safe verification.
* **System Hardening & Process Isolation**: `/proc` mounted with `hidepid=2`, compiler lockdown (`chmod 700` on gcc/g++/make), `/dev/shm` hardened with `noexec,nosuid,nodev`.
* **Kernel DoS Defense & eBPF Shield**: SYN cookies, RFC 1337, `bpf_jit_harden = 2`, `kptr_restrict`, and restricted core dumps.
* **Intelligent Firewall & Brute-Force Defense**: UFW rate-limiting, systemd-native Fail2Ban, auto-whitelisting of active management sessions.
* **Google TCP BBR**: Kernel-level network acceleration with Fair Queuing (`fq`) for lowest latency and maximum throughput.

---

## ◈ Author

Engineered with 🤍 by **laguser** — [github.com/laguser](https://github.com/laguser)  
Project Repository: [github.com/laguser/bastion](https://github.com/laguser/bastion)
