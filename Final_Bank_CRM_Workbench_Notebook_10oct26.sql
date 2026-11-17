
USE bank_crm;

/* =====================================================================
Q1. What is the distribution of account balances across different regions?

===================================================================== */
SELECT
    Geography,
    COUNT(*) AS total_customers,
    ROUND(SUM(Balance), 2) AS total_balance,
    ROUND(AVG(Balance), 2) AS average_balance,
    ROUND(MIN(Balance), 2) AS minimum_balance,
    ROUND(MAX(Balance), 2) AS maximum_balance,
    SUM(Balance = 0) AS zero_balance_customers,
    ROUND(100.0 * SUM(Balance = 0) / COUNT(*), 2)
        AS zero_balance_percentage
FROM vw_customer_churn_analysis
GROUP BY Geography
ORDER BY average_balance DESC;

/* =====================================================================
Q2. Identify the top 5 customers with the highest Estimated Salary in
    the last quarter of the year. (SQL)

ANSWER
The top five estimated salaries among Q4 2019 joiners range from 198,826.03
to 199,841.32. Three customers (60%) are from France, two (40%) from Spain,
and none from Germany. Two of the five (40%) have exited.
Currency is unspecified; these figures should not be labelled as rupees.

===================================================================== */
SELECT
    CustomerId,
    Surname,
    EstimatedSalary,
    Bank_DOJ,
    Geography,
    Gender,
    ExitCategory AS exit_status
FROM vw_customer_churn_analysis
WHERE DOJ_Year = (
    SELECT MAX(DOJ_Year)
    FROM vw_customer_churn_analysis
)
AND DOJ_Quarter = 4
ORDER BY EstimatedSalary DESC, CustomerId
LIMIT 5;

/* =====================================================================
Q3. Calculate the average number of products used by customers who have
    a credit card. (SQL)

ANSWER
There are 7,055 credit-card holders, using 1.53 products on average.
The recorded number of products ranges from one to four.
===================================================================== */
SELECT
    COUNT(*) AS credit_card_holders,
    MIN(NumOfProducts) AS minimum_products,
    MAX(NumOfProducts) AS maximum_products,
    ROUND(AVG(NumOfProducts), 2) AS average_products
FROM vw_customer_churn_analysis
WHERE Has_creditcard = 1;

/* =====================================================================
Q4. Determine the churn rate by gender for the most recent dataset year.

EXPECTED RESULTS — CUSTOMERS WHO JOINED IN 2019
Gender CustomerCount ExitedCustomers ChurnRatePct
Female 1537          385             25.05
Male   1776          273             15.37

INTERPRETATION
Female customers in the latest joining cohort have higher observed churn.

===================================================================== */
SELECT
    g.GenderCategory AS Gender,
    COUNT(*) AS CustomerCount,
    SUM(CASE WHEN e.ExitCategory = 'Exit' THEN 1 ELSE 0 END) AS ExitedCustomers,
    ROUND(100.0 * SUM(CASE WHEN e.ExitCategory = 'Exit' THEN 1 ELSE 0 END)
          / COUNT(*), 2) AS ChurnRatePct
FROM CustomerInfo c
JOIN Bank_Churn b ON c.CustomerId = b.CustomerId
JOIN Gender g ON c.GenderID = g.GenderID
JOIN ExitCustomer e ON b.Exited = e.ExitID
WHERE YEAR(c.Bank_DOJ) = (SELECT MAX(YEAR(Bank_DOJ)) FROM CustomerInfo)
GROUP BY g.GenderCategory
ORDER BY ChurnRatePct DESC;

/* =====================================================================
Q5. Compare average credit scores of exited and retained customers.

The difference is only 6.50 points. Group averages alone provide limited
separation between exited and retained customers.
===================================================================== */
SELECT e.ExitCategory AS CustomerStatus,
       COUNT(*) AS CustomerCount,
       ROUND(AVG(b.CreditScore), 2) AS AverageCreditScore
FROM Bank_Churn b
JOIN ExitCustomer e ON b.Exited = e.ExitID
GROUP BY e.ExitCategory
ORDER BY AverageCreditScore DESC;

