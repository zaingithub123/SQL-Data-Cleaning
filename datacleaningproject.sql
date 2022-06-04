
/*Cleaning Data*/


-------------------------------------standardise date format------------------------------------------------------------------------

alter table project..HousingDataCleaning  
add SaleDateConverted Date; -- added a new column called saledateconverted with date format

update project..HousingDataCleaning
set SaleDateConverted = CONVERT(Date,SaleDate) -- converts the original saledate column to date format

select SaleDateConverted
from project..HousingDataCleaning

-------------------------------------------populate address----------------------------------------------------------------
-- fill in the null column for property address

select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress) -- ISNULL saying if a.propaddress is null, then replace it with data in b.propaddress
from project..HousingDataCleaning a
join project..HousingDataCleaning b    -- self join tables
on a.ParcelID = b.ParcelID    
and a.[UniqueID ] <> b.[UniqueID ]  
where a.PropertyAddress is not null

update a
set PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
from project..HousingDataCleaning a
join project..HousingDataCleaning b    -- self join tables
on a.ParcelID = b.ParcelID    
and a.[UniqueID ] <> b.[UniqueID ]  
where a.PropertyAddress is null

-- when you run below, it will display data and there is no null data inside the property address
 
select *
from project..HousingDataCleaning
where propertyaddress is not null

-------------------Breaking down address into separate columns (Address,City,State) USING SUBSTRING----------------------------------------------------------------------

select PropertyAddress
from project..HousingDataCleaning

select 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',' , PropertyAddress) -1) as address,
-- substring and select the column (propertyaddress), start at position 1, goes until the comma(using charindex-searches for specific value), looking in propertyaddress
-- -1 to remove the comma because without this, it results in data and comma.
SUBSTRING(PropertyAddress, CHARINDEX(',' , PropertyAddress) +1, len(PropertyAddress)) as address
-- no need to have a starting position, +1 because we want to go ahead of the comma, this will display the next set of data
--len(property address) - specifies where it finishes and len used as address has different lengths
from project..HousingDataCleaning

-- updating the table with separate address columns
alter table project..HousingDataCleaning
add PropertySplitAddress nvarchar(255);

update project..HousingDataCleaning
set PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',' , PropertyAddress) -1)

alter table project..HousingDataCleaning
add PropertySplitCity nvarchar(255);

update project..HousingDataCleaning
set PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',' , PropertyAddress) +1, len(PropertyAddress)) 

select *
from project..HousingDataCleaning


--------------------------------ALTERNATIVE METHOD THROUGH PARSENAME( SPLITING OWNER ADDRESS)-----------------------------------------
-- it replaces the comma and changes it to a full stop

select OwnerAddress
from project..HousingDataCleaning

select 
PARSENAME(REPLACE(OwnerAddress, ',' , '.') , 1) as state,
PARSENAME(REPLACE(OwnerAddress, ',' , '.') , 2) as city,
PARSENAME(REPLACE(OwnerAddress, ',' , '.') , 3) as address
from project..HousingDataCleaning

--parsename computed the query backwards however it still performs correct output, breaks data in columns.

alter table project..HousingDataCleaning
add OwnerSplitState nvarchar(255);

update project..HousingDataCleaning
set OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',' , '.') , 1)


alter table project..HousingDataCleaning
add OwnerSplitCity nvarchar(255);

update project..HousingDataCleaning 
set OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',' , '.') , 2)


alter table project..HousingDataCleaning
add OwnerSplitAddress nvarchar(255);

update project..HousingDataCleaning
set OwnerSplitAddress= PARSENAME(REPLACE(OwnerAddress, ',' , '.') , 3)


select *
from project..HousingDataCleaning


-----------------------------------Changing Y AND N to YES and No in 'Sold as Vacant' field---------------------------------------------------------------

select SoldAsVacant,
CASE 
WHEN SoldAsVacant = 'Y' THEN 'Yes'
WHEN SoldAsVacant = 'N' THEN 'No'
else SoldAsVacant
End
from project..HousingDataCleaning

update project..HousingDataCleaning
set SoldAsVacant =
CASE 
WHEN SoldAsVacant = 'Y' THEN 'Yes'
WHEN SoldAsVacant = 'N' THEN 'No'
else SoldAsVacant
End

select distinct(SoldAsVacant)
from project..HousingDataCleaning

-------------------------------------------REMOVING DUPLICATES----------------------------------------------------------------------------


WITH DupDataCTE AS(   -- cte created 
select *,
row_number() over (
partition by ParcelID,  --partitioning by columns with duplicate data
PropertyAddress,
SalePrice,
SaleDate,
LegalReference
order by uniqueid) dupdata --order it by a unique column


from project..HousingDataCleaning
)
DELETE               -- delete statement to delete duplicate files
from DupDataCTE      -- calling cte
WHERE dupdata  > 1  -- dupdata column that displays greater than 1 are duplicates

-- checking to see if duplicates have been deleted

WITH DupDataCTE AS(
select *,
row_number() over (
partition by ParcelID,  
PropertyAddress,
SalePrice,
SaleDate,
LegalReference
order by uniqueid) dupdata 

from project..HousingDataCleaning
)
select *            
from DupDataCTE
WHERE dupdata  > 1 

-------------------------------------------DELETING UNUSED COLUMNS------------------------------------------------

ALTER TABLE project..HousingDataCleaning
drop column PropertyAddress, SaleDate, OwnerAddress, TaxDistrict

select *
from project..HousingDataCleaning