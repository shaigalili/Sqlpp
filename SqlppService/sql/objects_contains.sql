
SELECT  schemas.name + '.' + (objects.name) as oname 
FROM sys.objects
inner join sys.schemas
on schemas.schema_id=objects.schema_id
where exists (select top 1 1 from syscomments
			where syscomments.id=objects.object_id
			and	syscomments.text like '%$like%')
order by oname
