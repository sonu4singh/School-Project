drop table stu;

CREATE TABLE stu (
    student_id INT PRIMARY KEY,
    name VARCHAR(100),
    Gender VARCHAR(20),
    Year INT,
    Class INT,
    section VARCHAR(10),
    attendance_pct DECIMAL(5,2),
    math INT,
    science INT,
    english INT,
    sss INT,
    com_sc INT,
    average_score DECIMAL(5,2),
    final_grade VARCHAR(5),
    extracurricular VARCHAR(50)
);

load data infile 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/School Project/school_data.csv'
into table stu
fields terminated by ','
enclosed by '"'
lines terminated by '\r\n'
ignore 1 rows;
DESC stu;

select * from stu;

select avg(attendance_pct) as max_score from stu;

alter table stu
add column total_marks int;

update stu
set total_marks = math+science+english+sss+com_sc;


-- 2. Section Performance Comparison
-- For every section, calculate:
-- •	Number of students : 
-- •	Average score 
-- •	Average attendance 
-- •	Highest score 
-- •	Lowest score 

select section, count(student_id) as total_student, avg(average_score)as avgscore, avg(attendance_pct) as avgAt, max(total_marks), min(total_marks)as 
lowest_score from stu
group by section;

/* Gender Performance Analysis
Compare male and female students based on:
•	Student count 
•	Average score 
•	Average attendance 
•	Average math score 
•	Average science score 
•	Average English score 
*/
with cte as (
select gender, count(student_id) as total_Student from stu
group by gender)
select gender, total_student,
(total_student*100)/sum(total_student) over() as Perc
from cte ;
with ctc as (
select gender, avg(average_score) as avg_score,
avg(attendance_pct) as avg_att, avg(math) as avg_math, avg(science) as avgscience, avg(english) as avgEnglish
from stu
group by gender)
select * ,(avg_math+avgscience+avgEnglish) as total_avg_sum from ctc;

select extracurricular, count(student_id) as total_studnet from stu
group by 1
order by total_studnet desc;

SELECT
    extracurricular AS `Extracurricular Status`,
    COUNT(*) AS `Student Count`,
    ROUND(AVG(average_score), 2) AS `Average Score`,
    ROUND(AVG(attendance_pct), 2) AS `Average Attendance`
FROM stu
GROUP BY extracurricular
ORDER BY AVG(average_score) DESC;

SELECT
    extracurricular AS `Extracurricular Status`
FROM stu;
GROUP BY extracurricular
ORDER BY AVG(average_score) DESC;

/*5. Grade Distribution
For each final_grade, find:
Final Grade
Number of Students
Average Score
Average Attendance
Percentage of Students*/

with ctc as (
select final_grade, count(student_id)as total_student, avg(average_score) as avgScore, avg(attendance_pct) as avgatt
from stu
group by 1
order by avgscore desc)
select * , (total_student*100/sum(total_student) over() ) as per_of_student from ctc;

/* 6. Students Above Grade Average
Using a CTE, find students whose average_score is greater than the average score of their own grade_level.
Return:
Student
Grade
Average Score
Grade Average
Difference */

select class, avg(average_score) as avgscore
from stu
group by 1
order by class asc;

WITH grade_avg AS (
    SELECT
        class,
        AVG(average_score) AS grade_average
    FROM stu
    GROUP BY class
)
SELECT
   s.name AS `Student`,
    s.class AS `Grade`,
    s.average_score AS `Average Score`,
    ROUND(g.grade_average, 2) AS `Grade Average`,
    ROUND(s.average_score - g.grade_average, 2) AS `Difference`
FROM stu s
JOIN grade_avg g
    ON s.class = g.class
WHERE s.average_score > g.grade_average
ORDER BY `Difference` DESC;

-- ------------------------------------------------------------

with ctc as (
select class, avg(average_score) as class_avg from stu
group by class)
select a.name as student, a.class, 
a.average_score as averag_score,
b.class_avg,
(a.average_score - b.class_avg) as avgdiff
from stu a
join ctc b on a.class = b.class
where a.average_score < b.class_avg
order by avgdiff desc ;  

