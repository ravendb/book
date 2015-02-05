using System;
using System.Diagnostics;
using System.IO;
using System.Linq;
using Orders;
using Raven.Abstractions.Indexing;
using Raven.Client.Document;
using Raven.Client.Indexes;
using Raven.Client.Linq;

namespace Northwind
{
    public class Program
    {

        private static void Main(string[] args)
        {
            //var documentStore = new DocumentStore
            //{
            //	Url = "http://localhost:8080",
            //	DefaultDatabase = "repl3",
            //};

            //documentStore.Initialize();


            //while (true)
            //{
            //	using (var session = documentStore.OpenSession())
            //	{
            //		var configs = session.Load<dynamic>(new[] { "config/add", "config/default" });
            //	}
            //}

            var path =
                @"D:\ravendb\Raven.Tests.Issues\bin\Release\RavenDB-1369.Backup\Inc 2014-12-22 13-54-01\IndexDefinitions\f02c0134-7ac1-4e9f-b20b-40122bde5948";

            var dir = Path.GetDirectoryName(path);

            //if (Directory.Exists(dir) == false)
            Directory.CreateDirectory(dir);

            File.WriteAllText(path, path);
        }
    }


    public class Product_Search : AbstractIndexCreationTask<Product>
    {
        public Product_Search()
        {
            Map = products =>
                from product in products
                select new { product.Name };

            Index(x => x.Name, FieldIndexing.Analyzed);
        }
    }
}