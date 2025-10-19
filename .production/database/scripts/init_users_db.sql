CREATE DATABASE IF NOT EXISTS `ars_user`;
-- DEFAULT CHARACTER SET utf8mb4
-- COLLATE utf8mb4_unicode_ci
-- DEFAULT ENCRYPTION='N'
USE `ars_user`;
-- Server version 8.0.37

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS `role_authority`;
DROP TABLE IF EXISTS `authority`;
DROP TABLE IF EXISTS `user_role`;
DROP TABLE IF EXISTS `roles`;
DROP TABLE IF EXISTS `users`;

SET FOREIGN_KEY_CHECKS = 1;

DROP TABLE IF EXISTS users;
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    fullname NVARCHAR(100) NOT NULL,
    normalized_name VARCHAR(50),
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20),
    status TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '0: Dừng hoạt động, 1: Hoạt động, 2: Bị khóa, 3: Đã xóa',
    is_admin TINYINT(1) NOT NULL DEFAULT FALSE COMMENT 'Quyền admin: 1 = admin, 0 = user',
    created_by VARCHAR(50),
    last_modified_by VARCHAR(50),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS roles;
CREATE TABLE roles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name NVARCHAR(50) NOT NULL,
    code VARCHAR(50) NOT NULL UNIQUE,
    normalized_name VARCHAR(50) NOT NULL,
    created_by VARCHAR(50),
    last_modified_by VARCHAR(50),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS user_role;
