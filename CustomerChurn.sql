SELECT *
FROM Customer_Data

-- Create copy of data to work on
SELECT *
INTO cpyCustomer_Data
FROM Customer_Data

SELECT * 
FROM cpyCustomer_Data

-- Used to remove the extra digits that came over in the "Monthly Charges" and "Total_Charges" columns when data was uplaoded. Rounded to two decimal places
UPDATE cpyCustomer_Data SET
Monthly_Charges = ROUND(Monthly_Charges,2)

UPDATE cpyCustomer_Data SET
Total_Charges = ROUND(Total_Charges,2)

-- Drop column no need for two 3 columns with the same data duplicated
ALTER TABLE cpyCustomer_Data
DROP COLUMN Lat_Long

-- Total Number of Churned customers
SELECT COUNT(Churn_Value) as TotalChurnedCustomers
FROM cpyCustomer_Data
WHERE Churn_Value = 1

-- Check to see if there are instances where customer churned but did not provide a reason
SELECT Churn_Reason, Count(Churn_Value)
FROM cpyCustomer_Data
WHERE Churn_Reason IS NULL AND Churn_Value = 1
GROUP BY Churn_Reason,Churn_Value
-- No data showed up so they were no instances of that

-- Added churn status table to access predetermined Churn reason categories
SELECT *
FROM Churn_Status

-- Tallying the number of times a customer churned for each Churn reason

SELECT Churn_Reason, COUNT(Churn_Reason) as NumberOfTimes
FROM cpyCustomer_Data
GROUP BY Churn_Reason
ORDER BY NumberOfTimes DESC

-- Do the same but for Churn Status to see if the data matches
SELECT Churn_Reason, COUNT(Churn_Reason) as NumberOfTimes
FROM Churn_Status
GROUP BY Churn_Reason
ORDER BY NumberOfTimes DESC

/* Realising differences in the Reasons over the cpyCustomer_Data and Churn Status datasets- unsure why*/

-- Check to see if Churn_Status chruned customers is the same as cpyCustomer_Data table
SELECT COUNT(Churn_Value) as TotalChurnedCustomers,
	(SELECT COUNT(Churn_Value) as StatusTotalChurned 
	FROM Churn_Status 
	WHERE Churn_Value = 1)
FROM cpyCustomer_Data
WHERE Churn_Value = 1
-- Number is the same. So it is the same set.

-- Check to see if all customers are accounted for - Once everyone is the count should reach the total number of records
SELECT COUNT(*)
FROM Churn_Status
WHERE EXISTS (
	SELECT *
	FROM cpyCustomer_Data
	WHERE Churn_Status.Customer_ID = cpyCustomer_Data.CustomerID
)
-- Everyone is accounted for in each data set

-- Check to see if there is a difference in the customer churn reason between the datasets
-- Checks if churn reason is the same or not across each dataset

SELECT Customer_ID, Churn_Reason
FROM Churn_Status
WHERE EXISTS (
	SELECT *
	FROM cpyCustomer_Data
	WHERE Churn_Status.Customer_ID = cpyCustomer_Data.CustomerID AND Churn_Status.Churn_Reason <> cpyCustomer_Data.Churn_Reason 
)
-- Results show that there is a difference in data for Churn Reason for 519 custoemrs accros cpyCustomer_Data and Churn_Status datasets

-- Using the cpyCustomer_Data dataset to continue with the analysis; 
-- As this is just for practicing purposes I'll ignore the churn_status table and focus solely on the cpyCustomer_Data table

-- Spliting the data set into two categories; Churned customers and Staying customers; Store in seperate tables

-- Churned Customers
SELECT *
INTO Churned_Customers
FROM cpyCustomer_Data
WHERE Churn_Label = 'Yes'

-- Staying Customers
SELECT *
INTO Staying_Customers
FROM cpyCustomer_Data
WHERE Churn_Label = 'No'

-- Avg Monthly Charges for churned customers
SELECT ROUND(AVG(Monthly_Charges),2)
FROM Churned_Customers

-- Min, Max Monthly Charge for churned customers
SELECT ROUND(MIN(Monthly_Charges),2) as MinMonthlyCharge, ROUND(MAX(Monthly_Charges),2) as MaxMonthlyCharge
FROM Churned_Customers

-- Min, Max and Avg Churn Score for churn customers
SELECT MIN(Churn_Score) as Lowest, MAX(Churn_Score) as Highest, AVG(Churn_Score) as Avearage
FROM Churned_Customers

-- Mode (Most frequent) Churn Score for churned customers
SELECT DISTINCT TOP 1 Churn_Score, COUNT(Churn_Reason) as ScoreCount 
FROM Churned_Customers 
GROUP BY Churn_Score
ORDER BY ScoreCount DESC

-- Number of times Max Churn score was reached
SELECT COUNT(CustomerID) as NumTimesMaxChurn
FROM Churned_Customers
WHERE Churn_Score = 100

-- Apply the same MIN MAX AVG  to Customer Liftime Value for churned customers
SELECT MIN(CLTV) as Lowest, MAX(CLTV) as Highest, AVG(CLTV) as Avearage
FROM Churned_Customers

-- Tally of the diffrent reasons for customer churned
SELECT DISTINCT Churn_Reason, COUNT(Churn_Reason) as Instances, ROUND((COUNT(Churn_Reason)*100.00/(SELECT COUNT (*) FROM Churned_Customers)),2) as PercentOfTotalChurned
FROM Churned_Customers
GROUP BY Churn_Reason
ORDER BY Instances DESC

