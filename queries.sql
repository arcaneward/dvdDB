--This section demonstrates the code that creates tables to hold the reports.
 
CREATE TABLE actor_payment (
payment_id int,
actor_id int,
amount numeric(5,2),
PRIMARY KEY(payment_id, actor_id)
);
CREATE TABLE actor_payment_total (
actor_id int,
actor_name varchar(100),
sum_amount numeric(10,2),
PRIMARY KEY (actor_id)
);
 
--The SQL query that extracts the raw data required for the detailed table of the business report is shown in this section. By making sure the column and row data types match by performing the query below, one may confirm the accuracy of the data. There shouldn't be any empty or invalid cells.
 
INSERT INTO actor_payment
SELECT payment.payment_id, actor.actor_id, payment.amount
FROM actor
INNER JOIN film_actor ON actor.actor_id = film_actor.actor_id
INNER JOIN film ON film.film_id = film_actor.film_id
INNER JOIN inventory ON film_actor.film_id = inventory.film_id
INNER JOIN rental ON inventory.inventory_id = rental.inventory_id
INNER JOIN payment ON rental.rental_id = payment.rental_id;
SELECT * FROM actor_payment;
 
--The code for the function that does the transformation is demonstrated in this section. The sum of all payments made to each actor in the detail table will be contained in the total_amount function.
 
CREATE FUNCTION total_payments(a_id int)
RETURNS numeric(10,2)
LANGUAGE plpgsql
AS $func$
DECLARE
payments_sum numeric(10,2);
BEGIN
SELECT SUM(amount)
INTO payments_sum
FROM actor_payment
WHERE actor_id = a_id;
return payments_sum;
END;$func$;
 
--The SQL code used in this part to build a trigger on the report's detailed table, which updates the summary table as new raw data is uploaded, is shown.
 
CREATE FUNCTION update_actor_total()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
INSERT INTO actor_payment_total
SELECT actor_id, actor_full_name(actor_id) AS actor_name, sum_rental_payments(actor_id) AS sum_amount
FROM actor;
RETURN NEW;
END;$$;3
CREATE TRIGGER new_trigger
AFTER INSERT
ON actor_payment
FOR EACH STATEMENT
EXECUTE PROCEDURE update_actor_total();
 
--This section demonstrates a stored procedure is used to refresh data in both the summary and detailed tables. It clears the data of the summary and detailed tables and performs the ETL load process from section C. 

CREATE PROCEDURE refresh_all()
LANGUAGE plpgsql
AS $$
BEGIN
DELETE FROM actor_payment;
DELETE FROM actor_payment_total;
INSERT INTO actor_payment
SELECT payment.payment_id, actor.actor_id, payment.amount
FROM actor
INNER JOIN film_actor ON actor.actor_id = film_actor.actor_id
INNER JOIN film ON film.film_id = film_actor.film_id
INNER JOIN inventory ON film_actor.film_id = inventory.film_id
INNER JOIN rental ON inventory.inventory_id = rental.inventory_id
INNER JOIN payment ON rental.rental_id = payment.rental_id;
END;$$;

CALL refresh_all();
SELECT * FROM summary;
