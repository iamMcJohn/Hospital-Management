# 🏥 Hospital Management Exploratory Aalysis With SQL

## 📌 Introduction

Healthcare institutions generate large volumes of data daily; from patient admissions and diagnoses to billing, staffing, and resource utilization. When properly analyzed, this data can provide powerful insights that improve operational efficiency, patient outcomes, and financial sustainability.

This project focuses on analyzing a hospital management dataset to understand how a hospital operates across key functional areas such as patient flow, clinical services and revenue performance. Using SQL and exploratory data analysis (EDA) techniques, the project examines patterns in patient visits, treatment types, departmental workload, and operational bottlenecks.

## 🎯 Objectives

The goal of this analysis is to transform raw hospital data into actionable insights that hospital administrators and healthcare managers can use to:

- Optimize patient admission and discharge processes

- Improve utilization of medical staff and facilities

- Identify high-demand services and cost drivers

- Support data-driven decision-making in hospital operations

By simulating real-world healthcare analytics scenarios, this project demonstrates how data analysis can support efficient hospital management, enhance service delivery, and contribute to better healthcare outcomes.


## 📊 Data Overview
The analysis encompasses five interconnected datasets that model a comprehensive hospital ecosystem:
- patients table – Patient demographics, contact details, registration info, and insurance data
- doctors table – Doctor profiles with specializations, experience, and contact information
- appointments table – Appointment dates, times, visit reasons, and statuses
- treatments table – Treatment types, descriptions, dates, and associated costs
- billing table – Billing amounts, payment methods, and status linked to treatments

#### Tables & Column Descriptions
- **patients table**: Contains patient demographic and registration details.

  patient_id: Unique ID for each patient
  
  first_name: Patient's first name
  
  last_name: Patient's last name
  
  gender: Gender (M/F)
  
  date_of_birth: Date of birth
  
  contact_number: Phone number
  
  address: Address of the patient
  
  registration_date: Date of first registration at the hospital
  
  insurance_provider: Insurance company name
  
  insurance_number: Policy number
  
  email: Email address

- **doctors**: Details about the doctors working in the hospital.

  doctor_id: Unique ID for each doctor
  
  first_name: Doctor's first name
  
  last_name: Doctor's last name
  
  specialization: Medical field of expertise
  
  phone_number: Contact number
  
  years_experience: Total years of experience
  
  hospital_branch: Branch of hospital where doctor is based
  
  email: Official email address

- **appointments**: Records of scheduled and completed patient appointments.

  appointment_id: Unique appointment ID
  
  patient_id: ID of the patient
  
  doctor_id: ID of the attending doctor
  
  appointment_date: Date of the appointment
  
  appointment_time: Time of the appointment
  
  reason_for_visit: Purpose of visit (e.g., checkup)
  
  status: Status (Scheduled, Completed, Cancelled)

- **treatments**: Information about the treatments given during appointments.

  treatment_id: Unique ID for each treatment
  
  appointment_id: Associated appointment ID
  
  treatment_type: Type of treatment (e.g., MRI, X-ray)
  
  description: Notes or procedure details
  
  cost: Cost of treatment
  
  treatment_date: Date when treatment was given

- **billing**: Billing and payment details for treatments.

  bill_id: Unique billing ID
  
  patient_id: ID of the billed patient
  
  treatment_id: ID of the related treatment
  
  bill_date: Date of billing
  
  amount: Total amount billed
  
  payment_method: Mode of payment (Cash, Card, Insurance)
  
  payment_status: Status of payment (Paid, Pending, Failed)

