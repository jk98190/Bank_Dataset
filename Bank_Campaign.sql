-- SQLite-compatible SQL. Load outputs/bank_campaign_clean.csv as bank_campaign_clean.
-- Target: y = 'yes'. Do NOT use call_duration_seconds_post_call in pre-contact targeting.

-- 1. Data-quality and leakage audit
SELECT COUNT(*) AS records,
       SUM(CASE WHEN y = 'yes' THEN 1 ELSE 0 END) AS subscriptions,
       ROUND(100.0 * AVG(CASE WHEN y = 'yes' THEN 1.0 ELSE 0 END), 2) AS conversion_pct,
       SUM(CASE WHEN duration IS NOT NULL THEN 1 ELSE 0 END) AS post_call_field_present
FROM bank_full;

-- 2. Conversion by previous-campaign outcome
SELECT poutcome, COUNT(*) AS contacts,
       SUM(y = 'yes') AS subscriptions,
       ROUND(100.0 * AVG(y = 'yes'), 2) AS conversion_pct
FROM bank_full GROUP BY poutcome ORDER BY conversion_pct DESC;

-- 3. Contact channel effectiveness
SELECT contact, COUNT(*) AS contacts, SUM(y = 'yes') AS subscriptions,
       ROUND(100.0 * AVG(y = 'yes'), 2) AS conversion_pct
FROM bank GROUP BY contact ORDER BY conversion_pct DESC;

-- 4. Previously contacted versus new prospect
SELECT previously_contacted, COUNT(*) AS contacts, SUM(y = 'yes') AS subscriptions,
       ROUND(100.0 * AVG(y = 'yes'), 2) AS conversion_pct
FROM (
    SELECT *, CASE WHEN pdays = -1 THEN 'No' ELSE 'Yes' END AS previously_contacted
    FROM bank
) GROUP BY previously_contacted ORDER BY conversion_pct DESC;

-- 5. Outreach-fatigue curve
SELECT CASE WHEN campaign = 1 THEN '1' WHEN campaign <= 3 THEN '2-3'
            WHEN campaign <= 5 THEN '4-5' ELSE '6+' END AS attempt_band,
       COUNT(*) AS contacts, ROUND(100.0 * AVG(y = 'yes'), 2) AS conversion_pct
FROM bank GROUP BY attempt_band
ORDER BY CASE attempt_band WHEN '1' THEN 1 WHEN '2-3' THEN 2 WHEN '4-5' THEN 3 ELSE 4 END;

-- 6. Month and channel planning matrix
SELECT month, contact, COUNT(*) AS contacts,
       ROUND(100.0 * AVG(y = 'yes'), 2) AS conversion_pct
FROM bank GROUP BY month, contact
HAVING COUNT(*) >= 30 ORDER BY conversion_pct DESC, contacts DESC;

-- 7. Household-debt signal
SELECT housing, loan, COUNT(*) AS contacts, SUM(y = 'yes') AS subscriptions,
       ROUND(100.0 * AVG(y = 'yes'), 2) AS conversion_pct
FROM bank_full GROUP BY housing, loan ORDER BY conversion_pct DESC;

-- 8. Age and balance segments
SELECT age_band, balance_band, COUNT(*) AS contacts,
       ROUND(100.0 * AVG(y = 'yes'), 2) AS conversion_pct
FROM (
    SELECT y,
           multiIf(age < 30, 'Under 30', age < 40, '30-39', age < 50, '40-49', age < 60, '50-59', '60+') AS age_band,
           multiIf(balance < 0, 'Negative', balance < 1000, '0-999', balance < 5000, '1000-4999', balance < 10000, '5000-9999', '10000+') AS balance_band
    FROM bank
) GROUP BY age_band, balance_band
HAVING COUNT(*) >= 50 ORDER BY conversion_pct DESC;

-- 9. Job / education segments with sufficient volume
SELECT job, education, COUNT(*) AS contacts, SUM(y = 'yes') AS subscriptions,
       ROUND(100.0 * AVG(y = 'yes'), 2) AS conversion_pct
FROM bank GROUP BY job, education
HAVING COUNT(*) >= 100 ORDER BY conversion_pct DESC, contacts DESC;

-- 10. Prior-success target list (all inputs are available before the next call)
SELECT job,
       multiIf(age < 30, 'Under 30', age < 40, '30-39', age < 50, '40-49', age < 60, '50-59', '60+') AS age_band,
       contact,
       COUNT(*) AS contacts,
       SUM(y = 'yes') AS subscriptions,
       ROUND(100.0 * AVG(y = 'yes'), 2) AS conversion_pct
FROM bank_full
WHERE poutcome = 'success' AND previous > 0
GROUP BY job, age_band, contact HAVING COUNT(*) >= 20
ORDER BY conversion_pct DESC, contacts DESC;
