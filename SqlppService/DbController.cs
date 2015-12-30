using System;
using System.Collections.Generic;
using System.Data.Common;
using System.IO;
using System.Linq;
using System.Text;
using Dapper;
using System.Web.Http;
using System.Xml.Linq;
using System.Configuration;

namespace DbExploreService
{
    public class DbController : ApiController
    {
        [HttpGet]
        public IEnumerable<string> Search(string name)
        {
            var sql = File.ReadAllText( AppDomain.CurrentDomain.BaseDirectory +@"sql\search_object.sql");
            name = ValidateTable(name).Replace("[", "").Replace("]", "").Replace("_", "[_]");

            using (var conn = GetCon())
            {
                return conn.Query<string>(sql, new { name = name });
            }
        }


        [HttpGet]
        public string Get(string name)
        {
            var sql = File.ReadAllText(AppDomain.CurrentDomain.BaseDirectory + @"sql\getObject.sql");
            name = ValidateTable(name);
            dynamic[] ress;
            using (var conn = GetCon())
            {
                ress = conn.Query(sql, new { name = name }).ToArray();

                if (ress.Count() == 0)
                    throw new Exception(" not  found " + name);
                if (ress.Count() > 1)
                    throw new Exception(" found more than 1 object " + name);
                var res = ress[0];
                string dbName = res.dbName;
                string dbType = res.type;
                if (dbType.Trim() == "U")
                {
                    sql = File.ReadAllText(AppDomain.CurrentDomain.BaseDirectory + @"sql\genTable.sql");
                    var cols = conn.Query(sql, new { name = dbName }).ToArray();
                    var result = "declare\n";
                    foreach (var col in cols)
                        result += "@" + col.name + " " + col.system_type_name + " " + (cols.Last() == col ? "" : ",") + "   -- " + (col.is_nullable == true ? "null" : "not null") + "\n";

                    result += "select\n";
                    foreach (var col in cols)
                        result += col.name + (cols.Last() == col ? "" : ",") +"\n";
                    result += "from  " + name + " as " + Nick(name) + "\n";
                    return result;
                }
                else
                {
                    sql = File.ReadAllText(AppDomain.CurrentDomain.BaseDirectory + @"sql\objects_content.sql");

                    var cont = conn.Query<string>(sql, new { name = dbName }).ToArray();
                    return string.Join("", cont);
                }

            }
        }

        string Nick(string table)
        {
            string result = "";
            table = table.Split('.').Last().Replace("tbl_", "").Replace("TBL_", "");
            var lastC="";
            foreach ( var c in table)
            {
                var nc=c.ToString();
                if (lastC=="_")
                    nc=nc.ToUpper();
                else 
                    nc=nc.ToLower();
                lastC=nc;
                if (nc!="_")
                    result+=nc;
            }
            return result;
        }
        string ValidateTable(string table)
        {
            table = table.Trim('\r', '\n', ' ');
            if (table.Contains("\r")
                || table.Contains("\n")
                || table.Contains("'"))
                throw new Exception("invalid characters in object name (" + table);
            return table;
        }
        DbConnection GetCon()
        {
            var constr =ConfigurationManager.AppSettings["conn"];
            var dbFactory = DbProviderFactories.GetFactory("System.Data.SqlClient");
            var conn = dbFactory.CreateConnection();
            conn.ConnectionString = constr;
            conn.Open();
            return conn;
        }

    }
}
