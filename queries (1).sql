-- Financial Expense & Invoice Analysis | SQL for FP&A
-- SQL dialect: PostgreSQL
-- Run schema.sql, import the CSV files, and execute this file in pgAdmin 4.
-- All data is synthetic. Invoice date is used as a simplified proxy for expense period.
-- 20 foundational-to-intermediate queries, including 3 CTE-based analyses.

-- ============================================================
-- 01. Dataset overview
-- Business question: What is the overall size and value of the invoice dataset?
-- Concepts: COUNT, COUNT DISTINCT, SUM, AVG
-- ============================================================
SELECT
    COUNT(*) AS invoice_count,
    COUNT(DISTINCT vendor_id) AS vendors_used,
    ROUND(SUM(invoice_amount), 2) AS gross_invoice_value,
    ROUND(AVG(invoice_amount), 2) AS average_invoice_value
FROM invoices;

-- ============================================================
-- 02. Monthly invoiced spend
-- Business question: How much was invoiced in each month?
-- Concepts: DATE_TRUNC, GROUP BY, ORDER BY
-- ============================================================
SELECT
    DATE_TRUNC('month', invoice_date)::DATE AS invoice_month,
    ROUND(SUM(invoice_amount), 2) AS invoiced_spend
FROM invoices
GROUP BY DATE_TRUNC('month', invoice_date)::DATE
ORDER BY invoice_month;

-- ============================================================
-- 03. Spend by department
-- Business question: Which departments have the highest invoice spend?
-- Concepts: GROUP BY, COUNT, SUM, AVG
-- ============================================================
SELECT
    department,
    COUNT(*) AS invoice_count,
    ROUND(SUM(invoice_amount), 2) AS total_spend,
    ROUND(AVG(invoice_amount), 2) AS average_invoice_value
FROM invoices
GROUP BY department
ORDER BY total_spend DESC;

-- ============================================================
-- 04. Spend by expense category
-- Business question: Which expense categories drive expenditure?
-- Concepts: GROUP BY, SUM, ORDER BY
-- ============================================================
SELECT
    expense_category,
    COUNT(*) AS invoice_count,
    ROUND(SUM(invoice_amount), 2) AS total_spend
FROM invoices
GROUP BY expense_category
ORDER BY total_spend DESC;

-- ============================================================
-- 05. Top 10 vendors by invoice value
-- Business question: Which suppliers account for the largest invoice values?
-- Concepts: INNER JOIN, GROUP BY, ORDER BY, LIMIT
-- ============================================================
SELECT
    v.vendor_name,
    COUNT(i.invoice_id) AS invoice_count,
    ROUND(SUM(i.invoice_amount), 2) AS total_invoiced
FROM vendors v
JOIN invoices i ON i.vendor_id = v.vendor_id
GROUP BY v.vendor_id, v.vendor_name
ORDER BY total_invoiced DESC
LIMIT 10;

-- ============================================================
-- 06. Monthly budget vs actual by department [CTE 1 of 3]
-- Business question: Which department/month combinations are over or under budget?
-- Concepts: CTE, LEFT JOIN, COALESCE, CASE, NULLIF
-- Positive variance means actual spend is above budget.
-- ============================================================
WITH actuals AS (
    SELECT
        DATE_TRUNC('month', invoice_date)::DATE AS budget_month,
        department,
        SUM(invoice_amount) AS actual_spend
    FROM invoices
    GROUP BY DATE_TRUNC('month', invoice_date)::DATE, department
)
SELECT
    b.budget_month,
    b.department,
    ROUND(b.budget_amount, 2) AS budget_amount,
    ROUND(COALESCE(a.actual_spend, 0), 2) AS actual_spend,
    ROUND(COALESCE(a.actual_spend, 0) - b.budget_amount, 2) AS variance_amount,
    ROUND(
        100.0 * (COALESCE(a.actual_spend, 0) - b.budget_amount)
        / NULLIF(b.budget_amount, 0), 2
    ) AS variance_pct,
    CASE
        WHEN COALESCE(a.actual_spend, 0) > b.budget_amount THEN 'Over Budget'
        WHEN COALESCE(a.actual_spend, 0) < b.budget_amount THEN 'Under Budget'
        ELSE 'On Budget'
    END AS budget_status
FROM monthly_budgets b
LEFT JOIN actuals a
    ON a.budget_month = b.budget_month
    AND a.department = b.department
ORDER BY b.budget_month, b.department;

-- ============================================================
-- 07. Annual budget vs actual by department
-- Business question: Which departments exceeded their total budget?
-- Concepts: GROUP BY, LEFT JOIN, COALESCE, derived tables
-- ============================================================
SELECT
    b.department,
    ROUND(b.annual_budget, 2) AS annual_budget,
    ROUND(COALESCE(a.actual_spend, 0), 2) AS actual_spend,
    ROUND(COALESCE(a.actual_spend, 0) - b.annual_budget, 2) AS variance_amount
FROM (
    SELECT department, SUM(budget_amount) AS annual_budget
    FROM monthly_budgets
    GROUP BY department
) b
LEFT JOIN (
    SELECT department, SUM(invoice_amount) AS actual_spend
    FROM invoices
    GROUP BY department
) a ON a.department = b.department
ORDER BY variance_amount DESC;