/* 7. Grade Performance Ranking
Create a CTE that calculates the average score for each grade and rank grades from highest to lowest.
Return:
Grade
Average Score
Rank */
with ctc as ( select 
class, avg(average_score) as classavg
from stu
group by class)
select 
class, classavg,
rank() over(order by classavg desc) as rn
from ctc;

-- ________________________________________
/* 8. Top Student in Each Grade
Using a CTE and window function, find the highest-performing student from every grade.*/

with ctc as (
select class, name, average_score,
dense_rank() over (partition by class order by average_score desc) as dr
from stu)
select * from ctc 
where dr <=3
order by class asc,average_score desc;


/* 10. Attendance vs Academic Performance
Create a CTE that divides students into:
High Attendance    >= 90%
Medium Attendance  75% - 89.99%
Low Attendance     < 75%
Then calculate the average score for each group. */

with cte as (
select class, name, average_score,attendance_pct,
case
when attendance_pct >= 90 then 'High_att'
when attendance_pct >= 75 and attendance_pct <=89.99 then ' Medium_att'
else 'Low_att' end  as per_status
from stu)
-- select * from cte
-- where per_status like 'medium_att';
select per_status,avg(average_score) as avgscore, count(*) as total_student
from cte
group by per_status
order by avgscore desc ;
select * from stu;

/* Student Rank
Rank every student based on average_score from highest to lowest.
Return:
Student
Average Score
Rank*/

select name, average_score,class,
rank() over( order by average_score desc) as rnk
from stu;

/* 12. Grade-wise Student Rank
Rank students within their own grade.
Return:
Student
Grade
Score
Grade Rank */

select class, name, average_score as score,
rank() over(partition by class order by average_score desc) as rn
from stu;

/* 14. Previous Student Score
Using LAG(), display:
Student
Average Score
Previous Student Score
Score Difference
Order students by score descending.*/

with ctc as (
select name, average_score
from stu
order by average_score desc),
ctc2 as (
select name,average_score,
lag(average_score,1,average_score) over (order by average_score) as previous_score
from ctc)
select *, (average_score-previous_score) as diffavg from ctc2;

WITH student_scores AS (
    SELECT
        name AS Student,
        average_score AS `Average Score`,
        LAG(average_score) OVER (
            ORDER BY average_score DESC
        ) AS `Previous Student Score`
    FROM stu
)
SELECT
    Student,
    `Average Score`,
    `Previous Student Score`,
    ROUND(
        `Average Score` - `Previous Student Score`,
        2
    ) AS `Score Difference`
FROM student_scores
ORDER BY `Average Score` DESC;


with ctc as (
select name, average_score
from stu
order by average_score desc),
ctc2 as (
select name,average_score,
lead(average_score) over (order by average_score desc) as Next_score
from ctc)
select *, (average_score-Next_score) as diffavg from ctc2;

/* 16. Running Average
Calculate the running average of student scores ordered by student_id.*/

select student_id, average_score,
round(avg(average_score) over(order by student_id rows between unbounded preceding and current row ),2) as cumullative_sum
from stu;
use school;

SELECT
    student_id,
    name AS Student,
    average_score AS `Average Score`,
    ROUND(
        AVG(average_score) OVER (
            ORDER BY student_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ),
        2
    ) AS `Running Average`
FROM stu
ORDER BY student_id;

/* Calculate each student's contribution to the total score.
Return:
Student
Score
Total Score
Percentage Contribution */

with cte as (
select name as student,
average_score as score,
sum(average_score) over() as Total_Score
from stu
group by 1,2
order by score desc)
select *, round((score*100/total_Score),2) as pra from cte;

Select Name, average_score
from stu
where average_score >( select avg(average_score)as avgscore from stu)
order by average_score desc;

/* 20. Above Grade Average
Find students whose score is greater than the average score of their grade.
*/
with ctc as (
select class, round(avg(average_score),2) as avgscore
from stu
group by class)

select a.name, a.class, a.average_score,
b.avgscore , (a.average_score -b.avgscore) as avg_diff
from stu a 
join ctc b on a.class = b.class
where a.average_score > b.avgscore
order by a.class asc, a.average_score desc;

