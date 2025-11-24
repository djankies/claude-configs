# Financial Analysis Reference

Domain-specific calculations and conventions for financial data analysis.

## Quarter-over-Quarter (QoQ) Growth

### Formula
```
QoQ Growth = ((Current Quarter - Previous Quarter) / Previous Quarter) × 100%
```

### Example
```
Revenue Q3 2024: $850,000
Revenue Q4 2024: $1,020,000

QoQ Growth = (($1,020,000 - $850,000) / $850,000) × 100%
           = ($170,000 / $850,000) × 100%
           = 20.0%
```

### Interpretation
- **Positive QoQ:** Company growing quarter-to-quarter
- **Negative QoQ:** Revenue decline, investigate causes
- **>15% QoQ:** Strong growth, potentially unsustainable
- **5-10% QoQ:** Healthy, sustainable growth

## Year-over-Year (YoY) Growth

### Formula
```
YoY Growth = ((Current Period - Same Period Last Year) / Same Period Last Year) × 100%
```

### Example
```
Revenue Q4 2023: $750,000
Revenue Q4 2024: $1,020,000

YoY Growth = (($1,020,000 - $750,000) / $750,000) × 100%
           = ($270,000 / $750,000) × 100%
           = 36.0%
```

### Interpretation
- **Positive YoY:** Annual growth trend
- **Negative YoY:** Year-over-year decline
- **>20% YoY:** Strong annual growth
- **Consistent YoY:** Predictable business model

## Forecasting

### Linear Trend Forecast
```javascript
// Calculate average QoQ growth
const quarters = [850000, 920000, 1020000, 1150000];
const growthRates = quarters.slice(1).map((q, i) =>
  (q - quarters[i]) / quarters[i]
);
const avgGrowth = growthRates.reduce((a, b) => a + b) / growthRates.length;

// Forecast next quarter
const lastQuarter = quarters[quarters.length - 1];
const forecast = lastQuarter * (1 + avgGrowth);
// Result: $1,293,000
```

### Conservative Forecast
Use 75% of average growth rate for conservative projection:
```
Conservative Forecast = Last Quarter × (1 + (Avg Growth × 0.75))
```

## Financial Ratios

### Gross Profit Margin
```
Gross Profit Margin = ((Revenue - COGS) / Revenue) × 100%
```

### Operating Margin
```
Operating Margin = (Operating Income / Revenue) × 100%
```

### Burn Rate (for startups)
```
Monthly Burn Rate = (Starting Cash - Ending Cash) / Number of Months
Runway = Current Cash / Monthly Burn Rate
```

## Seasonality Adjustments

### Seasonal Index Calculation
```javascript
// Calculate quarterly seasonal indices
const yearData = [
  [Q1: 800, Q2: 950, Q3: 1100, Q4: 1300],  // 2023
  [Q1: 900, Q2: 1050, Q3: 1200, Q4: 1450]   // 2024
];

// Average for each quarter across years
const q1Avg = (800 + 900) / 2;  // 850
const q2Avg = (950 + 1050) / 2; // 1000
// ... etc

// Calculate seasonal indices
const overallAvg = (850 + 1000 + 1150 + 1375) / 4; // 1093.75
const q1Index = 850 / 1093.75 = 0.78  // Q1 typically 22% below average
```

## Complete Analysis Example

**Input Data:**
```
Q1 2024: $900,000
Q2 2024: $1,050,000
Q3 2024: $1,200,000
Q4 2024: $1,350,000
```

**Analysis:**
```
QoQ Growth Rates:
Q1→Q2: +16.7%
Q2→Q3: +14.3%
Q3→Q4: +12.5%

Average QoQ Growth: +14.5%

YoY Growth (vs 2023):
Q1: +12.5%
Q2: +10.5%
Q3: +9.1%
Q4: +3.8%

Observations:
- Decelerating YoY growth (12.5% → 3.8%)
- Consistent QoQ growth (~14%)
- Q4 weak compared to trend

Forecast Q1 2025:
Linear: $1,545,000 (+14.5%)
Conservative: $1,497,000 (+10.9%)
Range: $1.50M - $1.55M
```
