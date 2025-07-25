-- Step 1: Create a new database
CREATE DATABASE StudentResults;

-- Step 2: Use the database
USE StudentResults;

-- Step 3: Now create your tables
CREATE TABLE Students (
    student_id INT PRIMARY KEY,
    name VARCHAR(100),
    department VARCHAR(50)
);

CREATE TABLE Courses (
    course_id INT PRIMARY KEY,
    course_name VARCHAR(100),
    credits INT
);

CREATE TABLE Semesters (
    semester_id INT PRIMARY KEY,
    semester_name VARCHAR(50)
);

CREATE TABLE Grades (
    grade_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT,
    course_id INT,
    semester_id INT,
    marks INT,
    grade CHAR(2),
    gpa FLOAT,
    FOREIGN KEY (student_id) REFERENCES Students(student_id),
    FOREIGN KEY (course_id) REFERENCES Courses(course_id),
    FOREIGN KEY (semester_id) REFERENCES Semesters(semester_id)
);

-- STUDENTS
INSERT INTO Students VALUES (1, 'Alice', 'CSE'), (2, 'Bob', 'ECE');

-- COURSES
INSERT INTO Courses VALUES (101, 'DBMS', 4), (102, 'OS', 3);

-- SEMESTERS
INSERT INTO Semesters VALUES (1, 'Sem 1'), (2, 'Sem 2');

-- GRADES
INSERT INTO Grades (student_id, course_id, semester_id, marks)
VALUES 
(1, 101, 1, 85),
(1, 102, 1, 78),
(2, 101, 1, 60),
(2, 102, 1, 45);



-- GPA and Grade Calculation using CASE
-- Disable safe update mode
SET SQL_SAFE_UPDATES = 0;

-- Now run your update
UPDATE Grades
SET 
    grade = CASE 
        WHEN marks >= 90 THEN 'A+'
        WHEN marks >= 80 THEN 'A'
        WHEN marks >= 70 THEN 'B'
        WHEN marks >= 60 THEN 'C'
        WHEN marks >= 50 THEN 'D'
        ELSE 'F'
    END,
    gpa = CASE 
        WHEN marks >= 90 THEN 10
        WHEN marks >= 80 THEN 9
        WHEN marks >= 70 THEN 8
        WHEN marks >= 60 THEN 7
        WHEN marks >= 50 THEN 6
        ELSE 0
    END;

-- (Optional) Re-enable safe update after that
SET SQL_SAFE_UPDATES = 1;



SELECT 
    student_id,
    COUNT(*) AS total_courses,
    SUM(CASE WHEN gpa > 0 THEN 1 ELSE 0 END) AS passed,
    SUM(CASE WHEN gpa = 0 THEN 1 ELSE 0 END) AS failed
FROM Grades
GROUP BY student_id;


-- Rank students by total GPA in a semester
SELECT 
    g1.student_id,
    g1.semester_id,
    g1.semester_gpa,
    (
        SELECT COUNT(*) + 1
        FROM (
            SELECT student_id, semester_id, 
                   SUM(gpa * c.credits) / SUM(c.credits) AS semester_gpa
            FROM Grades g
            JOIN Courses c ON g.course_id = c.course_id
            GROUP BY student_id, semester_id
        ) AS g2
        WHERE g2.semester_id = g1.semester_id
          AND g2.semester_gpa > g1.semester_gpa
    ) AS `rank`
FROM (
    SELECT 
        student_id,
        semester_id,
        SUM(gpa * c.credits) / SUM(c.credits) AS semester_gpa
    FROM Grades g
    JOIN Courses c ON g.course_id = c.course_id
    GROUP BY student_id, semester_id
) AS g1;


DELIMITER //

CREATE TRIGGER calc_gpa
BEFORE INSERT ON Grades
FOR EACH ROW
BEGIN
    DECLARE grade_char CHAR(2);
    DECLARE grade_point FLOAT;

    IF NEW.marks >= 90 THEN
        SET grade_char = 'A+', grade_point = 10;
    ELSEIF NEW.marks >= 80 THEN
        SET grade_char = 'A', grade_point = 9;
    ELSEIF NEW.marks >= 70 THEN
        SET grade_char = 'B', grade_point = 8;
    ELSEIF NEW.marks >= 60 THEN
        SET grade_char = 'C', grade_point = 7;
    ELSEIF NEW.marks >= 50 THEN
        SET grade_char = 'D', grade_point = 6;
    ELSE
        SET grade_char = 'F', grade_point = 0;
    END IF;

    SET NEW.grade = grade_char;
    SET NEW.gpa = grade_point;
END;
//

DELIMITER ;


SELECT 
    s.student_id,
    s.name,
    sem.semester_name,
    ROUND(SUM(gpa * c.credits) / SUM(c.credits), 2) AS semester_gpa
FROM Grades g
JOIN Students s ON g.student_id = s.student_id
JOIN Courses c ON g.course_id = c.course_id
JOIN Semesters sem ON g.semester_id = sem.semester_id
GROUP BY s.student_id, sem.semester_id;
