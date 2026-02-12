--Number of registered patients in the hospital

	SELECT COUNT(patient_id) Total_patient
	FROM patients

--Gender distribution of patients

	SELECT gender, 
		   COUNT(patient_id) No_of_patients
	FROM patients
	GROUP BY gender
	
--Age distribution of patients (current age)

	SELECT patient_id, 
		   date_of_birth, 
		   DATEDIFF(YEAR, date_of_birth, GETDATE()) -
		   CASE 
		   WHEN MONTH(date_of_birth) > MONTH(GETDATE()) OR
		   MONTH(date_of_birth) = MONTH(GETDATE()) AND DAY(date_of_birth) >= DAY(GETDATE())
		   THEN 1
		   ELSE 0
		   END [patient's age]
	FROM patients

--Number of doctors by specialization

	SELECT specialization, 
		   COUNT(doctor_id) Number_of_doctors
	FROM doctors
	GROUP BY specialization


--Hospital branch with the most number of doctors

	SELECT TOP 1 hospital_branch, 
		   Number_of_doctors
	FROM	(
				SELECT hospital_branch, 
					   COUNT(doctor_id) Number_of_doctors
				FROM doctors
				GROUP BY hospital_branch
			) Doctors_count_by_hospital

--Number of appointments scheduled, completed, and cancelled

	SELECT [status], 
		   COUNT(appointment_id) No_of_appointments
	FROM appointments
	GROUP BY [status]


--Most common reasons for patient visits

	SELECT reason_for_visit, 
		   COUNT(appointment_id) No_of_appointments
	FROM appointments
	GROUP BY reason_for_visit

--Treatment types that are offered and how frequently are they performed
	
	SELECT treatment_type, 
		   COUNT(treatment_id) Frequency_of_admin
	FROM treatments
	GROUP BY treatment_type

--Average cost of treatments by treatment type

	SELECT treatment_type, 
		   ROUND(AVG(cost),2) avg_cost
	FROM treatments
	GROUP BY treatment_type	

--Percentage of bills that are Paid, Pending, or Failed
	
	SELECT payment_status, 
	CAST(COUNT(bill_id)/(SELECT CAST(COUNT(bill_id) AS FLOAT)
								FROM billing) AS FLOAT)*100 [%status]
	FROM billing
	GROUP BY payment_status

--Number of appointments handled by each doctor
	
	SELECT d.doctor_id, 
		   COUNT(appointment_id) Appoinments_handled
	FROM doctors d
	JOIN appointments a
	ON d.doctor_id = a.doctor_id
	GROUP BY d.doctor_id

--Doctors with the number of completed appointments

	SELECT doctor_id, 
		   COUNT(appointment_id) no_of_completed_appointment
	FROM appointments
	WHERE [status] = 'completed'
	GROUP BY doctor_id
	ORDER BY no_of_completed_appointment DESC

--Number of visit to the hospital by each patient
	
	SELECT patient_id, 
		   COUNT(appointment_id) number_of_visit
	FROM appointments
	GROUP BY patient_id
	
--Total treatment cost incurred by each patient

	SELECT p.patient_id, 
		   ROUND(SUM(amount),2) cost_incured
	FROM patients p
	JOIN billing b 
	ON p.patient_id = b.patient_id
	GROUP BY p.patient_id

--Total billing amount covered by each insurance provider
	
	SELECT insurance_provider, 
		   ROUND(SUM(amount),2) Total_payment
	FROM billing b
	JOIN patients p
	ON b.patient_id = p.patient_id
	GROUP BY insurance_provider

--Total revenue generated per hospital branch
	
	SELECT hospital_branch, 
		   ROUND(SUM(cost),2) revenue_generated
	FROM doctors d
	JOIN appointments a
	ON d.doctor_id = a.doctor_id
	JOIN treatments t
	ON a.appointment_id = t.appointment_id
	GROUP BY hospital_branch

--Doctor with the highest generating revenue treatment
	
	SELECT TOP 1 d.doctor_id, 
	       ROUND(SUM(cost),2) revenue_generated
	FROM doctors d
	JOIN appointments a
	ON d.doctor_id = a.doctor_id
	JOIN treatments t
	ON a.appointment_id = t.appointment_id
	GROUP BY d.doctor_id
	ORDER BY revenue_generated DESC

--Treatments most commonly associated with cancelled appointments
	
	SELECT treatment_type, 
		   COUNT(a.appointment_id)
	FROM treatments t
	JOIN appointments a
	ON t.appointment_id = a.appointment_id
	WHERE [status] = 'cancelled'
	GROUP BY treatment_type

--Patients already treated but no successful payment

	SELECT DISTINCT b.patient_id
	FROM patients p
	JOIN billing b
	ON p.patient_id = b.patient_id
	WHERE payment_status != 'paid'

--The average treatment cost per doctor specialization

	SELECT specialization, 
		   ROUND(AVG(cost),2) avg_treatment_cost
	FROM doctors d
	JOIN appointments a
	ON d.doctor_id = a.doctor_id
	JOIN treatments t
	ON a.appointment_id = t.appointment_id
	GROUP BY specialization

--Monthly patient registration trend

	select DATEPART(MONTH,registration_date) reg_month, 
		   COUNT(patient_id) Total_patient
	FROM patients
	GROUP BY DATEPART(MONTH,registration_date)
	
--Monthly appointment volume trend

	SELECT MONTH(appointment_date) [Month], 
		   COUNT(patient_id) No_of_appointments
	FROM appointments
	GROUP BY MONTH(appointment_date)

--volume of appointment by days of the week
	
	SELECT DATENAME(WEEKDAY,appointment_date) [Day], 
		   COUNT(patient_id) No_of_appointments 
	FROM appointments
	GROUP BY DATENAME(WEEKDAY,appointment_date)
	ORDER BY No_of_appointments DESC

--Number of failed transaction by month

	SELECT MONTH(bill_date) [Month], 
		   COUNT(bill_id) No_of_failed_payment
	FROM billing 
	WHERE payment_status = 'failed'
	GROUP BY MONTH(bill_date)

--Total treatment cost for patients with more than one visit to the hospital

	WITH ReatPatient (patient_id, freq)
	AS
	(
		SELECT patient_id, 
			   COUNT(patient_id) freq
		FROM appointments
		GROUP BY patient_id
		HAVING COUNT(patient_id) > 1
	) 

	SELECT r.patient_id, 
		   ROUND(SUM(b.amount),2) treat_cost
	FROM ReatPatient r
	JOIN billing b
	ON r.patient_id = b.patient_id
	GROUP BY r.patient_id
	

--Doctors whose appointment completion rate is above the hospital average.

	WITH comp_rate (doctor_id, no_of_appointment)
	AS
		(
			SELECT doctor_id, 
				   COUNT([status]) no_of_appointment
			FROM appointments
			WHERE [status] = 'completed'
			GROUP BY doctor_id
		) 
		
		SELECT doctor_id
		FROM comp_rate
		WHERE no_of_appointment > 
									(SELECT AVG(no_of_appointment)
									 FROM comp_rate)


--Revenue per specialization
	
	SELECT specialization, 
		   ROUND(SUM(amount),2) Revenue
	FROM doctors d
	JOIN appointments a
	ON d.doctor_id = a.doctor_id
	JOIN treatments t
	ON a.appointment_id = t.appointment_id
	JOIN billing b
	ON t.treatment_id = b.treatment_id
	GROUP BY specialization

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
				   FROM Patient_total)


