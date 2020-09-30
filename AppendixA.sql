USE stockauction;

-- View 1
CREATE OR REPLACE VIEW AllCattleSold2020 AS
SELECT breed, quantity, lotSellingPrice, buyer.fullName AS buyer, seller.fullName AS seller, Agent.fullName AS agent, auctioneer.fullName AS auctioneer
FROM cattlelot
JOIN cattleauction ON cattleauction.id = cattlelot.auctionId
JOIN auctionday ON auctionday.id = cattleauction.auctionId
JOIN auctionclientatauction AS buyeratauction ON cattlelot.buyer = buyeratauction.clientNumber AND cattlelot.auctionDay = buyeratauction.auctionId
JOIN auctionclient AS buyer ON buyeratauction.clientID = buyer.id
JOIN auctionclientatauction AS selleratauction ON cattlelot.buyer = selleratauction.clientNumber AND cattlelot.auctionDay = selleratauction.auctionId
JOIN auctionclient AS seller ON selleratauction.clientID = seller.id
INNER JOIN stockagent auctioneer ON cattlelot.auctioneer=auctioneer.id 
INNER JOIN stockagent Agent ON cattlelot.agent = Agent.id
WHERE cattlelot.lotSellingPrice IS NOT NULL AND YEAR(auctionday.auctionDay) = '2020';

-- tests for view 1
SELECT * FROM cattlelot;
SELECT * FROM stockauction.allcattlesold2020;
SELECT * FROM cattlelot WHERE cattlelot.lotSellingPrice IS NOT NULL AND auctionId = 'C1619'; 

-- View 2
CREATE OR REPLACE VIEW AllSheepSold2020 AS
SELECT breed, quantity, lotSellingPrice, buyer.fullName AS buyer, seller.fullName AS seller, Agent.fullName AS agent, auctioneer.fullName AS auctioneer
FROM sheeplot
JOIN sheepauction ON sheepauction.id = sheeplot.auctionId
JOIN auctionday ON auctionday.id = sheepauction.auctionId
JOIN auctionclientatauction AS buyeratauction ON sheeplot.buyer = buyeratauction.clientNumber AND sheeplot.auctionDay = buyeratauction.auctionId
JOIN auctionclient AS buyer ON buyeratauction.clientID = buyer.id
JOIN auctionclientatauction AS selleratauction ON sheeplot.buyer = selleratauction.clientNumber AND sheeplot.auctionDay = selleratauction.auctionId
JOIN auctionclient AS seller ON selleratauction.clientID = seller.id
INNER JOIN stockagent auctioneer ON sheeplot.auctioneer=auctioneer.id 
INNER JOIN stockagent Agent ON sheeplot.agent = Agent.id
WHERE sheeplot.lotSellingPrice IS NOT NULL AND YEAR(auctionday.auctionDay) = '2020';

-- tests for view 2
SELECT * FROM sheeplot;
SELECT * FROM stockauction.allsheepsold2020;
SELECT * FROM sheeplot WHERE sheeplot.lotSellingPrice IS NOT NULL AND sheeplot.auctionId = 'S1619'; 

-- Trigger 1
ALTER TABLE auctionclientatauction 
ADD COLUMN sold DECIMAL(8,2), 
ADD COLUMN bought DECIMAL(8,2);
ALTER TABLE auctionclient
ADD COLUMN totalsold DECIMAL(10,2),
ADD COLUMN totalbought DECIMAL(10,2);


DROP TRIGGER IF EXISTS addsold;
delimiter //
CREATE TRIGGER addsold  AFTER INSERT  ON cattlelot
FOR EACH ROW
BEGIN
	IF New.lotsellingprice IS NOT NULL THEN 
    -- update seller
		UPDATE auctionclientatauction, auctionclient
		SET 
        sold = COALESCE(new.lotsellingprice + auctionclientatauction.sold, new.lotsellingprice),
        auctionclient.totalsold = COALESCE(new.lotsellingprice + auctionclient.totalsold, new.lotsellingprice)
		WHERE auctionclientatauction.clientNumber = new.seller 
        AND auctionclientatauction.auctionId = new.auctionday
        AND auctionclient.id = auctionclientatauction.clientID;
        -- update buyer
        UPDATE auctionclientatauction, auctionclient
        SET 
        auctionclientatauction.bought = COALESCE(new.lotsellingprice + auctionclientatauction.bought, new.lotsellingprice),
        auctionclient.totalbought = COALESCE(new.lotsellingprice + auctionclient.totalbought, new.lotsellingprice)
        WHERE auctionclientatauction.clientNumber = new.buyer 
        AND auctionclientatauction.auctionId = new.auctionday
        AND auctionclient.id = auctionclientatauction.clientID;
	END IF;