/* =====================================================================
Q6. Which gender has higher average estimated salary, and how does it
    relate to the number of active accounts?
Female customers have higher average salary; male customers have a higher
active count and activity percentage.
===================================================================== */
SELECT
    g.GenderCategory AS Gender,
    COUNT(*) AS CustomerCount,
    ROUND(AVG(c.EstimatedSalary), 2) AS AverageEstimatedSalary,
    SUM(CASE WHEN b.IsActiveMember = 1 THEN 1 ELSE 0 END) AS ActiveCustomers,
    ROUND(100.0 * SUM(CASE WHEN b.IsActiveMember = 1 THEN 1 ELSE 0 END)
          / COUNT(*), 2) AS ActiveCustomerPct
FROM CustomerInfo c
JOIN Bank_Churn b ON c.CustomerId = b.CustomerId
JOIN Gender g ON c.GenderID = g.GenderID
GROUP BY g.GenderCategory
ORDER BY AverageEstimatedSalary DESC;

/* =====================================================================
Q7. Segment customers by credit score and identify the highest exit rate.

The 300-579 segment has the highest exit rate, 22.02%.
===================================================================== */
SELECT
    CASE
        WHEN b.CreditScore < 580 THEN '300-579'
        WHEN b.CreditScore < 670 THEN '580-669'
        WHEN b.CreditScore < 740 THEN '670-739'
        WHEN b.CreditScore < 800 THEN '740-799'
        ELSE '800-850'
    END AS CreditScoreSegment,
    COUNT(*) AS CustomerCount,
    SUM(CASE WHEN e.ExitCategory = 'Exit' THEN 1 ELSE 0 END) AS ExitedCustomers,
    ROUND(100.0 * SUM(CASE WHEN e.ExitCategory = 'Exit' THEN 1 ELSE 0 END)
          / COUNT(*), 2) AS ExitRatePct
FROM Bank_Churn b
JOIN ExitCustomer e ON b.Exited = e.ExitID
GROUP BY CreditScoreSegment
ORDER BY ExitRatePct DESC;

/* =====================================================================
Q8. Which region has the most active customers with tenure over five years?

===================================================================== */
SELECT g.GeographyLocation AS Region,
       COUNT(*) AS ActiveCustomersOver5Years
FROM CustomerInfo c
JOIN Bank_Churn b ON c.CustomerId = b.CustomerId
JOIN Geography g ON c.GeographyID = g.GeographyID
WHERE b.IsActiveMember = 1 AND b.Tenure > 5
GROUP BY g.GeographyLocation
ORDER BY ActiveCustomersOver5Years DESC;

/* =====================================================================
Q9. What is the impact of credit-card ownership on customer churn?

Cardholders have a slightly lower observed churn rate.
===================================================================== */
SELECT
    cc.Category AS CreditCardStatus,
    COUNT(*) AS CustomerCount,
    SUM(CASE WHEN e.ExitCategory = 'Exit' THEN 1 ELSE 0 END) AS ExitedCustomers,
    ROUND(100.0 * SUM(CASE WHEN e.ExitCategory = 'Exit' THEN 1 ELSE 0 END)
          / COUNT(*), 2) AS ChurnRatePct
FROM Bank_Churn b
JOIN CreditCard cc ON b.HasCrCard = cc.CreditID
JOIN ExitCustomer e ON b.Exited = e.ExitID
GROUP BY cc.Category
ORDER BY ChurnRatePct DESC;

/* =====================================================================
Q10. For exited customers, what is the most common number of products used?

One product is the most common count among exited customers (69.17%).
===================================================================== */
SELECT
    b.NumOfProducts,
    COUNT(*) AS ExitedCustomers,
    ROUND(100.0 * COUNT(*) / (
        SELECT COUNT(*)
        FROM Bank_Churn b2
        JOIN ExitCustomer e2 ON b2.Exited = e2.ExitID
        WHERE e2.ExitCategory = 'Exit'
    ), 2) AS ShareOfExitedCustomersPct
FROM Bank_Churn b
JOIN ExitCustomer e ON b.Exited = e.ExitID
WHERE e.ExitCategory = 'Exit'
GROUP BY b.NumOfProducts
ORDER BY ExitedCustomers DESC, b.NumOfProducts;

/* Q10 — SUPPLEMENTARY: CHURN RATE WITHIN EACH PRODUCT GROUP
Approach: include both Exit and Retain customers, group by product count,
then divide exits by all customers in each product group.

Two-product customers have the lowest observed rate. Three-/four-product
rates are high but based on smaller groups; investigate data quality,
product composition and customer experience before acting.
*/
SELECT
    b.NumOfProducts,
    COUNT(*) AS CustomerCount,
    SUM(CASE WHEN e.ExitCategory = 'Exit' THEN 1 ELSE 0 END) AS ExitedCustomers,
    ROUND(100.0 * SUM(CASE WHEN e.ExitCategory = 'Exit' THEN 1 ELSE 0 END)
          / COUNT(*), 2) AS ChurnRatePct
