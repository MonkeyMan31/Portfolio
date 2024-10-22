# Executive Summary

This report outlines a consultancy project for the U.S. Department of Transportation (DOT) focused on analysing arrival flight delays at public airports across the United States and its related territories. The analysis encompasses data from U.S. domestic flights spanning from June 2003 to December 2023. It includes monthly statistics of arrivals, delayed arrivals and cancelled flights by each airline and destination airport. The reason for delays are categorised as follows: 

1 - Carrier | Airline-controlled circumstances such as maintenance or crew issues

2 - Late Aircraft | Aircraft arriving late from the previous flight 

3 - National Airspace System (NAS) | Non-extreme weather, airport operations, and air traffic control 

4 - Weather | Significant meteorological conditions such as blizzards, or hurricanes 

5 - Security | security breaches or boarding problems 

The DOT seeks insights on the following issues:

- Avoidable Delays: Caused by on-ground and aviation operations, or air traffic control. This includes carrier, late aircraft and NAS categories. 
- Unavoidable Delays: Caused by harsh weather conditions or security reasons. This includes security and weather categories. 
- Flight Cancellations: Distribution, rate, and patterns based on season and regions.

In addition to passenger security, the DOT is concerned with the financial and temporal impacts of delays and cancellations in the aviation industry. In 2023, one in five flights were delayed due to avoidable or unavoidable reasons. These delays can cause passengers to miss connecting flights or accommodation reservations, placing additional strain on the National Aviation System to maintain the schedule. A reduction of even 10% in flight delays could save over $2 billion dollars and 40,000 hours, significantly enhancing passenger satisfaction. This analysis aims to identify opportunities to minimise these losses.

The approach involves analysing general categories of delay, distinguishing between avoidable and unavoidable delays, and considering the roles of airlines and airports. This includes a historical review and examination of delay rates for arrival flights, delay duration per delayed arrival, and the causes of delays. Exploratory analysis is used to identify the most influential elements in the avoidable delay category, which includes airlines, late aircrafts and National Airspace System (NAS) which is run by federal government. Seasonal trends for weather and security-related delays are also examined to anticipate future occurrences in unavoidable category.

The core of analysis evolves around the rate of delay by each of the 5 categories in arrivals and the delay duration per delayed arrivals that originates from them. Furthermore the share of each category from cumulative delay count and delay duration is measured for a fair scaled view of the matter and the influence of each element in total occurances. 
For good measure, an interactive dashboard with possibility of filtering the data based on date, region, airline and airport has been developed for deeper explorations into the matter.

**Findings**

- The average number of yearly delayed arrivals has decreased slightly from 2003 to 2023, but the median delay duration per delayed arrivals has increased by 31%, from 45 minutes in 2003 to 57 minutes in 2023. 
- 19.2% of total arrivals were delayed, with avoidable delays accounting for 96% of them. Late aircraft category has the highest share at 35.8% of all delays. 
- June, July, and December witness the highest delay rates, 3.5% more than yearly average, due to increased holiday travel and seasonal weather conditions.
- Southwest Airlines hold the the highest number of total delays in carrier (17.8%) and late aircraft (25.8%) categories, but their delay rate is just below the average of all.
- Internatioanl airports show considerably higher NAS delay rate (4.8%) and higher NAS delay duration (8.9 Minutes), followed by domestic (4%, 7.3 M) and regionals (3.7%, 7.2M).
- Highest average delay rates by region belongs to Northeast, with 21.7% in count and 56 minutes in duration, and the lowest to West region with 18.7% in count and 48 minutes in duration.
