--Top 25 queries

--1 (30 sec,138 rows)

SELECT 'Delivered', o.OrderType,o.InteractiveModule
, COUNT(1) AS Total
, SUM(CASE WHEN CONVERT(DATE,O.UpdatedDate) = CONVERT(DATE, GETDATE()) THEN 1 ELSE 0 END) AS Today
--, SUM(CASE WHEN CONVERT(DATE,O.UpdatedDate) < CONVERT(DATE, GETDATE()) AND CONVERT(DATE,O.UpdatedDate) >= CONVERT(DATE, GETDATE()-1) THEN 1 ELSE 0 END) AS [Since Yesterday]
, SUM(CASE WHEN CONVERT(DATE,O.UpdatedDate) = CONVERT(DATE, GETDATE()-1) THEN 1 ELSE 0 END) AS [Since Yesterday]
, SUM(CASE WHEN CONVERT(DATE,O.UpdatedDate) BETWEEN CONVERT(DATE, GETDATE()-3) AND CONVERT(DATE, GETDATE()-1) THEN 1 ELSE 0 END) AS [Since Last 3 days]
, SUM(CASE WHEN CONVERT(DATE,O.UpdatedDate) BETWEEN CONVERT(DATE, GETDATE()-7) AND CONVERT(DATE, GETDATE()-1) THEN 1 ELSE 0 END) AS [Since Last 7 days]
, ISNULL(O.WarehouseId, 1)
, CASE WHEN ISNULL(O.UserType,'C') = 'Y' THEN 'RS' ELSE 'SS' END
FROM Orders.tblOrder O with(nolock)
WHERE O.OrderStatusId = 5 
GROUP BY o.OrderType,o.InteractiveModule, ISNULL(O.WarehouseId, 1), CASE WHEN ISNULL(O.UserType,'C') = 'Y' THEN 'RS' ELSE 'SS' END


--2 (50 sec, 34k rows)

With Cte AS (
SELECT O.OrderId, OI.ProductId
FROM Orders.tblOrderItem OI WITH(NOLOCK)
INNER JOIN Orders.tblOrder O WITH(NOLOCK) ON OI.OrderId = O.OrderId
WHERE O.OrderDate BETWEEN DATEADD(day, -30, GETDATE()) AND GETDATE()
AND OI.PrescriptionOTC IN ('O', 'M') 
)
SELECT ProductId, RelatedProductId
FROM (
SELECT ProductId, RelatedProductId, ROW_NUMBER() OVER(Partition By ProductId, IsFeatured ORDER BY OrdCnt DESC) AS RN
FROM (
SELECT A.ProductId AS ProductId, B.ProductId AS RelatedProductId, ISNULL(PS2.IsFeatured, 0) AS IsFeatured, COUNT(1) AS OrdCnt
FROM Cte A
INNER JOIN Cte B ON A.OrderId = B.OrderId
INNER JOIN Catalog.tblProductStaged PS1 WITH(NOLOCK) ON A.ProductId = PS1.ProductId AND PS1.WarehouseId = 1
INNER JOIN Catalog.tblProductStaged PS2 WITH(NOLOCK) ON B.ProductId = PS2.ProductId AND PS2.WarehouseId = 1
INNER JOIN Catalog.tblProductInvStaged PIS1 WITH(NOLOCK) ON A.ProductId = PIS1.ProductId AND PIS1.WarehouseId = 1
INNER JOIN Catalog.tblProductInvStaged PIS2 WITH(NOLOCK) ON B.ProductId = PIS2.ProductId AND PIS2.WarehouseId = 1
WHERE A.ProductId <> B.ProductId AND PS1.ParentCategory1Name = PS2.ParentCategory1Name
AND (PIS1.MRP <= 50 OR (PIS1.MRP > 50 AND PIS2.MRP > 10))
AND PS1.ProductStatus = 'C'
AND PS2.ProductStatus = 'C'
AND PS1.IsActive = 1 
AND PS2.IsActive = 1
GROUP BY A.ProductId, B.ProductId, ISNULL(PS2.IsFeatured, 0)
) tbl
) tblOut
WHERE RN <= 10


--3 (1 min, 138k rows)

