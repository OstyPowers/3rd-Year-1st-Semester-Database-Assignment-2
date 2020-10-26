-- removing users as they may already be loaded from marking other students work
DROP USER 'AuctionCreator'@'localhost';
DROP USER 'ClientLoader'@'localhost';
DROP USER 'StockLoader'@'localhost';
DROP USER 'AuctionDayDataEntry'@'localhost';
DROP USER 'AuctionDaySupervisor'@'localhost';
DROP USER 'SaleDayAdmin'@'localhost';
DROP USER 'Reporter'@'localhost';
DROP USER 'DailyReporter'@'localhost';

-- creating users
CREATE USER 'AuctionCreator'@'localhost' IDENTIFIED BY 'AuctionCreator';
CREATE USER 'ClientLoader'@'localhost' IDENTIFIED BY 'ClientLoader';
CREATE USER 'StockLoader'@'localhost' IDENTIFIED BY 'StockLoader';
CREATE USER 'AuctionDayDataEntry'@'localhost' IDENTIFIED BY 'DataEntry';
CREATE USER 'AuctionDaySupervisor'@'localhost' IDENTIFIED BY 'Supervisor';
CREATE USER 'SaleDayAdmin'@'localhost' IDENTIFIED BY 'Admin';
CREATE USER 'Reporter'@'localhost' IDENTIFIED BY 'Reporter';
CREATE USER 'DailyReporter'@'localhost' IDENTIFIED BY 'DailyReporter';

-- grant rights to users
GRANT UPDATE, INSERT ON stockauction.auctionday TO AuctionCreator@localhost;
GRANT UPDATE, INSERT ON stockauction.cattleauction TO AuctionCreator@localhost;
GRANT UPDATE, INSERT ON  stockauction.sheepauction TO AuctionCreator@localhost;

GRANT UPDATE, INSERT ON stockauction.auctionclient TO ClientLoader@localhost;
GRANT UPDATE, INSERT ON stockauction.auctionclientatauction TO ClientLoader@localhost;

GRANT UPDATE, INSERT ON stockauction.cattlelot TO StockLoader@localhost;
GRANT UPDATE, INSERT ON stockauction.sheeplot TO StockLoader@localhost;

GRANT UPDATE ON stockauction.cattlelot TO AuctionDayDataEntry@localhost;
GRANT UPDATE ON stockauction.sheeplot TO AuctionDayDataEntry@localhost;

GRANT UPDATE, INSERT ON stockauction.auctionclient TO AuctionDaySupervisor@localhost;
GRANT UPDATE, INSERT ON stockauction.auctionclientatauction TO AuctionDaySupervisor@localhost;
GRANT UPDATE, INSERT ON stockauction.cattlelot TO AuctionDaySupervisor@localhost;
GRANT UPDATE, INSERT ON stockauction.sheeplot TO AuctionDaySupervisor@localhost;

GRANT ALL ON stockauction TO SaleDayAdmin@localhost WITH GRANT OPTION;

GRANT SELECT ON stockauction.* TO Reporter@localhost;

GRANT SELECT ON stockauction.allcattlesold2020 TO DailyReporter@localhost;
GRANT SELECT ON stockauction.allsheepsold2020 TO DailyReporter@localhost;

-- tests for grants
FLUSH PRIVILEGES;
SHOW GRANTS FOR AuctionCreator@localhost;
SHOW GRANTS FOR  ClientLoader@localhost;
SHOW GRANTS FOR StockLoader@localhost;
SHOW GRANTS FOR AuctionDayDataEntr@localhost;
SHOW GRANTS FOR AuctionDaySupervisor@localhost;
SHOW GRANTS FOR SaleDayAdmin@localhost;
SHOW GRANTS FOR Reporter@localhost;
SHOW GRANTS FOR DailyReporter@localhost;

-- creating application roles equivalent to ClientLoader, AuctionDayDataEntry and Reporter users
CREATE ROLE 'client_loader', 'auction_data_entry', '_reporter';

GRANT UPDATE, INSERT ON stockauction.auctionclient TO client_loader;
GRANT UPDATE, INSERT ON stockauction.auctionclientatauction TO client_loader;

GRANT UPDATE ON stockauction.cattlelot TO auction_data_entry;
GRANT UPDATE ON stockauction.sheeplot TO auction_data_entry;

GRANT SELECT ON stockauction.* TO _reporter;

-- tests for roles
SHOW GRANTS FOR client_loader;
SHOW GRANTS FOR auction_data_entry;
SHOW GRANTS FOR _reporter;

-- giving appropriate users rights to run stored procedures from appendix a 
GRANT EXECUTE ON PROCEDURE stockauction.LoadAuctionClientsFromTempTable TO ClientLoader@localhost;

GRANT EXECUTE ON PROCEDURE stockauction.CreateAuction TO AuctionCreator@localhost;

GRANT EXECUTE ON PROCEDURE stockauction.LoadAuctionsPreSaleFromTempTable TO StockLoader@localhost;

GRANT EXECUTE ON PROCEDURE stockauction.CalculateLotsSoldSeller TO  AuctionDayDataEntry@localhost;

GRANT EXECUTE ON PROCEDURE stockauction.CalculateLotsSoldBuyer TO  AuctionDayDataEntry@localhost;

-- tests for grants on procedures
SHOW GRANTS FOR ClientLoader@localhost;
SHOW GRANTS FOR AuctionCreator@localhost;
SHOW GRANTS FOR StockLoader@localhost;
SHOW GRANTS FOR AuctionDayDataEntry@localhost;

-- creating a user to rebuild the indices from appendix a
CREATE USER 'IndexBuilder'@'localhost' IDENTIFIED BY 'IndexBuilder';

GRANT INDEX ON stockauction.cattlelot TO IndexBuilder@localhost;
GRANT INDEX ON stockauction.sheeplot TO IndexBuilder@localhost;

-- tests for grant on IndexBuilder
SHOW GRANTS FOR IndexBuilder@localhost;






