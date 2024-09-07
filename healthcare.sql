--The healthcare dataset is quite an expansive and informative dataset; containing 55,000 rows and 15 columns gathered over 5 years from May 2019 to May 2024.
--It carries information on patients' demographics, medical condition, and details about their treatment.
--Looking at this data, there is so much that could be done with it. however, some parts of it are unclean and unfit to be used.
--Therefore, they have to be cleaned and reformed to be efficient.
--Conclusively, working on this data will be focused on two different end-points; data cleaning and actual data analysis.

--First off, let's take a view of the entire data
select * from PortfolioProject.dbo.healthcare_dataset

--Taking a general view; you could see that the 'Name' column is defective and irregular. Caps are written into small letters, giving the data a rough look.
--Thus, the first problem we'll be solving is dealing and regularizing this column.
--I imported a function which convertes the data in the Name column to proper case as there are no built in functions for this purpose in SSMS
 

IF OBJECT_ID('dbo.fn_TitleCase', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_TitleCase;
GO

CREATE FUNCTION dbo.fn_TitleCase
(
    @Input NVARCHAR(1000)
)
RETURNS NVARCHAR(1000)
AS
BEGIN
    DECLARE @Result NVARCHAR(1000);

    SELECT @Result = STRING_AGG(UPPER(LEFT(value, 1)) + LOWER(SUBSTRING(value, 2, LEN(value) - 1)), ' ')
    FROM STRING_SPLIT(@Input, ' ');

    RETURN @Result;
END;
GO

--- To use
UPDATE PortfolioProject.dbo.healthcare_dataset
SET Name = dbo.fn_TitleCase(Name);

--Next, there are irregularities in the 'Hospital' column.
--This stems from the inconsistent use of 'and' throughout the column
--Let's take a look at the column.
select Hospital
from PortfolioProject.dbo.healthcare_dataset

--It is evident that its usage in some cases is on point, in exceptions however, it looks and sound extremely ludicurous
--On the assumption that cases where the word is used within data points are right, we would then need to eliminate the exceptions where it exists at the beginning or the end of the hospital's name

update PortfolioProject.dbo.healthcare_dataset
set Hospital = Replace (Hospital, 'and', '')
where hospital like '% and'
or hospital like 'and %';

--Still in this column, there are anomalies where hospital names like Cook PLC, Cook Ltd were mistakenly entered as PLC Cook or Ltd Cook respectively. 
--Treating this is done in two steps; first concatenating those data points with their respective suffices to show, then removing the innapropiate prefix.

update PortfolioProject.dbo.healthcare_dataset
SET hospital = CONCAT(hospital, ' PLC')
WHERE hospital LIKE 'PLC %';

--Thereafter, a replacement operation can be carried to replace the unwanted suffix

update PortfolioProject.dbo.healthcare_dataset
set Hospital = Replace (Hospital, 'PLC', '')
where hospital like 'PLC %';

--This process is repeated for data points containing anomalies with LLC

update PortfolioProject.dbo.healthcare_dataset
SET hospital = CONCAT(hospital, ' LLC')
WHERE hospital LIKE 'LLC %';

update PortfolioProject.dbo.healthcare_dataset
set Hospital = Replace (Hospital, 'LLC', '')
where hospital like 'LLC %';

--As well as those with the Ltd anomaly

UPDATE PortfolioProject.dbo.healthcare_dataset
SET hospital = CONCAT(hospital, ' Ltd')
WHERE hospital LIKE 'Ltd %';

update PortfolioProject.dbo.healthcare_dataset
set Hospital = Replace (Hospital, 'Ltd', '')
where hospital like 'Ltd %';

--Lastly, some data points have unneccesary ',' at the end of their values. A replacement operation is carried out for correction.

update PortfolioProject.dbo.healthcare_dataset
set Hospital = Replace (Hospital, ',', '')
where hospital like '%,';

--Next, we will try to find out the duration of illness for each particular entry using both date values given in the data.
--For efficiency, an entirely new columm will be created for this purpose

alter table PortfolioProject.dbo.Healthcare_dataset
add Duration_of_Illness_Days int

--Updating the column with the differential of both columns

update PortfolioProject.dbo.Healthcare_dataset
set Duration_of_Illness_Days = DATEDIFF(DAY, Date_of_Admission, Discharge_Date)

--Lastly, values in the Age column can be redistributed to make age grades for patients
--As above, a new column will be created for this purpose as well.

alter table PortfolioProject.dbo.Healthcare_dataset
add Age_Grade varchar (25)

update PortfolioProject.dbo.healthcare_dataset
set Age_grade = 
case
when Age <=15 then 'Child'
when Age between 16 and 23 then 'Teen'
when Age between 24 and 40 then 'Young Adult'
when Age between 41 and 60 then 'Adult'
else 'Old'
end


--With this, the data is now ready for a deep dive analysis to locate trends and answer questions
--There is so much we could do with this data; on the surface and under different layers.
--First, using the demographics, let's examine the average age of patients with respect to their several medical conditions and gender

select Medical_condition,Gender, count(name) as total_patients, avg(age) as avg_age 
from PortfolioProject.dbo.healthcare_dataset
group by Medical_Condition, Gender
order by Medical_Condition

--How are these medical conditions distributed across different age grades?

select Age_Grade, Medical_Condition, count(medical_condition)
from PortfolioProject.dbo.healthcare_dataset
group by Age_grade, Medical_Condition
order by Age_Grade 

--What is the susceptibility of different Blood types to these medical conditions? 
--This could be further drilled down to show the distribution of each blood type under the various medical conditions presented
select Blood_Type,Medical_Condition, count(medical_condition) 
from PortfolioProject.dbo.healthcare_dataset
group by Blood_Type, Medical_Condition
order by Blood_Type 

--From the data, we can deduce that the mode of admission into hospitals vary.
--However, how do they vary against different medical conditions recorded in this dataset?

select Medical_Condition, Admission_Type, count(admission_type) as total_admissions
from PortfolioProject.dbo.healthcare_dataset
group by Medical_Condition, Admission_Type
order by Medical_Condition

--Still on the medical conditions, on a average, how long does the treatment of these conditions last?

Select Medical_Condition, avg(Duration_of_Illness_Days)
from PortfolioProject.dbo.healthcare_dataset
group by Medical_Condition
order by Medical_Condition

--Since this result seems uniform when we are actually looking for disparity, lets examine this same parameter relating to the medication used.

Select Medical_Condition,Medication, avg(Duration_of_Illness_Days)
from PortfolioProject.dbo.healthcare_dataset
group by Medical_Condition,Medication
order by Medical_Condition

--At the end of treatment, how do test results compare with regard to medication administered?

Select Medication, Test_Results, count(Test_results)
from PortfolioProject.dbo.healthcare_dataset
group by Medication, Test_Results
order by Medication,Test_Results

--How many cases were satisfactorily solved under different age grades?

select Age_Grade, Medical_Condition, Count(Test_Results) as Normal_Results
from PortfolioProject.dbo.healthcare_dataset
where Test_Results = 'Normal'
group by Age_Grade, Medical_Condition
order by Age_Grade,Medical_Condition


--What is the total billing accrued by each Insurance company?

Select Insurance_Provider, sum(Billing_Amount) 
from PortfolioProject.dbo.healthcare_dataset
group by Insurance_Provider
order by Insurance_Provider

--How costly does the treatment of different medical conditions appear under different companies?
--This could make prospective customers reach cost effective decision per the best choice of insurance provider to go for.

Select Insurance_Provider, Medical_condition, avg(Billing_Amount) 
from PortfolioProject.dbo.healthcare_dataset
group by Insurance_Provider,Medical_condition
order by Insurance_Provider,Medical_condition

--What is the distribution of insurance providers across diferent age groups in this data?
--This could be used by Insurance companies in customer reviews and performance studies

Select Age_Grade,Insurance_Provider, count(Insurance_Provider) 
from PortfolioProject.dbo.healthcare_dataset
group by Age_Grade,Insurance_Provider
order by Age_Grade,Insurance_Provider

--As far as emergency admissions go, it could happen to anyone. However, using this data, we could try to get which age grade experienced it the most.

Select Age_Grade, count(Admission_Type) as Emergency_count
from PortfolioProject.dbo.healthcare_dataset
where Admission_Type = 'Emergency'
group by Age_Grade
order by Emergency_count desc

--How effective were the medication in treating these medical conditions?
--Using the test results column, we could take those whose test results returned 'Normal' as successful treatments. This can be further utilized to get what we want;

select Medical_Condition, Medication, count(Test_Results) as Complete_Treatment
from PortfolioProject.dbo.healthcare_dataset
where Test_Results = 'Normal'
group by Medical_Condition, Medication
order by Medical_Condition, Medication