-- ============================================================
-- 08. Invoice-level outstanding balances [CTE 2 of 3]
-- Business question: How much remains unpaid on each invoice?
-- Concepts: CTE, SUM, LEFT JOIN, COALESCE
-- ============================================================
WITH payment_totals AS (
    SELECT invoice_id, SUM(payment_amount) AS total_paid
    FROM payments
    GROUP BY invoice_id
)
SELECT
    i.invoice_id,
    i.vendor_name,
    i.department,
    i.invoice_date,
    i.due_date,
    ROUND(i.invoice_amount, 2) AS invoice_amount,
    ROUND(COALESCE(p.total_paid, 0), 2) AS total_paid,
    ROUND(i.invoice_amount - COALESCE(p.total_paid, 0), 2) AS outstanding_amount
FROM invoices i
LEFT JOIN payment_totals p ON p.invoice_id = i.invoice_id
ORDER BY outstanding_amount DESC;

-- ============================================================
-- 09. Outstanding payables by vendor
-- Business question: Which vendors have the largest estimated unpaid balances?
-- Concepts: JOIN, GROUP BY, HAVING, derived table
-- ============================================================
SELECT
    v.vendor_name,
    COUNT(i.invoice_id) AS invoice_count,
    ROUND(SUM(i.invoice_amount), 2) AS invoice_value,
    ROUND(SUM(i.invoice_amount - COALESCE(p.total_paid, 0)), 2) AS outstanding_amount
FROM invoices i
JOIN vendors v ON v.vendor_id = i.vendor_id
LEFT JOIN (
    SELECT invoice_id, SUM(payment_amount) AS total_paid
    FROM payments
    GROUP BY invoice_id
) p ON p.invoice_id = i.invoice_id
GROUP BY v.vendor_id, v.vendor_name
HAVING SUM(i.invoice_amount - COALESCE(p.total_paid, 0)) > 0
ORDER BY outstanding_amount DESC;

-- ============================================================
-- 10. Overdue invoices with a positive outstanding balance
-- Business question: Which invoices may need payment follow-up?
-- Concepts: date filters, LEFT JOIN, COALESCE, date subtraction
-- ============================================================
SELECT
    i.invoice_id,
    i.vendor_name,
    i.department,
    i.due_date,
    ROUND(i.invoice_amount, 2) AS invoice_amount,
    ROUND(COALESCE(p.total_paid, 0), 2) AS total_paid,
    ROUND(i.invoice_amount - COALESCE(p.total_paid, 0), 2) AS outstanding_amount,
    CURRENT_DATE - i.due_date AS days_past_due
FROM invoices i
LEFT JOIN (
    SELECT invoice_id, SUM(payment_amount) AS total_paid
    FROM payments
    GROUP BY invoice_id
) p ON p.invoice_id = i.invoice_id
WHERE i.due_date < CURRENT_DATE
  AND i.invoice_amount - COALESCE(p.total_paid, 0) > 0
ORDER BY days_past_due DESC;

-- ============================================================
-- 11. Potential duplicate invoice patterns
-- Business question: Are there repeated vendor/date/amount combinations to review?
-- These are review candidates, not proof of duplicate payment or fraud.
-- Concepts: GROUP BY, HAVING, COUNT
-- ============================================================
SELECT
    vendor_id,
    invoice_date,
    invoice_amount,
    COUNT(*) AS record_count,
    ROUND(SUM(invoice_amount), 2) AS combined_record_value
FROM invoices
GROUP BY vendor_id, invoice_date, invoice_amount
HAVING COUNT(*) > 1
ORDER BY record_count DESC, combined_record_value DESC;

-- ============================================================
-- 12. Invoices above the overall average value
-- Business question: Which invoices are larger than the dataset average?
-- Concepts: scalar subquery, AVG
-- ============================================================
SELECT
    invoice_id,
    vendor_name,
    department,
    expense_category,
    invoice_amount
FROM invoices
WHERE invoice_amount > (SELECT AVG(invoice_amount) FROM invoices)
ORDER BY invoice_amount DESC;

-- ============================================================
-- 13. Month-on-month spend change [CTE 3 of 3]
-- Business question: How much did invoiced spend increase or decrease each month?
-- Concepts: CTE, LAG, percentage calculation, NULLIF
-- ============================================================
WITH monthly_spend AS (
    SELECT
        DATE_TRUNC('month', invoice_date)::DATE AS invoice_month,
        SUM(invoice_amount) AS spend
    FROM invoices
    GROUP BY DATE_TRUNC('month', invoice_date)::DATE
), spend_comparison AS (
    SELECT
        invoice_month,
        spend,
        LAG(spend) OVER (ORDER BY invoice_month) AS previous_month_spend
    FROM monthly_spend
)
SELECT
    invoice_month,
    ROUND(spend, 2) AS current_month_spend,
    ROUND(previous_month_spend, 2) AS previous_month_spend,
    ROUND(spend - previous_month_spend, 2) AS change_amount,
    ROUND(100.0 * (spend - previous_month_spend)
          / NULLIF(previous_month_spend, 0), 2) AS change_pct