END //
delimiter ;

-- tests for addsold

-- reset values
UPDATE auctionclientatauction SET sold = NULL, bought = NULL WHERE auctionid = 1619 AND (clientNumber = 56 OR clientnumber = 57) ;
UPDATE auctionclient SET totalsold = NULL, totalbought = NULL WHERE id = 'Mar64' OR id = 'GAN56';
DELETE FROM cattlelot WHERE lotNumber = 889 AND auctionid = 'c1619';

-- add data to cattlelot to trigger the trigger
INSERT INTO cattlelot VALUES( 'C1619', 889, 1619, 57, 'P_Jan', 'Angus', 'B', 2, 14, 1023.00, NULL, 'P_Jan', 56, 3.17, NULL, NULL);

-- check seller info has changed: expected result:(sold = 45400.47, totalsold = 45400.47) after above addition, assuming trigger only triggered once
SELECT sold FROM auctionclientatauction WHERE clientnumber = 57 AND auctionid = 1619;
SELECT totalsold FROM auctionclient WHERE id = 'GAN56';

-- check if buyer info has changed expected result:(bought = 45400.47 and totalbought = 45400.47) same as above
SELECT bought FROM auctionclientatauction WHERE clientnumber = 56 AND auctionid = 1619;
SELECT totalbought FROM auctionclient WHERE id = 'Mar64';

-- trigger 2

ALTER TABLE auctionclient ADD COLUMN auctionsattended INT NOT NULL DEFAULT 0;
DROP TRIGGER IF EXISTS addauctionsattended;
DELIMITER //
CREATE TRIGGER addauctionsattended AFTER UPDATE ON auctionclientatauction FOR EACH ROW 
BEGIN
    UPDATE auctionclient 
    SET auctionsattended = (
		SELECT COUNT(1) 
		FROM auctionclientatauction
		INNER JOIN auctionday ON auctionclientatauction.auctionId = auctionday.id
		WHERE clientNumber = new.clientNumber 
		AND (auctionday.auctionDay BETWEEN DATE_SUB(NOW(), INTERVAL 1 YEAR) AND NOW())
    )
    WHERE auctionclient.id = new.clientid;
END//
DELIMITER ;

-- tests for trigger 2

-- check initial values
SELECT auctionsattended FROM auctionclient WHERE id = 'KIR77';
SELECT * FROM auctionclientatauction ,auctionday WHERE auctionday.id = auctionid AND  (auctionday BETWEEN DATE_SUB(NOW(), INTERVAL 1 YEAR) AND NOW()) AND clientid = 'kir77';
-- phantom update client number to trigger trigger
UPDATE auctionclientatauction SET clientnumber = clientnumber WHERE auctionid = '1619' AND clientid = 'KIR77';


-- Stored Procedure 1

DROP PROCEDURE IF EXISTS CreateAuction;
DELIMITER //
CREATE PROCEDURE CreateAuction(
	dateofauction DATE,
    id SMALLINT(6),
    lotType CHAR(6)
)
BEGIN
	IF LOWER(lotType) = 'both' THEN
		INSERT INTO auctionday VALUES (id, dateofauction);
        INSERT INTO sheepauction VALUES (CONCAT('S', id), id, CURTIME());
        INSERT INTO cattleauction VALUES (CONCAT('C', id), id, CURTIME());
	ELSEIF LOWER(lotType) = 'sheep' THEN
		INSERT INTO auctionday VALUES (id, dateofauction);
        INSERT INTO sheepauction VALUES (CONCAT('S', id), id, CURTIME());
	ELSEIF LOWER(lotType) = 'cattle' THEN
		INSERT INTO auctionday VALUES (id, dateofauction);
        INSERT INTO cattleauction VALUES (CONCAT('C', id), id, CURTIME());
	END IF;
END//
DELIMITER ;

-- test for procedure 1
CALL CreateAuction('2020-09-27', 1621, 'both');
SELECT * FROM auctionday;


-- Stored Pocedure 2
DROP TABLE IF EXISTS ClientsAtAuctionDay;
CREATE TEMPORARY TABLE ClientsAtAuctionDay(
	theClientId CHAR(5),
    theClientNumber SMALLINT UNSIGNED
);
LOAD DATA INFILE 'C:\\Temp\\mysql\\AuctionData\\1621Clients.csv'
	IGNORE INTO TABLE ClientsAtAuctionDay 
	FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n'
    IGNORE 1 LINES
    (@nextId, @nextClientNumber)
    SET theClientId = @nextId, theClientNumber = @nextClientNumber
    ;
    
