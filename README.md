# Financial Expense Analysis & Budget Variance | SQL for FP&A | Powerbi

Project Overview

This project leverages PostgreSQL and SQL-driven financial analysis to evaluate synthetic accounts payable and operating expense data for a fictional multi-department organization. Designed around real-world Financial Planning & Analysis (FP&A) and finance operations use cases, it examines expenditure patterns, budget performance, vendor costs, payment status, and potential financial control issues.

The project demonstrates how structured financial data can be transformed into meaningful insights through data validation, budget variance analysis, payment reconciliation, trend analysis, and vendor-level performance evaluation. It follows a repeatable, data-driven approach to strengthen financial visibility, support management reporting, and enable more informed business decisions.

Data Disclaimer: All datasets are synthetic and created exclusively for educational and portfolio purposes. They do not represent any actual company, vendor, transaction, or financial ledger.

##Business Objectives

-**Analyze expenditure patterns:** Track invoiced spend by month, department, cost category, and vendor to understand key cost drivers.
-**Evaluate budget performance:** Compare invoice-date-based actual expenditure against monthly departmental budgets to identify overspending and underspending.
-**Quantify financial variances:** Calculate absolute budget variance, variance percentage, and budget utilization to assess financial performance.
-**Reconcile accounts payable:** Compare invoice values with recorded payments to estimate outstanding balances and improve payment visibility.
-**Monitor overdue liabilities:** Identify invoices with outstanding balances that were overdue as of 31 December 2025.
-**Strengthen financial controls:** Flag potential duplicate invoice references and investigate discrepancies requiring further review.
-**Evaluate spending trends:** Analyze month-on-month changes and vendor concentration to identify significant movements and spending dependencies.
-**Improve data reliability:** Apply data-quality checks to identify incomplete, inconsistent, or potentially problematic records before interpreting results.
-**Business Value:** The project connects SQL-based analysis with practical finance questions, demonstrating how data can support cost monitoring, budget control, accounts payable visibility, and evidence-based financial decision-making.

## Dataset information

| File | Grain | Purpose |
|---|---|---|
| `invoices.csv` | One row per invoice | Invoice amounts, vendors, departments, categories, invoice/due dates, and status |
| `payments.csv` | One row per payment | Payment dates, amounts, methods, references, and linked invoices |
| `vendors.csv` | One row per vendor | Supplier details, categories, payment terms, and active status |
| `monthly_budgets.csv` | One row per department per month | Budgeted expenditure for budget-versus-actual analysis |

### Dataset size and period

- **Invoice records:** 240
- **Distinct vendors referenced by invoices:** 30
- **Payment records:** 211
- **Monthly budget records:** 125
- **Invoice reporting period:** January 2025 – June 2026
- **Budget reporting period:** January 2025 – September 2026
- **Currency:** GBP (£)

Repeated vendor/date/amount combinations are treated as duplicate candidates for review, not proof of a duplicate payment or fraud.

## Tools and environment

- **PostgreSQL** — relational database and SQL analysis
- **pgAdmin 4** — database administration, CSV import, and query execution
- **SQL** — joins, aggregations, CTEs, subqueries, window functions, and financial calculations
- **CSV** — structured datasets
- **Git and GitHub** — version control and project presentation

