USE healthbridge;

-- Need billing table first before we can refactor it
CREATE TABLE IF NOT EXISTS billing (
    bill_no     VARCHAR(50),
    pid         INT,
    pname       VARCHAR(255),
    services    TEXT,
    svc_cost    FLOAT,
    tax_pct     FLOAT,
    tax_amt     FLOAT,
    grand_total FLOAT,
    paid        FLOAT,
    balance     FLOAT,
    created     VARCHAR(50),
    created_by  VARCHAR(255)
);

-- Now apply R1
ALTER TABLE billing DROP COLUMN tax_amt;
ALTER TABLE billing DROP COLUMN grand_total;
ALTER TABLE billing DROP COLUMN balance;

CREATE OR REPLACE VIEW v_billing_summary AS
SELECT
    bill_no, pid, pname, services, svc_cost, tax_pct,
    ROUND(svc_cost * tax_pct / 100, 2)                     AS tax_amt,
    ROUND(svc_cost + (svc_cost * tax_pct / 100), 2)        AS grand_total,
    paid,
    ROUND(svc_cost + (svc_cost * tax_pct / 100) - paid, 2) AS balance,
    created, created_by
FROM billing;