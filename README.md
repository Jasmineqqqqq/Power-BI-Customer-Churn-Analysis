# Bank CRM: Who Is Leaving the Bank, and Why It Matters

Customer churn analysis for a European retail bank, using a 10,000-customer CRM dataset across France, Germany and Spain. MySQL handles data validation, segmentation and cohort analysis, and Power BI provides four interactive dashboards. The findings are presented as a storytelling deck with recommendations.

## Business problem

About one in five customers (20.37%) has left the bank. The bank can see that customers are leaving, but not which customer groups churn most or where retention effort should go first. This project identifies the segments most associated with churn and turns them into prioritised retention actions.

## Dataset

The dataset has six tables in a MySQL database (`bank_crm`), with one row per customer in each of the two core tables.

| Table | Contents |
|---|---|
| `CustomerInfo` | CustomerId (PK), Surname, Age, GenderID (FK), EstimatedSalary, GeographyID (FK), Bank DOJ |
| `Bank_Churn` | CustomerId (PK, FK), CreditScore, Tenure, Balance, NumOfProducts, HasCrCard (FK), IsActiveMember, Exited (FK) |
| `Gender` | GenderID, GenderCategory |
| `Geography` | GeographyID, GeographyLocation |
| `CreditCard` | CreditID, Category |
| `ExitCustomer` | ExitID, ExitCategory |

**Relationships:** Gender and Geography → CustomerInfo (1 : many). CustomerInfo → Bank_Churn (1 : 1). CreditCard and ExitCustomer → Bank_Churn (1 : many).

**Scope:**
- 10,000 customers: France 5,014, Germany 2,509 and Spain 2,477.
- Joining dates (Bank DOJ) run from 2016 to 2019.

**Data-quality notes:**
- There are no missing values.
- 92 surnames contain corrupted characters.
- 735 customers are marked both `Exited = 1` and `IsActiveMember = 1`. `Exited` is treated as the authoritative churn flag.
- There are no exit dates or exit reasons, so findings are associations, not causes.

## Repository contents

| File | Description |
|---|---|
| `Final_Bank_CRM_Workbench_Notebook_10oct26.sql` | MySQL queries for the objective questions and the subjective segmentation (Q9) |
| `Final_objective_subjective_questions.docx` | Full write-up: each question with its query or DAX, output, approach and insights |
| `Power_bi_project_18oct.pbix` | Power BI report: four dashboard tabs plus supporting analysis pages |
| `Who-is-leaving-the-bank-and-why-it-matters.pptx` | 25-slide presentation: problem, data, analysis, conclusion, recommendations and dashboards |
| `Bank_Churn.csv`, `CustomerInfo.csv`, `Gender.csv`, `Geography.csv`, `CreditCard.csv`, `ExitCustomer.csv` | Source data |

## Approach

1. **Validate the data:** check nulls, duplicates, foreign-key integrity, date ranges and logical conflicts (exited but active).
2. **Set the baseline:** total, exited and retained customers, and the overall churn rate.
3. **Compare churn by single variables:** products, age, geography, activity, gender, credit score, card ownership, salary, tenure, balance and joining cohort.
4. **Test interactions:** country × age × activity, age × gender, and product count × activity.
5. **Build a risk view:** a rule-based churn risk score (3+ products +2 or 1 product +1, inactive +1, age 51+ +1, Germany +1), grouped into Low, Medium and High bands with Power BI conditional formatting.
6. **Build dashboards and recommendations.**

## Key findings

- **Overall churn is 20.37%:** 2,037 of 10,000 customers have exited.
- **Product count is the strongest signal.** Churn is 7.58% with two products, 27.71% with one, 82.71% with three and 100% with four. The four-product group has only 60 customers, so read it with caution.
- **Most exits come from 1-product customers.** They account for 69.17% of exits (1,409), even though their churn rate is lower than for 3+ products.
- **Germany is the geographic outlier.** Its churn is 32.44%, about double France (16.15%) and Spain (16.67%), and stays higher within comparable customer groups.
- **Churn climbs with age:** 7.52% at 18–30, 19.58% at 31–50 and 44.65% at 51+. Inactive customers aged 51+ churn above 83% in every country.
- **Inactive customers churn at 26.85%** vs 14.27% for active customers.
- **The female–male gap widens with age.** Women aged 51+ churn at 52.81% vs 37.14% for men.
- **High balances do not guarantee loyalty.** Exited customers average about 91K vs about 73K for retained customers, and funded accounts churn at 24.08% vs 13.82% for zero-balance accounts.
- **Some variables are weak separators.** Credit card ownership, credit score bands, salary and tenure all keep churn within 18.6%–22.0%.
- **Risk view:** 2,785 retained customers fall in the Medium-Risk band (the scalable early-warning group). Only 17 retained customers are High Risk.

## Dashboards (Power BI)

| Tab | Focus |
|---|---|
| DASHBOARD-1 | Overview KPIs, plus churn by products, geography, balance band and age, and the joining trend |
| Customer Demographics | Age, geography, gender, tenure and salary profile |
| Product Engagement | Product holding, card ownership, activity and balance by product count |
| Churn Analysis | Churn by gender, geography, age, and salary band × tenure, plus credit score by exit status |

All tabs share slicers for gender, geography, number of products, join year, activity status and credit card status.

## Recommendations

1. Review product mix, fees and servicing for 3+ product customers before expanding cross-sell.
2. Re-engage inactive single-product customers, and test (rather than assume) second-product offers.
3. Run a Germany-specific market and service diagnostic.
4. Review service accessibility and experience for customers aged 51+.
5. Start preventive outreach with the 2,785 retained Medium-Risk customers.
6. Collect exit reasons, exit dates, transactions, product holdings and profitability data, so the analysis can move from association to cause.

## How to reproduce

1. Create a MySQL database named `bank_crm` and import the six CSV files as tables with the names above.
2. Create the view `vw_customer_churn_analysis`, which the first three queries rely on. It joins the six tables and adds the readable labels (Geography, Gender, ExitCategory), the `DOJ_Year` and `DOJ_Quarter` fields, and the renamed `Has_creditcard` column. The SQL file does not include the definition, so build it before running those queries.
3. Run `Final_Bank_CRM_Workbench_Notebook_10oct26.sql` in MySQL Workbench.
4. Open `Power_bi_project_18oct.pbix` in Power BI Desktop and refresh the data source to point at your database or CSVs.

## Tools

MySQL 8 (MySQL Workbench), Power BI Desktop (DAX, Key Influencers, conditional formatting) and Microsoft PowerPoint.

## Limitations

- The data is a single snapshot with no exit dates, so the churn rates are current outcomes, not annual rates.
- There are no exit reasons, transactions, individual product holdings, service interactions, campaign data or profitability data.
- Balance is a value proxy, not revenue or profit.
- The risk score is a descriptive, rule-based proxy, not a validated predictive model.