--Determine hospital branches where average treatment cost is above the overall average.
	
	WITH Hos_branch (hospital_branch, avg_cost)
	AS
	(
		SELECT hospital_branch, 
			   ROUND(AVG(cost),2) avg_cost
		FROM doctors d
		JOIN appointments a
		ON d.doctor_id = a.doctor_id
		JOIN treatments t
		ON a.appointment_id = t.appointment_id
		GROUP BY hospital_branch
	)
	SELECT hospital_branch, 
		   avg_cost
	FROM Hos_branch
	WHERE avg_cost >
		(SELECT AVG(cost)
		FROM treatments)

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
		   RANK() OVER(partition by specialization ORDER BY revenue DESC) position
	FROM revenue_by_doc_spec

--Rank patients by total spending.

	WITH PTS (patient_id, Total_spending)
	AS
	(
	SELECT p.patient_id, 
		   ROUND(SUM(amount),2) Total_spending
	FROM patients p
	JOIN billing b
	ON p.patient_id = b.patient_id
	GROUP BY p.patient_id
	)

	SELECT patient_id, 
		   Total_spending, 
		   RANK() OVER(ORDER BY Total_spending DESC) position
	from PTS


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
		FROM Monthly_Revenue


--Compute running count of registered patients.

	WITH numberofpatient(month_num, [month], numberofpatients)
	AS
	(
	SELECT MONTH(registration_date) month_num, 
			DATENAME(MONTH, registration_date) [month], 
			COUNT(patient_id) numberofpatients
	FROM patients
	GROUP BY MONTH(registration_date), 
			DATENAME(MONTH, registration_date)
			)
	SELECT [month],
		   numberofpatients,
		   SUM(numberofpatients) OVER(ORDER BY month_num) runningcount
	FROM numberofpatient


--Compare each doctor’s appointment count to the average in their specialization.

	WITH doctor_apointment_count (doctor_id, specialization, num_pat)
	AS
	(
	SELECT d.doctor_id, specialization, 
		   COUNT(a.patient_id) num_pat
	FROM doctors d
	JOIN appointments a
	ON d.doctor_id = a.doctor_id
	JOIN treatments t
	ON a.appointment_id = t.appointment_id
	GROUP BY d.doctor_id, specialization
	)

	SELECT doctor_id, 
		   num_pat, 
		   AVG(num_pat) OVER(PARTITION BY specialization) avg_appointment_by_spec
	FROM doctor_apointment_count
	

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
	WHERE rn <= 3
		

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
	ON s.insurance_provider = a.insurance_provider
	

--Measure month-over-month growth in appointments.

	SELECT DATENAME(MONTH, appointment_date) month_name, 
		   MONTH(appointment_date) month_num, 
		   COUNT(appointment_id) total_apointment,
		   LAG(COUNT(appointment_id)) OVER(ORDER BY MONTH(appointment_date)) pre_count,
		   ROUND((CAST(COUNT(appointment_id) AS FLOAT)/CAST(LAG(COUNT(appointment_id)) OVER(ORDER BY MONTH(appointment_date)) AS FLOAT)-1)*100,2) MoM_growth
	FROM appointments
	GROUP BY DATENAME(MONTH, appointment_date),
		     MONTH(appointment_date)


--Detect treatments that were billed but not paid.

	SELECT t.treatment_id, 
		   treatment_type
	FROM billing b
	JOIN treatments t
	ON b.treatment_id = t.treatment_id
	WHERE payment_status = 'failed'	


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

	
--Stored procedure to calculate outstanding (unpaid) bills per patient.

	CREATE PROC sp_patOutstanding 
	@id VARCHAR(50)
	AS
	BEGIN
		SELECT p.patient_id, 
			   ROUND(SUM(amount),2) outstanding
		FROM patients p
		JOIN billing b
		ON p.patient_id = b.patient_id
		WHERE payment_status = 'failed' and p.patient_id = @id
		GROUP BY p.patient_id
	END 

	EXEC sp_patOutstanding 'p009'


