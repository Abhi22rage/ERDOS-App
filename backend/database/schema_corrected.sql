-- =============================================================================
-- Hybrid Database Schema for PHED/PWSS Infrastructure Management System
-- Dialect: MySQL 8.0+
-- Charset: utf8mb4 / utf8mb4_unicode_ci (FIX: added globally)
-- Corrected: forward references, missing indexes, missing updated_at,
--            explicit FK behaviors, soft-delete, session idle tracking,
--            contractor category/status ENUMs, schemes polymorphic FK,
--            repair_history.contractor_id FK, seed password comment.
-- =============================================================================
CREATE DATABASE IF NOT EXISTS phed_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE phed_db;
-- CHARACTER SET utf8mb4 -- defines what characters can be stored
-- COLLATE utf8mb4_unicode_ci -- defines how characters are compared/sorted (case-insensitive, accent-sensitive)
-- =============================================================================
-- 1. REFERENCE & RBAC TABLES
-- =============================================================================
-- User Roles
CREATE TABLE IF NOT EXISTS roles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    -- e.g.: 'field_staff', 'admin', 'ee', 'finance'
    display_name VARCHAR(100) NOT NULL,
    -- e.g.: 'Executive Engineer'
    description TEXT,
    hierarchy_level INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
-- Granular Permissions
CREATE TABLE IF NOT EXISTS permissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    permission_code VARCHAR(100) UNIQUE NOT NULL,
    -- e.g., 'approve_breakdown', 'view_reports'
    module VARCHAR(50) NOT NULL,
    -- e.g., 'breakdowns', 'users'
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
-- Role-Permission Mapping (M:N junction)
CREATE TABLE IF NOT EXISTS role_permissions (
    role_id INT NOT NULL,
    permission_id INT NOT NULL,
    granted BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (role_id, permission_id),
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
-- =============================================================================
-- 2. CORE ENTITY TABLES
-- =============================================================================
-- Users Table
CREATE TABLE IF NOT EXISTS users (
    id CHAR(36) PRIMARY KEY,
    -- UUID
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(15) UNIQUE NOT NULL,
    designation VARCHAR(100),
    department VARCHAR(100),
    role_id INT NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    is_verified BOOLEAN DEFAULT FALSE,
    CONSTRAINT chk_user_status CHECK (
        status IN ('active', 'suspended', 'deactivated', 'pending')
    ),
    password VARCHAR(255) NOT NULL,
    -- bcrypt hash; never store plain text
    fcm_token VARCHAR(255),
    -- Firebase push token; invalidate on logout
    photo_url VARCHAR(255),
    pincode_id INT,
    address_line TEXT,
    last_login TIMESTAMP NULL,
    deleted_at TIMESTAMP NULL,
    -- FIX: soft-delete; NULL = not deleted
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    -- FIX: explicit ON DELETE behavior on role_id
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE RESTRICT,
    FOREIGN KEY (pincode_id) REFERENCES pincodes(id) ON DELETE
    SET NULL
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
-- Indexes for users
CREATE INDEX idx_users_role ON users(role_id);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_pincode ON users(pincode_id);
CREATE INDEX idx_users_deleted_at ON users(deleted_at);
-- fast soft-delete filter
-- User Sessions — stateful session management with instant revocation
CREATE TABLE IF NOT EXISTS user_sessions (
    id CHAR(36) PRIMARY KEY,
    user_id CHAR(36) NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    expires_at TIMESTAMP NOT NULL,
    last_activity_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    -- FIX: idle timeout support
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
-- FIX: composite index — most critical query path in auth middleware
CREATE INDEX idx_sessions_user_active ON user_sessions(user_id, is_active);
CREATE INDEX idx_sessions_expires ON user_sessions(expires_at);
-- =============================================================================
-- 3. GEOGRAPHIC REFERENCE DATA
-- =============================================================================
CREATE TABLE IF NOT EXISTS states (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(5) UNIQUE NOT NULL,
    -- e.g., 'AS' for Assam
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS districts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    state_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (state_id) REFERENCES states(id) ON DELETE RESTRICT,
    UNIQUE (state_id, name)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE INDEX idx_districts_state ON districts(state_id);
CREATE TABLE IF NOT EXISTS cities (
    id INT AUTO_INCREMENT PRIMARY KEY,
    district_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (district_id) REFERENCES districts(id) ON DELETE RESTRICT,
    UNIQUE (district_id, name)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE INDEX idx_cities_district ON cities(district_id);
CREATE TABLE IF NOT EXISTS pincodes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(6) NOT NULL,
    city_id INT NOT NULL,
    area_name VARCHAR(150),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (city_id) REFERENCES cities(id) ON DELETE RESTRICT,
    UNIQUE (code, city_id)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE INDEX idx_pincodes_city ON pincodes(city_id);
CREATE INDEX idx_pincodes_code ON pincodes(code);
-- =============================================================================
-- 4. INFRASTRUCTURE HIERARCHY
-- Division -> Water Intake Plant (Barge) -> Production Centre -> WTP -> Boosting Station
-- =============================================================================
-- 1. Divisions
CREATE TABLE IF NOT EXISTS divisions (
    id CHAR(36) PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    district_id INT,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (district_id) REFERENCES districts(id) ON DELETE RESTRICT
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE INDEX idx_divisions_district ON divisions(district_id);
-- 2. Water Intake Plants (Barge)
CREATE TABLE IF NOT EXISTS water_intake_plants (
    id CHAR(36) PRIMARY KEY,
    division_id CHAR(36) NOT NULL,
    name VARCHAR(150) NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    pincode_id INT,
    address_line TEXT,
    capacity_mld FLOAT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (division_id) REFERENCES divisions(id) ON DELETE RESTRICT,
    FOREIGN KEY (pincode_id) REFERENCES pincodes(id) ON DELETE
    SET NULL
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE INDEX idx_wip_division ON water_intake_plants(division_id);
CREATE INDEX idx_wip_pincode ON water_intake_plants(pincode_id);
-- 3. Production Centres (WSS / Plants)
CREATE TABLE IF NOT EXISTS production_centres (
    id CHAR(36) PRIMARY KEY,
    intake_plant_id CHAR(36) NOT NULL,
    name VARCHAR(150) NOT NULL,
    capacity_mld FLOAT,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    pincode_id INT,
    address_line TEXT,
    type VARCHAR(50),
    -- WSS / Plant
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (intake_plant_id) REFERENCES water_intake_plants(id) ON DELETE RESTRICT,
    FOREIGN KEY (pincode_id) REFERENCES pincodes(id) ON DELETE
    SET NULL
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE INDEX idx_pc_intake_plant ON production_centres(intake_plant_id);
CREATE INDEX idx_pc_pincode ON production_centres(pincode_id);
-- 4. Water Treatment Plants (WTP)
CREATE TABLE IF NOT EXISTS water_treatment_plants (
    id CHAR(36) PRIMARY KEY,
    centre_id CHAR(36) NOT NULL,
    name VARCHAR(150) NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    pincode_id INT,
    address_line TEXT,
    capacity_mld FLOAT,
    gis_map_data JSON,
    -- GeoJSON of the internal pipe network
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (centre_id) REFERENCES production_centres(id) ON DELETE RESTRICT,
    FOREIGN KEY (pincode_id) REFERENCES pincodes(id) ON DELETE
    SET NULL
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE INDEX idx_wtp_centre ON water_treatment_plants(centre_id);
CREATE INDEX idx_wtp_pincode ON water_treatment_plants(pincode_id);
-- 5. Boosting Stations
CREATE TABLE IF NOT EXISTS boosting_stations (
    id CHAR(36) PRIMARY KEY,
    wtp_id CHAR(36) NOT NULL,
    name VARCHAR(150) NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    pincode_id INT,
    address_line TEXT,
    gis_map_data JSON,
    -- GeoJSON of the internal pipe network
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (wtp_id) REFERENCES water_treatment_plants(id) ON DELETE RESTRICT,
    FOREIGN KEY (pincode_id) REFERENCES pincodes(id) ON DELETE
    SET NULL
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE INDEX idx_bs_wtp ON boosting_stations(wtp_id);
CREATE INDEX idx_bs_pincode ON boosting_stations(pincode_id);
-- 6. Components (linked to Barge, WTP, or Boosting Station)
CREATE TABLE IF NOT EXISTS components (
    id CHAR(36) PRIMARY KEY,
    intake_plant_id CHAR(36),
    wtp_id CHAR(36),
    station_id CHAR(36),
    category VARCHAR(100),
    -- Electrical, Mechanical, Civil, etc.
    component_type VARCHAR(100),
    component_name VARCHAR(150) NOT NULL,
    specification VARCHAR(100),
    -- e.g., '100 HP'
    quantity INT DEFAULT 1,
    purpose TEXT,
    deleted_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (intake_plant_id) REFERENCES water_intake_plants(id) ON DELETE RESTRICT,
    FOREIGN KEY (wtp_id) REFERENCES water_treatment_plants(id) ON DELETE RESTRICT,
    FOREIGN KEY (station_id) REFERENCES boosting_stations(id) ON DELETE RESTRICT,
    -- At least one parent facility must be linked
    CONSTRAINT chk_component_link CHECK (
        intake_plant_id IS NOT NULL
        OR wtp_id IS NOT NULL
        OR station_id IS NOT NULL
    )
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE INDEX idx_comp_intake ON components(intake_plant_id);
CREATE INDEX idx_comp_wtp ON components(wtp_id);
CREATE INDEX idx_comp_station ON components(station_id);
-- 6.1 Component Units (Individual instances for quantity > 1)
-- Tracks specific physical units (e.g., "Pump 01", "Pump 02")
CREATE TABLE IF NOT EXISTS component_units (
    id CHAR(36) PRIMARY KEY,
    component_id CHAR(36) NOT NULL,
    unit_identifier VARCHAR(100) NOT NULL,
    -- e.g., 'Pump01', 'Pump02'
    unit_status ENUM(
        'active',
        'inactive',
        'under_repair',
        'decommissioned'
    ) DEFAULT 'active',
    deleted_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (component_id) REFERENCES components(id) ON DELETE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE INDEX idx_comp_unit_parent ON component_units(component_id);
-- =============================================================================
-- 4. SCHEMES & BENEFICIARIES
-- =============================================================================
-- 1. Schemes
-- FIX: facility_id was an unenforced polymorphic CHAR(36).
--      Replaced with three nullable FKs + a CHECK to ensure exactly one is set.
--      facility_type ENUM kept for quick filtering without joins.
CREATE TABLE IF NOT EXISTS schemes (
    id CHAR(36) PRIMARY KEY,
    division_id CHAR(36) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    -- Polymorphic facility link — exactly one of the three must be non-NULL
    production_centre_id CHAR(36) NULL,
    wtp_id CHAR(36) NULL,
    boosting_station_id CHAR(36) NULL,
    facility_type ENUM('production_centre', 'wtp', 'boosting_station') NOT NULL,
    revenue_target DECIMAL(15, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (division_id) REFERENCES divisions(id) ON DELETE RESTRICT,
    FOREIGN KEY (production_centre_id) REFERENCES production_centres(id) ON DELETE RESTRICT,
    FOREIGN KEY (wtp_id) REFERENCES water_treatment_plants(id) ON DELETE RESTRICT,
    FOREIGN KEY (boosting_station_id) REFERENCES boosting_stations(id) ON DELETE RESTRICT,
    CONSTRAINT chk_scheme_facility CHECK (
        (
            production_centre_id IS NOT NULL
            AND wtp_id IS NULL
            AND boosting_station_id IS NULL
        )
        OR (
            production_centre_id IS NULL
            AND wtp_id IS NOT NULL
            AND boosting_station_id IS NULL
        )
        OR (
            production_centre_id IS NULL
            AND wtp_id IS NULL
            AND boosting_station_id IS NOT NULL
        )
    )
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE INDEX idx_schemes_division ON schemes(division_id);
-- 2. Beneficiary Institutions
CREATE TABLE IF NOT EXISTS beneficiary_institutions (
    id CHAR(36) PRIMARY KEY,
    scheme_id CHAR(36) NOT NULL,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(100),
    -- School, Hospital, Govt Office, etc.
    contact_person VARCHAR(150),
    pincode_id INT,
    address_line TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (scheme_id) REFERENCES schemes(id) ON DELETE RESTRICT,
    FOREIGN KEY (pincode_id) REFERENCES pincodes(id) ON DELETE
    SET NULL
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE INDEX idx_bi_scheme ON beneficiary_institutions(scheme_id);
CREATE INDEX idx_bi_pincode ON beneficiary_institutions(pincode_id);
-- 3. Household Registry
CREATE TABLE IF NOT EXISTS households (
    id CHAR(36) PRIMARY KEY,
    scheme_id CHAR(36) NOT NULL,
    household_head VARCHAR(255) NOT NULL,
    connection_id VARCHAR(100) UNIQUE,
    pincode_id INT,
    address_line TEXT,
    status ENUM('active', 'inactive', 'suspended') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (scheme_id) REFERENCES schemes(id) ON DELETE RESTRICT,
    FOREIGN KEY (pincode_id) REFERENCES pincodes(id) ON DELETE
    SET NULL
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE INDEX idx_households_scheme ON households(scheme_id);
CREATE INDEX idx_households_pincode ON households(pincode_id);
-- 4. Water Quality Reports
CREATE TABLE IF NOT EXISTS water_quality_reports (
    id CHAR(36) PRIMARY KEY,
    scheme_id CHAR(36) NOT NULL,
    test_date DATE NOT NULL,
    parameters JSON,
    -- pH, Turbidity, Chlorine level, etc.
    overall_status ENUM('safe', 'unsafe', 'warning') DEFAULT 'safe',
    tested_by CHAR(36),
    report_url VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (scheme_id) REFERENCES schemes(id) ON DELETE RESTRICT,
    FOREIGN KEY (tested_by) REFERENCES users(id) ON DELETE
    SET NULL
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE INDEX idx_wqr_scheme ON water_quality_reports(scheme_id);
-- 5. Revenue Collection Status
CREATE TABLE IF NOT EXISTS revenue_collection (
    id CHAR(36) PRIMARY KEY,
    -- FIX: explicit PRIMARY KEY declaration
    scheme_id CHAR(36) NOT NULL,
    period_label VARCHAR(50),
    -- e.g., 'Oct 2023'
    target_amount DECIMAL(15, 2),
    collected_amount DECIMAL(15, 2) DEFAULT 0.00,
    collection_percentage FLOAT GENERATED ALWAYS AS (
        (collected_amount / NULLIF(target_amount, 0)) * 100
    ) STORED,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (scheme_id) REFERENCES schemes(id) ON DELETE RESTRICT
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE INDEX idx_rc_scheme ON revenue_collection(scheme_id);
-- =============================================================================
-- 5. PIPELINES
-- =============================================================================
CREATE TABLE IF NOT EXISTS pipelines (
    id CHAR(36) PRIMARY KEY,
    intake_plant_id CHAR(36),
    wtp_id CHAR(36),
    station_id CHAR(36),
    component_unit_id CHAR(36),
    -- Optional: specific component it serves
    scheme_id CHAR(36),
    -- Optional: supply scheme link
    name VARCHAR(150) NOT NULL,
    diameter_mm INT,
    material VARCHAR(100),
    length_km FLOAT,
    geometry JSON,
    -- GeoJSON LineString or MultiLineString
    deleted_at TIMESTAMP NULL,
    -- FIX: soft-delete
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    -- FIX: added
    FOREIGN KEY (intake_plant_id) REFERENCES water_intake_plants(id) ON DELETE RESTRICT,
    FOREIGN KEY (wtp_id) REFERENCES water_treatment_plants(id) ON DELETE RESTRICT,
    FOREIGN KEY (station_id) REFERENCES boosting_stations(id) ON DELETE RESTRICT,
    FOREIGN KEY (component_unit_id) REFERENCES component_units(id) ON DELETE RESTRICT,
    FOREIGN KEY (scheme_id) REFERENCES schemes(id) ON DELETE
    SET NULL,
        CONSTRAINT chk_pipeline_link CHECK (
            intake_plant_id IS NOT NULL
            OR wtp_id IS NOT NULL
            OR station_id IS NOT NULL
            OR component_unit_id IS NOT NULL
        )
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE INDEX idx_pipe_intake ON pipelines(intake_plant_id);
CREATE INDEX idx_pipe_wtp ON pipelines(wtp_id);
CREATE INDEX idx_pipe_station ON pipelines(station_id);
CREATE INDEX idx_pipe_component ON pipelines(component_unit_id);
CREATE INDEX idx_pipe_scheme ON pipelines(scheme_id);
-- =============================================================================
-- 6. INCIDENT STATUS LOOKUP
-- (Moved before breakdowns to resolve forward reference: breakdowns -> breakdown_statuses)
-- =============================================================================
CREATE TABLE IF NOT EXISTS breakdown_statuses (
    id INT AUTO_INCREMENT PRIMARY KEY,
    status VARCHAR(50) UNIQUE NOT NULL,
    display_name VARCHAR(100) NOT NULL
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
-- =============================================================================
-- 7. INCIDENT & WORKFLOW TABLES
-- =============================================================================
-- Breakdown Reports
CREATE TABLE IF NOT EXISTS breakdowns (
    id CHAR(36) PRIMARY KEY,
    report_number VARCHAR(50) UNIQUE NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    pipeline_id CHAR(36),
    component_unit_id CHAR(36),
    -- Changed to track specific physical units
    reporter_id CHAR(36) NOT NULL,
    status_id INT NOT NULL,
    severity ENUM('critical', 'high', 'medium', 'low') DEFAULT 'low',
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    pincode_id INT,
    address_line TEXT,
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    approved_at TIMESTAMP NULL,
    approved_by CHAR(36),
    auto_approval_at TIMESTAMP NULL,
    completion_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    -- FIX: explicit ON DELETE behaviors on all FKs
    FOREIGN KEY (pipeline_id) REFERENCES pipelines(id) ON DELETE RESTRICT,
    FOREIGN KEY (component_unit_id) REFERENCES component_units(id) ON DELETE RESTRICT,
    FOREIGN KEY (reporter_id) REFERENCES users(id) ON DELETE RESTRICT,
    FOREIGN KEY (approved_by) REFERENCES users(id) ON DELETE
    SET NULL,
        FOREIGN KEY (status_id) REFERENCES breakdown_statuses(id) ON DELETE RESTRICT,
        FOREIGN KEY (pincode_id) REFERENCES pincodes(id) ON DELETE
    SET NULL,
        CONSTRAINT chk_breakdown_asset CHECK (
            pipeline_id IS NOT NULL
            OR component_unit_id IS NOT NULL
        )
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE INDEX idx_bd_pincode ON breakdowns(pincode_id);
-- FIX: all FK and high-frequency query columns indexed
CREATE INDEX idx_bd_status ON breakdowns(status_id);
CREATE INDEX idx_bd_reporter ON breakdowns(reporter_id);
CREATE INDEX idx_bd_pipeline ON breakdowns(pipeline_id);
CREATE INDEX idx_bd_component ON breakdowns(component_unit_id);
CREATE INDEX idx_bd_severity ON breakdowns(severity);
CREATE INDEX idx_bd_submitted ON breakdowns(submitted_at);
CREATE INDEX idx_bd_approved_by ON breakdowns(approved_by);
-- Execution Stages (stage-wise repair progress)
CREATE TABLE IF NOT EXISTS execution_stages (
    id CHAR(36) PRIMARY KEY,
    breakdown_id CHAR(36) NOT NULL,
    stage_name ENUM(
        'initial_inspection',
        'damage_report',
        'excavation',
        'repair_in_progress',
        'completion',
        'road_restoration',
        'inspection'
    ) NOT NULL,
    uploaded_by CHAR(36) NOT NULL,
    -- FIX: track who uploaded each stage
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    -- FIX: added
    -- RESTRICT: prevent deletion of breakdown while progress stages exist
    FOREIGN KEY (breakdown_id) REFERENCES breakdowns(id) ON DELETE RESTRICT,
    FOREIGN KEY (uploaded_by) REFERENCES users(id) ON DELETE RESTRICT,
    UNIQUE (breakdown_id, stage_name)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE INDEX idx_es_breakdown ON execution_stages(breakdown_id);
-- Centralized Media Table
CREATE TABLE IF NOT EXISTS media (
    id CHAR(36) PRIMARY KEY,
    breakdown_id CHAR(36),
    -- Nullable: link to initial report
    execution_stage_id CHAR(36),
    -- Nullable: link to work progress
    media_url VARCHAR(255) NOT NULL,
    media_type ENUM('photo', 'video') NOT NULL,
    file_type VARCHAR(50),
    -- MIME type (e.g., image/jpeg)
    file_size BIGINT,
    -- Size in bytes
    uploaded_by CHAR(36) NOT NULL,
    gps_coords JSON,
    remarks TEXT,
    metadata_json JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (breakdown_id) REFERENCES breakdowns(id) ON DELETE CASCADE,
    FOREIGN KEY (execution_stage_id) REFERENCES execution_stages(id) ON DELETE CASCADE,
    FOREIGN KEY (uploaded_by) REFERENCES users(id) ON DELETE RESTRICT
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE INDEX idx_media_breakdown ON media(breakdown_id);
CREATE INDEX idx_media_stage ON media(execution_stage_id);
CREATE INDEX idx_media_uploader ON media(uploaded_by);
-- =============================================================================
-- 8. CONTRACTOR & WORK ASSIGNMENT SYSTEM
-- =============================================================================
-- Contractors Table
CREATE TABLE IF NOT EXISTS contractor (
    id CHAR(36) PRIMARY KEY,
    user_id CHAR(36) UNIQUE NOT NULL,
    company_name VARCHAR(255) NOT NULL,
    pincode_id INT,
    address_line TEXT,
    -- FIX: category changed from VARCHAR to ENUM — enforces valid specialties
    category ENUM(
        'electrical',
        'pipe',
        'pump_motor',
        'civil',
        'other'
    ) NOT NULL,
    experience INT,
    -- FIX: documents moved to JSON array of {name, url} objects; document_url kept for primary cert
    documents_json JSON,
    -- [{"name": "PAN Card", "url": "..."}]
    document_url VARCHAR(255),
    -- Primary registration certificate URL
    -- FIX: status changed from VARCHAR to ENUM
    status ENUM('active', 'suspended', 'blacklisted', 'inactive') DEFAULT 'active',
    deleted_at TIMESTAMP NULL,
    -- FIX: soft-delete
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    -- FIX: added
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (pincode_id) REFERENCES pincodes(id) ON DELETE
    SET NULL
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE INDEX idx_contractor_status ON contractor(status);
CREATE INDEX idx_contractor_pincode ON contractor(pincode_id);
-- Work Orders (Contractor Assignments)
CREATE TABLE IF NOT EXISTS work_orders (
    id CHAR(36) PRIMARY KEY,
    breakdown_id CHAR(36) NOT NULL,
    contractor_id CHAR(36) NOT NULL,
    supervisor_id CHAR(36),
    -- PHE Official supervising the work
    assigned_by CHAR(36) NOT NULL,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expected_completion_date DATETIME,
    status ENUM(
        'pending',
        'in_progress',
        'completed',
        'cancelled'
    ) DEFAULT 'pending',
    progress_percentage INT DEFAULT 0,
    excavation_required BOOLEAN DEFAULT FALSE,
    path_sammanay_cert_url VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    -- FIX: added
    -- FIX: explicit ON DELETE on all FKs
    FOREIGN KEY (breakdown_id) REFERENCES breakdowns(id) ON DELETE RESTRICT,
    FOREIGN KEY (contractor_id) REFERENCES contractor(id) ON DELETE RESTRICT,
    FOREIGN KEY (supervisor_id) REFERENCES users(id) ON DELETE
    SET NULL,
        FOREIGN KEY (assigned_by) REFERENCES users(id) ON DELETE RESTRICT
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE INDEX idx_wo_breakdown ON work_orders(breakdown_id);
CREATE INDEX idx_wo_contractor ON work_orders(contractor_id);
CREATE INDEX idx_wo_status ON work_orders(status);
CREATE INDEX idx_wo_supervisor ON work_orders(supervisor_id);
-- Work Order Task Checklist
CREATE TABLE IF NOT EXISTS work_order_tasks (
    id CHAR(36) PRIMARY KEY,
    work_order_id CHAR(36) NOT NULL,
    task_name VARCHAR(255) NOT NULL,
    description TEXT,
    is_completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    -- FIX: added
    FOREIGN KEY (work_order_id) REFERENCES work_orders(id) ON DELETE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE INDEX idx_wot_work_order ON work_order_tasks(work_order_id);
-- Contractor Performance Reviews
CREATE TABLE IF NOT EXISTS contractor_performance (
    id CHAR(36) PRIMARY KEY,
    assignment_id CHAR(36) UNIQUE NOT NULL,
    rating INT CHECK (
        rating >= 1
        AND rating <= 5
    ),
    remarks TEXT,
    actual_completion_time TIMESTAMP,
    delay_days INT,
    -- (actual_completion_time - expected_completion_date)
    rated_by CHAR(36) NOT NULL,
    rated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (assignment_id) REFERENCES work_orders(id) ON DELETE CASCADE,
    FOREIGN KEY (rated_by) REFERENCES users(id) ON DELETE RESTRICT
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
-- =============================================================================
-- 9. APPROVAL SYSTEM & REPAIR HISTORY
-- =============================================================================
-- Approval Flow (Immutable Audit Trail — no updates, only inserts)
CREATE TABLE IF NOT EXISTS approval_flow (
    id CHAR(36) PRIMARY KEY,
    breakdown_id CHAR(36) NOT NULL,
    approver_id CHAR(36),
    -- NULL if system / auto-approved
    action ENUM(
        'SUBMITTED',
        'APPROVED',
        'REJECTED',
        'AUTO_APPROVED',
        'ASSIGNED'
    ) NOT NULL,
    remarks TEXT,
    action_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (breakdown_id) REFERENCES breakdowns(id) ON DELETE CASCADE,
    FOREIGN KEY (approver_id) REFERENCES users(id) ON DELETE
    SET NULL
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE INDEX idx_af_breakdown ON approval_flow(breakdown_id);
CREATE INDEX idx_af_approver ON approval_flow(approver_id);
CREATE INDEX idx_af_timestamp ON approval_flow(action_timestamp);
-- Completion Certificates
CREATE TABLE IF NOT EXISTS completion_certificates (
    id CHAR(36) PRIMARY KEY,
    breakdown_id CHAR(36) UNIQUE NOT NULL,
    applied_by CHAR(36) NOT NULL,
    issued_by CHAR(36) NOT NULL,
    pdf_url VARCHAR(255) NOT NULL,
    budget_allocated DECIMAL(15, 2),
    repair_cost DECIMAL(15, 2),
    issue_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (breakdown_id) REFERENCES breakdowns(id) ON DELETE RESTRICT,
    FOREIGN KEY (applied_by) REFERENCES users(id) ON DELETE RESTRICT,
    FOREIGN KEY (issued_by) REFERENCES users(id) ON DELETE RESTRICT
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
-- Repair History (Physical Audit Table — populated via trigger on certificate insert)
CREATE TABLE IF NOT EXISTS repair_history (
    id CHAR(36) PRIMARY KEY,
    breakdown_id CHAR(36),
    certificate_id CHAR(36),
    -- Asset snapshot (denormalized intentionally for permanent record)
    asset_id CHAR(36) NOT NULL,
    asset_type ENUM('pipeline', 'component') NOT NULL,
    asset_name VARCHAR(255) NOT NULL,
    -- Financial snapshot
    budget_allocated DECIMAL(15, 2),
    repair_cost DECIMAL(15, 2) NOT NULL,
    -- Metadata
    contractor_id CHAR(36),
    completed_at TIMESTAMP NOT NULL,
    verified_by CHAR(36),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- FIX: SET NULL on breakdown/certificate preserves history even if source records are removed
    FOREIGN KEY (breakdown_id) REFERENCES breakdowns(id) ON DELETE
    SET NULL,
        FOREIGN KEY (certificate_id) REFERENCES completion_certificates(id) ON DELETE
    SET NULL,
        -- FIX: FK added on contractor_id — was unenforced before
        FOREIGN KEY (contractor_id) REFERENCES contractor(id) ON DELETE
    SET NULL,
        FOREIGN KEY (verified_by) REFERENCES users(id) ON DELETE
    SET NULL
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE INDEX idx_rh_breakdown ON repair_history(breakdown_id);
CREATE INDEX idx_rh_asset ON repair_history(asset_id, asset_type);
CREATE INDEX idx_rh_contractor ON repair_history(contractor_id);
-- =============================================================================
-- 10. AUDIT & NOTIFICATIONS
-- =============================================================================
-- Master Audit Logs (immutable — never update or delete rows here)
CREATE TABLE IF NOT EXISTS audit_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id CHAR(36),
    action_type VARCHAR(50) NOT NULL,
    -- CREATE, UPDATE, DELETE, LOGIN, etc.
    entity_type VARCHAR(50) NOT NULL,
    -- breakdowns, users, work_orders, etc.
    entity_id CHAR(36),
    diff_json JSON,
    -- { "old": {}, "new": {} }
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE
    SET NULL
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
-- FIX: indexes critical for Finance/DC audit queries
CREATE INDEX idx_al_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX idx_al_user ON audit_logs(user_id);
CREATE INDEX idx_al_timestamp ON audit_logs(timestamp);
-- Notification Logs
-- Note: FCM tokens in target_fcm_token must be invalidated/updated on user logout or device change
CREATE TABLE IF NOT EXISTS notification_logs (
    id CHAR(36) PRIMARY KEY,
    sent_by CHAR(36),
    sent_to CHAR(36) NOT NULL,
    target_fcm_token VARCHAR(255),
    -- Snapshot of token at send time
    is_read BOOLEAN DEFAULT FALSE,
    event_type VARCHAR(50),
    -- e.g., 'breakdown_reported', 'work_assigned', 'certificate_issued'
    status ENUM('sent', 'delivered', 'failed', 'pending') DEFAULT 'pending',
    message TEXT,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sent_by) REFERENCES users(id) ON DELETE
    SET NULL,
        FOREIGN KEY (sent_to) REFERENCES users(id) ON DELETE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE INDEX idx_nl_sent_to ON notification_logs(sent_to);
CREATE INDEX idx_nl_sent_at ON notification_logs(sent_at);