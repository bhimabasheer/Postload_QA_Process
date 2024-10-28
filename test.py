import pandas as pd
import os
from urllib.parse import quote_plus
from sqlalchemy.orm import Session,sessionmaker,declarative_base
from sqlalchemy import select,Integer,VARCHAR,Column,BIGINT,create_engine,Identity,text,MetaData,Table


connection_string = (
'Driver={ODBC Driver 17 For SQL Server};'
'SERVER=standoutresearch.cmgm5ibackyh.us-east-2.rds.amazonaws.com;'
'Database=Data_Load;'
'UID=Bbeema;'
'PWD=Sits@2023;'
'Trusted_Connection=no;'
)

connection_uri = f"mssql+pyodbc:///?odbc_connect={quote_plus(connection_string)}"

engine = create_engine(connection_uri, fast_executemany=True)

connection=engine.connect()


table_name = 'Postload_QA_Details'

metadata = MetaData()
table = Table(table_name, metadata, autoload_with=engine)

columns = table.columns.keys()

for column_name in columns:
    column_type = table.c[column_name].type

    if not issubclass(column_type.python_type, (int, float)):
        continue
    if column_name != 'IssueID':
        query = table.select().where(table.c[column_name] == 1 )
        
        result = connection.execute(query).fetchall()
        try:
            if result:
                print(f"Column '{column_name}' has at least one row with the value 1.")
        except Exception as e:
            print(f"Error processing column '{column_name}': {e}")

connection.close()

print('Done')

