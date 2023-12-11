/*
Business Requirement: Supplier Performance Data Exploration 

Skills used: Joins, CTEs, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

-- Vendors by total order amount 

SELECT 
    VendorName,
    MAX(CAST(POAmount AS DECIMAL(10, 2))) AS MaxOrderAmount
FROM ProcurementData
WHERE UPPER(VendorAgreementTerms) LIKE '%FOB%'
GROUP BY VendorName;

--Top 5 domestic Vendors by order amount

WITH DomesticVendorTotalSpend AS (
    SELECT 
        VendorName,
        PurchaseOfficers,
        SUM(POAmount) AS TotalSpend,
        RANK() OVER (PARTITION BY DomesticOrInternational ORDER BY SUM(POAmount) DESC) AS VendorRank
    FROM ProcurementData
    WHERE DomesticOrInternational = 'Domestic'
    GROUP BY VendorName, PurchaseOfficers, DomesticOrInternational
)
SELECT 
    DVS.VendorName,
    DVS.TotalSpend,
    DVS.PurchaseOfficers
FROM DomesticVendorTotalSpend DVS
WHERE DVS.VendorRank <= 5;

--Top 5 international Vendors by order amount
CREATE TEMPORARY TABLE InternationalVendorTotalSpend AS (
    SELECT 
        VendorName,
        PurchaseOfficers,
        SUM(POAmount) AS TotalSpend,
        RANK() OVER (PARTITION BY DomesticOrInternational ORDER BY SUM(POAmount) DESC) AS VendorRank
    FROM ProcurementData
    WHERE DomesticOrInternational = 'International'
    GROUP BY VendorName, PurchaseOfficers, DomesticOrInternational
);

SELECT 
    VendorName,
    TotalSpend,
    PurchaseOfficers
FROM InternationalVendorTotalSpend
WHERE VendorRank <= 5;

--Top 5 vendors offering the least discounts 
SELECT 
    VendorName,
    SUM(PODiscount) AS TotalDiscount
FROM ProcurementData
GROUP BY VendorName
ORDER BY TotalDiscount ASC
LIMIT 5;

-- List of Vendors, where we have to pay shipping fees for the order from their warehouse
SELECT 
    p.VendorName,
    p.POAmount,
    p.PurchaseOfficers
FROM ProcurementData p
WHERE p.VendorAgreementTerms = 'FOB - Vendor Warehouse'
ORDER BY p.POAmount DESC;

-- Delivery Delay for order transited by vendors
SELECT 
    s.VendorName,
    CASE 
        WHEN DATEDIFF(s.DeliveryDate, de.ExpectedDeliveryDate) = 0 THEN 'On Time'
        WHEN DATEDIFF(s.DeliveryDate, de.ExpectedDeliveryDate) > 0 THEN 'Delayed'
        ELSE 'Varied'
    END AS DeliveryPerformance
FROM SupplierDeliveryData s
JOIN DeliveryExpectations de ON s.VendorID = de.VendorID;
WHERE s.VendorAgreementTerms = 'FOB - Destination';


