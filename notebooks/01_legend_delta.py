# Databricks notebook source
# MAGIC %md
# MAGIC <img src=https://d1r5llqwmkrl74.cloudfront.net/notebooks/fsi/fs-lakehouse-logo-transparent.png width="600px">
# MAGIC 
# MAGIC [![DBR](https://img.shields.io/badge/DBR-10.4-red?logo=databricks&style=for-the-badge)](https://docs.databricks.com/release-notes/runtime/10.4.html)
# MAGIC [![CLOUD](https://img.shields.io/badge/CLOUD-ALL-blue?logo=googlecloud&style=for-the-badge)](https://cloud.google.com/databricks)
# MAGIC [![POC](https://img.shields.io/badge/POC-10_days-green?style=for-the-badge)](https://databricks.com/try-databricks)
# MAGIC [![Maven Central](https://img.shields.io/maven-central/v/org.finos.legend-community/legend-delta.svg?style=for-the-badge)](http://search.maven.org/#search%7Cga%7C1%7Ca%3A%22legend-delta)
# MAGIC 
# MAGIC *In addition to the JDBC connectivity enabled to Databricks from the legend-engine itself, this project helps 
# MAGIC organizations define data models that can be converted into efficient data pipelines, ensuring data being queried 
# MAGIC is of high quality and availability. Raw data can be ingested as stream or batch and processed in line with the 
# MAGIC business semantics defined from the Legend interface. Domain specific language defined in Legend Studio can be 
# MAGIC interpreted as a series of Spark SQL operations, helping analysts create Delta Lake tables that not only guarantees 
# MAGIC schema definition but also complies with expectations, derivations and constraints defined by business analysts.*
# MAGIC 
# MAGIC ___
# MAGIC <antoine.amend@databricks.com>
# MAGIC 
# MAGIC ___
# MAGIC 
# MAGIC 
# MAGIC <img src='https://raw.githubusercontent.com/databricks-industry-solutions/legend-getting-started/main/images/reference_architecture.png' width=800>

# COMMAND ----------

# MAGIC %md
# MAGIC Make sure to have the jar file of org.finos.legend-community:legend-delta:X.Y.Z and all its dependencies available in your spark classpath and a legend data model (version controlled on gitlab) previously compiled to disk or packaged as a jar file and available in your classpath. For python support, please add the corresponding library from pypi repo. See example of a configured spark cluster on databricks environment (although the same can be achieved on native spark / delta)

# COMMAND ----------

# MAGIC %md
# MAGIC <img src="https://raw.githubusercontent.com/finos/legend-community-delta/main/images/legend-cluster.png">

# COMMAND ----------

# MAGIC %md
# MAGIC ## Legend model
# MAGIC Legend project can be loaded from classpath or directory as follows. From this object, we can access all underlying PURE entities, mapping, services, etc.

# COMMAND ----------

from legend.delta import LegendClasspathLoader
legend = LegendClasspathLoader().loadResources()

# COMMAND ----------

import pandas as pd
display(pd.DataFrame(legend.get_entities(), columns=['legend_entity']))

# COMMAND ----------

# MAGIC %md
# MAGIC ## Legend schema
# MAGIC We can create the spark schema for any Legend entity of type `Class`. 
# MAGIC This process will recursively loop through each of its underlying fields, enums and possibly nested properties and supertypes.

# COMMAND ----------

schema = legend.get_schema("databricks::entity::employee")

# COMMAND ----------

import pandas as pd
display(pd.DataFrame(
  [[f.name, str(f.dataType), f.nullable, f.metadata['comment']] for f in schema.fields], 
  columns=['field', 'type', 'optional', 'description']
))

# COMMAND ----------

# MAGIC %md
# MAGIC ## Legend transformations
# MAGIC We can transform raw entities into their desired target tables. Note that relational transformations only support direct mapping and therefore easily enforced through `.withColumnRenamed` syntax.

# COMMAND ----------

transformations = legend.get_transformations("databricks::mapping::employee_delta")

# COMMAND ----------

import pandas as pd
display(pd.DataFrame(
  [[e, transformations[e]] for e in transformations], 
  columns=['from_column', 'to_column']
))

# COMMAND ----------

# MAGIC %md
# MAGIC ## Legend expectations
# MAGIC Given the `multiplicity` properties, we can 
# MAGIC detect if a field is optional or not or list has the right number of elements. Given an `enumeration`, 
# MAGIC we check for value consistency. These will be considered **technical expectations** and converted into SQL constraints. In addition to the rules derived from the schema itself, we also support the conversion of **business expectations**
# MAGIC from the PURE language to SQL expressions. We generate a legend
# MAGIC execution plan against a Databricks runtime, hence operating against relational legend `mapping` rather
# MAGIC than pure entities of type `class`.

# COMMAND ----------

expectations = legend.get_expectations("databricks::mapping::employee_delta")

# COMMAND ----------

import pandas as pd
display(pd.DataFrame(
  [[e, expectations[e]] for e in expectations], 
  columns=['expectation', 'constraint']
))

