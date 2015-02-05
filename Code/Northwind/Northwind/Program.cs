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
            var documentStore = new DocumentStore
            {
                Url = "http://live-test.ravendb.net",
                DefaultDatabase = "Northwind",
            };

            documentStore.Initialize();


            //while (true)
            //{
            //	using (var session = documentStore.OpenSession())
            //	{
            //		var configs = session.Load<dynamic>(new[] { "config/add", "config/default" });
            //	}
            //}

            new Products_FrenchNames().Execute(documentStore);
        }
    }


    public class Products_FrenchNames : AbstractIndexCreationTask<Product>
    {
        public Products_FrenchNames()
        {
            Map = products =>
                from product in products
                select new { product.Name, French_Name = product.Name };

            Index("French_Name", FieldIndexing.Analyzed);
            Analyze("French_Name", "Raven.Database.Indexing.Collation.Cultures.FrCollationAnalyzer, Raven.Database");
        }
    }
}