select p.ProductId,OI.ParentWarehouseId AS WarehouseId,ISNULL(OI.TotalOrderqty,0) as SaleQuantity,ISNULL(oi.OrderCount,0) AS OrderCount
from  Catalog.tblproduct P WITH(NOLOCK)
INNER JOIN Reports.tblSoldandAvailableQty tbl on P.ProductId = tbl.ProductID
left join (
select distinct OS.ProductId,prr.ParentWarehouseId,SUM(itemquantity) as TotalOrderqty,COUNT(Distinct o.OrderId) AS OrderCount 
from Reports.tblSoldandAvailableQty prr
Inner join Orders.tblOrderItem OS WITH(NOLOCK) on OS.ProductId =prr.ProductID
inner join	orders.tblorder O WITH(NOLOCK)	on OS.Orderid=O.OrderId
----inner join orders.tblinvoice i with(nolock) on o.OrderId= i.orderid
INNER JOIN SiteManagement.tblWarehouse ws on o.WarehouseId = ws.WarehouseId
--inner join Orders.tblInvoice I WITH(NOLOCK) on O.OrderId=I.OrderId
where OS.PKLotId is not null and O.OrderStatusId  in (1,2,3,4,5,6,7,10,11,12,13,14,15)
and convert(date,o.ConfirmationDate) >=DATEADD(DD,-60,CONVERT(date,Getdate())) 
and convert(date,o.ConfirmationDate) < CONVERT(date,Getdate())			
AND ws.ParentWarehouseId=prr.ParentWarehouseId
group by OS.ProductId,prr.ParentWarehouseId
) OI on OI.ProductId=P.ProductId AND tbl.ParentWarehouseId = OI.ParentWarehouseId


--4 (16 sec, 0 rows)

SELECT DISTINCT pr.ProductRequestId FROM UserCommunication.tblProductRequest pr  WITH(NOLOCK)
INNER JOIN SiteManagement.tblWarehouse ws on ISNULL(pr.PRWHId,1) = ws.WarehouseId
INNER JOIN Catalog.tblProductInventory pn WITH(NOLOCK) on pr.ProductId = pn.ProductId AND ws.ParentWarehouseId = pn.WarehouseId
INNER JOIN UserManagement.tblCustomer u WITH(Nolock) on pr.CustUserId = u.userId -- added on 19.09.20
WHERE pr.IsOutOfStock = 'Y'
AND ISNULL(ProductRequestStatusMasId,10) IN (1,10,4)
AND DATEDIFF(HH,pn.CreatedDate,GETDATE()) <= 2


--5