select max(average_score) from stu; 



SELECT
    s.name AS Student,
    s.section AS Section,
    s.average_score AS `Score`,
    ROUND((
        SELECT AVG(s2.average_score)
        FROM stu s2
        WHERE s2.section = s.section
    ), 2) AS `Section Average`
FROM stu s
WHERE s.average_score > (
    SELECT AVG(s2.average_score)
    FROM stu s2
    WHERE s2.section = s.section
)
ORDER BY s.section, s.average_score DESC;

 SELECT
    s.name AS Student,
    s.section AS Section,
    s.average_score AS `Score`,
    ROUND((
        SELECT AVG(s2.average_score)
        FROM stu s2
        WHERE s2.section = s.section
    ), 2) AS `Section Average`
FROM stu s
WHERE s.average_score > (
    SELECT AVG(s2.average_score)
    FROM stu s2
    WHERE s2.section = s.section
)
ORDER BY s.section, s.average_score DESC;


select a.name as Student, a.section , a.average_score as Score,
round(( select avg(b.average_score) from stu b where a.section =b.section),2) as section_average
from stu a; 




select a.name,a.section, a.average_score,
round( ( select avg(b.average_score) from stu b where a.section = b.section ),2) as section_average
from stu a
where a.average_score > (round( ( select avg(b.average_score) from stu b where a.section = b.section ),2))
order by a.section asc , a.average_score desc;

/* 26. Student Performance Classification
Create:
Excellent     >= 90
Very Good     80-89
Good          70-79
Average       60-69
Needs Help    < 60
Return:
Student
Score
Performance Category */
with ctc as (
Select name as Student, Average_score as Score,
case
when average_score >=90 then 'Excellent'
when average_score >=80 then 'Very Good'
when average_score >=70 then 'Good'
when average_score >=60 then 'Average'
else 'Need Help  why' end as Performance_category
from stu )
select * from ctc
where student like 'sara patel';

with ctc as (
SELECT
    name AS `Student`,
    average_score AS `Score`,
    CASE
        WHEN average_score >= 90 THEN 'Excellent'
        WHEN average_score >= 80 THEN 'Very Good'
        WHEN average_score >= 70 THEN 'Good'
        WHEN average_score >= 60 THEN 'Average'
        ELSE 'Needs Help'
    END AS `Performance Category`
FROM stu
ORDER BY average_score DESC)
select * from ctc where student like 'Sara Patel';


SELECT
    name AS `Student`,
    average_score AS `Score`,
    CASE
        WHEN average_score >= 90 THEN 'Excellent'
        WHEN average_score >= 80 THEN 'Very Good'
        WHEN average_score >= 70 THEN 'Good'
        WHEN average_score >= 60 THEN 'Average'
        ELSE 'Needs Help'
    END AS `Performance Category`
FROM stu
ORDER BY average_score DESC;

/* 27. Attendance Classification
Create:
Excellent Attendance >= 90
Good Attendance      75-89
Poor Attendance      < 75  */

select name,
case 
when attendance_pct >= 90 then 'Excellent_Attendance'
when attendance_pct >=75 then 'Good_Attendance'
else 'Poor_attendance' end as Attendance_classification
from stu;

/* 28. Academic Risk
Create an academic_risk column:
High Risk
    Score < 50 OR Attendance < 60
Medium Risk
    Score between 50 and 69
Low Risk
    Score >= 70 AND Attendance >= 75 */

with ctc as (
select section,average_score , attendance_pct,
case
	when  average_score <50 or attendance_pct < 60 then 'High Risk'
    when  average_score >=50 or attendance_pct >=60  then 'Medium Risk'
    when  average_score >=70 or attendance_pct >=75  then 'Low Risk'
    end as risk_status
from stu) select * from ctc where average_score > 94;
select risk_status, count(*) as total_risk
from ctc 
group by 1;

SELECT
    section,
    average_score,
    attendance_pct,
    CASE
        WHEN average_score < 50
             OR attendance_pct < 60
            THEN 'High Risk'

        WHEN average_score < 70
             OR attendance_pct < 75
            THEN 'Medium Risk'

        ELSE 'Low Risk'
    END AS risk_status