You can download the data [here](https://www.kaggle.com/datasets/kanakbaghel/hospital-management-dataset)
 

## 🛠️ Tools
- SQL Server - The entire analysis was built within SQL Server, beginning with the critical data preparation phase. I imported the source .csv files, corrected and enforced appropriate data types for each column, and then structured the database by defining the relational keys (primary and foreign keys) based on the provided ER diagram. This foundational work ensured the data model was both accurate and efficient for complex queries.

## 💡 Key Insights and Findings
### Patient Demographics & Engagement: Understanding patient composition, visit behavior, lifetime value, and registration growth trends.

```sql
--Number of registered patients in the hospital
	SELECT COUNT(patient_id) Total_patient
	FROM patients;
```

```sql
--Monthly patient registration trend
	SELECT DATEPART(MONTH,registration_date) reg_month,
          COUNT(patient_id) Total_patient
	FROM patients
	GROUP BY DATEPART(MONTH,registration_date);
```

```sql
--Number of visit to the hospital by each patient
	SELECT patient_id, 
          COUNT(appointment_id) number_of_visit
	FROM appointments
	GROUP BY patient_id;
```

```sql
--Total treatment cost incurred by each patient
	SELECT p.patient_id, 
		   ROUND(SUM(amount),2) cost_incured
	FROM patients p
	JOIN billing b 
	ON p.patient_id = b.patient_id
	GROUP BY p.patient_id;
```

```sql
--Patients whose total billed amount exceeds the average patient billing.
	WITH Patient_total (patient_id, total)
	AS
	(
		SELECT patient_id, 
			   ROUND(SUM(amount),2) total
		FROM billing 
		GROUP BY patient_id
	)
	SELECT patient_id, 
		   total
	FROM Patient_total
	WHERE total > (SELECT ROUND(AVG(total),2) 
				   FROM Patient_total);
```

**Business Value**: This helps the hospital management understand patient mix, retention, high-value patients, and long-term demand growth.


### Doctor Workforce & Performance Insights: How medical staff contribute to care delivery and revenue.

```sql
--Number of appointments handled by each doctor
	SELECT d.doctor_id, 
		   COUNT(appointment_id) Appoinments_handled
	FROM doctors d
	JOIN appointments a
	ON d.doctor_id = a.doctor_id
	GROUP BY d.doctor_id;
```

```sql
--Doctors with the number of completed appointments
	SELECT doctor_id, 
		   COUNT(appointment_id) no_of_completed_appointment
	FROM appointments
	WHERE [status] = 'completed'
	GROUP BY doctor_id
	ORDER BY no_of_completed_appointment DESC;
```

```sql
--Doctor with the highest generating revenue treatment
	SELECT TOP 1 d.doctor_id, 
	       ROUND(SUM(cost),2) revenue_generated
	FROM doctors d
	JOIN appointments a
	ON d.doctor_id = a.doctor_id
	JOIN treatments t
	ON a.appointment_id = t.appointment_id
	GROUP BY d.doctor_id
	ORDER BY revenue_generated DESC;
```

```sql
--The average treatment cost per doctor specialization
	SELECT specialization, 
		   ROUND(AVG(cost),2) avg_treatment_cost
	FROM doctors d
	JOIN appointments a
	ON d.doctor_id = a.doctor_id
	JOIN treatments t
	ON a.appointment_id = t.appointment_id
	GROUP BY specialization;
```

```sql
--Rank doctors by total revenue generated within each specialization.
	WITH revenue_by_doc_spec (doctor_id, specialization, Revenue)
	AS
	(
		SELECT d.doctor_id, specialization, 
			   ROUND(SUM(amount),2) Revenue
		FROM doctors d
		JOIN appointments a
		ON d.doctor_id = a.doctor_id
		JOIN billing b
		ON a.patient_id = b.patient_id
		GROUP BY d.doctor_id, specialization
	)
	SELECT doctor_id, 
		   specialization, 
		   Revenue, 
		   RANK() OVER(PARTITION BY specialization ORDER BY revenue DESC) position
	FROM revenue_by_doc_spec;
```
**Business Value**: This will help in making staffing decisions, performance evaluation, and incentive planning.

### Appointment & Operational Efficiency Insights: How effectively the hospital runs day-to-day operations.
  
```sql
--Number of appointments scheduled, completed, and cancelled
	SELECT [status], 
		   COUNT(appointment_id) No_of_appointments
	FROM appointments
	GROUP BY [status];
```

```sql
--Most common reasons for patient visits
	SELECT reason_for_visit, 
		   COUNT(appointment_id) No_of_appointments
	FROM appointments
	GROUP BY reason_for_visit
  ORDER BY No_of_appointments DESC;
```

```sql
--Monthly appointment volume trend
	SELECT MONTH(appointment_date) [Month], 
		   COUNT(patient_id) No_of_appointments
	FROM appointments
	GROUP BY MONTH(appointment_date);
```

```sql
--Measure of month-over-month growth in appointments.
	SELECT DATENAME(MONTH, appointment_date) month_name, 
		   MONTH(appointment_date) month_num, 
		   COUNT(appointment_id) total_apointment,
		   LAG(COUNT(appointment_id)) OVER(ORDER BY MONTH(appointment_date)) pre_count,
		   ROUND((CAST(COUNT(appointment_id) AS FLOAT)/CAST(LAG(COUNT(appointment_id)) OVER(ORDER BY MONTH(appointment_date)) AS FLOAT)-1)*100,2) MoM_growth
	FROM appointments
	GROUP BY DATENAME(MONTH, appointment_date),
		     MONTH(appointment_date);
```

```sql
--Treatments most commonly associated with cancelled appointments
	SELECT treatment_type, 
		   COUNT(a.appointment_id)
	FROM treatments t
	JOIN appointments a
	ON t.appointment_id = a.appointment_id
	WHERE [status] = 'cancelled'
	GROUP BY treatment_type;
```

**Business Value**: This helps in identifying operational bottlenecks, peak demand periods, and inefficiencies in scheduling.


### Treatment & Clinical Cost Insights: What services are delivered and their cost structure.

```sql
--Treatment types that are offered and how frequently are they performed
	SELECT treatment_type, 
		   COUNT(treatment_id) Frequency_of_admin
	FROM treatments
	GROUP BY treatment_type;
````

```sql
--The top 3 most expensive treatments per month.
	WITH Exp_treat([month], treatment_type, total_expense, rn)
	AS
	(
	SELECT MONTH(treatment_date) [month], 
		   treatment_type, 
		   ROUND(SUM(cost),2) total_expense, 
		   RANK() OVER(PARTITION BY MONTH(treatment_date)  ORDER BY SUM(cost)) rn
	FROM treatments
	GROUP BY MONTH(treatment_date), treatment_type
	)
	
	SELECT [month], treatment_type, total_expense
	FROM Exp_treat
	WHERE rn <= 3;
````

**Business Value**: This highlights cost drivers, high-value services, and areas requiring cost control or investment.

### Billing, Revenue & Financial Performance Insights: How money flows through the hospital.
  
```sql
--Percentage of bills that are Paid, Pending, or Failed
	SELECT payment_status, 
	CAST(COUNT(bill_id)/(SELECT CAST(COUNT(bill_id) AS FLOAT)
								FROM billing) AS FLOAT)*100 [%status]
	FROM billing
	GROUP BY payment_status;
```

```sql
--Total revenue generated per hospital branch
	SELECT hospital_branch, 
		   ROUND(SUM(cost),2) revenue_generated
	FROM doctors d
	JOIN appointments a
	ON d.doctor_id = a.doctor_id
	JOIN treatments t
	ON a.appointment_id = t.appointment_id
	GROUP BY hospital_branch;
```

```sql
--Total billing amount covered by each insurance provider
	SELECT insurance_provider, 
		   ROUND(SUM(amount),2) Total_payment
	FROM billing b
	JOIN patients p
	ON b.patient_id = p.patient_id
	GROUP BY insurance_provider;
```

```sql
--Calculate cumulative monthly revenue over time.
WITH Monthly_Revenue (month_num, [month], monthly_revenue)
AS
  (
		SELECT MONTH(bill_date) month_num, 
			  DATENAME(MONTH, bill_date) [month], 
			  ROUND(SUM(amount),2) monthly_revenue
		FROM billing
		GROUP BY MONTH(bill_date), 
				 DATENAME(MONTH, bill_date)
  )
SELECT [month], 
     monthly_revenue, 
     SUM(monthly_revenue) OVER(ORDER BY month_num) Running_total
FROM Monthly_Revenue;
```

```sql
--Calculate payment success rate per insurance provider.
	WITH successful_payment (insurance_provider, payment_method, succ_payment)
	AS
	(
	SELECT insurance_provider, 
		   payment_method, 
		   CAST(COUNT(payment_status) AS FLOAT) succ_payment
	FROM billing b
	JOIN patients p
	ON b.patient_id = p.patient_id
	WHERE payment_status = 'paid' AND payment_method = 'insurance'
	GROUP BY insurance_provider, payment_method
	),

	attempted_payment (insurance_provider, payment_method, initiated_payment)
	AS
	(
	SELECT insurance_provider, 
		   payment_method, 
		   CAST(COUNT(payment_status) AS FLOAT) initiated_payment
	FROM billing b
	JOIN patients p
	ON b.patient_id = p.patient_id
	WHERE payment_method = 'insurance'
	GROUP BY insurance_provider, 
		     payment_method
	)
	SELECT a.insurance_provider, 
		   ROUND((succ_payment/initiated_payment*100),2) success_rate
	FROM successful_payment s
	JOIN attempted_payment a
	ON s.insurance_provider = a.insurance_provider;
```


**Business Value**: This provides visibility into revenue health, insurance dependency, and financial stability.

### Automation & Reporting: Operationalizing analytics for real-world use.

```sql
--Stored procedure to return a patient’s full medical & billing history by patient_id.
	CREATE PROC sp_medicalhistory 
		@id VARCHAR(50)
	AS
	BEGIN
		SELECT t.treatment_id, 
			   treatment_type, 
			   treatment_date, 
			   payment_method, 
			   payment_status
		FROM treatments t
		JOIN billing b
		ON t.treatment_id = b.treatment_id
		WHERE b.patient_id = @id
	END

	EXEC sp_medicalhistory 'p008'
```

```sql
--Stored procedure to generate monthly hospital revenue reports.
	CREATE PROC sp_monthlyrevenue
	@hospital NVARCHAR(50),
	@month_num INT
	AS
	BEGIN
		SELECT d.hospital_branch, 
			   MONTH(t.treatment_date), 
			   ROUND(SUM(cost),2) revenue
		FROM doctors d
		JOIN appointments a
		ON d.doctor_id = a.doctor_id
		JOIN treatments t
		ON a.appointment_id = t.appointment_id
		JOIN billing b
		ON t.treatment_id = b.treatment_id
		WHERE payment_status <> 'failed' and hospital_branch = @hospital AND MONTH(t.treatment_date) = @month_num
		GROUP BY hospital_branch, 
			     MONTH(t.treatment_date)
	END

	EXEC sp_monthlyrevenue 'Westside Clinic', 3
```

**Business Value**: This demonstrates production-ready SQL skills and enables repeatable reporting.


## Conclusion

This exploratory data analysis examined hospital operations, clinical services, and financial performance using a relational hospital management dataset in SQL Server. The objective was to uncover patterns in patient behavior, doctor performance, operational efficiency, and revenue flow to support data-driven decision-making in a healthcare setting.

The analysis revealed clear patterns in **patient engagement**, with patients not been a one time visit type, thereby accounting for revenue generation.

**Appointment analysis** showed various reasons patient visit the hosppital and the rate of completion of treatment by doctors.
It also revealed **chemotherapy** as the treatment associated with cancelled appointment.

On the financial side, the **billing analysis** highlighted payment delays and failed transactions, particularly within insurance providers. These gaps represent potential revenue leakage and emphasize the need for stronger billing follow-ups and insurance processing workflows. 


## Recommendations

Based on these insights, the hospital management can:

- Optimize doctor scheduling based on demand and completion rates.
  
- Create a bonus/incentive scheme for doctors based off their completion rate to mitigate uncompleted appointment.

- Liase with insurance provider to cut down payment failure by introducing alternate platform.

- Bring on board more doctors with specialization in oncology.