declare @pStartDate datetime 
declare @pEndDate datetime 
set @pStartDate= DATEADD(day,-2,GETDATE())
set @pEndDate=GETDATE()
select top 100 *, 10001 AS CreatedBy, GetDate() AS CreatedDate
from (
select * from (
SELECT b.CustUserId, b.OrderId,b.HBId, 'Redeemtion' AS TransactionType
, convert(date, i.InvoicePrintingDate) AS TransactionDate, 'Order Placed' AS Comment
, isnull(a.SSCurrencyValue,0) AS SSCurrencyValue
, isnull(a.CouponDiscount, 0) AS CouponPromoDiscount
FROM Orders.tblorderItem a  with(nolock)
INNER JOIN Orders.tblOrder b with(nolock) ON a.OrderId = b.OrderId
INNER JOIN Orders.tblinvoice i  with(nolock) on b.OrderId = i.OrderId
WHERE --(a.SSCurrencyValue IS NOT NULL OR a.CouponDiscount IS NOT NULL)
(ISNULL(a.SSCurrencyValue, 0) > 0 OR ISNULL(a.CouponDiscount, 0) > 0) --Updated by Anujit on 20.12.2018
and convert(date, i.InvoicePrintingDate) >= @pStartDate
and convert(date, i.InvoicePrintingDate) <= @pEndDate
and convert(date, i.InvoiceDate) >= '08/01/2017'
AND i.IntegrationId is not null ANd b.orderstatusId not in (8,9) and i.InvoiceNo <> 'Not Assigned'
UNION ALL
-- Order Place -- Order Level Coupon Redemtion
SELECT b.CustUserId, b.OrderId,b.HBId, 'Redeemtion' AS TransactionType
, convert(date, i.InvoicePrintingDate) AS TransactionDate, 'Order Placed' AS Comment
, 0 AS SSCurrencyValue
,(CASE WHEN sph.IsPartnerShip = 1  THEN 0.00 ELSE isnull(b.CouponDiscount, 0) END) + ISNULL(b.PromoDiscount, 0) AS CouponPromoDiscount
FROM Orders.tblOrder b  with(nolock)
INNER JOIN Orders.tblinvoice i with(nolock) on b.OrderId = i.OrderId
LEFT JOIN 
(
--SELECT OrderId, MAX(IsPartnerShip) AS IsPartnerShip
--FROM (
SELECT o.OrderId,
p.IsPartnerShipCoupon  AS IsPartnerShip

FROM Orders.tblOrder o with(nolock)
INNER JOIN Orders.tblInvoice i with(nolock) on o.OrderId = i.OrderId
INNER JOIN UserManagement.tblHealthBuddy h on o.HBId = h.UserId
---INNER JOIN UserManagement.tblCouponPartnershipHB sph on o.HBId = sph.HBId
INNER JOIN Promotion.tblPromotion p with(nolock) on o.CouponPromoId = p.PromoId
WHERE CONVERT(date,i.InvoicePrintingDate) >=@pStartDate
AND CONVERT(date,i.InvoicePrintingDate) <=@pEndDate
AND o.IntegrationId IS NOT NULL
-----AND (o.OrderDate>= sph.StartDate AND o.OrderDate <= ISNULL(sph.EndDate,GETDATE()))
and o.OrderStatusId NOT IN (8,9)
AND i.InvoiceNo != 'Not Assigned'
AND p.IsPartnerShipCoupon = 1
and CONVERT(date,I.InvoiceDate) > '07/31/2017'
--) tbl
--GROUP BY OrderId
) sph on b.OrderId= sph.OrderId
WHERE --(b.CouponDiscount IS NOT NULL OR b.PromoDiscount IS NOT NULL)
(ISNULL(b.CouponDiscount, 0) > 0 OR ISNULL(b.PromoDiscount, 0) > 0) --Updated by Anujit on 20.12.2018
and convert(date, i.InvoicePrintingDate) >= @pStartDate
and convert(date, i.InvoicePrintingDate) <= @pEndDate
and convert(date, i.InvoiceDate) >= '08/01/2017'
AND i.IntegrationId is not null ANd b.orderstatusId not in (8,9) and i.InvoiceNo <> 'Not Assigned'
) tbl
UNION ALL
SELECT  *
FROM (
select O.CustUserId,O.OrderId,O.HBId, 'Reversal' AS TransactionType
,CONVERT(date,R.UpdatedDate) AS RetDate, 'Sales Return' AS Comment
,ISNULL(CONVERT(numeric(10,2),(ii.SSCurrencyValue*R.AcceptedQty)/ItemQuantity),0) AS SSCurrencyValue
,ISNULL(CONVERT(numeric(10,2),(ii.CouponDiscount*R.AcceptedQty)/ItemQuantity),0)  AS CouponPromoDiscount
from Orders.tblSalesReturnItem R with(nolock)
inner join Orders.tblInvoiceItem II with(nolock) on II.InvoiceItemId =R.InvoiceItemId
inner join Orders.tblInvoice I with(nolock) On II.InvoiceId = I.InvoiceId
inner join Orders.tblOrder O with(nolock) On I.OrderId = O.OrderId
Where 
--CONVERT(date,I.InvoicePrintingDate) >= @pStartDate And  CONVERT(date,I.InvoicePrintingDate) <= @pEndDate and --Commented on 21.06.2022
CONVERT(date,R.UpdatedDate) >= @pStartDate And CONVERT(date,R.UpdatedDate) <= @pEndDate
and i.InvoiceNo <> 'Not Assigned'
and R.SalesReturnStatusId = 6 --AND R.IntegrationId IS NOT  NULL --and i.hbid in  (SELECT USERID FROM UserManagement.tblhealthbuddy WHERE IsSSPLOwned = 1 )
UNION ALL
SELECT O.CustUserId,O.OrderId,O.HBId, 'Reversal' AS TransactionType
,tbl.RetDate, 'Sales Return' AS Comment
,0 AS SSCurrency
,(Case When (inv.InvoiceVal + ( CASE WHEN sph.IsPartnerShip = 1  THEN 0.00 ELSE ISNULL(inv.CouponDiscount,0.00) END) + ISNULL(inv.PromoDiscount,0.00)) > 0 Then 
((CONVERT(numeric(10,2),((( CASE WHEN sph.IsPartnerShip = 1  THEN 0.00 ELSE ISNULL(inv.CouponDiscount,0.00) END) + ISNULL(inv.PromoDiscount,0.00))
/(inv.InvoiceVal + ( CASE WHEN sph.IsPartnerShip = 1  THEN 0.00 ELSE ISNULL(inv.CouponDiscount,0.00) END) + ISNULL(inv.PromoDiscount,0.00))
)*(SalesReturnGrossAmt -	(ISNULL(SalesReturnCashDiscount,0.00) + ISNULL(SalesReturnCouponDiscount,0.00) + ISNULL(SalesReturnSSCurrencyValue,0.00))))))
ELSE 0.00 END)  AS ItemDisc
FROM Orders.tblInvoice inv with(nolock)
inner join Orders.tblOrder O with(nolock) On inv.OrderId = O.OrderId
INNER JOIN (
SELECT sr.InvoiceId,RetDate,InvoiceNo,ISNULL(SalesReturnGrossAmt,0) AS SalesReturnGrossAmt
,ISNULL(SalesReturnCashDiscount,0) AS SalesReturnCashDiscount
,ISNULL(SalesReturnCouponDiscount,0) AS SalesReturnCouponDiscount
,ISNULL(SalesReturnSSCurrencyValue,0) AS SalesReturnSSCurrencyValue
FROM 
(
SELECT s.InvoiceId,CONVERT(date,si.UpdatedDate) AS RetDate ,CONVERT(varchar(8),i.InvoiceDate,112) AS InvoiceNo
,SUM(ii.ItemBasePrice*si.AcceptedQty) AS SalesReturnGrossAmt
,SUM(ISNULL(CONVERT(numeric(10,2),(ii.ItemDiscount*si.AcceptedQty)/ItemQuantity),0)) AS SalesReturnCashDiscount --check si.ItemDiscount/si.AcceptedQty
,SUM(ISNULL(CONVERT(numeric(10,2),(ii.CouponDiscount*si.AcceptedQty)/ItemQuantity),0)) AS SalesReturnCouponDiscount
,SUM(ISNULL(CONVERT(numeric(10,2),(ii.SSCurrencyValue*si.AcceptedQty)/ItemQuantity),0)) AS SalesReturnSSCurrencyValue
FROM Orders.tblSalesReturn s with(nolock)
INNER JOIN Orders.tblSalesReturnItem si with(nolock) on s.SalesReturnId = si.SalesReturnId
INNER JOIN  Orders.tblInvoiceItem ii with(nolock) on si.InvoiceItemId = ii.InvoiceItemId
INNER JOIN Orders.tblInvoice i with(nolock) on ii.InvoiceId = i.InvoiceId
WHERE si.SalesReturnStatusId = 6  
and CONVERT(date,si.UpdatedDate) >= @pStartDate And CONVERT(date,si.UpdatedDate) <= @pEndDate
and si.SalesReturnStatusId = 6 --AND si.IntegrationId IS NOT  NULL
--AND CONVERT(date,I.InvoicePrintingDate) >= @pStartDate AND CONVERT(date,I.InvoicePrintingDate) <= @pEndDate --Commented on 21.06.2022
and i.InvoiceNo <> 'Not Assigned'
GROUP BY s.InvoiceId,CONVERT(date,si.UpdatedDate) ,CONVERT(varchar(8),i.InvoiceDate,112)
) sr
) tbl on inv.InvoiceId = tbl.InvoiceId

LEFT JOIN 
(
--SELECT OrderId, MAX(IsPartnerShip) AS IsPartnerShip
--FROM (
SELECT o.OrderId,
p.IsPartnerShipCoupon AS IsPartnerShip

FROM Orders.tblOrder o with(nolock)
INNER JOIN Orders.tblInvoice i with(nolock) on o.OrderId = i.OrderId
INNER JOIN UserManagement.tblHealthBuddy h on o.HBId = h.UserId
INNER JOIN UserManagement.tblCouponPartnershipHB sph on o.HBId = sph.HBId
INNER JOIN Promotion.tblPromotion p with(nolock) on o.CouponPromoId = p.PromoId
WHERE CONVERT(date,i.InvoicePrintingDate) >=@pStartDate
AND CONVERT(date,i.InvoicePrintingDate) <=@pEndDate
AND o.IntegrationId IS NOT NULL
AND (o.OrderDate>= sph.StartDate AND o.OrderDate <= ISNULL(sph.EndDate,GETDATE()))
and o.OrderStatusId NOT IN (8,9)
AND i.InvoiceNo != 'Not Assigned'
AND sph.IsActive = 1
and CONVERT(date,I.InvoiceDate) > '07/31/2017'
--) tbl
--GROUP BY OrderId
) sph on o.OrderId= sph.OrderId

)tbl
UNION ALL
SELECT  *
FROM (
select O.CustUserId,O.OrderId,O.HBId, 'Reversal' AS TransactionType
,CONVERT(date,R.UpdatedDate) AS RetDate, 'Sales Return' AS Comment
,ISNULL(CONVERT(numeric(10,2),(ii.SSCurrencyValue*R.AcceptedQty)/ItemQuantity),0) AS SSCurrencyValue
,ISNULL(CONVERT(numeric(10,2),(ii.CouponDiscount*R.AcceptedQty)/ItemQuantity),0)  AS CouponPromoDiscount
from Orders.tblSalesReturnItem R with(nolock)
inner join Orders.tblInvoiceItem II with(nolock) on II.InvoiceItemId =R.InvoiceItemId
inner join Orders.tblInvoice I with(nolock) On II.InvoiceId = I.InvoiceId
inner join Orders.tblOrder O with(nolock) On I.OrderId = O.OrderId
Where CONVERT(date,I.InvoiceDate) >= '07/01/2017' And  CONVERT(date,I.InvoiceDate) <= '07/31/2017'
and CONVERT(date,R.UpdatedDate) >= @pStartDate And CONVERT(date,R.UpdatedDate) <= @pEndDate
and R.SalesReturnStatusId = 6 --AND R.IntegrationId IS NOT  NULL --and i.hbid in  (SELECT USERID FROM UserManagement.tblhealthbuddy WHERE IsSSPLOwned = 1 )
UNION ALL
SELECT O.CustUserId,O.OrderId,O.HBId, 'Reversal' AS TransactionType
,tbl.RetDate, 'Sales Return' AS Comment
,0 AS SSCurrency
,(Case When (inv.InvoiceVal + ISNULL(inv.CouponDiscount,0.00) + ISNULL(inv.PromoDiscount,0.00)) > 0 Then 
((CONVERT(numeric(10,2),((ISNULL(inv.CouponDiscount,0.00) + ISNULL(inv.PromoDiscount,0.00))
/(inv.InvoiceVal + ISNULL(inv.CouponDiscount,0.00) + ISNULL(inv.PromoDiscount,0.00))
)*(SalesReturnGrossAmt -	(ISNULL(SalesReturnCashDiscount,0.00) + ISNULL(SalesReturnCouponDiscount,0.00) + ISNULL(SalesReturnSSCurrencyValue,0.00))))))
ELSE 0.00 END)  AS ItemDisc
FROM Orders.tblInvoice inv with(nolock)
inner join Orders.tblOrder O with(nolock) On inv.OrderId = O.OrderId
INNER JOIN (
SELECT sr.InvoiceId,RetDate,InvoiceNo,ISNULL(SalesReturnGrossAmt,0) AS SalesReturnGrossAmt
,ISNULL(SalesReturnCashDiscount,0) AS SalesReturnCashDiscount
,ISNULL(SalesReturnCouponDiscount,0) AS SalesReturnCouponDiscount
,ISNULL(SalesReturnSSCurrencyValue,0) AS SalesReturnSSCurrencyValue
FROM 
(
SELECT s.InvoiceId,CONVERT(date,si.UpdatedDate) AS RetDate ,CONVERT(varchar(8),i.InvoiceDate,112) AS InvoiceNo
,SUM(ii.ItemBasePrice*si.AcceptedQty) AS SalesReturnGrossAmt
,SUM(ISNULL(CONVERT(numeric(10,2),(ii.ItemDiscount*si.AcceptedQty)/ItemQuantity),0)) AS SalesReturnCashDiscount --check si.ItemDiscount/si.AcceptedQty
,SUM(ISNULL(CONVERT(numeric(10,2),(ii.CouponDiscount*si.AcceptedQty)/ItemQuantity),0)) AS SalesReturnCouponDiscount
,SUM(ISNULL(CONVERT(numeric(10,2),(ii.SSCurrencyValue*si.AcceptedQty)/ItemQuantity),0)) AS SalesReturnSSCurrencyValue
FROM Orders.tblSalesReturn s with(nolock)
INNER JOIN Orders.tblSalesReturnItem si with(nolock) on s.SalesReturnId = si.SalesReturnId
INNER JOIN  Orders.tblInvoiceItem ii with(nolock) on si.InvoiceItemId = ii.InvoiceItemId
INNER JOIN Orders.tblInvoice i with(nolock) on ii.InvoiceId = i.InvoiceId
WHERE si.SalesReturnStatusId = 6  
and CONVERT(date,si.UpdatedDate) >= @pStartDate And CONVERT(date,si.UpdatedDate) <= @pEndDate
and si.SalesReturnStatusId = 6 --AND si.IntegrationId IS NOT  NULL
AND CONVERT(date,I.InvoiceDate) >= '07/01/2017' AND CONVERT(date,I.InvoiceDate) <= '07/31/2017'
GROUP BY s.InvoiceId,CONVERT(date,si.UpdatedDate) ,CONVERT(varchar(8),i.InvoiceDate,112)
) sr
) tbl on inv.InvoiceId = tbl.InvoiceId
)tbl
) tblout
order by TransactionDate