FROM stu
where average_score >94;


/*30. Best Performing Grade
Find the grade with the highest average score.
*/

select class, avg(average_score) as best_average
from stu
group by class
order by best_average desc
limit 1;

with ctc as (
select math as marks, 'math' as subject from stu
union all
select english as marks, 'English' as subject from stu
union all
select science as marks, 'science' as subject from stu
union all
select sss as marks, 'SSS' as subject from stu
),
avg_m as (
select subject, avg(marks) as avgscore from ctc
group by subject)

select a.subject, a.marks, round((b.avgscore),2) as avg_s, a.marks-b.avgscore as diffavg
from ctc a 
join avg_m b on a.subject=b.subject
where a.marks > b.avgscore
order by diffavg desc;


/*Compare average scores between:
Students with attendance >= 75%
Students with attendance < 75%
Calculate the score difference.
*/


with ctc as (
select name as student,average_score, 
attendance_pct, 
case
when attendance_pct >= 75 then 'above_75' 
else 'below_75' end as status
from stu)
-- select * from ctc;
select status, avg(average_score) as avg_s, count(*) as total_s
from ctc
group by status
order by avg_s desc
;

SELECT
    CASE
        WHEN attendance_pct >= 75 THEN 'Attendance >= 75%'
        ELSE 'Attendance < 75%'
    END AS `Attendance Group`,
    COUNT(*) AS `Student Count`,
    ROUND(AVG(average_score), 2) AS `Average Score`
FROM stu
GROUP BY
    CASE
        WHEN attendance_pct >= 75 THEN 'Attendance >= 75%'
        ELSE 'Attendance < 75%'
    END;
    
    
/*Extracurricular Impact
Determine whether extracurricular participation is associated with higher average scores.
Return:
Participation
Students
Average Score
Difference from Overall Average
*/

select extracurricular, round(avg(average_score),2) as avgscore from stu group by 1
order by avgscore desc limit 1;    

SELECT
    extracurricular AS `Participation`,
    COUNT(*) AS `Students`,
    ROUND(AVG(average_score), 2) AS `Average Score`,
    ROUND(
        AVG(average_score) -
        (SELECT AVG(average_score) FROM stu),
        2
    ) AS `Difference from Overall Average`
FROM stu
GROUP BY extracurricular
ORDER BY `Average Score` DESC;

select extracurricular, 
avg(average_score) as avgscore, 
(avg(average_score) - (select avg(average_score)  from stu))  as diffoveall
from stu 
group by 1 
order by avgscore desc ;


with ctc as (
select name as student,class,average_score,
dense_rank() over(partition by class order by average_score desc) as dr
from stu)
select * from ctc where dr <=3;

/*Create a report:
Student
Grade
Student Score
Grade Average
Difference from Grade Average
Rank
*/
select name as student, class, average_score
from stu
group by 1,2,3
order by class asc ;

WITH grade_report AS (
    SELECT
        name AS Student,
        class AS Grade,
        average_score AS `Student Score`,

        AVG(average_score) OVER (
            PARTITION BY class
        ) AS `Grade Average`,

        RANK() OVER (
            PARTITION BY class
            ORDER BY average_score DESC
        ) AS `Rank`

    FROM stu
) -- select * from grade_report;
SELECT
    Student,
    grade,
    `Student Score`,
    ROUND(`Grade Average`, 2) AS `Grade Average`,
    ROUND(
        `Student Score` - `Grade Average`,
        2
    ) AS `Difference from Grade Average`,
    `Rank`
FROM grade_report
ORDER BY Grade, `Rank`;

with ctc as (
select name as student, class, average_score as student_score,
avg(average_score) over (partition by class) as class_avg,
rank() over(partition by class order by average_score desc) as rn
from stu)
select *, round( student_score - Class_avg,2) as diff
from ctc;


select name as student, class, average_score as marks
from stu
where average_Score > all (select avg(average_score) from stu group by class)
order by class asc;

select all(select avg(average_score) from stu group by class)
from stu;

