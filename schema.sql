-- Financial Planning & Expense Analytics | MySQL 8+
-- Load the CLEANED CSV files into these tables after creating the database.
CREATE DATABASE IF NOT EXISTS fpa_expense_analytics;
USE fpa_expense_analytics;

DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS invoices;
DROP TABLE IF EXISTS monthly_budgets;
DROP TABLE IF EXISTS vendors;

CREATE TABLE vendors (
    vendor_id VARCHAR(10) PRIMARY KEY,
    vendor_name VARCHAR(150) NOT NULL,
    vendor_category VARCHAR(80),
    payment_terms_days INT,
    active_flag CHAR(1)
);

CREATE TABLE invoices (
    invoice_id VARCHAR(12) PRIMARY KEY,
    vendor_id VARCHAR(10) NOT NULL,
    vendor_name VARCHAR(150),
    department VARCHAR(80),
    expense_category VARCHAR(80),
    invoice_date DATE,
    due_date DATE,
    invoice_amount DECIMAL(12,2),
    currency CHAR(3),
    invoice_status VARCHAR(30),
    description VARCHAR(255),
    CONSTRAINT fk_invoice_vendor FOREIGN KEY (vendor_id) REFERENCES vendors(vendor_id)
);

CREATE TABLE monthly_budgets (
    budget_month DATE NOT NULL,
    department VARCHAR(80) NOT NULL,
    budget_amount DECIMAL(12,2),
    currency CHAR(3),
    UNIQUE KEY uq_budget_month_department (budget_month, department)
);

CREATE TABLE payments (
    payment_id VARCHAR(12) PRIMARY KEY,
    invoice_id VARCHAR(12) NOT NULL,
    payment_date DATE,
    payment_amount DECIMAL(12,2),
    payment_method VARCHAR(40),
    payment_reference VARCHAR(80),
    CONSTRAINT fk_payment_invoice FOREIGN KEY (invoice_id) REFERENCES invoices(invoice_id)
);