--6 (30 sec, 747k rows)

select p.ProductId,OI.ParentWarehouseId AS WarehouseId,ISNULL(OI.TotalOrderqty,0) as SaleQuantity,ISNULL(oi.OrderCount,0) AS OrderCount
from  Catalog.tblproduct P WITH(NOLOCK)
INNER JOIN Reports.tblSoldandAvailableQty tbl on P.ProductId = tbl.ProductID
left join (
select distinct OS.ProductId,prr.ParentWarehouseId,SUM(itemquantity) as TotalOrderqty,COUNT(Distinct o.OrderId) AS OrderCount 
from Reports.tblSoldandAvailableQty prr
Inner join Orders.tblOrderItem OS WITH(NOLOCK) on OS.ProductId =prr.ProductID
inner join	orders.tblorder O WITH(NOLOCK)	on OS.Orderid=O.OrderId
----inner join orders.tblinvoice i with(nolock) on o.OrderId= i.orderid
INNER JOIN SiteManagement.tblWarehouse ws on o.WarehouseId = ws.WarehouseId
--inner join Orders.tblInvoice I WITH(NOLOCK) on O.OrderId=I.OrderId
where OS.PKLotId is not null and O.OrderStatusId  in (1,2,3,4,5,6,7,10,11,12,13,14,15)
and convert(date,o.ConfirmationDate) >=DATEADD(DD,-30,CONVERT(date,Getdate())) 
and convert(date,o.ConfirmationDate) < CONVERT(date,Getdate())			
AND ws.ParentWarehouseId=prr.ParentWarehouseId
group by OS.ProductId,prr.ParentWarehouseId
) OI on OI.ProductId=P.ProductId AND tbl.ParentWarehouseId = OI.ParentWarehouseId


