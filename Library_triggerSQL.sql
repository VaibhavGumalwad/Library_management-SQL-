CREATE DATABASE Library;
USE Library;

-- Table "books" creation
CREATE TABLE books (
    book_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255),
    author VARCHAR(255),
    available_copies INT NOT NULL
);
-- Members Table
CREATE TABLE members (
    member_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    total_borrowed INT DEFAULT 0
);
-- Borrowings Table
CREATE TABLE borrowings (
    borrow_id INT AUTO_INCREMENT PRIMARY KEY,
    member_id INT,
    book_id INT,
    borrow_date DATE,
    return_date DATE,
    fine DECIMAL(10, 2) DEFAULT 0,
    FOREIGN KEY (member_id) REFERENCES members(member_id),
    FOREIGN KEY (book_id) REFERENCES books(book_id)
);

DELIMITER $$
-- Trigger to Decrease Available Copies on Borrowing
CREATE TRIGGER decrease_copies
BEFORE INSERT ON borrowings
FOR EACH ROW
BEGIN
    DECLARE available INT;
    -- Check available copies
    SELECT available_copies INTO available FROM books WHERE book_id = NEW.book_id;
    
    -- If no copies are available, raise an error
    IF available <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No available copies of this book';
    ELSE
        -- Otherwise, decrease the available copies
        UPDATE books SET available_copies = available_copies - 1 WHERE book_id = NEW.book_id;
    END IF;
END$$;


-- Trigger to Increase Available Copies on Return
CREATE TRIGGER increase_copies
AFTER UPDATE ON borrowings
FOR EACH ROW
BEGIN
    -- If the book has been returned, increase available copies
    IF NEW.return_date IS NOT NULL AND OLD.return_date IS NULL THEN
        UPDATE books SET available_copies = available_copies + 1 WHERE book_id = NEW.book_id;
    END IF;
END$$;


-- Trigger for Fine Calculation
CREATE TRIGGER calculate_fine
BEFORE UPDATE ON borrowings
FOR EACH ROW
BEGIN
    DECLARE days_borrowed INT;
    DECLARE fine_amount DECIMAL(10,2);
    
    -- Check if the return date is being updated
    IF NEW.return_date IS NOT NULL THEN
        -- Calculate the number of days the book was borrowed
        SET days_borrowed = DATEDIFF(NEW.return_date, OLD.borrow_date);
        
        -- If the book was borrowed for more than 14 days, calculate a fine
        IF days_borrowed > 15 THEN
            SET fine_amount = (days_borrowed - 15) * 10; -- Assuming the fine is $10 per extra day
            SET NEW.fine = fine_amount;
        ELSE
            SET NEW.fine = 0;
        END IF;
    END IF;
END$$;

-- Now we have to test the three given trigger by inserting data of borrowing table and updating the borrowing table data (return date ) That will result in decreasing copies in books table when we insert data in borrowings table. But decrease automaticaly the value of copies available when we update the return date from borrowings table.
-- Member 1 borrows Book 1
INSERT INTO borrowings (member_id, book_id, borrow_date) VALUES (1, 1, CURDATE());

-- Member 1 tries to borrow more than 3 books
INSERT INTO borrowings (member_id, book_id, borrow_date) VALUES (1, 2, CURDATE());
-- Member 1 returns Book 1 after 20 days (fine will be applied)
UPDATE borrowings SET return_date = DATE_ADD(borrow_date, INTERVAL 20 DAY) WHERE borrow_id = 1;







