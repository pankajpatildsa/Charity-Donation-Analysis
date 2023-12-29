## Basic information

SELECT count(*) FROM acts
where ActType like 'PA';

SELECT count(*) from (
SELECT *
FROM acts
GROUP BY ContactId) as aa;

SELECT ContactId ,count(*) from acts
GROUP BY ContactId
ORDER BY 2 DESC ;

SELECT *,count(*),sum(Amount) from acts
WHERE ContactId = 68190
GROUP BY ActType;

SELECT * from contacts
WHERE ContactId = 68190;

SELECT ActType,sum(Amount) from acts
GROUP BY ActType;

SELECT a.ContactId,c.ZipCode,c.Prefix,c.FirstName,a.ActType,sum(Amount),count(*) from acts as a
LEFT JOIN contacts as c
  on a.ContactId = c.ContactId
  where ActType like 'DO'
GROUP BY a.ContactId;


##==================================================================================================##
## Which parts of France are more generous?

SELECT dpt, count(*) as total_times, avg(Amount) as avg_amount from (
SELECT c.ContactId                   AS id,
        a.ActType As type,
        a.Amount as Amount,
       LEFT(ANY_VALUE(c.ZipCode), 2) AS dpt
FROM contacts AS c
LEFT JOIN acts AS a
ON c.ContactId = a.ContactId
WHERE a.ActType like 'DO') as aa
GROUP BY dpt
ORDER BY avg_amount DESC;

SELECT dpt, count(*) as total_times, avg(Amount) as avg_amount from (
SELECT c.ContactId                   AS id,
        a.ActType As type,
        a.Amount as Amount,
       LEFT(ANY_VALUE(c.ZipCode), 2) AS dpt
FROM contacts AS c
LEFT JOIN acts AS a
ON c.ContactId = a.ContactId
WHERE a.ActType like 'PA') as aa
GROUP BY dpt
ORDER BY avg_amount DESC;

##==================================================================================================##
## Which months do people prefer to donate
SELECT Amount,PaymentType, month(ActDate) as month,
  year(ActDate) as year, date_format(ActDate,'%Y%m')as ym,sum(Amount)as total_money,
  count(Sq) as total_doner
from acts
WHERE ActType LIKE 'PA'
GROUP BY ym
ORDER BY ym;