--7 (7 sec, 490 rows)

SELECT c.HealthBuddyId AS HBId
,COUNT(1) AS PendingEmailVerified 
FROM UserManagement.tblUser u with(nolock)
INNER join UserManagement.tblCustomer c with(nolock) on u.UserId = c.UserId
WHERE ISNULL(IsEmailVerified,0) = 0 
GROUP BY c.HealthBuddyId


--8 (14 sec, 700 rows)

SELECT tbl1.HBId
,CASE WHEN 5 - CEILING((NumOrders)*ISNULL(hb.GracePercentPendingDelivery,10.00)/100.00) < 0 THEN CEILING((NumOrders)*ISNULL(hb.GracePercentPendingDelivery,10.00)/100.00) ELSE 5 END   AS PendingDeliveryCNTVal
FROM
(
SELECT O.HBId,COUNT(1) AS NumOrders FROM Orders.tblOrder O WITH(NOLOCK)
INNER JOIN
(
SELECT OS.OrderId,MAX(CONVERT(date,OS.UpdatedDate)) AS ReceivedDate FROM Orders.tblOrderStatusHistory OS WITH(NOLOCK)
WHERE OS.OrderStatusId = 4
GROUP BY OS.OrderId
--HAVING MAX(CONVERT(date,OS.UpdatedDate)) = @vDT
) tbl on O.OrderId = tbl.OrderId
GROUP BY O.HBId
) tbl1
INNER JOIN UserManagement.tblHealthBuddy hb on tbl1.HBId = hb.UserId