FROM spend_comparison
ORDER BY invoice_month;

-- ============================================================
-- 14. Vendor share of total invoiced spend
-- Business question: What percentage of invoice value comes from each vendor?
-- Concepts: GROUP BY, window SUM, NULLIF
-- ============================================================
SELECT
    v.vendor_name,
    ROUND(SUM(i.invoice_amount), 2) AS vendor_spend,
    ROUND(
        100.0 * SUM(i.invoice_amount)
        / NULLIF(SUM(SUM(i.invoice_amount)) OVER (), 0), 2
    ) AS share_of_total_pct
FROM invoices i
JOIN vendors v ON v.vendor_id = i.vendor_id
GROUP BY v.vendor_id, v.vendor_name
ORDER BY vendor_spend DESC;

-- ============================================================
-- 15. Top three expense categories within each department
-- Business question: Which categories contribute most to each department's spend?
-- Concepts: GROUP BY, DENSE_RANK, PARTITION BY, subquery
-- ============================================================
SELECT department, expense_category, total_spend, category_rank
FROM (
    SELECT
        department,
        expense_category,
        ROUND(SUM(invoice_amount), 2) AS total_spend,
        DENSE_RANK() OVER (
            PARTITION BY department
            ORDER BY SUM(invoice_amount) DESC
        ) AS category_rank
    FROM invoices
    GROUP BY department, expense_category
) ranked_categories
WHERE category_rank <= 3
ORDER BY department, category_rank;

-- ============================================================
-- 16. Average days from invoice date to last recorded payment
-- Business question: How long does it take to pay vendors on average?
-- Concepts: MAX, date subtraction, AVG, GROUP BY, derived table
-- ============================================================
SELECT
    v.vendor_name,
    v.payment_terms_days,
    COUNT(i.invoice_id) AS invoices_with_payment,
    ROUND(AVG(p.last_payment_date - i.invoice_date), 1) AS avg_days_to_last_payment
FROM invoices i
JOIN vendors v ON v.vendor_id = i.vendor_id
JOIN (
    SELECT invoice_id, MAX(payment_date) AS last_payment_date
    FROM payments
    GROUP BY invoice_id
) p ON p.invoice_id = i.invoice_id
GROUP BY v.vendor_id, v.vendor_name, v.payment_terms_days
ORDER BY avg_days_to_last_payment DESC;

-- ============================================================
-- 17. Payment method summary
-- Business question: How much value was paid through each method?
-- Concepts: GROUP BY, COUNT, SUM
-- ============================================================
SELECT
    payment_method,
    COUNT(*) AS payment_count,
    ROUND(SUM(payment_amount), 2) AS total_payment_value
FROM payments
GROUP BY payment_method
ORDER BY total_payment_value DESC;

-- ============================================================
-- 18. Basic data-quality checks
-- Business question: Are there obvious records requiring investigation?
-- Concepts: UNION ALL, COUNT, IS NULL, LEFT JOIN
-- ============================================================
SELECT 'Missing vendor ID' AS check_name, COUNT(*) AS issue_count
FROM invoices
WHERE vendor_id IS NULL
UNION ALL
SELECT 'Non-positive invoice amount', COUNT(*)
FROM invoices
WHERE invoice_amount <= 0
UNION ALL
SELECT 'Due date before invoice date', COUNT(*)
FROM invoices
WHERE due_date < invoice_date
UNION ALL
SELECT 'Payment linked to unknown invoice', COUNT(*)
FROM payments p
LEFT JOIN invoices i ON i.invoice_id = p.invoice_id
WHERE i.invoice_id IS NULL;

-- ============================================================
-- 19. Departments with total spend above £100,000
-- Business question: Which departments exceed a chosen spend threshold?
-- Change 100000 to match the business's materiality threshold.
-- Concepts: GROUP BY, HAVING
-- ============================================================
SELECT
    department,
    ROUND(SUM(invoice_amount), 2) AS total_spend
FROM invoices
GROUP BY department
HAVING SUM(invoice_amount) > 100000
ORDER BY total_spend DESC;

-- ============================================================
-- 20. Invoice status compared with recorded payment totals
-- Business question: Do recorded payment totals broadly align with invoice status?
-- Differences may have valid operational explanations and require review.
-- Concepts: LEFT JOIN, GROUP BY, SUM, COALESCE, derived table
-- ============================================================
SELECT
    i.invoice_status,
    COUNT(*) AS invoice_count,
    ROUND(SUM(i.invoice_amount), 2) AS invoice_value,
    ROUND(SUM(COALESCE(p.total_paid, 0)), 2) AS recorded_payment_value,
    ROUND(SUM(i.invoice_amount - COALESCE(p.total_paid, 0)), 2) AS calculated_remaining_balance
FROM invoices i
LEFT JOIN (
    SELECT invoice_id, SUM(payment_amount) AS total_paid
    FROM payments
    GROUP BY invoice_id
) p ON p.invoice_id = i.invoice_id
GROUP BY i.invoice_status
ORDER BY invoice_count DESC;