SELECT AVG(average_score)
FROM stu
GROUP BY class
order by avg(average_score) desc;

/* Students Below Their Section Average
Find students whose score is below their section's average.
Return:
Student
Section
Score
Section Average
Difference */

select name as student,
class, average_score -- , (select avg(average_score) from stu group by class) as claas_avg
from stu
where average_score < all ( select avg(average_score) from stu group by class);


with ctc as (
select name, class,math as score,'math' as subject from stu
union all
select name, class,english as score,'english' as subject from stu 
union all
select name, class,science as score,'science' as subject from stu
union all
select name, class,sss as score,'sss' as subject from stu
union all
select name, class,com_sc as score,'com_sc' as subject from stu)
select *
from ctc 
where score> all (select avg(score) from ctc group by subject)
order by name asc;

with ctc as (
select name as student, class,math,english,science,sss,com_sc,
average_score as score,
avg(math) over() as math_avg,
avg(english) over() as english_avg,
avg(science) over() as science_avg,
avg(sss) over() as sss_avg,
avg(com_sc) over() as com_sc_avg
from stu
where math > (select avg(math) from stu)
and 
english > (select avg(english) from stu)
and 
science > (select avg(science) from stu)
and 
sss > (select avg(sss) from stu)
and 
com_sc > (select avg(com_sc) from stu)
order by class asc , score desc)
select * from ctc ;


select name as student, class, math,english,science,sss,com_sc, 'above 75%_student' as status
from stu 
where math>75 and english>75 and  science>75 and sss>75 and com_sc >75
order by class, average_score desc;

SELECT LEAST(math, science, english, sss, com_sc) FROM stu;


SELECT
    name AS Student,
    CASE
        WHEN math = LEAST(math, science, english, sss, com_sc)
            THEN 'Math'
        WHEN science = LEAST(math, science, english, sss, com_sc)
            THEN 'Science'
        WHEN english = LEAST(math, science, english, sss, com_sc)
            THEN 'English'
        WHEN sss = LEAST(math, science, english, sss, com_sc)
            THEN 'Social Studies'
        ELSE 'com_sc'
    END AS `Weakest Subject`,

    LEAST(math, science, english, sss, com_sc) AS Score

FROM stu;
select * from stu;

select name as student, class, -- section, math,science, english,sss,com_sc,
case 
when math = least(math,science, english,sss,com_sc) then 'Math'
when science = least(math,science, english,sss,com_sc) then 'science'
when english = least(math,science, english,sss,com_sc) then 'english'
when sss = least(math,science, english,sss,com_sc) then 'sss'
else 'com_sc' end as weak_subject,
least(math,science, english,sss,com_sc) as lowest_score
from stu
order by class asc, lowest_score desc;

with ctc as (
select name as student, class,math as score, 'math' as subject from stu
union all
select name as student, class,science as score, 'science' as subject from stu
union all
select name as student, class,english as score, 'english' as subject from stu
union all
select name as student, class,sss as score, 'sss' as subject from stu
union all
select name as student, class,com_sc as score, 'com_sc' as subject from stu
),
ctc2 as (
select *, 
rank() over (partition by student order by score desc ) as rn
from ctc
)
select * from ctc2
where rn =1
order by class asc, score desc; 



select name as student, class, -- section, math,science, english,sss,com_sc,
case 
when math = greatest(math,science, english,sss,com_sc) then 'Math'
when science = greatest(math,science, english,sss,com_sc) then 'science'
when english = greatest(math,science, english,sss,com_sc) then 'english'
when sss = greatest(math,science, english,sss,com_sc) then 'sss'
else 'com_sc' end as weak_subject,
greatest(math,science, english,sss,com_sc) as great_score
from stu
order by class asc, great_score desc;

/*
 For every student, calculate:
Highest Subject Score
Lowest Subject Score
Score Gap
*/