CREATE TABLE user_role (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    role_id INT NOT NULL,
    created_by VARCHAR(50),
    last_modified_by VARCHAR(50),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_user_role_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_user_role_role FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    UNIQUE (user_id, role_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS authority;
CREATE TABLE authority (
    id INT AUTO_INCREMENT PRIMARY KEY,
    parent_id INT NULL,
    parent_code VARCHAR(50) NULL,
    name NVARCHAR(50) NOT NULL,
    code VARCHAR(50) NOT NULL UNIQUE,
    description NVARCHAR(255),
    created_by VARCHAR(50),
    last_modified_by VARCHAR(50),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_authority_parent FOREIGN KEY (parent_id) REFERENCES authority(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS role_authority;
CREATE TABLE role_authority (
    id INT AUTO_INCREMENT PRIMARY KEY,
    role_id INT NOT NULL,
    authority_id INT NOT NULL,
    created_by VARCHAR(50),
    last_modified_by VARCHAR(50),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_role_authority_role FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    CONSTRAINT fk_role_authority_authority FOREIGN KEY (authority_id) REFERENCES authority(id) ON DELETE CASCADE,
    UNIQUE (role_id, authority_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create SUPER_ADMIN role
INSERT INTO roles (
    name,
    code,
    normalized_name,
    created_by,
    created_date,
    last_modified_by,
    last_modified_date
)
VALUES
(
    'Administrator',
    'ROLE_ADMIN',
    'administrator',
    'system',
    CURRENT_TIMESTAMP,
    'system',
    CURRENT_TIMESTAMP
),
(
    'Shop owner',
    'ROLE_DEFAULT',
    'shop_owner',
    'system',
    CURRENT_TIMESTAMP,
    'system',
    CURRENT_TIMESTAMP
);

-- Manage System
INSERT INTO `authority` (`name`, `code`, `description`, `parent_id`, `parent_code`, `created_by`, `last_modified_by`)
VALUES ('authority.system', '01', 'authority.system.description', NULL, NULL, 'admin', 'admin');

SET @system_id = LAST_INSERT_ID();

INSERT INTO `authority` (`name`, `code`, `description`, `parent_id`, `parent_code`, `created_by`, `last_modified_by`)
VALUES ('authority.system.update', '0101', 'authority.system.update.description', @system_id, '01', 'admin', 'admin');

-- Manage Users
INSERT INTO `authority` (`name`, `code`, `description`, `parent_id`, `parent_code`, `created_by`, `last_modified_by`)
VALUES ('authority.user', '02', 'authority.user.description', NULL, NULL, 'admin', 'admin');

SET @user_id = LAST_INSERT_ID();

INSERT INTO `authority` (`name`, `code`, `description`, `parent_id`, `parent_code`, `created_by`, `last_modified_by`)
VALUES
('authority.user.create', '0201', 'authority.user.create.description', @user_id, '02', 'admin', 'admin'),
('authority.user.update', '0202', 'authority.user.update.description', @user_id, '02', 'admin', 'admin'),
('authority.user.delete', '0203', 'authority.user.delete.description', @user_id, '02', 'admin', 'admin');

-- Manage Roles
INSERT INTO `authority` (`name`, `code`, `description`, `parent_id`, `parent_code`, `created_by`, `last_modified_by`)
VALUES ('authority.role', '03', 'authority.role.description', NULL, NULL, 'admin', 'admin');

SET @role_id = LAST_INSERT_ID();

INSERT INTO `authority` (`name`, `code`, `description`, `parent_id`, `parent_code`, `created_by`, `last_modified_by`)
VALUES
('authority.role.create', '0301', 'authority.role.create.description', @role_id, '03', 'admin', 'admin'),
('authority.role.update', '0302', 'authority.role.update.description', @role_id, '03', 'admin', 'admin'),
('authority.role.delete', '0303', 'authority.role.delete.description', @role_id, '03', 'admin', 'admin');


START TRANSACTION;
-- Delete all old rights of ROLE_ADMIN
DELETE ra
FROM role_authority ra JOIN roles r ON ra.role_id = r.id
WHERE r.code = 'ROLE_ADMIN';

-- Re-add all permissions to ROLE_ADMIN
INSERT INTO role_authority (
    role_id,
    authority_id,
    created_by,
    created_date,
    last_modified_by,
    last_modified_date
)
SELECT
    r.id AS role_id,
    a.id AS authority_id,
    'system' AS created_by,
    CURRENT_TIMESTAMP AS created_date,
    'system' AS last_modified_by,
    CURRENT_TIMESTAMP AS last_modified_date
FROM roles r CROSS JOIN authority a
WHERE r.code = 'ROLE_ADMIN';

COMMIT;


START TRANSACTION;
-- Delete all old rights of ROLE_DEFAULT
DELETE ra
FROM role_authority ra JOIN roles r ON ra.role_id = r.id
WHERE r.code = 'ROLE_DEFAULT';

-- Re-add all permissions to ROLE_DEFAULT
INSERT INTO role_authority (
    role_id,
    authority_id,
    created_by,
    created_date,
    last_modified_by,
    last_modified_date
)
SELECT
    r.id AS role_id,
    a.id AS authority_id,
    'system' AS created_by,
    CURRENT_TIMESTAMP AS created_date,
    'system' AS last_modified_by,
    CURRENT_TIMESTAMP AS last_modified_date
FROM roles r CROSS JOIN authority a
WHERE r.code = 'ROLE_DEFAULT' AND a.code NOT IN ('01', '0101', '0102');

COMMIT;


-- Insert default super admin
INSERT INTO users (
    username,
    password,
    email,
    fullname,
    normalized_name,
    phone,
    is_admin,
    status,
    created_by,
    created_date,
    last_modified_by,
    last_modified_date
) VALUES (
    'admin',
    '$2a$12$gktW54NWmDzOCWwUNdkhOuJ4SIcYEHBudpIr.kAozvLWhRXgYL3F.',
    'admin@example.com',
    'Administrator',
    'administrator',
    '0123456789',
    1,
    1,
    'system',
    CURRENT_TIMESTAMP,
    'system',
    CURRENT_TIMESTAMP
);

SET @admin_user_id = LAST_INSERT_ID();
SELECT id INTO @role_admin_id FROM roles WHERE code = 'ROLE_ADMIN';

-- Assign ROLE_ADMIN to admin
INSERT INTO user_role (
    user_id,
    role_id,
    created_by,
    created_date,
    last_modified_by,
    last_modified_date
) VALUES (
    @admin_user_id,
    @role_admin_id,
    'system',
    CURRENT_TIMESTAMP,
    'system',
    CURRENT_TIMESTAMP
);