FROM Bank_Churn b
JOIN ExitCustomer e ON b.Exited = e.ExitID
GROUP BY b.NumOfProducts
ORDER BY b.NumOfProducts;

-- 11.	Examine the trend of customers joining over time and identify any seasonal patterns 
-- (yearly or monthly). Prepare the data through SQL and then visualize it.
-- Recorded joiners increased each year, from 1,951 in 2016 to 3,313 in 2019.
-- September, November, and December consistently have high joining counts; 
-- February has the lowest count in every year.
SELECT
    YEAR(Bank_DOJ) AS JoiningYear,
    COUNT(*) AS CustomersJoined
FROM CustomerInfo
GROUP BY YEAR(Bank_DOJ)
ORDER BY JoiningYear;

-- monthly trend and seasonal comparison
SELECT
    YEAR(Bank_DOJ) AS JoiningYear,
    MONTH(Bank_DOJ) AS JoiningMonth,
    COUNT(*) AS CustomersJoined,
    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (
            PARTITION BY YEAR(Bank_DOJ)
        ),
        2
    ) AS ShareOfYearPct
FROM CustomerInfo
GROUP BY
    YEAR(Bank_DOJ),
    MONTH(Bank_DOJ)
ORDER BY JoiningYear, JoiningMonth;

-- 12. Analyze the relationship between the number of products and the account
-- balance for customers who have exited.
-- Average balances decline from one to three products, then increase for four products.
-- There is no consistent increasing or decreasing relationship in these group averages.
SELECT
    b.NumOfProducts,
    COUNT(*) AS ExitedCustomers,
    ROUND(AVG(b.Balance), 2) AS AverageBalance,
    ROUND(MIN(b.Balance), 2) AS MinimumBalance,
    ROUND(MAX(b.Balance), 2) AS MaximumBalance,
    SUM(CASE WHEN b.Balance = 0 THEN 1 ELSE 0 END)
        AS ZeroBalanceCustomers
FROM Bank_Churn b
JOIN ExitCustomer e
    ON b.Exited = e.ExitID
WHERE e.ExitCategory = 'Exit'
GROUP BY b.NumOfProducts
ORDER BY b.NumOfProducts;

-- 13.	Identify any potential outliers in terms of balance among customers
-- who have remained with the bank.
-- answer : Interpretation: No retained customers have balances outside the IQR boundaries.
-- That is why the first query original will return no customer rows
WITH orderedbalances
     AS (SELECT b.customerid,
                b.balance,
                Row_number()
                  OVER (
                    ORDER BY b.balance, b.customerid ) AS RowNum,
                Count(*)
                  OVER ()                              AS TotalCustomers
         FROM   bank_churn b
                JOIN exitcustomer e
                  ON b.exited = e.exitid
         WHERE  e.exitcategory = 'Retain'),
     quartiles
     AS (SELECT Max(CASE
                      WHEN rownum = Ceil(0.25 * totalcustomers) THEN balance
                    END) AS Q1,
                Max(CASE
                      WHEN rownum = Ceil(0.75 * totalcustomers) THEN balance
                    END) AS Q3
         FROM   orderedbalances),
     bounds
     AS (SELECT q1 - 1.5 * ( q3 - q1 ) AS LowerBound,
                q3 + 1.5 * ( q3 - q1 ) AS UpperBound
         FROM   quartiles)
SELECT o.customerid,
       o.balance,
       Round(b.lowerbound, 2) AS LowerBound,
       Round(b.upperbound, 2) AS UpperBound
FROM   orderedbalances o
       CROSS JOIN bounds b
WHERE  o.balance < b.lowerbound
        OR o.balance > b.upperbound
ORDER  BY o.balance DESC; 