WITH unpivoted AS (
    SELECT student_id, name, 'Math' AS subject, math AS score FROM stu
    UNION ALL SELECT student_id, name, 'Science', science as score FROM stu
    UNION ALL SELECT student_id, name, 'English', english as score FROM stu
    UNION ALL SELECT student_id, name, 'sss', sss as score FROM stu
    UNION ALL SELECT student_id, name, 'Com_sc', com_sc as score FROM stu
),
ranked AS 
( SELECT *, RANK() OVER (PARTITION BY subject ORDER BY score DESC) AS rnk
    FROM unpivoted
)
SELECT subject, name AS student, score, rnk
FROM ranked
WHERE rnk <= 5
ORDER BY subject, rnk;


select Name as student,
case 
when math = least(math,science,english,sss,com_sc) then 'Math'
when english = least(math,science,english,sss,com_sc) then 'english'
when science = least(math,science,english,sss,com_sc) then 'science'
when sss = least(math,science,english,sss,com_sc) then 'sss'
when com_sc = least(math,science,english,sss,com_sc) then 'com_sc'
end as weaked_subject, least(math,science,english,sss,com_sc) as lowest_score
from stu
order by class asc, lowest_score asc;

with ctc as (
select name,
least(math,science,english,sss,com_sc) as lowest_score, 
greatest(math,science,english,sss,com_sc) as high_score
from stu),
ctc2 as (
select *, high_score-lowest_score as diff
from ctc 
order by diff desc )
select * from ctc2
where diff>=10
order by diff desc;

/* Create a single report containing:
Student Name ,Grade ,Section,Gender,Average Score,Attendance,Final Grade,Grade Average,Section Average
Student Rank,Grade Rank,Performance Category,Attendance Category,Academic Risk */

WITH report AS (
    SELECT
        name AS `Student Name`,
        Class AS Grade,
        section AS Section,
        gender AS Gender,
        average_score AS `Average Score`,
        attendance_pct AS Attendance,

        -- Grade Average
        AVG(average_score) OVER (
            PARTITION BY class
        ) AS `Grade Average`,

        -- Section Average
        AVG(average_score) OVER (
            PARTITION BY section
        ) AS `Section Average`,

        -- Overall Student Rank
        RANK() OVER (
            ORDER BY average_score DESC
        ) AS `Student Rank`,

        -- Rank within Grade
        RANK() OVER (
            PARTITION BY Class
            ORDER BY average_score DESC
        ) AS `Grade Rank`

    FROM stu
)

SELECT
    `Student Name`,
    Grade,
    Section,
    Gender,
    ROUND(`Average Score`, 2) AS `Average Score`,
    ROUND(Attendance, 2) AS Attendance,

    -- Final Grade
    CASE
        WHEN `Average Score` >= 90 THEN 'A+'
        WHEN `Average Score` >= 80 THEN 'A'
        WHEN `Average Score` >= 70 THEN 'B'
        WHEN `Average Score` >= 60 THEN 'C'
        WHEN `Average Score` >= 50 THEN 'D'
        ELSE 'F'
    END AS `Final Grade`,

    ROUND(`Grade Average`, 2) AS `Grade Average`,
    ROUND(`Section Average`, 2) AS `Section Average`,

    `Student Rank`,
    `Grade Rank`,

    -- Performance Category
    CASE
        WHEN `Average Score` >= 90 THEN 'Excellent'
        WHEN `Average Score` >= 80 THEN 'Very Good'
        WHEN `Average Score` >= 70 THEN 'Good'
        WHEN `Average Score` >= 60 THEN 'Average'
        ELSE 'Needs Help'
    END AS `Performance Category`,

    -- Attendance Category
    CASE
        WHEN Attendance >= 75 THEN 'Good Attendance'
        WHEN Attendance >= 60 THEN 'Average Attendance'
        ELSE 'Low Attendance'
    END AS `Attendance Category`,

    -- Academic Risk
    CASE
        WHEN `Average Score` < 50
             OR Attendance < 60
            THEN 'High Risk'

        WHEN `Average Score` < 70
             OR Attendance < 75
            THEN 'Medium Risk'

        ELSE 'Low Risk'
    END AS `Academic Risk`

FROM report
ORDER BY Grade, `Grade Rank`;

