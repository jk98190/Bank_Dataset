# Bank Marketing Campaign Analysis

Leakage-safe analysis of the UCI Bank Marketing campaign data using Python's standard library and SQLite-compatible SQL.

## Overview

This project cleans the Bank Marketing data, establishes the correct relationship between the two supplied CSV files, and produces actionable customer-targeting insights without using post-call information.

The analysis finds that `bank.csv` is a complete 4,521-row subset of `bank-full.csv` (45,211 rows). It must **not** be joined to or appended to the full dataset because that would double-count campaign contacts. `bank-full.csv` is used as the canonical analysis dataset.

## Repository contents

| File | Purpose |
|---|---|
| `outputs/bank_campaign_analysis.py` | Cleans data, verifies file containment, prints segment findings and recommendations, and creates the cleaned CSV. |
| `outputs/bank_campaign_queries.sql` | Ten SQLite-compatible queries for data quality, segmentation, conversion, and targeting analysis. |
| `outputs/bank_campaign_clean.csv` | Cleaned canonical version of `bank-full.csv` with derived analysis fields. |
| `outputs/bank_campaign_readme.md` | Detailed analysis notes, findings, and assumptions. |

## Data requirements

Download the UCI Bank Marketing files and place them anywhere accessible locally:

- `bank-full.csv`
- `bank.csv`

The files use semicolon delimiters and contain 17 source columns. The source data is not redistributed in this repository.

## Run the analysis

No third-party Python packages are required.

```bash
python3 outputs/bank_campaign_analysis.py \
  /path/to/bank-full.csv \
  /path/to/bank.csv
```

The script writes `outputs/bank_campaign_clean.csv` and prints the data-quality checks, conversion breakdowns, and recommendations.

## Cleaning and feature engineering

- Standardizes whitespace and categorical text case.
- Converts numeric fields to integers.
- Confirms expected schema and checks row-level containment between the files with a SHA-256 record fingerprint.
- Converts `pdays = -1` to a null `days_since_previous_contact` value and adds `previously_contacted`.
- Adds interpretable `age_band` and `balance_band` fields.
- Renames `duration` to `call_duration_seconds_post_call` to make its timing explicit.

## Leakage policy

`duration` must not be used in any pre-call targeting, model training, feature selection, or model evaluation. Call duration is only known after a call finishes, so including it would create target leakage and overstate model performance.

Permitted pre-call model inputs include age, job, marital status, education, balance, housing and personal-loan status, contact channel, day/month, prior-contact information, prior outcome, and historical campaign attempts. In production, use a customer ID and contact timestamp to perform customer-level, time-based validation.

## Key findings

| Segment | Conversion rate |
|---|---:|
| Overall | 11.7% |
| Previous campaign outcome: success | 64.7% |
| Previously contacted | 23.1% |
| No prior contact | 9.2% |
| Cellular contact | 14.9% |
| Unknown contact channel | 4.1% |
| One campaign attempt | 14.6% |
| Six or more attempts | 5.8% |

## Recommendations

1. Prioritize customers whose prior campaign outcome was successful, subject to a time-based holdout validation.
2. Favor cellular contact and improve unknown contact records before allocating calling capacity.
3. Begin with one contact attempt and limit excessive repeat outreach because conversion declines as campaign attempts increase.
4. Build a propensity model with only pre-call features and monitor outcomes by age band and other protected or sensitive segments as applicable.
5. Treat the findings as historical associations, not causal effects. Test targeting changes with a controlled experiment.

## SQL analysis

Import `outputs/bank_campaign_clean.csv` into a SQLite table called `bank_campaign_clean`, then run:

```bash
sqlite3 bank_campaign.db < outputs/bank_campaign_queries.sql
```

The SQL file includes ten queries covering the data-quality audit, channel performance, prior-contact effectiveness, outreach fatigue, monthly/channel planning, debt signals, demographic segments, and prior-success target groups.

## Limitations

- The source lacks a unique customer ID, a campaign year, and an exact contact timestamp.
- The smaller dataset is not an independent test set because all of its records occur in the full dataset.
- Segment differences may reflect past bank targeting decisions and other confounding factors.
- The analysis supports campaign prioritization; it does not establish causality.

## License

Use the source dataset according to its original license and terms. Add a project license before publishing if you want to define reuse terms for this repository's code.
