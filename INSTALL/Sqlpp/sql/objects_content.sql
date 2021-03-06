SELECT c.text
from sys.objects AS objects 
inner JOIN syscomments as c
on c.id=objects.object_id 
inner JOIN sys.schemas AS schemas
ON objects.schema_id = schemas.schema_id 
where lower(schemas.name)+'.'+lower(objects.name)=lower(@name)
ORDER BY c.colid