with ctc as (
select name as `Student Name`, Class as Grade,Section, gender as Gender, Average_score, concat(round((attendance_pct),0),'%') as Attendance,
round(avg(average_score) over(partition by class ),2) as Class_Average,
round(avg(average_score) over(partition by section ),2) as Section_Average,
rank() over(order by average_score desc)as Over_School_rank,
rank() over( partition by class order by average_score desc ) as class_Rank
from stu)
select *,
/* (select 
case 
when math = least(math,science,english,sss,com_sc) then 'Math'
when english = least(math,science,english,sss,com_sc) then 'english'
when science = least(math,science,english,sss,com_sc) then 'science'
when sss = least(math,science,english,sss,com_sc) then 'sss'
when com_sc = least(math,science,english,sss,com_sc) then 'com_sc'
end from stu) as Lowest_Subject, least(math,science,english,sss,com_sc),
*/

case 
when average_score >= 90 then 'A+'
when average_score >= 80 then 'A'
when average_score >= 70 then 'B+'
when average_score >= 60 then 'B'
when average_score >= 55 then 'C'
else 'F' end as Final_Grade,
-- attendance_Category
case 
when Attendance >= 75 then 'Good Attendance'
when Attendance >= 60 then 'Average_Attendance'
when Attendance <60  then 'Low_Attendance'
end as Attendance_Status,
-- overall performance 
case 
when average_score >= 90 then 'Excellent'
when average_score >= 80 then 'Very Good'
when average_score >= 70 then 'Good'
when average_score <70 then 'Need Exctra Class'
end as Performance_Status,

-- Risk catagory
case 
when average_score >=85 or attendance >=85  then 'Low Riks'
when average_score >=60 or attendance >=60  then 'Mediam Riks'
when average_score <60 or attendance <60  then 'low Riks'
else 'Suspence' end as Risk_Status
from ctc
order by grade asc, average_score desc; 


/* Create a leaderboard showing:
Grade,Student,Score,Grade Rank,Grade Average
Difference from Grade Average*/

with cte as (
Select class as Grade, Name as Student, Average_score as Score,
dense_rank() over (order by average_score desc) as `School Rank`,
dense_rank() over (partition by Class order by average_score desc) as `Grade Rank`,
round(avg(average_score) over ( partition by Class ),2) as `Grade Average`
from stu)
select * , round((score -`Grade Average`),2) as Diff

from cte 
order by `school rank` asc;


WITH attendance_groups AS (
    SELECT
        CASE
            WHEN attendance_pct >= 75 THEN 'High Attendance'
            WHEN attendance_pct >= 60 THEN 'Medium Attendance'
            ELSE 'Low Attendance'
        END AS attendance_group,
        attendance_pct,
        average_score
    FROM stu
),
group_performance AS (
    SELECT
        attendance_group AS `Attendance Group`,
        COUNT(*) AS Students,
        ROUND(AVG(attendance_pct), 2) AS `Average Attendance`,
        ROUND(AVG(average_score), 2) AS `Average Score`,
        MAX(average_score) AS `Highest Score`,
        MIN(average_score) AS `Lowest Score`
    FROM attendance_groups
    GROUP BY attendance_group
)
SELECT
    `Attendance Group`,
    Students,
    `Average Attendance`,
    `Average Score`,
    `Highest Score`,
    `Lowest Score`,
    CASE
        WHEN `Average Score` = MAX(`Average Score`) OVER ()
        THEN 'Best Performing Group'
        ELSE ''
    END AS `Performance`
FROM group_performance
ORDER BY `Average Score` DESC;


with cte as (
select gender, avg(average_score)as c
from stu
 group by 1 order by c desc
) select *, concat(round((c*100/sum(c) over()),2),'%') as pct 
from cte;

/* For each subject, find the top 5 students.
Output:,Subject,Student,Score,Rank */

with cte as (
select 'Math' as Subject,name as Student,math as subject_score, average_score as score from stu
Union all
select 'science' as Subject,name as Student,science as subject_score, average_score as score from stu
Union all
select 'english' as Subject,name as Student,english as subject_score, average_score as score from stu
Union all
select 'SSS' as Subject,name as Student,sss as subject_score, average_score as score from stu
Union all
select 'com_sc' as Subject,name as Student,com_sc as subject_score, average_score as score from stu
),
cte2 as (
select *,
rank() over( partition by subject order by subject_score asc) as rn
from cte)
select * from cte2 where rn <= 5
;

