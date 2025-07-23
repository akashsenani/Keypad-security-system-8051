# 🔐 Keypad-Based Security System using 8051 Microcontroller

A multi-layered embedded security solution using password authentication, servo-controlled locking, motion detection, and LCD/buzzer feedback — built using the AT89S52 microcontroller.

---

## 🎯 Project Aim

To design a smart access control system that:
1. Restricts unauthorized access using a 5-digit keypad.
2. Opens and closes door via servo motor control.
3. Detects human presence using PIR sensor for auto-door closure.
4. Displays messages and status via LCD and buzzer.

---

## ⚙️ Hardware Used
| Component         | Description                                 |
|------------------|---------------------------------------------|
| 8051 MCU         | AT89S52 variant                             |
| 4x4 Keypad       | Password entry                              |
| 16x2 LCD         | Visual feedback (P0 for data, P2 for ctrl)  |
| SG90 Servo       | Lock/unlock mechanism (PWM via Timer0)      |
| HC-SR501 PIR     | Detects motion and auto-closes door         |
| Buzzer           | Alerts on wrong password                    |

---

## 🧠 Software Design (Assembly)

- **Password Storage**: Stored in memory (default: `12345`)
- **Keypad Scanning**: Matrix logic with software debouncing
- **LCD Handling**: 8-bit mode with custom routines
- **Servo PWM**: Simulated using delay loops for 1ms/2ms
- **PIR Monitoring**: Polling logic with auto-close feature

---

## 🧾 Features
- 🔐 5-digit password-based access
- 📟 LCD display for real-time instructions
- 🔊 Buzzer alert for wrong attempts
- 🔄 Auto-close door when motion detected
- ✅ Expandable for RFID, EEPROM, or voice alerts

---

## 🛠️ Folder Contents

- `Code/` – Assembly code (`.asm`)
- `Schematics/` – Circuit diagram(s)
- `Media/` – Images or video demos

---

## 🚀 Future Improvements

- ✅ RFID-based 2FA
- ✅ EEPROM logging of attempts
- ✅ Voice feedback via APR9600
- ✅ Low-power sleep modes
- ✅ Manual override switch

---

