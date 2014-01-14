select OBJECT_NAME(parent_object_id)
as table_name, name 
from sys.check_constraints
where is_not_trusted = 1;
-- HAMMERORA GO
