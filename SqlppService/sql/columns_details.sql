

declare @tbl varchar(100)
set @tbl= '$table'


select schemas.name as [schema]
		,objects.name as [table]
		,columns.name  as col
		,case when columns.is_nullable=1 then 1 else 0 end as is_nullable
		,case when columns.is_identity=1 then 1 else 0 end as is_identity
		,case when exists (
				SELECT 1 FROM sys.indexes ind
				INNER JOIN sys.index_columns indcol
				ON ind.index_id = indcol.index_id
				AND ind.object_id = indcol.object_id
				AND columns.column_id = indcol.column_id
				WHERE ind.object_id = columns.object_id
				AND ind.is_primary_key =  1 
				) then 1 else 0 end as is_primary
		,defaults.definition as [default]
		,ref_schemas.name as ref_schema
		,ref_objects.name as ref_table
		, fcolumns.name as refNameCol
		,desc_columns.name  as refDesc
		,columns_types.name as type_name
		 ,columns_types.name +
                  case when columns_types.name='numeric'
					 or columns_types.name='decimal'
					 or columns_types.name='money' then '(' + cast(columns.PRECISION as varchar(10)) + ',' + cast(columns.SCALE as varchar(10)) + ')'
                  when columns_types.name='varchar' 
					or columns_types.name='varbinary'
					or columns_types.name='char' 
					or columns_types.name='nvarchar' 
					or columns_types.name='nchar'  then '(' +
							case when columns.MAX_LENGTH<0 then 'max' 
							else  cast(columns.MAX_LENGTH as varchar(10))  end + ')'
                  else '' end  as data_type
		 ,ref_types.name +
                  case when ref_types.name='numeric'
					 or ref_types.name='decimal'
					 or ref_types.name='money' then '(' + cast(desc_columns.PRECISION as varchar(10)) + ',' + cast(columns.SCALE as varchar(10)) + ')'
                  when ref_types.name='varchar' 
					or ref_types.name='varbinary'
					or ref_types.name='char' 
					or ref_types.name='nvarchar' 
					or ref_types.name='nchar'  then '(' +
							case when desc_columns.MAX_LENGTH<0 then 'max' 
							else  cast(desc_columns.MAX_LENGTH as varchar(10))  end + ')'
                  else '' end  as ref_type
            ,case columns_types.name
                  when 'smallint' then 'short'
                  when 'tinyint' then 'short'
                  when 'numeric' then 'int'
                  when 'money' then 'decimal'
                  when 'bigint' then 'long'
                  when 'xml' then 'XmlDocument'
                  when 'varchar' then 'string'
                  when 'nvarchar' then 'string'
                  when 'bit' then 'bool'
                  when 'datetime' then 'DateTime'
                  when 'smalldatetime' then 'DateTime'
                  else columns_types.name
            end  as cs_type
		
 FROM sys.columns as columns
inner JOIN sys.objects AS objects 
   ON columns.object_id = objects.object_id 
inner JOIN sys.schemas AS schemas 
   ON objects.schema_id = schemas.schema_id 
left JOIN sys.types AS columns_types 
   ON columns.user_type_id = columns_types.user_type_id 
left JOIN sys.foreign_key_columns AS fkc 
   ON columns.column_id = fkc.parent_column_id 
   and columns.object_id =  fkc.parent_object_id 
left JOIN sys.columns AS fcolumns
   ON fcolumns.column_id = fkc.referenced_column_id 
   and fcolumns.object_id = fkc.referenced_object_id 
left JOIN sys.objects AS ref_objects
   ON ref_objects.object_id =  fcolumns.object_id 
left JOIN sys.schemas AS ref_schemas
   ON ref_schemas.schema_id =  ref_objects.schema_id 
left JOIN sys.default_constraints AS defaults
   ON columns.column_id = defaults.parent_column_id 
   and columns.object_id =  defaults.parent_object_id 
left join sys.columns  as desc_columns
   ON desc_columns.object_id = fcolumns.object_id 
	and desc_columns.column_id in
	(select top 1 top_desc.column_id from sys.columns as top_desc
				where top_desc.object_id = fcolumns.object_id
				order by case when top_desc.name like '%name%'  then 1
				when top_desc.name  like '%desc%' then 2
				when top_desc.name  like '%value%' then 3 else 4 end )
left JOIN sys.types AS ref_types 
   ON desc_columns.user_type_id = ref_types.user_type_id 
where lower(objects.name)=lower(@tbl)
order by is_primary desc,ref_table desc,col
for xml raw,root