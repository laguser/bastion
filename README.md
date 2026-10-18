<div align="center">
  <br>
  <h1>🏰 bastion</h1>
  <p><b>Hardened Linux VPS Security, Malware Inspection & TCP Acceleration Suite</b></p>
  
  <p>
    <code>audit</code> · <code>fail2ban</code> · <code>ufw</code> · <code>bbr</code> · <code>hidepid</code> · <code>ed25519</code> · <code>1-click-rollback</code>
  </p>

  <p>
    <a href="#-русский">русский</a> · <a href="#-english">english</a>
  </p>

  <p>
    <img src="https://img.shields.io/badge/os-ubuntu_%7C_debian-000000?style=flat-square&logo=linux&logoColor=white" alt="OS">
    <img src="https://img.shields.io/badge/author-laguser-000000?style=flat-square&logo=github&logoColor=white" alt="Author">
    <img src="https://img.shields.io/badge/audit-backdoor_scanner-000000?style=flat-square" alt="Audit">
    <img src="https://img.shields.io/badge/tcp-google_bbr-000000?style=flat-square" alt="TCP">
    <img src="https://img.shields.io/badge/tests-qemu_kvm_verified-000000?style=flat-square" alt="Tests">
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

Запуск только аудита и сканера бэкдоров (без изменения системы):
```bash
curl -sSLo audit.sh https://raw.githubusercontent.com/laguser/bastion/main/audit.sh
bash audit.sh
```

---

# 🇷🇺 Русский

## ◈ О проекте

**Bastion** — инструмент от **laguser** для превращения свежего Linux VPS (Ubuntu / Debian) в защищённый и производительный сервер за 60 секунд. 
Полностью автономен, не зависит от сторонних облачных API, не производит недоверенных внешних запросов и гарантирует защиту от случайной блокировки (Lockout Protection).

Включает автономный сканер компрометаций и бэкдоров, защиту от DoS-атак на уровне ядра, изоляцию процессов пользователей, разгон сети Google BBR, строгую фильтрацию трафика и возможность мгновенного отката в один клик.

---

## ◈ Сравнение с аналогами

| Параметр / Функция | **Bastion** | **dev-sec/ansible-collection-hardening** | **CIS Benchmark Bash Scripts** | **Базовый UFW + Fail2Ban** |
| :--- | :---: | :---: | :---: | :---: |
| **Время развертывания** | **⚡ ~60 сек** | ⏳ 5-15 мин (требует Ansible/Python) | ⏳ 10-30 мин | ⚡ 1-2 мин |
| **Автономный сканер бэкдоров** | **✅ Встроен (`audit.sh`)** | ❌ Нет | ❌ Нет | ❌ Нет |
| **Защита от Lockout (потери SSH)** | **✅ Двойной порт + sshd -t + сокеты** | ⚠️ Средняя (легко заблокировать доступ) | ❌ Нет авто-отката | ❌ Высокий риск lockout |
| **Разгон сети Google BBR + TCP буферы** | **✅ Да (98-bbr.conf + FQ)** | ❌ Нет (только ограничения) | ❌ Нет | ❌ Нет |
| **Процессная изоляция (`/proc hidepid=2`)** | **✅ Да** | ⚠️ Опционально | ⚠️ Зависит от версии | ❌ Нет |
| **Ограничение прав компиляторов (`gcc/make`)** | **✅ Да (`chmod 700`)** | ❌ Редко | ⚠️ Частично | ❌ Нет |
| **Защита памяти `/dev/shm` (noexec)** | **✅ Да** | ✅ Да | ✅ Да | ❌ Нет |
| **1-Click скрипт отката (`rollback.sh`)** | **✅ Автогенерация** | ❌ Ручной откат snapshot | ❌ Ручной откат | ❌ Нет |
| **Неинтерактивный режим для CI/CD** | **✅ Флаг `--auto`** | ✅ Да | ⚠️ Зависит от параметров | ⚠️ Требует скриптования |

---

## ◈ Результаты стресс-тестирования в виртуальной машине (QEMU/KVM)

Скрипт и его механизмы защиты протестированы в боевых условиях на чистом облачном инстансе **Ubuntu 24.04 LTS (Noble Numbat)** в виртуальной машине **QEMU/KVM**:

```text
======================================================
     BASTION HARDENING & RESILIENCE TEST RESULTS
======================================================
[✔] Bash syntax & shell integrity check ........... PASS
[✔] Input clamping & port boundary logic .......... PASS
[✔] OpenSSH ED25519 public key regex validator .... PASS
[✔] Malformed SSH injection key rejection ......... PASS
[✔] Shared memory (/dev/shm) noexec execution ..... BLOCKED (Permission denied)
[✔] Unprivileged compiler execution (gcc/make) .... BLOCKED (Permission denied)
[✔] L4 DoS & SYN Flood protection (syncookies) .... ACTIVE
[✔] OpenSSH strict ciphers negotiation ............ VERIFIED (ChaCha20-Poly1305 / ED25519)
[✔] Brute-force rate limiting (ufw-user-limit) .... ENFORCED (Drops after burst)
[✔] 1-Click Rollback script execution ............. VERIFIED (Clean restoration)
======================================================
```

