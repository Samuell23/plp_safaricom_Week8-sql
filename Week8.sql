

-- Database creation
DROP DATABASE IF EXISTS library_management;
CREATE DATABASE library_management;
USE library_management;

-- Publishers table
CREATE TABLE publishers (
    publisher_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address VARCHAR(200),
    phone VARCHAR(20),
    email VARCHAR(100),
    website VARCHAR(100),
    established_year YEAR,
    CONSTRAINT chk_publisher_email CHECK (email LIKE '%@%.%')
) COMMENT 'Stores information about book publishers';

-- Authors table
CREATE TABLE authors (
    author_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    birth_date DATE,
    nationality VARCHAR(50),
    biography TEXT,
    CONSTRAINT uk_author_name UNIQUE (first_name, last_name)
) COMMENT 'Stores information about book authors';

-- Categories table
CREATE TABLE categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT
) COMMENT 'Book categories/genres';

-- Members table
CREATE TABLE members (
    member_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20),
    address VARCHAR(200),
    date_of_birth DATE,
    membership_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    membership_expiry DATE,
    status ENUM('Active', 'Expired', 'Suspended') DEFAULT 'Active',
    CONSTRAINT chk_member_email CHECK (email LIKE '%@%.%'),
    CONSTRAINT chk_member_age CHECK (YEAR(CURRENT_DATE) - YEAR(date_of_birth) >= 13)
) COMMENT 'Library members information';

-- Books table
CREATE TABLE books (
    book_id INT AUTO_INCREMENT PRIMARY KEY,
    isbn VARCHAR(20) NOT NULL UNIQUE,
    title VARCHAR(200) NOT NULL,
    publisher_id INT NOT NULL,
    publication_year YEAR,
    edition INT DEFAULT 1,
    page_count INT,
    language VARCHAR(30) DEFAULT 'English',
    description TEXT,
    available_copies INT NOT NULL DEFAULT 1,
    total_copies INT NOT NULL DEFAULT 1,
    CONSTRAINT fk_book_publisher FOREIGN KEY (publisher_id) 
        REFERENCES publishers(publisher_id) ON DELETE RESTRICT,
    CONSTRAINT chk_book_copies CHECK (available_copies <= total_copies AND available_copies >= 0),
    CONSTRAINT chk_book_year CHECK (publication_year <= YEAR(CURRENT_DATE))
) COMMENT 'Main books inventory';

-- Book-Author relationship (M-M)
CREATE TABLE book_authors (
    book_id INT NOT NULL,
    author_id INT NOT NULL,
    PRIMARY KEY (book_id, author_id),
    CONSTRAINT fk_ba_book FOREIGN KEY (book_id) 
        REFERENCES books(book_id) ON DELETE CASCADE,
    CONSTRAINT fk_ba_author FOREIGN KEY (author_id) 
        REFERENCES authors(author_id) ON DELETE CASCADE
) COMMENT 'Many-to-many relationship between books and authors';

-- Book-Category relationship (M-M)
CREATE TABLE book_categories (
    book_id INT NOT NULL,
    category_id INT NOT NULL,
    PRIMARY KEY (book_id, category_id),
    CONSTRAINT fk_bc_book FOREIGN KEY (book_id) 
        REFERENCES books(book_id) ON DELETE CASCADE,
    CONSTRAINT fk_bc_category FOREIGN KEY (category_id) 
        REFERENCES categories(category_id) ON DELETE CASCADE
) COMMENT 'Many-to-many relationship between books and categories';

-- Loans table
CREATE TABLE loans (
    loan_id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT NOT NULL,
    member_id INT NOT NULL,
    loan_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    due_date DATE NOT NULL,
    return_date DATE,
    status ENUM('On Loan', 'Returned', 'Overdue') DEFAULT 'On Loan',
    late_fee DECIMAL(10,2) DEFAULT 0.00,
    CONSTRAINT fk_loan_book FOREIGN KEY (book_id) 
        REFERENCES books(book_id) ON DELETE RESTRICT,
    CONSTRAINT fk_loan_member FOREIGN KEY (member_id) 
        REFERENCES members(member_id) ON DELETE RESTRICT,
    CONSTRAINT chk_loan_dates CHECK (due_date > loan_date AND (return_date IS NULL OR return_date >= loan_date))
) COMMENT 'Tracks book loans to members';

-- Fines table
CREATE TABLE fines (
    fine_id INT AUTO_INCREMENT PRIMARY KEY,
    loan_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    issue_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    payment_date DATE,
    status ENUM('Pending', 'Paid', 'Waived') DEFAULT 'Pending',
    CONSTRAINT fk_fine_loan FOREIGN KEY (loan_id) 
        REFERENCES loans(loan_id) ON DELETE CASCADE,
    CONSTRAINT chk_fine_amount CHECK (amount >= 0)
) COMMENT 'Tracks fines for overdue books';

-- Reservations table
CREATE TABLE reservations (
    reservation_id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT NOT NULL,
    member_id INT NOT NULL,
    reservation_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expiry_date DATETIME NOT NULL,
    status ENUM('Pending', 'Fulfilled', 'Cancelled', 'Expired') DEFAULT 'Pending',
    CONSTRAINT fk_reservation_book FOREIGN KEY (book_id) 
        REFERENCES books(book_id) ON DELETE CASCADE,
    CONSTRAINT fk_reservation_member FOREIGN KEY (member_id) 
        REFERENCES members(member_id) ON DELETE CASCADE,
    CONSTRAINT chk_reservation_dates CHECK (expiry_date > reservation_date)
) COMMENT 'Tracks book reservations by members';

-- Create indexes for performance
CREATE INDEX idx_books_title ON books(title);
CREATE INDEX idx_members_name ON members(last_name, first_name);
CREATE INDEX idx_loans_dates ON loans(loan_date, due_date, return_date);
CREATE INDEX idx_loans_status ON loans(status);
CREATE INDEX idx_fines_status ON fines(status);