## Repository structure
```text
financial-planning-expense-analytics/
├── README.md
├── data/
│   ├── raw/
│   └── cleaned/
├── sql/
│   ├── schema.sql
│   └── analysis_queries.sql
└── powerbi/
  └── dashboard_build_guide.md
  
``````

## Analysis performed

### 1. Spend overview and cost drivers

- Total invoice value, invoice count, and average invoice value
- Monthly invoiced spend
- Department and expense-category expenditure
- Top vendors ranked by invoiced value
- Vendor contribution to total invoiced spend

**Business question:** Which departments, categories, and vendors account for the largest share of expenditure, and where should finance investigate material movements?

### 2. Budget vs. actual analysis

- Monthly budget and invoice-date-based actual spend by department
- Absolute variance: `Actual Spend − Budget`
- Percentage variance, with `NULLIF()` protection against division by zero
- Identification of departments and months with the largest positive or negative variances

**Interpretation convention:** positive variance means invoice-date-based actual spend exceeded budget; negative variance means spend was below budget. Invoice date is used as a simplified proxy for expense period. Real FP&A reporting may also require accruals, prepayments, credit notes, cut-off rules, and approved accounting-period logic.

### 3. Accounts payable visibility

- Invoice amounts compared with recorded payments
- Estimated outstanding balances by invoice and vendor
- Overdue invoices with an unpaid or partially paid status
- Payment totals where an invoice has multiple payment records
- Comparison of invoice status with calculated payment position

Outstanding balance is estimated as `Invoice Amount − Recorded Payments`. The dataset does not model every real-world adjustment, including credit notes, withholding, disputes, or write-offs; results should be treated as analytical estimates rather than a formal accounts-payable ledger.

### 4. Data quality and financial controls

- Record-count and control-total checks
- Missing or inconsistent identifiers and fields
- Payments that do not link to a known invoice
- Repeated vendor, invoice-date, and amount combinations for review
- Reconciliation of invoice values with recorded payments

Duplicate candidates should be checked against source invoices, vendor references, approval records, and payment references before a payment is blocked or an item is labelled fraudulent.

### 5. Trend and concentration analysis

- Month-on-month spend movement using `LAG()`
- Department-level expenditure comparisons
- Ranking analysis using `DENSE_RANK()`
- Vendor share of total invoice value using a windowed `SUM()`
- Payment-method summaries

## Initial sample-data control totals

These figures are reproducible from the supplied synthetic data and describe the dataset only; they are not real-company performance claims.

- **Total invoice-record value:** £2,189,543.47
- **Average invoice-record value:** £9,123.10
- **Total recorded payment value:** £1,448,550.30
- **Total budget value across supplied budget rows:** £4,310,768.77
- **Repeated vendor/date/amount groups for review:** 0
- **Highest-spend department:** Human Resources (£473,123.20)
- **Highest invoice-spend month:** 2025-09 (£177,767.07)

The difference between total invoice value and total recorded payments is **£740,993.17**. This is an aggregate control comparison, not a confirmed accounts-payable balance; payment allocation, timing, and invoice-level exceptions must be checked before drawing a conclusion.

## SQL concepts demonstrated

- Filtering and sorting: `WHERE`, `ORDER BY`
- Grouped analysis: `GROUP BY`, `HAVING`, aggregate functions
- Relational analysis: `INNER JOIN`, `LEFT JOIN`
- Conditional calculations using `CASE`
- Common Table Expressions (CTEs) and subqueries
- Window functions: `LAG()`, `DENSE_RANK()`, and `SUM() OVER()`
- Date functions: `DATE_TRUNC()`, `TO_CHAR()`, and date comparisons
- Budget variance and percentage calculations
- Safe calculations using `COALESCE()` and `NULLIF()`
- Reconciliation logic, control totals, and exception checks

## FP&A-oriented recommendations framework

1. **Investigate overspend:** prioritise departments and months with the largest positive budget variances, then determine whether changes are recurring, seasonal, one-off, volume-driven, price-driven, or timing-related.
2. **Improve forecast assumptions:** compare recurring cost patterns with budget assumptions and validate material changes with budget owners.
3. **Prioritise payables follow-up:** review overdue invoices with positive estimated balances, considering payment terms, disputes, and approval status.
4. **Strengthen invoice controls:** review duplicate candidates against invoice documents and payment references before deciding whether they are genuine duplicates.
5. **Manage supplier concentration:** assess reliance on high-spend vendors and investigate material price, volume, or supplier-mix changes.

These are investigation priorities, not conclusions that a department or supplier is performing poorly. Recommendations should follow validation of the underlying records and business context.

## How to run the project in PostgreSQL / pgAdmin 4

1. Install PostgreSQL and open **pgAdmin 4**.
2. Create a database named `fpa_expense_analytics` and connect to it.
3. Open the Query Tool and execute `schema.sql` to create the four tables.
4. Import each CSV from the `data/` folder into its matching table using pgAdmin's **Import/Export Data** feature. Import in this order to respect foreign keys: `vendors.csv`, `invoices.csv`, `monthly_budgets.csv`, then `payments.csv`.
5. Ensure the CSV import options use a comma delimiter, a header row, and the correct encoding. Confirm column order matches the table definitions.
6. Open and execute `queries.sql`. Start with the control totals, then review spend, budget variances, payment reconciliation, and exception outputs.

## Conclusion

Conclusion

This project demonstrates how SQL can transform raw financial data into actionable business insights that support better financial planning, cost control, and decision-making. By analyzing budget vs. actual expenditure, departmental spending patterns, vendor costs, invoice payment status, and overdue payables, the project establishes a structured approach to monitoring financial performance and strengthening financial controls.

Using PostgreSQL, I applied joins, CTEs, aggregate functions, subqueries, and window functions to investigate spending trends, quantify budget variances, reconcile payments, identify potential duplicate invoices, and perform data-quality checks. These analyses demonstrate how financial data can be used to highlight cost deviations, improve visibility into outstanding liabilities, and support more informed business decisions.

**Key takeaway:** Effective financial analysis goes beyond reporting numbers—it connects financial data with business performance, identifies risks and opportunities, and enables organizations to make data-driven decisions.

This project reflects my practical application of SQL to FP&A, financial reporting, expense analysis, and accounts payable, aligning technical analytical skills with real-world business needs.

## Limitations

This is a portfolio exercise using synthetic data. It does not demonstrate real-company savings, confirmed fraud, or operational impact. Budget-versus-actual analysis uses invoice-date month as a simplified expense-period proxy, and payment balances are estimates based on the supplied records. Validate source data and business rules before using similar outputs for formal reporting or decisions.