DROP PROCEDURE IF EXISTS LoadAuctionClientsFromTempTable;
DELIMITER //
CREATE PROCEDURE LoadAuctionClientsFromTempTable(
	id SMALLINT(6)
)
BEGIN
    INSERT INTO auctionclientatauction (auctionId, clientNumber, clientID)
    SELECT id, theClientNumber, theClientId FROM ClientsAtAuctionDay;
END//
DELIMITER ;

-- tests for procedure 2
SELECT * FROM ClientsAtAuctionDay;
CALL LoadAuctionClientsFromTempTable(1621);



-- Stored Procedure 3
DROP TABLE IF EXISTS tempcattlelot;
CREATE TEMPORARY TABLE tempcattlelot(
	_lotNumber NCHAR(5),
    _seller SMALLINT UNSIGNED,
    _agent NCHAR(10),
    _auctioneer NCHAR(10),
    _breed NCHAR(20),
    _sex NCHAR(1),
    _age TINYINT,
    _quantity TINYINT,
    _averageWeight DECIMAL(6,2),
    _reserve DECIMAL(5,2),
    _buyer SMALLINT,
    _sellingPricePerkg DECIMAL(8,2),
    _passedIn INT(1)
);

DROP TABLE IF EXISTS tempsheeplot;
CREATE TEMPORARY TABLE tempsheeplot(
	_lotNumber NCHAR(5),
    _seller SMALLINT UNSIGNED,
    _agent NCHAR(10),
    _auctioneer NCHAR(10),
    _breed NCHAR(20),
    _sex NCHAR(1),
    _age TINYINT,
    _quantity TINYINT,
    _reserve DECIMAL(5,2),
    _buyer SMALLINT,
    _sellingPricePerHead DECIMAL(8,2),
    _passedIn INT(1)
);

LOAD DATA LOCAL INFILE 'C:\\Temp\\mysql\\C1621.csv'
	INTO TABLE tempcattlelot
	FIELDS TERMINATED BY ',' 
	ENCLOSED BY '"'
	LINES TERMINATED BY '\n'
	IGNORE 1 ROWS
    (@nextLotNumber, @nextSeller, @nextAgent, @nextAuctioneer, @nextBreed, @nextSex, @nextAge, @nextQuantity, @nextAverageWeight, @nextReserve, @nextBuyer, @nextSellingPricePerKG, @nextPassedIn)
    SET _lotNumber = @nextLotNumber, _seller = @nextSeller, _agent = @nextAgent, _auctioneer = @nextAuctioneer, _breed = @nextBreed, _sex = @nextSex, _age = @nextAge, _quantity = @nextQuantity, _reserve = @nextReserve;
    

LOAD DATA INFILE 'C:\\Temp\\mysql\\S1621.csv'
	INTO TABLE tempsheeplot
	FIELDS TERMINATED BY ',' 
	ENCLOSED BY '"'
	LINES TERMINATED BY '\n'
	IGNORE 1 ROWS
    (@nextLotNumber, @nextSeller, @nextAgent, @nextAuctioneer, @nextBreed, @nextSex, @nextAge, @nextQuantity, @nextAverageWeight, @nextReserve, @nextBuyer, @nextSellingPricePerKG, @nextPassedIn)
    SET _lotNumber = @nextLotNumber, _seller = @nextSeller, _agent = @nextAgent, _auctioneer = @nextAuctioneer, _breed = @nextBreed, _sex = @nextSex, _age = @nextAge, _quantity = @nextQuantity, _reserve = @nextReserve;
    
SELECT * FROM tempcattlelot;
SELECT * FROM tempsheeplot;