### Тестирование детекции бэкдоров:
Внутри тестовой ВМ были смоделированы 4 распространенных вектора закрепления атакующих:
1. **Userland Rootkit**: Инжекция библиотеки через `/etc/ld.so.preload` → **ОБНАРУЖЕНО**
2. **Скрытый root-аккаунт**: Создание стороннего пользователя с `UID 0` (`toor:x:0:0...`) → **ОБНАРУЖЕНО**
3. **Cron Reverse Shell**: Внедрение таймера с `/bin/bash -i >& /dev/tcp/...` → **ОБНАРУЖЕНО**
4. **SUID Privilege Escalation**: Копирование `/bin/bash` с правами `4755` в `/tmp` → **ОБНАРУЖЕНО**

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
* **`LD_PRELOAD` Rootkits**: Инспекция `/etc/ld.so.preload` на библиотечные перехватчики.
* **Скрытые суперпользователи**: Выявление нелегитимных аккаунтов с `UID 0` в `/etc/passwd`.
* **Пустые хэши паролей**: Проверка `/etc/shadow` на учетные записи с возможностью входа без пароля.
* **Cron & Timers Reverse Shells**: Поиск сигнатур шеллов (`/dev/tcp`, `curl|sh`, `nc -e`, `ncat`, `socat`) в планировщиках.
* **GTFOBins SUID бинарники**: Аудит опасных SUID-битов на системных утилитах (`nmap`, `vim`, `bash`, `python` и др.).
* **Вредоносный код в temp-директориях**: Поиск подозрительных исполняемых файлов в `/tmp` и `/dev/shm`.

### 2. Защита OpenSSH
* **Современный криптографический стек**: Drop-in конфиг `00-bastion.conf`, Kex `curve25519-sha256`, `diffie-hellman-group16-sha512`, шифры `chacha20-poly1305`, `aes256-gcm`, MACs `hmac-sha2-512-etm`.
* **Защита от спуфинга и инъекций**: `HostbasedAuthentication no`, `IgnoreRhosts yes`, отключение X11 и перенаправления агентов.
* **Защита от Lockout**: Проверка синтаксиса `sshd -t` с авто-откатом при ошибках, аварийный порт 22 с rate-limit и сокет-детектирование (`ssh.socket`).
* **Безопасная работа с ключами**: Поддержка ED25519/RSA, отложенное отключение парольной аутентификации через сгенерированный хелпер `/root/bastion-disable-password-auth.sh`.

### 3. Экранирование ядра и изоляция
* **Изоляция процессов (`hidepid=2`)**: Монтирование `/proc` с параметром `hidepid=2` скрывает чужие процессы от обычных пользователей и взломанных сервисов.
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

## ◈ Comparison with Alternatives

| Feature / Metric | **Bastion** | **dev-sec/ansible-hardening** | **CIS Benchmark Shell Scripts** | **Basic UFW + Fail2Ban** |
| :--- | :---: | :---: | :---: | :---: |
| **Deployment Time** | **⚡ ~60s** | ⏳ 5-15 min (requires Ansible) | ⏳ 10-30 min | ⚡ 1-2 min |
| **Built-in Backdoor Scanner** | **✅ Included (`audit.sh`)** | ❌ No | ❌ No | ❌ No |
| **Lockout Protection** | **✅ Dual port + sshd -t + systemd socket** | ⚠️ Moderate (easy to misconfigure) | ❌ No auto-revert | ❌ High risk |
| **Google BBR + TCP Tuning** | **✅ Yes (98-bbr.conf + FQ)** | ❌ No | ❌ No | ❌ No |
| **Process Isolation (`/proc hidepid=2`)**| **✅ Yes** | ⚠️ Optional | ⚠️ Version dependent | ❌ No |
| **Compiler Access Lockdown (`gcc`)** | **✅ Yes (`chmod 700`)** | ❌ Rarely | ⚠️ Partial | ❌ No |
| **1-Click Rollback Script (`rollback.sh`)** | **✅ Generated automatically** | ❌ Manual snapshot rollback | ❌ Manual recovery | ❌ No |
| **CI/CD Unattended Mode** | **✅ `--auto` flag** | ✅ Yes | ⚠️ Complex | ⚠️ Custom scripting |

---

## ◈ Tested in Virtualized Conditions (QEMU/KVM)

All defensive modules and self-healing mechanisms are battle-tested inside isolated **Ubuntu 24.04 LTS (Noble)** environments using **QEMU/KVM**:
* **Exploit prevention**: Verified blocking of arbitrary script execution on `/dev/shm` via `noexec`.
* **Privilege escalation mitigation**: Verified compiler lockdown preventing non-root users from executing `gcc`.
* **Real-world backdoor detection**: 100% detection rate on injected `LD_PRELOAD` hooks, rogue UID 0 users, cron reverse shells, and GTFOBins SUID binaries.
* **1-Click recovery**: Verified instant restoration of all original system files via `/var/backups/bastion/<timestamp>/rollback.sh`.

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

## ◈ Author

Engineered with 🤍 by **laguser** — [github.com/laguser](https://github.com/laguser)  
Project Repository: [github.com/laguser/bastion](https://github.com/laguser/bastion)