-- Create a new column that categorizes chrun reasons
ALTER TABLE Churned_Customers
ADD Churn_Reason_Category AS
	CASE WHEN (LOWER(Churn_Reason) LIKE '%attitude%') THEN 'Attitude'
		WHEN (LOWER(Churn_Reason) LIKE '%competitor%') THEN 'Competitor'
		WHEN (LOWER(Churn_Reason) LIKE '%price%' OR LOWER(Churn_Reason) LIKE '%charges%') THEN 'Price'
		WHEN (LOWER(Churn_Reason) LIKE '%dissatisfaction%' OR LOWER(Churn_Reason) LIKE '%limited%' OR 
		LOWER(Churn_Reason) LIKE '%lack%' OR LOWER(Churn_Reason) LIKE '%poor%' OR LOWER(Churn_Reason) LIKE '%reliability%') THEN 'Dissatisfaction'
		ELSE 'Other'
	END

-- Create a new coulumn that tallies the number of services a churned customer had
ALTER TABLE Churned_Customers
ADD Service_Count AS
	CASE WHEN (Phone_Service = 'Yes') THEN 1 ELSE 0	END +
	CASE WHEN (Internet_Service <> 'No') ThEN 1 ELSE 0 END +
	CASE WHEN (Online_Security = 'Yes') THEN 1 ELSE 0 END +
	CASE WHEN (Online_Backup = 'Yes') THEN 1 ELSE 0 END +
	CASE WHEN (Device_Protection = 'Yes') THEN 1 ELSE 0 END +
	CASE WHEN (Tech_Support = 'Yes') THEN 1 ELSE 0 END +
	CASE WHEN (Streaming_TV = 'Yes') THEN 1 ELSE 0 END +
	CASE WHEN (Streaming_Movies = 'Yes') THEN 1 ELSE 0 END

-- Apply same tally of services to staying customers as well

ALTER TABLE Staying_Customers
ADD Service_Count AS
	CASE WHEN (Phone_Service = 'Yes') THEN 1 ELSE 0	END +
	CASE WHEN (Internet_Service <> 'No') ThEN 1 ELSE 0 END +
	CASE WHEN (Online_Security = 'Yes') THEN 1 ELSE 0 END +
	CASE WHEN (Online_Backup = 'Yes') THEN 1 ELSE 0 END +
	CASE WHEN (Device_Protection = 'Yes') THEN 1 ELSE 0 END +
	CASE WHEN (Tech_Support = 'Yes') THEN 1 ELSE 0 END +
	CASE WHEN (Streaming_TV = 'Yes') THEN 1 ELSE 0 END +
	CASE WHEN (Streaming_Movies = 'Yes') THEN 1 ELSE 0 END

-- Churn Per City
SELECT DISTINCT City, COUNT(city) as ChurnedCustomers
FROM Churned_Customers
GROUP BY City
ORDER BY ChurnedCustomers DESC

-- Min Max Avg Churn Score for Staying Customers
SELECT MIN(Churn_Score) as Lowest, MAX(Churn_Score) as Highest, AVG(Churn_Score) as Avearage
FROM Staying_Customers

-- Mode Churn Score
SELECT DISTINCT TOP 1 Churn_Score, Count(Churn_Score) as ScoreCount
FROM Staying_Customers
GROUP BY Churn_Score
ORDER BY ScoreCount DESC

-- Min Max Avg CLTV Scores for staying customers
SELECT MIN(CLTV) as Lowest, MAX(CLTV) as Highest, AVG(CLTV) as Avearage
FROM Staying_Customers

-- New Customers vs Churned customers (New customers calssified as customers who had service for a month or less)
SELECT COUNT(*) as NewCustomers, (SELECT COUNT(*) FROM cpyCustomer_Data WHERE Churn_Value = 1) as ChurnedCustomers
FROM cpyCustomer_Data
WHERE Tenure_Months < 2

-- Contract Type Count for churned customers
SELECT DISTINCT Contract, COUNT(Contract) as NumContractType
FROM Churned_Customers
GROUP BY Contract

-- Contract Type Count for Staying Customers
SELECT DISTINCT Contract, COUNT(Contract) as NumContractType
FROM Staying_Customers
GROUP BY Contract

-- Churn Risk levels for Staying customers - Add Column Levels determined based on comparisons of the min, max and avg values for churn score for both churned and staying customers

ALTER TABLE Staying_Customers
ADD Churn_Risk_Level AS
	CASE 
		WHEN (Churn_Score < 40) THEN 'Low'
		WHEN (Churn_Score >= 40 AND Churn_Score <= 60) THEN 'Medium'
		ELSE 'High'
	END 

-- Number of customer that are at high risk of churning vs low
SELECT COUNT(*) as HighRisk, (SELECT COUNT(*) FROM Staying_Customers WHERE Churn_Risk_Level = 'Medium') as MediumRisk, (SELECT COUNT(*) FROM Staying_Customers WHERE Churn_Risk_Level = 'Low') as LowTally
FROM Staying_Customers
WHERE Churn_Risk_Level ='High'


-- Lets say hgih value custoemrs have a CLTV score of 5000 or more; identify high value customers that are at high risk of churning

SELECT COUNT(*) as HighValueHighRisk
FROM Staying_Customers
WHERE Churn_Risk_Level ='High' AND CLTV > 5000
