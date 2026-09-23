# Reconix: Enterprise Kenyan VAT 3-Way Reconciliation & Audit Defense Platform

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11-0175C2?logo=dart)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Windows%20Desktop%20%7C%20Web-blue)](#installation--setup)
[![License](https://img.shields.io/badge/License-Proprietary-gold.svg)](#license)
[![KRA eTIMS](https://img.shields.io/badge/KRA-eTIMS%20%26%20TIMS%20ETR%20Certified-emerald)](#kra-regulatory-compliance)

**Reconix** is a high-performance, enterprise-grade tax compliance and audit defense platform built specifically for Kenyan corporate taxpayers, finance directors, and ICPAK certified audit firms. 

It automates **3-Way Reconciliation** between internal accounting ledgers (ERP/POS), live Kenya Revenue Authority (KRA) eTIMS & hardware TIMS ETR server transmissions, and auto-populated iTax pre-filled schedules—eliminating **VAT Automated Assessment (VAA)** back-tax disallowances and Section 16(1) corporate tax deductibility penalties.

---

## Key Features & Enterprise Capabilities

### 1. Automated 3-Way VAT Matching Engine
- **Cross-Reference Matrix**: Reconciles transactions by Control Code, ETR CU Serial Number, Supplier KRA PIN, Invoice Date, and Tax Amounts across 3 independent data streams.
- **6 Precision Compliance Statuses**:
  - `Matched (100% Safe)`: Verified 3-way match ready for Section B input VAT claim.
  - `Timing Latency`: Identifies vendor invoices transmitted after month-end tax cutoff.
  - `Unclaimed Input VAT`: Uncovers omitted input VAT credits in internal books to claim extra KES refunds.
  - `VAA Disallowance Risk`: Identifies ERP claims lacking eTIMS control codes **BEFORE** return submission.
  - `Expense Validation Risk`: Highlights non-eTIMS purchases threatened under 2026 expense deductibility rules.
  - `Mismatched Amounts`: Pinpoints discrepancies between ERP booked tax and eTIMS transmitted tax.

### 2. KRA iTax Form VAT 7 Filing Bundle Exporter
- **4-in-1 CSV Schedule Exporter**: Generates sanitized CSV upload bundles for:
  - **Section A**: Output VAT Sales Register
  - **Section B**: Input VAT Purchases Schedule (sanitized to contain ONLY 3-way verified claimable records)
  - **Section C**: Customs Import VAT Schedule
  - **Section D**: 2% Withholding VAT (WHVAT) Schedule
- **Pre-Flight Audit Validation Engine**: Evaluates KRA iTax rules, PIN syntax, tax rates (16%, 8%, 0%), and 6-month statutory claim limits prior to export.

### 3. Specialized Enterprise Ledgers
- **2% Withholding VAT (WHVAT) Certificate Ledger**: Reconciles certificates issued by appointed withholding agents (KCB, Equity, Safaricom, Government Ministries) against sales invoices to reduce net tax payable.
- **Customs Import C17 Entry Ledger (Section C)**: Ingests SIMBA/ICMS C17 customs import entries for Mombasa Port and JKIA Airport imports, reconciling CIF values, duty paid, and 16% import VAT.

### 4. Direct ERP Connectors & Automated Ingestion
- **Tally Prime XML Parser**: Native XML interchange parser (`parseTallyXml`) reading `<VOUCHER>` elements directly.
- **QuickBooks CSV Parser**: Automatically parses QuickBooks Desktop & Online Purchase Registers and vendor PINs (`parseQuickBooksCsv`).
- **SAP Business One & Sage**: Ingests `OPCH` / `PCH1` purchase analysis query dumps and audit trails.
- **JSON Webhook Standard**: Real-time REST API endpoint (`/api/v1/ingest/erp`) for automated nightly ERP sync.
- **Sample CSV Templates Manager**: Interactive previews and 1-click CSV template downloads for all 5 import streams.

### 5. Supplier Behavioral Latency & Dispute Chaser Engine
- **Vendor Risk Scorecard**: Tracks supplier eTIMS transmission delay frequency and assigns risk tiers (*Low*, *Moderate*, *High VAA Risk*).
- **Automated Dispute Notice Chaser**: Generates formal Email & WhatsApp dispute notices complete with supplier PIN, missing control codes, and statutory disallowance warnings.

### 6. KRA Statutory Penalty & Interest Exposure Simulator
- Real-time simulation of KRA statutory penalties under Section 38, 83 & 84 of the Tax Procedures Act (TPA):
  - **Sec. 83 Late Filing Penalty**: 5% of tax due or KES 10,000 statutory minimum.
  - **Sec. 38 Late Payment Interest**: 1% simple interest per month.
  - **Sec. 84 VAA Disallowance Penalty**: 20% penalty threat on disallowed input claims.

### 7. Executive Reporting & Audit Working Papers
- **PDF Audit Defense Binder**: Multi-page formal PDF report complete with Executive Certificate of Reconciliation, VAA Disallowance Risk Schedule, eTIMS Verification Matrix, and Audit Trail Transcript.
- **Multi-Tab Excel Workbook**: Export `.xlsx` files with structured sheets for *Executive Summary*, *ERP Purchase Ledger*, *eTIMS Verification*, and *Audit Logs*.
- **Tax Period Lock Workflow**: Allows Senior Partners (`admin` / `auditor`) to sign off and lock a tax period (`is_locked = 1`), preserving working paper integrity.
- **SQLite Schema v5 & DB Backup/Restore**: Full multi-company data isolation, RBAC logging, and 1-click database snapshot exports.

---

## 🏗️ Architecture & Data Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           DATA INGESTION HUB                            │
│  ┌──────────────────────┐  ┌──────────────────────┐  ┌───────────────┐  │
│  │ eTIMS / TIMS ETR CSV │  │ ERP Ledger / XML/CSV │  │ iTax SEC-B CSV│  │
│  └──────────┬───────────┘  └──────────┬───────────┘  └───────┬───────┘  │
└─────────────│─────────────────────────│──────────────────────│──────────┘
              │                         │                      │
              ▼                         ▼                      ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                   3-WAY VAT RECONCILIATION ENGINE                       │
│  - Control Code Matching   - KRA PIN Syntax Check   - Date/Rate Check   │
└───────────────────────────────────┬─────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                     COMPLIANCE & EXPORT HUB                             │
│  ┌─────────────────────┐  ┌──────────────────────┐  ┌────────────────┐ │
│  │ KRA VAT 7 CSV Bundle│  │ PDF Audit Defense Pack│ │  WHVAT & C17   │ │
│  └─────────────────────┘  └──────────────────────┘  └────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Installation & Setup

### Option 1: Standalone Windows Installer (Recommended for End-Users)
Download the 1-click Windows Setup Wizard executable from the release build:
```
build/installer/Reconix_Setup_v1.0.0.exe
```
Double-click `Reconix_Setup_v1.0.0.exe` to run the installation wizard. It will create a **Desktop Shortcut ("Reconix VAT Platform")** and bundle all Visual C++ runtime dependencies automatically.

### Option 2: Build from Source (Developers)

#### Prerequisites
- Flutter SDK (v3.11.1 or higher)
- Visual Studio 2022 with C++ Desktop Development Workload (for Windows Desktop compilation)

#### 1. Clone Repository
```bash
git clone https://github.com/Pearl-Techno/Reconix.git
cd Reconix
```

#### 2. Install Dependencies
```bash
flutter pub get
```

#### 3. Run Application locally
```bash
# Run on Windows Desktop
flutter run -d windows

# Run on Web Browser
flutter run -d chrome
```

#### 4. Run Automated Test Suite
```bash
flutter test
```

#### 5. Build Production Windows Executable
```bash
# 1. Compile Flutter release binary
flutter build windows --release

# 2. Package into 1-click Windows Setup Wizard
powershell -ExecutionPolicy Bypass -File .\create_installer.ps1
```

---

## Project Structure

```
reconix/
├── lib/
│   ├── main.dart                       # App entry point & theme configuration
│   ├── models/                         # Data models (Invoice, WHVAT, Customs, AuditLog)
│   ├── providers/                      # AppState (ChangeNotifier state management)
│   ├── services/                       # Business logic services
│   │   ├── reconciliation_engine.dart  # 3-Way matching core engine
│   │   ├── database_service.dart       # SQLite Schema v5 persistence layer
│   │   ├── erp_connector_service.dart  # Tally XML & QuickBooks CSV parsers
│   │   ├── itax_filing_bundle_service.dart # KRA Form VAT 7 bundle exporter
│   │   ├── penalty_simulator_service.dart  # Tax Procedures Act Sec. 38 simulator
│   │   ├── audit_defense_pack_service.dart # PDF & Excel audit defense exporter
│   │   └── sample_template_service.dart   # CSV template generators
│   ├── theme/                          # AppColors, HSL palettes, glassmorphism styles
│   └── views/                          # UI View screens & interactive modals
│       ├── getting_started_view.dart   # Landing overview & step-by-step workflow
│       ├── ingestion_view.dart         # Multi-Source Data Ingestion Hub
│       ├── reconciliation_view.dart    # 3-Way Matching Ledger
│       ├── whvat_reconciliation_view.dart # 2% WHVAT Certificate Ledger
│       ├── historical_trend_view.dart  # Multi-Period Analytics & Vendor Risk
│       ├── evidence_pack_view.dart     # Audit Evidence Hub & PDF/Excel Exporter
│       ├── tax_exposure_calculator_view.dart # Penalty Simulator & CIT exposure
│       └── widgets/                    # Dialog modals & interactive tools
├── test/                               # Automated unit & integration test suites
│   ├── commercial_features_test.dart   # Enterprise features test suite
│   └── operational_features_test.dart  # Operational features & penalty simulator tests
├── create_installer.ps1                # PowerShell build & packaging script
├── reconix_installer.iss               # Inno Setup compiler configuration
└── pubspec.yaml                        # Flutter project configuration
```

---

## KRA Regulatory Compliance Notices

- **Tax Procedures Act (Cap 469B)**: Complies with Section 38 (Interest on Unpaid Tax), Section 83 (Late Filing Penalty), and Section 84 (Understatement & Disallowance Penalties).
- **VAT Act 2013 & Regulations**: Supports Section B Input VAT deduction rules, Section C Customs Import VAT claims, and Section D 2% Withholding VAT deduction certificates.
- **Income Tax Act Sec 16(1)**: Validates non-eTIMS purchase disallowances under corporate income tax expense deductibility rules.

---

## Commercial Licensing, Acquisition & Developer Contact

- **Lead Developer**: **Davies Mukoya**
- **Company**: **Quantyx Labs**
- **Contact Email**: [`info@quantyx.co.ke`](mailto:info@quantyx.co.ke)
- **WhatsApp / M-Pesa / Buy Coffee**: **`+254702687799`**
- **Repository Maintenance**: **Pearl Techno** ([Pearl-Techno/Reconix](https://github.com/Pearl-Techno/Reconix))

### Commercial Access & License Requirements

> [!IMPORTANT]
> **System Usage Policy**: Reconix is protected by an obfuscated First-Run Licensing & Activation Engine. Acquiring or cloning the codebase requires a minimum commercial fee of **KES 15,000**. On first execution, the system requires inputting an activation key (Master Key `120196` is built-in and verified via salted hash digest). The system license is valid for **365 days** and must be renewed annually for **KES 20,000** paid to account/till **`quantyx001`** (Quantyx Labs).

- **Buy the Lead Engineer Coffee ☕**: Support ongoing development via M-Pesa: **`+254702687799`** (Davies Mukoya / Quantyx Labs).
- **Copyright**: © 2026 Quantyx Labs & Reconix Technologies. All rights reserved.