# COMMAND ----------

# MAGIC %md
# MAGIC ## Legend derivations
# MAGIC We can convert Legend derived properties as SQL expressions. In the example model, the field `age` is not physically stored but can be computed at runtime.

# COMMAND ----------

derivations = legend.get_derivations("databricks::mapping::employee_delta")

# COMMAND ----------

import pandas as pd
display(pd.DataFrame(
  [[e, derivations[e]] for e in derivations], 
  columns=['column', 'expression']
))

# COMMAND ----------

# MAGIC %md
# MAGIC ## Legend tables
# MAGIC In order to query our validated entity from legend interface, we can easily create the target state table we know complies with our legend model for the employee entity (hence our queries). We can specify additional parameters such as the path of our database on cloud storage.

# COMMAND ----------

dst_table = legend.get_table("databricks::mapping::employee_delta")
dst_db = dst_table.split('.')[0]
dst_tb = dst_table.split('.')[1]

# COMMAND ----------

_ = sql("CREATE DATABASE IF NOT EXISTS {}".format(dst_db))
_ = sql("DROP TABLE IF EXISTS {}".format(dst_table))

# COMMAND ----------

legend.create_table("databricks::mapping::employee_delta")

# COMMAND ----------

display(sql("DESCRIBE EXTENDED {}".format(dst_table)))

# COMMAND ----------

# MAGIC %md
# MAGIC # Example - write
# MAGIC In this scenario, we read raw JSON files that we schematize, transform and persist to our target state delta table.

# COMMAND ----------

import uuid
import shutil

data_path = '/tmp/{}'.format(uuid.uuid4().hex)
shutil.copyfile('data/MOCK_DATA.json', '/dbfs{}'.format(data_path))

# COMMAND ----------

schema = legend.get_schema("databricks::entity::employee")
schema_df = spark.read.format("json").schema(schema).load(data_path)
display(schema_df.limit(10))

# COMMAND ----------

transformations = legend.get_transformations("databricks::mapping::employee_delta")
for from_column in transformations.keys():
  schema_df = schema_df.withColumnRenamed(from_column, transformations[from_column])

display(schema_df.limit(10))

# COMMAND ----------

schema_df.write.format("delta").mode("append").saveAsTable(dst_table)

# COMMAND ----------

# MAGIC %md
# MAGIC # Example - read
# MAGIC From delta, we read objects that we transform back as a pure entity with derived properties and violated constraints. New derivations could be added from legend studio and seamlessly computed here without the need for engineering team to code. The generated dataframe would comply with business expectations and data quality, as defined from the legend studio.

# COMMAND ----------

sql = legend.generate_sql('databricks::mapping::employee_delta')
print(sql)

# COMMAND ----------

df = legend.query('databricks::mapping::employee_delta')
display(df.limit(10))

# COMMAND ----------

# MAGIC %md
# MAGIC Given the following service defined on legend studio, we generate the corresponding spark execution plan and return a dataframe with all requested attributes and calculations

# COMMAND ----------

df = legend.query('databricks::service::employee')
display(df.limit(10))

# COMMAND ----------

# MAGIC %md
# MAGIC The same works against aggregated functions like `groupBy`, now executing complex queries with scalable compute and simple dataframes

# COMMAND ----------

df = legend.query('databricks::service::skills')
display(df.limit(10))

# COMMAND ----------

# MAGIC %md
# MAGIC ## Reverse engineering PURE
# MAGIC There might be some scenario where we have an existing physical model that we want to map to legend. We may have to code the entire PURE model, or derive most of it programmatically from our physical model. This will generate both the logical and phisical representation of a table as well as the expected mapping. 

# COMMAND ----------

from legend.delta import LegendCodeGen
pure_model = LegendCodeGen().generate_from_table('databricks::legend', dst_db, dst_tb)

# COMMAND ----------

import base64

def download_pure(pure_model):
  base64_bytes = base64.b64encode(pure_model.encode("ascii"))
  base64_string = base64_bytes.decode("ascii")
  html = '''<html lang="en">
      <head>
      <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.2.0/dist/css/bootstrap.min.css" rel="stylesheet" crossorigin="anonymous">
      <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.9.1/font/bootstrap-icons.css" rel="stylesheet" crossorigin="anonymous">
      <style>
      .btn-primary {{
        background-color: rgb(34, 114, 180) !important;
      }}
      </style>
      <script>
      function download() {{
        var element = document.createElement('a');
        element.setAttribute('href', 'data:text/plain;base64,{}');
        element.setAttribute('download', 'model.txt');
        element.style.display = 'none';
        document.body.appendChild(element);
        element.click();
        document.body.removeChild(element);
      }}
      </script>
      </head>
      <body>
      <button type="button" class="btn btn-primary btn-sm" onclick="download()"><i class="bi bi-cloud-download"></i> Legend model</button>
      </body>
      </html>'''.format(base64_string)
  displayHTML(html)

# COMMAND ----------

download_pure(pure_model)
