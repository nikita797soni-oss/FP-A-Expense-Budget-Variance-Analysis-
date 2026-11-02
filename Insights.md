# Findings and interpretation

## Verified sample-data profile

All amounts are from the synthetic data supplied with this repository.
Re-run the SQL queries to validate them in DuckDB.

-   Invoice records: 246
-   Distinct vendors referenced: 30
-   Gross invoice-record value: £251,393.84
-   Average invoice-record value: £1,021.93
-   Payment records: 258
-   Recorded payment value: £202,171.56
-   Invoice balance less recorded payments: £49,222.28
-   Repeated vendor/invoice-reference groups: 6
-   Highest-spend department: Operations (£81,121.36)
-   Highest invoice-date spend month: 2025-10 (£31,711.27)
-   Overdue invoices with positive calculated balance as of 2025-12-31:
    77

## What to investigate after running queries

1.  Identify the largest positive and negative budget variances. Check
    whether changes are driven by a few large invoices or broad-based
    spending.
2.  Review top vendor and category rankings. High spend alone does not
    imply poor performance; consider scope, volume and business
    criticality.
3.  Review overdue balances with invoice owners. Validate approval
    status, terms and disputes before recommending action.
4.  Review duplicate-candidate groups against invoice copies and payment
    references. Repeated references are alerts for review, not proof of
    duplicate payment.
5.  Check whether payments exceed invoice values and investigate any
    allocation anomalies before reporting a final payable balance.

## Limitations

-   Simulated data, not an actual company ledger.
-   Invoice date is used as a proxy for the spend month.
-   Credit notes, accruals, prepayments, tax and foreign exchange are
    not modelled.
-   Outstanding balance excludes adjustments not present in the sample.
-   Duplicate candidates require human review.