WITH subject_avg AS (
    SELECT 'Math' AS subject, AVG(math) AS avg_score
    FROM stu

    UNION ALL

    SELECT 'Science', AVG(science)
    FROM stu

    UNION ALL

    SELECT 'English', AVG(english)
    FROM stu

    UNION ALL

    SELECT 'Social Studies', AVG(sss)
    FROM stu

    UNION ALL

    SELECT 'Computer Science', AVG(com_sc)
    FROM stu
)-- select * from subject_avg; 
,

grade_avg AS (
    SELECT
        Class,
        AVG(average_score) AS avg_score
    FROM stu
    GROUP BY Class
) -- select * from grade_avg;
,

section_avg AS (
    SELECT
        section,
        AVG(average_score) AS avg_score
    FROM stu
    GROUP BY section
) -- select * from section_avg;

SELECT
    COUNT(*) AS `Total Students`,

    ROUND(AVG(average_score), 2) AS `Average Score`,

    ROUND(AVG(attendance_pct), 2) AS `Average Attendance`,

    MAX(average_score) AS `Highest Score`,

    MIN(average_score) AS `Lowest Score`,

    (
        SELECT name
        FROM stu
        WHERE average_score = (
            SELECT MAX(average_score)
            FROM stu
        )
        LIMIT 1
    ) AS `Top Student`,

    (
        SELECT  Class
        FROM grade_avg
        ORDER BY avg_score DESC
        LIMIT 1
    ) AS `Best Grade`,

    (
        SELECT section
        FROM section_avg
        ORDER BY avg_score DESC
        LIMIT 1
    ) AS `Best Section`,

    (
        SELECT subject
        FROM subject_avg
        ORDER BY avg_score DESC
        LIMIT 1
    ) AS `Best Subject`,

    SUM(
        CASE
            WHEN average_score < 50
                 OR attendance_pct < 60
            THEN 1
            ELSE 0
        END
    ) AS `Students At Risk`,

    SUM(
        CASE
            WHEN average_score > 80
            THEN 1
            ELSE 0
        END
    ) AS `Students Above 80`,

    SUM(
        CASE
            WHEN average_score < 50
            THEN 1
            ELSE 0
        END
    ) AS `Students Below 50`

FROM stu;

with Subject_avg as (
select 'math' as subject, round(avg(math),2) as sub_avg from stu
union all
select 'English' as subject, round(avg(English),2) as sub_avg from stu
union all
select 'Science' as subject, round(avg(Science),2) as sub_avg from stu
union all
select 'sss' as subject, round(avg(sss),2) as sub_avg from stu
union all
select 'com_sc' as subject, round(avg(com_sc),2) as sub_avg from stu
),
section_avg as 
(select section, avg(average_score) as sec_avg 
from stu group by section
), 
class_avg as 
(select class, avg(average_score) as class_avg 
from stu group by class
)
-- select * from class_avg;
select (select count(*) as `Total Student` from stu) as `Total Student`,
 round((select avg(average_score) from stu),2) as `Average score`,
 round((select avg(attendance_pct ) from stu),2) as `Average Attedance`,
 (select max(average_score) from stu) as `Max score`,
 (select min(average_score) from stu) as `Min score`,
 (select name from stu where average_score= (select max(average_score) from stu))as`Top Student`,
 (select class from class_avg order by class_avg desc limit 1) as `Best Class`,
 (select Section from Section_avg order by sec_avg desc limit 1) as `Best Section`,
 (select subject from Subject_avg order by sub_avg desc limit 1) as `Best Subject`,
 sum( case when average_score <50 or attendance_pct < 60 then 1 else 0 end)  as `Riks Student`,
 sum( case when average_score >80 then 1 else 0 end)  as `Student above 80%`,
 sum( case when average_score <50 then 1 else 0 end)  as `Student below 50%` from stu;