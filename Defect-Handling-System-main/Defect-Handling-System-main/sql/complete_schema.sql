-- Complete Database Schema for Steel Plant Detection System
-- ===================================================

-- Drop existing tables (in reverse order of dependencies)
-- WARNING: This will delete all existing data!
DROP TABLE user_specializations CASCADE CONSTRAINTS;
DROP TABLE complaints CASCADE CONSTRAINTS;
DROP TABLE users CASCADE CONSTRAINTS;
DROP TABLE technician_specializations CASCADE CONSTRAINTS;

-- Drop sequences
DROP SEQUENCE users_seq;
DROP SEQUENCE complaints_seq;
DROP SEQUENCE technician_specializations_seq;

-- Sequences for Primary Keys
-- ==========================
CREATE SEQUENCE users_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE complaints_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE technician_specializations_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

-- Users Table
-- ===========
CREATE TABLE users (
    user_id NUMBER DEFAULT users_seq.NEXTVAL NOT NULL,
    username VARCHAR2(50) NOT NULL,
    password VARCHAR2(72) NOT NULL, -- Increased to 72 for BCrypt hashes
    email VARCHAR2(100) NOT NULL,
    user_type VARCHAR2(20) NOT NULL CHECK (user_type IN ('ADMIN', 'TECHNICIAN', 'EMPLOYEE')),
    first_name VARCHAR2(50),
    last_name VARCHAR2(50),
    phone VARCHAR2(15),
    address VARCHAR2(200),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    CONSTRAINT users_pk PRIMARY KEY (user_id),
    CONSTRAINT users_username_uk UNIQUE (username),
    CONSTRAINT users_email_uk UNIQUE (email)
);

-- Complaints Table
-- ===============
CREATE TABLE complaints (
    complaint_id NUMBER DEFAULT complaints_seq.NEXTVAL NOT NULL,
    user_id NUMBER NOT NULL,
    title VARCHAR2(100) NOT NULL,
    description CLOB,
    location VARCHAR2(200),
    image_path VARCHAR2(200),
    status VARCHAR2(20) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'ASSIGNED', 'IN_PROGRESS', 'COMPLETED', 'CLOSED')),
    assigned_to NUMBER,
    completion_notes CLOB,
    completion_image_path VARCHAR2(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    CONSTRAINT complaints_pk PRIMARY KEY (complaint_id),
    CONSTRAINT complaints_user_fk FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT complaints_assigned_fk FOREIGN KEY (assigned_to) REFERENCES users(user_id) ON DELETE SET NULL
);

-- Technician Specializations Table
-- ===============================
CREATE TABLE technician_specializations (
    specialization_id NUMBER DEFAULT technician_specializations_seq.NEXTVAL NOT NULL,
    name VARCHAR2(50) NOT NULL,
    CONSTRAINT tech_spec_pk PRIMARY KEY (specialization_id),
    CONSTRAINT tech_spec_name_uk UNIQUE (name)
);

-- User Specializations (Link Table for Technicians and Specializations)
-- ==================================================================
CREATE TABLE user_specializations (
    user_id NUMBER NOT NULL,
    specialization_id NUMBER NOT NULL,
    CONSTRAINT user_spec_pk PRIMARY KEY (user_id, specialization_id),
    CONSTRAINT user_spec_user_fk FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT user_spec_spec_fk FOREIGN KEY (specialization_id) REFERENCES technician_specializations(specialization_id) ON DELETE CASCADE
);

-- Default Data
-- ============

-- Default Specializations
INSERT INTO technician_specializations (name) VALUES ('Plumber');
INSERT INTO technician_specializations (name) VALUES ('Electrician');
INSERT INTO technician_specializations (name) VALUES ('Mechanic');
INSERT INTO technician_specializations (name) VALUES ('Welder');

-- Insert admin user with BCrypt hashed password (default password: admin123)
INSERT INTO users (username, password, email, user_type, first_name, last_name, phone, address) 
VALUES ('admin', '$2a$10$8K1p/aCGQDautLIZLL3pW.2XGm5xKTB/uBmYx3tZJQcQw5xNo/YiC', 'admin@example.com', 'ADMIN', 'Admin', 'User', '1234567890', 'Dummy Address');

-- Commit all changes
COMMIT;

-- Display success message
PROMPT Database schema created and populated successfully!