--9 (30 sec, 750k rows)

SELECT WH.ParentWarehouseId AS WarehouseId,ProductId
FROM Orders.tblOrderItem OI WITH (NOLOCK)
INNER JOIN Orders.tblOrder O WITH (NOLOCK) On OI.OrderId = O.OrderId
INNER JOIN SiteManagement.tblWarehouse WH ON ISNULL(O.WarehouseId, 1) = WH.WarehouseId
UNION
SELECT distinct W.ParentWarehouseId AS WarehouseId,P.ProductId
FROM Catalog.tblProduct P WITH(NOLOCK)
CROSS JOIN SiteManagement.tblWarehouse W with(nolock)
WHERE P.SourceProductId IS NOT NULL


--10 (6 sec, 13k rows)

SELECT DISTINCT o.OrderId,CONVERT(DATE,DeliveryDate) AS DeliveryDate,CourierCompMasId 
FROM  Orders.tblOrder o WITH (NOLOCK)
	INNER JOIN UserManagement.tblHealthBuddy hb on o.HBId=hb.UserId
INNER JOIN
(
SELECT OrderId ,MAX(UpdatedDate) AS DeliveryDate FROM [Orders].tblOrderStatusHistory WHERE OrderStatusId =5
GROUP BY OrderId
)dl on o.OrderId =dl.OrderId
WHERE CONVERT(DATE,DeliveryDate) = CONVERT(DATE,DATEADD(DD,-1,GETDATE()))
AND hb.CourierCategory IS NOT NULL AND o.OrderStatusId =5
and CONVERT(DATE,DeliveryDate)>= '02/01/2022'


--11 (30 sec, 747k rows)