DROP PROCEDURE IF EXISTS LoadAuctionsPreSaleFromTempTable;
DELIMITER //
CREATE PROCEDURE LoadAuctionsPreSaleFromTempTable(
	_auctionId SMALLINT(6),
    lotType CHAR(6)
)
BEGIN
    IF LOWER(lotType) = 'both' THEN
		INSERT INTO sheeplot (auctionId, auctionDay, lotNumber, seller, agent, breed, sex, age, quantity, reserve, auctioneer)
		SELECT CONCAT('S', _auctionId), _auctionId, _lotNumber, _seller, _agent, _breed, _sex, _age, _quantity, _reserve, _auctioneer FROM tempsheeplot;
        INSERT INTO cattlelot (auctionId, auctionDay, lotNumber, seller, agent, breed, sex, age, quantity, reserve, auctioneer)
		SELECT CONCAT('C', _auctionId), _auctionId, _lotNumber, _seller, _agent, _breed, _sex, _age, _quantity, _reserve, _auctioneer FROM tempcattlelot;
	ELSEIF LOWER(lotType) = 'sheep' THEN
		INSERT INTO sheeplot (auctionId, auctionDay, lotNumber, seller, agent, breed, sex, age, quantity, reserve, auctioneer)
		SELECT CONCAT('S', _auctionId), _auctionId, _lotNumber, _seller, _agent, _breed, _sex, _age, _quantity, _reserve, _auctioneer FROM tempsheeplot;
	ELSEIF LOWER(lotType) = 'cattle' THEN
		INSERT INTO cattlelot (auctionId, auctionDay, lotNumber, seller, agent, breed, sex, age, quantity, reserve, auctioneer)
		SELECT CONCAT('C', _auctionId), _auctionId, _lotNumber, _seller, _agent, _breed, _sex, _age, _quantity, _reserve, _auctioneer FROM tempcattlelot;
	END IF;
END//
DELIMITER ;

-- tests for procedure 3
SELECT COUNT(1) FROM cattlelot;
SELECT COUNT(1) FROM sheeplot;
CALL LoadAuctionsPreSaleFromTempTable(1621, 'both');
SELECT COUNT(1) FROM cattlelot;
SELECT COUNT(1) FROM sheeplot;


-- Stored Procedure 5
SELECT COUNT(1) FROM cattlelot,sheeplot WHERE cattlelot.seller = 69 OR sheeplot.seller = 69;

DROP PROCEDURE IF EXISTS CalculateLotsSoldSeller;
DELIMITER //
CREATE PROCEDURE CalculateLotsSoldSeller(
	lotType CHAR(6),
    sellerID CHAR(10)
)
BEGIN
	DECLARE total INT DEFAULT 0;
    IF LOWER(lotType) = 'both' THEN
		SET total = (SELECT (SELECT SUM(lotSellingPrice) FROM cattlelot WHERE seller = sellerID) + (SELECT SUM(lotSellingPrice) FROM sheeplot WHERE seller = sellerID));
	ELSEIF LOWER(lotType) = 'sheep' THEN
		SET total = (SELECT SUM(lotSellingPrice) FROM sheeplot WHERE seller = sellerID);
	ELSEIF LOWER(lotType) = 'cattle' THEN
		SET total = (SELECT SUM(lotSellingPrice) FROM cattlelot WHERE seller = sellerID);
	END IF;
    SELECT total;
END//
DELIMITER ;

-- tests for procedure 5
CALL CalculateLotsSoldSeller('both', '40');
SELECT seller FROM cattlelot;

-- Stored Procedure 6
DROP PROCEDURE IF EXISTS CalculateLotsSoldBuyer;
DELIMITER //
CREATE PROCEDURE CalculateLotsSoldBuyer(
	lotType CHAR(6),
    buyerID CHAR(10)
)
BEGIN
	DECLARE total INT DEFAULT 0;
    IF LOWER(lotType) = 'both' THEN
		SET total = (SELECT (SELECT SUM(lotSellingPrice) FROM cattlelot WHERE buyer = buyerID) + (SELECT SUM(lotSellingPrice) FROM sheeplot WHERE buyer = buyerID));
	ELSEIF LOWER(lotType) = 'sheep' THEN
		SET total = (SELECT SUM(lotSellingPrice) FROM sheeplot WHERE buyer = buyerID);
	ELSEIF LOWER(lotType) = 'cattle' THEN
		SET total = (SELECT SUM(lotSellingPrice) FROM cattlelot WHERE buyer = buyerID);
	END IF;
    SELECT total;
END//
DELIMITER ;

-- tests for procedure 6
CALL CalculateLotsSoldBuyer('both', '65');
SELECT buyer FROM cattlelot;

-- Index 1
CREATE INDEX catauction ON cattlelot(auctionId, lotNumber);

-- test for index 1
SELECT * FROM cattlelot WHERE auctionId = 'C1619' AND lotNumber = '101';

-- Index 2
CREATE INDEX sheauction ON sheeplot(auctionId, lotNumber);

-- test for index 2
SELECT * FROM sheeplot WHERE auctionId = 'S1620' AND lotNumber = '260';



























