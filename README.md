# Olist E-commerce Customer & Revenue Analytics

An analytics project using **PostgreSQL, Python, and Tableau** to examine e-commerce revenue, customer behavior, delivery performance, and low-review risk in the Brazilian Olist marketplace dataset.

## Project Overview

The project is organized into three complementary parts:

- **PostgreSQL:** business analysis across multiple relational tables, including revenue, average order value, regional/category performance, month-over-month growth, delivery performance, and customer cohort retention.
- **Python:** order-level exploratory analysis and logistic regression focused on factors associated with low customer reviews.
- **Tableau:** an executive-style dashboard summarizing revenue, order volume, category/state performance, and the relationship between delivery timing and low-review rates.

## Key Findings

- The analysis contains **96,478 delivered orders**.
- Delivered-order merchandise revenue is approximately **R$13.22M**, with an average order value of about **R$137.04**.
- Low reviews (scores 1–2) account for about **12.8%** of reviewed delivered orders.
- Late orders have a **54.0% low-review rate**, compared with **9.2%** for orders delivered on time or early.
- Median delivery time is about **15.7 days** for low-review orders versus **9.9 days** for other reviewed orders.
- A class-balanced logistic regression increases low-review recall from roughly **16% to 58%**, with ROC-AUC around **0.73**.

These results are **associational, not causal**. The model uses actual delivery outcomes, so it should be interpreted as a **post-fulfillment diagnostic/risk-scoring model**, not a pre-delivery forecasting system.

## Dashboard

![Olist E-commerce Performance Dashboard](assets/dashboard.png)

The dashboard highlights total revenue, delivered orders, average order value, average review score, monthly revenue trends, top product categories, state-level revenue, and low-review rate by delivery status.

## SQL Analysis

The SQL portion demonstrates:

- Multi-table `JOIN`s across customers, orders, order items, products, and reviews
- CTE-based transformations
- Conditional aggregation and `CASE WHEN`
- Order-level aggregation for correct AOV calculation
- `LAG()` window functions for month-over-month revenue growth
- Customer cohort construction and retention analysis using `COUNT(DISTINCT ...)` and window functions

See [`sql/olist_analysis.sql`](sql/olist_analysis.sql).

## Python Analysis

The Python notebook builds an order-level dataset from PostgreSQL and creates features including:

- `delivery_days`
- `delay_days`
- `freight_ratio`
- `low_review`

It then compares low-review and non-low-review orders and evaluates baseline and class-balanced logistic regression models.

See [`notebooks/olist_delivery_review_analysis.ipynb`](notebooks/olist_delivery_review_analysis.ipynb).

## Repository Structure

```text
olist-ecommerce-analytics/
├── README.md
├── requirements.txt
├── sql/
│   └── olist_analysis.sql
├── notebooks/
│   └── olist_delivery_review_analysis.ipynb
├── tableau/
│   └── Olist_Ecommerce_Dashboard.twb
└── assets/
    └── dashboard.png
```

## Data

This project uses the **Brazilian E-Commerce Public Dataset by Olist**. Raw CSV files are intentionally not included in this repository.

The core PostgreSQL tables used are:

- `customers`
- `orders`
- `order_items`
- `products`
- `payments`
- `reviews`

## Tools

**PostgreSQL · Python · pandas · NumPy · scikit-learn · Matplotlib · Tableau Public**

## Running the Notebook

1. Load the Olist data into PostgreSQL using the table names listed above.
2. Install the Python dependencies:

```bash
pip install -r requirements.txt
```

3. Open the notebook and run the cells. The PostgreSQL password is requested interactively with `getpass`, so no credential is stored in the notebook.

## Tableau

The Tableau workbook was built in Tableau Public from project CSV exports. The dashboard screenshot is included above for direct viewing on GitHub. A Tableau Public profile/workbook link can be added here after publishing.