select p.ProductId,OI.ParentWarehouseId AS WarehouseId,ISNULL(OI.TotalOrderqty,0) as SaleQuantity,ISNULL(oi.OrderCount,0) AS OrderCount
from  Catalog.tblproduct P WITH(NOLOCK)
INNER JOIN Reports.tblSoldandAvailableQty tbl on P.ProductId = tbl.ProductID
left join (
select distinct OS.ProductId,prr.ParentWarehouseId,SUM(itemquantity) as TotalOrderqty,COUNT(Distinct o.OrderId) AS OrderCount 
from Reports.tblSoldandAvailableQty prr
Inner join Orders.tblOrderItem OS WITH(NOLOCK) on OS.ProductId =prr.ProductID
inner join	orders.tblorder O WITH(NOLOCK)	on OS.Orderid=O.OrderId
----inner join orders.tblinvoice i with(nolock) on o.OrderId= i.orderid
INNER JOIN SiteManagement.tblWarehouse ws on o.WarehouseId = ws.WarehouseId
--inner join Orders.tblInvoice I WITH(NOLOCK) on O.OrderId=I.OrderId
where OS.PKLotId is not null and O.OrderStatusId  in (1,2,3,4,5,6,7,10,11,12,13,14,15)
and convert(date,o.ConfirmationDate) >=DATEADD(DD,-15,CONVERT(date,Getdate())) 
and convert(date,o.ConfirmationDate) < CONVERT(date,Getdate())			
AND ws.ParentWarehouseId=prr.ParentWarehouseId
group by OS.ProductId,prr.ParentWarehouseId
) OI on OI.ProductId=P.ProductId AND tbl.ParentWarehouseId = OI.ParentWarehouseId


--12 (1:12 sec, 76k rows)

declare @pStartDate datetime 
declare @pEndDate datetime 
set @pStartDate= DATEADD(day,-2,GETDATE())
set @pEndDate=GETDATE()
SELECT o.OrderId,i.InvoiceId,i.IsInterState,CONVERT(date,i.InvoicePrintingDate),i.HBId,
(( CASE WHEN sph.IsPartnerShip = 1  THEN 0.00 
ELSE ISNULL(o.CouponDiscount,0) END) + ISNULL(o.PromoDiscount,0))
,(ISNULL(ISNULL(o.ShippingCharge,o.CourierCharge),0.00))
,(ISNULL(i.SGSTShippingValue,0)) AS ShippingSGSTValue
,(ISNULL(i.CGSTShippingValue,0)) AS ShippingCGSTValue
,(ISNULL(i.IGSTShippingValue,0)) AS ShippingIGSTValue
,CASE WHEN sph.IsPartnerShip = 1  THEN ISNULL(o.CouponDiscount,0)*(sph.SSDiscprovide) ELSE 0.00 END
,ISNULL(i.TotalCessValue,0) AS CessVal
,CASE WHEN ISNULL(DiscPercent,0.00)> = 0.00 THEN  CONVERT(NUMERIC(10,2),(o.BankDisc*DiscPercent)/100.00) ELSE o.BankDisc END AS BankDisc
FROM Orders.tblOrder o with(nolock)
INNER JOIN Orders.tblInvoice i with(nolock) on o.OrderId = i.OrderId
LEFT JOIN (SELECT DISTINCT BankOfferId ,HBId,DiscPercent FROM [UserManagement].[tblHBBankDiscPercentageConfig] WHERE IsActive=1) bno on i.HBId = bno.HBId AND o.OfferId = bno.BankOfferId

LEFT JOIN 
(
--SELECT OrderId, MAX(IsPartnerShip) AS IsPartnerShip
--FROM (
SELECT o.OrderId,
ISNULL(p.IsPartnerShipCoupon,0) AS IsPartnerShip
,p.SSDiscprovide
FROM Orders.tblOrder o with(nolock)
INNER JOIN Orders.tblInvoice i with(nolock) on o.OrderId = i.OrderId
INNER JOIN UserManagement.tblHealthBuddy h on o.HBId = h.UserId
--INNER JOIN UserManagement.tblCouponPartnershipHB sph on o.HBId = sph.HBId
INNER JOIN Promotion.tblPromotion p on o.CouponPromoId = p.PromoId
WHERE CONVERT(date,i.InvoicePrintingDate) >=@pStartDate
AND CONVERT(date,i.InvoicePrintingDate) <=@pEndDate
----AND (o.OrderDate>= sph.StartDate AND o.OrderDate <= ISNULL(sph.EndDate,@pStartDate))
AND o.IntegrationId IS NOT NULL
and o.OrderStatusId NOT IN (8,9)
AND i.InvoiceNo != 'Not Assigned'
AND ISNULL(p.IsPartnerShipCoupon,0) = 1
AND CONVERT(date,i.InvoicePrintingDate)>=convert(date,DATEADD(DD,-5,@pStartDate))
and CONVERT(date,I.InvoiceDate) > '07/31/2017'
--) tbl
--GROUP BY OrderId
) sph on o.OrderId= sph.OrderId
WHERE CONVERT(date,i.InvoicePrintingDate) >=@pStartDate
AND CONVERT(date,i.InvoicePrintingDate) <=@pEndDate
AND o.IntegrationId IS NOT NULL
and o.OrderStatusId NOT IN (8,9)
AND i.InvoiceNo != 'Not Assigned'
and CONVERT(date,I.InvoiceDate) > '07/31/2017'
AND CONVERT(date,i.InvoicePrintingDate)>=convert(date,DATEADD(DD,-5,@pStartDate))