-- second query to recheck
WITH orderedbalances AS (
    SELECT
        b.CustomerId,
        b.Balance,
        ROW_NUMBER() OVER (
            ORDER BY b.Balance, b.CustomerId
        ) AS RowNum,
        COUNT(*) OVER () AS TotalCustomers
    FROM Bank_Churn b
    JOIN ExitCustomer e
        ON b.Exited = e.ExitID
    WHERE e.ExitCategory = 'Retain'
),
quartiles AS (
    SELECT
        MAX(
            CASE
                WHEN RowNum = CEIL(0.25 * TotalCustomers)
                THEN Balance
            END
        ) AS Q1,
        MAX(
            CASE
                WHEN RowNum = CEIL(0.75 * TotalCustomers)
                THEN Balance
            END
        ) AS Q3
    FROM orderedbalances
),
bounds AS (
    SELECT
        Q1,
        Q3,
        Q1 - 1.5 * (Q3 - Q1) AS LowerBound,
        Q3 + 1.5 * (Q3 - Q1) AS UpperBound
    FROM quartiles
)
SELECT
    (SELECT COUNT(*) FROM orderedbalances) AS RetainedCustomers,
    ROUND(b.Q1, 2) AS Q1,
    ROUND(b.Q3, 2) AS Q3,
    ROUND(b.LowerBound, 2) AS LowerBound,
    ROUND(b.UpperBound, 2) AS UpperBound,
    (
        SELECT COUNT(*)
        FROM orderedbalances o
        WHERE o.Balance < b.LowerBound
           OR o.Balance > b.UpperBound
    ) AS OutlierCount
FROM bounds b;

-- SUBJECTIVE QUESTION
-- Q9. Utilize SQL queries to segment customers based on demographics and
-- account details.
WITH CustomerSegments AS
  (SELECT c.CustomerId,
          geo.GeographyLocation AS Region,
          g.GenderCategory AS Gender,
          CASE
              WHEN c.Age BETWEEN 18 AND 30 THEN '18-30'
              WHEN c.Age BETWEEN 31 AND 50 THEN '31-50'
              ELSE '51+'
          END AS AgeSegment,
          CASE
              WHEN b.NumOfProducts = 1 THEN '1 Product'
              WHEN b.NumOfProducts = 2 THEN '2 Products'
              ELSE '3+ Products'
          END AS ProductSegment,
          CASE
              WHEN b.IsActiveMember = 1 THEN 'Active'
              ELSE 'Inactive'
          END AS ActivityStatus,
          CASE
              WHEN b.HasCrCard = 1 THEN 'Credit Card Holder'
              ELSE 'No Credit Card'
          END AS CreditCardStatus,
          CASE
              WHEN b.Balance = 0 THEN 'Zero Balance'
              ELSE 'Positive Balance'
          END AS BalanceSegment,
          b.Balance,
          e.ExitCategory
   FROM CustomerInfo c
   JOIN Bank_Churn b ON c.CustomerId = b.CustomerId
   JOIN Geography geo ON c.GeographyID = geo.GeographyID
   JOIN Gender g ON c.GenderID = g.GenderID
   JOIN ExitCustomer e ON b.Exited = e.ExitID)
SELECT Region,
       AgeSegment,
       ProductSegment,
       ActivityStatus,
       COUNT(*) AS Customers,
       SUM(CASE
               WHEN ExitCategory = 'Exit' THEN 1
               ELSE 0
           END) AS ExitedCustomers,
       ROUND(100.0 * SUM(CASE
                             WHEN ExitCategory = 'Exit' THEN 1
                             ELSE 0
                         END) / COUNT(*), 2) AS ChurnRatePct,
       ROUND(AVG(Balance), 2) AS AverageBalance
FROM CustomerSegments
GROUP BY Region,
         AgeSegment,
         ProductSegment,
         ActivityStatus
ORDER BY ChurnRatePct DESC,
         Customers DESC;

-- second query

SELECT geo.GeographyLocation AS Region,
       g.GenderCategory AS Gender,
       CASE
           WHEN c.Age BETWEEN 18 AND 30 THEN '18-30'
           WHEN c.Age BETWEEN 31 AND 50 THEN '31-50'
           ELSE '51+'
       END AS AgeSegment,
       COUNT(*) AS Customers,
       ROUND(100.0 * SUM(CASE
                             WHEN e.ExitCategory = 'Exit' THEN 1
                             ELSE 0
                         END) / COUNT(*), 2) AS ChurnRatePct
FROM CustomerInfo c
JOIN Bank_Churn b ON c.CustomerId = b.CustomerId
JOIN Geography geo ON c.GeographyID = geo.GeographyID
JOIN Gender g ON c.GenderID = g.GenderID
JOIN ExitCustomer e ON b.Exited = e.ExitID
GROUP BY geo.GeographyLocation,
         g.GenderCategory,
         AgeSegment
ORDER BY ChurnRatePct DESC;