--13

SELECT TOP 1000 * FROM (
SELECT ROW_NUMBER() OVER(ORDER BY GCMRegId ASC) AS RN, * 
FROM [SiteManagement].[tblMobileAppGCMReg]
WHERE IsActive=1 AND IsUnInstallApp IS NULL AND AppVersion<= '4.0.4'
AND ISNULL(AppType,'N') IN ('N','A') AND DeviceCode IN (SELECT DISTINCT DeviceCode FROM [SiteManagement].[tblDeviceSpcPushNotificationForAndroid] WHERE ISNULL(IsDeleted,0) = 0) 
) tbl


--14 (35 sec, 892k rows)

SELECT CustUserId,COUNT(1) as SalesReturnTotal,iv.HBId
FROM Orders.tblSalesReturn sr (nolock)
INNER JOIN Orders.tblInvoice iv (nolock) ON sr.InvoiceId=iv.InvoiceId
GROUP BY iv.CustUserId,iV.HBId


--15

Select distinct o.custuserid
from usermanagement.tblcustomer c with(nolock)
inner join orders.tblorder o with(nolock) on c.firstorderid = o.orderid
where o.orderstatusid in (8,9)


--16 (30 sec, 747k rows)

select p.ProductId,OI.ParentWarehouseId AS WarehouseId,ISNULL(OI.TotalOrderqty,0) as SaleQuantity,ISNULL(oi.OrderCount,0) AS OrderCount
from  Catalog.tblproduct P WITH(NOLOCK)
INNER JOIN Reports.tblSoldandAvailableQty tbl on P.ProductId = tbl.ProductID
left join (
select distinct OS.ProductId,prr.ParentWarehouseId,SUM(itemquantity) as TotalOrderqty,COUNT(Distinct o.OrderId) AS OrderCount 
from Reports.tblSoldandAvailableQty prr
Inner join Orders.tblOrderItem OS WITH(NOLOCK) on OS.ProductId =prr.ProductID
inner join	orders.tblorder O WITH(NOLOCK)	on OS.Orderid=O.OrderId
----inner join orders.tblinvoice i with(nolock) on o.OrderId= i.orderid
INNER JOIN SiteManagement.tblWarehouse ws on o.WarehouseId = ws.WarehouseId
--inner join Orders.tblInvoice I WITH(NOLOCK) on O.OrderId=I.OrderId
where OS.PKLotId is not null and O.OrderStatusId  in (1,2,3,4,5,6,7,10,11,12,13,14,15)
and convert(date,o.ConfirmationDate) >=DATEADD(DD,-7,CONVERT(date,Getdate())) 
and convert(date,o.ConfirmationDate) < CONVERT(date,Getdate())			
AND ws.ParentWarehouseId=prr.ParentWarehouseId
group by OS.ProductId,prr.ParentWarehouseId
) OI on OI.ProductId=P.ProductId AND tbl.ParentWarehouseId = OI.ParentWarehouseId


--17 

SELECT DISTINCT p.ProductId,pl.ShelfNo,SourceProductId,pl.ProductStatus,replace(replace(p.Attributes , char(10), ''), char(13), '') AS Attributes
, ISNULL(pl.WarehouseId,1),s.PrescriptionOTC,p.DisplayName,p.MfgGroup,ws.ParentWarehouseId
,0,GETDATE(),pl.StockLocationWHId
FROM Catalog.tblProduct p with(nolock)
INNER JOIN Catalog.tblSalt s with(nolock) on p.SaltId =s.SaltId 
INNER JOIN Catalog.tblProductLocation pl with(nolock) ON  p.ProductId=pl.ProductId  
INNER JOIN SiteManagement.tblWarehouse ws on pl.WarehouseId =ws.WarehouseId
WHERE ws.ParentWarehouseId =ws.WarehouseId
AND p.SourceProductId is not null and P.SaltId is not null


